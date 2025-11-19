@echo off
echo ========================================
echo  Sonarr-Seedr Deployment Test Script
echo ========================================

echo.
echo [1/5] Testing executable...
SonarrSeedr.exe --help > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Executable runs successfully
) else (
    echo ❌ Executable failed to run
    echo.
    echo Trying to run with error output:
    SonarrSeedr.exe --help
    pause
    exit /b 1
)

echo.
echo [2/5] Checking file structure...
if exist "_internal" (
    echo ✓ Dependencies folder found
) else (
    echo ❌ Dependencies folder missing
    pause
    exit /b 1
)

if exist "_internal\app\web\templates" (
    echo ✓ Web templates found
) else (
    echo ❌ Web templates missing
    pause
    exit /b 1
)

echo.
echo [3/5] Testing port availability...
netstat -ano | findstr :8000 > nul
if %ERRORLEVEL% EQU 0 (
    echo ⚠️  Port 8000 is already in use
    echo    The application will need to use a different port
    set USE_ALT_PORT=1
) else (
    echo ✓ Port 8000 is available
    set USE_ALT_PORT=0
)

echo.
echo [4/5] Starting application test...
echo    This will start the application for 10 seconds to test functionality

if %USE_ALT_PORT% EQU 1 (
    echo    Using alternate port 9000
    start /B SonarrSeedr.exe --no-browser --port 9000
    set TEST_PORT=9000
) else (
    start /B SonarrSeedr.exe --no-browser --port 8000
    set TEST_PORT=8000
)

echo    Waiting for application to start...
timeout /t 5 /nobreak > nul

echo.
echo [5/5] Testing API response...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:%TEST_PORT%/api/test' -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '✓ API test successful' -ForegroundColor Green } else { Write-Host '❌ API test failed' -ForegroundColor Red } } catch { Write-Host '❌ API test failed - could not connect' -ForegroundColor Red }" 2>nul

echo.
echo Stopping test application...
taskkill /F /IM SonarrSeedr.exe > nul 2>&1

echo.
echo ========================================
echo  Test Complete!
echo ========================================
echo.
echo If all tests passed, your deployment is ready!
echo.
echo To start the application normally:
echo   SonarrSeedr.exe
echo.
echo To start on a different port:
echo   SonarrSeedr.exe --port 9000
echo.
echo The web interface will be available at:
echo   http://localhost:%TEST_PORT%
echo.

pause
