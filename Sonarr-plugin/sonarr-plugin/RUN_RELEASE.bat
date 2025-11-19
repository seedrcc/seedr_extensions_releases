@echo off
REM Ultra-simple launcher that CANNOT close without showing errors

title Release Script Debug
color 0A

echo.
echo ============================================================
echo    RELEASE SCRIPT LAUNCHER
echo ============================================================
echo.
echo This launcher will catch ALL errors and keep window open.
echo.
pause

echo.
echo Starting release.bat...
echo.

REM Use PowerShell version (much better error handling)
powershell.exe -ExecutionPolicy Bypass -File release.ps1

echo.
echo ============================================================
echo    Script execution completed
echo ============================================================
echo.
echo Press ANY key to close this window...
pause >nul


