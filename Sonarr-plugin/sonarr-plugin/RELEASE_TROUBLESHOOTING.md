# 🔧 Release Script Troubleshooting Guide

Common issues and solutions when using the automated release scripts.

---

## ❌ Error: "Could not find ZIP file in releases folder"

### **What happened:**
The build completed but the script couldn't find the expected ZIP file.

### **Why it happens:**
Usually a version mismatch:
- Script updated `version.py` to `1.1.6`
- But `build.bat` created a ZIP with version `1.1.4`
- This can happen due to Python bytecode caching

### **Solution (Now Fixed!):**
The scripts now:
1. ✅ Clear Python cache before building
2. ✅ Look for the most recent ZIP if expected version not found
3. ✅ Warn you about version mismatches
4. ✅ Ask for confirmation before continuing

### **Manual Fix (if still occurs):**
```bash
# Delete all Python cache
rmdir /s /q app\__pycache__
del /s app\*.pyc

# Re-run the release
RUN_RELEASE.bat
```

---

## ❌ Error: "GitHub CLI (gh) not found"

### **What happened:**
The `gh` command is not installed or not in PATH.

### **Solutions:**

#### **Option 1: Use Manual Release** ⭐ **EASIEST!**
```bash
release_manual.bat
```
This builds your app and opens GitHub in browser for manual upload!

#### **Option 2: Install GitHub CLI**
1. Download from: https://cli.github.com/
2. Install it
3. **Restart PowerShell/Terminal** (important!)
4. Run: `gh auth login`
5. Try release again

#### **Option 3: Refresh PATH**
After installing `gh`, restart your terminal or run:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

---

## ❌ Error: "You are not logged in to GitHub"

### **What happened:**
GitHub CLI is installed but not authenticated.

### **Solution:**
```bash
gh auth login
```

Follow the prompts to authenticate with GitHub.

---

## ❌ Error: "Build failed!"

### **What happened:**
PyInstaller encountered an error during the build.

### **Common causes:**

#### **1. Missing dependencies**
```bash
pip install -r requirements.txt
```

#### **2. Syntax error in code**
Check the error message for the file and line number.

#### **3. Import errors**
Make sure all modules are properly imported in `sonarr_seedr.spec`.

---

## ❌ Error: "Failed to create GitHub release"

### **What happened:**
The `gh release create` command failed.

### **Common causes:**

#### **1. Tag already exists**
```bash
# Delete the tag locally and remotely
git tag -d v1.2.0
git push origin :refs/tags/v1.2.0

# Try release again
```

#### **2. Network issues**
Check your internet connection and try again.

#### **3. Repository access**
Make sure you have write access to `jose987654/sonarr-plugin`.

### **Solution:**
Use manual release:
```bash
release_manual.bat
```

---

## ❌ Script closes immediately

### **What happened:**
The script window closes without showing any output.

### **Why it happens:**
Usually an early error in the script.

### **Solution (Now Fixed!):**
All scripts now have error trapping and will pause on exit.

### **If still occurs:**
1. Run from PowerShell/CMD (don't double-click)
2. Check the output before it closes
3. Use the PowerShell version for better error messages:
   ```bash
   RUN_RELEASE.bat
   ```

---

## ⚠️ Warning: "ZIP file version mismatch"

### **What happened:**
Script shows:
```
WARNING: ZIP file version mismatch!
Expected: v1.1.6
Found:    SonarrSeedr-v1.1.4-20250211_173520.zip
```

### **What to do:**

#### **Option 1: Continue anyway**
Press `y` to use the found ZIP file. The version number in the filename doesn't affect functionality.

#### **Option 2: Cancel and rebuild**
Press `n` to cancel, then:
```bash
# Clear cache
rmdir /s /q app\__pycache__

# Update version.py manually to match
# Then run release again
```

---

## 🎯 Best Practices

### **1. Always use fresh terminal**
Close and reopen your terminal before running release scripts.

### **2. Check version.py before releasing**
Make sure `app\version.py` has the correct version number.

### **3. Test build first**
Run `build.bat` alone first to catch any build errors:
```bash
build.bat
```

### **4. Use manual release when in doubt**
The manual release helper is reliable and easy:
```bash
release_manual.bat
```

### **5. Keep releases separate from source**
- Releases: `jose987654/sonarr-plugin` (for end users)
- Source code: `jose987654/sonarr-ext` (for development)

---

## 📋 Quick Command Reference

| Task | Command |
|------|---------|
| **Build only** | `build.bat` |
| **Manual release** | `release_manual.bat` ⭐ |
| **Auto release (PowerShell)** | `RUN_RELEASE.bat` |
| **Auto release (Batch)** | `release.bat` |
| **Install gh CLI** | `winget install --id GitHub.cli` |
| **Login to GitHub** | `gh auth login` |
| **Clear Python cache** | `rmdir /s /q app\__pycache__` |

---

## 🆘 Still Having Issues?

### **Try the manual release helper:**
```bash
release_manual.bat
```

This is the most reliable method and requires no setup!

### **Or follow the manual guide:**
See `MANUAL_RELEASE.md` for step-by-step instructions.

---

**Remember:** The release scripts are helpers to save time, but manual releasing is always a valid option! 🚀

