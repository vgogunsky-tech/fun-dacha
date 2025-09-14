#!/usr/bin/env python3
"""
Script to scrape category banner images from Florapress website
and save them to data/imageLibrary/categories
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

def extract_category_banner_images(category_url, category_name, categories_dir):
    """Extract category banner/header images from a category page"""
    print(f"Processing category: {category_name} - {category_url}")
    
    response = get_page_content(category_url)
    if not response:
        return []
    
    soup = BeautifulSoup(response.text, 'html.parser')
    images = []
    
    # Look for category banner/header images specifically
    # These are typically larger images at the top of category pages
    selectors = [
        # Category headers and banners
        '.category-header img',
        '.category-banner img',
        '.hero-image img',
        '.page-header img',
        '.category-title img',
        '.category-image img',
        '.banner img',
        '.header img',
        '.main-image img',
        '.category-hero img',
        '.page-title img',
        # Look for images in the main content area that might be category banners
        '.main-content img:first-of-type',
        '.content img:first-of-type',
        '.category-content img:first-of-type',
        # Look for large images that might be category banners
        'img[style*="width: 100%"]',
        'img[style*="width:100%"]',
        'img[style*="height: 200px"]',
        'img[style*="height: 300px"]',
        'img[style*="height: 400px"]',
        # Look for images with category-related alt text
        'img[alt*="категорі"]',
        'img[alt*="category"]',
        'img[alt*="' + category_name.lower() + '"]',
        # Look for WebP images which are often used for banners
        'img[src*=".webp"]',
        'img[src*="WebCache"]',
        'img[src*="banner"]',
        'img[src*="header"]',
        'img[src*="category"]',
        'img[src*="hero"]'
    ]
    
    for selector in selectors:
        imgs = soup.select(selector)
        for img in imgs:
            src = img.get('src') or img.get('data-src') or img.get('data-lazy')
            if src:
                full_url = urljoin(category_url, src)
                alt_text = img.get('alt', '')
                
                # Filter for likely category banner images
                if any(keyword in full_url.lower() for keyword in ['banner', 'header', 'category', 'hero', 'webcache']):
                    images.append({
                        'url': full_url,
                        'alt': alt_text,
                        'category': category_name
                    })
                # Also include images that are likely category banners based on size or position
                elif any(keyword in alt_text.lower() for keyword in ['категорі', 'category', category_name.lower()]):
                    images.append({
                        'url': full_url,
                        'alt': alt_text,
                        'category': category_name
                    })
    
    # Also look for background images in CSS that might be category banners
    style_tags = soup.find_all('style')
    for style in style_tags:
        if style.string:
            # Look for background-image URLs
            bg_matches = re.findall(r'background-image:\s*url\(["\']?([^"\']+)["\']?\)', style.string)
            for match in bg_matches:
                full_url = urljoin(category_url, match)
                if any(keyword in full_url.lower() for keyword in ['banner', 'header', 'category', 'hero', 'webcache']):
                    images.append({
                        'url': full_url,
                        'alt': f'Background image for {category_name}',
                        'category': category_name
                    })
    
    # Remove duplicates
    seen_urls = set()
    unique_images = []
    for img in images:
        if img['url'] not in seen_urls and any(ext in img['url'].lower() for ext in ['.jpg', '.jpeg', '.png', '.webp']):
            seen_urls.add(img['url'])
            unique_images.append(img)
    
    print(f"Found {len(unique_images)} potential category banner images for {category_name}")
    return unique_images

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
        
        # Extract category banner images
        images = extract_category_banner_images(category['url'], category['name'], categories_dir)
        
        if not images:
            print(f"No category banner images found for {category['name']}")
            continue
        
        # Download images
        category_slug = category['slug']
        category_slug = re.sub(r'[^\w\-_]', '_', category_slug)  # Clean slug
        
        downloaded_count = 0
        for j, img in enumerate(images, 1):
            # Generate filename
            parsed_url = urlparse(img['url'])
            original_filename = os.path.basename(parsed_url.path)
            if not original_filename or '.' not in original_filename:
                original_filename = f"banner_{j}.webp"
            
            # Clean filename
            filename = re.sub(r'[^\w\-_\.]', '_', original_filename)
            if not filename.endswith(('.jpg', '.jpeg', '.png', '.webp')):
                filename += '.webp'
            
            # Add category prefix to avoid conflicts
            filename = f"{category_slug}_{filename}"
            
            if download_image(img['url'], filename, categories_dir):
                downloaded_count += 1
                total_images += 1
            
            # Small delay to be respectful
            time.sleep(0.5)
        
        if downloaded_count > 0:
            successful_categories += 1
            print(f"Downloaded {downloaded_count} category banner images for {category['name']}")
        
        # Delay between categories
        time.sleep(1)
    
    print(f"\n=== Scraping Complete ===")
    print(f"Processed {len(categories)} categories")
    print(f"Successfully scraped {successful_categories} categories")
    print(f"Total category banner images downloaded: {total_images}")
    print(f"Images saved to: {categories_dir}")

if __name__ == "__main__":
    main()