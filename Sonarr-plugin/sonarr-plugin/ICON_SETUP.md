# 🎨 Adding a Custom Icon to SonarrSeedr

## ✅ Icon Configuration Updated!

The spec file is now configured to use `seedr_icon.ico` as the application icon.

---

## 📥 How to Get a Seedr Icon

### Method 1: Download from Seedr Website

1. **Visit Seedr:**
   - Go to https://www.seedr.cc
   - Right-click on the Seedr logo
   - Save image as PNG or JPG

2. **Convert to .ico:**
   - Visit: https://convertio.co/png-ico/
   - Upload your Seedr logo
   - Set size to **256x256** (recommended for best quality)
   - Download the `.ico` file
   - Rename it to `seedr_icon.ico`

3. **Place in Project:**
   - Copy `seedr_icon.ico` to your project root folder:
     ```
     D:\New folder (3)\New folder (5)\Seedr Plugins\sonarr-fast-API-plugin\seedr_icon.ico
     ```

### Method 2: Use Online Icon Generator

1. **Visit Icon Generator:**
   - https://favicon.io/favicon-converter/
   - Or: https://www.icoconverter.com/

2. **Upload Image:**
   - Upload Seedr logo (any format)
   - Choose **Windows Icon** format
   - Select multiple sizes (16x16, 32x32, 48x48, 64x64, 128x128, 256x256)

3. **Download & Place:**
   - Download the `.ico` file
   - Rename to `seedr_icon.ico`
   - Place in project root

### Method 3: Use Python Script (If you have Pillow)

If you have Python Pillow installed, use this script:

```python
# create_icon.py
from PIL import Image

# Convert PNG/JPG to ICO
img = Image.open('seedr_logo.png')  # Your source image
icon_sizes = [(16,16), (32,32), (48,48), (64,64), (128,128), (256,256)]
img.save('seedr_icon.ico', format='ICO', sizes=icon_sizes)
print("Icon created: seedr_icon.ico")
```

Run with:
```bash
pip install Pillow
python create_icon.py
```

---

## 🔨 Build with New Icon

Once you have `seedr_icon.ico` in your project root:

```bash
# Run the build
build.bat

# The executable will now have your custom icon!
```

---

## 📝 What Was Changed

In `sonarr_seedr.spec`, line 233:

**Before:**
```python
icon=None,  # Add path to .ico file here if you have one
```

**After:**
```python
icon='seedr_icon.ico',  # Custom Seedr icon
```

---

## ✨ Icon Requirements

For best results, your `.ico` file should include multiple sizes:
- 16x16 pixels (taskbar)
- 32x32 pixels (desktop)
- 48x48 pixels (large icons)
- 64x64 pixels (extra large)
- 128x128 pixels (jumbo)
- 256x256 pixels (high-DPI displays)

Most online converters create multi-size icons automatically!

---

## 🎯 Quick Steps Summary

1. ✅ **Spec file updated** (already done!)
2. ⬜ **Get Seedr logo** (download from seedr.cc)
3. ⬜ **Convert to .ico** (use online converter)
4. ⬜ **Place in project root** (name it `seedr_icon.ico`)
5. ⬜ **Run build.bat** (executable will have new icon!)

---

## 🆘 Troubleshooting

### "Icon file not found" error
- Make sure `seedr_icon.ico` is in the project root (same folder as `build.bat`)
- Check the filename is exactly `seedr_icon.ico` (case-sensitive on some systems)

### Icon doesn't appear after build
- Windows may cache icons - restart Explorer or reboot
- Right-click EXE → Properties → Check icon tab
- Try deleting `build` folder and rebuilding

### Icon looks blurry
- Use higher resolution source image (at least 256x256)
- Make sure .ico file contains multiple sizes
- Use PNG format before converting (better quality than JPG)

---

## 💡 Pro Tips

1. **Use SVG if available** - Seedr might have SVG logo which scales perfectly
2. **Transparent background** - Looks better on all backgrounds
3. **Square image** - Icons should be square (1:1 aspect ratio)
4. **High contrast** - Make sure it's visible on light and dark backgrounds
5. **Test before building** - Preview the .ico file in Windows before building

---

## 🔗 Helpful Links

- **Online Icon Converter:** https://convertio.co/png-ico/
- **Favicon Generator:** https://favicon.io/favicon-converter/
- **ICO Converter:** https://www.icoconverter.com/
- **Seedr Website:** https://www.seedr.cc

---

## 📱 Where the Icon Appears

After building with the new icon, you'll see it:
- ✅ Desktop shortcut
- ✅ Taskbar when running
- ✅ File Explorer
- ✅ Alt+Tab switcher
- ✅ Task Manager
- ✅ Start Menu (if pinned)

---

**Ready to build with your new icon!** 🚀

Just place `seedr_icon.ico` in the project root and run `build.bat`!

