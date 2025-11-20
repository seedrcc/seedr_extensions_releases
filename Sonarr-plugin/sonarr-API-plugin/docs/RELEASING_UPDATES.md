# 🚀 How to Release Updates (For Developers)

## 📝 Pre-Release Checklist

Before building and releasing a new version:

### 1. **Update Version Number**

Edit `app/version.py`:

```python
__version__ = "1.2.0"  # Update this
__build_date__ = "2025-02-15"  # Update this
__description__ = "Sonarr-Seedr Integration with Auto-Download"

# Version history:
# 1.2.0 - New features added (describe what's new)
# 1.1.0 - Added automatic polling and local download from Seedr
# 1.0.0 - Initial release with upload to Seedr functionality
```

**Version Numbering:**
- **MAJOR.MINOR.PATCH** (e.g., 1.2.0)
- **MAJOR**: Breaking changes (user needs to reconfigure)
- **MINOR**: New features (fully compatible)
- **PATCH**: Bug fixes (safe to update)

### 2. **Test Everything**

```bash
# Test in development
python run.py

# Test build
build.bat

# Test the executable
cd dist\SonarrSeedr
SonarrSeedr.exe

# Check:
# - App starts without errors
# - Tray icon appears
# - Browser opens
# - All features work
# - API responds: http://localhost:8242/api/version
```

### 3. **Update Documentation**

Check if these need updates:
- ✅ `README.md` - Any new features?
- ✅ `SIMPLE_USAGE.md` - New setup steps?
- ✅ `HOW_TO_USE.txt` - Changed behavior?
- ✅ `UPDATE_GUIDE.md` - New update notes?

---

## 🔨 Building the Release

### **Step 1: Clean Build**

```bash
# Make sure everything is saved
# Run the build
build.bat
```

This creates:
- `dist\SonarrSeedr\` - Distribution folder
- `releases\SonarrSeedr-v1.2.0-[timestamp].zip` - Release package

### **Step 2: Test the Build**

```bash
cd dist\SonarrSeedr
SonarrSeedr.exe
```

**Test checklist:**
- [ ] App starts without console window
- [ ] Browser opens automatically
- [ ] Tray icon appears
- [ ] Can authenticate with Seedr
- [ ] Can configure settings
- [ ] Folder watcher works
- [ ] All API endpoints work

### **Step 3: Test Update Process**

Simulate user update:

```bash
# 1. Install "old" version somewhere
# 2. Configure it (add some settings)
# 3. Extract new version to SAME location
# 4. Overwrite files
# 5. Run new version
# 6. Verify settings are preserved
```

---

## 📦 Creating the Release Package

### **What Gets Included:**

The `build.bat` automatically creates a ZIP with:

```
SonarrSeedr-v1.2.0-[timestamp].zip
├── SonarrSeedr.exe        - Main executable
├── _internal/             - Python runtime & libraries
├── config/                - Empty config folder structure
├── completed/             - Empty folder
├── processed/             - Empty folder  
├── error/                 - Empty folder
├── torrents/              - Empty folder
├── README.md              - Project overview
├── LICENSE                - License file
├── SIMPLE_USAGE.md        - Complete setup guide
├── HOW_TO_USE.txt         - Quick start guide
├── UPDATE_GUIDE.md        - Update instructions
├── update.bat             - Update helper script
├── debug.bat              - Debug helper
└── VERSION.txt            - Version information
```

### **What's NOT Included (Good!):**

- ❌ User's `config/seedr_token.json` (sensitive!)
- ❌ User's downloaded files
- ❌ User's logs
- ❌ Development files (.py source)

---

## 🌐 Publishing the Release

### **Option 1: GitHub Releases (Recommended)**

1. **Commit and Push:**
   ```bash
   git add .
   git commit -m "Release v1.2.0 - New features and bug fixes"
   git push origin main
   ```

2. **Create GitHub Release:**
   - Go to GitHub → Releases → Create new release
   - Tag version: `v1.2.0`
   - Release title: `SonarrSeedr v1.2.0`
   - Description: List changes (see template below)
   - Upload: `releases/SonarrSeedr-v1.2.0-[timestamp].zip`
   - Publish release

3. **Release Notes Template:**
   ```markdown
   ## 🎉 What's New in v1.2.0
   
   ### ✨ New Features
   - Added system tray icon support
   - Hidden console window for cleaner experience
   - Added /api/version endpoint
   
   ### 🐛 Bug Fixes
   - Fixed Unicode encoding crash
   - Fixed syntax errors in seedr_sonarr_integration.py
   
   ### 📝 Changes
   - Changed default port from 8000 to 8242
   - Updated dependencies (pystray, Pillow)
   
   ### ⬇️ Download
   - [Download SonarrSeedr-v1.2.0.zip](link)
   
   ### 📚 Documentation
   - See UPDATE_GUIDE.md for update instructions
   - See SIMPLE_USAGE.md for setup guide
   
   ### 🔄 Updating from v1.1.0
   Simple! Just extract to your existing installation and overwrite files.
   Your settings will be preserved automatically.
   ```

### **Option 2: Direct Distribution**

If not using GitHub:

1. **Upload ZIP to:**
   - Your website
   - Google Drive / Dropbox (shared link)
   - File hosting service

2. **Share the link with:**
   - Release notes (what's new)
   - Update instructions (link to UPDATE_GUIDE.md)
   - Support contact

---

## 📢 Notifying Users

### **Methods to Inform Users:**

1. **GitHub Release** (auto-notifies watchers)
2. **Email** (if you have user list)
3. **Website/Blog Post**
4. **Social Media**
5. **Discord/Telegram** (if you have community)

### **What to Tell Users:**

```
🎉 SonarrSeedr v1.2.0 Released!

