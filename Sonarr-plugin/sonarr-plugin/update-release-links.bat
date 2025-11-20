@echo off
REM Windows batch script to update release links
REM Usage: update-release-links.bat [GITHUB_TOKEN]

echo ========================================
echo  Update Release Links Script
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    pause
    exit /b 1
)

REM Check if requests library is installed
python -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo Installing requests library...
    pip install requests
    if errorlevel 1 (
        echo ERROR: Failed to install requests library
        pause
        exit /b 1
    )
)

REM Run the Python script
if "%1"=="" (
    python update-release-links.py
) else (
    python update-release-links.py %1
)

if errorlevel 1 (
    echo.
    echo ERROR: Script failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Script completed successfully!
echo ========================================
pause

