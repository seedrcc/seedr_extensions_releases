# Build script for Sonarr-Seedr executable with versioning
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Building Sonarr-Seedr Executable" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Read version from version.py
Write-Host ""
Write-Host "[0/5] Reading version information..." -ForegroundColor Yellow
$versionFile = Get-Content "app\version.py" -Raw
if ($versionFile -match '__version__\s*=\s*"([^"]+)"') {
    $version = $Matches[1]
    Write-Host "  Version: $version" -ForegroundColor Cyan
}
else {
    $version = "1.0.0"
    Write-Host "  Warning: Could not read version, using default: $version" -ForegroundColor Yellow
}

# Generate build timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$buildDate = Get-Date -Format "yyyy-MM-dd"
$buildName = "SonarrSeedr-v${version}-${timestamp}"

Write-Host "  Build Name: $buildName" -ForegroundColor Cyan
Write-Host "  Build Date: $buildDate" -ForegroundColor Cyan

# Update build date in version.py
$versionContent = Get-Content "app\version.py" -Raw
$versionContent = $versionContent -replace '__build_date__\s*=\s*"[^"]*"', "__build_date__ = `"$buildDate`""
Set-Content "app\version.py" -Value $versionContent
Write-Host "  Updated build date in version.py" -ForegroundColor Green

Write-Host ""
Write-Host "[1/5] Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "dist") { Remove-Item -Recurse -Force "dist" }
if (Test-Path "build") { Remove-Item -Recurse -Force "build" }

Write-Host ""
Write-Host "[2/5] Creating necessary directories..." -ForegroundColor Yellow
$dirs = @("config", "completed", "processed", "error", "torrents", "releases")
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[3/5] Building executable with PyInstaller..." -ForegroundColor Yellow
try {
    & pyinstaller sonarr_seedr.spec --clean --noconfirm
    $buildSuccess = $LASTEXITCODE -eq 0
}
catch {
    $buildSuccess = $false
    Write-Host "Error running PyInstaller: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[4/5] Creating versioned release package..." -ForegroundColor Yellow

if ($buildSuccess -and (Test-Path "dist\SonarrSeedr\SonarrSeedr.exe")) {
    # Copy documentation files to dist
    $docFiles = @("README.md", "LICENSE", "SIMPLE_USAGE.md", "PORTABLE_USAGE.md", "COMPLETE_WORKFLOW.md", "DOWNLOAD_WORKFLOW_EXPLAINED.md")
    foreach ($doc in $docFiles) {
        if (Test-Path $doc) {
            Copy-Item $doc "dist\SonarrSeedr\" -Force
            Write-Host "  Copied: $doc" -ForegroundColor Gray
        }
    }
    
    # Create debug.bat in dist
    @"
@echo off
echo Starting Sonarr-Seedr in debug mode...
echo.
SonarrSeedr.exe
echo.
echo Application closed. Press any key to exit...
pause > nul
"@ | Set-Content "dist\SonarrSeedr\debug.bat"
    Write-Host "  Created: debug.bat" -ForegroundColor Gray
    
    # Create version info file
    @"
Sonarr-Seedr Integration
Version: $version
Build Date: $buildDate
Build Name: $buildName

Visit: https://github.com/yourusername/sonarr-seedr
"@ | Set-Content "dist\SonarrSeedr\VERSION.txt"
    Write-Host "  Created: VERSION.txt" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "[5/5] Creating ZIP archive..." -ForegroundColor Yellow
    
    # Create ZIP file
    $zipPath = "releases\$buildName.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path "dist\SonarrSeedr\*" -DestinationPath $zipPath -Force
    
    $zipSizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host "  Created: $zipPath ($zipSizeMB MB)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✓ SUCCESS: Build complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Build Information:" -ForegroundColor White
    Write-Host "  Version: " -NoNewline -ForegroundColor White
    Write-Host $version -ForegroundColor Cyan
    Write-Host "  Build Date: " -NoNewline -ForegroundColor White
    Write-Host $buildDate -ForegroundColor Cyan
    Write-Host "  Package: " -NoNewline -ForegroundColor White
    Write-Host $buildName -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Locations:" -ForegroundColor White
    Write-Host "  Executable: " -NoNewline -ForegroundColor White
    Write-Host "dist\SonarrSeedr\SonarrSeedr.exe" -ForegroundColor Cyan
    Write-Host "  ZIP Package: " -NoNewline -ForegroundColor White
    Write-Host $zipPath -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To run the application:" -ForegroundColor White
    Write-Host "  1. Extract ZIP or navigate to: dist\SonarrSeedr\" -ForegroundColor Gray
    Write-Host "  2. Double-click: SonarrSeedr.exe" -ForegroundColor Gray
    Write-Host "  3. Or run from command line: .\dist\SonarrSeedr\SonarrSeedr.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "The application will start on http://localhost:8000" -ForegroundColor Magenta
    Write-Host ""
    
    # Ask if user wants to run the executable
    $response = Read-Host "Would you like to run the executable now? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "Starting application..." -ForegroundColor Green
        Start-Process "dist\SonarrSeedr\SonarrSeedr.exe"
    }
}
else {
    Write-Host ""
    Write-Host "❌ ERROR: Build failed!" -ForegroundColor Red
    Write-Host "Check the output above for errors." -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
