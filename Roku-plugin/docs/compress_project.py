#!/usr/bin/env python3
"""
Project Compression Script

Compresses manifest, components/, main.py, images/, and source/ into a single ZIP file
with all items available at the root of the compressed file.
"""

import os
import zipfile
import sys
import re
from pathlib import Path

def get_next_version_number():
    """Find the next version number by checking existing files."""
    base_dir = Path.cwd()
    existing_files = list(base_dir.glob("Roku_test_V*.zip"))
    
    if not existing_files:
        return 1
    
    # Extract version numbers from existing files
    version_numbers = []
    for file_path in existing_files:
        match = re.search(r'Roku_test_V(\d+)\.zip', file_path.name)
        if match:
            version_numbers.append(int(match.group(1)))
    
    if version_numbers:
        return max(version_numbers) + 1
    else:
        return 1

def compress_project():
    """Compress the project files into a single ZIP archive."""
    
    # Get the current working directory
    base_dir = Path.cwd()
    
    # Define the items to compress
    items_to_compress = [
        'manifest',
        'components',
        'main.py', 
        'images',
        'source'
    ]
    
    # Get next version number and create output file name
    version_number = get_next_version_number()
    output_file = f'Roku_test_V{version_number}.zip'
    
    print(f"Starting compression from directory: {base_dir}")
    print(f"Output file: {output_file}")
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
        print("\nPlease ensure you're running this script from the correct directory.")
        return False
    
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
        print(f"✓ Output file: {output_file} (Version {version_number})")
        print(f"✓ Compressed size: {zip_size_mb:.2f} MB ({zip_size:,} bytes)")
        
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
        
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to create ZIP file: {str(e)}")
        return False

def main():
    """Main function."""
    print("Roku Project Compression Script")
    print("=" * 50)
    
    # Get the next version number
    version_number = get_next_version_number()
    output_file = f'Roku_test_V{version_number}.zip'
    
    print(f"Next version will be: V{version_number}")
    print(f"Output file: {output_file}")
    
    # Check existing versions
    existing_files = list(Path.cwd().glob("Roku_test_V*.zip"))
    if existing_files:
        print(f"Found {len(existing_files)} existing version(s):")
        for file_path in sorted(existing_files):
            file_size = file_path.stat().st_size / (1024 * 1024)
            print(f"  - {file_path.name} ({file_size:.2f} MB)")
    
    # No need to check for overwrite since we're auto-incrementing
    
    # Perform compression
    success = compress_project()
    
    if success:
        print(f"\n🎉 Project successfully compressed to: {output_file}")
        print(f"📦 Version V{version_number} is ready for distribution!")
        print("\nYou can now distribute this single ZIP file containing all your project components.")
    else:
        print("\n❌ Compression failed. Please check the error messages above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
