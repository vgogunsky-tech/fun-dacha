# 🧹 Clean Migration Guide

This guide explains how to perform a clean migration of your OpenCart database.

## 🚀 Quick Options

### Option 1: Complete Clean Migration (Recommended)
```bash
cd /workspace
./clean_migration.sh
```

**What this does:**
- Stops and removes all containers and volumes
- Deletes all database data
- Deletes all OpenCart files
- Starts fresh containers
- Performs complete migration from scratch

### Option 2: Quick Database Clean Only
```bash
cd /workspace
./quick_clean.sh
```

**What this does:**
- Keeps containers running
- Only cleans database tables
- Preserves OpenCart installation files
- Faster than complete clean

### Option 3: Regular Migration (No Clean)
```bash
cd /workspace
./migrate_with_docker.sh
```

**What this does:**
- Updates existing data
- Adds new products/categories
- Preserves existing data

## 🔍 When to Use Each Option

### Use Complete Clean Migration when:
- First time setup
- Major data structure changes
- Corrupted database
- Want to start completely fresh
- Testing migration scripts

### Use Quick Database Clean when:
- Want to keep OpenCart installation
- Just need to refresh product data
- Testing data changes
- Faster than complete clean

### Use Regular Migration when:
- Adding new products
- Updating existing data
- Incremental changes
- Production environment

## 📊 What Gets Migrated

All migration scripts include:

### Categories
- 37 categories from `data/categories_list.csv`
- Category images from `data/images/categories/`
- Parent-child relationships
- Ukrainian and Russian descriptions

### Products
- 435 products from `data/list.csv`
- Product images (primary and secondary) from `data/images/products/`
- Price and weight from CSV
- Ukrainian and Russian names and descriptions
- Tags with localization

### Inventory Options
- Package options (Small/Medium/Large) from `data/inventory.csv`
- Pricing tiers
- Stock quantities
- Ukrainian and Russian option names

## 🛠️ Manual Cleanup Commands

If you need to manually clean specific parts:

### Clean Only Products
```bash
cd opencart-docker
docker compose exec db mysql -u root -pexample opencart -e "
DELETE FROM oc_product_option_value;
DELETE FROM oc_product_option;
DELETE FROM oc_product_to_category;
DELETE FROM oc_product_description;
DELETE FROM oc_product_image;
DELETE FROM oc_product;
ALTER TABLE oc_product AUTO_INCREMENT = 1;
"
```

### Clean Only Categories
```bash
cd opencart-docker
docker compose exec db mysql -u root -pexample opencart -e "
DELETE FROM oc_category_path;
DELETE FROM oc_category_description;
DELETE FROM oc_category;
ALTER TABLE oc_category AUTO_INCREMENT = 1;
"
```

### Reset Everything (Nuclear Option)
```bash
cd opencart-docker
docker compose down -v
sudo rm -rf db_data/*
sudo rm -rf opencart_data/*
docker compose up -d
```

## 🔍 Verification

After any migration, verify the results:

### Check Database Counts
```bash
cd opencart-docker
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Categories:' as info, COUNT(*) as count FROM oc_category
UNION ALL
SELECT 'Products:', COUNT(*) FROM oc_product
UNION ALL
SELECT 'Product Images:', COUNT(*) FROM oc_product_image
UNION ALL
SELECT 'Product Options:', COUNT(*) FROM oc_product_option;
"
```

### Check Web Interface
- Frontend: http://localhost:8080
- Admin: http://localhost:8080/admin
- phpMyAdmin: http://localhost:8082

### Check Images
- Product images: http://localhost:8080/image/catalog/product/p100001.jpg
- Category images: http://localhost:8080/image/catalog/category/c100.jpg

## 🚨 Troubleshooting

### Migration Fails
1. Check Docker containers are running: `docker compose ps`
2. Check database connection: `docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart`
3. Check CSV files exist: `ls -la data/*.csv`
4. Check images exist: `ls -la data/images/products/ | head -5`

### Images Not Showing
1. Check image staging: `ls -la opencart-docker/opencart_data/image/catalog/product/ | head -5`
2. Check container images: `docker compose exec web ls -la /var/www/html/image/catalog/product/ | head -5`
3. Check permissions: `docker compose exec web ls -la /var/www/html/image/`

### Database Connection Issues
1. Restart containers: `docker compose restart`
2. Check logs: `docker compose logs db`
3. Wait longer: `sleep 30` then retry

## 📝 Notes

- Complete clean migration takes longer but ensures no conflicts
- Quick clean is faster but may leave some orphaned data
- Always backup important data before cleaning
- The migration scripts handle all data types: categories, products, images, options, and inventory

---

**Choose the right option for your needs! 🎯**