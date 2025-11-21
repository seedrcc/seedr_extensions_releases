@echo off
echo.
echo ========================================
echo Kodi Plugin ZIP Generator
echo ========================================
echo.

cd /d "%~dp0"

if not exist "plugin.video.seedr" (
    echo ERROR: plugin.video.seedr folder not found!
    echo Make sure you run this from Kodi-plugin folder.
    pause
    exit /b 1
)

if not exist "repository.seedr" (
    echo ERROR: repository.seedr folder not found!
    pause
    exit /b 1
)

if not exist "create_release.py" (
    echo ERROR: create_release.py not found!
    pause
    exit /b 1
)

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found!
    pause
    exit /b 1
)

echo Creating release package...
echo.

python "create_release.py"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Script failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS!
echo ========================================
echo.
pause
