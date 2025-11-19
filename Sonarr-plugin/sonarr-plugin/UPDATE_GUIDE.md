# 🔄 How to Update SonarrSeedr

## 📋 Update Process for Users

### **Option 1: Simple Update (Recommended)**

**What is Preserved:**
- ✅ Your Seedr authentication token
- ✅ All configuration settings
- ✅ Folder watcher settings
- ✅ Download history

**Steps:**

1. **Stop the current version:**
   - Right-click tray icon → Quit
   - OR Task Manager → End "SonarrSeedr.exe"

2. **Download new version:**
   - Get the new ZIP file (e.g., `SonarrSeedr-v1.2.0-[date].zip`)

3. **Extract to SAME location:**
   - Extract new files to your existing folder
   - Click "Yes" when asked to replace files
   - **Important:** This overwrites the .exe but keeps your config!

4. **Start the new version:**
   - Run `SonarrSeedr.exe`
   - Everything will work with your existing settings!

**That's it!** ✅ Your settings are automatically preserved.

---

### **Option 2: Clean Install (If having issues)**

**When to use:**
- App not starting after update
- Experiencing crashes
- Want fresh start

**Steps:**

1. **Backup your config:**
   ```
   Copy these folders to a safe location:
   - config/
   - completed/
   - processed/
   ```

2. **Delete old installation:**
   - Delete entire SonarrSeedr folder

3. **Install new version:**
   - Extract new ZIP to new location

4. **Restore config:**
   - Copy your backed-up `config/` folder to new installation
   - Copy other folders if needed

5. **Start app:**
   - Run `SonarrSeedr.exe`
   - Authenticate with Seedr again if needed

---

## 📁 What Gets Updated vs What Stays

### **Files That Get Replaced (Updated):**
- ✅ `SonarrSeedr.exe` - New version
- ✅ `_internal/` folder - Updated libraries
- ✅ Documentation files (.md, .txt)
- ✅ `debug.bat`

### **Files That Are Preserved (Your Data):**
- 🔒 `config/seedr_token.json` - Your authentication
- 🔒 `config/watcher_config.json` - Your settings
- 🔒 `completed/` - Downloaded files
- 🔒 `processed/` - Processed torrents
- 🔒 `error/` - Error logs
- 🔒 `folder_watcher.log` - Activity logs

**Why?** These files are in separate folders that don't get overwritten!

---

## 🔍 How to Check Your Version

### **Method 1: VERSION.txt file**
```
Open: VERSION.txt
Look for: Version: X.X.X
```

### **Method 2: Web Interface**
```
1. Open browser to http://localhost:8242
2. Look at bottom of page or dashboard
3. Version shown there
```

### **Method 3: API**
```
Visit: http://localhost:8242/docs
Check the version at the top
```

---

## 🆕 Release Naming Convention

Updates are named like:
```
SonarrSeedr-v1.1.0-20250211_181936.zip
         │      │            │
         │      │            └─ Build timestamp
         │      └─ Version number (MAJOR.MINOR.PATCH)
         └─ Application name
```

**Version Numbers:**
- **MAJOR** (1.x.x) - Big changes, may need reconfiguration
- **MINOR** (x.1.x) - New features, fully compatible
- **PATCH** (x.x.1) - Bug fixes, always safe to update

---

## ⚠️ Update Best Practices

### **Before Updating:**
1. ✅ Stop the app completely
2. ✅ Note your current version
3. ✅ Backup `config/` folder (optional but safe)
4. ✅ Read release notes if available

### **During Update:**
1. ✅ Extract to existing folder
2. ✅ Overwrite when prompted
3. ✅ Don't delete config manually

### **After Update:**
1. ✅ Start the app
2. ✅ Check it opens in browser
3. ✅ Verify tray icon appears
4. ✅ Test basic functionality

---

## 🚨 Troubleshooting Updates

### **Problem: App won't start after update**

**Solution:**
1. Check if old version is still running (Task Manager)
2. Restart computer
3. Try running `debug.bat` to see errors
4. Do clean install (Option 2 above)

### **Problem: Lost my settings**

**Solution:**
- Settings are in `config/` folder
- If you extracted to NEW location instead of same location, copy `config/` folder from old location

### **Problem: Authentication required again**

**Solution:**
- Normal if you did clean install
- Just authenticate with Seedr again
- Token will be saved in `config/seedr_token.json`

### **Problem: Different port after update**

**Solution:**
- Default port changed from 8000 to 8242 in recent version
- Visit: http://localhost:8242
- Or run: `SonarrSeedr.exe --port 8000` to use old port

### **Problem: Tray icon missing**

**Solution:**
- New feature in recent versions
- Requires `pystray` and `Pillow` libraries
- Rebuild from source if needed
- Or just use browser interface

---

## 📦 For Advanced Users: Building from Source

If you want the latest development version:

### **1. Get Latest Code:**
```bash
git pull origin main
# Or download ZIP from GitHub
```

### **2. Update Dependencies:**
```bash
pip install -r requirements.txt --upgrade
```

### **3. Rebuild:**
```bash
build.bat
```

### **4. Your Settings Are Safe:**
- Located in `config/` folder
- Not affected by rebuild
- Will work with new build

---

## 🔔 Stay Updated

### **How to Know When Updates Are Available:**

**Option A: Manual Check**
- Check GitHub releases page periodically
- Look for newer version numbers

**Option B: Subscribe to Notifications**
- Watch the GitHub repository
- Enable release notifications

**Option C: Check Changelog**
- Read `CHANGELOG.md` or release notes
- See what's new in each version

---

## 💡 Quick Update Checklist

```
[ ] Stop current version (right-click tray → Quit)
[ ] Download new ZIP file
[ ] Extract to SAME location as old version
[ ] Click "Yes" to overwrite files
[ ] Run SonarrSeedr.exe
[ ] Check browser opens to localhost:8242
[ ] Verify settings are intact
[ ] Done! ✅
```

---

## 📝 Example Update Scenario

### **Updating from v1.1.0 to v1.2.0:**

```
Old installation: C:\Apps\SonarrSeedr\
New ZIP: SonarrSeedr-v1.2.0-20250215_120000.zip

Steps:
1. Stop v1.1.0 (right-click tray icon → Quit)
2. Extract v1.2.0 ZIP
3. Copy contents to C:\Apps\SonarrSeedr\
4. Overwrite when prompted
5. Run C:\Apps\SonarrSeedr\SonarrSeedr.exe
6. Everything works with your old settings! ✅
```

---

## 🎯 Key Points to Remember

1. **Settings are separate** from the executable
2. **Always extract to same location** for easy updates
3. **Stop the app before updating** (important!)
4. **Config folder is preserved** automatically
5. **No need to reconfigure** after normal updates

---

## 🆘 Need Help?

- Check `folder_watcher.log` for errors
- Run `debug.bat` to see what's happening
- Backup `config/` before major version updates
- When in doubt, do a clean install with config backup

---

**Updating is easy!** Just replace the files and your settings stay intact! 🚀

