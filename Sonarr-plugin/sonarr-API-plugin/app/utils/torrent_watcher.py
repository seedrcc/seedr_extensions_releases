"""
Torrent watcher module for monitoring folders.
"""
import os
import time
import logging
import shutil
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from ..config import Config

# Configure logging
logger = logging.getLogger("torrent_watcher")

class TorrentWatcher(FileSystemEventHandler):
    """File system event handler for watching and processing torrent files."""
    
    def __init__(self, config, integration, download_dir=None, poll_interval=30):
        """Initialize the torrent watcher."""
        # Lazy import to avoid circular dependency
        from .paths import get_completed_dir, get_processed_dir, get_error_dir
        
        self.config = config
        self.integration = integration
        self.poll_interval = poll_interval  # How often to check for completed downloads (seconds)
        self.polling_active = True  # Flag to control polling loop
        
        # Set up directories
        self.download_dir = download_dir or str(get_completed_dir())
        self.processed_dir = str(get_processed_dir())
        self.error_dir = str(get_error_dir())
        
        # Create necessary directories
        os.makedirs(self.download_dir, exist_ok=True)
        os.makedirs(self.processed_dir, exist_ok=True)
        os.makedirs(self.error_dir, exist_ok=True)
        
        # Configure logging
        self.logger = logger
        self.logger.info(f"TorrentWatcher initialized. Watching for .torrent and .magnet files")
        self.logger.info(f"Completed downloads will be saved to: {self.download_dir}")
        self.logger.info(f"Polling interval: {self.poll_interval} seconds")
    
    def on_created(self, event):
        """Handle file creation events."""
        if not event.is_directory and self._is_torrent_or_magnet(event.src_path):
            self.logger.info(f"New file detected: {event.src_path}")
            self._process_torrent_file(event.src_path)
    
    def on_modified(self, event):
        """Handle file modification events."""
        if not event.is_directory and self._is_torrent_or_magnet(event.src_path):
            self.logger.info(f"Modified file detected: {event.src_path}")
            self._process_torrent_file(event.src_path)
    
    def _is_torrent_or_magnet(self, file_path):
        """Check if the file is a torrent or magnet file."""
        _, ext = os.path.splitext(file_path)
        return ext.lower() in ['.torrent', '.magnet']
    
    def _process_torrent_file(self, file_path):
        """Process a torrent file by uploading it to Seedr."""
        try:
            self.logger.info(f"Processing torrent file: {os.path.basename(file_path)}")
            
            # Read file content
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            # Determine if this is a magnet link or a torrent file
            _, ext = os.path.splitext(file_path)
            
            # Get title from filename (without extension)
            title = os.path.splitext(os.path.basename(file_path))[0]
            
            if ext.lower() == '.magnet':
                # It's a magnet link file, read the content as text
                magnet_link = file_data.decode('utf-8').strip()
                self.logger.info(f"Uploading magnet link: {magnet_link[:50]}...")
                
                # Add the magnet link to Seedr via integration (stores mapping)
                result = self.integration.add_download(title, magnet_link)
                
                if not result or not result.get("success"):
                    self.logger.error(f"Failed to add magnet link to Seedr: {result.get('message', 'Unknown error')}")
                    # Move to error directory
                    error_path = os.path.join(self.error_dir, os.path.basename(file_path))
                    shutil.copy2(file_path, error_path)
                    return False
                
                self.logger.info(f"Successfully added magnet link to Seedr (ID: {result.get('torrent_id', 'N/A')})")
            else:
                # It's a torrent file
                self.logger.info(f"Uploading torrent file: {os.path.basename(file_path)}")
                
                # Add the torrent file to Seedr via integration (stores mapping)
                result = self.integration.add_download(title, file_data)
                
                if not result or not result.get("success"):
                    self.logger.error(f"Failed to add torrent file to Seedr: {result.get('message', 'Unknown error')}")
                    # Move to error directory
                    error_path = os.path.join(self.error_dir, os.path.basename(file_path))
                    shutil.copy2(file_path, error_path)
                    return False
                
                self.logger.info(f"Successfully added torrent file to Seedr (ID: {result.get('torrent_id', 'N/A')})")
            
            # Move to processed directory
            processed_path = os.path.join(self.processed_dir, os.path.basename(file_path))
            shutil.copy2(file_path, processed_path)
            
            return True
            
        except Exception as e:
            self.logger.exception(f"Error processing torrent file {os.path.basename(file_path)}: {str(e)}")
            
            # Move to error directory
            try:
                error_path = os.path.join(self.error_dir, os.path.basename(file_path))
                shutil.copy2(file_path, error_path)
            except Exception as move_error:
                self.logger.error(f"Error moving file to error directory: {str(move_error)}")
            
            return False
    
    def poll_completed_downloads(self):
        """Poll Seedr for completed downloads and download them locally.
        This method should be called periodically to check for completed downloads."""
        try:
            # Get all tracked downloads
            self.logger.info("[POLLING] Calling integration.poll_downloads()...")
            downloads = self.integration.poll_downloads()
            self.logger.info(f"[POLLING] Received {len(downloads) if downloads else 0} tracked download(s) from Seedr")
            
            if not downloads:
                self.logger.info("[POLLING] No tracked downloads found")
                return
            
            # Separate downloads by status
            failed_or_missing = []
            active = []
            completed = []
            
            for d in downloads:
                status = d.get('status', 'unknown')
                title = d.get('title', 'Unknown')
                error = d.get('error', '')
                
                # Check if torrent is not found or has errors (SKIP THESE)
                if status in ['not_found', 'unknown'] or error in ['404', 'no_mapping_file', 'not_in_mappings']:
                    failed_or_missing.append(d)
                    if error == '404':
                        self.logger.warning(f"[SKIP] '{title}' - Not found on Seedr (404) - torrent may have been deleted")
                    elif status == 'unknown':
                        self.logger.warning(f"[SKIP] '{title}' - Status unknown - skipping this torrent")
                elif status == "completed":
                    completed.append(d)
                    self.logger.info(f"[POLLING]   - {title}: status='completed' [READY TO DOWNLOAD]")
                else:
                    active.append(d)
                    self.logger.info(f"[POLLING]   - {title}: status='{status}' [DOWNLOADING]")
            
            # Report status summary
            if failed_or_missing:
                self.logger.info(f"[POLLING] {len(failed_or_missing)} torrents skipped (not found or errors)")
            if active:
                self.logger.info(f"[POLLING] {len(active)} torrents are still downloading/processing")
            if completed:
                self.logger.info(f"[DOWNLOAD] Found {len(completed)} completed downloads to process!")
            else:
                if not active:
                    self.logger.info(f"[POLLING] No active downloads (only errors/not found)")
                else:
                    self.logger.info(f"[POLLING] No completed downloads yet")
            
            # Process completed downloads
            for download in completed:
                title = download.get("title", "Unknown")
                
                # Check if we have already downloaded this
                flag_file = os.path.join(self.download_dir, f".{title}.downloaded")
                if os.path.exists(flag_file):
                    self.logger.info(f"[DOWNLOAD] Skipping {title} - already downloaded")
                    continue
                
                self.logger.info(f"[DOWNLOAD] Download completed on Seedr: {title}")
                self.logger.info(f"[DOWNLOAD] Starting local download from Seedr to: {self.download_dir}")
                
                # Download files from Seedr to local storage
                try:
                    result = self.integration.download_completed_files(title, self.download_dir)
                    
                    if result.get("success"):
                        # Create flag file to mark as downloaded
                        with open(flag_file, 'w') as f:
                            f.write("downloaded")
                        
                        downloaded_files = result.get("downloaded_files", [])
                        self.logger.info(f"[SUCCESS] Downloaded {len(downloaded_files)} file(s) for '{title}'")
                        for file_path in downloaded_files:
                            self.logger.info(f"[SUCCESS]   -> {os.path.basename(file_path)}")
                    else:
                        self.logger.error(f"[ERROR] Error downloading files for '{title}': {result.get('message')}")
                except Exception as e:
                    self.logger.exception(f"[ERROR] Exception downloading files for '{title}': {str(e)}")
                    
        except Exception as e:
            self.logger.exception(f"[ERROR] Error polling completed downloads: {str(e)}")
    
    def start_polling(self):
        """Start the polling loop in a background thread."""
        import threading
        
        self.logger.info(f"[POLLING] Initializing polling thread (interval: {self.poll_interval} seconds)...")
        
        def polling_loop():
            self.logger.info(f"[POLLING] Thread STARTED - checking for completed downloads every {self.poll_interval} seconds")
            iteration = 0
            while self.polling_active:
                try:
                    iteration += 1
                    self.logger.info(f"[POLLING] Iteration #{iteration} - Checking Seedr for completed downloads...")
                    self.poll_completed_downloads()
                    self.logger.info(f"[POLLING] Iteration #{iteration} complete")
                except Exception as e:
                    self.logger.exception(f"[ERROR] Error in polling loop iteration #{iteration}: {str(e)}")
                
                # Sleep for the interval
                if self.polling_active:
                    self.logger.info(f"[POLLING] Sleeping for {self.poll_interval} seconds until next check...")
                    time.sleep(self.poll_interval)
            
            self.logger.info("[POLLING] Polling loop stopped")
        
        # Start polling in a background thread
        try:
            polling_thread = threading.Thread(target=polling_loop, daemon=True, name="SeedrPollingThread")
            polling_thread.start()
            self.logger.info(f"[POLLING] Background polling thread started successfully (Thread ID: {polling_thread.ident})")
        except Exception as e:
            self.logger.exception(f"[ERROR] FAILED to start polling thread: {str(e)}")
    
    def stop_polling(self):
        """Stop the polling loop."""
        self.polling_active = False
        self.logger.info("Stopping polling loop...")

