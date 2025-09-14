#!/usr/bin/env python3
"""
Category Mapping Creator
Creates a CSV mapping between category IDs and library folder names
"""

import csv
import os
import re

def create_category_mapping():
    """Create mapping between category IDs and library folders"""
    
    # Read the categories CSV
    categories_file = '/workspace/data/categories_list.csv'
    library_base = '/workspace/data/imageLibrary'
    
    # Get existing library folders
    library_folders = []
    if os.path.exists(library_base):
        library_folders = [d for d in os.listdir(library_base) 
                          if os.path.isdir(os.path.join(library_base, d))]
    
    print(f"Found {len(library_folders)} library folders: {library_folders}")
    
    # Read categories and create mapping
    mappings = []
    
    with open(categories_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            category_id = row['id']
            name_ukr = row['name']
            tag = row['tag']
            
            # Try to find matching library folder
            matched_folder = None
            
            # Direct tag matching
            if tag in library_folders:
                matched_folder = tag
            else:
                # Try to match by name patterns
                name_lower = name_ukr.lower()
                
                # Create mapping patterns
                patterns = {
                    'tomato': 'pomidori',
                    'cucumber': 'ogirki',
                    'cabbage': 'kapusta',
                    'radish': 'redis-redka',
                    'pepper': 'perets',
                    'eggplant': 'baklazhan',
                    'onion': 'tsibulya',
                    'carrot': 'morkva',
                    'beet': 'buryak',
                    'watermelon': 'kavun',
                    'melon': 'dinya',
                    'pumpkin': 'garbuz',
                    'marrow-squash': 'kabachok',
                    'squash': 'patis',
                    'green-crops': 'salat',
                    'spicy-crops': 'zelen-pryanoschi',
                    'lawn-grass': 'trava-gazonna',
                    'bean-crops': 'goroh',
                    'beans': 'kvaso',
                    'corn': 'kukurudza',
                    'flowers': 'kviti',
                    'annual-flowes': 'kviti-aystra',
                    'perennial-flowers': 'kviti',
                    'bobovi': 'goroh'
                }
                
                # Check patterns
                for pattern, folder in patterns.items():
                    if pattern in tag.lower() or pattern in name_lower:
                        if folder in library_folders:
                            matched_folder = folder
                            break
                
                # Additional specific mappings
                if not matched_folder:
                    specific_mappings = {
                        'Томати': 'pomidori',
                        'Огірки': 'ogirki',
                        'Капуста': 'kapusta',
                        'Редис': 'redis-redka',
                        'Перець': 'perets',
                        'Баклажани': 'baklazhan',
                        'Цибуля': 'tsibulya',
                        'Морква': 'morkva',
                        'Буряк': 'buryak',
                        'Кавуни': 'kavun',
                        'Дині': 'dinya',
                        'Гарбузи': 'garbuz',
                        'Кабачки': 'kabachok',
                        'Патисони': 'patis',
                        'Зелені культури': 'salat',
                        'Пряносмакові культури': 'zelen-pryanoschi',
                        'Газонні трави': 'trava-gazonna',
                        'Бобові культури': 'goroh',
                        'Кукурудза': 'kukurudza',
                        'Квіти': 'kviti',
                        'Кріп': 'krip'
                    }
                    
                    for ukr_name, folder in specific_mappings.items():
                        if ukr_name in name_ukr:
                            if folder in library_folders:
                                matched_folder = folder
                                break
            
            mappings.append({
                'category_id': category_id,
                'name_ukr': name_ukr,
                'tag': tag,
                'library_folder': matched_folder or '',
                'has_images': 'Yes' if matched_folder else 'No'
            })
    
    # Write mapping CSV
    output_file = '/workspace/category_library_mapping.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['category_id', 'name_ukr', 'tag', 'library_folder', 'has_images']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(mappings)
    
    print(f"\nMapping created: {output_file}")
    
    # Print summary
    with_images = [m for m in mappings if m['has_images'] == 'Yes']
    without_images = [m for m in mappings if m['has_images'] == 'No']
    
    print(f"\nSummary:")
    print(f"Categories with images: {len(with_images)}")
    print(f"Categories without images: {len(without_images)}")
    
    print(f"\nMappings found:")
    for mapping in with_images:
        print(f"  {mapping['category_id']} -> {mapping['library_folder']} ({mapping['name_ukr']})")
    
    if without_images:
        print(f"\nCategories without library folders:")
        for mapping in without_images:
            print(f"  {mapping['category_id']}: {mapping['name_ukr']} ({mapping['tag']})")
    
    return mappings

if __name__ == "__main__":
    create_category_mapping()