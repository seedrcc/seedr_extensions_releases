@echo off
echo ================================================================================
echo                    BUILD AND MANUAL RELEASE HELPER
echo ================================================================================
echo.
echo This script will:
echo   1. Build your app
echo   2. Open GitHub releases page in browser
echo   3. You manually upload the ZIP file
echo.
pause

REM Step 1: Read version
echo [1/3] Reading current version...
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
    set VERLINE=%%a
)
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%
echo   Current Version: v%VERSION%
echo.

REM Step 2: Build
echo [2/3] Building application...
echo   This may take several minutes...
echo.
call build.bat

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo   Build completed!
echo.

REM Step 3: Find ZIP
echo [3/3] Locating ZIP file...
for /f "delims=" %%i in ('dir /b /od releases\SonarrSeedr*.zip 2^>nul') do set ZIP_FILE=%%i

if not defined ZIP_FILE (
    echo [ERROR] Could not find ZIP file in releases folder!
    pause
    exit /b 1
)

set ZIP_PATH=releases\%ZIP_FILE%
echo   Found: %ZIP_FILE%
echo.

echo ================================================================================
echo                          BUILD COMPLETE!
echo ================================================================================
echo.
echo Your ZIP file is ready at:
echo   %ZIP_PATH%
echo.
echo File size:
for %%A in ("%ZIP_PATH%") do echo   %%~zA bytes
echo.
echo ================================================================================
echo.
echo NEXT STEPS:
echo.
echo 1. The GitHub releases page will open in your browser
echo 2. Click "Create a new release"
echo 3. Enter tag: v%VERSION%
echo 4. Enter title: Version %VERSION%
echo 5. Drag and drop: %ZIP_FILE%
echo 6. Write release notes (what's new)
echo 7. Click "Publish release"
echo.
echo ================================================================================
echo.
set /p OPEN_BROWSER="Open GitHub releases page now? (y/n): "

if /i "%OPEN_BROWSER%"=="y" (
    echo.
    echo Opening browser...
    start https://github.com/jose987654/sonarr-plugin/releases/new
    echo.
    echo Also opening releases folder...
    start "" "%CD%\releases"
)

echo.
echo Press any key to close...
pause >nul


