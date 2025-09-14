#!/usr/bin/env python3
"""
Script to replace category images using the mapping between category IDs and library images
"""

import os
import shutil
import csv
from pathlib import Path

def create_category_mapping():
    """Create mapping between category IDs and library images"""
    
    # Read categories from CSV
    categories = {}
    with open('/workspace/data/categories_list.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter=',')
        for row in reader:
            # Clean up the field names (remove extra spaces)
            clean_row = {k.strip(): v.strip() for k, v in row.items()}
            categories[clean_row['id']] = {
                'name': clean_row['name'],
                'primary_image': clean_row['primary_image']
            }
    
    # Create mapping between category names and library images
    category_name_mapping = {
        'Томати': 'помидори_banner.webp',
        'Огірки': 'огірки_banner.webp', 
        'Капуста': 'капуста_banner.webp',
        'Редис': 'редис-редька_banner.webp',
        'Перець': 'перець_banner.webp',
        'Баклажани': 'баклажан_banner.webp',
        'Цибуля': 'цибуля_banner.webp',
        'Морква': 'морква_banner.webp',
        'Буряк': 'буряк_banner.webp',
        'Кавуни': 'кавуни_banner.webp',
        'Дині': 'диня_banner.webp',
        'Гарбузи': 'гарбуз_banner.webp',
        'Кабачки': 'кабачки_banner.webp',
        'Патисони': 'патисони_banner.webp',
        'Зелені культури': 'салат_banner.webp',
        'Пряносмакові культури': 'зелень-прянощі_banner.webp',
        'Газонні трави': 'трава-газонна_banner.webp',
        'Бобові культури': 'горох_banner.webp',
        'Квасоля': 'квасоля_banner.webp',
        'Кукурудза': 'кукурудза_banner.webp',
        'Квіти': 'квіти_banner.webp',
        'Бобові': 'горох_banner.webp'
    }
    
    # Map category IDs to library images
    mapping = {}
    for cat_id, cat_data in categories.items():
        cat_name = cat_data['name']
        
        # Find matching library image
        library_image = None
        for key, value in category_name_mapping.items():
            if key in cat_name or cat_name in key:
                library_image = value
                break
        
        if library_image:
            mapping[cat_id] = {
                'name': cat_name,
                'current_image': cat_data['primary_image'],
                'library_image': library_image
            }
    
    return mapping

def replace_category_images():
    """Replace category images with library images"""
    
    print("Creating category mapping...")
    mapping = create_category_mapping()
    
    print(f"Found {len(mapping)} categories to process")
    
    # Source and destination directories
    library_dir = Path('/workspace/data/imageLibrary/categories')
    categories_dir = Path('/workspace/data/images/categories')
    
    # Process each category
    replaced_count = 0
    for cat_id, cat_data in mapping.items():
        current_image = cat_data['current_image']
        library_image = cat_data['library_image']
        
        # Check if current image exists
        current_path = categories_dir / current_image
        if not current_path.exists():
            print(f"⚠️  Current image not found: {current_image}")
            continue
        
        # Check if library image exists
        library_path = library_dir / library_image
        if not library_path.exists():
            print(f"⚠️  Library image not found: {library_image}")
            continue
        
        try:
            # Create backup of current image
            backup_path = categories_dir / f"{current_image}.backup"
            shutil.copy2(current_path, backup_path)
            
            # Replace with library image
            shutil.copy2(library_path, current_path)
            
            print(f"✅ Replaced {cat_id} ({cat_data['name']}): {current_image} -> {library_image}")
            replaced_count += 1
            
        except Exception as e:
            print(f"❌ Error replacing {cat_id}: {e}")
    
    print(f"\n=== Replacement Complete ===")
    print(f"Successfully replaced {replaced_count} category images")
    print(f"Backups created with .backup extension")

def main():
    """Main function"""
    print("Starting category image replacement...")
    replace_category_images()

if __name__ == "__main__":
    main()