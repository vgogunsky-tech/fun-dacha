#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Complete Telegram Chat History Product Extractor
Processes telegram chat history to extract ALL seed product information
and creates CSV tables for database import.
"""

import re
import csv
import os
import html
import shutil

class CompleteProductExtractor:
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
            'томат': 19,  # томаты
            'огур': 33,   # огурцы
            'перец': 10,  # перец
            'капуст': 4, # капуста
            'редис': 31,  # редис
            'свекл': 13,  # свекла
            'тыкв': 3,   # тыквы
            'фасол': 29,  # фасоль
            'цвет': 21,   # цветы
            'лук': 37,   # лук
            'морков': 34, # морковь
            'кабач': 32, # кабачки
            'кукуруз': 26, # кукуруза
            'арбуз': 36, # арбузы
            'баклажан': 1, # баклажан
            'дын': 14,   # дыни
            'земляник': 17, # земляника
            'лекарствен': 15, # лекарственные растения
            'пряно': 20, # пряно-вкусовые культуры
            'газон': 12, # газонные травы
            'многолет': 5, # многолетники
            'однолет': 7, # однолетники
            'лукович': 30, # луковичные
            'патиссон': 2, # патиссон
            'салат': 8,   # салат
            'шпинат': 8,  # салат
            'щавел': 8,   # салат
            'петрушк': 20, # пряно-вкусовые культуры
            'кинз': 20,   # пряно-вкусовые культуры
            'укроп': 20,  # пряно-вкусовые культуры
            'базилик': 20, # пряно-вкусовые культуры
            'майоран': 20, # пряно-вкусовые культуры
            'тимьян': 20, # пряно-вкусовые культуры
            'розмарин': 20, # пряно-вкусовые культуры
            'орегано': 20, # пряно-вкусовые культуры
            'мята': 20,   # пряно-вкусовые культуры
            'мелисса': 20, # пряно-вкусовые культуры
            'лаванда': 20, # пряно-вкусовые культуры
            'шалфей': 20, # пряно-вкусовые культуры
            'ромашка': 15, # лекарственные растения
            'календула': 15, # лекарственные растения
            'эхинацея': 15, # лекарственные растения
            'зверобой': 15, # лекарственные растения
            'пустырник': 15, # лекарственные растения
            'валериана': 15, # лекарственные растения
            'мать-и-мачеха': 15, # лекарственные растения
            'подорожник': 15, # лекарственные растения
            'крапива': 15, # лекарственные растения
            'одуванчик': 15, # лекарственные растения
            'полынь': 15, # лекарственные растения
            'тысячелистник': 15, # лекарственные растения
            'чистотел': 15, # лекарственные растения
            'золототысячник': 15, # лекарственные растения
            'бессмертник': 15, # лекарственные растения
            'пижма': 15, # лекарственные растения
            'девясил': 15, # лекарственные растения
            'алтей': 15, # лекарственные растения
            'солодка': 15, # лекарственные растения
            'душица': 20, # пряно-вкусовые культуры
            'чабер': 20, # пряно-вкусовые культуры
            'майоран': 20, # пряно-вкусовые культуры
            'кориандр': 20, # пряно-вкусовые культуры
            'тмин': 20,   # пряно-вкусовые культуры
            'анис': 20,   # пряно-вкусовые культуры
            'фенхель': 20, # пряно-вкусовые культуры
            'укроп': 20,  # пряно-вкусовые культуры
            'базилик': 20, # пряно-вкусовые культуры
            'мята': 20,   # пряно-вкусовые культуры
            'мелисса': 20, # пряно-вкусовые культуры
            'лаванда': 20, # пряно-вкусовые культуры
            'шалфей': 20, # пряно-вкусовые культуры
            'розмарин': 20, # пряно-вкусовые культуры
            'тимьян': 20, # пряно-вкусовые культуры
            'орегано': 20, # пряно-вкусовые культуры
            'майоран': 20, # пряно-вкусовые культуры
            'чабер': 20, # пряно-вкусовые культуры
            'кориандр': 20, # пряно-вкусовые культуры
            'тмин': 20,   # пряно-вкусовые культуры
            'анис': 20,   # пряно-вкусовые культуры
            'фенхель': 20, # пряно-вкусовые культуры
        }
    
    def extract_products(self):
        """Extract product information from HTML messages using a more robust approach"""
        with open(self.messages_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Use a more comprehensive approach to find all numbered products
        # Look for patterns like "123. Product Name" throughout the entire content
        
        # First, let's find all potential product numbers
        product_pattern = r'(\d+)\.\s*([А-Я][^.\n]*?)(?:\.|$|\n)'
        all_matches = re.findall(product_pattern, content, re.MULTILINE | re.DOTALL)
        
        print(f"Found {len(all_matches)} potential product matches")
        
        # Process each match
        for match in all_matches:
            product_number = int(match[0])
            product_name = match[1].strip()
            
            # Skip if product name is too short or contains invalid characters
            if len(product_name) < 2:
                continue
                
            # Clean up product name
            product_name = re.sub(r'[^\w\s-]', '', product_name)
            product_name = product_name.strip()
            
            if len(product_name) < 2:
                continue
            
            # Find the full description for this product
            # Look for the text starting from this product number
            description_pattern = rf'{product_number}\.\s*{re.escape(product_name)}.*?(?=\d+\.|$)'
            description_match = re.search(description_pattern, content, re.DOTALL)
            
            if description_match:
                description = description_match.group(0).strip()
            else:
                # Fallback: just use the product name and number
                description = f"{product_number}. {product_name}"
            
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
        
        # Sort products by number
        self.products.sort(key=lambda x: x['number'])
        
        print(f"Successfully extracted {len(self.products)} products")
    
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
            'универсал': 'Универсальный',
            'детерминант': 'Детерминантный',
            'индетерминант': 'Индетерминантный',
            'партенокарп': 'Партенокарпический',
            'пчелоопыля': 'Пчелоопыляемый',
            'самоопыля': 'Самоопыляемый'
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
        processed_dir = "processed_photos_complete"
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
        with open('products_complete.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'number', 'title', 'short_description', 'long_description', 
                         'category_id', 'subcategory', 'weight', 'price', 'image']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for product in self.products:
                writer.writerow(product)
        
        # Create categories CSV
        with open('categories_complete.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'name', 'photo']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for category in self.categories.values():
                writer.writerow(category)
        
        print(f"Created products_complete.csv with {len(self.products)} products")
        print(f"Created categories_complete.csv with {len(self.categories)} categories")
    
    def run(self):
        """Run the complete extraction process"""
        print("Starting complete product extraction...")
        
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
        
        # Print last few products to show range
        print("\nLast few products:")
        for product in self.products[-5:]:
            print(f"  {product['id']}: {product['title']} (Category: {product['category_id']})")

def main():
    extractor = CompleteProductExtractor(
        messages_file='SourceData/messages.html',
        photos_dir='SourceData/photos',
        categories_dir='photo-categories'
    )
    
    extractor.run()

if __name__ == "__main__":
    main()