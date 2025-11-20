# Building Both Versions - Portable & Installer

This guide shows you how to build **both** the portable ZIP version and the installer version of Sonarr-Seedr.

## Two Distribution Methods

| Method | Best For | Installation | Data Storage | Admin Required |
|--------|----------|--------------|--------------|----------------|
| **Portable ZIP** | Power users, USB drives, testing | Extract & run | Next to exe | ❌ No |
| **Installer** | Regular users, permanent install | Run installer | AppData | ❌ No |

## Quick Build Commands

### Build Portable ZIP
```batch
build.bat
```
**Output:** `releases\SonarrSeedr-v1.1.9-[timestamp].zip`

### Build Installer
```batch
build-installer.bat
```
**Output:** `releases\installers\SonarrSeedr-Setup-v1.1.9.exe`

### Build Both (One Command)
```batch
build-both.bat
```
**Output:** Both ZIP and installer

---

## Method 1: Portable ZIP Version

### What It Does
- Stores all data **next to the executable**
- Truly portable (USB drive, different computers)
- No installation required
- Self-contained

### How to Build

1. **Run the build script:**
   ```batch
   build.bat
   ```

2. **Wait for completion** (takes 2-3 minutes)

3. **Find your ZIP:**
   ```
   releases\SonarrSeedr-v1.1.9-[timestamp].zip
   ```

### How Users Install It

1. Extract `SonarrSeedr-v1.1.9-[timestamp].zip` to any folder
2. Double-click `SonarrSeedr.exe`
3. Done! All data stays in that folder

### Data Location (Portable)
```
C:\MyFolder\SonarrSeedr\
├── SonarrSeedr.exe          ← The app
├── config\                  ← Configs here
├── logs\                    ← Logs here
├── torrents\                ← Torrents here
└── completed\               ← Downloads here
```

**No `.installed` marker file = Portable mode**

---

## Method 2: Windows Installer

### What It Does
- Installs to `AppData\Local\Seedr\`
- Stores data in `AppData\Local\Seedr\` (separate location)
- Appears in Windows app list
- Proper uninstaller
- No admin rights needed

### How to Build

1. **Install Inno Setup** (one-time setup):
   - Download: https://jrsoftware.org/isdl.php
   - Install to default location

2. **Run the installer build script:**
   ```batch
   build-installer.bat
   ```

3. **Wait for completion** (takes 3-4 minutes)

4. **Find your installer:**
   ```
   releases\installers\SonarrSeedr-Setup-v1.1.9.exe
   ```

### How Users Install It

1. Run `SonarrSeedr-Setup-v1.1.9.exe`
2. Click through the installation wizard
3. Choose install location (default: `C:\Users\You\AppData\Local\Seedr\`)
4. Done! App appears in Start Menu and Windows app list

### Data Location (Installed)
```
Application:
C:\Users\YourUsername\AppData\Local\Seedr\
├── SonarrSeedr.exe
├── .installed              ← Marker file (tells app to use AppData)
└── [other exe files]

Data (separate):
C:\Users\YourUsername\AppData\Local\Seedr\
├── config\                 ← Configs here
├── logs\                   ← Logs here
├── torrents\               ← Torrents here
└── completed\              ← Downloads here
```

**`.installed` marker file present = Installed mode (uses AppData)**

---

## Method 3: Build Both at Once

Create this batch file to build both versions:

```batch
@echo off
echo ================================
echo Building Both Versions
echo ================================
echo.

echo [1/2] Building portable ZIP...
call build.bat --auto
if errorlevel 1 (
    echo ERROR: Portable build failed!
    pause
    exit /b 1
)

echo.
echo [2/2] Building installer...
call build-installer.bat --auto
if errorlevel 1 (
    echo ERROR: Installer build failed!
    pause
    exit /b 1
)

echo.
echo ================================
echo SUCCESS: Both versions built!
echo ================================
echo.
echo Portable ZIP:
dir /b releases\*.zip | findstr /i "SonarrSeedr-v"
echo.
echo Installer:
dir /b releases\installers\*.exe
echo.
pause
```

Save as `build-both.bat` and run it.

---

## Key Differences

### Portable ZIP
- ✅ No installation
- ✅ Self-contained folder
- ✅ Run from USB drive
- ✅ Multiple instances
- ❌ Manual updates
- ❌ No Windows app list entry
- ❌ No uninstaller

### Installer
- ✅ Professional installation
- ✅ Windows app list entry
- ✅ Proper uninstaller
- ✅ Start Menu shortcuts
- ✅ No admin required
- ❌ Not portable
- ❌ Single location install

---

## Which to Distribute?

### Recommended: Offer Both!

**On your releases page:**
```
📦 SonarrSeedr v1.1.9

