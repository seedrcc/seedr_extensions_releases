@echo off
REM Quick Start Script for SonarrSeedr
REM This shows a brief message then starts the app

echo ================================================
echo   Starting SonarrSeedr...
echo ================================================
echo.
echo   1. App will run in background (no console)
echo   2. Browser will open to http://localhost:8242
echo   3. Look for icon in system tray (near clock)
echo   4. Right-click icon for menu options
echo.
echo   Starting in 2 seconds...
echo ================================================
timeout /t 2 /nobreak >nul

REM Start the application
start "" "dist\SonarrSeedr\SonarrSeedr.exe"

echo.
echo App started! Check your browser and system tray.
echo.
timeout /t 3 /nobreak >nul

