# 🚀 Auto-Update Feature Setup Guide

This guide explains how to configure the **auto-update feature** in your Sonarr-Seedr plugin so users can update with one click!

---

## 📋 Overview

The auto-update feature allows users to:
- ✅ Check for updates from within the app
- ✅ Download new versions automatically
- ✅ Install updates with one click
- ✅ Automatic restart after update

---

## ⚙️ Configuration Required

### **Step 1: Update GitHub Repository URL**

You need to configure your GitHub repository URL in the update service.

**File:** `app/service/update_service.py`

Find this line (around line 17):

```python
GITHUB_REPO = "YOUR_USERNAME/sonarr-seedr-plugin"
```

**Already configured for you:**

```python
GITHUB_REPO = "jose987654/sonarr-plugin"
```

✅ **This is already set up and ready to use!**

Your repository: [https://github.com/jose987654/sonarr-plugin](https://github.com/jose987654/sonarr-plugin)

---

### **Step 2: Create GitHub Releases**

For the auto-update to work, you need to create proper GitHub releases.

#### How to Create a Release:

1. **Go to your GitHub repository**
2. **Click "Releases" → "Create a new release"**
3. **Create a tag** (e.g., `v1.2.0`)
   - ⚠️ **Important:** Tag format should be `vX.Y.Z` (e.g., `v1.2.0`)
4. **Set release title** (e.g., "Version 1.2.0")
5. **Write release notes** (what's new):

```markdown
## What's New in v1.2.0

- Added auto-update feature
- Improved performance
- Fixed bug with torrent downloads
- Enhanced UI design
```

6. **Upload the ZIP file** (from `releases/` folder after build)
   - The ZIP name should be something like `SonarrSeedr-v1.2.0-timestamp.zip`
7. **Click "Publish release"**

---

### **Step 3: Update Settings Page GitHub Link (Optional)**

In `app/web/templates/settings.html`, update the GitHub link (around line 95):

```html
<td><a href="https://github.com/YOUR_USERNAME/sonarr-seedr-plugin" target="_blank" style="color: #3182ce;">View on GitHub</a></td>
```

Change to:

```html
<td><a href="https://github.com/yourusername/sonarr-seedr" target="_blank" style="color: #3182ce;">View on GitHub</a></td>
```

---

## 🎯 How It Works

### **For Users:**

1. User opens the app: `http://localhost:8242/settings`
2. Clicks "Check for Updates" button
3. App fetches latest release from GitHub
4. If new version available, shows "Download & Install" button
5. User clicks install → app downloads, installs, and restarts automatically
6. Done! ✅

### **Behind the Scenes:**

```
User clicks "Check for Updates"
    ↓
Frontend calls: GET /api/check-update
    ↓
Backend fetches: https://api.github.com/repos/{user}/{repo}/releases/latest
    ↓
Compares current version (1.1.0) vs latest (1.2.0)
    ↓
If newer: Show update button
    ↓
User clicks "Install Update"
    ↓
Frontend calls: POST /api/install-update
    ↓
Backend:
  1. Downloads ZIP from GitHub
  2. Extracts to temp folder
  3. Creates updater.bat script
  4. Starts updater.bat
  5. Exits app
    ↓
updater.bat:
  1. Waits for app to close
  2. Copies new files over old files
  3. Restarts SonarrSeedr.exe
  4. Deletes itself
    ↓
User sees updated app! 🎉
```

---

## 📝 Version Numbering

Use **semantic versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (1.0.0 → 2.0.0)
- **MINOR**: New features (1.1.0 → 1.2.0)
- **PATCH**: Bug fixes (1.1.0 → 1.1.1)

### Where to Update Version:

**File:** `app/version.py`

```python
__version__ = "1.2.0"  # Update this!
__build_date__ = "2025-02-11"
__description__ = "Sonarr-Seedr Integration Plugin"
```

---

## 🧪 Testing the Auto-Update

### **Option 1: Test with Real GitHub Release**

1. Build your app: `build.bat`
2. Create a GitHub release (e.g., v1.2.0)
3. Upload the ZIP to the release
4. Change `app/version.py` back to an older version (e.g., 1.1.0)
5. Rebuild: `build.bat`
6. Run the app and go to Settings
7. Click "Check for Updates" → should find v1.2.0
8. Click "Install" → should update successfully

### **Option 2: Test Locally (Without GitHub)**

For testing without creating real releases, you can modify the update service temporarily:

1. Comment out the GitHub API call
2. Return mock data with a fake version
3. Test the UI and download flow

---

## 🔧 Troubleshooting

### **Problem: "Update check failed" error**

**Solution:**
- Check if GitHub repository URL is correct in `update_service.py`
- Ensure you have at least one release published on GitHub
- Check internet connection

### **Problem: "No assets found" in release**

**Solution:**
- Make sure you uploaded the ZIP file to the GitHub release
- The ZIP should be attached as an "asset" to the release

### **Problem: Version comparison not working**

**Solution:**
- Ensure version format is `X.Y.Z` (no prefix like "v")
- The GitHub tag should be `vX.Y.Z` (with "v")
- The code strips the "v" automatically

### **Problem: Update downloads but doesn't install**

**Solution:**
- Check if `updater.bat` was created in the app directory
- Ensure the app has write permissions to its own directory
- Check Windows Task Manager to see if updater is running

---

## 📦 What Gets Updated

✅ **Updated files:**
- `SonarrSeedr.exe`
- All DLL files and libraries
- Templates and static files
- Documentation files

❌ **NOT updated (preserved):**
- `config/` folder (user settings)
- User's Seedr token
- Watcher configuration
- Download history

This ensures users never lose their settings during updates!

---

## 🎉 Benefits

- ✅ **One-click updates** for users
- ✅ **No manual file management**
- ✅ **Settings preserved automatically**
- ✅ **Professional user experience**
- ✅ **Automatic version checking**
- ✅ **Built-in changelog display**

---

## 📚 Files Involved

| File | Purpose |
|------|---------|
| `app/service/update_service.py` | Core update logic |
| `app/web/templates/settings.html` | Settings page UI |
| `app/main.py` | API endpoints (`/api/check-update`, `/api/install-update`) |
| `app/version.py` | Version information |
| `sonarr_seedr.spec` | PyInstaller config (includes update modules) |
| `requirements.txt` | Added `packaging` dependency |

---

## 🚀 Quick Start Checklist

- [ ] Update `GITHUB_REPO` in `app/service/update_service.py`
- [ ] Update GitHub link in `settings.html` (optional)
- [ ] Create your first GitHub release
- [ ] Upload build ZIP to release
- [ ] Test the update feature
- [ ] Enjoy automated updates! 🎉

---

## 💡 Pro Tips

1. **Always test updates** on a test machine before releasing
2. **Write clear release notes** so users know what's new
3. **Use consistent version numbering** (semantic versioning)
4. **Create pre-releases** on GitHub for beta testing
5. **Keep old releases available** in case users need to downgrade

---

## ❓ Questions?

If you need help setting this up:
1. Check the GitHub API URL is correct
2. Ensure you have at least one release
3. Verify the ZIP is uploaded correctly
4. Test locally first before releasing

Happy updating! 🎊

