@echo off
REM Critical: Set up error handling FIRST before anything else
setlocal enabledelayedexpansion

REM Trap any unhandled errors
if not defined RELEASE_DEBUG (
    set "RELEASE_DEBUG=1"
    call "%~f0" %*
    set EXIT_CODE=%ERRORLEVEL%
    echo.
    echo ================================================================================
    if %EXIT_CODE%==0 (
        echo Script completed successfully!
    ) else (
        echo Script exited with code: %EXIT_CODE%
    )
    echo ================================================================================
    echo.
    echo Press any key to close...
    pause >nul
    exit /b %EXIT_CODE%
)

echo ================================================================================
echo                    AUTOMATED BUILD AND GITHUB RELEASE
echo ================================================================================
echo.

REM Step 1: Read version from version.py
echo [1/6] Reading version information...
set VERSION=1.1.0

REM Check if version.py exists
if not exist "app\version.py" (
    echo [ERROR] Could not find app\version.py!
    echo Please make sure you are running this from the project root directory.
    echo.
    pause
    exit /b 1
)

for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
    set VERLINE=%%a
)
REM Remove quotes and spaces
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%

if "%VERSION%"=="" (
    echo [ERROR] Could not read version from app\version.py!
    echo.
    pause
    exit /b 1
)

echo   Current Version: v%VERSION%
echo.

REM Step 2: Ask for release type
echo [2/6] What type of release is this?
echo   1. Major (breaking changes) - 1.0.0 -^> 2.0.0
echo   2. Minor (new features)     - 1.1.0 -^> 1.2.0
echo   3. Patch (bug fixes)        - 1.1.0 -^> 1.1.1
echo   4. Use current version (%VERSION%)
echo   5. Custom version
echo.
set /p RELEASE_TYPE="Enter choice (1-5): "

if "%RELEASE_TYPE%"=="1" (
    REM Parse current version and increment major
    for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
        set /a MAJOR=%%a+1
        set NEW_VERSION=!MAJOR!.0.0
    )
) else if "%RELEASE_TYPE%"=="2" (
    REM Parse current version and increment minor
    for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
        set MAJOR=%%a
        set /a MINOR=%%b+1
        set NEW_VERSION=!MAJOR!.!MINOR!.0
    )
) else if "%RELEASE_TYPE%"=="3" (
    REM Parse current version and increment patch
    for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
        set MAJOR=%%a
        set MINOR=%%b
        set /a PATCH=%%c+1
        set NEW_VERSION=!MAJOR!.!MINOR!.!PATCH!
    )
) else if "%RELEASE_TYPE%"=="4" (
    set NEW_VERSION=%VERSION%
) else if "%RELEASE_TYPE%"=="5" (
    set /p NEW_VERSION="Enter version (e.g., 1.2.0): "
) else (
    echo Invalid choice. Exiting.
    pause
    exit /b 1
)

echo.
echo   New Version: v!NEW_VERSION!
echo.

REM Step 3: Update version.py
echo [3/6] Updating version.py...
set BUILD_DATE=%date:~-4%-%date:~-10,2%-%date:~-7,2%

REM Create temporary file with new version
(
    echo """Version information for the Sonarr-Seedr Integration."""
    echo __version__ = "!NEW_VERSION!"
    echo __build_date__ = "!BUILD_DATE!"
    echo __description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
) > app\version.py.tmp

REM Replace old version.py
move /y app\version.py.tmp app\version.py >nul 2>&1
echo   Updated to v!NEW_VERSION!
echo.

