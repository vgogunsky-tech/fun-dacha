#!/usr/bin/env python3
"""
Universal Florapress Image Scraper
Scrapes product images from any Florapress category with automatic page detection
"""

import os
import requests
import time
import re
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
import logging
import argparse
import sys

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class UniversalFlorapressScraper:
    def __init__(self, base_url="https://florapress.com.ua", save_base_dir="/workspace/data/imageLibrary"):
        self.base_url = base_url
        self.save_base_dir = save_base_dir
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.downloaded_images = set()
        self.failed_downloads = []
        
    def get_page_content(self, url, max_retries=3):
        """Fetch page content with retries"""
        for attempt in range(max_retries):
            try:
                logger.info(f"Fetching: {url} (attempt {attempt + 1})")
                response = self.session.get(url, timeout=30)
                response.raise_for_status()
                return response.text
            except requests.RequestException as e:
                logger.warning(f"Attempt {attempt + 1} failed for {url}: {e}")
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    logger.error(f"Failed to fetch {url} after {max_retries} attempts")
                    return None
    
    def detect_max_pages(self, category):
        """Detect the maximum number of pages for a category"""
        # Try to find pagination info
        page_url = f"{self.base_url}/shop/{category}/"
        html_content = self.get_page_content(page_url)
        if not html_content:
            return 1
        
        soup = BeautifulSoup(html_content, 'html.parser')
        
        # Look for pagination elements
        max_page = 1
        
        # Method 1: Look for "page X of Y" or similar patterns
        pagination_text = soup.get_text()
        page_patterns = [
            r'page\s+\d+\s+of\s+(\d+)',
            r'сторінка\s+\d+\s+з\s+(\d+)',
            r'(\d+)\s+сторінк',
            r'(\d+)\s+pages?'
        ]
        
        for pattern in page_patterns:
            matches = re.findall(pattern, pagination_text, re.IGNORECASE)
            if matches:
                max_page = max(max_page, int(matches[-1]))
        
        # Method 2: Look for pagination links
        pagination_selectors = [
            '.pagination a',
            '.page-numbers a',
            '.pager a',
            'nav a[href*="page-"]',
            'a[href*="page-"]'
        ]
        
        for selector in pagination_selectors:
            links = soup.select(selector)
            for link in links:
                href = link.get('href', '')
                page_match = re.search(r'page-(\d+)', href)
                if page_match:
                    page_num = int(page_match.group(1))
                    max_page = max(max_page, page_num)
        
        # Method 3: Try to find the last page by checking if page numbers exist
        # Start from a reasonable number and work backwards
        for test_page in range(50, 0, -1):
            test_url = f"{self.base_url}/shop/{category}/page-{test_page}/"
            test_content = self.get_page_content(test_url)
            if test_content and "404" not in test_content.lower() and "not found" not in test_content.lower():
                # Check if the page has products
                test_soup = BeautifulSoup(test_content, 'html.parser')
                if self.has_products(test_soup):
                    max_page = max(max_page, test_page)
                    break
        
        logger.info(f"Detected maximum pages for {category}: {max_page}")
        return max_page
    
    def has_products(self, soup):
        """Check if a page has products"""
        # Look for product indicators
        product_selectors = [
            '.product',
            '.woocommerce-loop-product',
            '.product-item',
            'img[src*="product"]',
            'img[src*="shop"]',
            '.product-image',
            '.product-title'
        ]
        
        for selector in product_selectors:
            if soup.select(selector):
                return True
        return False
    
    def extract_product_images(self, html_content, page_url, category):
        """Extract product image URLs from page HTML"""
        soup = BeautifulSoup(html_content, 'html.parser')
        image_urls = []
        
        # Look for product images in various common selectors
        selectors = [
            'img[src*="product"]',
            'img[src*="shop"]',
            'img[src*="' + category + '"]',
            '.product img',
            '.woocommerce-loop-product__link img',
            '.product-item img',
            '.product-image img',
            'img[alt*="' + category + '"]',
            'img[alt*="товар"]',
            'img[alt*="продукт"]'
        ]
        
        for selector in selectors:
            images = soup.select(selector)
            for img in images:
                src = img.get('src') or img.get('data-src') or img.get('data-lazy-src')
                if src:
                    # Convert relative URLs to absolute
                    full_url = urljoin(page_url, src)
                    # Filter for likely product images
                    if self.is_product_image(full_url, category):
                        image_urls.append(full_url)
        
        # Also look for images in background-image CSS
        elements_with_bg = soup.find_all(style=re.compile(r'background-image'))
        for element in elements_with_bg:
            bg_match = re.search(r'url\(["\']?([^"\']+)["\']?\)', element.get('style', ''))
            if bg_match:
                full_url = urljoin(page_url, bg_match.group(1))
                if self.is_product_image(full_url, category):
                    image_urls.append(full_url)
        
        return list(set(image_urls))  # Remove duplicates
    
    def is_product_image(self, url, category):
        """Check if URL looks like a product image for the given category"""
        url_lower = url.lower()
        
        # Skip common non-product images
        skip_patterns = [
            'logo', 'banner', 'icon', 'avatar', 'placeholder',
            'loading', 'spinner', 'arrow', 'button', 'social',
            'facebook', 'twitter', 'instagram', 'youtube',
            'header', 'footer', 'nav', 'menu', 'cart'
        ]
        
        for pattern in skip_patterns:
            if pattern in url_lower:
                return False
        
        # Look for product-related patterns
        product_patterns = [
            'product', 'shop', 'catalog', 'item', 'товар', 'продукт',
            category.lower()  # Category-specific
        ]
        
        for pattern in product_patterns:
            if pattern in url_lower:
                return True
        
        # Check file extension
        if any(url_lower.endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp']):
            return True
            
        return False
    
    def download_image(self, image_url, filename, category):
        """Download a single image"""
        try:
            logger.info(f"Downloading: {image_url}")
            response = self.session.get(image_url, timeout=30, stream=True)
            response.raise_for_status()
            
            # Ensure filename has proper extension
            if not any(filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp']):
                # Try to get extension from URL
                parsed_url = urlparse(image_url)
                path = parsed_url.path
                if '.' in path:
                    ext = '.' + path.split('.')[-1].lower()
                    if ext in ['.jpg', '.jpeg', '.png', '.webp']:
                        filename += ext
                    else:
                        filename += '.jpg'  # Default to jpg
                else:
                    filename += '.jpg'
            
            # Create category directory
            category_dir = os.path.join(self.save_base_dir, category)
            os.makedirs(category_dir, exist_ok=True)
            
            filepath = os.path.join(category_dir, filename)
            
            # Skip if already downloaded
            if os.path.exists(filepath):
                logger.info(f"Skipping existing file: {filename}")
                return True
            
            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            logger.info(f"Downloaded: {filename}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to download {image_url}: {e}")
            self.failed_downloads.append(image_url)
            return False
    
    def scrape_category(self, category, max_pages=None):
        """Scrape all pages for a specific category"""
        logger.info(f"Starting scrape for category: {category}")
        
        # Detect max pages if not provided
        if max_pages is None:
            max_pages = self.detect_max_pages(category)
        
        total_images = 0
        downloaded_count = 0
        
        for page_num in range(1, max_pages + 1):
            if page_num == 1:
                url = f"{self.base_url}/shop/{category}/"
            else:
                url = f"{self.base_url}/shop/{category}/page-{page_num}/"
            
            logger.info(f"Scraping page {page_num}: {url}")
            
            html_content = self.get_page_content(url)
            if not html_content:
                logger.warning(f"Failed to fetch page {page_num}, stopping")
                break
            
            # Check if page has products
            soup = BeautifulSoup(html_content, 'html.parser')
            if not self.has_products(soup):
                logger.info(f"No products found on page {page_num}, stopping")
                break
            
            image_urls = self.extract_product_images(html_content, url, category)
            logger.info(f"Found {len(image_urls)} product images on page {page_num}")
            
            for i, image_url in enumerate(image_urls):
                # Create unique filename
                filename = f"page{page_num:02d}_img{i+1:03d}"
                if self.download_image(image_url, filename, category):
                    downloaded_count += 1
                    self.downloaded_images.add(image_url)
                
                # Be respectful - small delay between downloads
                time.sleep(0.5)
            
            total_images += len(image_urls)
            
            # Be respectful - delay between pages
            time.sleep(2)
        
        logger.info(f"Scraping completed for {category}!")
        logger.info(f"Total images found: {total_images}")
        logger.info(f"Total images downloaded: {downloaded_count}")
        logger.info(f"Failed downloads: {len(self.failed_downloads)}")
        
        return total_images, downloaded_count
    
    def scrape_all_categories(self, categories):
        """Scrape multiple categories"""
        results = {}
        
        for category in categories:
            logger.info(f"Starting scrape for category: {category}")
            try:
                total, downloaded = self.scrape_category(category)
                results[category] = {
                    'total_images': total,
                    'downloaded': downloaded,
                    'failed': len(self.failed_downloads)
                }
                logger.info(f"Completed {category}: {downloaded} images downloaded")
            except Exception as e:
                logger.error(f"Error scraping {category}: {e}")
                results[category] = {
                    'total_images': 0,
                    'downloaded': 0,
                    'failed': 0,
                    'error': str(e)
                }
        
        return results

def main():
    parser = argparse.ArgumentParser(description='Universal Florapress Image Scraper')
    parser.add_argument('--category', '-c', help='Single category to scrape')
    parser.add_argument('--categories', '-l', nargs='+', help='Multiple categories to scrape')
    parser.add_argument('--all', '-a', action='store_true', help='Scrape all available categories')
    parser.add_argument('--max-pages', '-p', type=int, help='Maximum pages to scrape per category')
    parser.add_argument('--output-dir', '-o', default='/workspace/data/imageLibrary', 
                       help='Output directory for images')
    
    args = parser.parse_args()
    
    scraper = UniversalFlorapressScraper(save_base_dir=args.output_dir)
    
    if args.all:
        # Extract all categories from main page
        from category_extractor import extract_categories
        categories = extract_categories()
        if not categories:
            logger.error("Failed to extract categories from main page")
            sys.exit(1)
    elif args.categories:
        categories = args.categories
    elif args.category:
        categories = [args.category]
    else:
        logger.error("Please specify --category, --categories, or --all")
        sys.exit(1)
    
    logger.info(f"Scraping categories: {categories}")
    
    results = scraper.scrape_all_categories(categories)
    
    # Print summary
    logger.info("\n" + "="*50)
    logger.info("SCRAPING SUMMARY")
    logger.info("="*50)
    
    total_downloaded = 0
    for category, result in results.items():
        if 'error' in result:
            logger.info(f"{category}: ERROR - {result['error']}")
        else:
            logger.info(f"{category}: {result['downloaded']} images downloaded")
            total_downloaded += result['downloaded']
    
    logger.info(f"Total images downloaded across all categories: {total_downloaded}")

if __name__ == "__main__":
    main()