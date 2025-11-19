"""
Auto-update service for checking and installing updates from GitHub releases.
"""
import os
import sys
import json
import requests
import subprocess
import tempfile
import zipfile
from pathlib import Path
from typing import Dict, Optional, List
from packaging import version as pkg_version

class UpdateService:
    """Handles checking for and installing updates from GitHub"""
    
    # GitHub repository for checking updates
    GITHUB_REPO = "jose987654/sonarr-plugin"
    GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
    
    def __init__(self, current_version: str):
        """
        Initialize update service.
        
        Args:
            current_version: Current application version (e.g., "1.1.0")
        """
        self.current_version = current_version
        
    def check_for_updates(self) -> Dict:
        """
        Check if a new version is available on GitHub.
        
        Returns:
            Dict with keys:
                - update_available (bool)
                - current_version (str)
                - latest_version (str)
                - download_url (str, optional)
                - changelog (list, optional)
                - error (str, optional)
        """
        try:
            # Fetch latest release from GitHub
            response = requests.get(
                self.GITHUB_API_URL,
                headers={"Accept": "application/vnd.github.v3+json"},
                timeout=10
            )
            response.raise_for_status()
            
            release_data = response.json()
            
            # Extract version from tag name (e.g., "v1.2.0" -> "1.2.0")
            latest_version_str = release_data.get("tag_name", "").lstrip("v")
            
            if not latest_version_str:
                return {
                    "update_available": False,
                    "current_version": self.current_version,
                    "latest_version": self.current_version,
                    "error": "Could not parse latest version from GitHub"
                }
            
            # Compare versions
            try:
                current = pkg_version.parse(self.current_version)
                latest = pkg_version.parse(latest_version_str)
                update_available = latest > current
            except Exception as e:
                print(f"[ERROR] Version comparison failed: {e}")
                update_available = False
            
            # Find the ZIP asset in the release
            # IMPORTANT: Only look for SonarrSeedr*.zip (not source code archives)
            download_url = None
            for asset in release_data.get("assets", []):
                asset_name = asset.get("name", "")
                # Must start with "SonarrSeedr" and end with ".zip"
                # This excludes source code archives which GitHub auto-generates
                if asset_name.startswith("SonarrSeedr") and asset_name.endswith(".zip"):
                    download_url = asset.get("browser_download_url")
                    break
            
            # Parse changelog from release body
            changelog = self._parse_changelog(release_data.get("body", ""))
            
            return {
                "update_available": update_available,
                "current_version": self.current_version,
                "latest_version": latest_version_str,
                "download_url": download_url,
                "changelog": changelog,
                "release_notes": release_data.get("body", ""),
                "release_date": release_data.get("published_at", "")
            }
            
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Failed to check for updates: {e}")
            return {
                "update_available": False,
                "current_version": self.current_version,
                "latest_version": self.current_version,
                "error": f"Failed to connect to GitHub: {str(e)}"
            }
        except Exception as e:
            print(f"[ERROR] Unexpected error checking for updates: {e}")
            return {
                "update_available": False,
                "current_version": self.current_version,
                "latest_version": self.current_version,
                "error": f"Unexpected error: {str(e)}"
            }
    
    def _parse_changelog(self, release_body: str) -> List[str]:
        """
        Parse changelog from release body.
        
        Args:
            release_body: The release notes text
            
        Returns:
            List of changelog items
        """
        changelog = []
        
        if not release_body:
            return changelog
        
        # Look for lines starting with - or * (bullet points)
        for line in release_body.split("\n"):
            line = line.strip()
            if line.startswith("-") or line.startswith("*"):
                # Remove the bullet and add to changelog
                changelog_item = line.lstrip("-*").strip()
                if changelog_item:
                    changelog.append(changelog_item)
        
        return changelog[:10]  # Limit to 10 items
    
    def download_and_install_update(self, download_url: str, version: str) -> Dict:
        """
        Download and install an update.
        
        Args:
            download_url: URL to download the update ZIP from
            version: Version being installed
            
        Returns:
            Dict with keys:
                - success (bool)
                - message (str)
                - error (str, optional)
        """
        try:
            print(f"[UPDATE] Downloading update from: {download_url}")
            
            # Determine the application directory
            if getattr(sys, 'frozen', False):
                # Running as compiled executable
                app_dir = Path(sys.executable).parent
            else:
                # Running as script (development)
                app_dir = Path(__file__).parents[2]
            
            # Create temp directory for download
            temp_dir = Path(tempfile.gettempdir()) / "sonarr_seedr_update"
            temp_dir.mkdir(exist_ok=True)
            
            # Download the update ZIP
            print(f"[UPDATE] Downloading to: {temp_dir}")
            zip_path = temp_dir / "update.zip"
            
            response = requests.get(download_url, stream=True, timeout=300)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(zip_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            print(f"[UPDATE] Download progress: {progress:.1f}%")
            
            print(f"[UPDATE] Download complete: {zip_path}")
            
            # Extract the ZIP to temp directory
            extract_dir = temp_dir / "extracted"
            extract_dir.mkdir(exist_ok=True)
            
            print(f"[UPDATE] Extracting update...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
            
            print(f"[UPDATE] Extraction complete")
            
            # Create the updater batch script
            updater_script = self._create_updater_script(
                app_dir=app_dir,
                extract_dir=extract_dir,
                version=version
            )
            
            print(f"[UPDATE] Updater script created: {updater_script}")
            
            # Return success - the updater script will handle the rest
            return {
                "success": True,
                "message": f"Update downloaded successfully. Updater script ready at: {updater_script}",
                "updater_script": str(updater_script)
            }
            
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Failed to download update: {e}")
            return {
                "success": False,
                "message": "Failed to download update",
                "error": str(e)
            }
        except Exception as e:
            print(f"[ERROR] Failed to install update: {e}")
            import traceback
            traceback.print_exc()
            return {
                "success": False,
                "message": "Failed to install update",
                "error": str(e)
            }
    
    def _create_updater_script(self, app_dir: Path, extract_dir: Path, version: str) -> Path:
        """
        Create a batch script to perform the update.
        
        The script will:
        1. Wait for the main app to close
        2. Copy new files over old files
        3. Restart the application
        4. Delete itself
        
        Args:
            app_dir: Application installation directory
            extract_dir: Directory containing extracted update files
            version: Version being installed
            
        Returns:
            Path to the updater script
        """
        updater_script = app_dir / "updater.bat"
        
        # Find the exe name
        exe_name = "SonarrSeedr.exe"
        
        # Create the updater batch script
        script_content = f"""@echo off
title Sonarr-Seedr Auto-Updater
echo ================================
echo Sonarr-Seedr Auto-Updater
echo Installing version {version}
echo ================================
echo.

REM Wait for main application to close
echo Waiting for application to close...
timeout /t 3 /nobreak >nul

REM Kill any running instances
taskkill /f /im "{exe_name}" 2>nul

REM Wait a moment
timeout /t 2 /nobreak >nul

echo.
echo Copying new files...

REM Copy files from extracted update to app directory
REM (Preserving config folder - it's not in the update ZIP)
xcopy /E /Y /Q "{extract_dir}\\*" "{app_dir}\\"

echo.
echo Update installed successfully!
echo.

REM Restart the application
echo Starting updated application...
start "" "{app_dir}\\{exe_name}"

REM Wait a moment
timeout /t 2 /nobreak >nul

REM Clean up
echo.
echo Cleaning up...
rmdir /s /q "{extract_dir.parent}"

REM Delete this updater script
echo Update complete!
timeout /t 2 /nobreak >nul
del "%~f0"
"""
        
        # Write the script
        with open(updater_script, 'w') as f:
            f.write(script_content)
        
        return updater_script
    
    def trigger_update_restart(self, updater_script: Path):
        """
        Trigger the updater script and exit the application.
        
        Args:
            updater_script: Path to the updater batch script
        """
        try:
            print(f"[UPDATE] Starting updater script: {updater_script}")
            
            # Start the updater script in a new process
            subprocess.Popen(
                [str(updater_script)],
                creationflags=subprocess.CREATE_NEW_CONSOLE | subprocess.DETACHED_PROCESS,
                close_fds=True
            )
            
            print("[UPDATE] Updater started. Exiting application...")
            
            # Exit the application after a short delay
            import time
            time.sleep(1)
            sys.exit(0)
            
        except Exception as e:
            print(f"[ERROR] Failed to trigger update restart: {e}")
            raise

