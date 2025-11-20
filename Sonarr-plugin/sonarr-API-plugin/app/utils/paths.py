"""
Path management for Sonarr-Seedr application.
Handles proper data directories for installed applications on Windows.
"""
import os
import sys
from pathlib import Path
from typing import Optional


def get_app_data_dir() -> Path:
    """
    Get the application data directory.
    
    - Installed version (via installer): uses AppData\\Local\\Seedr
    - Portable version (from ZIP): uses directory next to exe
    - Running from source: uses project directory
    
    Returns:
        Path: Application data directory
    """
    # Check if running as PyInstaller bundle
    if getattr(sys, 'frozen', False):
        # Running as compiled executable
        exe_dir = Path(sys.executable).parent
        
        # Check if this is an installed version (marker file created by installer)
        installed_marker = exe_dir / '.installed'
        
        if installed_marker.exists():
            # INSTALLED VERSION - use AppData (no permission issues)
            app_data = os.getenv('LOCALAPPDATA', os.path.expanduser('~\\AppData\\Local'))
            data_dir = Path(app_data) / 'Seedr'
        else:
            # PORTABLE VERSION - use directory next to exe (truly portable)
            data_dir = exe_dir
    else:
        # Running from source - use project directory
        data_dir = Path(__file__).parents[2]
    
    # Ensure directory exists
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir


def get_config_dir() -> Path:
    """
    Get the configuration directory.
    
    Returns:
        Path: Configuration directory
    """
    config_dir = get_app_data_dir() / 'config'
    config_dir.mkdir(parents=True, exist_ok=True)
    return config_dir


def get_log_file() -> Path:
    """
    Get the log file path.
    
    Returns:
        Path: Log file path
    """
    log_dir = get_app_data_dir() / 'logs'
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir / 'folder_watcher.log'


def get_torrents_dir() -> Path:
    """
    Get the torrents directory.
    
    Returns:
        Path: Torrents directory
    """
    torrents_dir = get_app_data_dir() / 'torrents'
    torrents_dir.mkdir(parents=True, exist_ok=True)
    return torrents_dir


def get_completed_dir() -> Path:
    """
    Get the completed downloads directory.
    
    Returns:
        Path: Completed directory
    """
    completed_dir = get_app_data_dir() / 'completed'
    completed_dir.mkdir(parents=True, exist_ok=True)
    return completed_dir


def get_processed_dir() -> Path:
    """
    Get the processed torrents directory.
    
    Returns:
        Path: Processed directory
    """
    processed_dir = get_app_data_dir() / 'processed'
    processed_dir.mkdir(parents=True, exist_ok=True)
    return processed_dir


def get_error_dir() -> Path:
    """
    Get the error torrents directory.
    
    Returns:
        Path: Error directory
    """
    error_dir = get_app_data_dir() / 'error'
    error_dir.mkdir(parents=True, exist_ok=True)
    return error_dir


def get_static_dir() -> Path:
    """
    Get the static files directory (always in installation directory).
    
    Returns:
        Path: Static files directory
    """
    if getattr(sys, 'frozen', False):
        # Running as compiled executable - check multiple possible locations
        # Try _MEIPASS first (PyInstaller temp extraction)
        base_path = Path(sys._MEIPASS)
        static_path = base_path / 'app' / 'web' / 'static'
        if not static_path.exists():
            # Try without 'app' prefix
            static_path = base_path / 'web' / 'static'
        return static_path
    else:
        # Running from source
        base_path = Path(__file__).parents[1]
        return base_path / 'web' / 'static'


def get_templates_dir() -> Path:
    """
    Get the templates directory (always in installation directory).
    
    Returns:
        Path: Templates directory
    """
    if getattr(sys, 'frozen', False):
        # Running as compiled executable - check multiple possible locations
        # Try _MEIPASS first (PyInstaller temp extraction)
        base_path = Path(sys._MEIPASS)
        templates_path = base_path / 'app' / 'web' / 'templates'
        if not templates_path.exists():
            # Try without 'app' prefix
            templates_path = base_path / 'web' / 'templates'
        return templates_path
    else:
        # Running from source
        base_path = Path(__file__).parents[1]
        return base_path / 'web' / 'templates'


def get_icon_path() -> Optional[Path]:
    """
    Get the tray icon path.
    
    Returns:
        Optional[Path]: Icon path if it exists, None otherwise
    """
    if getattr(sys, 'frozen', False):
        # Running as compiled executable
        base_path = Path(sys._MEIPASS)
        icon_path = base_path / 'logo.ico'
        if icon_path.exists():
            return icon_path
    else:
        # Running from source
        icon_path = Path(__file__).parents[2] / 'logo.ico'
        if icon_path.exists():
            return icon_path
    
    return None


def ensure_all_directories() -> None:
    """
    Ensure all required directories exist.
    Call this on application startup.
    """
    get_config_dir()
    get_log_file().parent.mkdir(parents=True, exist_ok=True)
    get_torrents_dir()
    get_completed_dir()
    get_processed_dir()
    get_error_dir()


# For backward compatibility
def get_base_dir() -> Path:
    """
    Get the base application directory.
    
    Returns:
        Path: Base directory
    """
    return get_app_data_dir()

