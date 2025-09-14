#!/usr/bin/env python3
"""
Florapress Image Scraper
Scrapes product images from Florapress tomato pages (page 1-20)
"""

import os
import requests
import time
import re
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class FlorapressScraper:
    def __init__(self, base_url="https://florapress.com.ua/shop/pomidori/", save_dir="/workspace/data/imageLibrary/pomidori"):
        self.base_url = base_url
        self.save_dir = save_dir
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        self.downloaded_images = set()
        self.failed_downloads = []
        
        # Create save directory
        os.makedirs(save_dir, exist_ok=True)
        
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
    
    def extract_product_images(self, html_content, page_url):
        """Extract product image URLs from page HTML"""
        soup = BeautifulSoup(html_content, 'html.parser')
        image_urls = []
        
        # Look for product images in various common selectors
        selectors = [
            'img[src*="product"]',
            'img[src*="pomidori"]', 
            'img[src*="tomato"]',
            '.product img',
            '.woocommerce-loop-product__link img',
            '.product-item img',
            '.product-image img',
            'img[alt*="помидор"]',
            'img[alt*="томат"]',
            'img[alt*="pomidori"]'
        ]
        
        for selector in selectors:
            images = soup.select(selector)
            for img in images:
                src = img.get('src') or img.get('data-src') or img.get('data-lazy-src')
                if src:
                    # Convert relative URLs to absolute
                    full_url = urljoin(page_url, src)
                    # Filter for likely product images
                    if self.is_product_image(full_url):
                        image_urls.append(full_url)
        
        # Also look for images in background-image CSS
        elements_with_bg = soup.find_all(style=re.compile(r'background-image'))
        for element in elements_with_bg:
            bg_match = re.search(r'url\(["\']?([^"\']+)["\']?\)', element.get('style', ''))
            if bg_match:
                full_url = urljoin(page_url, bg_match.group(1))
                if self.is_product_image(full_url):
                    image_urls.append(full_url)
        
        return list(set(image_urls))  # Remove duplicates
    
    def is_product_image(self, url):
        """Check if URL looks like a product image"""
        url_lower = url.lower()
        
        # Skip common non-product images
        skip_patterns = [
            'logo', 'banner', 'icon', 'avatar', 'placeholder',
            'loading', 'spinner', 'arrow', 'button', 'social',
            'facebook', 'twitter', 'instagram', 'youtube',
            'header', 'footer', 'nav', 'menu'
        ]
        
        for pattern in skip_patterns:
            if pattern in url_lower:
                return False
        
        # Look for product-related patterns
        product_patterns = [
            'product', 'pomidori', 'tomato', 'товар', 'помидор',
            'shop', 'catalog', 'item'
        ]
        
        for pattern in product_patterns:
            if pattern in url_lower:
                return True
        
        # Check file extension
        if any(url_lower.endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp']):
            return True
            
        return False
    
    def download_image(self, image_url, filename):
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
            
            filepath = os.path.join(self.save_dir, filename)
            
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
    
    def scrape_page(self, page_num):
        """Scrape a single page"""
        if page_num == 1:
            url = self.base_url
        else:
            url = f"{self.base_url}page-{page_num}/"
        
        logger.info(f"Scraping page {page_num}: {url}")
        
        html_content = self.get_page_content(url)
        if not html_content:
            return []
        
        image_urls = self.extract_product_images(html_content, url)
        logger.info(f"Found {len(image_urls)} product images on page {page_num}")
        
        downloaded_count = 0
        for i, image_url in enumerate(image_urls):
            # Create unique filename
            filename = f"page{page_num:02d}_img{i+1:03d}"
            if self.download_image(image_url, filename):
                downloaded_count += 1
                self.downloaded_images.add(image_url)
            
            # Be respectful - small delay between downloads
            time.sleep(0.5)
        
        logger.info(f"Downloaded {downloaded_count} images from page {page_num}")
        return image_urls
    
    def scrape_all_pages(self, start_page=1, end_page=20):
        """Scrape all pages from start_page to end_page"""
        logger.info(f"Starting scrape from page {start_page} to {end_page}")
        
        total_images = 0
        for page_num in range(start_page, end_page + 1):
            try:
                image_urls = self.scrape_page(page_num)
                total_images += len(image_urls)
                
                # Be respectful - delay between pages
                time.sleep(2)
                
            except Exception as e:
                logger.error(f"Error scraping page {page_num}: {e}")
                continue
        
        logger.info(f"Scraping completed!")
        logger.info(f"Total images found: {total_images}")
        logger.info(f"Total images downloaded: {len(self.downloaded_images)}")
        logger.info(f"Failed downloads: {len(self.failed_downloads)}")
        
        if self.failed_downloads:
            logger.info("Failed download URLs:")
            for url in self.failed_downloads:
                logger.info(f"  - {url}")
        
        return total_images, len(self.downloaded_images)

def main():
    scraper = FlorapressScraper()
    
    # Test with first few pages first
    logger.info("Testing with pages 1-3 first...")
    scraper.scrape_all_pages(1, 3)
    
    # Check results
    downloaded_files = os.listdir(scraper.save_dir)
    logger.info(f"Files in {scraper.save_dir}: {len(downloaded_files)}")
    
    if len(downloaded_files) > 0:
        logger.info("Test successful! Proceeding with full scrape...")
        scraper.scrape_all_pages(1, 20)
    else:
        logger.warning("No images downloaded in test. Check the website structure.")

if __name__ == "__main__":
    main()