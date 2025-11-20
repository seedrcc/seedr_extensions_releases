# 📦 How to Update Release Links Automatically

This guide explains how to automatically update `index.html` and `README.md` with new release links whenever you publish a new release on GitHub.

## 🎯 Two Methods Available

### Method 1: Automatic (Recommended) - GitHub Actions

**This method automatically updates files when you publish a release!**

#### Setup (One-time):

1. **The workflow file is already created**: `.github/workflows/update-release-links.yml`

2. **Ensure GitHub Actions has write permissions**:
   - Go to your repository → Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
   - Click "Save"

3. **That's it!** The workflow will automatically run when you publish a release.

#### How It Works:

1. **Publish a new release** on GitHub (e.g., `v1.1.7`)
2. **Upload your ZIP file** as a release asset (e.g., `SonarrSeedr-v1.1.7-20250212_120000.zip`)
3. **GitHub Actions automatically**:
   - Detects the new release
   - Finds the ZIP file in release assets
   - Updates all download links to point directly to the ZIP file download URL
   - Updates `index.html`, `README.md`, and `WINDOWS_SETUP_GUIDE.html`
   - Commits and pushes the changes

#### Manual Trigger (if needed):

You can also manually trigger the workflow:
- Go to Actions tab → "Update Release Links" → "Run workflow"

---

### Method 2: Manual Script

**Use this if you prefer to update manually or if GitHub Actions isn't working.**

#### Prerequisites:

1. **Python 3.7+** installed
2. **requests library**: `pip install requests`

#### Usage:

**Windows:**
```batch
# Simple (uses public API, may hit rate limits)
update-release-links.bat

# With GitHub token (recommended for frequent updates)
update-release-links.bat YOUR_GITHUB_TOKEN
```

**Linux/Mac:**
```bash
# Simple
python3 update-release-links.py

# With GitHub token
python3 update-release-links.py YOUR_GITHUB_TOKEN
```

#### Getting a GitHub Token (Optional but Recommended):

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "Release Updater")
4. Select scope: `repo` (full control of private repositories)
5. Click "Generate token"
6. Copy the token and use it in the script

#### After Running the Script:

The script will update the files. Then commit and push:

```bash
git add index.html README.md WINDOWS_SETUP_GUIDE.html
git commit -m "📦 Update release links to SonarrSeedr-v1.1.7-20250212_120000.zip"
git push
```

---

## 🔍 What Gets Updated?

The script automatically finds the ZIP file in your release and updates all download links to point directly to it:

### `index.html`
- Download button link: Direct download URL to the ZIP file (e.g., `https://github.com/jose987654/sonarr-plugin/releases/download/v1.1.6/SonarrSeedr-v1.1.6-20250911_183343.zip`)

### `README.md`
- Quick Start download link → Direct ZIP file link with filename
- Requirements section download link → Direct ZIP file link with filename
- Quick Start Summary download link → Direct ZIP file link with filename

### `WINDOWS_SETUP_GUIDE.html`
- Installation section → Direct ZIP file download link

**Note**: All links now point directly to the ZIP file download, so users can click and download immediately. The system automatically finds the ZIP file in your release assets!

---

## 🧪 Testing

### Test the Script Locally:

1. **Dry run** - Check what would be updated:
   ```bash
   python update-release-links.py
   ```

2. **Check the changes**:
   ```bash
   git diff index.html README.md WINDOWS_SETUP_GUIDE.html
   ```

3. **If satisfied, commit**:
   ```bash
   git add index.html README.md WINDOWS_SETUP_GUIDE.html
   git commit -m "📦 Update to latest release"
   git push
   ```

---

## 🐛 Troubleshooting

### GitHub Actions Not Running?

1. **Check Actions tab** - Is the workflow enabled?
2. **Check permissions** - Settings → Actions → General → Workflow permissions
3. **Check release** - Make sure the release is published (not draft)
4. **Check ZIP file** - Make sure a ZIP file is uploaded as an asset

### Script Errors?

1. **"requests library not found"**:
   ```bash
   pip install requests
   ```

2. **"No ZIP file found"**:
   - Make sure your ZIP file name contains "SonarrSeedr"
   - Make sure it's uploaded as a release asset (not just in the release description)

3. **Rate limit errors**:
   - Use a GitHub token: `python update-release-links.py YOUR_TOKEN`

### Files Not Updating?

1. **Check file paths** - Make sure you're running from the repository root
2. **Check file permissions** - Make sure files are writable
3. **Check regex patterns** - The script looks for specific patterns, make sure your file format matches

---

## 📝 Release Naming Convention

For best results, name your releases and ZIP files consistently:

**Recommended format:**
- **Release Tag**: `v1.1.7` or `1.1.7`
- **ZIP File**: `SonarrSeedr-v1.1.7-20250212_120000.zip`

The script will find any ZIP file containing "SonarrSeedr" in the release assets.

---

## 🎉 Quick Start Summary

**For Automatic Updates (Recommended):**
1. ✅ Workflow file already created
2. ✅ Enable GitHub Actions write permissions
3. ✅ Publish release → Files auto-update!

**For Manual Updates:**
1. ✅ Run `update-release-links.bat` (Windows) or `python3 update-release-links.py` (Linux/Mac)
2. ✅ Review changes with `git diff`
3. ✅ Commit and push

---

**Need help?** Check the [GitHub Actions logs](https://github.com/jose987654/sonarr-plugin/actions) or run the script with verbose output.

