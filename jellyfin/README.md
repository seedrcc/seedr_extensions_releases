# Seedr for Jellyfin - Installation Guide

Stream your Seedr cloud storage directly in your Jellyfin media server.

## 📦 What You Need

- Jellyfin Server (version 10.8.0 or higher)
- A Seedr.cc account (free or premium)
- Admin access to your Jellyfin server

---

## 🚀 Installation (Choose One Method)

### Method 1: Via Repository (Recommended - Auto Updates!)

**Quick Setup in 3 Steps:**

1. **Add Repository:**
   - Open Jellyfin Dashboard
   - Go to: **Plugins** → **Repositories**
   - Click **"+"** to add repository
   - Enter URL:
     ```
     https://raw.githubusercontent.com/seedrcc/seedr_extensions_releases/main/jellyfin/manifest.json
     ```

2. **Install Plugin:**
   - Go to: **Plugins** → **Catalog**
   - Find **"Seedr"** and click **Install**

3. **Restart Jellyfin** and you're done!

---

### Method 2: Manual Installation

1. **Download the latest ZIP file** from this release

2. **Find your Jellyfin data folder:**
   - Windows: `C:\ProgramData\Jellyfin\Server\`
   - Linux: `/var/lib/jellyfin/`
   - Docker: Your mapped config volume

3. **Extract files:**
   - Create folder: `[data-folder]/plugins/Seedr/`
   - Extract ZIP contents into that folder

4. **Restart Jellyfin**

---

## 🔑 First Time Setup

After installation and restart:

1. **Go to Plugin Settings:**
   - Dashboard → Plugins → Seedr → Settings

2. **Authorize with Seedr:**
   - You'll see a verification URL and code
   - On your phone/computer, visit: `https://www.seedr.cc/devices`
   - Login to Seedr and enter the code shown
   - Click **"Authorize"**

3. **Complete in Jellyfin:**
   - Click **"Check Authorization"**
   - Save settings when connected ✓

4. **Add to Library:**
   - Dashboard → Libraries → Add Media Library
   - Select Seedr folders
   - Start streaming!

---

## 🎯 Features

✨ **Stream Videos** - Watch your Seedr files directly in Jellyfin  
✨ **Play Music** - Listen to your audio collection  
✨ **No Downloads** - Stream directly from the cloud  
✨ **Auto Updates** - Stay up-to-date (if installed via repository)  
✨ **All Devices** - Works on web, mobile, TV apps

---

## ❓ Need Help?

**Plugin not showing in Catalog?**  
Wait 1-2 minutes and refresh. Make sure the repository URL is correct.

**Authentication failing?**  
Double-check the device code. Codes expire after 15 minutes - request a new one if needed.

**Files not appearing?**  
Scan your libraries: Dashboard → Libraries → Scan All Libraries

**Need Seedr account?**  
Sign up free at https://www.seedr.cc/

**More help?**  
Visit: https://www.seedr.cc/support

---

## 📋 System Requirements

- **Jellyfin:** 10.8.0 or higher
- **OS:** Windows, Linux, macOS, Docker (any supported by Jellyfin)
- **Internet:** Stable connection for streaming

---

## 🔗 Links

- Repository URL: `https://raw.githubusercontent.com/seedrcc/seedr_extensions_releases/main/jellyfin/manifest.json`
- Seedr Website: https://www.seedr.cc
- Jellyfin Docs: https://jellyfin.org/docs

---

**Latest Version** | Support: https://www.seedr.cc/support