REM Step 4: Ask for release notes
echo [4/6] Enter release notes (what's new in this version):
echo   Type your changes, one per line. Type 'done' when finished.
echo   Example:
echo     - Added auto-update feature
echo     - Fixed bug with downloads
echo     - Improved performance
echo.

set RELEASE_NOTES=## What's New in v!NEW_VERSION!^

^

set LINE_COUNT=0

:input_loop
set /p INPUT_LINE="  - "
if /i "%INPUT_LINE%"=="done" goto :done_input
if /i "%INPUT_LINE%"=="" goto :input_loop
set RELEASE_NOTES=!RELEASE_NOTES!- %INPUT_LINE%^

^

set /a LINE_COUNT+=1
goto :input_loop

:done_input

if %LINE_COUNT%==0 (
    set RELEASE_NOTES=## What's New in v!NEW_VERSION!^

^

- Bug fixes and improvements
)

echo.
echo   Release notes captured.
echo.

REM Step 5: Run build.bat
echo [5/6] Running build process...
echo   This may take several minutes...
echo.

REM Clear Python cache to ensure fresh build
if exist "app\__pycache__" rmdir /s /q "app\__pycache__" 2>nul
for /r "app" %%f in (*.pyc) do del "%%f" 2>nul

REM Call build.bat with --auto flag to skip pause
call build.bat --auto

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed! Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo   Build completed successfully!
echo.

REM Step 6: Find the ZIP file
echo [6/6] Preparing GitHub release...

REM First try to find ZIP with new version (sort by date, newest first)
for /f "delims=" %%i in ('dir /b /o-d releases\SonarrSeedr-v!NEW_VERSION!*.zip 2^>nul') do (
    set ZIP_FILE=%%i
    goto :zip_found
)

:zip_found
REM If not found, get the most recent ZIP (newest first)
if not defined ZIP_FILE (
    echo   Looking for most recent build...
    for /f "delims=" %%i in ('dir /b /o-d releases\SonarrSeedr*.zip 2^>nul') do (
        set ZIP_FILE=%%i
        goto :zip_found2
    )
)

:zip_found2

if not defined ZIP_FILE (
    echo [ERROR] Could not find any ZIP file in releases folder!
    echo Build may have failed!
    pause
    exit /b 1
)

set ZIP_PATH=releases\%ZIP_FILE%

REM Warn if version mismatch
echo %ZIP_FILE% | findstr /C:"v!NEW_VERSION!" >nul
if errorlevel 1 (
    echo.
    echo   [WARNING] ZIP file version mismatch!
    echo   Expected: v!NEW_VERSION!
    echo   Found:    %ZIP_FILE%
    echo.
    set /p CONTINUE="  Continue with this file? (y/n): "
    if /i not "!CONTINUE!"=="y" (
        echo.
        echo   Release cancelled.
        pause
        exit /b 1
    )
)

echo   Found: %ZIP_FILE%
echo.

REM Step 7: Check if GitHub CLI is installed
echo Checking for GitHub CLI (gh)...
where gh >nul 2>&1
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo                          GITHUB CLI NOT FOUND
    echo ================================================================================
    echo.
    echo The GitHub CLI (gh) is not installed or not in PATH.
    echo.
    echo OPTION 1: Install GitHub CLI (Recommended)
    echo   1. Download from: https://cli.github.com/
    echo   2. Install and restart this script
    echo   3. Run: gh auth login
    echo.
    echo OPTION 2: Manual Release
    echo   1. Go to: https://github.com/jose987654/sonarr-plugin/releases/new
    echo   2. Tag: v!NEW_VERSION!
    echo   3. Title: Version !NEW_VERSION!
    echo   4. Upload: %ZIP_PATH%
    echo   5. Publish release
    echo.
    echo ================================================================================
    echo.
    echo Your build is ready at: %ZIP_PATH%
    echo.
    pause
    exit /b 0
)

echo   GitHub CLI found!
echo.

REM Step 8: Check if authenticated
echo Checking GitHub authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo You are not logged in to GitHub.
    echo Please run: gh auth login
    echo.
    echo Then run this script again.
    pause
    exit /b 1
)

echo   Authenticated!
echo.

REM Step 9: Commit version change
echo Committing version change...
git add app\version.py
git commit -m "Release v!NEW_VERSION!" >nul 2>&1
echo   Committed!
echo.

REM Step 10: Create git tag (delete if exists)
echo Creating git tag v!NEW_VERSION!...

REM Delete local tag if exists
git tag -d "v!NEW_VERSION!" >nul 2>&1

