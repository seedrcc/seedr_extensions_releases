# 🎯 System Tray Icon Setup Guide

## ✨ What You Get

When you build with the system tray icon, you'll have:
- ✅ **Seedr icon in notification area** (near the clock)
- ✅ **Hidden console window** (clean and professional)
- ✅ **Quick menu** - Right-click for options
- ✅ **Easy control** - Open browser, quit app, etc.

---

## 📋 Requirements

You need these additional libraries installed:

```bash
pip install pystray Pillow
```

Or install all requirements:

```bash
pip install -r requirements.txt
```

---

## 🔧 What Was Added

### 1. **New Module: `app/tray_icon.py`**
- Creates system tray icon
- Uses your `logo.ico` file
- Provides menu with options

### 2. **Updated: `run.py`**
- Auto-starts tray icon when running as .exe
- Only shows tray icon in compiled version (not when running with Python)

### 3. **Updated: `requirements.txt`**
- Added `pystray>=0.19.0`
- Added `Pillow>=10.0.0`

### 4. **Updated: `sonarr_seedr.spec`**
- Includes `logo.ico` in build
- Includes tray icon module
- Includes Pillow dependencies

---

## 🚀 How to Build

### Step 1: Install Dependencies

```bash
pip install pystray Pillow
```

### Step 2: Build the Application

```bash
build.bat
```

### Step 3: Run and Test

```bash
cd dist\SonarrSeedr
SonarrSeedr.exe
```

**Expected Result:**
- ✅ No console window appears
- ✅ Seedr icon appears in system tray (near clock)
- ✅ Browser opens to http://localhost:8242
- ✅ Right-click icon for menu

---

## 🎨 Tray Icon Menu

Right-click the tray icon to see:

```
┌─────────────────────────────────┐
│ Open Web Interface         [⭐]  │  ← Opens http://localhost:8242
│ Dashboard                        │  ← Opens dashboard page
│ API Documentation                │  ← Opens /docs
├─────────────────────────────────┤
│ Running on port 8242             │  ← Info (disabled)
├─────────────────────────────────┤
│ Quit SonarrSeedr                 │  ← Stops the app
└─────────────────────────────────┘
```

### Menu Options:

1. **Open Web Interface** (Default - double-click)
   - Opens http://localhost:8242 in browser
   
2. **Dashboard**
   - Opens dashboard page
   
3. **API Documentation**
   - Opens interactive API docs at /docs
   
4. **Quit SonarrSeedr**
   - Stops the application completely

---

## 💡 Features

### ✅ **Smart Detection**
- Tray icon only appears when running as `.exe`
- When running with `python run.py`, no tray icon (not needed)

### ✅ **Automatic Icon Loading**
- Uses your `logo.ico` file automatically
- Falls back to simple icon if logo.ico not found

### ✅ **Clean Exit**
- Clicking "Quit" properly stops the server
- No orphaned processes

### ✅ **Hidden Console**
- Combined with `console=False` in spec file
- Professional appearance

---

## 🔍 How to Find the Icon

After running `SonarrSeedr.exe`:

1. **Look at bottom-right of screen** (Windows taskbar)
2. **Near the clock** and WiFi/volume icons
3. **Click the up arrow** (^) if you don't see it
4. **Look for your Seedr icon**

### If Icon Not Visible:

The icon might be in the **hidden icons area**:
- Click the small **up arrow (^)** on taskbar
- Look for the Seedr icon there
- **Drag it to taskbar** to keep visible

---

## 🛠️ Troubleshooting

### Icon Doesn't Appear

**Problem:** No icon in system tray after running .exe

**Solutions:**
1. Check if `pystray` is installed:
   ```bash
   pip install pystray Pillow
   ```

2. Rebuild the application:
   ```bash
   build.bat
   ```

3. Check if logo.ico exists in project folder

4. Look in hidden icons (click ^ near clock)

### Import Error During Build

**Problem:** PyInstaller can't find pystray

**Solution:**
```bash
pip install pystray Pillow
pyinstaller sonarr_seedr.spec --clean
```

### Icon Shows But No Menu

**Problem:** Right-click doesn't show menu

**Solutions:**
1. Try left-click first
2. Wait a few seconds for app to fully start
3. Check if app is actually running (Task Manager)

### Wrong Icon Shows

**Problem:** Generic icon instead of Seedr logo

**Solutions:**
1. Make sure `logo.ico` is in project root
2. Rebuild: `build.bat`
3. Check if logo.ico is valid (open it in Windows)

---

## 🎯 Testing Without Building

You can test the tray icon without building:

```bash
# Make sure dependencies are installed
pip install pystray Pillow

# Run the test
python app/tray_icon.py
```

This will show the tray icon. Press `Ctrl+C` to exit.

---

## 📝 Configuration

### Change the Port in Menu

The menu automatically shows which port the app is running on.

If you change the port:
```bash
SonarrSeedr.exe --port 9999
```

The menu will show "Running on port 9999"

### Customize Menu Items

Edit `app/tray_icon.py` to add/remove menu items:

```python
def create_menu(self):
    return Menu(
        MenuItem('Open Web Interface', self.open_browser, default=True),
        MenuItem('Dashboard', self.open_dashboard),
        # Add your custom menu items here
        Menu.SEPARATOR,
        MenuItem('Quit SonarrSeedr', self.quit_app)
    )
```

---

## 🎨 Using a Different Icon

### Option 1: Replace logo.ico

Simply replace `logo.ico` with your new icon file (must be named `logo.ico`)

### Option 2: Edit tray_icon.py

Change line in `app/tray_icon.py`:

```python
icon_path = base_path / 'your_icon_name.ico'
```

Then update `sonarr_seedr.spec`:

```python
('your_icon_name.ico', '.'),
```

---

## ✨ Summary

### Before (Without Tray Icon):
- ❌ Console window visible
- ❌ No way to know app is running
- ❌ Must close from Task Manager

### After (With Tray Icon):
- ✅ Console hidden (professional)
- ✅ Icon in system tray (visible status)
- ✅ Easy access via right-click menu
- ✅ Simple quit option
- ✅ Quick browser access

---

## 🚀 Quick Start Checklist

- [ ] Install dependencies: `pip install pystray Pillow`
- [ ] Make sure `logo.ico` exists in project root
- [ ] Run: `build.bat`
- [ ] Test: `dist\SonarrSeedr\SonarrSeedr.exe`
- [ ] Check system tray for icon (near clock)
- [ ] Right-click icon to see menu
- [ ] Test "Open Web Interface" option
- [ ] Test "Quit" option

**All working?** You're done! Enjoy your professional app! 🎉

---

## 📞 Need Help?

- **Icon not showing?** Check hidden icons (^ near clock)
- **Import errors?** Run: `pip install -r requirements.txt`
- **Build fails?** Make sure all files are saved and try again
- **App crashes?** Check `folder_watcher.log` for errors

---

**Version with tray icon is the best user experience!** 🌟

