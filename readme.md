# Seedr Plugins Repository

This repository contains plugins and integrations for **Seedr.cc** cloud storage service across various platforms and applications.

## What is Seedr?

Seedr.cc is a cloud-based client and storage service that allows you to download files to the cloud and stream or download them from anywhere. These plugins extend Seedr's functionality by integrating it with popular media centers and automation tools.

### How It Works

1. **Upload or Add files**: Add  files or magnet links to your Seedr account through the web interface
2. **Cloud Download**: Seedr downloads the files to their cloud servers (no need to keep your computer on)
3. **Stream or Download**: Access your files from anywhere - stream directly or download to your device
4. **Plugin Integration**: Use these plugins to access your Seedr content directly from Kodi, Roku, or other supported platforms

### Why Use These Plugins?

- **Convenience**: Access your Seedr library without opening a web browser
- **Better Experience**: Native integration with your favorite media center for a seamless viewing experience
- **Remote Access**: Stream your content on any device where the plugin is installed
- **No Local Storage**: Save space on your devices - files stay in the cloud

## Available Plugins

### 🎬 Kodi Plugin

**Status:** ✅ Available

A fully functional Kodi addon that allows you to access and stream your Seedr.cc cloud storage content directly through Kodi media center.

**Features:**

- Stream video files from your Seedr account
- Listen to audio files
- View image files
- Support for SRT subtitles
- Automatic subtitle matching for videos
- Device code authentication

**[View Kodi Plugin Documentation →](Kodi-plugin/)**

### 📺 Roku Plugin

**Status:** ✅ Available

A fully functional Roku channel that allows you to access and stream your Seedr.cc cloud storage content directly on your Roku device.

**Features:**

- Stream video files from your Seedr account
- Device code authentication
- Easy installation via developer mode

**[View Roku Plugin Documentation →](roku/)**

### 📡 Sonarr Plugin

**Status:** 🚧 Coming Soon

Sonarr integration plugin for automated TV show management with Seedr.

## Requirements

- A Seedr.cc account ([Sign up here](https://www.seedr.cc))
- Internet connection
- The respective platform (Kodi, Roku, or Sonarr) installed on your device

## Quick Start

### For First-Time Users

**Step 1: Get a Seedr Account**

- If you don't have one yet, [sign up for a free Seedr account](https://www.seedr.cc)
- Free accounts include 2GB of storage (upgrade available for more space)
- You can start using the service immediately after signup

**Step 2: Add Content to Seedr**

- Log into your Seedr account at https://www.seedr.cc
- Add media files or links through the web interface
- Wait for downloads to complete (you'll see progress in your Seedr dashboard)

**Step 3: Install the Plugin**

- Choose the plugin for your platform (Kodi or Roku) from the list above
- Navigate to the plugin's directory for detailed installation instructions
- Follow the step-by-step installation guide

**Step 4: Authenticate**

- Launch the plugin on your device
- You'll be shown a device code or authentication link
- Visit the provided URL and autheticate to link your Seedr account
- Your Seedr library will now be accessible through the plugin!

**Step 5: Start Streaming**

- Browse your Seedr files directly from the plugin interface
- Select any video, audio, or image file to stream instantly
- No need to download files to your device - everything streams from the cloud

### Need Help?

- Check the detailed documentation in each plugin's folder
- Make sure your device is connected to the internet
- Ensure your Seedr account has active content to display

## Repository Structure

```
Seedr-plugins/
├── kodi/                 # Kodi media center plugin
├── roku/                 # Roku streaming device plugin
└── Sonarr/               # Sonarr automation plugin
```

## Support

For issues, questions, or feature requests:

- Open an issue in this repository
- Check the documentation in each plugin's folder

---

**Note:** This is official third-party plugin repository.
