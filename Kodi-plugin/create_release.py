#!/usr/bin/env python3
"""
Kodi Plugin Release Package Creator
Creates versioned folders with both plugin and repository ZIPs
"""

import os
import sys
import zipfile
import shutil
import re
import xml.etree.ElementTree as ET
from pathlib import Path


def cleanup_pyc_files(addon_dir):
    """Remove *.pyc files to reduce ZIP size"""
    for root, dirs, files in os.walk(addon_dir):
        for filename in files:
            if filename.endswith(".pyc"):
                try:
                    os.remove(os.path.join(root, filename))
                except:
                    pass


def read_addon_xml(addon_dir):
    """Read the addon.xml file"""
    addon_xml_path = os.path.join(addon_dir, "addon.xml")
    if not os.path.exists(addon_xml_path):
        return None
    try:
        tree = ET.parse(addon_xml_path)
        return tree.getroot()
    except Exception as e:
        print(f"Error parsing {addon_xml_path}: {e}")
        return None


def get_next_version(output_base_dir):
    """Get next version by scanning existing version folders"""
    output_path = Path(output_base_dir)
    if not output_path.exists():
        return "1.0.1"
    
    existing_dirs = [d for d in output_path.iterdir() if d.is_dir() and d.name.startswith('v')]
    if not existing_dirs:
        return "1.0.1"
    
    max_major = 0
    max_minor = 0
    max_patch = 0
    
    for dir_path in existing_dirs:
        match = re.search(r'v(\d+)\.(\d+)\.(\d+)', dir_path.name)
        if match:
            major = int(match.group(1))
            minor = int(match.group(2))
            patch = int(match.group(3))
            
            current_version = major * 1000000 + minor * 1000 + patch
            max_version = max_major * 1000000 + max_minor * 1000 + max_patch
            
            if current_version > max_version:
                max_major = major
                max_minor = minor
                max_patch = patch
    
    if max_major > 0 or max_minor > 0 or max_patch > 0:
        return f"{max_major}.{max_minor}.{max_patch + 1}"
    
    return "1.0.1"


def create_zipfile(addon_dir, output_dir, addon_version):
    """Create ZIP file for the addon"""
    addon_xml_root = read_addon_xml(addon_dir)
    if addon_xml_root is None:
        print(f"ERROR: No valid addon.xml found in {addon_dir}")
        return None
    
    addon_id = addon_xml_root.get("id")
    zipfile_name = os.path.join(output_dir, f"{addon_id}-{addon_version}.zip")
    print(f"  Creating ZIP for {addon_id}...")
    
    temp_dir = f"{addon_id}_temp"
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)
    
    shutil.copytree(addon_dir, os.path.join(temp_dir, addon_id))
    cleanup_pyc_files(os.path.join(temp_dir, addon_id))
    
    with zipfile.ZipFile(zipfile_name, 'w', zipfile.ZIP_DEFLATED) as zip_ref:
        source_dir = os.path.join(temp_dir, addon_id)
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, source_dir)
                zip_path = os.path.join(addon_id, rel_path).replace('\\', '/')
                zip_ref.write(file_path, zip_path)
    
    shutil.rmtree(temp_dir)
    zip_size = os.path.getsize(zipfile_name) / (1024 * 1024)
    zip_basename = os.path.basename(zipfile_name)
    print(f"    Created: {zip_basename} ({zip_size:.2f} MB)")
    
    return zipfile_name


def create_release_package():
    """Create a release package with both plugin and repository"""
    base_output_dir = os.path.join("..", "Plugin Zips", "Kodi")
    if not os.path.exists(base_output_dir):
        os.makedirs(base_output_dir)
    
    new_version = get_next_version(base_output_dir)
    version_dir = os.path.join(base_output_dir, f"v{new_version}")
    
    # Don't create if already exists (shouldn't happen with proper increment)
    if os.path.exists(version_dir):
        print(f"ERROR: Version folder v{new_version} already exists!")
        print(f"This shouldn't happen. Please check the version folders.")
        return False
    
    os.makedirs(version_dir, exist_ok=True)
    
    print(f"Creating release package v{new_version}")
    print("-" * 50)
    
    existing_dirs = [d for d in Path(base_output_dir).iterdir() if d.is_dir() and d.name.startswith('v')]
    if existing_dirs:
        existing_count = len(existing_dirs)
        print(f"Found {existing_count} existing versions")
        for d in sorted(existing_dirs)[-3:]:
            print(f"  - {d.name}")
        print("-" * 50)
    
    # Create plugin ZIP
    plugin_zip = create_zipfile("plugin.video.seedr", version_dir, new_version)
    if not plugin_zip:
        return False
    
    # Create repository ZIP
    repo_zip = create_zipfile("repository.seedr", version_dir, new_version)
    if not repo_zip:
        return False
    
    print("-" * 50)
    print(f"SUCCESS: Release package created!")
    print(f"  Version: v{new_version}")
    print(f"  Location: {version_dir}")
    print(f"  Contains:")
    print(f"    - plugin.video.seedr-{new_version}.zip")
    print(f"    - repository.seedr-{new_version}.zip")
    
    return True


if __name__ == "__main__":
    if not create_release_package():
        sys.exit(1)
