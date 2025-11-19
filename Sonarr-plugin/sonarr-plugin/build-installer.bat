@echo off
setlocal enabledelayedexpansion

echo =====================================
echo Building Sonarr-Seedr Installer
echo =====================================
echo.

REM Check if we're in the right directory
if not exist "app\version.py" (
    echo [ERROR] Could not find app\version.py!
    echo Please make sure you are running this from the project root directory.
    echo.
    echo Current directory: %CD%
    echo.
    goto :end_with_error
)

REM Read version from version.py
set VERSION=1.1.0
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
    set VERLINE=%%a
)
REM Remove quotes and spaces
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%

if "%VERSION%"=="" (
    echo [ERROR] Could not read version from app\version.py!
    echo.
    goto :end_with_error
)

echo Version: %VERSION%
echo.

REM Step 1: Check if Inno Setup is installed
echo [1/3] Checking for Inno Setup...
set "INNO_PATH="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "INNO_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"
) else (
    echo.
    echo ERROR: Inno Setup not found!
    echo.
    echo Please install Inno Setup 6 from:
    echo https://jrsoftware.org/isdl.php
    echo.
    echo After installation, run this script again.
    echo.
    goto :end_with_error
)

echo   Found: !INNO_PATH!

REM Step 2: Build executable first if needed
echo.
echo [2/3] Checking if executable exists...
if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo   Executable not found. Building now...
    call build.bat --auto
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to build executable!
        goto :end_with_error
    )
) else (
    echo   Executable found: dist\SonarrSeedr\SonarrSeedr.exe
)

REM Step 3: Create installers directory
echo.
echo [3/3] Building installer...
if not exist "releases\installers" mkdir "releases\installers"

REM Update version in installer.iss
powershell -Command "(Get-Content installer.iss) -replace '#define MyAppVersion \".*\"', '#define MyAppVersion \"%VERSION%\"' | Set-Content installer.iss"

REM Build installer
echo   Compiling installer (this may take a minute)...
"!INNO_PATH!" "installer.iss" /Q

if errorlevel 1 (
    echo.
    echo =====================================
    echo ERROR: Installer build failed!
    echo =====================================
    echo.
    echo Check the errors above for details.
    echo.
    goto :end_with_error
)

echo.
echo =====================================
echo SUCCESS: Installer created!
echo =====================================
echo.

REM Find the installer file
set "INSTALLER_FILE="
for /f "delims=" %%i in ('dir /b /o-d "releases\installers\SonarrSeedr-Setup*.exe" 2^>nul') do (
    set "INSTALLER_FILE=%%i"
    goto :installer_found
)

:installer_found

if not defined INSTALLER_FILE (
    echo [ERROR] Could not find installer file!
    goto :end_with_error
)

set "INSTALLER_PATH=releases\installers\!INSTALLER_FILE!"

echo Installer: !INSTALLER_FILE!
echo Location: !INSTALLER_PATH!
echo.

REM Step 4: Ask if user wants to upload to GitHub
echo =====================================
echo Upload to GitHub?
echo =====================================
echo.
set /p UPLOAD_CHOICE="Do you want to upload this installer to GitHub releases? (y/n): "

if /i not "!UPLOAD_CHOICE!"=="y" (
    echo.
    echo Installer ready at: !INSTALLER_PATH!
    echo.
    echo To test the installer:
    echo   1. Run the installer as Administrator
    echo   2. Complete the installation
    echo   3. Check Windows Settings ^> Apps ^& features
    echo.
    goto :end_success
)

echo.
echo =====================================
echo GitHub Upload
echo =====================================
echo.

REM Step 5: Check if GitHub CLI is installed
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
    echo OPTION 2: Manual Upload
    echo   1. Go to: https://github.com/jose987654/sonarr-plugin/releases
    echo   2. Edit the latest release (v%VERSION%)
    echo   3. Upload: !INSTALLER_PATH!
    echo   4. Save release
    echo.
    echo ================================================================================
    echo.
    echo Your installer is ready at: !INSTALLER_PATH!
    echo.
    goto :end_success
)

