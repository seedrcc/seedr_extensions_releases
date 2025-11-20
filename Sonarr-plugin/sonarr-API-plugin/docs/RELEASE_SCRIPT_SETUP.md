# 🚀 Automated Release Script Setup

This guide shows you how to use the **automated release script** to build and publish releases to GitHub with one command!

---

## 📋 What the Script Does

The `release.bat` script automates the entire release process:

1. ✅ Reads current version from `app/version.py`
2. ✅ Lets you choose version bump (major/minor/patch)
3. ✅ Updates version.py automatically
4. ✅ Prompts for release notes
5. ✅ Runs `build.bat` to create executable
6. ✅ Commits version change to git
7. ✅ Creates git tag (e.g., `v1.2.0`)
8. ✅ Pushes to GitHub
9. ✅ Creates GitHub release
10. ✅ Uploads ZIP file automatically
11. ✅ Users can now update with one click!

**All in ONE command!** 🎉

---

## ⚙️ One-Time Setup

### Step 1: Install GitHub CLI

The script uses GitHub CLI (`gh`) to interact with GitHub.

#### Windows Installation:

**Option A: Download Installer (Easiest)**
1. Go to: https://cli.github.com/
2. Click "Download for Windows"
3. Run the installer
4. Restart your terminal

**Option B: Using Winget**
```bash
winget install --id GitHub.cli
```

**Option C: Using Chocolatey**
```bash
choco install gh
```

**Option D: Using Scoop**
```bash
scoop install gh
```

### Step 2: Authenticate with GitHub

After installing, run:

```bash
gh auth login
```

Follow the prompts:
1. Choose: `GitHub.com`
2. Choose: `HTTPS`
3. Authenticate: `Login with a web browser`
4. Copy the one-time code
5. Press Enter
6. Browser opens → Paste code → Authorize

**Done!** ✅ You're now authenticated!

### Step 3: Verify Setup

Test if everything works:

```bash
gh auth status
```

Should show:
```
✓ Logged in to github.com as jose987654
✓ Git operations for github.com configured to use https protocol.
✓ Token: *******************
```

---

## 🎯 How to Use the Script

### Basic Usage:

```bash
release.bat
```

That's it! The script will guide you through the process.

---

## 📝 Step-by-Step Walkthrough

### Example: Releasing v1.2.0

```
> release.bat

================================================================================
                    AUTOMATED BUILD AND GITHUB RELEASE
================================================================================

[1/6] Reading version information...
  Current Version: v1.1.0

[2/6] What type of release is this?
  1. Major (breaking changes) - 1.0.0 -> 2.0.0
  2. Minor (new features)     - 1.1.0 -> 1.2.0
  3. Patch (bug fixes)        - 1.1.0 -> 1.1.1
  4. Use current version (1.1.0)
  5. Custom version

Enter choice (1-5): 2

  New Version: v1.2.0

[3/6] Updating version.py...
  Updated to v1.2.0

[4/6] Enter release notes (what's new in this version):
  Type your changes, one per line. Type 'done' when finished.
  Example:
    - Added auto-update feature
    - Fixed bug with downloads
    - Improved performance

  - Added one-click auto-update feature
  - New Settings page with update checker
  - Improved performance and stability
  - done

  Release notes captured.

[5/6] Running build process...
  This may take several minutes...

[Building... PyInstaller output...]

  Build completed successfully!

[6/6] Preparing GitHub release...
  Found: SonarrSeedr-v1.2.0-20250211_183835.zip

Checking for GitHub CLI (gh)...
  GitHub CLI found!

Checking GitHub authentication...
  Authenticated!

Committing version change...
  Committed!

Creating git tag v1.2.0...
  Tag created!

Pushing to GitHub...
  Pushed!

Creating GitHub release...

================================================================================
                          SUCCESS! RELEASE PUBLISHED
================================================================================

  Version:  v1.2.0
  ZIP File: SonarrSeedr-v1.2.0-20250211_183835.zip
  Size:     45678901 bytes

  Release URL: https://github.com/jose987654/sonarr-plugin/releases/tag/v1.2.0

  Users can now update with one click from the Settings page!

================================================================================
```

---

## 🎨 Release Type Examples

### 1. **Minor Release** (New Features)
```
Current:  1.1.0
Choose:   2 (Minor)
New:      1.2.0
```
**When to use:**
- Added new features
- Improved functionality
- Non-breaking changes

### 2. **Patch Release** (Bug Fixes)
```
Current:  1.2.0
Choose:   3 (Patch)
New:      1.2.1
```
**When to use:**
- Fixed bugs
- Small improvements
- Security patches

### 3. **Major Release** (Breaking Changes)
```
Current:  1.2.1
Choose:   1 (Major)
New:      2.0.0
```
**When to use:**
- Breaking changes
- Complete rewrites
- Major architecture changes

