@echo off
echo Starting build in a new window...
echo.
start cmd /k "cd /d "%~dp0" && build.bat && echo. && echo BUILD COMPLETE - You can close this window now && echo."
echo.
echo Build started in a new window!
echo Press any key to close this launcher...
pause > nul

