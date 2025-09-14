#!/usr/bin/env python3
"""
Script to scrape actual category banner images from Florapress website
Focus on finding the category header/banner images like буряк-jpg.webp
"""

import os
import requests
from bs4 import BeautifulSoup
import time
import re
from urllib.parse import urljoin, urlparse
import json

def create_directories():
    """Create necessary directories"""
    categories_dir = "/workspace/data/imageLibrary/categories"
    os.makedirs(categories_dir, exist_ok=True)
    return categories_dir

def get_page_content(url, max_retries=3):
    """Get page content with retry logic"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'uk-UA,uk;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
    }
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            return response
        except Exception as e:
            print(f"Attempt {attempt + 1} failed for {url}: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                print(f"Failed to fetch {url} after {max_retries} attempts")
                return None

def extract_category_links(base_url):
    """Extract category links from the main page"""
    print(f"Fetching main page: {base_url}")
    response = get_page_content(base_url)
    if not response:
        return []
    
    soup = BeautifulSoup(response.text, 'html.parser')
    categories = []
    
    # Look for category links in various selectors
    selectors = [
        'a[href*="/shop/"]',
        '.category-link',
        '.menu-item a',
        'nav a',
        '.categories a',
        '.product-categories a',
        '[class*="category"] a',
        '[class*="menu"] a'
    ]
    
    for selector in selectors:
        links = soup.select(selector)
        for link in links:
            href = link.get('href')
            if href and '/shop/' in href and href != '/shop/':
                full_url = urljoin(base_url, href)
                text = link.get_text(strip=True)
                if text and len(text) > 2:  # Filter out very short text
                    categories.append({
                        'url': full_url,
                        'name': text,
                        'slug': href.split('/')[-1] if href.split('/')[-1] else href.split('/')[-2]
                    })
    
    # Remove duplicates
    seen_urls = set()
    unique_categories = []
    for cat in categories:
        if cat['url'] not in seen_urls:
            seen_urls.add(cat['url'])
            unique_categories.append(cat)
    
    print(f"Found {len(unique_categories)} unique categories")
    return unique_categories

def find_category_banner_image(category_url, category_name, categories_dir):
    """Find the actual category banner image"""
    print(f"Processing category: {category_name} - {category_url}")
    
    response = get_page_content(category_url)
    if not response:
        return None
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Look for category banner images in specific patterns
    # Based on the example: https://florapress.com.ua/WebCache/Media/shop-12127/_assets/буряк-jpg.webp
    
    # 1. Look for WebCache images that might be category banners
    webcache_images = soup.find_all('img', src=re.compile(r'WebCache.*\.webp'))
    for img in webcache_images:
        src = img.get('src')
        if src and 'WebCache' in src and '.webp' in src:
            # Check if it might be a category banner based on filename
            filename = os.path.basename(urlparse(src).path)
            if any(keyword in filename.lower() for keyword in ['banner', 'header', 'category', 'hero']):
                return urljoin(category_url, src)
    
    # 2. Look for images with category name in the filename
    category_name_lower = category_name.lower()
    all_images = soup.find_all('img')
    for img in all_images:
        src = img.get('src') or img.get('data-src') or img.get('data-lazy')
        if src:
            full_url = urljoin(category_url, src)
            filename = os.path.basename(urlparse(full_url).path).lower()
            # Check if category name appears in filename
            if any(word in filename for word in category_name_lower.split()):
                return full_url
    
    # 3. Look for large images that might be category banners
    # Check for images with specific dimensions or styles
    for img in all_images:
        src = img.get('src') or img.get('data-src') or img.get('data-lazy')
        if src:
            full_url = urljoin(category_url, src)
            # Check if it's a WebP image (often used for banners)
            if '.webp' in full_url.lower():
                # Check if it's likely a banner based on URL structure
                if any(keyword in full_url.lower() for keyword in ['banner', 'header', 'category', 'hero', 'webcache']):
                    return full_url
    
    # 4. Look for background images in CSS
    style_tags = soup.find_all('style')
    for style in style_tags:
        if style.string:
            # Look for background-image URLs
            bg_matches = re.findall(r'background-image:\s*url\(["\']?([^"\']+)["\']?\)', style.string)
            for match in bg_matches:
                full_url = urljoin(category_url, match)
                if '.webp' in full_url.lower() and 'WebCache' in full_url:
                    return full_url
    
    # 5. Try to construct the expected banner URL based on the pattern
    # Pattern: https://florapress.com.ua/WebCache/Media/shop-12127/_assets/{category-name}-jpg.webp
    category_slug = category_name.lower().replace(' ', '-').replace(',', '').replace('ё', 'е')
    category_slug = re.sub(r'[^\w\-]', '', category_slug)
    
    # Try different variations of the category name
    variations = [
        category_slug,
        category_name.lower().replace(' ', ''),
        category_name.lower().replace(' ', '-'),
        category_name.lower().replace('ё', 'е'),
    ]
    
    for variation in variations:
        if variation:
            # Try the WebCache pattern
            webcache_url = f"https://florapress.com.ua/WebCache/Media/shop-12127/_assets/{variation}-jpg.webp"
            try:
                test_response = requests.head(webcache_url, timeout=10)
                if test_response.status_code == 200:
                    print(f"Found category banner via pattern: {webcache_url}")
                    return webcache_url
            except:
                pass
    
    print(f"No category banner image found for {category_name}")
    return None

def download_image(image_url, filename, categories_dir):
    """Download an image and save it"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Referer': 'https://florapress.com.ua/'
        }
        
        response = requests.get(image_url, headers=headers, timeout=30)
        response.raise_for_status()
        
        filepath = os.path.join(categories_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(response.content)
        
        print(f"Downloaded: {filename}")
        return True
    except Exception as e:
        print(f"Failed to download {image_url}: {e}")
        return False

def main():
    """Main function to scrape category banner images"""
    base_url = "https://florapress.com.ua"
    categories_dir = create_directories()
    
    print("Starting category banner image scraping...")
    
    # Extract category links
    categories = extract_category_links(base_url)
    
    if not categories:
        print("No categories found!")
        return
    
    # Process each category
    total_images = 0
    successful_categories = 0
    
    for i, category in enumerate(categories, 1):
        print(f"\n--- Processing {i}/{len(categories)}: {category['name']} ---")
        
        # Find category banner image
        banner_url = find_category_banner_image(category['url'], category['name'], categories_dir)
        
        if not banner_url:
            print(f"No category banner image found for {category['name']}")
            continue
        
        # Download the banner image
        category_slug = category['slug']
        category_slug = re.sub(r'[^\w\-_]', '_', category_slug)  # Clean slug
        
        # Generate filename
        parsed_url = urlparse(banner_url)
        original_filename = os.path.basename(parsed_url.path)
        if not original_filename or '.' not in original_filename:
            original_filename = f"{category_slug}_banner.webp"
        
        # Clean filename
        filename = re.sub(r'[^\w\-_\.]', '_', original_filename)
        if not filename.endswith(('.jpg', '.jpeg', '.png', '.webp')):
            filename += '.webp'
        
        if download_image(banner_url, filename, categories_dir):
            total_images += 1
            successful_categories += 1
            print(f"Downloaded category banner for {category['name']}")
        
        # Delay between categories
        time.sleep(1)
    
    print(f"\n=== Scraping Complete ===")
    print(f"Processed {len(categories)} categories")
    print(f"Successfully scraped {successful_categories} categories")
    print(f"Total category banner images downloaded: {total_images}")
    print(f"Images saved to: {categories_dir}")

if __name__ == "__main__":
    main()