Installer (Recommended for most users):
  🟢 SonarrSeedr-Setup-v1.1.9.exe (12.5 MB)
     - Installs to your user profile
     - Appears in Windows apps list
     - Easy uninstall
     - No admin rights needed

Portable Version (For advanced users):
  🔵 SonarrSeedr-v1.1.9-[timestamp].zip (10.2 MB)
     - Extract and run anywhere
     - USB drive compatible
     - Self-contained folder
```

### Target Audiences

| User Type | Recommended Version | Why |
|-----------|-------------------|-----|
| Regular users | **Installer** | Easy, professional, appears in Windows |
| Power users | **Portable ZIP** | Flexibility, control, portability |
| Enterprise | **Both** | Installer for desktops, ZIP for servers |
| Testers | **Portable ZIP** | Quick test without installation |
| USB users | **Portable ZIP** | Run from anywhere |

---

## Installation Size

| Version | Download Size | Installed Size |
|---------|--------------|----------------|
| Portable ZIP | ~10 MB | ~25 MB (extracted) |
| Installer | ~12 MB | ~25 MB (installed) |

---

## Testing Both Versions

### Test Portable Version
1. Extract ZIP to `C:\Test\Portable\`
2. Run `SonarrSeedr.exe`
3. Check data is created in `C:\Test\Portable\config\`
4. ✅ Portable mode confirmed!

### Test Installed Version
1. Run `SonarrSeedr-Setup-v1.1.9.exe`
2. Complete installation
3. Run from Start Menu
4. Check data is in `%LOCALAPPDATA%\Seedr\config\`
5. Check `.installed` marker exists in exe folder
6. ✅ Installed mode confirmed!

---

## Troubleshooting

### Portable ZIP stores data in AppData
**Problem:** ZIP version using AppData instead of its own folder

**Solution:** Delete the `.installed` marker file from the exe directory

### Installer doesn't create marker file
**Problem:** Installed version storing data next to exe

**Solution:** Manually create `.installed` file in installation folder

### Both versions conflict
**Problem:** Both versions trying to run simultaneously

**Solution:** They're independent! Portable uses its folder, installed uses AppData

---

## Build Checklist

Before releasing:

**Portable ZIP:**
- [ ] Run `build.bat`
- [ ] Test ZIP extraction
- [ ] Verify no `.installed` file in ZIP
- [ ] Test data storage (should be next to exe)
- [ ] Test on clean machine
- [ ] Create GitHub release with ZIP

**Installer:**
- [ ] Run `build-installer.bat`
- [ ] Test installation
- [ ] Verify `.installed` marker created
- [ ] Test data storage (should be in AppData)
- [ ] Test uninstallation
- [ ] Test on clean machine
- [ ] Create GitHub release with installer

---

## Advanced: Customization

### Change Portable Detection
Edit `app/utils/paths.py`:
```python
installed_marker = exe_dir / '.installed'
```

### Change Installer Install Location
Edit `installer.iss`:
```ini
DefaultDirName={localappdata}\{#MyAppName}
```

Options:
- `{localappdata}` = `C:\Users\You\AppData\Local\`
- `{autopf}` = `C:\Program Files\` (requires admin)
- `{userappdata}` = `C:\Users\You\AppData\Roaming\`

---

## FAQ

**Q: Can users have both versions installed?**
A: Yes! They're completely independent. Portable uses its folder, installed uses AppData.

**Q: Do I need to build both every release?**
A: Recommended! Different users prefer different methods.

**Q: Which version updates easier?**
A: Installed version can support auto-updates. Portable requires manual replacement.

**Q: Does portable need `.installed` file?**
A: No! Portable specifically should NOT have it. That's how we detect portable vs installed.

**Q: Can I convert portable to installed?**
A: Yes, just run the installer. Your portable version can stay or be deleted.

**Q: Does installed version need admin?**
A: No! It installs to your user profile (`%LOCALAPPDATA%`), no admin needed.

---

**Happy Building!** 🚀






