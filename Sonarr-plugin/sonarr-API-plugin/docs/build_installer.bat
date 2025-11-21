@echo off
setlocal enabledelayedexpansion
echo.
echo =====================================
echo Building Sonarr-Seedr Installer
echo =====================================
echo.

cd /d "%~dp0"
cd ..

if not exist "app\version.py" (
    echo ERROR: app\version.py not found!
    echo Make sure you run this from sonarr-API-plugin folder.
    pause
    exit /b 1
)

if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo ERROR: SonarrSeedr.exe not found!
    echo Please run build.bat first to create the executable.
    pause
    exit /b 1
)

if not exist "installer.iss" (
    echo ERROR: installer.iss not found!
    pause
    exit /b 1
)

echo Checking for Inno Setup...
set "INNO="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "INNO=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set "INNO=C:\Program Files\Inno Setup 6\ISCC.exe"

if not defined INNO (
    echo ERROR: Inno Setup not found!
    echo Install from: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

echo Found Inno Setup
echo.

echo Reading current version...
set "VERSION="
for /f "tokens=2 delims==" %%a in ('type "app\version.py" ^| findstr "__version__"') do set "VERSION=%%a"
set "VERSION=%VERSION: =%"
set "VERSION=%VERSION:"=%"

if not defined VERSION (
    echo ERROR: Could not read version!
    pause
    exit /b 1
)

echo Current version: %VERSION%
echo.

echo Checking for existing installers...
set "PLUGIN_ZIPS_DIR=%~dp0..\..\..\Plugin Zips\Sonarr\installer"
if not exist "%PLUGIN_ZIPS_DIR%" mkdir "%PLUGIN_ZIPS_DIR%"

REM Check if installer with current version already exists
if exist "%PLUGIN_ZIPS_DIR%\SonarrSeedr-Setup-v%VERSION%.exe" (
    echo.
    echo Installer v%VERSION% already exists!
    echo Auto-incrementing to next version...
    
    REM Parse version using tokens
    for /f "tokens=1-3 delims=." %%a in ("!VERSION!") do (
        set "MAJOR=%%a"
        set "MINOR=%%b"
        set "PATCH=%%c"
    )
    
    REM Increment patch version
    set /a "PATCH=!PATCH!+1"
    set "VERSION=!MAJOR!.!MINOR!.!PATCH!"
    
    echo New version: !VERSION!
    
    REM Get current date in YYYY-MM-DD format
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
        set "MM=%%a"
        set "DD=%%b"
        set "YYYY=%%c"
    )
    set "DATE=!YYYY!-!MM!-!DD!"
    
    REM Update version.py
    (
    echo """Version information for the Sonarr-Seedr Integration."""
    echo __version__ = "!VERSION!"
    echo __build_date__ = "!DATE!"
    echo __description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
    ) > "app\version.py"
    
    echo Updated app\version.py to !VERSION!
    echo.
)

echo Building version: !VERSION!
echo Output directory: %PLUGIN_ZIPS_DIR%
echo.

echo IMPORTANT: Make sure you rebuilt the executable with:
echo   scripts\run-build.bat
echo.
echo Press any key to continue with installer build...
pause >nul
echo.

echo Building installer with Inno Setup...
echo.

"%INNO%" "installer.iss" /Q

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installer build failed!
    pause
    exit /b 1
)

echo.
echo Finding new installer...
set "INSTALLER="
for /f "delims=" %%i in ('dir /b /o-d "releases\installers\SonarrSeedr-Setup-v!VERSION!.exe" 2^>nul') do (
    set "INSTALLER=%%i"
    goto :found
)

:found
if not defined INSTALLER (
    echo ERROR: Installer not found!
    echo Looking for: releases\installers\SonarrSeedr-Setup-v!VERSION!.exe
    pause
    exit /b 1
)

echo Found: !INSTALLER!
echo Source: %CD%\releases\installers\!INSTALLER!
echo.

echo Copying to Plugin Zips\Sonarr\installer...
copy "%CD%\releases\installers\!INSTALLER!" "%PLUGIN_ZIPS_DIR%\!INSTALLER!"

if %errorlevel% neq 0 (
    echo ERROR: Copy failed!
    pause
    exit /b 1
)

echo.
echo =====================================
echo SUCCESS!
echo =====================================
echo.
echo Version: v!VERSION!
echo File: !INSTALLER!
echo Location: %PLUGIN_ZIPS_DIR%\!INSTALLER!
echo.
echo All installers in this folder:
dir /b "%PLUGIN_ZIPS_DIR%\SonarrSeedr-Setup-*.exe"
echo.

REM Update installer.iss version for next build
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'installer.iss') -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"!VERSION!\"' | Set-Content 'installer.iss'" >nul 2>&1
if not errorlevel 1 (
    echo installer.iss updated with version !VERSION!
)

echo.
pause
