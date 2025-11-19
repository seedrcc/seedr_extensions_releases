@echo off
setlocal enabledelayedexpansion

echo ================================================================================
echo                          BUILD DIAGNOSTICS
echo ================================================================================
echo.

echo [CHECK 1] Checking if dist folder exists...
if exist "dist\SonarrSeedr\" (
    echo   [OK] dist\SonarrSeedr\ exists
) else (
    echo   [FAIL] dist\SonarrSeedr\ not found!
    echo   Solution: Run build.bat first
    goto :end
)
echo.

echo [CHECK 2] Counting files in dist folder...
set COUNT=0
for /f %%A in ('dir /b /s "dist\SonarrSeedr\*.*" 2^>nul ^| find /c /v ""') do set COUNT=%%A
echo   [INFO] Found %COUNT% files
if %COUNT% GTR 0 (
    echo   [OK] Files found
) else (
    echo   [FAIL] No files found!
    echo   Solution: Build may have failed
    goto :end
)
echo.

echo [CHECK 3] Checking for .exe file...
if exist "dist\SonarrSeedr\SonarrSeedr.exe" (
    echo   [OK] SonarrSeedr.exe found
    for %%A in ("dist\SonarrSeedr\SonarrSeedr.exe") do (
        echo   [INFO] Size: %%~zA bytes
    )
) else (
    echo   [FAIL] SonarrSeedr.exe not found!
    echo   Solution: PyInstaller build failed
    goto :end
)
echo.

echo [CHECK 4] Checking releases folder...
if exist "releases\" (
    echo   [OK] releases\ exists
) else (
    echo   [INFO] Creating releases\ folder...
    mkdir "releases"
    echo   [OK] Created
)
echo.

echo [CHECK 5] Checking disk space...
for /f "tokens=3" %%A in ('dir /-C "%SystemDrive%\" ^| findstr /C:"bytes free"') do set FREE=%%A
set /a FREE_MB=%FREE:~0,-6%/1024/1024
echo   [INFO] Free space: %FREE_MB% MB
if %FREE_MB% LSS 500 (
    echo   [WARN] Low disk space! Need at least 500 MB free
) else (
    echo   [OK] Sufficient disk space
)
echo.

echo [CHECK 6] Checking path length...
set "LONG_PATH=%CD%\dist\SonarrSeedr\"
echo   [INFO] Current path length: 
echo   %LONG_PATH%
set PATHLEN=0
set "STR=%LONG_PATH%"
:loop
if defined STR (
    set /a PATHLEN+=1
    set "STR=%STR:~1%"
    goto :loop
)
echo   [INFO] Length: %PATHLEN% characters
if %PATHLEN% GTR 200 (
    echo   [WARN] Path is quite long. Windows has a 260 character limit.
    echo   [WARN] Consider moving project to a shorter path like C:\sonarr
) else (
    echo   [OK] Path length acceptable
)
echo.

echo [CHECK 7] Testing PowerShell availability...
powershell -Command "Write-Host '  [OK] PowerShell is working'" 2>nul
if errorlevel 1 (
    echo   [FAIL] PowerShell not working properly!
    echo   Solution: Reinstall PowerShell
    goto :end
)
echo.

echo [CHECK 8] Testing ZIP creation capability...
echo   [INFO] Testing with a small file...
echo test > test_file.txt
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { ^
        Add-Type -AssemblyName System.IO.Compression.FileSystem; ^
        [System.IO.Compression.ZipFile]::CreateFromDirectory('dist\SonarrSeedr\_internal', 'test.zip', 'Optimal', $false); ^
        Remove-Item 'test.zip' -ErrorAction SilentlyContinue; ^
        Write-Host '  [OK] ZIP creation works'; ^
        exit 0; ^
    } catch { ^
        Write-Host ('  [FAIL] ZIP creation failed: ' + $_.Exception.Message) -ForegroundColor Red; ^
        exit 1; ^
    }" 2>nul
del test_file.txt >nul 2>&1
echo.

echo [CHECK 9] Checking for file locks...
echo   [INFO] Checking if any files are locked...
powershell -Command ^
    "$locked = $false; ^
    Get-ChildItem -Path 'dist\SonarrSeedr' -Recurse -File | ForEach-Object { ^
        try { ^
            $file = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'None'); ^
            $file.Close(); ^
        } catch { ^
            Write-Host ('  [WARN] Locked file: ' + $_.Name) -ForegroundColor Yellow; ^
            $locked = $true; ^
        } ^
    }; ^
    if (-not $locked) { Write-Host '  [OK] No locked files' }"
echo.

echo [CHECK 10] Listing largest files...
echo   [INFO] Top 5 largest files in dist:
powershell -Command ^
    "Get-ChildItem -Path 'dist\SonarrSeedr' -Recurse -File | ^
    Sort-Object Length -Descending | ^
    Select-Object -First 5 | ^
    ForEach-Object { ^
        $size = [math]::Round($_.Length / 1MB, 2); ^
        Write-Host ('  ' + $_.Name + ' (' + $size + ' MB)'); ^
    }"
echo.

echo ================================================================================
echo                          DIAGNOSTICS COMPLETE
echo ================================================================================
echo.
echo If all checks passed, try running: create_zip.bat
echo.

:end
pause

