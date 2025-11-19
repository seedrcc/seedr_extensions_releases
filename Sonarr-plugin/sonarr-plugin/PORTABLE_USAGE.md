# Sonarr-Seedr Portable Application - Quick Usage Guide

## 📦 What You Need

- **SonarrSeedr-Portable-Final.zip** (the portable package)
- Windows 10/11 (64-bit)
- Internet connection

## 🚀 Quick Start (3 Steps)

### Step 1: Extract

```
1. Download SonarrSeedr-Portable-Final.zip
2. Extract to any folder (e.g., C:\SonarrSeedr)
3. Navigate to the extracted folder
```

### Step 2: Test (Optional but Recommended)

```cmd
# Run the test script to verify everything works
test-deployment.bat
```

### Step 3: Run

```cmd
# Start the application
SonarrSeedr.exe
```

**That's it!** The application will:

- Start automatically
- Open your browser to http://localhost:8000
- Be ready to configure

## 📋 File Structure After Extraction

```
SonarrSeedr/
├── SonarrSeedr.exe          # ← Main application
├── debug.bat                # ← Debug script (shows errors)
├── test-deployment.bat      # ← Test script
├── test-deployment.ps1      # ← PowerShell test script
├── README.txt               # ← Quick reference
└── _internal/               # ← Dependencies (don't touch)
```

## ⚙️ Command Line Options

```cmd
# Use different port if 8000 is busy
SonarrSeedr.exe --port 9000

# Don't open browser automatically
SonarrSeedr.exe --no-browser

# Enable debug logging
SonarrSeedr.exe --log-level debug

# Bind to all network interfaces (for remote access)
SonarrSeedr.exe --host 0.0.0.0
```

## 🛠️ Troubleshooting

| Problem                      | Solution                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------ |
| **CMD opens/closes quickly** | **FIXED!** App now starts properly. Use `debug.bat` if needed                        |
| **Won't start**              | Run `test-deployment.bat` to diagnose                                                |
| **Port 8000 busy**           | Use `--port 9000`                                                                    |
| **Antivirus blocks**         | Add folder to exclusions                                                             |
| **Missing DLLs**             | Install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) |
| **Firewall blocks**          | Allow through Windows Firewall                                                       |

### 🚨 CMD Window Opens and Closes Immediately?

This means the executable is crashing. To see the error:

1. **Method 1 - Command Prompt:**

   ```cmd
   # Open Command Prompt manually
   cmd
   # Navigate to your folder
   cd C:\path\to\SonarrSeedr
   # Run with no-browser to see errors
   SonarrSeedr.exe --no-browser
   ```

2. **Method 2 - PowerShell:**

   ```powershell
   # Hold Shift + Right-click in folder, select "Open PowerShell here"
   .\SonarrSeedr.exe --no-browser
   ```

3. **Method 3 - Use Included Debug Script:**

   ```cmd
   # Run the included debug script
   debug.bat
   ```

   This will run the application and keep the window open to show any errors.

## 🌐 Access URLs

- **Local access**: http://localhost:8000
- **Network access**: http://[YOUR-IP]:8000 (if using `--host 0.0.0.0`)
- **API docs**: http://localhost:8000/docs

## 📱 Remote Access (Advanced)

To access from other devices on your network:

```cmd
SonarrSeedr.exe --host 0.0.0.0 --port 8000
```

Then use: `http://[COMPUTER-IP]:8000`

## 🔧 First Time Setup

### Option 1: Configuration via .env file (Recommended)

1. **Rename** `env.example` to `.env`
2. **Edit** `.env` file with your settings:
   ```
   SEEDR_CLIENT_ID=your_seedr_client_id_here
   SONARR_HOST=http://localhost:8989
   SONARR_API_KEY=your_sonarr_api_key_here
   ```
3. **Get Seedr Client ID** from: https://www.seedr.cc/api
4. **Restart** the application
5. **Start using** - authentication will work automatically

### Option 2: Configuration via Web Interface

1. Start the application
2. Go to http://localhost:8000
3. Configure your Seedr account (you'll need Client ID)
4. Configure your Sonarr connection
5. Set up folder watching (optional)

## ⚡ Performance Notes

- **Startup time**: 3-5 seconds
- **Memory usage**: ~50-100 MB
- **Package size**: ~80-150 MB
- **No Python installation required**

## 📞 Support

If you encounter issues:

1. Run `test-deployment.bat` first
2. Check `folder_watcher.log` for errors
3. Try running with `--log-level debug`
4. Ensure Windows is up to date

---

**✅ Ready to use!** The portable application is completely self-contained and runs without any additional installation.
