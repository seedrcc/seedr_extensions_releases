@echo off
echo.
echo =====================================
echo Building Installer
echo =====================================
echo.

REM Change to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Check for version file
if not exist "app\version.py" (
    echo ERROR: Not in correct directory!
    echo Cannot find app\version.py
    echo.
    echo Press any key to exit...
    pause >nul
    exit
)

echo Found: app\version.py
echo.

REM Read version
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do set VERLINE=%%a
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%

echo Version: %VERSION%
echo.

REM Check for Inno Setup
set "INNO="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "INNO=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set "INNO=C:\Program Files\Inno Setup 6\ISCC.exe"

if not defined INNO (
    echo ERROR: Inno Setup not found!
    echo Install from: https://jrsoftware.org/isdl.php
    echo.
    echo Press any key to exit...
    pause >nul
    exit
)

echo Found Inno Setup
echo.

REM Check for executable
if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo ERROR: Executable not found!
    echo Please run build.bat first
    echo.
    echo Press any key to exit...
    pause >nul
    exit
)

echo Found executable
echo.

REM Create output directory
if not exist "releases\installers" mkdir "releases\installers"

REM Update version in installer.iss
echo Updating installer.iss...
powershell -Command "(Get-Content installer.iss) -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"%VERSION%\"' | Set-Content installer.iss"

REM Build installer
echo Building installer...
echo.
"%INNO%" "installer.iss" /Q

if errorlevel 1 (
    echo.
    echo ERROR: Build failed!
    echo.
    echo Press any key to exit...
    pause >nul
    exit
)

echo.
echo =====================================
echo SUCCESS!
echo =====================================
echo.
echo Installer created in: releases\installers\
echo.
dir /b releases\installers\SonarrSeedr-Setup*.exe
echo.
echo Press any key to exit...
pause >nul



