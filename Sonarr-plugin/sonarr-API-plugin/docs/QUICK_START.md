# ⚡ Quick Start - Get Running in 5 Minutes!

## 🎯 Super Quick Setup (TL;DR)

### What You Need First
1. **Sonarr** running on http://localhost:8989
2. **Prowlarr** running on http://localhost:9696  
3. **Seedr account** at https://seedr.cc (free account works!)

> Don't have them? Get them here:
> - Sonarr: https://sonarr.tv/#download
> - Prowlarr: https://prowlarr.com/#downloads

---

## 🚀 5-Step Setup

### Step 1: Run the App (30 seconds)
```
1. Double-click SonarrSeedr.exe
2. Browser opens to http://localhost:8000
```

### Step 2: Authenticate with Seedr (1 minute)
```
1. Click "Start Authentication"
2. Scan the QR Code with your phone 📱
   OR
   Copy the device code and visit https://www.seedr.cc/device
3. Authorize the app
4. Done! ✅
```

### Step 3: Connect Sonarr (1 minute)
```
1. Get API Key:
   - Open Sonarr → Settings → General
   - Copy the API Key

2. In SonarrSeedr:
   - Go to Config tab
   - Enter: http://localhost:8989
   - Paste your API Key
   - Click Save
```

### Step 4: Link Prowlarr to Sonarr (2 minutes)
```
1. Open Prowlarr → Settings → Apps → Add (+)
2. Select "Sonarr"
3. Fill in:
   - Sonarr Server: http://localhost:8989
   - API Key: (from Step 3)
4. Click Test → Save

5. Add Indexers:
   - Prowlarr → Indexers → Add Indexer
   - Add 2-3 indexers (e.g., EZTV, 1337x)
   - They auto-sync to Sonarr!
```

### Step 5: Setup Folders (30 seconds)
```
1. In SonarrSeedr → Folder Watcher tab:
   - Torrent Directory: Where .torrent files go
     (e.g., D:\Torrents\Watch)
   - Download Directory: Where completed files go
     (e.g., D:\Torrents\Completed)
2. Enable "Auto-start"
3. Click "Save & Start Watcher"
```

**One More Thing:** Configure Sonarr's Download Client
```
1. Sonarr → Settings → Download Clients → Add
2. Select "Torrent Blackhole"
3. Set Torrent Folder to your "Torrent Directory" from Step 5
4. Test → Save
```

---

## 🎬 Test It!

```
1. Open Sonarr
2. Add a TV show
3. Go to Wanted → Missing
4. Click Search on any episode
5. Watch magic happen! ✨
```

**Check Progress:**
- SonarrSeedr Dashboard: http://localhost:8000
- Torrents Tab: See active downloads
- Folder Watcher Tab: Monitor activity

---

## 🔄 How It Works

```
Sonarr searches → Prowlarr finds torrent → 
Drops .torrent file → SonarrSeedr uploads to Seedr → 
Seedr downloads fast → SonarrSeedr downloads files → 
Notifies Sonarr → Sonarr organizes → Done! 🎉
```

---

## ❓ Stuck?

**App won't start?**
```bash
# Run this to see errors:
debug.bat
```

**Authentication failed?**
```
- Wait 2 minutes and try again
- Delete config/seedr_token.json
- Restart app and re-authenticate
```

**No torrents found?**
```
- Add more indexers in Prowlarr
- Check Prowlarr → Apps → Sync to Sonarr
```

**Files not downloading?**
```
- Check folders exist and are accessible
- Verify "Torrent Blackhole" is configured in Sonarr
- Check folder_watcher.log for errors
```

---

## 📚 Need Detailed Guide?

See **SIMPLE_USAGE.md** for:
- Complete step-by-step instructions
- Troubleshooting guide
- Advanced configuration
- All features explained

---

## ✅ Quick Checklist

- [ ] Sonarr running
- [ ] Prowlarr running  
- [ ] SonarrSeedr.exe running
- [ ] Authenticated with Seedr
- [ ] Sonarr API configured
- [ ] Prowlarr linked to Sonarr
- [ ] 2+ indexers in Prowlarr
- [ ] Folders configured
- [ ] Watcher running
- [ ] Download client configured in Sonarr

**All done?** Start adding shows and enjoy! 🍿

---

**Need help?** Check `SIMPLE_USAGE.md` for detailed instructions!

