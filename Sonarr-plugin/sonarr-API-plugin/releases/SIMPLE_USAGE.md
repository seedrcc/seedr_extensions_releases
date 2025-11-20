# 🚀 Sonarr-Seedr Integration - Complete Setup Guide

## 📋 Prerequisites - What You Need

Before starting, make sure you have these applications installed and running:

1. **Sonarr** - TV show management (http://localhost:8989)
2. **Prowlarr** - Torrent indexer manager (http://localhost:9696)
3. **Seedr Account** - Cloud torrent service (https://seedr.cc)

> **Don't have them yet?** Download from:
>
> - Sonarr: https://sonarr.tv/#download
> - Prowlarr: https://prowlarr.com/#downloads

---

## 🎯 Quick Start Guide

### Step 1: Run the Application

1. **Double-click** `SonarrSeedr.exe`
2. Wait for the console window to show: `Uvicorn running on http://0.0.0.0:8000`
3. Your browser should automatically open to http://localhost:8000

> **Tip:** If the browser doesn't open automatically, manually navigate to http://localhost:8000

---

### Step 2: Authenticate with Seedr (2 Options)

#### Option A: Quick Authentication with QR Code (Easiest!)

1. Click **"Start Authentication"** on the main page
2. A **QR Code** will appear on screen
3. **Scan the QR code** with your phone camera
4. You'll be taken to https://www.seedr.cc/device
5. **Enter the device code** shown on screen (e.g., `AB12-CD34`)
6. Click **"Authorize"** on Seedr
7. **Done!** The app will automatically detect and connect

#### Option B: Manual Authentication

1. Click **"Start Authentication"** on the main page
2. Copy the **device code** (e.g., `AB12-CD34`)
3. Open **https://www.seedr.cc/device** in a new browser tab
4. **Paste the code** and click authorize
5. Return to the app - it will connect automatically

> **Note:** Authentication expires after 15 minutes. If you don't complete it in time, just click "Start Authentication" again.

---

## ⚙️ Step 3: Configure Sonarr Integration

### Get Sonarr API Key

1. Open **Sonarr** (http://localhost:8989)
2. Go to **Settings** → **General**
3. Scroll down to **Security** section
4. Copy the **API Key** (long string of letters and numbers)

### Configure in SonarrSeedr

1. Go to **Config** tab in SonarrSeedr
2. Enter your **Sonarr Host**: `http://localhost:8989`
3. Paste your **Sonarr API Key**
4. Click **"Save Configuration"**

---

## 🔗 Step 4: Link Prowlarr with Sonarr

### Why Prowlarr?

Prowlarr finds torrents from multiple sources and automatically sends them to Sonarr. **This is required for the automation to work!**

### Setup Instructions

#### A. Add Sonarr to Prowlarr

1. Open **Prowlarr** (http://localhost:9696)
2. Go to **Settings** → **Apps** → Click **+** button
3. Select **"Sonarr"**
4. Fill in the details:
   - **Name**: `Sonarr` (or any name you prefer)
   - **Sync Level**: `Full Sync`
   - **Prowlarr Server**: `http://localhost:9696`
   - **Sonarr Server**: `http://localhost:8989`
   - **API Key**: (Paste your Sonarr API Key from Step 3)
5. Click **"Test"** to verify connection
6. Click **"Save"** if test is successful

#### B. Add Indexers to Prowlarr

1. In Prowlarr, go to **Indexers** → Click **"Add Indexer"**
2. Search for your preferred indexers (e.g., EZTV, TorrentGalaxy, 1337x)
3. Add at least **2-3 indexers** for best results
4. Each indexer will automatically sync to Sonarr

> **Important:** Without indexers, Prowlarr won't find any torrents!

#### C. Configure Download Client in Sonarr

1. Open **Sonarr** → **Settings** → **Download Clients**
2. Click **"Add"** → Select **"Torrent Blackhole"**
3. Configure:
   - **Name**: `SonarrSeedr`
   - **Torrent Folder**: Select the **"Torrent Directory"** you configured in SonarrSeedr (Step 6)
   - **Watch Folder**: Same as above
4. Click **"Test"** and **"Save"**

---

## 📁 Step 5: Configure Folder Watcher

### Setup Watch Folders

1. Go to **"Folder Watcher"** tab in SonarrSeedr
2. Click **"Select Folder"** for **Torrent Directory**
   - Choose where Sonarr will drop `.torrent` files
   - Example: `D:\Torrents\Watch`
3. Click **"Select Folder"** for **Download Directory**
   - Choose where completed downloads will be saved
   - Example: `D:\Torrents\Completed`
4. Enable **"Auto-start on Launch"** (recommended)
5. Click **"Save Settings & Start Watcher"**

### What the Watcher Does

- **Monitors** the Torrent Directory for new `.torrent` and `.magnet` files
- **Automatically uploads** them to Seedr
- **Downloads** completed files from Seedr to Download Directory
- **Notifies** Sonarr when downloads are ready

---

## 🎬 Step 6: How It All Works Together

### The Complete Workflow

```
1. You add a TV show in Sonarr
         ↓
2. Sonarr searches Prowlarr for episodes
         ↓
3. Prowlarr finds torrents from indexers
         ↓
4. Sonarr downloads .torrent file to Watch Folder
         ↓
5. SonarrSeedr detects new torrent file
         ↓
6. SonarrSeedr uploads to Seedr cloud
         ↓
7. Seedr downloads the torrent (fast!)
         ↓
8. SonarrSeedr downloads completed files
         ↓
9. SonarrSeedr notifies Sonarr
         ↓
10. Sonarr moves and renames the files
         ↓
11. Done! Episode is ready to watch!
```

### Testing the Setup

1. Open **Sonarr** and add a TV show
2. Go to **Wanted** → **Missing**
3. Find an episode and click **Search** icon
4. Check **SonarrSeedr Dashboard** - you should see activity
5. Monitor the **Torrents** tab for download progress

---

## 🌟 Features & Benefits

- ✅ **Automatic Torrent Processing** - Drop and forget!
- ✅ **Cloud-Based Downloading** - Uses Seedr's fast servers
- ✅ **Sonarr Integration** - Seamless TV show organization
- ✅ **Prowlarr Support** - Search multiple indexers at once
- ✅ **Web Interface** - Easy monitoring and management
- ✅ **Portable** - No installation or database required
- ✅ **Auto-Start** - Resumes watching on application launch
- ✅ **Real-Time Monitoring** - Live status updates

---

## 🔧 Troubleshooting

### Application Issues

| Problem                     | Solution                                         |
| --------------------------- | ------------------------------------------------ |
| **App won't start**         | Run `debug.bat` to see detailed error messages   |
| **Port 8000 busy**          | Run: `SonarrSeedr.exe --port 8001`               |
| **White screen in browser** | Clear browser cache or try incognito mode        |
| **Watcher not starting**    | Check that both folders exist and are accessible |

### Authentication Issues

| Problem                     | Solution                                                    |
| --------------------------- | ----------------------------------------------------------- |
| **Device code expired**     | Click "Start Authentication" again (codes expire in 15 min) |
| **QR code not scanning**    | Use manual authentication method instead                    |
| **Seedr keeps logging out** | Delete `config/seedr_token.json` and re-authenticate        |

### Prowlarr Connection Issues

| Problem                  | Solution                                          |
| ------------------------ | ------------------------------------------------- |
| **Prowlarr test fails**  | Verify Sonarr is running on http://localhost:8989 |
| **No torrents found**    | Add more indexers in Prowlarr                     |
| **Indexers not syncing** | In Prowlarr, go to Apps → Click sync button       |

### Sonarr Integration Issues

| Problem                    | Solution                                             |
| -------------------------- | ---------------------------------------------------- |
| **Sonarr API error**       | Verify API key is correct (check Settings → General) |
| **Downloads not starting** | Check Torrent Blackhole is configured correctly      |
| **Files not importing**    | Check Download Directory path is correct in Sonarr   |

---

## 📱 Web Interface Overview

### Main Dashboard

**URL:** http://localhost:8000

- View system status
- See recent activity
- Quick authentication

### Configuration Page

**URL:** http://localhost:8000/config

- Configure Sonarr connection
- Set up folder paths
- Adjust polling intervals

### Torrents Monitor

**URL:** http://localhost:8000/torrents

- View active downloads
- Check progress
- Manage torrents

### Folder Watcher

**URL:** http://localhost:8000/folder-watcher

- Configure watch folders
- Start/stop watcher
- View recent scans

### API Documentation

**URL:** http://localhost:8000/docs

- Interactive API testing
- Full endpoint documentation

---

## 💡 Pro Tips

1. **Keep Everything Running** - Sonarr, Prowlarr, and SonarrSeedr should all run together
2. **Use Quality Indexers** - Better indexers = better results in Prowlarr
3. **Monitor Logs** - Check `folder_watcher.log` for detailed activity
4. **Enable Auto-Start** - Let the watcher start automatically when you launch the app
5. **Test with One Episode** - Before adding many shows, test with one episode first

---

## 🆘 Need More Help?

- **Detailed Guide**: See `PORTABLE_USAGE.md` for advanced configuration
- **Logs**: Check `folder_watcher.log` for debugging
- **API Docs**: Visit http://localhost:8000/docs for API details

---

## ✅ Quick Setup Checklist

- [ ] Sonarr installed and running (http://localhost:8989)
- [ ] Prowlarr installed and running (http://localhost:9696)
- [ ] Seedr account created (https://seedr.cc)
- [ ] SonarrSeedr.exe running
- [ ] Authenticated with Seedr (via QR code or manual)
- [ ] Sonarr API key configured in SonarrSeedr
- [ ] Sonarr added to Prowlarr as an App
- [ ] At least 2-3 indexers added to Prowlarr
- [ ] Torrent Blackhole configured in Sonarr
- [ ] Watch folders configured in SonarrSeedr
- [ ] Folder watcher started and running
- [ ] Tested with one episode search

**All checked?** You're ready to automate your TV show downloads! 🎉

---

_Enjoy seamless TV show automation with Sonarr + Prowlarr + Seedr!_ 🚀
