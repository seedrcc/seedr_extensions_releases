@echo off
setlocal enabledelayedexpansion

echo ================================================================================
echo                          ZIP CREATION TEST SCRIPT
echo ================================================================================
echo.
echo This script will help diagnose ZIP creation issues.
echo.

REM Check if dist folder exists
if not exist "dist\SonarrSeedr\" (
    echo [ERROR] dist\SonarrSeedr\ folder not found!
    echo Please run build.bat first.
    pause
    exit /b 1
)

REM Count files
set COUNT=0
for /f %%A in ('dir /b /s "dist\SonarrSeedr\*.*" ^| find /c /v ""') do set COUNT=%%A
echo [INFO] Found %COUNT% files in dist\SonarrSeedr\
echo.

REM Get folder size
for /f "tokens=3" %%A in ('dir /s "dist\SonarrSeedr" ^| findstr /C:"File(s)"') do set SIZE=%%A
echo [INFO] Total size: %SIZE% bytes
echo.

REM Get version
set VERSION=1.0.0
if exist "app\version.py" (
    for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py') do (
        set VERLINE=%%a
    )
    set VERSION=!VERLINE:"=!
    set VERSION=!VERSION: =!
)

REM Generate timestamp
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set ZIP_NAME=SonarrSeedr-v%VERSION%-%TIMESTAMP%.zip

echo [INFO] Output file: releases\%ZIP_NAME%
echo.

REM Create releases folder if needed
if not exist "releases" mkdir "releases"

REM Delete old ZIP if exists
if exist "releases\%ZIP_NAME%" (
    echo [INFO] Deleting existing ZIP file...
    del "releases\%ZIP_NAME%" >nul 2>&1
)

echo ================================================================================
echo                          METHOD 1: Using .NET ZipFile
echo ================================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop'; ^
    $ProgressPreference = 'SilentlyContinue'; ^
    try { ^
        Write-Host '[1/3] Loading compression library...'; ^
        Add-Type -AssemblyName System.IO.Compression.FileSystem; ^
        Write-Host '[2/3] Creating ZIP archive...'; ^
        $source = Resolve-Path 'dist\SonarrSeedr'; ^
        $destination = Join-Path (Get-Location) 'releases\%ZIP_NAME%'; ^
        Write-Host ('      Source: ' + $source); ^
        Write-Host ('      Destination: ' + $destination); ^
        [System.IO.Compression.ZipFile]::CreateFromDirectory($source, $destination, 'Optimal', $false); ^
        Write-Host '[3/3] Verifying...'; ^
        $zipSize = [math]::Round((Get-Item $destination).Length / 1MB, 2); ^
        Write-Host ('      ZIP file created successfully! Size: ' + $zipSize + ' MB'); ^
        exit 0; ^
    } catch { ^
        Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red; ^
        Write-Host ('Type: ' + $_.Exception.GetType().FullName) -ForegroundColor Red; ^
        exit 1; ^
    }"

if errorlevel 1 (
    echo.
    echo [ERROR] Method 1 failed! Trying Method 2...
    echo.
    
    echo ================================================================================
    echo                          METHOD 2: Using Compress-Archive
    echo ================================================================================
    echo.
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ErrorActionPreference = 'Stop'; ^
        $ProgressPreference = 'SilentlyContinue'; ^
        try { ^
            Write-Host '[1/2] Compressing with Compress-Archive...'; ^
            Compress-Archive -Path 'dist\SonarrSeedr\*' -DestinationPath 'releases\%ZIP_NAME%' -CompressionLevel Optimal -Force; ^
            Write-Host '[2/2] Verifying...'; ^
            $zipSize = [math]::Round((Get-Item 'releases\%ZIP_NAME%').Length / 1MB, 2); ^
            Write-Host ('      ZIP file created successfully! Size: ' + $zipSize + ' MB'); ^
            exit 0; ^
        } catch { ^
            Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red; ^
            exit 1; ^
        }"
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Both methods failed!
        echo.
        echo ========================================================================
        echo                          TROUBLESHOOTING
        echo ========================================================================
        echo.
        echo Possible causes:
        echo   1. Insufficient disk space
        echo   2. File path too long (Windows has 260 char limit)
        echo   3. Antivirus blocking the operation
        echo   4. Insufficient permissions
        echo   5. Corrupted PowerShell installation
        echo.
        echo Solutions:
        echo   1. Free up disk space
        echo   2. Run as Administrator
        echo   3. Temporarily disable antivirus
        echo   4. Move project to shorter path (e.g., C:\sonarr)
        echo   5. Reinstall PowerShell
        echo.
        echo ========================================================================
        echo.
        pause
        exit /b 1
    )
)

echo.
echo ================================================================================
echo                          SUCCESS!
echo ================================================================================
echo.
echo ZIP file created: releases\%ZIP_NAME%
echo.
if exist "releases\%ZIP_NAME%" (
    for %%A in ("releases\%ZIP_NAME%") do (
        echo File size: %%~zA bytes
        set /a MB=%%~zA/1024/1024
        echo File size: !MB! MB
    )
)
echo.
echo You can now test the ZIP file or use it for release.
echo.
pause

