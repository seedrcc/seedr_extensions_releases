# Data Storage Locations

This document explains where Sonarr-Seedr stores its data files depending on how you run it.

## Three Deployment Methods

### 1. Installed Version (via Installer)

When you install the application using the Windows installer, all user data is stored in your Windows user profile to avoid permission issues.

### Data Directory
```
C:\Users\YourUsername\AppData\Local\Seedr\
```

### Subdirectories

| Directory | Purpose | Location |
|-----------|---------|----------|
| **config** | Configuration files | `%LOCALAPPDATA%\Seedr\config\` |
| **logs** | Application logs | `%LOCALAPPDATA%\Seedr\logs\` |
| **torrents** | Torrent files to watch | `%LOCALAPPDATA%\Seedr\torrents\` |
| **completed** | Downloaded files | `%LOCALAPPDATA%\Seedr\completed\` |
| **processed** | Processed torrent files | `%LOCALAPPDATA%\Seedr\processed\` |
| **error** | Failed torrent files | `%LOCALAPPDATA%\Seedr\error\` |

### Key Files

| File | Purpose | Location |
|------|---------|----------|
| **seedr_token.json** | Seedr authentication token | `%LOCALAPPDATA%\Seedr\config\seedr_token.json` |
| **watcher_config.json** | Torrent watcher settings | `%LOCALAPPDATA%\Seedr\config\watcher_config.json` |
| **folder_watcher.log** | Application log file | `%LOCALAPPDATA%\Seedr\logs\folder_watcher.log` |

### 2. Portable Version (from ZIP)

When you extract and run the application from a ZIP file (portable mode), all data is stored **next to the executable**.

**Installation:** `C:\MyFolder\SonarrSeedr\`

```
C:\MyFolder\SonarrSeedr\
├── SonarrSeedr.exe          ← The executable
├── config\                  ← Stored here
│   ├── seedr_token.json
│   └── watcher_config.json
├── logs\                    ← Stored here
│   └── folder_watcher.log
├── torrents\                ← Stored here
├── completed\               ← Stored here
├── processed\               ← Stored here
└── error\                   ← Stored here
```

**Benefits:**
- ✅ Truly portable (USB drive, different computers)
- ✅ Self-contained (everything in one folder)
- ✅ No installation required
- ✅ Multiple instances possible

### 3. Running from Source (Development)

When running from source (development mode), all data is stored in the project directory:

```
D:\YourProject\sonarr-fast-API-plugin\
├── config\
│   ├── seedr_token.json
│   └── watcher_config.json
├── logs\
│   └── folder_watcher.log
├── torrents\
├── completed\
├── processed\
└── error\
```

## Quick Access

### Opening Data Folder (Windows)

1. Press `Win + R`
2. Type: `%LOCALAPPDATA%\Seedr`
3. Press Enter

Or copy this path into File Explorer's address bar:
```
%LOCALAPPDATA%\Seedr
```

### Opening Logs

1. Press `Win + R`
2. Type: `%LOCALAPPDATA%\Seedr\logs`
3. Press Enter

## Why This Approach?

### Problem with Program Files
When installed in `C:\Program Files\`, Windows blocks write access for security reasons. This causes:
- ❌ Cannot write log files
- ❌ Cannot save configuration
- ❌ Cannot create torrent files
- ❌ Application crashes with "Permission Denied" errors

### Solution: AppData
Using `%LOCALAPPDATA%` (AppData\Local):
- ✅ Full write permissions
- ✅ Per-user data isolation
- ✅ Follows Windows conventions
- ✅ Works without admin rights
- ✅ Data persists across updates

## Backup Your Data

To backup your settings and data:

1. Open `%LOCALAPPDATA%\Seedr`
2. Copy the entire `Seedr` folder to your backup location
3. To restore, copy it back to `%LOCALAPPDATA%\`

## Uninstalling

When you uninstall the application:
- The installer removes files from `C:\Program Files\Seedr\`
- Your data in `%LOCALAPPDATA%\Seedr\` is **preserved**

### Complete Removal

To completely remove all data:

1. Uninstall the application (Windows Settings > Apps)
2. Manually delete: `%LOCALAPPDATA%\Seedr\`

## Portable Version

If you're using the portable ZIP version (not the installer):
- Data is stored in the same folder as the executable
- This allows running from a USB drive
- No AppData folder is used

## Troubleshooting

### Can't Find Data Folder
If you can't see the data folder:

1. Show hidden files:
   - Open File Explorer
   - Click View > Show > Hidden items
   
2. Or use the full path:
   ```
   C:\Users\<YourUsername>\AppData\Local\Seedr\
   ```

### Permission Issues
If you still get permission errors after installing:

1. Check that the app is installed via the installer (not just copied)
2. Verify data is in `%LOCALAPPDATA%\Seedr\` (not Program Files)
3. Run the app normally (not as Administrator)

### Missing Configuration
If your configuration is lost after update:

1. Check `%LOCALAPPDATA%\Seedr\config\`
2. Look for `seedr_token.json` and `watcher_config.json`
3. If missing, you'll need to reconfigure

## How Does the App Know Which Mode It's In?

The application uses a **marker file** system:

| Mode | Detection Method | Data Location |
|------|-----------------|---------------|
| **Installed** | `.installed` file exists in exe directory | `%LOCALAPPDATA%\Seedr\` |
| **Portable** | No `.installed` file in exe directory | Next to exe |
| **Source** | Not compiled (Python script) | Project directory |

### The Marker File

When you install via the installer:
- A hidden file `.installed` is created in `C:\Users\You\AppData\Local\Seedr\.installed`
- This tells the app: "I'm installed, use AppData for data"

When you run from ZIP:
- No `.installed` file exists
- The app says: "I'm portable, use my own folder"

## Technical Details

### Path Detection Logic

The application automatically detects where to store data:

```python
if running_as_compiled_exe:
    if '.installed' file exists:
        # INSTALLED - use AppData
        data_dir = "C:/Users/You/AppData/Local/Seedr/"
    else:
        # PORTABLE - use exe directory
        data_dir = "C:/MyFolder/SonarrSeedr/"
else:
    # DEVELOPMENT - use project directory
    data_dir = "ProjectDirectory/"
```

### Migration from Old Versions

If you're upgrading from an older version that stored data in the installation directory:

1. Your old data is in: `C:\Program Files\Seedr\config\`
2. New data location: `%LOCALAPPDATA%\Seedr\config\`
3. Manually copy `seedr_token.json` to the new location to preserve your login

## Best Practices

1. **Regular Backups**: Backup `%LOCALAPPDATA%\Seedr\config\` regularly
2. **Check Logs**: Monitor `%LOCALAPPDATA%\Seedr\logs\` for issues
3. **Clean Up**: Periodically clean old files from `completed` and `processed` folders
4. **Security**: Keep `seedr_token.json` secure (contains authentication token)

## Support

If you experience issues with file permissions or data locations:

1. Check Windows Event Viewer for permission errors
2. Verify the installer was used (not manual copy)
3. Ensure you have disk space in `%LOCALAPPDATA%`
4. Try running the application normally (not as admin)

---

**Note**: This new data location system was introduced in version 1.0.0 to fix permission issues when installed in Program Files.