What's New:
- System tray icon
- Hidden console
- Bug fixes

Download: [link]
Update Guide: [link to UPDATE_GUIDE.md]

Updating is easy - just extract to your existing folder!
```

---

## 🔍 Version Checking (For Future Auto-Update Feature)

Users can check their version:

### **Via API:**
```bash
curl http://localhost:8242/api/version
```

Response:
```json
{
  "version": "1.2.0",
  "build_date": "2025-02-15",
  "description": "Sonarr-Seedr Integration with Auto-Download",
  "api_version": "v1"
}
```

### **Via File:**
Check `VERSION.txt` in installation folder

---

## 🛠️ Hotfix Release Process

For urgent bug fixes:

1. **Update version** (increment PATCH): `1.2.0` → `1.2.1`
2. **Fix the bug**
3. **Test thoroughly**
4. **Build and release** (same process as above)
5. **Notify users** with urgency level

---

## 📋 Release Checklist

Use this before every release:

```
Pre-Release:
[ ] Updated version number in app/version.py
[ ] Updated version history in app/version.py
[ ] Tested in development mode
[ ] Updated documentation if needed
[ ] Committed all changes to git

Building:
[ ] Ran build.bat successfully
[ ] Tested the exe (starts, works, no errors)
[ ] Verified VERSION.txt shows correct version
[ ] Checked ZIP file contains all needed files

Testing:
[ ] Fresh install works
[ ] Update from previous version works
[ ] Settings are preserved after update
[ ] All features functional
[ ] API /api/version returns correct version

Release:
[ ] Created GitHub release with tag
[ ] Uploaded ZIP file
[ ] Written release notes
[ ] Tested download link works
[ ] Notified users (if applicable)

Post-Release:
[ ] Monitor for bug reports
[ ] Answer user questions
[ ] Plan next version features
```

---

## 🔄 Version History Best Practices

Keep `app/version.py` updated:

```python
# Version history:
# 1.2.1 - Fixed tray icon crash on startup
# 1.2.0 - Added system tray icon, hidden console
# 1.1.0 - Added automatic polling and local download from Seedr
# 1.0.0 - Initial release with upload to Seedr functionality
```

This helps you and users track what changed!

---

## 💡 Tips

1. **Test updates** before releasing:
   - Install old version
   - Configure it
   - Update to new version
   - Verify settings survive

2. **Keep releases organized:**
   - `releases/` folder has all ZIPs
   - Timestamp in filename helps
   - Don't delete old versions (users might need them)

3. **Semantic versioning:**
   - Major: Breaking changes
   - Minor: New features
   - Patch: Bug fixes

4. **Always test the .exe:**
   - Don't just test with `python run.py`
   - Actual users run the .exe
   - Test with console=False

5. **Document changes:**
   - Users need to know what's new
   - Helps with support questions
   - Makes updates less scary

---

## 🚨 Emergency Rollback

If a release has critical bugs:

1. **Remove the bad release** from download links
2. **Post notice** about the issue
3. **Point users** to previous stable version
4. **Fix the bug** and release hotfix (increment patch)
5. **Test more thoroughly** next time

---

## 📈 Roadmap (Future Ideas)

- [ ] Auto-update checker (checks GitHub for new version)
- [ ] In-app update notification
- [ ] One-click update button
- [ ] Automatic backup before update
- [ ] Update logs/changelog viewer in app

---

**Remember:** Users trust you with their setup. Test thoroughly before releasing! 🎯

