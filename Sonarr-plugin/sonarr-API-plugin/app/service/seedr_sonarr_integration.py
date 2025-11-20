"""
Integration service for Seedr and Sonarr.
"""
import os
import json
import re
import time
from typing import Dict, Any, Optional, List
from ..api.seedr_client import SeedrClient
from ..api.sonarr_client import SonarrClient
from ..config import Config

class SeedrSonarrIntegration:
    def __init__(self, config: Optional[Config] = None, strict_validation: bool = True):
        self.config = config or Config.from_env()
        self.config.validate(strict=strict_validation)
        self.seedr = SeedrClient(self.config.seedr)
        self.sonarr = SonarrClient(self.config.sonarr)
        # Set up download directory and mapping file
        if self.config.download.download_dir:
            self.mapping_file = os.path.join(self.config.download.download_dir, "download_mappings.json")
            # Ensure download directory exists
            os.makedirs(self.config.download.download_dir, exist_ok=True)
        else:
            # Use a default location if not configured (lazy import to avoid circular dependency)
            from ..utils.paths import get_completed_dir
            default_dir = str(get_completed_dir())
            self.mapping_file = os.path.join(default_dir, "download_mappings.json")
            os.makedirs(default_dir, exist_ok=True)

        # Status cache to avoid excessive API calls
        self.status_cache = {}
        self.status_cache_ttl = 15  # Cache active downloads for 15 seconds
        self.failed_cache_ttl = 300  # Cache 404/failed for 5 minutes

    def add_download(self, title: Optional[str], download_url: str, series_id: Optional[int] = None) -> Dict[str, Any]:
        """Add a download to Seedr and return the response."""
        try:
            # Normalize YTS URLs to match the working example format
            if "yts" in download_url.lower() and "/torrent/download/" in download_url.lower():
                # Extract the hash from the URL if possible
                hash_match = re.search(r'/download/([A-F0-9]+)', download_url, re.IGNORECASE)
                if hash_match:
                    torrent_hash = hash_match.group(1)
                    # Format it exactly like the working example
                    download_url = f"https://yts.mx/torrent/download/{torrent_hash}"

            # Add torrent to Seedr using the Tasks API
            result = self.seedr.add_torrent(download_url)
            
            # Extract title from Seedr response if not provided
            if not title:
                title = result.get("title") or result.get("name") or download_url[:50]
            
            # The API might return a 413 status with a wishlist item (not enough space)
            if result.get("reason_phrase") == "not_enough_space_added_to_wishlist" and result.get("wt"):
                wishlist_item = result.get("wt", {})
                task_id = wishlist_item.get("id")
                if task_id:
                    self._store_download_mapping(title, task_id, series_id)
                    return {
                        "success": True,
                        "message": f"Added {title} to Seedr wishlist (not enough space)",
                        "download_id": task_id,
                        "torrent_id": task_id,
                        "title": title
                    }
                else:
                    return {
                        "success": False,
                        "message": "Failed to get wishlist ID from Seedr response"
                    }
            
            # For a regular successful addition - check all possible ID fields
            task_id = result.get("task_id") or result.get("id") or result.get("user_torrent_id")

            if not task_id:
                # If we have success=true but no ID, use the torrent_hash as ID
                if result.get("success") and result.get("torrent_hash"):
                    task_id = result.get("torrent_hash")
                else:
                    return {
                        "success": False,
                            "message": "Failed to get task ID from Seedr response",
                            "response": result
                    }
            
            # Store mapping of Sonarr title to Seedr task ID
            self._store_download_mapping(title, task_id, series_id)
            
            return {
                "success": True,
                "message": f"Added {title} to Seedr",
                "download_id": task_id,
                "torrent_id": task_id,
                "title": title
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Failed to add download: {str(e)}"
            }

    def _store_download_mapping(self, title: str, torrent_id: str, series_id: Optional[int] = None) -> None:
        """Store mapping between Sonarr title and Seedr torrent ID."""
        try:
            mappings = {}
            if os.path.exists(self.mapping_file):
                with open(self.mapping_file, 'r') as f:
                    mappings = json.load(f)
            
            mappings[title] = {
                "torrent_id": torrent_id,
                "series_id": series_id,
                "added_at": time.time()
            }
            
            with open(self.mapping_file, 'w') as f:
                json.dump(mappings, f)
        except Exception as e:
            print(f"Error storing download mapping: {e}")

    def check_download_status(self, title: str, use_cache: bool = True) -> Dict[str, Any]:
        """Check the status of a download.
        
        Args:
            title: The title of the download
            use_cache: If True, return cached status if available (default: True)
        """
        try:
            # Check cache first (if enabled)
            if use_cache and title in self.status_cache:
                cached_status, cached_time, is_failed = self.status_cache[title]
                age = time.time() - cached_time
                # Use longer cache for failed/404 torrents
                cache_ttl = self.failed_cache_ttl if is_failed else self.status_cache_ttl
                if age < cache_ttl:
                    # Cache is still valid - return without logging
                    return cached_status
            
            if not os.path.exists(self.mapping_file):
                result = {"status": "not_found", "message": "No download mapping found", "error": "no_mapping_file"}
                self.status_cache[title] = (result, time.time(), True)
                return result

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                result = {"status": "not_found", "message": "Download not found", "error": "not_in_mappings"}
                self.status_cache[title] = (result, time.time(), True)
                return result

            torrent_id = mappings[title]["torrent_id"]

            # Try to get status using the Tasks API
            try:
                status = self.seedr.get_task(torrent_id)
                
                # Check if this is a 404 error (torrent not found on Seedr)
                if status.get("status") == "unknown" and "404" in status.get("message", ""):
                    result = {
                        "status": "not_found",
                        "progress": 0,
                        "message": "Torrent not found on Seedr (404 - may have been deleted or already downloaded)",
                        "error": "404"
                    }
                    # Cache 404 errors for longer (5 minutes)
                    self.status_cache[title] = (result, time.time(), True)
                    return result
                
                # If we have a valid task response (not an error)
                if "id" in status or "progress" in status:
                    # Get progress from response
                    progress = status.get("progress", 0)
                    speed = status.get("speed", 0)
                    
                    # Determine status based on progress and speed
                    if progress >= 100:
                        # Progress 100% or more = completed
                        task_status = "completed"
                    elif progress > 0 and speed > 0:
                        # Has progress and is downloading
                        task_status = "downloading"
                    elif progress > 0 and speed == 0:
                        # Has progress but not downloading - might be seeding or finished
                        task_status = "completed" if progress >= 99 else "paused"
                    else:
                        # No progress yet = queued/waiting
                        task_status = "queued"
                    
                    result = {
                        "status": task_status,
                        "progress": progress,
                        "message": f"Progress: {progress}%"
                    }
                    # Cache active downloads for shorter time (15 seconds)
                    self.status_cache[title] = (result, time.time(), False)
                    return result
                
                # Fallback: use status field from response
                if status.get("status") != "unknown":
                    result = {
                    "status": status.get("status", "unknown"),
                    "progress": status.get("progress", 0),
                    "message": status.get("message", "")
                }
                    # Cache active downloads for shorter time (15 seconds)
                    self.status_cache[title] = (result, time.time(), False)
                    return result
            except Exception as e:
                pass  # Silently fall back to old methods
            
            # If the tasks API fails, fall back to the old methods
            try:
                status = self.seedr.get_torrent_status(torrent_id)
                
                # If successful, cache and return the status
                result = {
                    "status": status.get("status", "unknown"),
                    "progress": status.get("progress", 0),
                    "message": status.get("message", "")
                }
                self.status_cache[title] = (result, time.time(), False)
                return result
            except Exception as e:
                # If the ID is a hash, the torrent might be completed and moved to a folder
                if len(torrent_id) == 40:  # SHA-1 hash length
                    # Try to find the folder by listing root folders
                    try:
                        folders = self.seedr.get_folder_contents("0")  # Root folder
                        for folder in folders:
                            if folder.get("torrent_hash") == torrent_id.lower():
                                result = {
                                    "status": "completed",
                                    "progress": 100,
                                    "message": "Torrent completed and moved to folder",
                                    "folder_id": folder.get("id")
                                }
                                self.status_cache[title] = (result, time.time(), False)
                                return result
                    except:
                        pass
                
                # If we can't find it, return error
                result = {"status": "error", "message": str(e)}
                self.status_cache[title] = (result, time.time(), True)
                return result
            
        except Exception as e:
            result = {"status": "error", "message": str(e)}
            self.status_cache[title] = (result, time.time(), True)
            return result

    def get_downloaded_files(self, title: str) -> Dict[str, Any]:
        """Get downloaded files for a title."""
        try:
            if not os.path.exists(self.mapping_file):
                return {"success": False, "message": "No download mapping found"}

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                return {"success": False, "message": "Download not found"}

            torrent_id = mappings[title]["torrent_id"]
            
            # First try to get contents using the Tasks API
            try:
                task_status = self.seedr.get_task(torrent_id)
                
                # Debug: Check what we got
                if not isinstance(task_status, dict):
                    print(f"[ERROR] get_task returned non-dict: {type(task_status)} - {task_status}")
                    return {"success": False, "message": f"Invalid task status type: {type(task_status).__name__}"}
                
                # Check if task has valid response (not an error)
                if "id" in task_status:
                    # Check if completed based on progress or folder_id
                    progress = task_status.get("progress", 0)
                    folder_id = task_status.get("folder_id")
                    folder_created_id = task_status.get("folder_created_id")
                    
                    print(f"[DEBUG] Task {torrent_id}: progress={progress}, folder_id={folder_id}, folder_created_id={folder_created_id}")
                    
                    # Try folder_created_id first (this is usually the actual folder with files)
                    if folder_created_id and folder_created_id != "0" and folder_created_id != 0:
                        print(f"[DEBUG] Trying folder_created_id: {folder_created_id}")
                        try:
                            contents = self.seedr.get_folder_contents(str(folder_created_id))
                            print(f"[DEBUG] folder_created_id {folder_created_id} returned {len(contents) if isinstance(contents, list) else 0} items")
                            if contents and isinstance(contents, list) and len(contents) > 0:
                                print(f"[SUCCESS] Found {len(contents)} items in folder_created_id {folder_created_id}")
                                return {
                                    "success": True,
                                    "files": contents
                                }
                            else:
                                print(f"[WARNING] folder_created_id {folder_created_id} is empty, trying next method...")
                        except Exception as e:
                            print(f"[WARNING] folder_created_id {folder_created_id} failed (might be 404): {e}")
                            print(f"[INFO] Continuing with alternate methods...")
                    
                    # If has folder_id, torrent is completed and moved to folder
                    if folder_id and folder_id != "0" and folder_id != 0 and str(folder_id) != str(folder_created_id):
                        print(f"[DEBUG] Trying folder_id: {folder_id}")
                        try:
                            contents = self.seedr.get_folder_contents(str(folder_id))
                            print(f"[DEBUG] folder_id {folder_id} returned {len(contents) if isinstance(contents, list) else 0} items")
                            if contents and isinstance(contents, list) and len(contents) > 0:
                                print(f"[SUCCESS] Found {len(contents)} items in folder_id {folder_id}")
                                return {
                                    "success": True,
                                    "files": contents
                                }
                            else:
                                print(f"[WARNING] folder_id {folder_id} is empty, trying next method...")
                        except Exception as e:
                            print(f"[WARNING] folder_id {folder_id} failed (might be 404): {e}")
                            print(f"[INFO] Continuing with alternate methods...")
                    
                    # If progress >= 100, try to get task contents (should have 'files' key)
                    if progress >= 100:
                        print(f"[DEBUG] Trying task contents for task ID: {torrent_id}")
                        try:
                            contents = self.seedr.get_task_contents(str(torrent_id))
                            print(f"[DEBUG] Task contents returned: {len(contents) if isinstance(contents, list) else 0} items")
                            
                            if isinstance(contents, list) and len(contents) > 0:
                                print(f"[SUCCESS] Found {len(contents)} file(s) in task contents!")
                                # Add type to each item if not present
                                for item in contents:
                                    if isinstance(item, dict) and 'type' not in item:
                                        # Infer type based on presence of size (files have size, folders don't)
                                        item['type'] = 'file' if 'size' in item else 'folder'
                                
                                return {
                                    "success": True,
                                    "files": contents
                                }
                            else:
                                print(f"[WARNING] Task contents is empty or invalid, trying next method...")
                        except Exception as e:
                            print(f"[WARNING] Task contents failed: {e}")
                            print(f"[INFO] Continuing with alternate methods...")
            except Exception as e:
                print(f"[ERROR] Exception in get_downloaded_files: {e}")
                import traceback
                traceback.print_exc()
            
            # If the tasks API fails, try alternate method
            try:
                status = self.seedr.get_torrent_status(torrent_id)
                
                # Check for folder_created_id first (preferred), then folder_id
                folder_created_id = status.get("folder_created_id")
                folder_id = status.get("folder_id")
                
                # Try folder_created_id first
                if folder_created_id and folder_created_id != "0" and folder_created_id != 0:
                    print(f"[DEBUG] Alternate method: Trying folder_created_id: {folder_created_id}")
                    try:
                        contents = self.seedr.get_folder_contents(str(folder_created_id))
                        if contents and len(contents) > 0:
                            print(f"[SUCCESS] Alternate method found {len(contents)} items in folder_created_id")
                            return {
                                "success": True,
                                "files": contents
                            }
                    except Exception as e:
                        print(f"[WARNING] Alternate method folder_created_id failed: {e}")
                
                # Try folder_id as fallback
                if folder_id and folder_id != "0" and folder_id != 0:
                    print(f"[DEBUG] Alternate method: Trying folder_id: {folder_id}")
                    try:
                        contents = self.seedr.get_folder_contents(str(folder_id))
                        if contents and len(contents) > 0:
                            print(f"[SUCCESS] Alternate method found {len(contents)} items in folder_id")
                        return {
                            "success": True,
                            "files": contents
                        }
                    except Exception as e:
                        print(f"[WARNING] Alternate method folder_id failed: {e}")
            except Exception as e:
                if self.seedr.verbose_logging:
                    print(f"Error in alternate method: {e}")
            
            # Last resort: Search root folder for matching torrent name
            print(f"[DEBUG] Last resort: Searching root folder (ID: 0) for matching files...")
            try:
                root_contents = self.seedr.get_folder_contents("0")
                print(f"[DEBUG] Root folder has {len(root_contents) if isinstance(root_contents, list) else 0} items")
                
                if root_contents and isinstance(root_contents, list) and len(root_contents) > 0:
                    # Look for folder/file matching the title
                    torrent_name = title.replace('.magnet', '').replace('.torrent', '')
                    print(f"[DEBUG] Looking for items matching: '{torrent_name}'")
                    
                    # First pass: exact or very close matches
                    for item in root_contents:
                        if isinstance(item, dict):
                            item_name = item.get("name", "")
                            item_type = item.get("type", "unknown")
                            item_id = item.get("id", "unknown")
                            
                            # Check if item name matches torrent (case-insensitive)
                            if torrent_name.lower() in item_name.lower() or item_name.lower() in torrent_name.lower():
                                print(f"[DEBUG] Found potential match in root: {item_type} '{item_name}' (ID: {item_id})")
                                
                                # If it's a folder, get its contents
                                if item_type == "folder":
                                    try:
                                        folder_contents = self.seedr.get_folder_contents(str(item_id))
                                        if folder_contents and len(folder_contents) > 0:
                                            print(f"[SUCCESS] Found {len(folder_contents)} items in root folder '{item_name}'")
                                            return {
                                                "success": True,
                                                "files": folder_contents
                                            }
                                        else:
                                            print(f"[WARNING] Root folder '{item_name}' is empty")
                                    except Exception as e:
                                        print(f"[WARNING] Failed to access root folder '{item_name}': {e}")
                                
                                # If it's a file, return it
                                elif item_type == "file":
                                    print(f"[SUCCESS] Found matching file in root: '{item_name}'")
                                    return {
                                        "success": True,
                                        "files": [item]
                                    }
                    
                    print(f"[WARNING] No matching items found in root folder")
                else:
                    print(f"[WARNING] Root folder is empty or inaccessible")
            except Exception as e:
                print(f"[ERROR] Error searching root folder: {e}")
                import traceback
                traceback.print_exc()
            
            return {"success": False, "message": "No files found or download not completed"}
            
        except Exception as e:
            return {"success": False, "message": str(e)}

    def download_completed_files(self, title: str, save_path: Optional[str] = None) -> Dict[str, Any]:
        """Download completed files for a title."""
        try:
            if not save_path:
                save_path = self.config.download.download_dir
            
            print(f"[DOWNLOAD] ========================================")
            print(f"[DOWNLOAD] Starting download process for: {title}")
            print(f"[DOWNLOAD] Save path: {save_path}")
            print(f"[DOWNLOAD] ========================================")
            
            # Get downloaded files
            print(f"[DOWNLOAD] Step 1: Retrieving file list from Seedr...")
            files_result = self.get_downloaded_files(title)
            print(f"[DOWNLOAD] Step 1 complete: Success={files_result.get('success')}")
            
            # Ensure files_result is a dict
            if not isinstance(files_result, dict):
                return {"success": False, "message": f"Invalid response type: {type(files_result).__name__}"}
            
            if not files_result.get("success"):
                print(f"[DOWNLOAD] ERROR: Failed to get file list - {files_result.get('message')}")
                return files_result
            
            files = files_result.get("files", [])
            
            print(f"[DOWNLOAD] Step 2: Found {len(files)} file/folder(s) to download")
            
            if not files:
                print(f"[DOWNLOAD] ERROR: No files to download!")
                return {"success": False, "message": "No files to download"}
            
            # List the files/folders found
            for idx, item in enumerate(files, 1):
                if isinstance(item, dict):
                    item_type = item.get("type", "unknown")
                    item_name = item.get("name", "unknown")
                    item_id = item.get("id", "unknown")
                    print(f"[DOWNLOAD]   {idx}. {item_type}: {item_name} (ID: {item_id})")
            
            # Create the save directory if it doesn't exist
            print(f"[DOWNLOAD] Step 3: Creating download directory...")
            os.makedirs(save_path, exist_ok=True)
            print(f"[DOWNLOAD] Step 3 complete: Directory ready at {save_path}")
            
            # Track downloaded files
            downloaded_files = []
            
            print(f"[DOWNLOAD] Step 4: Starting file downloads...")
            
            # Process files and folders
            for item in files:
                # Ensure item is a dict
                if not isinstance(item, dict):
                    print(f"[ERROR] File item is not a dict: {type(item)} - {item}")
                    continue
                    
                if item.get("type") == "file":
                    # Download file
                    file_id = item.get("id")
                    file_name = item.get("name")
                    
                    print(f"[DEBUG] Processing file: {file_name} with ID: {file_id}")
                    
                    if file_id is None or not file_name:
                        print(f"[ERROR] Missing file_id or file_name: id={file_id}, name={file_name}")
                        continue
                    
                    # Ensure file_id is a string
                    file_id = str(file_id)
                    
                    file_path = os.path.join(save_path, file_name)
                    print(f"[DEBUG] Downloading file ID {file_id} to {file_path}")
                    
                    if self.seedr.download_file(file_id, file_path):
                        print(f"[SUCCESS] Downloaded file: {file_name}")
                        downloaded_files.append(file_path)
                    else:
                        print(f"[ERROR] Failed to download file: {file_name}")
                elif item.get("type") == "folder":
                    # Download folder as archive
                    folder_id = item.get("id")
                    folder_name = item.get("name")
                    
                    print(f"[DEBUG] Processing folder: {folder_name} with ID: {folder_id}")
                    
                    if folder_id is None or not folder_name:
                        print(f"[ERROR] Missing folder_id or folder_name: id={folder_id}, name={folder_name}")
                        continue
                    
                    # Ensure folder_id is a string
                    folder_id = str(folder_id)
                    
                    archive_path = os.path.join(save_path, f"{folder_name}.zip")
                    print(f"[DEBUG] Downloading folder ID {folder_id} as archive to {archive_path}")
                    
                    if self.seedr.download_folder_as_archive(folder_id, archive_path):
                        print(f"[SUCCESS] Downloaded folder: {folder_name}")
                        downloaded_files.append(archive_path)
                    else:
                        print(f"[ERROR] Failed to download folder: {folder_name}")
            
            print(f"[DOWNLOAD] ========================================")
            print(f"[DOWNLOAD] Download process complete!")
            print(f"[DOWNLOAD] Successfully downloaded: {len(downloaded_files)} file(s)")
            print(f"[DOWNLOAD] ========================================")
            
            return {
                "success": True,
                "downloaded_files": downloaded_files,
                "message": f"Downloaded {len(downloaded_files)} files"
            }
            
        except Exception as e:
            print(f"[DOWNLOAD] ========================================")
            print(f"[DOWNLOAD] FATAL ERROR in download process: {e}")
            print(f"[DOWNLOAD] ========================================")
            import traceback
            traceback.print_exc()
            return {"success": False, "message": str(e)}

    def notify_sonarr(self, title: str) -> Dict[str, Any]:
        """Notify Sonarr of downloaded files."""
        try:
            if not os.path.exists(self.mapping_file):
                return {"success": False, "message": "No download mapping found"}

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                return {"success": False, "message": "Download not found"}
            
            # Download the files if needed
            download_path = self.config.download.download_dir
            
            # Check if download directory is set
            if not download_path:
                return {"success": False, "message": "Download directory not set"}
            
            # Download files
            download_result = self.download_completed_files(title, download_path)
            
            if not download_result.get("success"):
                return download_result
            
            # Trigger Sonarr scan
            scan_result = self.sonarr.command_download_scan(download_path)
            
            return {
                "success": True,
                "message": "Notified Sonarr of downloaded files",
                "sonarr_response": scan_result,
                "downloaded_files": download_result.get("downloaded_files", [])
            }
            
        except Exception as e:
            return {"success": False, "message": str(e)}

    def pause_download(self, title: str) -> Dict[str, Any]:
        """Pause a download."""
        try:
            if not os.path.exists(self.mapping_file):
                return {"success": False, "message": "No download mapping found"}

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                return {"success": False, "message": "Download not found"}

            torrent_id = mappings[title]["torrent_id"]
            
            # Check if the download is active
            status = self.check_download_status(title)
            
            if status.get("status") == "downloading":
                # Pause the download
                if self.seedr.pause_task(torrent_id):
                    return {
                        "success": True,
                        "message": f"Paused download for {title}"
                    }
                else:
                    return {
                        "success": False,
                        "message": "Failed to pause download"
                    }
            else:
                return {
                    "success": False,
                    "message": f"Download not in progress (status: {status.get('status')})"
                }
            
        except Exception as e:
            return {"success": False, "message": str(e)}

    def resume_download(self, title: str) -> Dict[str, Any]:
        """Resume a paused download."""
        try:
            if not os.path.exists(self.mapping_file):
                return {"success": False, "message": "No download mapping found"}

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                return {"success": False, "message": "Download not found"}

            torrent_id = mappings[title]["torrent_id"]
            
            # Check if the download is paused
            status = self.check_download_status(title)
            
            if status.get("status") == "paused":
                # Resume the download
                if self.seedr.resume_task(torrent_id):
                    return {
                        "success": True,
                        "message": f"Resumed download for {title}"
                    }
                else:
                    return {
                        "success": False,
                        "message": "Failed to resume download"
                    }
            else:
                return {
                    "success": False,
                    "message": f"Download not paused (status: {status.get('status')})"
                }
            
        except Exception as e:
            return {"success": False, "message": str(e)}

    def delete_download(self, title: str) -> Dict[str, Any]:
        """Delete a download."""
        try:
            if not os.path.exists(self.mapping_file):
                return {"success": False, "message": "No download mapping found"}

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            if title not in mappings:
                return {"success": False, "message": "Download not found"}

            torrent_id = mappings[title]["torrent_id"]
            
            # Delete the torrent
            if self.seedr.delete_torrent(torrent_id):
                # Remove from mappings
                del mappings[title]
                
                # Save updated mappings
                with open(self.mapping_file, 'w') as f:
                    json.dump(mappings, f)
                
                return {
                    "success": True,
                    "message": f"Deleted download for {title}"
                }
            else:
                return {
                    "success": False,
                    "message": "Failed to delete download"
                }
            
        except Exception as e:
            return {"success": False, "message": str(e)}

    def poll_downloads(self, use_cache: bool = False) -> List[Dict[str, Any]]:
        """Poll all downloads and return their status.
        
        Args:
            use_cache: If True, use cached status (default: False - force fresh checks for polling)
        """
        try:
            if not os.path.exists(self.mapping_file):
                return []

            with open(self.mapping_file, 'r') as f:
                mappings = json.load(f)

            results = []
            
            for title, mapping in mappings.items():
                torrent_id = mapping["torrent_id"]
                series_id = mapping.get("series_id")
                added_at = mapping.get("added_at", 0)
                
                # Get status (force fresh check for polling by default)
                status = self.check_download_status(title, use_cache=use_cache)
                
                # Add to results
                results.append({
                    "title": title,
                    "torrent_id": torrent_id,
                    "series_id": series_id,
                    "added_at": added_at,
                    "status": status.get("status", "unknown"),
                    "progress": status.get("progress", 0),
                    "message": status.get("message", ""),
                    "error": status.get("error", "")
                })
            
            return results
            
        except Exception as e:
            print(f"Error polling downloads: {e}")
            return [] 