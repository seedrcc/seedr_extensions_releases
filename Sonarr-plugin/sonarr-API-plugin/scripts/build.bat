@echo off
setlocal enabledelayedexpansion

REM Check if we're being called from another script (no pause needed)
set "AUTO_MODE=%~1"

echo ================================
echo Building Sonarr-Seedr Executable
echo ================================

echo.
echo [0/5] Reading version information...

REM Read version from version.py
set VERSION=1.1.0
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
    set VERLINE=%%a
)
REM Remove quotes and spaces
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%

echo   Current version: %VERSION%

REM Check if ZIP already exists in Plugin Zips - use absolute path
set "SCRIPT_DIR=%~dp0"
set "PLUGIN_ZIPS_DIR=%SCRIPT_DIR%..\..\..\Plugin Zips\Sonarr\zip"
if not exist "%PLUGIN_ZIPS_DIR%" mkdir "%PLUGIN_ZIPS_DIR%"

REM Check for existing ZIP with this version
for /f "delims=" %%i in ('dir /b "%PLUGIN_ZIPS_DIR%\SonarrSeedr-v%VERSION%-*.zip" 2^>nul') do (
    echo   Found existing build for v%VERSION%
    echo   Auto-incrementing version...
    
    REM Parse and increment version
    for /f "tokens=1-3 delims=." %%a in ("!VERSION!") do (
        set "MAJOR=%%a"
        set "MINOR=%%b"  
        set "PATCH=%%c"
    )
    
    set /a "PATCH=!PATCH!+1"
    set "VERSION=!MAJOR!.!MINOR!.!PATCH!"
    
    REM Update version.py
    for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
    set "YEAR=!dt:~0,4!"
    set "MONTH=!dt:~4,2!"
    set "DAY=!dt:~6,2!"
    set "DATE=!YEAR!-!MONTH!-!DAY!"
    
    (
    echo """Version information for the Sonarr-Seedr Integration."""
    echo __version__ = "!VERSION!"
    echo __build_date__ = "!DATE!"
    echo __description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
    ) > "app\version.py"
    
    echo   New version: !VERSION!
    goto :version_done
)

:version_done
echo   Building version: %VERSION%

REM Generate timestamp
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BUILD_DATE=%date:~-4%-%date:~-10,2%-%date:~-7,2%
set BUILD_NAME=SonarrSeedr-v%VERSION%-%TIMESTAMP%

echo   Build Name: %BUILD_NAME%
echo   Build Date: %BUILD_DATE%

echo.
echo [1/5] Cleaning previous build...
if exist "dist" rmdir /s /q "dist" 2>nul
if exist "build" rmdir /s /q "build" 2>nul

echo.
echo [2/5] Creating necessary directories...
if not exist "config" mkdir "config"
if not exist "completed" mkdir "completed"
if not exist "processed" mkdir "processed"
if not exist "error" mkdir "error"
if not exist "torrents" mkdir "torrents"
if not exist "releases" mkdir "releases"

echo.
echo [3/5] Building executable with PyInstaller...
echo This may take several minutes...
echo.

pyinstaller sonarr_seedr.spec --clean --noconfirm

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ================================
    echo ERROR: PyInstaller failed!
    echo ================================
    echo.
    echo Possible solutions:
    echo   1. Install PyInstaller: pip install pyinstaller
    echo   2. Install requirements: pip install -r requirements.txt
    echo   3. Check if Python is in PATH
    echo.
    goto ERROR_END
)

echo.
echo [4/5] Creating versioned release package...

if not exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo.
    echo ERROR: Executable was not created!
    goto ERROR_END
)

REM Copy essential documentation files only
if exist "README.md" (
    copy "README.md" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: README.md
)
if exist "LICENSE" (
    copy "LICENSE" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: LICENSE
)
if exist "SIMPLE_USAGE.md" (
    copy "SIMPLE_USAGE.md" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: SIMPLE_USAGE.md
)
if exist "HOW_TO_USE.txt" (
    copy "HOW_TO_USE.txt" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: HOW_TO_USE.txt
)
if exist "UPDATE_GUIDE.md" (
    copy "UPDATE_GUIDE.md" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: UPDATE_GUIDE.md
)
if exist "update.bat" (
    copy "update.bat" "dist\SonarrSeedr\" >nul 2>&1
    echo   Copied: update.bat
)

