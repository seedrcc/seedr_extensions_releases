"""
System tray icon for SonarrSeedr
Shows app running status and provides quick controls
"""
import os
import sys
import webbrowser
import threading
from pathlib import Path

try:
    from pystray import Icon, Menu, MenuItem
    from PIL import Image
    TRAY_AVAILABLE = True
except ImportError:
    TRAY_AVAILABLE = False
    Icon = None
    Menu = None
    MenuItem = None
    Image = None


class TrayIcon:
    """System tray icon for SonarrSeedr application."""
    
    def __init__(self, port=8242):
        """Initialize the tray icon."""
        self.port = port
        self.icon = None
        self.running = True
        
    def get_icon_image(self):
        """Load the icon image from logo.ico."""
        try:
            # Try to find logo.ico
            if getattr(sys, 'frozen', False):
                # Running as compiled executable
                base_path = Path(sys._MEIPASS)
            else:
                # Running as script
                base_path = Path(__file__).parent.parent
            
            icon_path = base_path / 'logo.ico'
            
            if icon_path.exists():
                return Image.open(str(icon_path))
            else:
                # Create a simple default icon if logo.ico not found
                return self._create_default_icon()
                
        except Exception as e:
            print(f"Error loading icon: {e}")
            return self._create_default_icon()
    
    def _create_default_icon(self):
        """Create a simple default icon if logo.ico is not available."""
        # Create a simple 64x64 icon with "S" text
        img = Image.new('RGB', (64, 64), color='#3b82f6')
        return img
    
    def open_browser(self, icon, item):
        """Open the web interface in browser."""
        url = f"http://localhost:{self.port}"
        webbrowser.open(url)
    
    def open_api_docs(self, icon, item):
        """Open API documentation in browser."""
        url = f"http://localhost:{self.port}/docs"
        webbrowser.open(url)
    
    def open_dashboard(self, icon, item):
        """Open dashboard in browser."""
        url = f"http://localhost:{self.port}/dashboard"
        webbrowser.open(url)
    
    def quit_app(self, icon, item):
        """Quit the application."""
        self.running = False
        icon.stop()
        # Force exit the entire application
        os._exit(0)
    
    def create_menu(self):
        """Create the system tray menu."""
        return Menu(
            MenuItem('Open Web Interface', self.open_browser, default=True),
            MenuItem('Dashboard', self.open_dashboard),
            MenuItem('API Documentation', self.open_api_docs),
            Menu.SEPARATOR,
            MenuItem(f'Running on port {self.port}', None, enabled=False),
            Menu.SEPARATOR,
            MenuItem('Quit SonarrSeedr', self.quit_app)
        )
    
    def run(self):
        """Run the system tray icon."""
        if not TRAY_AVAILABLE:
            return
        
        try:
            image = self.get_icon_image()
            self.icon = Icon(
                'SonarrSeedr',
                image,
                'SonarrSeedr - Running on port {}'.format(self.port),
                menu=self.create_menu()
            )
            
            # Run the icon (this blocks until icon.stop() is called)
            self.icon.run()
            
        except Exception as e:
            # Silently fail if tray icon can't start
            pass


def create_tray_icon(port=8242):
    """
    Create and start the system tray icon in a background thread.
    
    Args:
        port: The port the application is running on
        
    Returns:
        TrayIcon instance
    """
    if not TRAY_AVAILABLE:
        return None
    
    tray = TrayIcon(port=port)
    
    # Start tray icon in a separate thread
    tray_thread = threading.Thread(target=tray.run, daemon=True)
    tray_thread.start()
    
    return tray


if __name__ == "__main__":
    # Test the tray icon
    print("Testing tray icon...")
    tray = create_tray_icon()
    if tray:
        print("Tray icon started! Check your system tray.")
        print("Press Ctrl+C to exit...")
        try:
            import time
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nExiting...")
    else:
        print("Tray icon not available. Install pystray and Pillow:")
        print("  pip install pystray Pillow")

