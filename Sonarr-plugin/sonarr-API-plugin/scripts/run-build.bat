@echo off
echo ================================
echo Sonarr-Seedr Build Wrapper
echo ================================
echo.
echo This window will stay open to show you all output.
echo.
pause

REM Run the build script
call build.bat

echo.
echo.
echo ================================
echo Build process completed!
echo ================================
echo.
echo Check above for any errors.
echo.
echo Press any key to close this window...
pause > nul
exit

