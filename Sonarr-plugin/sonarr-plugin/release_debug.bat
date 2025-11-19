@echo off
REM Absolute minimal wrapper - catches EVERYTHING

echo Starting release script...
echo.

REM Run and capture output
call release.bat 2>&1
set RESULT=%ERRORLEVEL%

echo.
echo ================================================================================
echo Script finished with exit code: %RESULT%
echo ================================================================================
echo.
echo Window will stay open. Press any key to close...
pause


