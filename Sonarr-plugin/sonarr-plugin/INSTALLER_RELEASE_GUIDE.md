# Installer & Release Guide

## Overview
This guide explains how to create and publish both the **Portable ZIP** and **Windows Installer** to GitHub releases.

## Two Release Options for Users

After following this guide, users will have **two download options** on GitHub:

1. **Installer (.exe)** - Easy Windows installation with Start Menu shortcuts
2. **Portable ZIP** - No installation, extract and run

---

## Quick Start: Complete Release Process

### **Option A: Release Everything at Once (Recommended)**

1. **Create the main release with ZIP:**
   ```batch
   release.bat
   ```
   - Choose version type (major/minor/patch)
   - Enter release notes
   - Builds the ZIP and uploads to GitHub
   - Creates the release with formatted notes

2. **Add the installer to the same release:**
   ```batch
   build-installer.bat
   ```
   - Builds the installer .exe
   - Asks if you want to upload to GitHub
   - Type `y` to upload
   - Automatically adds to the existing release

**Result:** One GitHub release with both ZIP and Installer! 🎉

---

### **Option B: Build Installer Only (No Upload)**

If you just want to test the installer locally:

```batch
build-installer.bat
```
- When asked "Upload to GitHub?", type `n`
- Installer will be in `releases\installers\`
- Test it locally without publishing

---

## Detailed Workflow

### Step 1: Main Release (ZIP + Notes)
```batch
release.bat
```

**What it does:**
1. ✅ Reads current version from `app\version.py`
2. ✅ Asks for version bump (major/minor/patch)
3. ✅ Updates `app\version.py` with new version
4. ✅ Asks for release notes
5. ✅ Runs `build.bat` to create portable ZIP
6. ✅ Commits version change to git
7. ✅ Creates and pushes git tag
8. ✅ Creates GitHub release with:
   - Formatted release notes
   - Download instructions
   - Installation guide
   - Uploaded ZIP file

**Example Output:**
```
================================================================================
                    AUTOMATED BUILD AND GITHUB RELEASE
================================================================================

[1/6] Reading version information...
  Current Version: v1.1.0

[2/6] What type of release is this?
  1. Major (breaking changes) - 1.0.0 -> 2.0.0
  2. Minor (new features)     - 1.1.0 -> 1.2.0
  3. Patch (bug fixes)        - 1.1.0 -> 1.1.1
  4. Use current version (1.1.0)
  5. Custom version

Enter choice (1-5): 3

  New Version: v1.1.1