def watch_folder(torrent_dir, download_dir=None, interval=30):
    """Watch a folder for torrent files and process them."""
    # Lazy import to avoid circular dependency
    from ..service.seedr_sonarr_integration import SeedrSonarrIntegration
    
    logger.info(f"Starting folder watcher for {torrent_dir}")
    
    # Ensure the torrent directory exists
    if not os.path.exists(torrent_dir):
        logger.info(f"Creating torrent directory: {torrent_dir}")
        os.makedirs(torrent_dir, exist_ok=True)
    
    # Set up the integration
    config = Config.from_env()
    integration = SeedrSonarrIntegration(config, strict_validation=False)
    
    # Start watching the folder
    event_handler = TorrentWatcher(config, integration, download_dir)
    observer = Observer()
    observer.schedule(event_handler, torrent_dir, recursive=False)
    observer.start()
    
    logger.info(f"Started watching {torrent_dir} for torrent files")
    
    try:
        # Process any existing torrent files
        existing_files = [f for f in os.listdir(torrent_dir) 
                         if os.path.isfile(os.path.join(torrent_dir, f)) and 
                            (f.endswith('.torrent') or f.endswith('.magnet'))]
        
        if existing_files:
            logger.info(f"Found {len(existing_files)} existing torrent files to process")
            for file_name in existing_files:
                file_path = os.path.join(torrent_dir, file_name)
                try:
                    event_handler._process_torrent_file(file_path)
                except Exception as e:
                    logger.exception(f"Error processing existing file {file_name}: {str(e)}")
        
        # Monitor downloads and check for new files
        while True:
            # Check for completed downloads
            try:
                downloads = integration.poll_downloads()
                completed = [d for d in downloads if d.get("status", {}).get("status") == "completed"]
                
                for download in completed:
                    title = download.get("title", "Unknown")
                    
                    # Check if we have already downloaded this
                    flag_file = os.path.join(event_handler.download_dir, f".{title}.downloaded")
                    if os.path.exists(flag_file):
                        continue
                    
                    logger.info(f"Download completed: {title}")
                    
                    # Download files
                    try:
                        result = integration.download_completed_files(title, event_handler.download_dir)
                        
                        if result.get("success"):
                            # Create flag file to mark as downloaded
                            with open(flag_file, 'w') as f:
                                f.write("downloaded")
                            
                            logger.info(f"Downloaded files for {title}: {result.get('message')}")
                        else:
                            logger.error(f"Error downloading files for {title}: {result.get('message')}")
                    except Exception as e:
                        logger.exception(f"Exception downloading files for {title}: {str(e)}")
            except Exception as e:
                logger.exception(f"Error checking downloads: {str(e)}")
            
            # Sleep for the specified interval
            time.sleep(interval)
    
    except KeyboardInterrupt:
        logger.info("Folder watcher stopped by user")
    except Exception as e:
        logger.exception(f"Folder watcher error: {str(e)}")
    finally:
        observer.stop()
        observer.join()
        logger.info("Folder watcher stopped") 