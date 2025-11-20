@echo off
echo ================================
echo Building Sonarr-Seedr Executable
echo ================================

echo.
echo [0/5] Reading version information...

REM Read version from version.py
set VERSION=1.0.0
for /f "tokens=2 delims=^\"" %%a in ('findstr "__version__" app\version.py') do set VERSION=%%a
echo   Version: %VERSION%

REM Generate timestamp
for /f "tokens=1-6 delims=/:. " %%a in ("%date% %time%") do (
    set TIMESTAMP=%%c%%a%%b_%%d%%e%%f
    set BUILD_DATE=%%c-%%a-%%b
)
set TIMESTAMP=%TIMESTAMP: =0%
set BUILD_NAME=SonarrSeedr-v%VERSION%-%TIMESTAMP%

echo   Build Name: %BUILD_NAME%
echo   Build Date: %BUILD_DATE%

REM Update build date in version.py
powershell -Command "$content = Get-Content 'app\version.py' -Raw; $content = $content -replace '__build_date__ = \"[^\"]*\"', '__build_date__ = \"%BUILD_DATE%\"'; Set-Content 'app\version.py' -Value $content -NoNewline"
echo   Updated build date in version.py

echo.
echo [1/5] Cleaning previous build...
if exist "dist" rmdir /s /q "dist"
if exist "build" rmdir /s /q "build"

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
pyinstaller sonarr_seedr.spec --clean --noconfirm

if errorlevel 1 (
    echo.
    echo ================================
    echo ERROR: PyInstaller failed!
    echo ================================
    echo.
    echo Check the output above for errors.
    echo.
    echo Common fixes:
    echo   pip install pyinstaller
    echo   pip install -r requirements.txt
    echo.
    echo Press any key to exit...
    pause > nul
    exit /b 1
)

echo.
echo [4/5] Creating versioned release package...

if exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    REM Copy documentation files
    if exist "README.md" copy "README.md" "dist\SonarrSeedr\" >nul && echo   Copied: README.md
    if exist "LICENSE" copy "LICENSE" "dist\SonarrSeedr\" >nul && echo   Copied: LICENSE
    if exist "SIMPLE_USAGE.md" copy "SIMPLE_USAGE.md" "dist\SonarrSeedr\" >nul && echo   Copied: SIMPLE_USAGE.md
    if exist "PORTABLE_USAGE.md" copy "PORTABLE_USAGE.md" "dist\SonarrSeedr\" >nul && echo   Copied: PORTABLE_USAGE.md
    if exist "COMPLETE_WORKFLOW.md" copy "COMPLETE_WORKFLOW.md" "dist\SonarrSeedr\" >nul && echo   Copied: COMPLETE_WORKFLOW.md
    if exist "DOWNLOAD_WORKFLOW_EXPLAINED.md" copy "DOWNLOAD_WORKFLOW_EXPLAINED.md" "dist\SonarrSeedr\" >nul && echo   Copied: DOWNLOAD_WORKFLOW_EXPLAINED.md
    
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
    
    REM Create ZIP file using PowerShell
    powershell -Command "Compress-Archive -Path 'dist\SonarrSeedr\*' -DestinationPath 'releases\%BUILD_NAME%.zip' -Force"
    echo   Created: releases\%BUILD_NAME%.zip
    
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
    echo The application will start on http://localhost:8000
    echo.
) else (
    echo.
    echo ================================
    echo ERROR: Build failed!
    echo ================================
    echo Check the output above for errors.
    echo.
)

echo.
echo Press any key to exit...
pause > nul

