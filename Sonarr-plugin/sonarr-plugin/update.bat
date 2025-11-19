@echo off
REM SonarrSeedr Update Script
REM This helps users update to a new version safely

echo ============================================
echo   SonarrSeedr Update Assistant
echo ============================================
echo.

REM Check if running from correct location
if not exist "SonarrSeedr.exe" (
    echo ERROR: This script must be run from the SonarrSeedr folder!
    echo Current location: %CD%
    echo.
    echo Please:
    echo 1. Copy this update.bat to your SonarrSeedr folder
    echo 2. Run it from there
    echo.
    pause
    exit /b 1
)

REM Show current version
if exist "VERSION.txt" (
    echo Current Version:
    type VERSION.txt
    echo.
) else (
    echo Current Version: Unknown
    echo.
)

echo ============================================
echo   Update Instructions
echo ============================================
echo.
echo STEP 1: Stop the current version
echo   - Right-click tray icon ^> Quit
echo   - OR close from Task Manager
echo.

REM Check if app is running
tasklist /FI "IMAGENAME eq SonarrSeedr.exe" 2>NUL | find /I /N "SonarrSeedr.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [WARNING] SonarrSeedr.exe is currently RUNNING!
    echo.
    choice /C YN /M "Do you want me to stop it now"
    if errorlevel 2 goto MANUAL_STOP
    if errorlevel 1 goto AUTO_STOP
    
    :AUTO_STOP
    echo.
    echo Stopping SonarrSeedr...
    taskkill /F /IM SonarrSeedr.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo   Stopped successfully!
    goto BACKUP
    
    :MANUAL_STOP
    echo.
    echo Please stop SonarrSeedr manually, then press any key...
    pause >nul
) else (
    echo [OK] SonarrSeedr is not running.
)

:BACKUP
echo.
echo STEP 2: Backup your configuration (optional but recommended)
echo.
choice /C YN /M "Do you want to backup your config folder"
if errorlevel 2 goto SKIP_BACKUP
if errorlevel 1 goto DO_BACKUP

:DO_BACKUP
echo.
echo Creating backup...

REM Create backup folder with timestamp
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FOLDER=config_backup_%TIMESTAMP%

if exist "config" (
    xcopy "config" "%BACKUP_FOLDER%\" /E /I /H /Y >nul 2>&1
    echo   Backup created: %BACKUP_FOLDER%\
) else (
    echo   No config folder found (this is okay for first-time setup)
)
goto UPDATE

:SKIP_BACKUP
echo   Skipping backup...
goto UPDATE

:UPDATE
echo.
echo STEP 3: Install the new version
echo ============================================
echo.
echo TO UPDATE:
echo 1. Download the new version ZIP file
echo 2. Extract it
echo 3. Copy ALL files from extracted folder to THIS folder
echo 4. Choose "Yes" when asked to overwrite files
echo.
echo YOUR SETTINGS WILL BE PRESERVED!
echo (They are in the 'config' folder which won't be deleted)
echo.
echo ============================================
echo.
echo After copying the new files, press any key to start the app...
pause >nul

REM Start the updated version
if exist "SonarrSeedr.exe" (
    echo.
    echo Starting updated version...
    start "" "SonarrSeedr.exe"
    timeout /t 2 /nobreak >nul
    echo.
    echo ============================================
    echo   Update Complete!
    echo ============================================
    echo.
    echo The app should now be running.
    echo.
    echo Check:
    echo   - Browser should open to http://localhost:8242
    echo   - Tray icon should appear near clock
    echo   - Your settings should still be there
    echo.
    echo If you have issues, run debug.bat to see errors.
    echo.
) else (
    echo.
    echo ERROR: SonarrSeedr.exe not found!
    echo Make sure you copied all files from the new version.
    echo.
)

pause