### 4. **Custom Version**
```
Current:  1.2.1
Choose:   5 (Custom)
Enter:    1.5.0
New:      1.5.0
```
**When to use:**
- Specific version needed
- Version alignment with other projects

---

## 📚 What Gets Updated

### Files Modified:
- ✅ `app/version.py` - Version number and build date
- ✅ Git repository - New commit and tag
- ✅ GitHub - New release with ZIP

### What's Preserved:
- ✅ All source code
- ✅ Configuration files
- ✅ Documentation
- ✅ Previous releases

---

## 🛠️ Troubleshooting

### Problem: "GitHub CLI not found"

**Solution:**
```bash
# Install GitHub CLI
winget install --id GitHub.cli

# Restart terminal
# Run script again
```

### Problem: "Not authenticated"

**Solution:**
```bash
gh auth login
# Follow the prompts
```

### Problem: "Tag already exists"

**Solution:**
```bash
# Delete the tag locally
git tag -d v1.2.0

# Delete the tag on GitHub
git push origin :refs/tags/v1.2.0

# Run script again
```

### Problem: "Build failed"

**Solution:**
1. Check Python is installed
2. Run `pip install -r requirements.txt`
3. Check for syntax errors in code
4. Try running `build.bat` manually to see errors

### Problem: "Push failed"

**Solution:**
```bash
# Make sure you're on the main branch
git checkout main

# Pull latest changes
git pull origin main

# Try script again
```

---

## 🎯 Best Practices

### Before Running the Script:

1. ✅ **Test your code** - Make sure everything works
2. ✅ **Commit changes** - Commit all your work first
3. ✅ **Update documentation** - Update README if needed
4. ✅ **Check current version** - Know what version you're on

### Release Notes Tips:

**Good Release Notes:**
```
- Added auto-update feature in Settings page
- Fixed bug where downloads would fail on large files
- Improved performance by 30%
- Updated dependencies to latest versions
```

**Bad Release Notes:**
```
- stuff
- fixed things
- idk some changes
```

### Version Numbering:

Follow **Semantic Versioning**:
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backwards compatible
- **Patch** (0.0.X): Bug fixes only

---

## 🚀 Quick Commands

### First Time Setup:
```bash
# Install GitHub CLI
winget install --id GitHub.cli

# Authenticate
gh auth login

# Test
gh auth status
```

### Release a New Version:
```bash
release.bat
```

### Manual GitHub Operations:
```bash
# Create release manually
gh release create v1.2.0 releases\YourFile.zip --title "Version 1.2.0"

# List releases
gh release list

# Delete a release
gh release delete v1.2.0

# View release
gh release view v1.2.0
```

---

## 📦 What Happens After Release

### For You (Developer):
1. ✅ New version committed to git
2. ✅ Tag created (`v1.2.0`)
3. ✅ Release published on GitHub
4. ✅ ZIP file uploaded

### For Your Users:
1. ✅ Open app → Settings page
2. ✅ Click "Check for Updates"
3. ✅ See new version available
4. ✅ Click "Download & Install"
5. ✅ App updates automatically!
6. ✅ Settings preserved! 🎉

---

## 💡 Pro Tips

1. **Test First**: Always test your build locally before releasing
2. **Version Bump**: Use Minor for features, Patch for fixes
3. **Release Notes**: Write clear, user-friendly notes
4. **Tag Format**: Always use `v` prefix (v1.2.0)
5. **Backup**: Keep old releases available for rollbacks

---

## 🎊 Summary

### Without This Script (Manual):
1. Update version.py manually
2. Run build.bat
3. Commit changes
4. Create git tag
5. Push to GitHub
6. Go to GitHub website
7. Create release manually
8. Upload ZIP file
9. Write release notes
10. Publish

**Time: 10-15 minutes** ⏰

### With This Script (Automated):
```bash
release.bat
```

**Time: 2-3 minutes** ⚡

---

## ❓ FAQ

### Q: Do I need to create releases for every commit?
**A:** No! Only create releases for versions you want users to download.

### Q: Can I delete a release?
**A:** Yes! Use `gh release delete v1.2.0` or delete on GitHub website.

### Q: What if I make a mistake?
**A:** You can delete the release and tag, fix the issue, and run the script again.

### Q: Can I edit release notes after publishing?
**A:** Yes! Go to the release on GitHub and click "Edit release".

### Q: Will this overwrite my code?
**A:** No! It only updates `version.py` and creates a new commit. All your code is safe.

---

## 🔗 Useful Links

- **GitHub CLI**: https://cli.github.com/
- **GitHub CLI Docs**: https://cli.github.com/manual/
- **Your Releases**: https://github.com/jose987654/sonarr-plugin/releases
- **Semantic Versioning**: https://semver.org/

---

**🎉 Happy Releasing!**

Now you can publish updates in seconds! Your users will love the one-click auto-update feature! 🚀

