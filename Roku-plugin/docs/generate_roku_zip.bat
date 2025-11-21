@echo off
echo.
echo ========================================
echo Roku Plugin ZIP Generator
echo ========================================
echo.

cd /d "%~dp0"
cd ..

if not exist "manifest" (
    echo ERROR: manifest not found!
    echo Make sure you run this from Roku-plugin folder.
    pause
    exit /b 1
)

if not exist "components" (
    echo ERROR: components folder not found!
    pause
    exit /b 1
)

if not exist "docs\compress_project.py" (
    echo ERROR: docs\compress_project.py not found!
    pause
    exit /b 1
)

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found!
    pause
    exit /b 1
)

echo Running compression script...
echo.

python "docs\compress_project.py"

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
