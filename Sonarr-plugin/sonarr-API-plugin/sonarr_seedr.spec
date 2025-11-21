# -*- mode: python ; coding: utf-8 -*-

import os
import sys
from pathlib import Path

# Add the current directory to Python path
block_cipher = None

# Get the application directory
app_dir = os.path.abspath('.')

# Define data files and folders to include
datas = [
    # Include the entire app directory with all Python modules and subdirectories
    ('app', 'app'),
    
    # Include the icon file for system tray
    ('icons/logo.ico', '.'),
    
    # Include config directory structure (but not sensitive files)
    ('config', 'config'),
    
    # Include any other necessary directories
    ('completed', 'completed'),
    ('processed', 'processed'),  
    ('error', 'error'),
    ('torrents', 'torrents'),
]

# Hidden imports for modules that PyInstaller might miss
hiddenimports = [
    # Core application modules - with ALL submodules explicitly listed
    'app',
    'app.main',
    'app.config',
    'app.version',
    
    # Auth modules
    'app.auth',
    'app.auth.oauth_handler',
    
    # API modules
    'app.api',
    'app.api.seedr_client',
    'app.api.sonarr_client',
    
    # Service modules
    'app.service',
    'app.service.seedr_sonarr_integration',
    'app.service.update_service',
    
    # Utils modules
    'app.utils',
    'app.utils.torrent_watcher',
    
    # Web modules
    'app.web',
    'app.web.routes',
    
    # Tray icon module
    'app.tray_icon',
    
    # System tray dependencies
    'pystray',
    'pystray._win32',
    'PIL',
    'PIL.Image',
    'PIL.ImageDraw',
    
    # FastAPI and related
    'uvicorn',
    'uvicorn.main',
    'uvicorn.lifespan',
    'uvicorn.lifespan.on',
    'uvicorn.loops',
    'uvicorn.loops.auto',
    'uvicorn.protocols',
    'uvicorn.protocols.http',
    'uvicorn.protocols.http.auto',
    'uvicorn.protocols.http.h11_impl',
    'uvicorn.protocols.websockets',
    'uvicorn.protocols.websockets.auto',
    'uvicorn.logging',
    'uvicorn.config',
    'uvicorn.server',
    'fastapi',
    'fastapi.routing',
    'fastapi.staticfiles',
    'fastapi.templating',
    'fastapi.security',
    'fastapi.security.oauth2',
    'fastapi.middleware',
    'fastapi.middleware.cors',
    'fastapi.responses',
    'fastapi.exceptions',
    'fastapi.params',
    'fastapi.datastructures',
    'fastapi.dependencies',
    'fastapi.dependencies.utils',
    
    # Pydantic
    'pydantic',
    'pydantic.fields',
    'pydantic.main',
    'pydantic.types',
    'pydantic.validators',
    'pydantic_core',
    'pydantic_core._pydantic_core',
    
    # Starlette
    'starlette',
    'starlette.staticfiles',
    'starlette.templating',
    'starlette.responses',
    'starlette.middleware',
    'starlette.middleware.base',
    'starlette.middleware.cors',
    'starlette.routing',
    'starlette.applications',
    'starlette.requests',
    'starlette.datastructures',
    'starlette.concurrency',
    'starlette.types',
    'starlette.background',
    'starlette.formparsers',
    
    # Template engine
    'jinja2',
    'jinja2.ext',
    'jinja2.loaders',
    
    # HTTP and networking
    'requests',
    'requests.auth',
    'requests.adapters',
    'requests.sessions',
    'requests.models',
    'urllib3',
    'urllib3.poolmanager',
    'urllib3.connectionpool',
    'urllib3.connection',
    'urllib3.util',
    'urllib3.util.retry',
    'urllib3.util.timeout',
    'urllib3.util.ssl_',
    
    # Version parsing for updates
    'packaging',
    'packaging.version',
    'packaging.specifiers',
    
    # File watching
    'watchdog',
    'watchdog.observers',
    'watchdog.observers.api',
    'watchdog.events',
    'watchdog.observers.polling',
    'watchdog.observers.winapi',
    'watchdog.utils',
    'watchdog.utils.dirsnapshot',
    
    # File operations
    'aiofiles',
    'aiofiles.os',
    'aiofiles.threadpool',
    'aiofiles.threadpool.binary',
    'aiofiles.threadpool.text',
    'python_multipart',
    'multipart',
    
    # Async libraries
    'anyio',
    'anyio._backends',
    'anyio._backends._asyncio',
    'anyio._core',
    'anyio._core._eventloop',
    'anyio._core._sockets',
    'anyio.abc',
    
    # Email and MIME
    'email.mime',
    'email.mime.multipart',
    'email.mime.text',
    'email.mime.base',
    
    # Standard library modules
    'json',
    'threading',
    'time',
    'os',
    'sys',
    'pathlib',
    'shutil',
    'logging',
    'logging.handlers',
    'webbrowser',
    'argparse',
    'dotenv',
    'ctypes',
    'ctypes.wintypes',
    'sqlite3',
    'ssl',
    'socket',
    'http',
    'http.client',
    'collections',
    'collections.abc',
    'typing_extensions',
    'inspect',
    'warnings',
    're',
]

# Analysis phase
a = Analysis(
    ['run.py'],
    pathex=[app_dir],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[app_dir],  # Add current directory to hook search path
    hooksconfig={},
    runtime_hooks=['hook app.py'],  # Add our custom runtime hook
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# Remove duplicate files
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# Create executable
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='SonarrSeedr',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,  # Hidden console - runs in background
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='icons/logo.ico',  # Custom application icon
)

# Create distribution folder
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='SonarrSeedr',
)
