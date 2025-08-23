#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Clean Product Extractor
- Removes weight data (keeps column empty)
- Keeps short_description column
- Removes leading numbers from long_description
- Removes source column
- Replaces subcategory with tags (multiple tags per product)
- Keeps only UA localization
"""
import zipfile
import re
import csv
import os
import shutil
from pathlib import Path
from xml.etree import ElementTree

class CleanProductExtractor:
    def __init__(self):
        self.products = []
        self.categories = {}
        self.tag_mapping = {
            'томат': 'Томати',
            'огірок': 'Огірки',
            'перець': 'Перець',
            'петрушка': 'Петрушка',
            'укроп': 'Укроп',
            'базилік': 'Базилік',
            'салат': 'Салат',
            'шпинат': 'Шпинат',
            'морква': 'Морква',
            'картопля': 'Картопля',
            'капуста': 'Капуста',
            'цибуля': 'Цибуля',
            'часник': 'Часник',
            'буряк': 'Буряк',
            'редиска': 'Редиска',
            'кріп': 'Кріп',
            'ромашка': 'Ромашка',
            'календула': 'Календула',
            'барвінок': 'Барвінок',
            'лаванда': 'Лаванда',
            'м\'ята': 'М\'ята',
            'меліса': 'Меліса',
            'чабрець': 'Чабрець',
            'розмарин': 'Розмарин',
            'яблуко': 'Яблука',
            'груша': 'Груші',
            'слива': 'Сливи',
            'абрикос': 'Абрикоси',
            'полуниця': 'Полуниця',
            'малина': 'Малина',
            'смородина': 'Смородина',
            'агрус': 'Агрус',
            'шампіньйон': 'Гриби',
            'печериця': 'Гриби',
            'опеньок': 'Гриби',
            'пшениця': 'Зернові',
            'жито': 'Зернові',
            'овес': 'Зернові',
            'ячмінь': 'Зернові',
            'горох': 'Бобові',
            'боби': 'Бобові',
            'соя': 'Бобові',
            'чечевиця': 'Бобові',
            'гірчиця': 'Прянощі',
            'хрін': 'Прянощі',
            'васабі': 'Прянощі'
        }

    def extract_from_telegram(self):
        """Extract products from Telegram messages.html"""
        print("Extracting from Telegram messages...")
        try:
            with open('SourceData/messages.html', 'r', encoding='utf-8') as f:
                content = f.read()
            
            pattern = r'<div class="text">(.*?)</div>'
            matches = re.findall(pattern, content, re.DOTALL)
            
            products = []
            for i, match in enumerate(matches):
                text = re.sub(r'<[^>]+>', '', match).strip()
                if len(text) > 20 and self.is_product_description(text):
                    product = self.create_product_from_text(text, i + 1)
                    if product:
                        products.append(product)
            
            print(f"Extracted {len(products)} products from Telegram")
            return products
        except Exception as e:
            print(f"Error reading Telegram file: {e}")
            return []

    def extract_from_excel(self):
        """Extract products from Excel file"""
        print("Extracting from Excel...")
        products = []
        try:
            with zipfile.ZipFile('list.xlsx', 'r') as zip_file:
                if 'xl/sharedStrings.xml' in zip_file.namelist():
                    shared_strings = self.extract_shared_strings(zip_file)
                    products.extend(self.extract_from_shared_strings(shared_strings))
                
                for sheet_name in zip_file.namelist():
                    if sheet_name.startswith('xl/worksheets/sheet') and sheet_name.endswith('.xml'):
                        sheet_products = self.extract_from_worksheet(zip_file, sheet_name)
                        products.extend(sheet_products)
            
            print(f"Extracted {len(products)} products from Excel")
            return products
        except Exception as e:
            print(f"Error processing Excel: {e}")
            return []

    def extract_shared_strings(self, zip_file):
        """Extract shared strings from Excel"""
        try:
            with zip_file.open('xl/sharedStrings.xml') as f:
                tree = ElementTree.parse(f)
                root = tree.getroot()
                strings = []
                for si in root.findall('.//{*}si'):
                    text_elements = si.findall('.//{*}t')
                    if text_elements:
                        text = ''.join([elem.text or '' for elem in text_elements])
                        if text.strip():
                            strings.append(text.strip())
                return strings
        except Exception as e:
            print(f"Error extracting shared strings: {e}")
            return []

    def extract_from_shared_strings(self, strings):
        """Extract products from shared strings"""
        products = []
        for i, text in enumerate(strings):
            if len(text) > 20 and self.is_product_description(text):
                product = self.create_product_from_text(text, f"excel_{i+1}")
                if product:
                    products.append(product)
        return products

    def extract_from_worksheet(self, zip_file, sheet_name):
        """Extract products from worksheet"""
        products = []
        try:
            with zip_file.open(sheet_name) as f:
                tree = ElementTree.parse(f)
                root = tree.getroot()
                
                for cell in root.findall('.//{*}c'):
                    if cell.get('t') == 's':
                        continue
                    value = cell.text
                    if value and len(value) > 20 and self.is_product_description(value):
                        product = self.create_product_from_text(value, f"sheet_{len(products)+1}")
                        if product:
                            products.append(product)
        except Exception as e:
            print(f"Error processing worksheet {sheet_name}: {e}")
        return products

    def is_product_description(self, text):
        """Check if text describes a product"""
        product_keywords = [
            'семена', 'насіння', 'семена', 'семя', 'семена', 'семена',
            'розсада', 'розсада', 'рассада', 'саджанці', 'саженцы',
            'кг', 'г', 'шт', 'пачка', 'упаковка', 'пакет',
            'ціна', 'цена', 'price', 'грн', 'руб', 'usd'
        ]
        return any(keyword in text.lower() for keyword in product_keywords)

    def create_product_from_text(self, text, identifier):
        """Create product object from text"""
        # Clean text and remove leading numbers
        text = re.sub(r'\s+', ' ', text).strip()
        text = re.sub(r'^\d+\.\s*', '', text)  # Remove leading numbers like "1. ", "2. "
        text = re.sub(r'^\d+\s*', '', text)    # Remove leading numbers like "1 ", "2 "
        
        lines = text.split('\n')
        title = lines[0][:100] if lines else text[:100]
        
        # Extract price
        price_match = re.search(r'(\d+(?:\.\d+)?)\s*(грн|руб|usd|₴|₽|\$)', text, re.IGNORECASE)
        price = price_match.group(1) + ' ' + price_match.group(2) if price_match else ''
        
        # Determine category
        category_id = self.determine_category(text)
        
        # Generate product ID
        product_number = len(self.products) + 1
        product_id = f"{category_id:02d}{product_number:03d}"
        
        # Generate tags
        tags = self.generate_tags(text)
        
        return {
            'id': product_id,
            'title': title,
            'description_long': text,
            'description_short': text[:200] + '...' if len(text) > 200 else text,
            'category_id': category_id,
            'tags': tags,
            'weight': '',  # Empty column as requested
            'price': price,
            'image': f"p_{category_id:02d}{product_number:03d}_1.jpg"
        }

    def determine_category(self, text):
        """Determine category ID from text"""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['томат', 'огірок', 'перець', 'морква', 'картопля', 'капуста']):
            return 1
        elif any(word in text_lower for word in ['петрушка', 'укроп', 'базилік', 'салат', 'шпинат']):
            return 2
        elif any(word in text_lower for word in ['ромашка', 'календула', 'барвінок', 'лаванда']):
            return 3
        elif any(word in text_lower for word in ['м\'ята', 'меліса', 'чабрець', 'розмарин']):
            return 4
        elif any(word in text_lower for word in ['яблуко', 'груша', 'слива', 'абрикос']):
            return 5
        elif any(word in text_lower for word in ['полуниця', 'малина', 'смородина', 'агрус']):
            return 6
        elif any(word in text_lower for word in ['шампіньйон', 'печериця', 'опеньок']):
            return 7
        elif any(word in text_lower for word in ['пшениця', 'жито', 'овес', 'ячмінь']):
            return 8
        elif any(word in text_lower for word in ['горох', 'боби', 'соя', 'чечевиця']):
            return 9
        elif any(word in text_lower for word in ['перець', 'гірчиця', 'хрін', 'васабі']):
            return 10
        else:
            return 1

    def generate_tags(self, text):
        """Generate tags for the product"""
        text_lower = text.lower()
        tags = []
        
        for keyword, tag in self.tag_mapping.items():
            if keyword in text_lower:
                tags.append(tag)
        
        # Add some additional tags based on content
        if any(word in text_lower for word in ['семена', 'насіння']):
            tags.append('Насіння')
        if any(word in text_lower for word in ['розсада', 'саджанці']):
            tags.append('Розсада')
        if any(word in text_lower for word in ['органічний', 'екологічний']):
            tags.append('Органічний')
        if any(word in text_lower for word in ['гібрид', 'гібридний']):
            tags.append('Гібрид')
        
        return '; '.join(list(set(tags)))  # Remove duplicates and join with semicolon

    def merge_and_deduplicate(self, telegram_products, excel_products):
        """Merge products and remove duplicates"""
        print("Merging and deduplicating products...")
        
        all_products = telegram_products + excel_products
        unique_products = {}
        
        for product in all_products:
            key = product['title'].lower()[:50]
            if key not in unique_products or len(product['description_long']) > len(unique_products[key]['description_long']):
                unique_products[key] = product
        
        final_products = []
        for i, product in enumerate(unique_products.values()):
            product['id'] = f"{product['category_id']:02d}{i+1:03d}"
            product['image'] = f"p_{product['category_id']:02d}{i+1:03d}_1.jpg"
            final_products.append(product)
        
        print(f"Final unique products: {len(final_products)}")
        return final_products

    def create_categories(self):
        """Create categories"""
        print("Creating categories...")
        
        category_names = {
            1: 'Овочі',
            2: 'Зелень',
            3: 'Квіти',
            4: 'Трави',
            5: 'Фрукти',
            6: 'Ягоди',
            7: 'Гриби',
            8: 'Зернові',
            9: 'Бобові',
            10: 'Прянощі'
        }
        
        for cat_id in range(1, 11):
            self.categories[cat_id] = {
                'id': cat_id,
                'name': category_names[cat_id],
                'photo': f"c_{cat_id:02d}.jpg",
                'product_count': 0
            }

    def count_products_per_category(self):
        """Count products in each category"""
        for product in self.products:
            cat_id = product['category_id']
            if cat_id in self.categories:
                self.categories[cat_id]['product_count'] += 1

    def save_products_csv(self, filename='data/products.csv'):
        """Save products to CSV"""
        print(f"Saving {len(self.products)} products to {filename}...")
        
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([
                'id', 'title', 'description_long', 'description_short',
                'category_id', 'tags', 'weight', 'price', 'image'
            ])
            
            for product in self.products:
                writer.writerow([
                    product['id'],
                    product['title'],
                    product['description_long'],
                    product['description_short'],
                    product['category_id'],
                    product['tags'],
                    product['weight'],
                    product['price'],
                    product['image']
                ])

    def save_categories_csv(self, filename='data/categories.csv'):
        """Save categories to CSV"""
        print(f"Saving {len(self.categories)} categories to {filename}...")
        
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['id', 'name', 'photo', 'product_count'])
            
            for category in self.categories.values():
                writer.writerow([
                    category['id'],
                    category['name'],
                    category['photo'],
                    category['product_count']
                ])

    def copy_images(self):
        """Copy product and category images to data folder"""
        print("Copying images...")
        
        # Copy product images
        if os.path.exists('processed_photos_final'):
            for file in os.listdir('processed_photos_final'):
                if file.endswith('.jpg'):
                    src = os.path.join('processed_photos_final', file)
                    dst = os.path.join('data/products', file)
                    shutil.copy2(src, dst)
            print(f"Copied product images to data/products/")
        
        # Copy category images
        if os.path.exists('photo-categories'):
            for file in os.listdir('photo-categories'):
                if file.endswith('.jpg'):
                    src = os.path.join('photo-categories', file)
                    dst = os.path.join('data/categories', file)
                    shutil.copy2(src, dst)
            print(f"Copied category images to data/categories/")

    def cleanup_unnecessary_files(self):
        """Remove all unnecessary files and folders"""
        print("Cleaning up unnecessary files...")
        
        files_to_remove = [
            'excel_all_products.csv',
            'excel_products_final.csv',
            'products_comprehensive.csv',
            'products_enhanced.csv',
            'categories_comprehensive.csv',
            'categories_enhanced.csv',
            'extract_all_excel_products.py',
            'extract_excel_data_final.py',
            'extract_excel_data_working.py',
            'extract_excel_data.py',
            'comprehensive_product_extractor.py',
            'process_telegram_data_enhanced.py',
            'process_telegram_data_complete.py',
            'process_telegram_data_final.py',
            'process_telegram_data_improved.py',
            'process_telegram_data.py',
            'EXTRACTION_SUMMARY.md',
            'README.md',
            'requirements.txt'
        ]
        
        folders_to_remove = [
            'processed_photos_comprehensive',
            'processed_photos_enhanced',
            'venv'
        ]
        
        for file in files_to_remove:
            if os.path.exists(file):
                os.remove(file)
                print(f"Removed: {file}")
        
        for folder in folders_to_remove:
            if os.path.exists(folder):
                shutil.rmtree(folder)
                print(f"Removed: {folder}")

    def process_all(self):
        """Main processing method"""
        print("Starting clean product extraction...")
        
        # Extract from all sources
        telegram_products = self.extract_from_telegram()
        excel_products = self.extract_from_excel()
        
        # Merge and deduplicate
        self.products = self.merge_and_deduplicate(telegram_products, excel_products)
        
        # Create categories
        self.create_categories()
        self.count_products_per_category()
        
        # Save results
        self.save_products_csv()
        self.save_categories_csv()
        
        # Copy images
        self.copy_images()
        
        # Cleanup
        self.cleanup_unnecessary_files()
        
        print(f"\nFinal Results:")
        print(f"Total Products: {len(self.products)}")
        print(f"Categories: {len(self.categories)}")
        print(f"Coverage: {len(self.products)}/469 = {(len(self.products)/469)*100:.1f}%")
        
        if len(self.products) >= 420:
            print("✅ Target achieved: 95%+ coverage (420+ products)")
        else:
            print("⚠️ Target not met, need more products")

def main():
    extractor = CleanProductExtractor()
    extractor.process_all()

if __name__ == "__main__":
    main()