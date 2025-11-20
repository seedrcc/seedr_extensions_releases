# PowerShell Release Script with Better Error Handling
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    AUTOMATED BUILD AND GITHUB RELEASE" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Read version
    Write-Host "[1/6] Reading version information..." -ForegroundColor Yellow
    
    if (-not (Test-Path "app\version.py")) {
        throw "Could not find app\version.py! Make sure you're in the project root."
    }
    
    $versionContent = Get-Content "app\version.py" | Select-String '__version__'
    $currentVersion = ($versionContent -replace '.*"([^"]+)".*', '$1').Trim()
    
    Write-Host "  Current Version: v$currentVersion" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Ask for release type
    Write-Host "[2/6] What type of release is this?" -ForegroundColor Yellow
    Write-Host "  1. Major (breaking changes) - 1.0.0 -> 2.0.0"
    Write-Host "  2. Minor (new features)     - 1.1.0 -> 1.2.0"
    Write-Host "  3. Patch (bug fixes)        - 1.1.0 -> 1.1.1"
    Write-Host "  4. Use current version ($currentVersion)"
    Write-Host "  5. Custom version"
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1-5)"
    
    $versionParts = $currentVersion -split '\.'
    $major = [int]$versionParts[0]
    $minor = [int]$versionParts[1]
    $patch = [int]$versionParts[2]
    
    switch ($choice) {
        "1" { $newVersion = "$($major + 1).0.0" }
        "2" { $newVersion = "$major.$($minor + 1).0" }
        "3" { $newVersion = "$major.$minor.$($patch + 1)" }
        "4" { $newVersion = $currentVersion }
        "5" { $newVersion = Read-Host "Enter version (e.g., 1.2.0)" }
        default { throw "Invalid choice" }
    }
    
    Write-Host ""
    Write-Host "  New Version: v$newVersion" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Update version.py
    Write-Host "[3/6] Updating version.py..." -ForegroundColor Yellow
    $buildDate = Get-Date -Format "yyyy-MM-dd"
    
    $newContent = @"
