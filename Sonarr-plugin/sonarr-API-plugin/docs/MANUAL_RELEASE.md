# 📦 Manual Release Guide (No GitHub CLI Needed!)

If the automatic release script isn't working, you can release manually in 5 easy steps!

---

## 🚀 **Quick Steps:**

### **1. Build Your App**

```bash
build.bat
```

Wait for it to complete. You'll get a ZIP file in `releases/` folder.

---

### **2. Update Version Number** (Optional)

Edit `app/version.py`:

```python
__version__ = "1.2.0"  # Change this to your new version
__build_date__ = "2025-02-11"
__description__ = "Sonarr-Seedr Integration - Automated torrent downloading via Seedr cloud service"
```

---

### **3. Go to GitHub Releases**

Open this URL in your browser:

**https://github.com/jose987654/sonarr-plugin/releases/new**

---

### **4. Fill in Release Form**

| Field | What to Enter |
|-------|---------------|
| **Tag** | `v1.2.0` (must start with `v`) |
| **Title** | `Version 1.2.0` |
| **Description** | Write what's new (see example below) |
| **Upload File** | Drag your ZIP from `releases/` folder |

**Example Description:**

```markdown
## What's New in v1.2.0

- Added one-click auto-update feature
- New Settings page with update checker
- Added favicon to all pages
- Improved performance and stability
- Fixed download bugs

## Installation

1. Download the ZIP file below
2. Extract to your installation folder
3. Run `SonarrSeedr.exe`

## For Existing Users

Simply extract to your existing folder and overwrite files.
Your settings will be preserved automatically!
```

---

### **5. Publish Release**

Click the green **"Publish release"** button!

---

## ✅ **Done!**

Your release is now live at:
**https://github.com/jose987654/sonarr-plugin/releases**

Users can now:
- Download the latest version
- Use auto-update from Settings page! 🎉

---

## 🎯 **Tips:**

- ✅ Always use `vX.Y.Z` format for tags (e.g., `v1.2.0`)
- ✅ Write clear release notes so users know what's new
- ✅ Keep old releases available (don't delete them)
- ✅ Test the ZIP before uploading

---

## 🔧 **Common Issues:**

### **Q: Can't find the ZIP file?**
**A:** It's in `releases/` folder with a name like `SonarrSeedr-v1.1.0-20250211_183835.zip`

### **Q: What version should I use?**
**A:** Check `app/version.py` to see current version, then increment:
- Bug fixes: `1.1.0` → `1.1.1` (patch)
- New features: `1.1.0` → `1.2.0` (minor)
- Breaking changes: `1.1.0` → `2.0.0` (major)

### **Q: Do I need to push code to GitHub?**
**A:** No! Just upload the ZIP to releases. Keep source code in `sonarr-ext` repo.

---

**That's it!** Manual releasing is easy! 🚀


