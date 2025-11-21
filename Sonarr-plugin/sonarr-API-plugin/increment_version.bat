@echo off
echo.
echo =====================================
echo Version Incrementer
echo =====================================
echo.

cd /d "%~dp0"

if not exist "app\version.py" (
    echo ERROR: app\version.py not found!
    pause
    exit /b 1
)

echo Reading current version...
set "VERSION="
for /f "tokens=2 delims==" %%a in ('type "app\version.py" ^| findstr "__version__"') do set "VERSION=%%a"
set "VERSION=%VERSION: =%"
set "VERSION=%VERSION:"=%"

echo Current version: %VERSION%
echo.

REM Parse version (e.g., 1.1.13)
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
    set "PATCH=%%c"
)

echo What would you like to increment?
echo.
echo 1. Patch (1.1.13 -^> 1.1.14)
echo 2. Minor (1.1.13 -^> 1.2.0)
echo 3. Major (1.1.13 -^> 2.0.0)
echo 4. Cancel
echo.
set /p CHOICE="Enter choice (1-4): "

if "%CHOICE%"=="1" (
    set /a PATCH=%PATCH%+1
    set "NEW_VERSION=%MAJOR%.%MINOR%.%PATCH%"
) else if "%CHOICE%"=="2" (
    set /a MINOR=%MINOR%+1
    set "PATCH=0"
    set "NEW_VERSION=%MAJOR%.%MINOR%.%PATCH%"
) else if "%CHOICE%"=="3" (
    set /a MAJOR=%MAJOR%+1
    set "MINOR=0"
    set "PATCH=0"
    set "NEW_VERSION=%MAJOR%.%MINOR%.%PATCH%"
) else (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo New version: %NEW_VERSION%
echo.
set /p CONFIRM="Update version.py to %NEW_VERSION%? (y/n): "

if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

REM Get current date
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
    set "DATE=%%c-%%a-%%b"
)

REM Update version.py
(
echo """Version information for the Sonarr-Seedr Integration."""
echo __version__ = "%NEW_VERSION%"
echo __build_date__ = "%DATE%"
echo __description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
) > "app\version.py"

echo.
echo =====================================
echo SUCCESS!
echo =====================================
echo.
echo Version updated to: %NEW_VERSION%
echo Date: %DATE%
echo.
echo Next steps:
echo 1. Build the executable: scripts\run-build.bat
echo 2. Build the installer: build_installer.bat
echo.
pause

