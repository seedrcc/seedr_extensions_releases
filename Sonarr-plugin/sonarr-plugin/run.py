#!/usr/bin/env python
"""
Startup script for the Sonarr-Seedr FastAPI application.
"""
import uvicorn
import argparse
import os
import sys
import webbrowser
import threading
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Fix for PyInstaller frozen app with console=False
# When running with hidden console, stdout/stderr are None
if getattr(sys, 'frozen', False) and sys.stdout is None:
    # Running in a PyInstaller bundle with no console
    # Redirect stdout and stderr to prevent crashes
    import io
    sys.stdout = io.StringIO()
    sys.stderr = io.StringIO()

# Import tray icon (will be None if not available)
try:
    from app.tray_icon import create_tray_icon
    TRAY_AVAILABLE = True
except ImportError:
    TRAY_AVAILABLE = False
    print("Warning: System tray icon not available (pystray not installed)")

def open_browser(host, port, delay=1.5):
    """Open the default web browser after a short delay."""
    def _open_browser():
        # Wait a bit to make sure the server is up
        time.sleep(delay)
        # Determine the correct URL
        host_part = "localhost" if host == "0.0.0.0" else host
        url = f"http://{host_part}:{port}"
        # Open the browser
        try:
            if sys.stdout and hasattr(sys.stdout, 'write'):
                print(f"Opening browser to {url}")
        except:
            pass  # Silently fail if stdout is not available
        webbrowser.open(url)
    
    # Start the browser-opening function in a new thread
    threading.Thread(target=_open_browser, daemon=True).start()

def main():
    """Main entry point for the application."""
    parser = argparse.ArgumentParser(description="Sonarr-Seedr FastAPI Application")
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8242, help='Port to bind to')
    parser.add_argument('--reload', action='store_true', help='Enable auto-reload')
    parser.add_argument('--log-level', default='info', help='Logging level')
    parser.add_argument('--no-browser', action='store_true', help='Do not open browser automatically')

    args = parser.parse_args()
    
    # Configuration for uvicorn
    config = {
        "app": "app.main:app",
        "host": args.host,
        "port": args.port,
        "reload": args.reload,
        "log_level": args.log_level,
    }
    
    # If running as frozen app (PyInstaller), use simpler logging
    if getattr(sys, 'frozen', False):
        config["log_config"] = None  # Disable default logging config
        config["access_log"] = False  # Disable access log to console
    
    # Only print messages if we have a real console
    if sys.stdout and hasattr(sys.stdout, 'write'):
        try:
            print(f"\n=== Starting Sonarr-Seedr FastAPI on {args.host}:{args.port} ===\n")
            print(f"Access the web interface at http://{args.host if args.host != '0.0.0.0' else 'localhost'}:{args.port}")
            print(f"API documentation available at http://{args.host if args.host != '0.0.0.0' else 'localhost'}:{args.port}/docs")
        except:
            pass  # Silently fail if stdout is not available
    
    # Start system tray icon (if running as frozen app)
    tray_icon = None
    if getattr(sys, 'frozen', False) and TRAY_AVAILABLE:
        try:
            tray_icon = create_tray_icon(port=args.port)
            if sys.stdout and hasattr(sys.stdout, 'write'):
                try:
                    print(f"System tray icon started - Check notification area near clock!")
                except:
                    pass
        except Exception as e:
            if sys.stdout and hasattr(sys.stdout, 'write'):
                try:
                    print(f"Warning: Could not start system tray icon: {e}")
                except:
                    pass
    
    # Open browser automatically unless disabled
    if not args.no_browser:
        open_browser(args.host, args.port)
    
    # Run the application
    try:
        uvicorn.run(**config)
    finally:
        # Cleanup on exit
        if tray_icon:
            try:
                tray_icon.icon.stop()
            except:
                pass

if __name__ == "__main__":
    main() 