REM Delete remote tag if exists  
git push origin --delete "v!NEW_VERSION!" >nul 2>&1

REM Create new tag
git tag -a "v!NEW_VERSION!" -m "Release v!NEW_VERSION!"
echo   Tag created!
echo.

REM Step 11: Push changes and tags
echo Pushing to GitHub...
git push origin main
git push origin "v!NEW_VERSION!"
echo   Pushed!
echo.

REM Step 12: Create GitHub release with notes file
echo Creating GitHub release...

REM Write release notes to temporary file
set NOTES_FILE=release_notes_temp.txt
echo ## WARNING: Download Instructions> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo **DOWNLOAD THIS FILE ONLY:**>> "!NOTES_FILE!"
echo ### `%ZIP_FILE%`>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo **DO NOT download "Source code (zip)" or "Source code (tar.gz)"**>> "!NOTES_FILE!"
echo Those are auto-generated by GitHub and are NOT the application!>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo --->> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo ## What's New in v!NEW_VERSION!>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo !RELEASE_NOTES!>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo --->> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo ## Installation Steps>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo 1. **Download**: Click on `%ZIP_FILE%` above (NOT source code!)>> "!NOTES_FILE!"
echo 2. **Extract**: Unzip to your installation folder>> "!NOTES_FILE!"
echo 3. **Run**: Double-click `SonarrSeedr.exe`>> "!NOTES_FILE!"
echo 4. **Done!** The app will start on http://localhost:8242>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo --->> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo ## For Existing Users (Updating)>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo Simply extract to your existing folder and overwrite files.>> "!NOTES_FILE!"
echo Your settings will be preserved automatically!>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo Or use the **one-click auto-update** from the Settings page!>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo --->> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo ## Need Help?>> "!NOTES_FILE!"
echo.>> "!NOTES_FILE!"
echo - See `SIMPLE_USAGE.md` in the ZIP for setup instructions>> "!NOTES_FILE!"
echo - Check `HOW_TO_USE.txt` for quick start guide>> "!NOTES_FILE!"
echo - Issues? Open a ticket on GitHub!>> "!NOTES_FILE!"

REM Check if release already exists
echo Checking for existing release...
gh release view "v!NEW_VERSION!" --repo jose987654/sonarr-plugin >nul 2>&1

if not errorlevel 1 (
    echo   Release v!NEW_VERSION! already exists. Deleting old release...
    gh release delete "v!NEW_VERSION!" --repo jose987654/sonarr-plugin --yes >nul 2>&1
    if not errorlevel 1 (
        echo   Old release deleted!
    )
    REM Small delay to ensure deletion completes
    timeout /t 2 /nobreak >nul
)

REM Create release with file upload (on sonarr-plugin repo for releases)
gh release create "v!NEW_VERSION!" "%ZIP_PATH%" ^
    --title "Version !NEW_VERSION!" ^
    --notes-file "!NOTES_FILE!" ^
    --repo jose987654/sonarr-plugin

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to create GitHub release!
    echo.
    echo Please create the release manually:
    echo   1. Go to: https://github.com/jose987654/sonarr-plugin/releases/new
    echo   2. Tag: v!NEW_VERSION!
    echo   3. Upload: %ZIP_PATH%
    echo.
    del "!NOTES_FILE!" >nul 2>&1
    pause
    exit /b 1
)

REM Clean up temp file
del "!NOTES_FILE!" >nul 2>&1

echo.
echo ================================================================================
echo                          SUCCESS! RELEASE PUBLISHED
echo ================================================================================
echo.
echo   Version:  v!NEW_VERSION!
echo   ZIP File: %ZIP_FILE%
echo   Size:     
for %%A in ("%ZIP_PATH%") do echo   %%~zA bytes
echo.
echo   Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v!NEW_VERSION!
echo.
echo   Users can now update with one click from the Settings page!
echo.
echo ================================================================================
echo.
goto :end_script

:end_script
echo.
echo Press any key to close this window...
pause >nul
exit /b 0
