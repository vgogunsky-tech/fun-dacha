#!/usr/bin/env python3
"""
Script to convert WebP images to JPG format in the categories folder
"""

import os
import shutil
from pathlib import Path
from PIL import Image

def is_webp_file(file_path):
    """Check if a file is actually WebP format"""
    try:
        with open(file_path, 'rb') as f:
            header = f.read(12)
            # WebP files start with RIFF and contain WEBP
            return header.startswith(b'RIFF') and b'WEBP' in header
    except:
        return False

def convert_webp_to_jpg(input_path, output_path):
    """Convert WebP image to JPG format"""
    try:
        # Open the image
        with Image.open(input_path) as img:
            # Convert to RGB if necessary (WebP can have transparency)
            if img.mode in ('RGBA', 'LA', 'P'):
                # Create a white background
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                img = background
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Save as JPG with high quality
            img.save(output_path, 'JPEG', quality=95, optimize=True)
            return True
    except Exception as e:
        print(f"Error converting {input_path}: {e}")
        return False

def main():
    """Main function to convert all WebP images to JPG"""
    categories_dir = Path('/workspace/data/images/categories')
    
    print("Checking for WebP images in categories folder...")
    
    webp_files = []
    for file_path in categories_dir.glob('*.jpg'):
        if file_path.is_file() and is_webp_file(file_path):
            webp_files.append(file_path)
    
    print(f"Found {len(webp_files)} WebP files with .jpg extension")
    
    if not webp_files:
        print("No WebP files found. All images are already in proper format.")
        return
    
    # Convert each WebP file
    converted_count = 0
    for file_path in webp_files:
        print(f"Converting {file_path.name}...")
        
        # Create temporary file
        temp_path = file_path.with_suffix('.tmp.jpg')
        
        if convert_webp_to_jpg(file_path, temp_path):
            # Replace original with converted file
            shutil.move(temp_path, file_path)
            print(f"✅ Converted {file_path.name}")
            converted_count += 1
        else:
            # Remove temp file if conversion failed
            if temp_path.exists():
                temp_path.unlink()
            print(f"❌ Failed to convert {file_path.name}")
    
    print(f"\n=== Conversion Complete ===")
    print(f"Successfully converted {converted_count} WebP images to JPG format")

if __name__ == "__main__":
    main()