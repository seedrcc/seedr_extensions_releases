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

echo   Version: %VERSION%

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

REM Delete old ZIP if exists
if exist "releases\%BUILD_NAME%.zip" del "releases\%BUILD_NAME%.zip" >nul 2>&1

REM Create ZIP using PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\SonarrSeedr', 'releases\%BUILD_NAME%.zip', 'Optimal', $false); $size = [math]::Round((Get-Item 'releases\%BUILD_NAME%.zip').Length / 1MB, 2); Write-Host ('  Created: releases\%BUILD_NAME%.zip (' + $size + ' MB)'); } catch { Write-Host ('  ERROR: ' + $_.Exception.Message) -ForegroundColor Red; exit 1; }"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to create ZIP file!
    echo.
    echo Trying fallback method...
    
    REM Fallback to Compress-Archive
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'dist\SonarrSeedr\*' -DestinationPath 'releases\%BUILD_NAME%.zip' -CompressionLevel Optimal -Force"
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Both ZIP methods failed!
        echo.
        echo Troubleshooting:
        echo   1. Check if releases\ folder exists
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
echo   ZIP Package: releases\%BUILD_NAME%.zip
echo.
echo The application will start on http://localhost:8242
echo.
goto SUCCESS_END

:ERROR_END
echo.
echo Build failed! Check the errors above.
echo.
pause
exit /b 1

:SUCCESS_END
if not "%AUTO_MODE%"=="--auto" (
    echo Press any key to exit...
    pause >nul
)
exit /b 0
