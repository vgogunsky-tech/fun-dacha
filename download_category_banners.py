#!/usr/bin/env python3
"""
Script to download category banner images directly using the known pattern
Based on: https://florapress.com.ua/WebCache/Media/shop-12127/_assets/буряк-jpg.webp
"""

import os
import requests
import time
import re
from urllib.parse import quote

def create_directories():
    """Create necessary directories"""
    categories_dir = "/workspace/data/imageLibrary/categories"
    os.makedirs(categories_dir, exist_ok=True)
    return categories_dir

def download_image(image_url, filename, categories_dir):
    """Download an image and save it"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Referer': 'https://florapress.com.ua/',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'uk-UA,uk;q=0.9,en;q=0.8',
        }
        
        print(f"Trying to download: {image_url}")
        response = requests.get(image_url, headers=headers, timeout=30)
        response.raise_for_status()
        
        filepath = os.path.join(categories_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(response.content)
        
        print(f"✓ Downloaded: {filename} ({len(response.content)} bytes)")
        return True
    except Exception as e:
        print(f"✗ Failed to download {image_url}: {e}")
        return False

def main():
    """Main function to download category banner images"""
    categories_dir = create_directories()
    
    print("Starting direct category banner image download...")
    
    # Category names and their expected URLs
    categories = [
        "буряк", "гарбуз", "горох", "диня", "капуста", "квіти", "квасоля", 
        "кріп", "кукурудза", "морква", "огірки", "патисони", "перець", 
        "петрушка", "помідори", "салат", "трава газонна", "цибуля", 
        "самоклейка", "айстри", "баклажан", "кавуни", "зелень прянощі", 
        "кабачки", "редис редька", "огірок маша", "огірок мальчик з пальчик", 
        "огірок малиш", "огірок лялюк", "огірок льоша", "огірок кущовий", 
        "огірок кріспіна", "огірок крак"
    ]
    
    base_url = "https://florapress.com.ua/WebCache/Media/shop-12127/_assets/"
    total_images = 0
    successful_categories = 0
    
    for category_name in categories:
        print(f"\n--- Processing: {category_name} ---")
        
        # Create different variations of the category name for the URL
        variations = [
            category_name,
            category_name.replace(' ', '-'),
            category_name.replace(' ', ''),
            category_name.replace('ё', 'е'),
            category_name.replace('і', 'i'),
            category_name.replace('ї', 'i'),
            category_name.replace('є', 'e'),
            category_name.replace('ю', 'u'),
            category_name.replace('я', 'a'),
            category_name.replace('ь', ''),
            category_name.replace('ъ', ''),
        ]
        
        # Remove special characters and spaces
        clean_variations = []
        for variation in variations:
            clean = re.sub(r'[^\w\-]', '', variation.lower())
            if clean and clean not in clean_variations:
                clean_variations.append(clean)
        
        # Try each variation
        downloaded = False
        for variation in clean_variations:
            if not variation:
                continue
                
            # Try different URL patterns
            url_patterns = [
                f"{base_url}{variation}-jpg.webp",
                f"{base_url}{variation}.webp",
                f"{base_url}{variation}-jpg.jpg",
                f"{base_url}{variation}.jpg",
                f"{base_url}{variation}-banner.webp",
                f"{base_url}{variation}-header.webp",
            ]
            
            for url in url_patterns:
                filename = f"{variation}_banner.webp"
                if download_image(url, filename, categories_dir):
                    total_images += 1
                    successful_categories += 1
                    downloaded = True
                    break
            
            if downloaded:
                break
        
        if not downloaded:
            print(f"No banner image found for {category_name}")
        
        # Small delay between requests
        time.sleep(0.5)
    
    print(f"\n=== Download Complete ===")
    print(f"Processed {len(categories)} categories")
    print(f"Successfully downloaded {successful_categories} categories")
    print(f"Total category banner images downloaded: {total_images}")
    print(f"Images saved to: {categories_dir}")

if __name__ == "__main__":
    main()