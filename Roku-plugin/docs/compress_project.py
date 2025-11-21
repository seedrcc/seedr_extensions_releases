#!/usr/bin/env python3
"""
Project Compression Script

Compresses manifest, components/, images/, and source/ into a single ZIP file
with all items available at the root of the compressed file.
"""

import os
import zipfile
import sys
import re
from pathlib import Path

def find_roku_plugin_dir():
    """Find the Roku-plugin directory regardless of where script is run from."""
    # Get the script's location
    script_dir = Path(__file__).parent.absolute()
    
    # Check if we're in docs folder
    if script_dir.name == 'docs':
        roku_dir = script_dir.parent
    else:
        roku_dir = script_dir
    
    # Verify this is the correct directory by checking for manifest
    if not (roku_dir / 'manifest').exists():
        # Try to find Roku-plugin in parent directories
        current = Path.cwd()
        while current != current.parent:
            if (current / 'Roku-plugin' / 'manifest').exists():
                return current / 'Roku-plugin'
            current = current.parent
        return None
    
    return roku_dir

def get_output_directory():
    """Get the output directory for ZIP files."""
    roku_dir = find_roku_plugin_dir()
    if roku_dir is None:
        return None
    
    # Output to Plugin Zips/Roku directory
    output_dir = roku_dir.parent / 'Plugin Zips' / 'Roku'
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir

def get_next_version_number(output_dir):
    """Find the next version number by checking existing files."""
    if output_dir is None:
        return "1.0.1"
    
    existing_files = list(output_dir.glob("Roku_Seedr_v*.zip"))
    
    if not existing_files:
        return "1.0.1"
    
    # Extract version numbers from existing files
    version_numbers = []
    for file_path in existing_files:
        match = re.search(r'Roku_Seedr_v(\d+)\.(\d+)\.(\d+)\.zip', file_path.name)
        if match:
            major = int(match.group(1))
            minor = int(match.group(2))
            patch = int(match.group(3))
            # Convert version to comparable number
            version_num = major * 1000000 + minor * 1000 + patch
            version_numbers.append((version_num, major, minor, patch))
    
    if version_numbers:
        # Get the highest version and increment patch number
        highest = max(version_numbers, key=lambda x: x[0])
        major, minor, patch = highest[1], highest[2], highest[3]
        return f"{major}.{minor}.{patch + 1}"
    else:
        return "1.0.1"

def compress_project():
    """Compress the project files into a single ZIP archive."""
    
    # Find the Roku plugin directory
    base_dir = find_roku_plugin_dir()
    if base_dir is None:
        print("ERROR: Could not find Roku-plugin directory!")
        print("Please ensure the script is in the Roku-plugin or its docs folder.")
        return False, None
    
    # Get output directory
    output_dir = get_output_directory()
    if output_dir is None:
        print("ERROR: Could not determine output directory!")
        return False, None
    
    # Define the items to compress
    items_to_compress = [
        'manifest',
        'components',       
        'images',
        'source'
    ]
    
    # Get next version number and create output file name
    version_number = get_next_version_number(output_dir)
    output_file = output_dir / f'Roku_Seedr_v{version_number}.zip'
    
    print(f"Plugin directory: {base_dir}")
    print(f"Output directory: {output_dir}")
    print(f"Output file: {output_file.name}")
    print("-" * 50)
    
    # Check if all required items exist
    missing_items = []
    for item in items_to_compress:
        item_path = base_dir / item
        if not item_path.exists():
            missing_items.append(item)
    
    if missing_items:
        print(f"ERROR: The following items are missing:")
        for item in missing_items:
            print(f"  - {item}")
        print(f"\nChecked in directory: {base_dir}")
        return False, None
    
    try:
        # Create the ZIP file
        with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as zipf:
            
            for item in items_to_compress:
                item_path = base_dir / item
                
                if item_path.is_file():
                    # Add file directly to root of ZIP
                    print(f"Adding file: {item}")
                    zipf.write(item_path, item)
                    
                elif item_path.is_dir():
                    # Add directory and all its contents to root of ZIP
                    print(f"Adding directory: {item}/")
                    
                    # Walk through the directory
                    for root, dirs, files in os.walk(item_path):
                        # Calculate relative path from the base directory
                        rel_root = Path(root).relative_to(base_dir)
                        
                        # Add all files in this directory
                        for file in files:
                            file_path = Path(root) / file
                            # Archive path maintains the directory structure from the item root
                            archive_path = rel_root / file
                            print(f"  Adding: {archive_path}")
                            zipf.write(file_path, archive_path)
        
        # Get file size for confirmation
        zip_size = os.path.getsize(output_file)
        zip_size_mb = zip_size / (1024 * 1024)
        
        print("-" * 50)
        print(f"✓ Compression completed successfully!")
        print(f"✓ Output file: {output_file.name}")
        print(f"✓ Version: v{version_number}")
        print(f"✓ Compressed size: {zip_size_mb:.2f} MB ({zip_size:,} bytes)")
        print(f"✓ Location: {output_file}")
        
        # List contents of the ZIP file for verification
        print("\nContents of the compressed file:")
        with zipfile.ZipFile(output_file, 'r') as zipf:
            file_list = zipf.namelist()
            file_list.sort()
            
            # Group by top-level items
            root_files = [f for f in file_list if '/' not in f]
            directories = {}
            
            for file_path in file_list:
                if '/' in file_path:
                    top_dir = file_path.split('/')[0]
                    if top_dir not in directories:
                        directories[top_dir] = []
                    directories[top_dir].append(file_path)
            
            # Show root files
            if root_files:
                print("  Root files:")
                for f in root_files:
                    print(f"    {f}")
            
            # Show directories
            for dir_name, files in directories.items():
                print(f"  {dir_name}/ ({len(files)} files)")
                # Show first few files as sample
                for f in files[:3]:
                    print(f"    {f}")
                if len(files) > 3:
                    print(f"    ... and {len(files) - 3} more files")
        
        return True, output_file
        
    except Exception as e:
        print(f"ERROR: Failed to create ZIP file: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, None

def main():
    """Main function."""
    print("Roku Project Compression Script")
    print("=" * 50)
    
    # Get output directory
    output_dir = get_output_directory()
    if output_dir is None:
        print("ERROR: Could not find Roku-plugin directory!")
        sys.exit(1)
    
    # Get the next version number
    version_number = get_next_version_number(output_dir)
    output_file_name = f'Roku_Seedr_v{version_number}.zip'
    
    print(f"Next version will be: v{version_number}")
    print(f"Output file: {output_file_name}")
    
    # Check existing versions
    existing_files = list(output_dir.glob("Roku_Seedr_v*.zip"))
    if existing_files:
        print(f"Found {len(existing_files)} existing version(s):")
        for file_path in sorted(existing_files)[-5:]:  # Show last 5 versions
            file_size = file_path.stat().st_size / (1024 * 1024)
            print(f"  - {file_path.name} ({file_size:.2f} MB)")
    
    # Perform compression
    success, output_path = compress_project()
    
    if success:
        print(f"\n🎉 Project successfully compressed!")
        print(f"📦 Version v{version_number} is ready for distribution!")
        print(f"📍 Location: {output_path}")
        print("\nYou can now distribute this single ZIP file containing all your project components.")
    else:
        print("\n❌ Compression failed. Please check the error messages above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
