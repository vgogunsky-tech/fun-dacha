# Seed Shop Product Database Extractor

This project processes Telegram chat history containing seed product descriptions and extracts structured data for building an online seed shop database.

## Overview

The system extracts product information from Telegram chat messages and creates CSV tables that can be imported into a database for an online seed shop. The shop will allow customers to browse seeds, select quantities, and purchase via Nova Poshta delivery.

## Features

- **Product Extraction**: Automatically identifies and extracts seed product descriptions from Telegram messages
- **Smart Categorization**: Maps products to appropriate categories based on plant type
- **Data Enrichment**: Extracts weight, subcategory, and other product attributes
- **Photo Management**: Renames and organizes product photos with consistent naming convention
- **CSV Export**: Generates structured CSV files ready for database import

## File Structure

```
├── SourceData/
│   ├── messages.html          # Telegram chat history export
│   └── photos/               # Product photos from chat
├── photo-categories/         # Category photos for the shop
├── processed_photos/         # Renamed product photos
├── products_improved.csv     # Main products table
├── categories_improved.csv   # Categories table
├── process_telegram_data_improved.py  # Main extraction script
└── README.md                 # This file
```

## Data Schema

### Products Table (`products_improved.csv`)

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique product ID (format: category_id + product_number) | `19042` |
| `number` | Original product number from chat | `42` |
| `title` | Product name | `Американский ребристый` |
| `short_description` | Brief product description | `42. Американский ребристый.` |
| `long_description` | Full product description | Complete product details... |
| `category_id` | Reference to categories table | `19` |
| `subcategory` | Product subcategory | `Салатный`, `Гибрид`, etc. |
| `weight` | Product weight in grams | `400000` (400g-1kg converted) |
| `price` | Product price (currently empty) | |
| `image` | Product photo filename | `p_19042_1.jpg` |

### Categories Table (`categories_improved.csv`)

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique category ID | `19` |
| `name` | Category name | `томаты` |
| `photo` | Category photo filename | `томаты.jpg` |

## Product Categories

The system recognizes the following main categories:

1. **Томаты (Tomatoes)** - ID: 19
2. **Огурцы (Cucumbers)** - ID: 33
3. **Перец (Peppers)** - ID: 10
4. **Капуста (Cabbage)** - ID: 4
5. **Редис (Radish)** - ID: 31
6. **Свекла (Beets)** - ID: 13
7. **Тыквы (Pumpkins)** - ID: 3
8. **Фасоль (Beans)** - ID: 29
9. **Цветы (Flowers)** - ID: 21
10. **Лук (Onions)** - ID: 37
11. **Морковь (Carrots)** - ID: 34
12. **Кабачки (Zucchini)** - ID: 32
13. **Кукуруза (Corn)** - ID: 26
14. **Арбузы (Watermelons)** - ID: 36
15. **Баклажан (Eggplant)** - ID: 1
16. **Дыни (Melons)** - ID: 14
17. **Земляника (Strawberries)** - ID: 17
18. **Лекарственные растения (Medicinal Plants)** - ID: 15
19. **Пряно-вкусовые культуры (Spice Plants)** - ID: 20
20. **Газонные травы (Lawn Grasses)** - ID: 12
21. **Многолетники (Perennials)** - ID: 5
22. **Однолетники (Annuals)** - ID: 7
23. **Луковичные (Bulbous Plants)** - ID: 30
24. **Патиссон (Patisson)** - ID: 2

## Subcategories

Products are automatically classified into subcategories based on their descriptions:

- **Гибрид F1** - F1 Hybrid varieties
- **Раннеспелый** - Early maturing
- **Среднеспелый** - Mid-season
- **Позднеспелый** - Late maturing
- **Ультраскороспелый** - Ultra-early
- **Салатный** - Salad type
- **Засолочный** - Pickling type
- **Консервный** - Canning type
- **Универсальный** - Universal type
- **Детерминантный** - Determinate growth
- **Индетерминантный** - Indeterminate growth
- **Партенокарпический** - Parthenocarpic
- **Пчелоопыляемый** - Bee-pollinated
- **Самоопыляемый** - Self-pollinating

## Photo Naming Convention

Product photos are renamed using the following format:
```
p_[category_id][product_number]_[photo_number].jpg
```

Examples:
- `p_19042_1.jpg` - Product 42 in category 19 (tomatoes), photo 1
- `p_33102_1.jpg` - Product 102 in category 33 (cucumbers), photo 1

## Usage

### 1. Extract Products

Run the extraction script to process the Telegram chat history:

```bash
python3 process_telegram_data_improved.py
```

This will:
- Parse the HTML messages file
- Extract product information
- Categorize products automatically
- Rename and organize photos
- Generate CSV files

### 2. Import to Database

Use the generated CSV files to populate your database:

```sql
-- Import categories
COPY categories FROM 'categories_improved.csv' WITH (FORMAT csv, HEADER true);

-- Import products
COPY products FROM 'products_improved.csv' WITH (FORMAT csv, HEADER true);
```

### 3. Build Online Shop

The extracted data provides all necessary information for building an online seed shop:

- **Product Catalog**: Browse seeds by category
- **Search & Filter**: Find products by type, subcategory, etc.
- **Shopping Cart**: Select quantities and add to cart
- **Checkout**: Complete purchase with Nova Poshta delivery
- **Admin Panel**: Manage products, inventory, and orders

## Data Quality

The extraction process includes several quality improvements:

- **Smart Categorization**: Uses keyword matching to assign appropriate categories
- **Weight Extraction**: Automatically detects and converts weight measurements
- **Subcategory Detection**: Identifies plant characteristics from descriptions
- **Photo Organization**: Maintains consistent naming and organization
- **Data Validation**: Filters out invalid or incomplete product entries

## Future Enhancements

- **Price Extraction**: Add price detection from product descriptions
- **Inventory Management**: Track seed quantities and availability
- **Seasonal Categories**: Group products by growing season
- **Customer Reviews**: Add review and rating system
- **Bulk Import**: Support for additional data sources

## Technical Requirements

- Python 3.6+
- Standard library modules only (no external dependencies)
- UTF-8 encoding support
- File system access for photo processing

## Support

For questions or issues with the data extraction process, please refer to the script documentation or contact the development team.

## License

This project is designed for internal use in building the seed shop database. Please ensure compliance with data usage policies and regulations.