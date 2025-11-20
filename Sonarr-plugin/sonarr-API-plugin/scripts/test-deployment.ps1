# Sonarr-Seedr Deployment Test Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Sonarr-Seedr Deployment Test Script" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

$testPassed = $true

Write-Host ""
Write-Host "[1/5] Testing executable..." -ForegroundColor Yellow
try {
    $output = & .\SonarrSeedr.exe --help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Executable runs successfully" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Executable failed to run" -ForegroundColor Red
        Write-Host "Error output:" -ForegroundColor Red
        Write-Host $output -ForegroundColor Red
        $testPassed = $false
    }
}
catch {
    Write-Host "❌ Executable failed to run: $_" -ForegroundColor Red
    $testPassed = $false
}

Write-Host ""
Write-Host "[2/5] Checking file structure..." -ForegroundColor Yellow
if (Test-Path "_internal") {
    Write-Host "✓ Dependencies folder found" -ForegroundColor Green
}
else {
    Write-Host "❌ Dependencies folder missing" -ForegroundColor Red
    $testPassed = $false
}

if (Test-Path "_internal\app\web\templates") {
    Write-Host "✓ Web templates found" -ForegroundColor Green
}
else {
    Write-Host "❌ Web templates missing" -ForegroundColor Red
    $testPassed = $false
}

Write-Host ""
Write-Host "[3/5] Testing port availability..." -ForegroundColor Yellow
$portInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "⚠️  Port 8000 is already in use" -ForegroundColor Yellow
    Write-Host "   The application will need to use a different port" -ForegroundColor Yellow
    $useAltPort = $true
    $testPort = 9000
}
else {
    Write-Host "✓ Port 8000 is available" -ForegroundColor Green
    $useAltPort = $false
    $testPort = 8000
}

Write-Host ""
Write-Host "[4/5] Starting application test..." -ForegroundColor Yellow
Write-Host "   This will start the application for 10 seconds to test functionality" -ForegroundColor Gray

try {
    if ($useAltPort) {
        Write-Host "   Using alternate port $testPort" -ForegroundColor Gray
        $process = Start-Process -FilePath ".\SonarrSeedr.exe" -ArgumentList "--no-browser", "--port", $testPort -PassThru -WindowStyle Hidden
    }
    else {
        $process = Start-Process -FilePath ".\SonarrSeedr.exe" -ArgumentList "--no-browser", "--port", $testPort -PassThru -WindowStyle Hidden
    }
    
    Write-Host "   Waiting for application to start..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    Write-Host ""
    Write-Host "[5/5] Testing API response..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$testPort/api/test" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ API test successful" -ForegroundColor Green
            $apiContent = $response.Content | ConvertFrom-Json
            if ($apiContent.success -eq $true) {
                Write-Host "✓ API returned expected response" -ForegroundColor Green
            }
            else {
                Write-Host "⚠️  API responded but with unexpected content" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "❌ API test failed - Status: $($response.StatusCode)" -ForegroundColor Red
            $testPassed = $false
        }
    }
    catch {
        Write-Host "❌ API test failed - Could not connect: $($_.Exception.Message)" -ForegroundColor Red
        $testPassed = $false
    }
    
    Write-Host ""
    Write-Host "Stopping test application..." -ForegroundColor Gray
    if ($process -and !$process.HasExited) {
        $process.Kill()
        $process.WaitForExit(5000)
    }
    
    # Also kill any remaining processes
    Get-Process -Name "SonarrSeedr" -ErrorAction SilentlyContinue | Stop-Process -Force
    
}
catch {
    Write-Host "❌ Failed to start application: $_" -ForegroundColor Red
    $testPassed = $false
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($testPassed) {
    Write-Host " ✅ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host " Your deployment is ready!" -ForegroundColor Green
}
else {
    Write-Host " ❌ SOME TESTS FAILED!" -ForegroundColor Red
    Write-Host " Please check the errors above" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "📋 Usage Instructions:" -ForegroundColor White
Write-Host ""
Write-Host "To start the application normally:" -ForegroundColor Gray
Write-Host "  .\SonarrSeedr.exe" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start on a different port:" -ForegroundColor Gray
Write-Host "  .\SonarrSeedr.exe --port 9000" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start without opening browser:" -ForegroundColor Gray
Write-Host "  .\SonarrSeedr.exe --no-browser" -ForegroundColor Cyan
Write-Host ""
Write-Host "The web interface will be available at:" -ForegroundColor Gray
Write-Host "  http://localhost:$testPort" -ForegroundColor Magenta
Write-Host ""

# Ask if user wants to start the application
$response = Read-Host "Would you like to start the application now? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "Starting application..." -ForegroundColor Green
    if ($useAltPort) {
        Start-Process -FilePath ".\SonarrSeedr.exe" -ArgumentList "--port", $testPort
    }
    else {
        Start-Process -FilePath ".\SonarrSeedr.exe"
    }
    Write-Host "Application started! Check your browser." -ForegroundColor Green
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
