@echo off
cd /d "%~dp0"
cd ..

echo ================================
echo Sonarr-Seedr Build Wrapper
echo ================================
echo.
echo Current directory: %CD%
echo.

REM Run the build script
call "scripts\build.bat"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ================================
echo Build process completed!
echo ================================
echo.
echo Check above for any errors.
echo.
pause

