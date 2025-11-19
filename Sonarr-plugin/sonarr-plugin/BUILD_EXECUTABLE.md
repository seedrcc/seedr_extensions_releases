# Building Windows Executable for Sonarr-Seedr FastAPI Plugin

This guide explains how to convert your FastAPI application into a standalone Windows executable (.exe file).

## Prerequisites

1. **Python 3.13** (or compatible version)
2. **All dependencies installed** from `requirements.txt`
3. **PyInstaller** (included in requirements.txt)

## Quick Start

### Method 1: Using Build Scripts (Recommended)

**Option A: PowerShell (Recommended)**

```powershell
.\build.ps1
```

**Option B: Batch File**

```cmd
build.bat
```

### Method 2: Manual Build

```cmd
pyinstaller sonarr_seedr.spec --clean --noconfirm
```

## Build Output

After a successful build, you'll find:

- **Executable**: `dist\SonarrSeedr\SonarrSeedr.exe`
- **All dependencies**: Bundled in `dist\SonarrSeedr\_internal\`
- **Static files**: Web UI templates and assets included

## Running the Executable

### Basic Usage

```cmd
dist\SonarrSeedr\SonarrSeedr.exe
```

### With Options

```cmd
# Run on different port
dist\SonarrSeedr\SonarrSeedr.exe --port 9000

# Run on specific host
dist\SonarrSeedr\SonarrSeedr.exe --host 127.0.0.1

# Disable auto-browser opening
dist\SonarrSeedr\SonarrSeedr.exe --no-browser

# Set log level
dist\SonarrSeedr\SonarrSeedr.exe --log-level debug
```

## Distribution

The entire `dist\SonarrSeedr\` folder can be:

1. **Zipped** and shared with others
2. **Copied** to any Windows machine
3. **Run directly** without Python installation

### What's Included in Distribution

- ✅ Python runtime (embedded)
- ✅ All Python dependencies
- ✅ Web UI (HTML, CSS, JS)
- ✅ Configuration templates
- ✅ Required system DLLs

### What's NOT Included

- ❌ User-specific configurations (tokens, API keys)
- ❌ Torrent/download directories (created on first run)
- ❌ Log files (created during runtime)

## File Structure After Build

```
dist\SonarrSeedr\
├── SonarrSeedr.exe          # Main executable
├── _internal\               # Dependencies and runtime
│   ├── app\                 # Web UI templates and static files
│   ├── config\              # Configuration templates
│   ├── *.dll                # System libraries
│   ├── *.pyd                # Python extensions
│   └── base_library.zip     # Python standard library
```

## Troubleshooting

### Build Issues

**1. Missing Modules Error**

```
ModuleNotFoundError: No module named 'xyz'
```

**Solution**: Add the module to `hiddenimports` in `sonarr_seedr.spec`

**2. Template/Static Files Not Found**

```
TemplateNotFound: template.html
```

**Solution**: Verify paths in `datas` section of `sonarr_seedr.spec`

**3. Large Executable Size**

- Normal size: 80-150 MB (includes Python runtime + dependencies)
- To reduce size: Remove unused dependencies from requirements.txt

### Runtime Issues

**1. Executable Won't Start**

- Check Windows Defender/Antivirus (may flag as false positive)
- Run from command prompt to see error messages
- Ensure all Visual C++ Redistributables are installed

**2. Web UI Not Loading**

- Check if port 8000 is available
- Try running with `--port 9000` to use different port
- Check firewall settings

**3. Configuration Issues**

- First run creates default config directories
- Check `config\` folder for settings files
- Logs are written to `folder_watcher.log`

## Advanced Configuration

### Custom Icon

1. Create/find a `.ico` file
2. Edit `sonarr_seedr.spec` and set: `icon='path/to/your/icon.ico'`
3. Rebuild

### Windowed Mode (No Console)

1. Edit `sonarr_seedr.spec` and set: `console=False`
2. Rebuild
3. **Note**: You won't see startup logs in console mode

### One-File Executable

1. Edit `sonarr_seedr.spec`
2. Change `exclude_binaries=True` to `exclude_binaries=False`
3. Remove the `COLLECT` section
4. Rebuild

**Pros**: Single .exe file
**Cons**: Slower startup, larger file size

## Build Environment

### Recommended Setup

- **OS**: Windows 10/11
- **Python**: 3.13.x
- **Architecture**: 64-bit
- **Virtual Environment**: Recommended

### Dependencies Versions (Tested)

- fastapi>=0.104.1
- uvicorn>=0.24.0
- pydantic>=2.8.0
- pyinstaller>=6.15.0
- All other dependencies as per requirements.txt

## Security Considerations

### For Distribution

1. **Remove sensitive data** from config files before distribution
2. **Scan executable** with antivirus before sharing
3. **Test on clean Windows VM** before distribution

### For Users

1. **Download from trusted sources** only
2. **Scan with antivirus** before running
3. **Run in isolated environment** if unsure

## Performance Notes

- **Startup time**: 3-5 seconds (includes web server initialization)
- **Memory usage**: ~50-100 MB (varies with active connections)
- **File size**: ~80-150 MB (complete distribution)

## Support

If you encounter issues:

1. Check this troubleshooting guide
2. Run executable from command prompt for detailed error messages
3. Check log files in the application directory
4. Verify all prerequisites are met

---

**Successfully built executable will be available at:**
`dist\SonarrSeedr\SonarrSeedr.exe`

The application will start on `http://localhost:8000` by default.
