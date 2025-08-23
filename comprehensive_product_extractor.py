#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive Product Extractor
Combines data from Telegram chat history and Excel file to extract ALL products
"""

import re
import csv
import os
import html
import shutil
import zipfile

class ComprehensiveProductExtractor:
    def __init__(self, messages_file, photos_dir, categories_dir, excel_file):
        self.messages_file = messages_file
        self.photos_dir = photos_dir
        self.categories_dir = categories_dir
        self.excel_file = excel_file
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
    
    def extract_from_excel_sheet1(self):
        """Extract products from Excel sheet1 which seems to contain the main data"""
        print("Extracting from Excel sheet1...")
        
        products = []
        
        try:
            with zipfile.ZipFile(self.excel_file, 'r') as zip_file:
                # Read shared strings
                shared_content = zip_file.read('xl/sharedStrings.xml').decode('utf-8')
                shared_strings = {}
                
                # Parse shared strings manually
                si_tags = shared_content.split('<si>')
                for i, si_content in enumerate(si_tags[1:], 0):
                    t_start = si_content.find('<t')
                    if t_start != -1:
                        t_end = si_content.find('</t>')
                        if t_end != -1:
                            text_start = si_content.find('>', t_start) + 1
                            text = si_content[text_start:t_end].strip()
                            
                            if text.startswith('xml:space="preserve"'):
                                text_start = text.find('>') + 1
                                text = text[text_start:].strip()
                            
                            shared_strings[i] = text
                
                # Read sheet1
                sheet1_content = zip_file.read('xl/worksheets/sheet1.xml').decode('utf-8')
                
                # Find sheetData section
                if '<sheetData>' in sheet1_content:
                    start = sheet1_content.find('<sheetData>')
                    end = sheet1_content.find('</sheetData>')
                    sheet_data = sheet1_content[start:end+12]
                    
                    # Parse rows
                    row_tags = sheet_data.split('<row')
                    
                    # First row is headers
                    if len(row_tags) > 1:
                        header_row = row_tags[1]
                        headers = []
                        
                        # Extract headers
                        cell_tags = header_row.split('<c')
                        for cell_content in cell_tags[1:]:
                            value_match = re.search(r'<v>(\d+)</v>', cell_content)
                            type_match = re.search(r't="([^"]*)"', cell_content)
                            
                            if value_match and type_match:
                                value = int(value_match.group(1))
                                cell_type = type_match.group(1)
                                
                                if cell_type == 's':
                                    header_text = shared_strings.get(value, '')
                                else:
                                    header_text = str(value)
                                
                                headers.append(header_text)
                        
                        print(f"Sheet1 headers: {headers}")
                        
                        # Process data rows
                        for row_content in row_tags[2:]:  # Skip header row
                            cells = []
                            cell_tags = row_content.split('<c')
                            
                            for cell_content in cell_tags[1:]:
                                value_match = re.search(r'<v>([^<]+)</v>', cell_content)
                                type_match = re.search(r't="([^"]*)"', cell_content)
                                
                                if value_match and type_match:
                                    value = value_match.group(1)
                                    cell_type = type_match.group(1)
                                    
                                    if cell_type == 's':
                                        try:
                                            index = int(value)
                                            cell_value = shared_strings.get(index, '')
                                        except ValueError:
                                            cell_value = value
                                    else:
                                        cell_value = value
                                    
                                    cells.append(cell_value)
                            
                            # Create product if we have enough data
                            if len(cells) >= 3 and cells[0] and cells[1]:  # At least ID and name
                                try:
                                    product_id = cells[0]
                                    ukr_name = cells[1] if len(cells) > 1 else ''
                                    rus_name = cells[2] if len(cells) > 2 else ''
                                    ukr_desc = cells[3] if len(cells) > 3 else ''
                                    rus_desc = cells[4] if len(cells) > 4 else ''
                                    ukr_short = cells[5] if len(cells) > 5 else ''
                                    rus_short = cells[6] if len(cells) > 6 else ''
                                    image = cells[7] if len(cells) > 7 else ''
                                    
                                    # Use Ukrainian name if available
                                    name = ukr_name if ukr_name else rus_name
                                    description = ukr_desc if ukr_desc else rus_desc
                                    short_desc = ukr_short if ukr_short else rus_desc
                                    
                                    if name and name.strip():
                                        # Extract product number
                                        product_number = self.extract_product_number(name, product_id)
                                        
                                        # Determine category
                                        category_id = self.determine_category(name, description)
                                        
                                        product = {
                                            'id': f"{category_id:02d}{product_number:03d}",
                                            'number': product_number,
                                            'title': name.strip(),
                                            'short_description': short_desc[:100] + "..." if short_desc and len(short_desc) > 100 else short_desc,
                                            'long_description': description,
                                            'category_id': category_id,
                                            'subcategory': self.determine_subcategory(name, description),
                                            'weight': self.extract_weight(description),
                                            'price': '',
                                            'image': f"p_{category_id:02d}{product_number:03d}_1.jpg",
                                            'source': 'excel_sheet1',
                                            'excel_id': product_id,
                                            'ukr_name': ukr_name,
                                            'rus_name': rus_name
                                        }
                                        
                                        products.append(product)
                                        
                                except Exception as e:
                                    print(f"Error processing row: {e}")
                                    continue
                
                print(f"Extracted {len(products)} products from Excel sheet1")
                return products
                
        except Exception as e:
            print(f"Error processing Excel sheet1: {e}")
            return []
    
    def extract_products_from_telegram(self):
        """Extract product information from HTML messages"""
        with open(self.messages_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Clean HTML content first
        content = re.sub(r'<[^>]+>', ' ', content)
        content = html.unescape(content)
        
        # Find all product numbers and names
        product_pattern = r'(\d+)\.\s*([А-Я][^.\n]*?)(?:\.|$|\n)'
        all_matches = re.findall(product_pattern, content, re.MULTILINE | re.DOTALL)
        
        print(f"Found {len(all_matches)} potential product matches in Telegram")
        
        # Create a dictionary to avoid duplicates
        unique_products = {}
        
        # Process each match
        for match in all_matches:
            product_number = int(match[0])
            product_name = match[1].strip()
            
            # Skip if product name is too short
            if len(product_name) < 3:
                continue
                
            # Clean up product name
            product_name = re.sub(r'[^\w\s-]', '', product_name)
            product_name = product_name.strip()
            
            if len(product_name) < 3:
                continue
            
            # Skip if we already have this product number
            if product_number in unique_products:
                continue
            
            # Find the full description for this product
            start_pattern = rf'{product_number}\.\s*{re.escape(product_name)}'
            start_match = re.search(start_pattern, content, re.IGNORECASE)
            
            if start_match:
                start_pos = start_match.start()
                # Find the next product number
                next_match = re.search(rf'\d+\.\s*[А-Я]', content[start_pos + 10:], re.IGNORECASE)
                
                if next_match:
                    end_pos = start_pos + 10 + next_match.start()
                else:
                    end_pos = len(content)
                
                description = content[start_pos:end_pos].strip()
            else:
                description = f"{product_number}. {product_name}"
            
            # Clean up description
            description = re.sub(r'\s+', ' ', description)
            description = description.strip()
            
            # Create short description
            short_desc_match = re.search(r'^[^.]*\.', description)
            short_description = short_desc_match.group(0) if short_desc_match else description[:100] + "..."
            
            # Determine category
            category_id = self.determine_category(product_name, description)
            
            # Extract weight information
            weight = self.extract_weight(description)
            
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
                'price': '',
                'image': f"p_{category_id:02d}{product_number:03d}_1.jpg",
                'source': 'telegram'
            }
            
            unique_products[product_number] = product
        
        return unique_products
    
    def merge_all_products(self, telegram_products, excel_products):
        """Merge products from all sources, prioritizing Telegram data"""
        merged_products = {}
        
        # Add Telegram products first
        for product_number, product in telegram_products.items():
            merged_products[product_number] = product
        
        # Add Excel products that aren't already in Telegram data
        for excel_product in excel_products:
            product_number = excel_product['number']
            
            if product_number not in merged_products:
                merged_products[product_number] = excel_product
            else:
                # Merge data if Telegram product exists
                telegram_product = merged_products[product_number]
                # Update with Excel data if available
                if excel_product.get('ukr_name') and not telegram_product.get('ukr_name'):
                    telegram_product['ukr_name'] = excel_product['ukr_name']
                if excel_product.get('rus_name') and not telegram_product.get('rus_name'):
                    telegram_product['rus_name'] = excel_product['rus_name']
                if excel_product.get('long_description') and not telegram_product.get('long_description'):
                    telegram_product['long_description'] = excel_product['long_description']
        
        return merged_products
    
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
    
    def extract_product_number(self, name, product_id):
        """Extract product number from name or ID"""
        patterns = [
            r'^(\d+)\.\s*',  # "123. Product Name"
            r'\s+(\d+)\s*$',  # "Product Name 123"
            r'(\d+)',          # Any number
        ]
        
        for pattern in patterns:
            match = re.search(pattern, name)
            if match:
                try:
                    return int(match.group(1))
                except ValueError:
                    continue
        
        # Try to extract from ID
        if product_id:
            match = re.search(r'(\d+)', str(product_id))
            if match:
                try:
                    return int(match.group(1))
                except ValueError:
                    pass
        
        return 0
    
    def process_photos(self):
        """Process and rename product photos"""
        if not os.path.exists(self.photos_dir):
            print(f"Photos directory {self.photos_dir} not found")
            return
        
        # Create processed photos directory
        processed_dir = "processed_photos_comprehensive"
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
        with open('products_comprehensive.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'number', 'title', 'short_description', 'long_description', 
                         'category_id', 'subcategory', 'weight', 'price', 'image', 'source',
                         'excel_id', 'ukr_name', 'rus_name']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for product in self.products:
                writer.writerow(product)
        
        # Create categories CSV
        with open('categories_comprehensive.csv', 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['id', 'name', 'photo']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for category in self.categories.values():
                writer.writerow(category)
        
        print(f"Created products_comprehensive.csv with {len(self.products)} products")
        print(f"Created categories_comprehensive.csv with {len(self.categories)} categories")
    
    def run(self):
        """Run the complete extraction process"""
        print("Starting comprehensive product extraction...")
        
        # Extract products from Telegram
        telegram_products = self.extract_products_from_telegram()
        print(f"Extracted {len(telegram_products)} products from Telegram")
        
        # Extract products from Excel sheet1
        excel_products = self.extract_from_excel_sheet1()
        print(f"Extracted {len(excel_products)} products from Excel sheet1")
        
        # Merge products from all sources
        merged_products = self.merge_all_products(telegram_products, excel_products)
        
        # Convert to list and sort by number
        self.products = list(merged_products.values())
        self.products.sort(key=lambda x: x['number'])
        
        print(f"Total unique products after merging: {len(self.products)}")
        
        # Process photos
        self.process_photos()
        
        # Create CSV files
        self.create_csv_files()
        
        # Print summary
        print("\nComprehensive Extraction Summary:")
        print(f"Total products: {len(self.products)}")
        print(f"Total categories: {len(self.categories)}")
        
        # Print first few products as example
        print("\nSample products:")
        for product in self.products[:5]:
            print(f"  {product['id']}: {product['title']} (Category: {product['category_id']}, Source: {product['source']})")
        
        # Print last few products to show range
        print("\nLast few products:")
        for product in self.products[-5:]:
            print(f"  {product['id']}: {product['title']} (Category: {product['category_id']}, Source: {product['source']})")
        
        # Print product number range
        if self.products:
            print(f"\nProduct number range: {self.products[0]['number']} - {self.products[-1]['number']}")
        
        # Count products by source
        telegram_count = sum(1 for p in self.products if p['source'] == 'telegram')
        excel_count = sum(1 for p in self.products if p['source'] == 'excel_sheet1')
        print(f"\nProducts by source:")
        print(f"  Telegram: {telegram_count}")
        print(f"  Excel: {excel_count}")

def main():
    extractor = ComprehensiveProductExtractor(
        messages_file='SourceData/messages.html',
        photos_dir='SourceData/photos',
        categories_dir='photo-categories',
        excel_file='list.xlsx'
    )
    
    extractor.run()

if __name__ == "__main__":
    main()