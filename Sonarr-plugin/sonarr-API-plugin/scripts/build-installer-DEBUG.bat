@echo off
setlocal enabledelayedexpansion

REM Create debug log file
set "DEBUG_LOG=%~dp0installer-debug.log"
echo ============================================== > "%DEBUG_LOG%"
echo DEBUG LOG - %DATE% %TIME% >> "%DEBUG_LOG%"
echo ============================================== >> "%DEBUG_LOG%"
echo. >> "%DEBUG_LOG%"

REM Function to log and display
call :log "Starting script..."
call :log "Current directory: %CD%"
call :log ""

echo =====================================
echo Building Sonarr-Seedr Installer (DEBUG MODE)
echo =====================================
echo.
echo Debug log: %DEBUG_LOG%
echo.

REM Check if we're in the right directory
call :log "Checking for app\version.py..."
if not exist "app\version.py" (
    call :log "ERROR: app\version.py not found!"
    echo [ERROR] Could not find app\version.py!
    echo Please make sure you are running this from the project root directory.
    echo.
    echo Current directory: %CD%
    call :log "Current directory: %CD%"
    echo.
    echo Check the debug log at: %DEBUG_LOG%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

call :log "Found app\version.py"

REM Read version from version.py
call :log "Reading version from app\version.py..."
set VERSION=1.1.0
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
    set VERLINE=%%a
    call :log "Found version line: %%a"
)

REM Remove quotes and spaces
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%

call :log "Parsed version: %VERSION%"

if "%VERSION%"=="" (
    call :log "ERROR: Version is empty!"
    echo [ERROR] Could not read version from app\version.py!
    echo.
    echo Check the debug log at: %DEBUG_LOG%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo Version: %VERSION%
call :log "Version confirmed: %VERSION%"
echo.

REM Step 1: Check if Inno Setup is installed
echo [1/3] Checking for Inno Setup...
call :log "Checking for Inno Setup..."
set "INNO_PATH="

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    call :log "Found Inno Setup at: C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"
    call :log "Found Inno Setup at: C:\Program Files\Inno Setup 6\ISCC.exe"
) else (
    call :log "ERROR: Inno Setup not found in either location"
    echo.
    echo ERROR: Inno Setup not found!
    echo.
    echo Please install Inno Setup 6 from:
    echo https://jrsoftware.org/isdl.php
    echo.
    echo After installation, run this script again.
    echo.
    echo Check the debug log at: %DEBUG_LOG%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo   Found: !INNO_PATH!
call :log "Inno Setup path: !INNO_PATH!"

REM Step 2: Build executable first if needed
echo.
echo [2/3] Checking if executable exists...
call :log "Checking for dist\SonarrSeedr\SonarrSeedr.exe..."

if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    call :log "Executable not found, need to build it"
    echo   Executable not found. Building now...
    call :log "Calling build.bat --auto"
    call build.bat --auto
    if errorlevel 1 (
        call :log "ERROR: build.bat failed with errorlevel !errorlevel!"
        echo.
        echo ERROR: Failed to build executable!
        echo Check the debug log at: %DEBUG_LOG%
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    call :log "build.bat completed successfully"
) else (
    call :log "Executable found"
    echo   Executable found: dist\SonarrSeedr\SonarrSeedr.exe
)

REM Step 3: Create installers directory
echo.
echo [3/3] Building installer...
call :log "Creating releases\installers directory if needed..."
if not exist "releases\installers" (
    mkdir "releases\installers"
    call :log "Created releases\installers directory"
) else (
    call :log "releases\installers directory already exists"
)

REM Update version in installer.iss
call :log "Updating version in installer.iss to %VERSION%..."
powershell -Command "(Get-Content installer.iss) -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"%VERSION%\"' | Set-Content installer.iss" 2>> "%DEBUG_LOG%"
if errorlevel 1 (
    call :log "ERROR: PowerShell command failed with errorlevel !errorlevel!"
) else (
    call :log "installer.iss version updated successfully"
)

REM Build installer
echo   Compiling installer (this may take a minute)...
call :log "Running Inno Setup compiler..."
call :log "Command: ""!INNO_PATH!"" ""installer.iss"" /Q"

"!INNO_PATH!" "installer.iss" /Q >> "%DEBUG_LOG%" 2>&1
set INNO_ERROR=%errorlevel%

if %INNO_ERROR% NEQ 0 (
    call :log "ERROR: Inno Setup failed with errorlevel %INNO_ERROR%"
    echo.
    echo =====================================
    echo ERROR: Installer build failed!
    echo =====================================
    echo.
    echo Check the errors above for details.
    echo Full debug log at: %DEBUG_LOG%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

call :log "Inno Setup compilation completed successfully"

echo.
echo =====================================
echo SUCCESS: Installer created!
echo =====================================
echo.

REM Find the installer file
call :log "Looking for installer file..."
set "INSTALLER_FILE="
for /f "delims=" %%i in ('dir /b /o-d "releases\installers\SonarrSeedr-Setup*.exe" 2^>nul') do (
    set "INSTALLER_FILE=%%i"
    call :log "Found installer: %%i"
    goto :installer_found
)

:installer_found

if not defined INSTALLER_FILE (
    call :log "ERROR: Could not find installer file in releases\installers\"
    echo [ERROR] Could not find installer file!
    echo Check the debug log at: %DEBUG_LOG%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

set "INSTALLER_PATH=releases\installers\!INSTALLER_FILE!"
call :log "Installer path: !INSTALLER_PATH!"

echo Installer: !INSTALLER_FILE!
echo Location: !INSTALLER_PATH!
echo.

call :log "Installer build completed successfully"
call :log "=============================================="
call :log "Script completed at %TIME%"
call :log "=============================================="

echo.
echo =====================================
echo SUCCESS!
echo =====================================
echo.
echo Your installer is ready at:
echo !INSTALLER_PATH!
echo.
echo Debug log saved to:
echo %DEBUG_LOG%
echo.
echo Press any key to exit...
pause >nul
exit /b 0

REM Logging function
:log
echo %~1
echo %~1 >> "%DEBUG_LOG%"
goto :eof



