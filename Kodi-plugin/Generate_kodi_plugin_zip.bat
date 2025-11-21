@echo off
REM ====================================================================
REM Plugin ZIP Generator for Kodi Addons
REM This script creates a ZIP file for the specified plugin
REM ====================================================================

setlocal enabledelayedexpansion

echo ========================================
echo Kodi Plugin ZIP Generator
echo ========================================
echo.

REM Get the script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Check if plugin.video.seedr directory exists
if not exist "plugin.video.seedr" (
    echo ERROR: plugin.video.seedr directory not found!
    echo Please make sure you're running this script from the Kodi-plugin folder.
    pause
    exit /b 1
)

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH!
    echo Please install Python and try again.
    pause
    exit /b 1
)

echo Creating plugin ZIP file...
echo.

REM Create a temporary Python script to generate the ZIP
set "TEMP_SCRIPT=%TEMP%\create_plugin_zip.py"
(
echo import os
echo import sys
echo import zipfile
echo import shutil
echo import xml.etree.ElementTree as ET
echo from datetime import datetime
echo(
echo def cleanup_pyc_files^(addon_dir^):
echo     """Remove *.pyc files to reduce ZIP size"""
echo     for root, dirs, files in os.walk^(addon_dir^):
echo         for filename in files:
echo             if filename.endswith^(".pyc"^):
echo                 try:
echo                     os.remove^(os.path.join^(root, filename^)^)
echo                 except:
echo                     pass
echo(
echo def read_addon_xml^(addon_dir^):
echo     """Read the addon.xml file"""
echo     addon_xml_path = os.path.join^(addon_dir, "addon.xml"^)
echo     if not os.path.exists^(addon_xml_path^):
echo         return None
echo     try:
echo         tree = ET.parse^(addon_xml_path^)
echo         return tree.getroot^(^)
echo     except Exception as e:
echo         print^(f"Error parsing {addon_xml_path}: {e}"^)
echo         return None
echo(
echo def create_zipfile^(addon_dir, output_dir^):
echo     """Create ZIP file for the addon"""
echo     addon_xml_root = read_addon_xml^(addon_dir^)
echo     if addon_xml_root is None:
echo         print^(f"ERROR: No valid addon.xml found in {addon_dir}"^)
echo         return False
echo     addon_id = addon_xml_root.get^("id"^)
echo     addon_version = addon_xml_root.get^("version"^)
echo     zipfile_name = os.path.join^(output_dir, f"{addon_id}-{addon_version}.zip"^)
echo     print^(f"Creating ZIP for {addon_id} version {addon_version}..."^)
echo     temp_dir = f"{addon_id}_temp"
echo     if os.path.exists^(temp_dir^):
echo         shutil.rmtree^(temp_dir^)
echo     os.makedirs^(temp_dir^)
echo     shutil.copytree^(addon_dir, os.path.join^(temp_dir, addon_id^)^)
echo     cleanup_pyc_files^(os.path.join^(temp_dir, addon_id^)^)
echo     with zipfile.ZipFile^(zipfile_name, 'w', zipfile.ZIP_DEFLATED^) as zip_ref:
echo         source_dir = os.path.join^(temp_dir, addon_id^)
echo         for root, dirs, files in os.walk^(source_dir^):
echo             for file in files:
echo                 file_path = os.path.join^(root, file^)
echo                 rel_path = os.path.relpath^(file_path, source_dir^)
echo                 zip_path = os.path.join^(addon_id, rel_path^).replace^('\\', '/'^)
echo                 zip_ref.write^(file_path, zip_path^)
echo     shutil.rmtree^(temp_dir^)
echo     print^(f"SUCCESS: ZIP file created at {zipfile_name}"^)
echo     return True
echo(
echo if __name__ == "__main__":
echo     plugin_dir = "plugin.video.seedr"
echo     output_dir = os.path.join^("..", "Plugin Zips", "Kodi"^)
echo     if not os.path.exists^(output_dir^):
echo         os.makedirs^(output_dir^)
echo     if not create_zipfile^(plugin_dir, output_dir^):
echo         sys.exit^(1^)
) > "%TEMP_SCRIPT%"

REM Run the Python script
python "%TEMP_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to create plugin ZIP!
    del "%TEMP_SCRIPT%" 2>nul
    pause
    exit /b 1
)

REM Clean up temporary script
del "%TEMP_SCRIPT%" 2>nul

echo.
echo ========================================
echo Plugin ZIP created successfully!
echo ========================================
echo.
echo The ZIP file is ready in the current directory.
echo You can now use it to install or distribute your plugin.
echo.
pause

