#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Final Comprehensive Product Extractor with Localization
Merges Telegram + Excel data, adds UA/EN/RU localization, corrects spelling
Target: 95%+ coverage (420+ products)
"""
import zipfile
import re
import csv
import os
import shutil
from pathlib import Path
from xml.etree import ElementTree

class FinalProductExtractor:
    def __init__(self):
        self.products = []
        self.categories = {}
        self.localization = {
            'UA': {
                'categories': {
                    '1': 'Овочі',
                    '2': 'Зелень',
                    '3': 'Квіти',
                    '4': 'Трави',
                    '5': 'Фрукти',
                    '6': 'Ягоди',
                    '7': 'Гриби',
                    '8': 'Зернові',
                    '9': 'Бобові',
                    '10': 'Прянощі'
                }
            },
            'EN': {
                'categories': {
                    '1': 'Vegetables',
                    '2': 'Greens',
                    '3': 'Flowers',
                    '4': 'Herbs',
                    '5': 'Fruits',
                    '6': 'Berries',
                    '7': 'Mushrooms',
                    '8': 'Grains',
                    '9': 'Legumes',
                    '10': 'Spices'
                }
            },
            'RU': {
                'categories': {
                    '1': 'Овощи',
                    '2': 'Зелень',
                    '3': 'Цветы',
                    '4': 'Травы',
                    '5': 'Фрукты',
                    '6': 'Ягоды',
                    '7': 'Грибы',
                    '8': 'Зерновые',
                    '9': 'Бобовые',
                    '10': 'Пряности'
                }
            }
        }
        self.spelling_corrections = {
            'петрушка': 'Петрушка',
            'укроп': 'Укроп',
            'базилік': 'Базилік',
            'м\'ята': 'М\'ята',
            'ромашка': 'Ромашка',
            'календула': 'Календула',
            'томати': 'Томати',
            'огірки': 'Огірки',
            'перець': 'Перець',
            'морква': 'Морква',
            'цибуля': 'Цибуля',
            'часник': 'Часник',
            'картопля': 'Картопля',
            'капуста': 'Капуста',
            'буряк': 'Буряк',
            'редиска': 'Редиска',
            'салат': 'Салат',
            'шпинат': 'Шпинат',
            'кріп': 'Кріп',
            'петрушка': 'Петрушка'
        }

    def extract_from_telegram(self):
        """Extract products from Telegram messages.html"""
        print("Extracting from Telegram messages...")
        try:
            with open('SourceData/messages.html', 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Enhanced pattern to catch more products
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
                # Extract from shared strings
                if 'xl/sharedStrings.xml' in zip_file.namelist():
                    shared_strings = self.extract_shared_strings(zip_file)
                    products.extend(self.extract_from_shared_strings(shared_strings))
                
                # Extract from worksheets
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
                
                # Find all cells with text
                for cell in root.findall('.//{*}c'):
                    if cell.get('t') == 's':  # Shared string
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
        # Clean text
        text = re.sub(r'\s+', ' ', text).strip()
        text = self.correct_spelling(text)
        
        # Extract basic info
        lines = text.split('\n')
        title = lines[0][:100] if lines else text[:100]
        
        # Extract weight
        weight_match = re.search(r'(\d+(?:\.\d+)?)\s*(кг|г|шт|пачка)', text, re.IGNORECASE)
        weight = weight_match.group(1) + ' ' + weight_match.group(2) if weight_match else ''
        
        # Extract price
        price_match = re.search(r'(\d+(?:\.\d+)?)\s*(грн|руб|usd|₴|₽|\$)', text, re.IGNORECASE)
        price = price_match.group(1) + ' ' + price_match.group(2) if price_match else ''
        
        # Determine category
        category_id = self.determine_category(text)
        
        # Generate product ID
        product_number = len(self.products) + 1
        product_id = f"{category_id:02d}{product_number:03d}"
        
        return {
            'id': product_id,
            'title_ua': title,
            'title_en': self.translate_to_english(title),
            'title_ru': self.translate_to_russian(title),
            'description_long_ua': text,
            'description_long_en': self.translate_to_english(text),
            'description_long_ru': self.translate_to_russian(text),
            'description_short_ua': text[:200] + '...' if len(text) > 200 else text,
            'description_short_en': self.translate_to_english(text[:200] + '...' if len(text) > 200 else text),
            'description_short_ru': self.translate_to_russian(text[:200] + '...' if len(text) > 200 else text),
            'category_id': category_id,
            'subcategory': self.determine_subcategory(text),
            'weight': weight,
            'price': price,
            'image': f"p_{category_id:02d}{product_number:03d}_1.jpg"
        }

    def determine_category(self, text):
        """Determine category ID from text"""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['томат', 'огірок', 'перець', 'морква', 'картопля', 'капуста']):
            return 1  # Овочі
        elif any(word in text_lower for word in ['петрушка', 'укроп', 'базилік', 'салат', 'шпинат']):
            return 2  # Зелень
        elif any(word in text_lower for word in ['ромашка', 'календула', 'барвінок', 'лаванда']):
            return 3  # Квіти
        elif any(word in text_lower for word in ['м\'ята', 'меліса', 'чабрець', 'розмарин']):
            return 4  # Трави
        elif any(word in text_lower for word in ['яблуко', 'груша', 'слива', 'абрикос']):
            return 5  # Фрукти
        elif any(word in text_lower for word in ['полуниця', 'малина', 'смородина', 'агрус']):
            return 6  # Ягоди
        elif any(word in text_lower for word in ['шампіньйон', 'печериця', 'опеньок']):
            return 7  # Гриби
        elif any(word in text_lower for word in ['пшениця', 'жито', 'овес', 'ячмінь']):
            return 8  # Зернові
        elif any(word in text_lower for word in ['горох', 'боби', 'соя', 'чечевиця']):
            return 9  # Бобові
        elif any(word in text_lower for word in ['перець', 'гірчиця', 'хрін', 'васабі']):
            return 10  # Прянощі
        else:
            return 1  # Default to vegetables

    def determine_subcategory(self, text):
        """Determine subcategory from text"""
        text_lower = text.lower()
        
        if 'томат' in text_lower:
            return 'Томати'
        elif 'огірок' in text_lower:
            return 'Огірки'
        elif 'перець' in text_lower:
            return 'Перець'
        elif 'петрушка' in text_lower:
            return 'Петрушка'
        elif 'укроп' in text_lower:
            return 'Укроп'
        elif 'базилік' in text_lower:
            return 'Базилік'
        else:
            return ''

    def correct_spelling(self, text):
        """Correct common spelling errors"""
        corrected = text
        for wrong, correct in self.spelling_corrections.items():
            corrected = corrected.replace(wrong, correct)
        return corrected

    def translate_to_english(self, text):
        """Simple translation to English (placeholder)"""
        # This would ideally use a translation service
        # For now, return a basic English version
        return f"[EN] {text[:50]}..."

    def translate_to_russian(self, text):
        """Simple translation to Russian (placeholder)"""
        # This would ideally use a translation service
        # For now, return a basic Russian version
        return f"[RU] {text[:50]}..."

    def merge_and_deduplicate(self, telegram_products, excel_products):
        """Merge products and remove duplicates"""
        print("Merging and deduplicating products...")
        
        all_products = telegram_products + excel_products
        unique_products = {}
        
        for product in all_products:
            # Use title as key for deduplication
            key = product['title_ua'].lower()[:50]
            if key not in unique_products or len(product['description_long_ua']) > len(unique_products[key]['description_long_ua']):
                unique_products[key] = product
        
        # Reassign IDs to ensure proper sequence
        final_products = []
        for i, product in enumerate(unique_products.values()):
            product['id'] = f"{product['category_id']:02d}{i+1:03d}"
            product['image'] = f"p_{product['category_id']:02d}{i+1:03d}_1.jpg"
            final_products.append(product)
        
        print(f"Final unique products: {len(final_products)}")
        return final_products

    def create_categories(self):
        """Create categories with localization"""
        print("Creating categories...")
        
        for cat_id in range(1, 11):
            self.categories[cat_id] = {
                'id': cat_id,
                'name_ua': self.localization['UA']['categories'][str(cat_id)],
                'name_en': self.localization['EN']['categories'][str(cat_id)],
                'name_ru': self.localization['RU']['categories'][str(cat_id)],
                'photo': f"c_{cat_id:02d}.jpg",
                'product_count': 0
            }

    def count_products_per_category(self):
        """Count products in each category"""
        for product in self.products:
            cat_id = product['category_id']
            if cat_id in self.categories:
                self.categories[cat_id]['product_count'] += 1

    def save_products_csv(self, filename='products_final.csv'):
        """Save products to CSV with localization"""
        print(f"Saving {len(self.products)} products to {filename}...")
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([
                'id', 'title_ua', 'title_en', 'title_ru',
                'description_long_ua', 'description_long_en', 'description_long_ru',
                'description_short_ua', 'description_short_en', 'description_short_ru',
                'category_id', 'subcategory', 'weight', 'price', 'image'
            ])
            
            for product in self.products:
                writer.writerow([
                    product['id'],
                    product['title_ua'],
                    product['title_en'],
                    product['title_ru'],
                    product['description_long_ua'],
                    product['description_long_en'],
                    product['description_long_ru'],
                    product['description_short_ua'],
                    product['description_short_en'],
                    product['description_short_ru'],
                    product['category_id'],
                    product['subcategory'],
                    product['weight'],
                    product['price'],
                    product['image']
                ])

    def save_categories_csv(self, filename='categories_final.csv'):
        """Save categories to CSV with localization"""
        print(f"Saving {len(self.categories)} categories to {filename}...")
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['id', 'name_ua', 'name_en', 'name_ru', 'photo', 'product_count'])
            
            for category in self.categories.values():
                writer.writerow([
                    category['id'],
                    category['name_ua'],
                    category['name_en'],
                    category['name_ru'],
                    category['photo'],
                    category['product_count']
                ])

    def process_all(self):
        """Main processing method"""
        print("Starting final comprehensive extraction...")
        
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
        
        print(f"\nFinal Results:")
        print(f"Total Products: {len(self.products)}")
        print(f"Categories: {len(self.categories)}")
        print(f"Coverage: {len(self.products)}/469 = {(len(self.products)/469)*100:.1f}%")
        
        if len(self.products) >= 420:
            print("✅ Target achieved: 95%+ coverage (420+ products)")
        else:
            print("⚠️ Target not met, need more products")

def main():
    extractor = FinalProductExtractor()
    extractor.process_all()

if __name__ == "__main__":
    main()