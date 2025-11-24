# 🚀 Sonarr-Seedr Integration

**Automatically download torrents to Seedr cloud storage and sync with Sonarr for seamless TV show management.**

[![Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![Python](https://img.shields.io/badge/Python-3.13+-green.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-red.svg)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ✨ Features

- 🔄 **Automatic Torrent Watching** - Monitors directories for new torrent files
- ☁️ **Seedr Cloud Integration** - Uploads torrents to Seedr cloud for remote downloading
- 📥 **Auto-Download to Local** - Automatically downloads completed files from Seedr to your computer
- 🔁 **Smart Polling** - Checks every 30 seconds for completed downloads
- 📺 **Sonarr Integration** - Automatically imports downloaded shows to Sonarr
- 🌐 **Web Interface** - Easy-to-use dashboard for management
- 📱 **OAuth2 Authentication** - Secure Seedr account connection
- 🚀 **Portable** - No installation required, just run and go!

## 🎯 Quick Start

### 1. Download & Run

1. Download the latest release from [Releases](https://github.com/yourusername/sonarr-seedr/releases)
2. Extract `SonarrSeedr-SIMPLE.zip` to any folder
3. Run `SonarrSeedr.exe`
4. Open http://localhost:8000 in your browser

### 2. Authenticate with Seedr

1. Click **"Start Authentication"**
2. You'll receive a device code (e.g., `AB12-CD34`)
3. Go to [https://www.seedr.cc/device](https://www.seedr.cc/device)
4. Enter the code and approve the application
5. ✅ **Authentication complete!**

### 3. Configure Sonarr (Optional)

- **Sonarr Host**: `http://localhost:8989` (default)
- **API Key**: Get from Sonarr Settings → General → API Key

## 📖 How It Works

### The Complete Workflow

```mermaid
graph TD
    A[Torrent File Added] --> B[App Detects New File]
    B --> C[Upload to Seedr Cloud]
    C --> D[Seedr Downloads Torrent]
    D --> E[App Polls for Completion]
    E --> F[Download from Seedr to Local]
    F --> G[Sonarr Imports Show]
    G --> H[Organized in Your Library]
```

### Step-by-Step Process

1. **Torrent Detection**: The app watches your configured torrent directory for new `.torrent` or `.magnet` files
2. **Upload to Seedr**: Torrent files are automatically uploaded to your Seedr cloud account
3. **Seedr Processing**: Seedr downloads the actual torrent content to their cloud servers (this is done by Seedr, not your computer)
4. **Auto-Polling**: The app automatically checks every 30 seconds if Seedr has finished downloading
5. **Local Download**: Once complete, the app downloads the files FROM Seedr TO your local download directory
6. **Sonarr Integration**: Downloaded shows are automatically imported to Sonarr from your local directory
7. **Library Organization**: Your TV shows are organized and ready to watch!

### Two-Stage Download Process

**Important**: This app uses a **two-stage download process**:

- **Stage 1 (Cloud)**: Seedr downloads the torrent on their servers (fast, no P2P on your network)
- **Stage 2 (Local)**: The app downloads from Seedr to your computer (direct HTTPS download)

This means files are **not just stored in the cloud** - they are automatically downloaded to your local machine for Sonarr to use!

## 🛠️ Configuration

### Torrent Directory Setup

- Place your `.torrent` files in the watched directory
- The app will automatically detect and process them
- Default directory: `C:\Users\[Username]\Downloads\Torrents`

### Sonarr Integration

1. **Enable API**: Go to Sonarr Settings → General → API Key
2. **Copy API Key**: Copy the generated API key
3. **Configure in App**: Enter Sonarr host and API key in the web interface

### Seedr Account

- **Free Account**: 2GB storage, limited download speed
- **Premium Account**: Up to 1TB storage, faster downloads
- **No Configuration**: Client ID is pre-configured!

## 🌐 Web Interface

Access the web interface at **http://localhost:8000** for:

- 📊 **Dashboard** - Overview of your setup and status
- ⚙️ **Configuration** - Manage Sonarr and download settings
- 📁 **Torrent Management** - View and manage torrent downloads
- 🔧 **Settings** - Configure directories and preferences

### API Documentation

- **Interactive API**: http://localhost:8000/docs
- **Status Endpoint**: http://localhost:8000/api/status

## 🔧 Troubleshooting

### Common Issues

| Problem                     | Solution                                |
| --------------------------- | --------------------------------------- |
| **App won't start**         | Run `debug.bat` to see error messages   |
| **Port 8000 busy**          | Run `SonarrSeedr.exe --port 8001`       |
| **Authentication fails**    | Check internet connection and try again |
| **Sonarr not connecting**   | Verify API key and host URL             |
| **Torrents not processing** | Check torrent directory permissions     |

### Debug Mode

Run `debug.bat` to see detailed error messages and troubleshoot issues.

## 📋 Requirements

### System Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 512MB minimum
- **Storage**: 100MB for application
- **Network**: Internet connection for Seedr

### External Services

- **Seedr Account**: [Sign up here](https://www.seedr.cc)
- **Sonarr** (Optional): [Download here](https://sonarr.tv)

## 🚀 Advanced Usage

### Command Line Options

```bash
# Run on different port
SonarrSeedr.exe --port 8001

# Enable debug logging
SonarrSeedr.exe --log-level debug

# Disable browser auto-open
SonarrSeedr.exe --no-browser
```

### Directory Structure

```
SonarrSeedr/
├── SonarrSeedr.exe          # Main application
├── debug.bat                # Debug script
├── SIMPLE_USAGE.md          # Quick start guide
├── PORTABLE_USAGE.md        # Detailed documentation
└── _internal/               # Application files
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Run the application: `python run.py`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Seedr](https://www.seedr.cc) for cloud torrent service
- [Sonarr](https://sonarr.tv) for TV show management
- [FastAPI](https://fastapi.tiangolo.com) for the web framework
- [PyInstaller](https://pyinstaller.org) for executable packaging

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/sonarr-seedr/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sonarr-seedr/discussions)
- **Documentation**: Check the `PORTABLE_USAGE.md` file

---

**⭐ Star this repository if you find it helpful!**

_Made with ❤️ for the Plex/Sonarr community_