REM Create debug.bat
(
    echo @echo off
    echo echo Starting Sonarr-Seedr in debug mode...
    echo echo.
    echo SonarrSeedr.exe
    echo echo.
    echo echo Application closed. Press any key to exit...
    echo pause ^> nul
) > "dist\SonarrSeedr\debug.bat"
echo   Created: debug.bat

REM Create VERSION.txt
(
    echo Sonarr-Seedr Integration
    echo Version: %VERSION%
    echo Build Date: %BUILD_DATE%
    echo Build Name: %BUILD_NAME%
    echo.
    echo Visit: https://github.com/yourusername/sonarr-seedr
) > "dist\SonarrSeedr\VERSION.txt"
echo   Created: VERSION.txt

echo.
echo [5/5] Creating ZIP archive...
echo   Compressing files (this may take a minute)...

REM Create releases\zip directory if it doesn't exist
if not exist "releases\zip" mkdir "releases\zip"

REM Delete old ZIP if exists
if exist "releases\zip\%BUILD_NAME%.zip" del "releases\zip\%BUILD_NAME%.zip" >nul 2>&1

REM Create ZIP using PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\SonarrSeedr', 'releases\zip\%BUILD_NAME%.zip', 'Optimal', $false); $size = [math]::Round((Get-Item 'releases\zip\%BUILD_NAME%.zip').Length / 1MB, 2); Write-Host ('  Created: releases\zip\%BUILD_NAME%.zip (' + $size + ' MB)'); } catch { Write-Host ('  ERROR: ' + $_.Exception.Message) -ForegroundColor Red; exit 1; }"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to create ZIP file!
    echo.
    echo Trying fallback method...
    
    REM Fallback to Compress-Archive
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'dist\SonarrSeedr\*' -DestinationPath 'releases\zip\%BUILD_NAME%.zip' -CompressionLevel Optimal -Force"
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Both ZIP methods failed!
        echo.
        echo Troubleshooting:
        echo   1. Check if releases\zip\ folder exists
        echo   2. Check if dist\SonarrSeedr\ contains files
        echo   3. Try running as Administrator
        echo   4. Check disk space (need 500+ MB free)
        echo   5. Try moving project to path without spaces
        echo.
        pause
        exit /b 1
    )
)

echo.
echo [6/6] Copying to Plugin Zips folder...

REM Copy ZIP to Plugin Zips folder - use absolute paths
set "SOURCE_ZIP=%CD%\releases\zip\%BUILD_NAME%.zip"

REM Build absolute path for Plugin Zips using PowerShell (handles spaces correctly)
for /f "delims=" %%i in ('powershell -NoProfile -Command "$scriptDir = '%SCRIPT_DIR%'; $targetPath = Join-Path (Resolve-Path (Join-Path $scriptDir '..\..\..')) 'Plugin Zips\Sonarr\zip'; if (-not (Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }; $targetPath"') do set "PLUGIN_ZIPS_DIR=%%i"

set "DEST_ZIP=%PLUGIN_ZIPS_DIR%\%BUILD_NAME%.zip"

if not exist "%SOURCE_ZIP%" (
    echo   ERROR: Source ZIP not found: %SOURCE_ZIP%
    goto SKIP_COPY
)

echo   Source: %SOURCE_ZIP%
echo   Destination: %DEST_ZIP%

copy "%SOURCE_ZIP%" "%DEST_ZIP%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✓ Successfully copied to Plugin Zips folder
) else (
    echo   WARNING: Could not copy to Plugin Zips folder
    echo   Error code: %errorlevel%
)

:SKIP_COPY

echo.
echo ================================
echo SUCCESS: Build complete!
echo ================================
echo.
echo Build Information:
echo   Version: %VERSION%
echo   Build Date: %BUILD_DATE%
echo   Package: %BUILD_NAME%
echo.
echo Locations:
echo   Executable: dist\SonarrSeedr\SonarrSeedr.exe
echo   ZIP Package: releases\zip\%BUILD_NAME%.zip
echo   Plugin Zips: %PLUGIN_ZIPS_DIR%\%BUILD_NAME%.zip
echo.
echo The application will start on http://localhost:8242
echo.

REM Show all builds in Plugin Zips
echo All builds in Plugin Zips folder:
dir /b "%PLUGIN_ZIPS_DIR%\SonarrSeedr-*.zip" 2>nul
echo.
goto SUCCESS_END

:ERROR_END
echo.
echo Build failed! Check the errors above.
echo.
pause
exit /b 1

:SUCCESS_END
exit /b 0