echo   GitHub CLI found!
echo.

REM Step 6: Check if authenticated
echo Checking GitHub authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo You are not logged in to GitHub.
    echo Please run: gh auth login
    echo.
    echo Then run this script again.
    goto :end_with_error
)

echo   Authenticated!
echo.

REM Step 7: Check if release exists for this version
echo Checking for release v%VERSION%...
gh release view "v%VERSION%" --repo jose987654/sonarr-plugin >nul 2>&1

if errorlevel 1 (
    echo.
    echo [WARNING] Release v%VERSION% does not exist on GitHub.
    echo.
    echo Please run release.bat first to create the release with the ZIP file,
    echo then run this script to add the installer.
    echo.
    echo Alternatively, you can create a new release now.
    echo.
    set /p CREATE_RELEASE="Create new release v%VERSION% now? (y/n): "
    
    if /i not "!CREATE_RELEASE!"=="y" (
        echo.
        echo Upload cancelled. Your installer is ready at: !INSTALLER_PATH!
        echo.
        goto :end_success
    )
    
    echo.
    echo Creating new release v%VERSION%...
    
    REM Create minimal release notes
    set "NOTES_FILE=installer_notes_temp.txt"
    (
        echo ## Sonarr-Seedr Integration v%VERSION%
        echo.
        echo ### Download Options
        echo.
        echo **Option 1: Installer (Recommended for Windows^)**
        echo - Download: `!INSTALLER_FILE!`
        echo - Easy installation with Start Menu shortcuts
        echo - Automatic uninstaller
        echo.
        echo **Option 2: Portable ZIP**
        echo - Download: `SonarrSeedr-v%VERSION%.zip`
        echo - No installation required
        echo - Extract and run
        echo.
        echo ---
        echo.
        echo **DO NOT download "Source code" files - they are not the application!**
    ) > "!NOTES_FILE!"
    
    REM Create release with installer
    gh release create "v%VERSION%" "!INSTALLER_PATH!" --title "Version %VERSION%" --notes-file "!NOTES_FILE!" --repo jose987654/sonarr-plugin
    
    del "!NOTES_FILE!" >nul 2>&1
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to create release!
        goto :end_with_error
    )
    
    echo   Release created!
) else (
    echo   Found release v%VERSION%!
    echo.
    echo Uploading installer to existing release...
    
    REM Upload installer to existing release
    gh release upload "v%VERSION%" "!INSTALLER_PATH!" --repo jose987654/sonarr-plugin --clobber
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to upload installer!
        echo.
        echo You can upload manually:
        echo   1. Go to: https://github.com/jose987654/sonarr-plugin/releases/tag/v%VERSION%
        echo   2. Click "Edit release"
        echo   3. Drag and drop: !INSTALLER_PATH!
        echo   4. Click "Update release"
        echo.
        goto :end_with_error
    )
    
    echo   Uploaded successfully!
)

echo.
echo ================================================================================
echo                          SUCCESS! INSTALLER UPLOADED
echo ================================================================================
echo.
echo   Version:       v%VERSION%
echo   Installer:     !INSTALLER_FILE!
for %%A in ("!INSTALLER_PATH!") do echo   Size:          %%~zA bytes
echo.
echo   Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v%VERSION%
echo.
echo   Users can now download either:
echo     - Installer (.exe) - Easy Windows installation
echo     - Portable ZIP     - No installation required
echo.
echo ================================================================================
echo.
goto :end_success

:end_with_error
echo.
echo ================================================================================
echo Script finished with errors!
echo ================================================================================
echo.
pause
exit /b 1

:end_success
echo.
echo ================================================================================
echo Script completed successfully!
echo ================================================================================
echo.
pause
exit /b 0
