#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Telegram Chat History Product Extractor
Processes telegram chat history to extract seed product information
and creates CSV tables for database import.
"""

import re
import csv
import os
import html
import shutil

class ProductExtractor:
    def __init__(self, messages_file, photos_dir, categories_dir):
        self.messages_file = messages_file
        self.photos_dir = photos_dir
        self.categories_dir = categories_dir
        self.products = []
        self.categories = {}
        self.category_mapping = {}
        
        # Define category mappings based on photo-categories directory
        self.setup_categories()
        
    def setup_categories(self):
        """Setup category mappings based on available category photos"""
        category_files = os.listdir(self.categories_dir)
        
        # Map category names to IDs and photos
        category_id = 1
        for filename in category_files:
            if filename.endswith('.jpg'):
                # Extract category name from filename
                category_name = filename.replace('.jpg', '').strip()
                
                # Clean up category name
                category_name = re.sub(r'[^\w\s-]', '', category_name)
                category_name = category_name.strip()
                
                if category_name:
                    self.categories[category_id] = {
                        'id': category_id,
                        'name': category_name,
                        'photo': filename
                    }
                    category_id += 1
        
        # Create reverse mapping for product categorization
        self.category_mapping = {
            'томат': 1,  # томаты
            'огур': 2,   # огурцы
            'перец': 3,  # перец
            'капуст': 4, # капуста
            'редис': 5,  # редис
            'свекл': 6,  # свекла
            'тыкв': 7,   # тыквы
            'фасол': 8,  # фасоль
            'цвет': 9,   # цветы
            'лук': 10,   # лук
            'морков': 11, # морковь
            'кабач': 12, # кабачки
            'кукуруз': 13, # кукуруза
            'арбуз': 14, # арбузы
            'баклажан': 15, # баклажан
            'дын': 16,   # дыни
            'земляник': 17, # земляника
            'лекарствен': 18, # лекарственные растения
            'пряно': 19, # пряно-вкусовые культуры
            'газон': 20, # газонные травы
            'многолет': 21, # многолетники
            'однолет': 22, # однолетники
            'лукович': 23, # луковичные
            'патиссон': 24, # патиссон
        }
    
    def extract_products(self):
        """Extract product information from HTML messages"""
        with open(self.messages_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Simple HTML parsing using regex
        # Find all message divs with class "message default clearfix"
        message_pattern = r'<div class="message default clearfix"[^>]*>.*?<div class="text">(.*?)</div>'
        messages = re.findall(message_pattern, content, re.DOTALL)
        
        product_id = 1
        
        for message_html in messages:
            # Clean HTML tags and decode HTML entities
            text = re.sub(r'<[^>]+>', '', message_html)
            text = html.unescape(text)
            text = text.strip()
            
            # Look for product patterns (numbered items)
            product_match = re.search(r'^(\d+)\.\s*([А-Я][^.]*?)(?:\.|$)', text, re.MULTILINE)
            
            if product_match:
                product_number = int(product_match.group(1))
                product_name = product_match.group(2).strip()
                
                # Extract full description
                description = text.strip()
                
                # Create short description (first sentence)
                short_desc_match = re.search(r'^[^.]*\.', description)
                short_description = short_desc_match.group(0) if short_desc_match else description[:100] + "..."
                
                # Determine category based on product name and description
                category_id = self.determine_category(product_name, description)
                
                # Extract weight information
                weight = self.extract_weight(description)
                
                # Extract price (if available)
                price = self.extract_price(description)
                
                # Determine subcategory
                subcategory = self.determine_subcategory(product_name, description)
                
                # Create product entry
                product = {
                    'id': f"{category_id:02d}{product_number:03d}",
                    'number': product_number,
                    'title': product_name,
                    'short_description': short_description,
                    'long_description': description,
                    'category_id': category_id,
                    'subcategory': subcategory,
                    'weight': weight,
                    'price': price,
                    'image': f"p_{category_id:02d}{product_number:03d}_1.jpg"
                }
                
                self.products.append(product)
                product_id += 1
    
    def determine_category(self, product_name, description):
        """Determine product category based on name and description"""
        text = (product_name + " " + description).lower()
        
        for keyword, cat_id in self.category_mapping.items():
            if keyword in text:
                return cat_id
        
        # Default to first category if no match found
        return 1
    
    def determine_subcategory(self, product_name, description):
        """Determine product subcategory"""
        text = (product_name + " " + description).lower()
        
        subcategories = {
            'гибрид': 'Гибрид',
            'f1': 'Гибрид F1',
            'раннеспел': 'Раннеспелый',
            'среднеспел': 'Среднеспелый',
            'позднеспел': 'Позднеспелый',
            'ультраскороспел': 'Ультраскороспелый',
            'скороспел': 'Скороспелый',
            'салатн': 'Салатный',
            'засолочн': 'Засолочный',
            'консервн': 'Консервный',
            'универсал': 'Универсальный'
        }
        
        for keyword, subcat in subcategories.items():
            if keyword in text:
                return subcat
        
        return ''
    
    def extract_weight(self, description):
        """Extract weight information from description"""
        # Look for weight patterns
        weight_patterns = [
            r'массой\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
            r'весом\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
            r'масса\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
            r'(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
        ]
        
        for pattern in weight_patterns:
            match = re.search(pattern, description, re.IGNORECASE)
            if match:
                weight = match.group(1)
                # Convert to grams if in kg
                if 'кг' in description.lower():
                    try:
                        if '-' in weight:
                            parts = weight.split('-')
                            weight = f"{float(parts[0])*1000:.0f}-{float(parts[1])*1000:.0f}"
                        else:
                            weight = f"{float(weight)*1000:.0f}"
                    except:
                        pass
                return weight
        
        return ''
    
    def extract_price(self, description):
        """Extract price information from description"""
        # Look for price patterns (not found in current data)
        price_patterns = [
            r'(\d+)\s*(?:грн|₴|руб)',
            r'цена\s*(\d+)',
            r'стоимость\s*(\d+)'
        ]
        
        for pattern in price_patterns:
            match = re.search(pattern, description, re.IGNORECASE)
            if match:
                return match.group(1)
        
        return ''
    
    def process_photos(self):
        """Process and rename product photos"""
        if not os.path.exists(self.photos_dir):
            print(f"Photos directory {self.photos_dir} not found")
            return
        
        # Create processed photos directory
        processed_dir = "processed_photos"
        os.makedirs(processed_dir, exist_ok=True)
        
        # Get list of photo files
        photo_files = [f for f in os.listdir(self.photos_dir) if f.endswith('.jpg')]
        photo_files.sort()
        
        # Map photos to products (simple sequential mapping)
        for i, product in enumerate(self.products):
            if i < len(photo_files):
                source_photo = os.path.join(self.photos_dir, photo_files[i])
                target_photo = os.path.join(processed_dir, product['image'])
                
                try:
                    shutil.copy2(source_photo, target_photo)
                    print(f"Copied {source_photo} to {target_photo}")
                except Exception as e:
                    print(f"Error copying {source_photo}: {e}")
    
    def create_csv_files(self):
        """Create CSV files for products and categories"""
        # Create products CSV
        with open('products.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'number', 'title', 'short_description', 'long_description', 
                         'category_id', 'subcategory', 'weight', 'price', 'image']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for product in self.products:
                writer.writerow(product)
        
        # Create categories CSV
        with open('categories.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'name', 'photo']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for category in self.categories.values():
                writer.writerow(category)
        
        print(f"Created products.csv with {len(self.products)} products")
        print(f"Created categories.csv with {len(self.categories)} categories")
    
    def run(self):
        """Run the complete extraction process"""
        print("Starting product extraction...")
        
        # Extract products from messages
        self.extract_products()
        print(f"Extracted {len(self.products)} products")
        
        # Process photos
        self.process_photos()
        
        # Create CSV files
        self.create_csv_files()
        
        # Print summary
        print("\nExtraction Summary:")
        print(f"Total products: {len(self.products)}")
        print(f"Total categories: {len(self.categories)}")
        
        # Print first few products as example
        print("\nSample products:")
        for product in self.products[:5]:
            print(f"  {product['id']}: {product['title']} (Category: {product['category_id']})")

def main():
    extractor = ProductExtractor(
        messages_file='SourceData/messages.html',
        photos_dir='SourceData/photos',
        categories_dir='photo-categories'
    )
    
    extractor.run()

if __name__ == "__main__":
    main()