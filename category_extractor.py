#!/usr/bin/env python3
"""
Category Extractor for Florapress
Extracts all available product categories from the main page
"""

import requests
from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin, urlparse

def extract_categories(base_url="https://florapress.com.ua/"):
    """Extract all product categories from the main page"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(base_url, timeout=30, headers=headers)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        categories = []
        
        # Look for category links in various common selectors
        selectors = [
            'a[href*="/shop/"]',
            '.category-link',
            '.product-category',
            'nav a[href*="/shop/"]',
            '.menu a[href*="/shop/"]'
        ]
        
        for selector in selectors:
            links = soup.select(selector)
            for link in links:
                href = link.get('href')
                if href and '/shop/' in href:
                    # Extract category name from URL
                    category_match = re.search(r'/shop/([^/]+)/?', href)
                    if category_match:
                        category = category_match.group(1)
                        # Skip common non-category paths
                        if category not in ['', 'all', 'search', 'filter']:
                            categories.append(category)
        
        # Also look for category names in text content
        category_elements = soup.find_all(text=re.compile(r'[а-яё]+', re.IGNORECASE))
        for element in category_elements:
            if element.parent and element.parent.name == 'a':
                href = element.parent.get('href')
                if href and '/shop/' in href:
                    category_match = re.search(r'/shop/([^/]+)/?', href)
                    if category_match:
                        category = category_match.group(1)
                        if category not in ['', 'all', 'search', 'filter']:
                            categories.append(category)
        
        # Remove duplicates and sort
        categories = sorted(list(set(categories)))
        
        print(f"Found {len(categories)} categories:")
        for cat in categories:
            print(f"  - {cat}")
        
        return categories
        
    except Exception as e:
        print(f"Error extracting categories: {e}")
        return []

if __name__ == "__main__":
    categories = extract_categories()
    print(f"\nTotal categories found: {len(categories)}")