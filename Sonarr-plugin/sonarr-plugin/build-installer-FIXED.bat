@echo off
setlocal enabledelayedexpansion

REM Force the window to stay open no matter what
title Building Installer - DO NOT CLOSE

echo =====================================
echo Building Sonarr-Seedr Installer
echo =====================================
echo.

REM Check current directory
echo Current directory: %CD%
echo.

REM Check if we're in the right directory
echo Checking for app\version.py...
if not exist "app\version.py" (
    echo.
    echo [ERROR] Could not find app\version.py!
    echo Please make sure you are running this from the project root directory.
    echo.
    echo Looking for: %CD%\app\version.py
    echo.
    echo Press CTRL+C to exit or
    pause
    exit /b 1
)

echo Found app\version.py!
echo.

REM Read version from version.py
echo Reading version...
set "VERSION="
for /f "usebackq tokens=2 delims==" %%a in (`findstr "__version__" app\version.py`) do (
    set VERLINE=%%a
)

REM Remove quotes and spaces
if defined VERLINE (
    set VERSION=%VERLINE:"=%
    set VERSION=%VERSION: =%
)

if not defined VERSION (
    echo.
    echo [ERROR] Could not read version from app\version.py!
    echo.
    pause
    exit /b 1
)

echo Version: %VERSION%
echo.

REM Step 1: Check if Inno Setup is installed
echo [1/3] Checking for Inno Setup...
set "INNO_PATH="

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    echo Found: C:\Program Files (x86)\Inno Setup 6\ISCC.exe
    goto :inno_found
)

if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"
    echo Found: C:\Program Files\Inno Setup 6\ISCC.exe
    goto :inno_found
)

REM Inno Setup not found
echo.
echo ERROR: Inno Setup not found!
echo.
echo Please install Inno Setup 6 from:
echo https://jrsoftware.org/isdl.php
echo.
echo After installation, run this script again.
echo.
pause
exit /b 1

:inno_found
echo.

REM Step 2: Build executable first if needed
echo [2/3] Checking if executable exists...
if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo Executable not found. Building now...
    echo This may take several minutes...
    echo.
    call build.bat --auto
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to build executable!
        pause
        exit /b 1
    )
    echo Build completed!
) else (
    echo Executable found: dist\SonarrSeedr\SonarrSeedr.exe
)
echo.

REM Step 3: Create installers directory
echo [3/3] Building installer...
if not exist "releases\installers" (
    echo Creating releases\installers directory...
    mkdir "releases\installers"
)

REM Update version in installer.iss
echo Updating installer.iss version to %VERSION%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'installer.iss') -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"%VERSION%\"' | Set-Content 'installer.iss'"

REM Build installer
echo Compiling installer (this may take a minute)...
echo.

"%INNO_PATH%" "installer.iss" /Q

if errorlevel 1 (
    echo.
    echo =====================================
    echo ERROR: Installer build failed!
    echo =====================================
    echo.
    echo Check the errors above for details.
    echo.
    pause
    exit /b 1
)

echo.
echo =====================================
echo SUCCESS: Installer created!
echo =====================================
echo.

REM Find the installer file
echo Looking for installer file...
set "INSTALLER_FILE="
for /f "delims=" %%i in ('dir /b /o-d "releases\installers\SonarrSeedr-Setup*.exe" 2^>nul') do (
    set "INSTALLER_FILE=%%i"
    goto :found_installer
)

:found_installer
if not defined INSTALLER_FILE (
    echo [ERROR] Could not find installer file in releases\installers\
    echo.
    dir /b "releases\installers\*.exe"
    echo.
    pause
    exit /b 1
)

set "INSTALLER_PATH=releases\installers\!INSTALLER_FILE!"

echo.
echo =====================================
echo Installer Ready!
echo =====================================
echo.
echo File: !INSTALLER_FILE!
echo Path: !INSTALLER_PATH!
echo.

REM Check file size
for %%A in ("!INSTALLER_PATH!") do echo Size: %%~zA bytes
echo.

REM Ask about GitHub upload
echo =====================================
echo Upload to GitHub?
echo =====================================
echo.
set /p UPLOAD_CHOICE="Do you want to upload this installer to GitHub releases? (y/n): "

if /i not "!UPLOAD_CHOICE!"=="y" (
    echo.
    echo Installer ready at: !INSTALLER_PATH!
    echo.
    echo To test the installer:
    echo   1. Run the installer as Administrator
    echo   2. Complete the installation
    echo   3. Check Windows Settings - Apps and features
    echo.
    pause
    exit /b 0
)

echo.
echo =====================================
echo GitHub Upload
echo =====================================
echo.

REM Check if GitHub CLI is installed
echo Checking for GitHub CLI (gh)...
where gh >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: GitHub CLI (gh) is not installed or not in PATH.
    echo.
    echo Install from: https://cli.github.com/
    echo.
    echo Your installer is ready at: !INSTALLER_PATH!
    echo.
    pause
    exit /b 0
)

echo GitHub CLI found!
echo.

REM Check authentication
echo Checking GitHub authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo You are not logged in to GitHub.
    echo Please run: gh auth login
    echo.
    pause
    exit /b 1
)

echo Authenticated!
echo.

REM Check if release exists
echo Checking for release v%VERSION%...
gh release view "v%VERSION%" --repo jose987654/sonarr-plugin >nul 2>&1

if errorlevel 1 (
    echo.
    echo Release v%VERSION% does not exist on GitHub.
    echo.
    echo Please run release.bat first to create the release.
    echo.
    set /p CREATE_NEW="Create new release now? (y/n): "
    
    if /i not "!CREATE_NEW!"=="y" (
        echo.
        echo Upload cancelled. Installer ready at: !INSTALLER_PATH!
        echo.
        pause
        exit /b 0
    )
    
    echo Creating new release v%VERSION%...
    
    REM Create simple notes
    echo Creating release with installer...
    gh release create "v%VERSION%" "!INSTALLER_PATH!" --title "Version %VERSION%" --notes "Windows Installer for Sonarr-Seedr Integration v%VERSION%" --repo jose987654/sonarr-plugin
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to create release!
        pause
        exit /b 1
    )
    
    echo Release created successfully!
) else (
    echo Found release v%VERSION%!
    echo Uploading installer...
    
    gh release upload "v%VERSION%" "!INSTALLER_PATH!" --repo jose987654/sonarr-plugin --clobber
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to upload installer!
        pause
        exit /b 1
    )
    
    echo Uploaded successfully!
)

echo.
echo ================================================================================
echo                          SUCCESS!
echo ================================================================================
echo.
echo   Version:  v%VERSION%
echo   File:     !INSTALLER_FILE!
echo   URL:      https://github.com/jose987654/sonarr-plugin/releases/tag/v%VERSION%
echo.
echo ================================================================================
echo.
pause
exit /b 0



