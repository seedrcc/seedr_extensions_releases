#!/usr/bin/env python3
"""
Script to update release links in index.html and README.md
Can be run manually or via GitHub Actions
"""

import re
import sys
import os
import json
from pathlib import Path

try:
    import requests
except ImportError:
    print("❌ Error: requests library not found. Install it with: pip install requests")
    sys.exit(1)


def get_latest_release(repo_owner, repo_name, github_token=None):
    """Get the latest release information from GitHub API"""
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
    
    headers = {}
    if github_token:
        headers["Authorization"] = f"token {github_token}"
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching release: {e}")
        sys.exit(1)


def find_zip_asset(release_data):
    """Find the ZIP file in release assets and return its download URL"""
    for asset in release_data.get("assets", []):
        name = asset.get("name", "").lower()
        if name.endswith(".zip") and ("sonarrseedr" in name or "sonarr" in name):
            return asset.get("browser_download_url", ""), asset.get("name", "")
    return None, None


def find_installer_asset(release_data):
    """Find the installer EXE file in release assets and return its download URL"""
    for asset in release_data.get("assets", []):
        name = asset.get("name", "").lower()
        if name.endswith(".exe") and ("setup" in name or "installer" in name) and ("sonarrseedr" in name or "sonarr" in name):
            return asset.get("browser_download_url", ""), asset.get("name", "")
    return None, None


def update_file(file_path, zip_filename, pattern):
    """Update release links in a file"""
    file_path = Path(file_path)
    
    if not file_path.exists():
        print(f"⚠️  Warning: {file_path} not found, skipping...")
        return False
    
    try:
        content = file_path.read_text(encoding='utf-8')
        original_content = content
        
        # Update all matches
        content = re.sub(pattern, zip_filename, content)
        
        if content != original_content:
            file_path.write_text(content, encoding='utf-8')
            print(f"✅ Updated {file_path.name}")
            return True
        else:
            print(f"ℹ️  No changes needed in {file_path.name}")
            return False
    except Exception as e:
        print(f"❌ Error updating {file_path}: {e}")
        return False


def main():
    # Configuration
    REPO_OWNER = "jose987654"
    REPO_NAME = "sonarr-plugin"
    
    # Get GitHub token from environment (optional, for private repos or rate limits)
    github_token = None
    if len(sys.argv) > 1:
        github_token = sys.argv[1]
    elif "GITHUB_TOKEN" in os.environ:
        github_token = os.environ.get("GITHUB_TOKEN")
    
    print("🔍 Fetching latest release from GitHub...")
    release_data = get_latest_release(REPO_OWNER, REPO_NAME, github_token)
    
    zip_url, zip_filename = find_zip_asset(release_data)
    if not zip_url or not zip_filename:
        print("❌ Error: No ZIP file found in latest release assets")
        print("   Make sure you've uploaded a ZIP file containing 'SonarrSeedr' in the name")
        sys.exit(1)
    
    installer_url, installer_filename = find_installer_asset(release_data)
    
    print(f"📦 Latest release: {release_data['tag_name']}")
    print(f"📦 ZIP file: {zip_filename}")
    print(f"📦 Download URL: {zip_url}")
    if installer_url:
        print(f"💿 Installer: {installer_filename}")
        print(f"💿 Download URL: {installer_url}")
    else:
        print("⚠️  No installer found in this release")
    print()
    
    # Update files
    updated = False
    
    # Pattern for index.html - update both direct ZIP links and GitHub URLs
    print("📝 Updating index.html...")
    try:
        content = Path("index.html").read_text(encoding='utf-8')
        original_content = content
        
        # Multiple patterns to catch all ZIP link formats
        patterns_html_zip = [
            (r'releases/SonarrSeedr-[^"\']*\.zip', zip_url),
            (r'https://github\.com/jose987654/sonarr-plugin/releases/download/[^"\']*/[^"\']*\.zip', zip_url),
        ]
        
        for pattern, replacement in patterns_html_zip:
            content = re.sub(pattern, replacement, content)
        
        # Also update the download attribute to use download instead of target="_blank"
        content = re.sub(r'href="[^"]*releases[^"]*\.zip" class="btn btn-primary" target="_blank"', 
                       f'href="{zip_url}" class="btn btn-primary" download', content)
        content = re.sub(r'href="[^"]*releases[^"]*\.zip" class="btn btn-primary"(?!\s+download)', 
                       f'href="{zip_url}" class="btn btn-primary" download', content)
        
        # Update installer download link if installer exists
        if installer_url:
            patterns_html_installer = [
                (r'https://github\.com/jose987654/sonarr-plugin/releases/download/[^"\']*/[^"\']*\.(exe|EXE)', installer_url),
                (r'releases/SonarrSeedr-[^"\']*\.(exe|EXE)', installer_url),
            ]
            
            for pattern, replacement in patterns_html_installer:
                content = re.sub(pattern, replacement, content)
            
            # Ensure download attribute for installer button
            content = re.sub(r'href="[^"]*releases[^"]*\.exe" class="btn btn-primary" target="_blank"', 
                           f'href="{installer_url}" class="btn btn-primary" download', content)
            content = re.sub(r'href="[^"]*releases[^"]*\.exe" class="btn btn-primary"(?!\s+download)', 
                           f'href="{installer_url}" class="btn btn-primary" download', content)
        
        if content != original_content:
            Path("index.html").write_text(content, encoding='utf-8')
            if installer_url:
                print("✅ Updated index.html (ZIP and Installer links)")
            else:
                print("✅ Updated index.html (ZIP links)")
            updated = True
        else:
            print("ℹ️  No changes needed in index.html")
    except Exception as e:
        print(f"❌ Error updating index.html: {e}")
    
    # Pattern for README.md - update markdown links to point directly to ZIP file
    patterns_md = [
        (r'\[Download from GitHub Releases\]\([^)]*\)', f'[`{zip_filename}`]({zip_url})'),
        (r'\[Latest Release on GitHub\]\([^)]*\)', f'[`{zip_filename}`]({zip_url})'),
        (r'\[`SonarrSeedr-[^`]*\.zip`\]\([^)]*\)', f'[`{zip_filename}`]({zip_url})'),
        (r'https://github\.com/jose987654/sonarr-plugin/releases/[^)]*', zip_url),
    ]
    for pattern, replacement in patterns_md:
        content = Path("README.md").read_text(encoding='utf-8')
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            Path("README.md").write_text(new_content, encoding='utf-8')
            updated = True
    
    # Pattern for WINDOWS_SETUP_GUIDE.html
    patterns_guide = [
        (r'<a href="[^"]*releases[^"]*"[^>]*>GitHub Releases</a>', f'<a href="{zip_url}" download>{zip_filename}</a>'),
        (r'<code>SonarrSeedr-[^<]*\.zip</code>', f'<a href="{zip_url}" download>{zip_filename}</a>'),
        (r'https://github\.com/jose987654/sonarr-plugin/releases/[^<]*', zip_url),
    ]
    for pattern, replacement in patterns_guide:
        if update_file("WINDOWS_SETUP_GUIDE.html", replacement, pattern):
            updated = True
    
    if updated:
        print()
        print("✅ All files updated successfully!")
        print(f"📝 Next step: Commit and push the changes")
        print(f"   git add index.html README.md WINDOWS_SETUP_GUIDE.html")
        print(f"   git commit -m '📦 Update release links to latest GitHub release'")
        print(f"   git push")
    else:
        print()
        print("ℹ️  No files needed updating (already up to date)")


if __name__ == "__main__":
    main()

