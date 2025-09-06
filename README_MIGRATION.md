# OpenCart Product Migration Guide

This guide helps you migrate product data from CSV files to your OpenCart database using the provided Docker setup.

## 📋 Overview

The migration process includes:
- **37 categories** from `data/categories_list.csv`
- **435 products** from `data/list.csv`
- **891 product images** from `data/images/products/`
- **Category images** from `data/images/categories/`

## 🚀 Quick Start (Recommended)

### Option 1: Docker Migration (Easiest)

1. **Start the migration:**
   ```bash
   cd /workspace
   ./migrate_with_docker.sh
   ```

2. **Access your OpenCart store:**
   - Frontend: http://localhost:8080
   - Admin panel: http://localhost:8080/admin
   - phpMyAdmin: http://localhost:8082

### Option 2: Manual Docker Migration

1. **Start OpenCart containers:**
   ```bash
   cd /workspace/opencart-docker
   docker compose up -d
   ```

2. **Wait for database to be ready:**
   ```bash
   sleep 30
   ```

3. **Run the migration:**
   ```bash
   cd /workspace
   python3 opencart_migration.py
   ```

4. **Migrate images:**
   ```bash
   python3 migrate_images.py
   ```

## 🔧 Manual Setup (Without Docker)

If you have direct database access:

1. **Install dependencies:**
   ```bash
   pip3 install -r requirements_migration.txt
   ```

2. **Run migration:**
   ```bash
   python3 migrate_without_docker.py
   ```

3. **Follow the prompts to enter database credentials**

## 📊 Data Structure

### Categories CSV Format
```csv
id,name,parentId,tag,description (ukr),primary_image
100,Томати,,tomato,Томати відносяться до роду пасльонових...,c100.jpg
101,Томати високорослі,100,tomato-small,Відмітна риса високорослих томатів...,c101.jpg
```

### Products CSV Format
```csv
id,Название (укр),Название (рус),Описание (укр),Описание (рус),primary_image,category_id,subcategory_id,product_id,validated,year,availability,images,tags
1,Амурський тигр,Амурский тигр,Високий кущ з щільними червоними плодами...,p100001.jpg,100,101,p100001,1,2025,1,,tall,red,yellow,firm,disease_resistant,thin_skin
```

## 🗄️ Database Schema

The migration creates/updates these OpenCart tables:
- `oc_product` - Main product information
- `oc_product_description` - Product names and descriptions (Ukrainian/Russian)
- `oc_product_to_category` - Product-category relationships
- `oc_product_image` - Product images
- `oc_category` - Category information
- `oc_category_description` - Category names and descriptions
- `oc_language` - Language settings (Ukrainian/Russian)

## 🖼️ Image Migration

Images are copied to OpenCart's image directory:
- Product images: `/var/www/html/image/catalog/product/`
- Category images: `/var/www/html/image/catalog/category/`

## 🧪 Testing

Test your data before migration:
```bash
python3 test_migration_data.py
```

This will show:
- Number of categories and products
- Sample data structure
- Available images

## 📝 Migration Logs

Check migration progress and errors:
```bash
# View migration log
cat migration.log

# For Docker migration
docker compose exec web cat /var/www/html/migration.log
```

## 🔍 Verification

After migration, verify the data:

1. **Check OpenCart frontend:**
   - Visit http://localhost:8080
   - Browse categories and products

2. **Check admin panel:**
   - Login to http://localhost:8080/admin
   - Go to Catalog > Products
   - Go to Catalog > Categories

3. **Check database directly:**
   - Use phpMyAdmin at http://localhost:8082
   - Browse the `opencart` database tables

## 🛠️ Troubleshooting

### Common Issues

1. **Database connection failed:**
   - Ensure Docker containers are running
   - Check database credentials
   - Wait for database to fully initialize

2. **Images not showing:**
   - Run the image migration script
   - Check file permissions
   - Verify image paths in database

3. **Products not appearing:**
   - Check if products are enabled (status = 1)
   - Verify category assignments
   - Check language settings

### Reset Migration

To start fresh:
```bash
# Stop containers
docker compose down

# Remove volumes (WARNING: This deletes all data)
docker compose down -v

# Start fresh
docker compose up -d
```

## 📁 File Structure

```
/workspace/
├── data/
│   ├── categories_list.csv      # Category data
│   ├── list.csv                 # Product data
│   └── images/
│       ├── products/            # Product images
│       └── categories/          # Category images
├── opencart-docker/             # Docker setup
├── opencart_migration.py        # Main migration script
├── migrate_with_docker.sh       # Docker migration script
├── migrate_without_docker.py    # Manual migration script
├── migrate_images.py            # Image migration script
├── test_migration_data.py       # Data testing script
└── requirements_migration.txt   # Python dependencies
```

## 🎯 Next Steps

After successful migration:

1. **Configure OpenCart:**
   - Set up store settings
   - Configure payment methods
   - Set up shipping options

2. **Customize appearance:**
   - Choose a theme
   - Customize layouts
   - Add banners and content

3. **SEO optimization:**
   - Set up URL rewrites
   - Configure meta tags
   - Add sitemap

## 📞 Support

If you encounter issues:
1. Check the migration logs
2. Verify Docker container status
3. Test database connectivity
4. Review the troubleshooting section above

---

**Happy migrating! 🚀**