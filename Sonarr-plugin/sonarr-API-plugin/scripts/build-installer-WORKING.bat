@echo off
setlocal enabledelayedexpansion

echo.
echo =====================================
echo Building Sonarr-Seedr Installer
echo =====================================
echo.

REM Change to script directory (handles spaces)
pushd "%~dp0"

echo Current directory: %CD%
echo.

REM Check for version file (with quotes for spaces)
if not exist "app\version.py" (
    echo ERROR: Not in correct directory!
    echo Cannot find: app\version.py
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo Found: app\version.py
echo.

REM Read version
echo Reading version...
set "VERSION="
for /f "usebackq tokens=2 delims==" %%a in ("app\version.py") do (
    set "VERLINE=%%a"
)

REM Remove quotes and spaces
if defined VERLINE (
    set "VERSION=!VERLINE:"=!"
    set "VERSION=!VERSION: =!"
)

if not defined VERSION (
    echo ERROR: Could not read version!
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo Version: !VERSION!
echo.

REM Check for Inno Setup
echo Checking for Inno Setup...
set "INNO="

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "INNO=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "INNO=C:\Program Files\Inno Setup 6\ISCC.exe"
)

if not defined INNO (
    echo ERROR: Inno Setup not found!
    echo.
    echo Install from: https://jrsoftware.org/isdl.php
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo Found: !INNO!
echo.

REM Check for executable
echo Checking for executable...
if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo ERROR: Executable not found!
    echo Please run build.bat first
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo Found: dist\SonarrSeedr\SonarrSeedr.exe
echo.

REM Create output directory
echo Preparing output directory...
if not exist "releases\installers" mkdir "releases\installers"

REM Update version in installer.iss
echo Updating installer.iss version...
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'installer.iss') -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"!VERSION!\"' | Set-Content 'installer.iss'"

if errorlevel 1 (
    echo WARNING: Could not update version in installer.iss
    echo Continuing with existing version...
)
echo.

REM Build installer
echo Building installer...
echo This may take a minute...
echo.

"!INNO!" "installer.iss" /Q

if errorlevel 1 (
    echo.
    echo =====================================
    echo ERROR: Installer build failed!
    echo =====================================
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo.
echo =====================================
echo SUCCESS!
echo =====================================
echo.

REM Find the installer
set "INSTALLER_FILE="
for /f "delims=" %%i in ('dir /b /o-d "releases\installers\SonarrSeedr-Setup*.exe" 2^>nul') do (
    set "INSTALLER_FILE=%%i"
    goto :found_installer
)

:found_installer

if not defined INSTALLER_FILE (
    echo WARNING: Could not find installer file
    echo Check: releases\installers\
    echo.
    pause
    popd
    exit /b 1
)

echo Installer: !INSTALLER_FILE!
echo Location: releases\installers\!INSTALLER_FILE!
echo.

for %%A in ("releases\installers\!INSTALLER_FILE!") do echo Size: %%~zA bytes
echo.

REM Ask about upload
echo =====================================
echo GitHub Upload
echo =====================================
echo.
set /p UPLOAD="Upload to GitHub? (y/n): "

if /i not "!UPLOAD!"=="y" (
    echo.
    echo Done! Installer ready.
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 0
)

echo.
echo Checking for GitHub CLI...
where gh >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: GitHub CLI not found!
    echo Install from: https://cli.github.com/
    echo.
    echo Your installer is ready at: releases\installers\!INSTALLER_FILE!
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 0
)

echo Found: gh
echo.

echo Checking authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Not logged in to GitHub
    echo Run: gh auth login
    echo.
    echo Press any key to exit...
    pause >nul
    popd
    exit /b 1
)

echo Authenticated!
echo.

echo Checking for release v!VERSION!...
gh release view "v!VERSION!" --repo jose987654/sonarr-plugin >nul 2>&1

if errorlevel 1 (
    echo.
    echo Release v!VERSION! not found
    echo.
    set /p CREATE="Create new release? (y/n): "
    
    if /i not "!CREATE!"=="y" (
        echo.
        echo Upload cancelled
        echo.
        echo Press any key to exit...
        pause >nul
        popd
        exit /b 0
    )
    
    echo.
    echo Creating release v!VERSION!...
    gh release create "v!VERSION!" "releases\installers\!INSTALLER_FILE!" --title "Version !VERSION!" --notes "Windows Installer for v!VERSION!" --repo jose987654/sonarr-plugin
    
    if errorlevel 1 (
        echo ERROR: Failed to create release!
        pause
        popd
        exit /b 1
    )
    
    echo Release created!
) else (
    echo Found release v!VERSION!
    echo.
    echo Uploading installer...
    gh release upload "v!VERSION!" "releases\installers\!INSTALLER_FILE!" --repo jose987654/sonarr-plugin --clobber
    
    if errorlevel 1 (
        echo ERROR: Upload failed!
        pause
        popd
        exit /b 1
    )
    
    echo Uploaded!
)

echo.
echo ================================================================================
echo                          SUCCESS!
echo ================================================================================
echo.
echo   Version:  v!VERSION!
echo   File:     !INSTALLER_FILE!
echo   URL:      https://github.com/jose987654/sonarr-plugin/releases/tag/v!VERSION!
echo.
echo ================================================================================
echo.
echo Press any key to exit...
pause >nul
popd
exit /b 0



