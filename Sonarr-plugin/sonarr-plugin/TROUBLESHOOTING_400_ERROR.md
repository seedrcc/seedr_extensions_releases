# Troubleshooting 400 Bad Request Errors

## Overview
This document explains the "400 Bad Request" error that can occur when attempting to download files through the Sonarr-Seedr plugin interface.

## Error Message
```
Failed to load resource: the server responded with a status of 400 (Bad Request)
Error: Failed to start download
```

## What Was Fixed

### Improved Error Messaging
Previously, when a download failed, the error message was generic: "Failed to start download"

Now, the application extracts the actual error message from the backend API and displays it to the user. This makes debugging much easier!

**Changes made to:** `app/web/static/js/app.js` (lines 640-795)

## Common Causes of 400 Errors

### 1. **Download Not Found** ⚠️
**Error:** `"Download not found"`

**Cause:** The torrent title isn't in the download mappings file.

**Solutions:**
- Verify the torrent was successfully uploaded to Seedr
- Check the mapping file at `config/download_mapping.json`
- Try refreshing the downloads list
- Re-upload the torrent if necessary

### 2. **No Download Mapping File** ⚠️
**Error:** `"No download mapping found"`

**Cause:** The `download_mapping.json` file doesn't exist.

**Solutions:**
- Ensure at least one torrent has been uploaded
- Check that the `config` directory exists
- The file is created automatically on first upload

### 3. **No Files Available** ⚠️
**Error:** `"No files to download"`

**Cause:** The download exists but has no files associated with it.

**Solutions:**
- Wait for the torrent to finish downloading on Seedr
- Check Seedr directly to verify files exist
- Try deleting and re-uploading the torrent
- Check if the torrent completed successfully

### 4. **Seedr Authentication Issues** ⚠️
**Error:** Various auth-related errors

**Cause:** Token expired or invalid credentials.

**Solutions:**
- Re-authenticate with Seedr
- Check `config/seedr_token.json` exists and is valid
- Log out and log back in through the interface
- Verify Seedr account is active

### 5. **Download Directory Issues** ⚠️
**Error:** File system related errors

**Cause:** Download directory doesn't exist or lacks permissions.

**Solutions:**
- Verify the download directory path in config
- Check directory permissions
- Create the directory manually if needed
- Ensure adequate disk space

### 6. **Torrent Still Downloading** ⏳
**Error:** `"Download not found"` or empty files list

**Cause:** Torrent hasn't completed downloading on Seedr yet.

**Solutions:**
- Wait for the download to complete
- Check progress on Seedr dashboard
- Verify torrent is seeded properly
- Check for Seedr account limits

## Debugging Steps

### Step 1: Check the Browser Console
1. Open Developer Tools (F12)
2. Go to the Console tab
3. Look for the detailed error message
4. **With the fix, you'll now see the actual backend error!**

### Step 2: Check Backend Logs
Look for these debug messages in the console output:
```
[DOWNLOAD] ========================================
[DOWNLOAD] Starting download process for: <title>
[DOWNLOAD] Step 1: Retrieving file list from Seedr...
[DEBUG] Task <id>: progress=<progress>, folder_id=<id>
```

### Step 3: Verify Mappings
Check `config/download_mapping.json`:
```json
{
  "Torrent Title": {
    "torrent_id": "12345",
    "series_id": 1,
    "timestamp": "2024-11-14T10:00:00"
  }
}
```

### Step 4: Check Seedr Status
1. Log into Seedr directly
2. Verify the torrent completed
3. Check files are accessible
4. Note the folder/file IDs

### Step 5: Check Download Directory
Verify the directory exists and is writable:
```bash
# Windows
dir "D:\Downloads"

# Check in config
config/watcher_config.json -> download_dir
```

## API Endpoint Flow

```
User clicks "Download" button
    ↓
Frontend: downloadFiles(title)
    ↓
POST /api/downloads/{title}/download
    ↓
Backend: download_files() in app/main.py
    ↓
Integration: download_completed_files(title, save_path)
    ↓
Step 1: get_downloaded_files(title)
    ├─ Check mapping file exists
    ├─ Look up torrent_id
    ├─ Get task status from Seedr
    ├─ Try folder_created_id
    ├─ Try folder_id
    └─ Try task_contents
    ↓
Step 2: Create download directory
    ↓
Step 3: Download each file/folder
    ├─ Files: seedr.download_file(file_id, path)
    └─ Folders: seedr.download_folder_as_archive(folder_id, path)
    ↓
Return success with list of downloaded files
```

## Testing the Fix

After the fix, you should see more detailed error messages like:

- ✅ "Error starting download: Download not found"
- ✅ "Error starting download: No files to download"
- ✅ "Error starting download: No download mapping found"
- ❌ ~~"Error starting download: Failed to start download"~~ (old generic message)

## Additional Resources

- **Configuration:** `config/watcher_config.json`
- **Mappings:** `config/download_mapping.json`
- **Logs:** Check console output or `logs/` directory
- **API Docs:** Check FastAPI auto-docs at `http://localhost:8000/docs`

## Prevention Tips

1. **Always wait for torrents to complete** before attempting download
2. **Verify Seedr authentication** is active
3. **Check download directory** exists and has space
4. **Monitor the logs** for early warning signs
5. **Keep mappings file** backed up

## Need More Help?

If the error persists:
1. Check all items in debugging steps above
2. Review the backend console output for detailed logs
3. Verify Seedr API is accessible
4. Check network connectivity
5. Ensure all dependencies are installed

---

**Last Updated:** November 14, 2024  
**Related Files:** 
- `app/web/static/js/app.js`
- `app/main.py`
- `app/service/seedr_sonarr_integration.py`




