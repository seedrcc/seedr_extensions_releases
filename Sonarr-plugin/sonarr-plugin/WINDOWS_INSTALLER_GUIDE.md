# Windows Installer Guide

This guide explains how to make your Sonarr-Seedr application appear in the Windows app list (Settings > Apps & features).

## Why You Need an Installer

Currently, your application is distributed as a ZIP file. Users extract and run the `.exe` directly. This approach:
- ❌ Doesn't appear in Windows Settings > Apps & features
- ❌ Doesn't appear in Programs and Features
- ❌ Has no proper uninstaller
- ❌ Doesn't create Start Menu shortcuts automatically
- ❌ Doesn't follow Windows installation conventions

An installer solves all these issues!

## Quick Start - Using Inno Setup (Recommended)

### Step 1: Install Inno Setup

1. Download Inno Setup 6 from: https://jrsoftware.org/isdl.php
2. Install it (default location is fine)
3. Restart your terminal/command prompt

### Step 2: Customize the Installer

Open `installer.iss` and update these values:

```ini
#define MyAppPublisher "Your Name/Organization"
#define MyAppURL "https://github.com/yourusername/sonarr-seedr"
#define MyAppId "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
```

**IMPORTANT:** Generate a unique AppId (GUID) here: https://www.guidgenerator.com/
Replace the example GUID with your new one.

### Step 3: Build the Installer

Simply run:

```batch
build-installer.bat
```

This will:
1. Check if Inno Setup is installed
2. Build your executable (if needed)
3. Create the installer in `releases\installers\`

### Step 4: Test the Installer

1. Navigate to `releases\installers\`
2. Run `SonarrSeedr-Setup-v1.1.0.exe` as Administrator
3. Complete the installation wizard
4. Open Windows Settings > Apps & features
5. Search for "Sonarr-Seedr Integration"
6. You should see your app listed! ✓

## What the Installer Does

When users run your installer, it will:

✅ **Install to Program Files** - Properly installs to `C:\Program Files\Sonarr-Seedr Integration\`
✅ **Create Start Menu Entry** - Adds app to Windows Start Menu
✅ **Create Desktop Shortcut** - Optional desktop icon
✅ **Register in Windows** - Appears in Apps & features list
✅ **Create Uninstaller** - Proper removal through Windows Settings
✅ **Add Startup Option** - Optional auto-start with Windows

## Advanced Customization

### Changing Install Location

Edit `installer.iss`:

```ini
DefaultDirName={autopf}\{#MyAppName}        ; Program Files
; OR
DefaultDirName={localappdata}\{#MyAppName}  ; User's AppData\Local
; OR
DefaultDirName=C:\MyCustomLocation          ; Custom path
```

### Adding More Files

To include additional files during installation:

```ini
[Files]
Source: "docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs
Source: "config.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist
```

### Adding Registry Entries

To add Windows registry entries:

```ini
[Registry]
Root: HKCU; Subkey: "Software\{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
```

### Custom Installation Pages

You can add custom pages for configuration during installation. See Inno Setup documentation for details.

## Alternative Installer Options

### Option 2: NSIS (Nullsoft Scriptable Install System)

**Pros:**
- Very powerful and flexible
- Small installer size
- Good for complex setups

**Cons:**
- Steeper learning curve
- More complex scripting

Download: https://nsis.sourceforge.io/

### Option 3: Advanced Installer (Free Edition)

**Pros:**
- GUI-based (no scripting)
- Very professional
- Good for beginners

**Cons:**
- Free edition has limitations
- Larger installer size

Download: https://www.advancedinstaller.com/

### Option 4: WiX Toolset (MSI)

**Pros:**
- Creates MSI files (enterprise standard)
- Full control over installation
- Good for corporate environments

**Cons:**
- Complex XML-based
- Steep learning curve
- Requires Visual Studio Build Tools

Download: https://wixtoolset.org/

## Distribution Recommendations

### For End Users (Recommended)
Use the **installer** (`.exe` file) for distribution:
- `SonarrSeedr-Setup-v1.1.0.exe`

Benefits:
- Professional installation experience
- Appears in Windows app list
- Easy uninstallation
- Automatic shortcuts

### For Power Users (Optional)
Keep the **portable ZIP** for users who prefer it:
- `SonarrSeedr-v1.1.0-[timestamp].zip`

Benefits:
- No installation required
- Can run from USB drive
- Multiple instances possible

## Troubleshooting

### "Inno Setup not found"
- Make sure you installed Inno Setup 6
- Check that it's installed in default location
- Restart your terminal after installation

### "Access Denied" errors
- Run the installer build as Administrator
- Check that `dist\SonarrSeedr\` folder exists
- Ensure you have write permissions to `releases\installers\`

### App doesn't appear in Windows list
- Make sure you ran the installer (not just copied files)
- Check that you have a unique AppId (GUID) in installer.iss
- Try uninstalling and reinstalling

### Version number not updating
- The script auto-updates version from `app\version.py`
- If it's not working, manually update the version in `installer.iss`

## Signing Your Installer (Optional but Recommended)

For professional distribution, you should sign your installer with a code signing certificate:

1. Get a code signing certificate (from DigiCert, Sectigo, etc.)
2. Use `signtool.exe` to sign the installer
3. This removes Windows SmartScreen warnings

Example:
```batch
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com SonarrSeedr-Setup.exe
```

## Automatic Updates

Consider integrating an auto-update system:
- Sparkle (for Windows port)
- Squirrel.Windows
- Custom update checker in your app

Your app already checks for updates - extend this to download and run the new installer automatically!

## Best Practices

1. **Always increment version numbers** - Users can track updates
2. **Test installers on clean VMs** - Ensure they work on fresh systems
3. **Provide both installer and portable** - Different users prefer different methods
4. **Sign your executables** - Builds trust with users
5. **Include release notes** - Show what's new in each version
6. **Support silent installation** - For enterprise deployments

Silent install example:
```batch
SonarrSeedr-Setup.exe /SILENT /DIR="C:\MyPath"
```

## Next Steps

1. ✅ Install Inno Setup
2. ✅ Update `installer.iss` with your details
3. ✅ Generate a unique AppId (GUID)
4. ✅ Run `build-installer.bat`
5. ✅ Test the installer
6. ✅ Distribute the installer to users

## Resources

- Inno Setup Documentation: https://jrsoftware.org/ishelp/
- Inno Setup Examples: https://jrsoftware.org/isinfo.php
- Code Signing Guide: https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools

## Support

If you encounter issues:
1. Check the Inno Setup compiler output for errors
2. Test on a fresh Windows installation (VM)
3. Review the Inno Setup documentation
4. Check Windows Event Viewer for installation errors

---

**Pro Tip:** Keep both the ZIP (portable) and installer (setup) versions. Offer both on your releases page so users can choose their preferred installation method!

