"""
Icon Creator for SonarrSeedr
Converts PNG/JPG/BMP images to Windows .ico format
"""
import sys
import os

def create_icon_from_image(input_file, output_file='seedr_icon.ico'):
    """
    Convert an image to .ico format with multiple sizes.
    
    Args:
        input_file: Path to input image (PNG, JPG, BMP, etc.)
        output_file: Output .ico filename (default: seedr_icon.ico)
    """
    try:
        from PIL import Image
    except ImportError:
        print("❌ ERROR: Pillow library not installed!")
        print("\nInstall it with:")
        print("  pip install Pillow")
        print("\nOr use an online converter:")
        print("  https://convertio.co/png-ico/")
        return False
    
    try:
        # Open the image
        print(f"📂 Opening image: {input_file}")
        img = Image.open(input_file)
        
        # Convert to RGB if necessary (remove alpha channel issues)
        if img.mode != 'RGB' and img.mode != 'RGBA':
            print("🔄 Converting image mode...")
            if 'transparency' in img.info:
                img = img.convert('RGBA')
            else:
                img = img.convert('RGB')
        
        # Define icon sizes (Windows standard)
        icon_sizes = [
            (16, 16),    # Small icons
            (32, 32),    # Standard desktop icons
            (48, 48),    # Large icons
            (64, 64),    # Extra large
            (128, 128),  # Jumbo icons
            (256, 256),  # High-DPI displays
        ]
        
        print("🎨 Creating multi-size icon...")
        print(f"   Sizes: {', '.join([f'{w}x{h}' for w, h in icon_sizes])}")
        
        # Save as .ico with multiple sizes
        img.save(output_file, format='ICO', sizes=icon_sizes)
        
        # Get file size
        file_size = os.path.getsize(output_file)
        size_kb = file_size / 1024
        
        print(f"\n✅ SUCCESS! Icon created:")
        print(f"   File: {output_file}")
        print(f"   Size: {size_kb:.1f} KB")
        print(f"   Contains {len(icon_sizes)} sizes")
        print("\n🚀 Ready to build! Run: build.bat")
        
        return True
        
    except FileNotFoundError:
        print(f"❌ ERROR: File not found: {input_file}")
        print("\nMake sure the file exists and the path is correct.")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        print("\nTry using an online converter instead:")
        print("  https://convertio.co/png-ico/")
        return False


def main():
    """Main function with user interaction."""
    print("="*60)
    print("🎨 SonarrSeedr Icon Creator")
    print("="*60)
    print()
    
    # Check if input file provided as argument
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        # Ask user for input file
        print("Enter the path to your Seedr logo image:")
        print("(PNG, JPG, BMP, or any image format)")
        print()
        input_file = input("Image path: ").strip().strip('"')
    
    if not input_file:
        print("❌ No input file specified!")
        return
    
    # Create the icon
    success = create_icon_from_image(input_file)
    
    if not success:
        print("\n" + "="*60)
        print("Alternative: Use Online Converter")
        print("="*60)
        print("\n1. Visit: https://convertio.co/png-ico/")
        print("2. Upload your image")
        print("3. Download the .ico file")
        print("4. Save as: seedr_icon.ico")
        print("5. Run: build.bat")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelled by user")
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
    
    print("\n" + "="*60)
    input("Press Enter to exit...")

