"""
PyInstaller runtime hook for the app module.
This hook ensures that the app package and its submodules are properly accessible at runtime.
"""
import sys
import os
from pathlib import Path

# Get the base path of the bundled application
if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
    # Running in a PyInstaller bundle
    bundle_dir = Path(sys._MEIPASS)
    
    # Add the app directory to sys.path if not already present
    app_path = str(bundle_dir / 'app')
    if app_path not in sys.path:
        sys.path.insert(0, app_path)
    
    # Also add the base directory
    base_path = str(bundle_dir)
    if base_path not in sys.path:
        sys.path.insert(0, base_path)
    
    # Set environment variable for the app to know it's running from bundle
    os.environ['PYINSTALLER_BUNDLED'] = '1'