[4/6] Enter release notes (what's new in this version):
  - Fixed download error handling
  - Improved error messages
  - done

[5/6] Running build process...
  Build completed successfully!

[6/6] Preparing GitHub release...
  Found: SonarrSeedr-v1.1.1.zip

Creating GitHub release...

================================================================================
                          SUCCESS! RELEASE PUBLISHED
================================================================================

  Version:  v1.1.1
  ZIP File: SonarrSeedr-v1.1.1.zip
  
  Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v1.1.1
================================================================================
```

---

### Step 2: Add Installer to Release
```batch
build-installer.bat
```

**What it does:**
1. ✅ Reads version from `app\version.py`
2. ✅ Checks if executable exists (builds if needed)
3. ✅ Compiles Windows installer using Inno Setup
4. ✅ Asks if you want to upload to GitHub
5. ✅ Checks for GitHub CLI and authentication
6. ✅ Finds existing release for the version
7. ✅ Uploads installer to the release

**Example Output:**
```
=====================================
Building Sonarr-Seedr Installer
=====================================

Version: 1.1.1

[1/3] Checking for Inno Setup...
  Found: C:\Program Files (x86)\Inno Setup 6\ISCC.exe

[2/3] Checking if executable exists...
  Executable found: dist\SonarrSeedr\SonarrSeedr.exe

[3/3] Building installer...
  Compiling installer (this may take a minute)...

=====================================
SUCCESS: Installer created!
=====================================

Installer: SonarrSeedr-Setup-v1.1.1.exe
Location: releases\installers\SonarrSeedr-Setup-v1.1.1.exe

=====================================
Upload to GitHub?
=====================================

Do you want to upload this installer to GitHub releases? (y/n): y

Checking for GitHub CLI (gh)...
  GitHub CLI found!

Checking GitHub authentication...
  Authenticated!

Checking for release v1.1.1...
  Found release v1.1.1!

Uploading installer to existing release...
  Uploaded successfully!

================================================================================
                          SUCCESS! INSTALLER UPLOADED
================================================================================

  Version:       v1.1.1
  Installer:     SonarrSeedr-Setup-v1.1.1.exe
  Size:          45829120 bytes

  Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v1.1.1

  Users can now download either:
    - Installer (.exe) - Easy Windows installation
    - Portable ZIP     - No installation required

================================================================================
```

---

## Prerequisites

### For `release.bat`:
- ✅ Python 3.x installed
- ✅ PyInstaller installed
- ✅ Git configured
- ✅ GitHub CLI (`gh`) installed and authenticated
- ✅ Repository access

### For `build-installer.bat`:
- ✅ Inno Setup 6 installed ([download here](https://jrsoftware.org/isdl.php))
- ✅ GitHub CLI (`gh`) installed (optional, for upload)
- ✅ Built executable in `dist\SonarrSeedr\` (created automatically if missing)

---

## GitHub CLI Setup

If you haven't installed GitHub CLI yet:

1. **Download:** https://cli.github.com/
2. **Install:** Run the installer
3. **Authenticate:**
   ```batch
   gh auth login
   ```
4. **Follow prompts:**
   - Choose GitHub.com
   - Choose HTTPS
   - Authenticate via browser
   - Done!

---

## What Gets Uploaded to GitHub?

After running both scripts, your GitHub release will have:

### ✅ **Assets:**
```
📦 SonarrSeedr-v1.1.1.zip              (Portable version)
📦 SonarrSeedr-Setup-v1.1.1.exe        (Windows Installer)
📄 Source code (zip)                    (Auto-generated by GitHub)
📄 Source code (tar.gz)                 (Auto-generated by GitHub)
```

### ✅ **Release Notes:**
```markdown
## WARNING: Download Instructions

**DOWNLOAD THIS FILE ONLY:**
### `SonarrSeedr-v1.1.1.zip`

**DO NOT download "Source code (zip)" or "Source code (tar.gz)"**
Those are auto-generated by GitHub and are NOT the application!

---

## What's New in v1.1.1

- Fixed download error handling
- Improved error messages

---

## Installation Steps

**Option 1: Installer (Recommended for Windows)**
1. Download: `SonarrSeedr-Setup-v1.1.1.exe`
2. Run installer as Administrator
3. Follow installation wizard
4. Launch from Start Menu

**Option 2: Portable ZIP**
1. Download: `SonarrSeedr-v1.1.1.zip` (NOT source code!)
2. Extract to your installation folder
3. Run: Double-click `SonarrSeedr.exe`
4. Done! The app will start on http://localhost:8242

---

## For Existing Users (Updating)

Simply extract to your existing folder and overwrite files.
Your settings will be preserved automatically!

Or use the **one-click auto-update** from the Settings page!
```

---

## Troubleshooting

### "GitHub CLI not found"
```
Solution: Install GitHub CLI
1. Download from: https://cli.github.com/
2. Install and restart script
3. Run: gh auth login
```

### "Release v1.1.1 does not exist"
```
Solution: Run release.bat first
- release.bat creates the main release with ZIP
- build-installer.bat adds installer to existing release
```

### "Inno Setup not found"
```
Solution: Install Inno Setup 6
1. Download from: https://jrsoftware.org/isdl.php
2. Install (default location is fine)
3. Run build-installer.bat again
```

### "Build failed"
```
Solution: Check dependencies
1. Ensure Python is installed
2. Ensure PyInstaller is installed: pip install pyinstaller
3. Check for error messages in console
```

---

## File Structure

After running both scripts, you'll have:

```
sonarr-fast-API-plugin/
├── releases/
│   ├── SonarrSeedr-v1.1.1.zip           ← Portable version
│   └── installers/
│       └── SonarrSeedr-Setup-v1.1.1.exe ← Windows installer
├── dist/
│   └── SonarrSeedr/
│       └── SonarrSeedr.exe              ← Built executable
└── app/
    └── version.py                        ← Updated version
```

---

## Tips & Best Practices

### ✅ **Release Order (Recommended)**
1. Run `release.bat` first (creates release with ZIP)
2. Run `build-installer.bat` second (adds installer to release)

### ✅ **Version Sync**
Both scripts read from `app\version.py`, so they're always in sync!

### ✅ **Testing Before Release**
Test locally first:
```batch
build-installer.bat
# Choose 'n' when asked to upload
# Test the installer
# If good, run again and choose 'y' to upload
```

### ✅ **Updating an Existing Release**
`build-installer.bat` uses `--clobber` flag, so it will replace the installer if you run it again for the same version.

---

## Quick Commands Reference

| Action | Command | Upload to GitHub? |
|--------|---------|-------------------|
| **Full release (ZIP)** | `release.bat` | ✅ Yes |
| **Add installer** | `build-installer.bat` → `y` | ✅ Yes |
| **Test installer locally** | `build-installer.bat` → `n` | ❌ No |
| **Just build (no installer)** | `build.bat` | ❌ No |

---

## Need Help?

- **GitHub CLI Docs:** https://cli.github.com/manual/
- **Inno Setup Docs:** https://jrsoftware.org/ishelp/
- **Issues?** Check error messages carefully - they include solutions!

---

**Last Updated:** November 2024  
**Related Files:** `release.bat`, `build-installer.bat`, `build.bat`