"""Version information for the Sonarr-Seedr Integration."""
__version__ = "$newVersion"
__build_date__ = "$buildDate"
__description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
"@
    
    $newContent | Out-File "app\version.py" -Encoding UTF8
    Write-Host "  Updated to v$newVersion" -ForegroundColor Green
    Write-Host ""
    
    # Step 4: Ask for release notes
    Write-Host "[4/6] Enter release notes (what's new in this version):" -ForegroundColor Yellow
    Write-Host "  Type your changes, one per line. Type 'done' when finished."
    Write-Host ""
    
    $releaseNotes = @()
    while ($true) {
        $line = Read-Host "  -"
        if ($line -eq "done") { break }
        if ($line) { $releaseNotes += $line }
    }
    
    if ($releaseNotes.Count -eq 0) {
        $releaseNotes = @("Bug fixes and improvements")
    }
    
    Write-Host ""
    Write-Host "  Release notes captured." -ForegroundColor Green
    Write-Host ""
    
    # Step 5: Run build.bat
    Write-Host "[5/6] Running build process..." -ForegroundColor Yellow
    Write-Host "  This may take several minutes..." -ForegroundColor Gray
    Write-Host ""
    
    # Clear any cached Python bytecode to ensure fresh build
    if (Test-Path "app\__pycache__") {
        Remove-Item "app\__pycache__" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Path "app" -Filter "*.pyc" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Run build.bat with proper error handling (pass --auto to skip pause)
    $buildBat = Join-Path (Get-Location) "build.bat"
    $buildProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$buildBat`" --auto" -NoNewWindow -Wait -PassThru
    
    if ($buildProcess.ExitCode -ne 0) {
        throw "Build failed with exit code: $($buildProcess.ExitCode)"
    }
    
    Write-Host ""
    Write-Host "  Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Step 6: Find ZIP file
    Write-Host "[6/6] Preparing GitHub release..." -ForegroundColor Yellow
    
    # First try to find ZIP with the new version (get newest if multiple)
    $zipFile = Get-ChildItem "releases\SonarrSeedr-v$newVersion*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    # If not found, get the most recent ZIP file
    if (-not $zipFile) {
        Write-Host "  Looking for most recent build..." -ForegroundColor Gray
        $zipFile = Get-ChildItem "releases\SonarrSeedr*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
    
    if (-not $zipFile) {
        throw "Could not find any ZIP file in releases folder! Build may have failed."
    }
    
    # Warn if version mismatch
    if ($zipFile.Name -notlike "*v$newVersion*") {
        Write-Host ""
        Write-Host "  WARNING: ZIP file version mismatch!" -ForegroundColor Yellow
        Write-Host "  Expected: v$newVersion" -ForegroundColor Yellow
        Write-Host "  Found:    $($zipFile.Name)" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "  Continue with this file? (y/n)"
        if ($continue -ne "y") {
            throw "User cancelled due to version mismatch"
        }
    }
    
    Write-Host "  Found: $($zipFile.Name)" -ForegroundColor Green
    Write-Host ""
    
    # Step 7: Check GitHub CLI
    Write-Host "Checking for GitHub CLI (gh)..." -ForegroundColor Yellow
    
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    
    if (-not $ghInstalled) {
        Write-Host ""
        Write-Host "================================================================================" -ForegroundColor Red
        Write-Host "                          GITHUB CLI NOT FOUND" -ForegroundColor Red
        Write-Host "================================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "The GitHub CLI (gh) is not installed or not in PATH."
        Write-Host ""
        Write-Host "OPTION 1: Install GitHub CLI (Recommended)"
        Write-Host "  1. Download from: https://cli.github.com/"
        Write-Host "  2. Install and restart this script"
        Write-Host "  3. Run: gh auth login"
        Write-Host ""
        Write-Host "OPTION 2: Manual Release"
        Write-Host "  1. Go to: https://github.com/jose987654/sonarr-plugin/releases/new"
        Write-Host "  2. Tag: v$newVersion"
        Write-Host "  3. Title: Version $newVersion"
        Write-Host "  4. Upload: $($zipFile.FullName)"
        Write-Host "  5. Publish release"
        Write-Host ""
        Write-Host "================================================================================"
        Write-Host ""
        Write-Host "Your build is ready at: $($zipFile.FullName)" -ForegroundColor Green
        Write-Host ""
        return
    }
    
    Write-Host "  GitHub CLI found!" -ForegroundColor Green
    Write-Host ""
    
    # Step 8: Check authentication
    Write-Host "Checking GitHub authentication..." -ForegroundColor Yellow
    
    $authResult = & gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "You are not logged in to GitHub." -ForegroundColor Red
        Write-Host "Please run: gh auth login" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Then run this script again."
        Write-Host ""
        return
    }
    
    Write-Host "  Authenticated!" -ForegroundColor Green
    Write-Host ""
    
    # Step 9: Commit version change
    Write-Host "Committing version change..." -ForegroundColor Yellow
    git add app\version.py
    git commit -m "Release v$newVersion" 2>&1 | Out-Null
    Write-Host "  Committed!" -ForegroundColor Green
    Write-Host ""
    
    # Step 10: Create tag (delete if exists)
    Write-Host "Creating git tag v$newVersion..." -ForegroundColor Yellow
    
    # Delete local tag if exists
    git tag -d "v$newVersion" 2>$null | Out-Null
    
    # Delete remote tag if exists
    git push origin --delete "v$newVersion" 2>$null | Out-Null
    
    # Create new tag
    git tag -a "v$newVersion" -m "Release v$newVersion" 2>&1 | Out-Null
    Write-Host "  Tag created!" -ForegroundColor Green
    Write-Host ""
    
    # Step 11: Push
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin main 2>&1 | Out-Null
    git push origin "v$newVersion" 2>&1 | Out-Null
    Write-Host "  Pushed!" -ForegroundColor Green
    Write-Host ""
    
    # Step 12: Create release notes file
    $notesContent = @"
## IMPORTANT: Download Instructions

**DOWNLOAD THIS FILE ONLY:**
### ``$($zipFile.Name)``

**DO NOT download "Source code (zip)" or "Source code (tar.gz)"**
Those are auto-generated by GitHub and are NOT the application!

---

## What's New in v$newVersion

$($releaseNotes | ForEach-Object { "- $_" } | Out-String)

---

## Installation Steps

1. **Download**: Click on ``$($zipFile.Name)`` above (NOT source code!)
2. **Extract**: Unzip to your installation folder
3. **Run**: Double-click ``SonarrSeedr.exe``
4. **Done!** The app will start on http://localhost:8242

---

## For Existing Users (Updating)

Simply extract to your existing folder and overwrite files.
Your settings will be preserved automatically!

Or use the **one-click auto-update** from the Settings page!

---

## Need Help?

- See ``SIMPLE_USAGE.md`` in the ZIP for setup instructions
- Check ``HOW_TO_USE.txt`` for quick start guide
- Issues? Open a ticket on GitHub!
"@
    
    $notesFile = "release_notes_temp.txt"
    # Use UTF8 without BOM to avoid encoding issues
    [System.IO.File]::WriteAllText($notesFile, $notesContent, [System.Text.UTF8Encoding]::new($false))
    
    # Step 13: Create or update GitHub release
    Write-Host "Creating GitHub release..." -ForegroundColor Yellow
    
    # Check if release already exists
    $releaseExists = gh release view "v$newVersion" --repo jose987654/sonarr-plugin 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Release v$newVersion already exists. Deleting old release..." -ForegroundColor Yellow
        & gh release delete "v$newVersion" --repo jose987654/sonarr-plugin --yes 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Old release deleted!" -ForegroundColor Green
        }
        
        # Small delay to ensure deletion completes
        Start-Sleep -Seconds 2
    }
    
    # Create the release
    & gh release create "v$newVersion" $zipFile.FullName `
        --title "Version $newVersion" `
        --notes-file $notesFile `
        --repo jose987654/sonarr-plugin
    
    Remove-Item $notesFile -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create GitHub release!"
    }
    
    # Note: GitHub auto-generates "Source code (zip)" and "Source code (tar.gz)" 
    # These are based on the git tag and cannot be removed via API.
    # Solution: sonarr-plugin repo should be releases-only (no source code)
    # This way the auto-generated archives will be empty/minimal.
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "                          SUCCESS! RELEASE PUBLISHED" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Version:  v$newVersion" -ForegroundColor Cyan
    Write-Host "  ZIP File: $($zipFile.Name)" -ForegroundColor Cyan
    Write-Host "  Size:     $([math]::Round($zipFile.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v$newVersion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Users can now update with one click from the Settings page!" -ForegroundColor Green
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "                                ERROR" -ForegroundColor Red
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host ""
} finally {
    Write-Host "Press any key to close this window..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


