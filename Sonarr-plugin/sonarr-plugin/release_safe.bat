@echo off
REM Safe wrapper for release.bat - catches any crashes

echo ================================================================================
echo                    SAFE RELEASE LAUNCHER
echo ================================================================================
echo.
echo This wrapper will catch any errors and prevent the window from closing.
echo.
pause

REM Run the actual release script
call release.bat

REM Capture the exit code
set RELEASE_EXIT_CODE=%ERRORLEVEL%

echo.
echo ================================================================================
if %RELEASE_EXIT_CODE%==0 (
    echo                          RELEASE COMPLETED SUCCESSFULLY
) else (
    echo                          RELEASE FAILED (Exit Code: %RELEASE_EXIT_CODE%)
)
echo ================================================================================
echo.

REM Always pause at the end
echo Press any key to close this window...
pause >nul


