"""
Test script to verify all imports work correctly.
This can be used to test both the source code and the bundled executable.
"""
import sys
import os

print("="*80)
print("IMPORT TEST - Checking all application modules")
print("="*80)
print(f"Python version: {sys.version}")
print(f"Python executable: {sys.executable}")
print(f"Current working directory: {os.getcwd()}")
print(f"Frozen: {getattr(sys, 'frozen', False)}")
if hasattr(sys, '_MEIPASS'):
    print(f"Bundle directory: {sys._MEIPASS}")
print("\nPython path:")
for p in sys.path:
    print(f"  - {p}")
print("="*80)

# Test imports one by one
modules_to_test = [
    'app',
    'app.main',
    'app.config',
    'app.version',
    'app.auth',
    'app.auth.oauth_handler',
    'app.api',
    'app.api.seedr_client',
    'app.api.sonarr_client',
    'app.service',
    'app.service.seedr_sonarr_integration',
    'app.utils',
    'app.utils.torrent_watcher',
    'app.web',
    'app.web.routes',
]

failed_imports = []
successful_imports = []

for module in modules_to_test:
    try:
        __import__(module)
        print(f"✓ {module}")
        successful_imports.append(module)
    except Exception as e:
        print(f"✗ {module}: {str(e)}")
        failed_imports.append((module, str(e)))

print("\n" + "="*80)
print(f"RESULTS: {len(successful_imports)}/{len(modules_to_test)} modules imported successfully")
print("="*80)

if failed_imports:
    print("\nFailed imports:")
    for module, error in failed_imports:
        print(f"  - {module}: {error}")
    sys.exit(1)
else:
    print("\n✅ All imports successful!")
    sys.exit(0)

