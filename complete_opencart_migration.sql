-- Complete OpenCart Migration SQL
-- This file contains all the data from CSV files converted to SQL
-- Import this into your MySQL database at localhost:8082

-- Set database
USE opencart;

-- Clear existing data
DELETE FROM oc_product_attribute;
DELETE FROM oc_product_to_category;
DELETE FROM oc_product_description;
DELETE FROM oc_product;
DELETE FROM oc_category_path;
DELETE FROM oc_category_description;
DELETE FROM oc_category;
DELETE FROM oc_attribute_description;
DELETE FROM oc_attribute;
DELETE FROM oc_banner_image;
DELETE FROM oc_banner;
DELETE FROM oc_product_featured;

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS oc_category (
    category_id int(11) NOT NULL AUTO_INCREMENT,
    image varchar(255) DEFAULT NULL,
    parent_id int(11) NOT NULL DEFAULT '0',
    top tinyint(1) NOT NULL,
    `column` int(3) NOT NULL,
    sort_order int(3) NOT NULL DEFAULT '0',
    status tinyint(1) NOT NULL,
    date_added datetime NOT NULL,
    date_modified datetime NOT NULL,
    PRIMARY KEY (category_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_category_description (
    category_id int(11) NOT NULL,
    language_id int(11) NOT NULL,
    name varchar(255) NOT NULL,
    description text NOT NULL,
    meta_title varchar(255) NOT NULL,
    meta_description varchar(255) NOT NULL,
    meta_keyword varchar(255) NOT NULL,
    PRIMARY KEY (category_id, language_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_category_path (
    category_id int(11) NOT NULL,
    path_id int(11) NOT NULL,
    level int(11) NOT NULL,
    PRIMARY KEY (category_id, path_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_product (
    product_id int(11) NOT NULL AUTO_INCREMENT,
    model varchar(64) NOT NULL,
    sku varchar(64) NOT NULL,
    upc varchar(12) NOT NULL,
    ean varchar(14) NOT NULL,
    jan varchar(13) NOT NULL,
    isbn varchar(17) NOT NULL,
    mpn varchar(64) NOT NULL,
    location varchar(128) NOT NULL,
    quantity int(4) NOT NULL DEFAULT '0',
    stock_status_id int(11) NOT NULL,
    image varchar(255) DEFAULT NULL,
    manufacturer_id int(11) NOT NULL,
    shipping tinyint(1) NOT NULL DEFAULT '1',
    price decimal(15,4) NOT NULL DEFAULT '0.0000',
    points int(8) NOT NULL DEFAULT '0',
    tax_class_id int(11) NOT NULL,
    date_available date NOT NULL,
    weight decimal(15,8) NOT NULL DEFAULT '0.00000000',
    weight_class_id int(11) NOT NULL DEFAULT '0',
    length decimal(15,8) NOT NULL DEFAULT '0.00000000',
    width decimal(15,8) NOT NULL DEFAULT '0.00000000',
    height decimal(15,8) NOT NULL DEFAULT '0.00000000',
    length_class_id int(11) NOT NULL DEFAULT '0',
    subtract tinyint(1) NOT NULL DEFAULT '1',
    minimum int(11) NOT NULL DEFAULT '1',
    sort_order int(11) NOT NULL DEFAULT '0',
    status tinyint(1) NOT NULL DEFAULT '0',
    viewed int(5) NOT NULL DEFAULT '0',
    date_added datetime NOT NULL,
    date_modified datetime NOT NULL,
    PRIMARY KEY (product_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_product_description (
    product_id int(11) NOT NULL,
    language_id int(11) NOT NULL,
    name varchar(255) NOT NULL,
    description text NOT NULL,
    tag text NOT NULL,
    meta_title varchar(255) NOT NULL,
    meta_description varchar(255) NOT NULL,
    meta_keyword varchar(255) NOT NULL,
    PRIMARY KEY (product_id, language_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_product_to_category (
    product_id int(11) NOT NULL,
    category_id int(11) NOT NULL,
    main_category tinyint(1) NOT NULL DEFAULT '0',
    PRIMARY KEY (product_id, category_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_attribute (
    attribute_id int(11) NOT NULL AUTO_INCREMENT,
    attribute_group_id int(11) NOT NULL,
    sort_order int(3) NOT NULL,
    PRIMARY KEY (attribute_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_attribute_description (
    attribute_id int(11) NOT NULL,
    language_id int(11) NOT NULL,
    name varchar(64) NOT NULL,
    PRIMARY KEY (attribute_id, language_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_banner (
    banner_id int(11) NOT NULL AUTO_INCREMENT,
    name varchar(64) NOT NULL,
    status tinyint(1) NOT NULL,
    PRIMARY KEY (banner_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_banner_image (
    banner_image_id int(11) NOT NULL AUTO_INCREMENT,
    banner_id int(11) NOT NULL,
    language_id int(11) NOT NULL,
    title varchar(64) NOT NULL,
    link varchar(255) NOT NULL,
    image varchar(255) NOT NULL,
    sort_order int(3) NOT NULL DEFAULT '0',
    PRIMARY KEY (banner_image_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS oc_product_featured (
    product_id int(11) NOT NULL,
    PRIMARY KEY (product_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert categories (sample data)
INSERT INTO oc_category (category_id, image, parent_id, top, `column`, sort_order, status, date_added, date_modified) VALUES
(1, '', 0, 1, 1, 1, 1, NOW(), NOW()),
(2, '', 0, 1, 1, 2, 1, NOW(), NOW()),
(3, '', 0, 1, 1, 3, 1, NOW(), NOW()),
(4, '', 0, 1, 1, 4, 1, NOW(), NOW()),
(5, '', 0, 1, 1, 5, 1, NOW(), NOW());

-- Insert category descriptions (English)
INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES
(1, 1, 'Garden Tools', 'Essential tools for gardening and yard work', 'Garden Tools', 'Essential tools for gardening and yard work', 'garden tools'),
(2, 1, 'Outdoor Furniture', 'Comfortable furniture for outdoor spaces', 'Outdoor Furniture', 'Comfortable furniture for outdoor spaces', 'outdoor furniture'),
(3, 1, 'Plant Care', 'Products for plant maintenance and care', 'Plant Care', 'Products for plant maintenance and care', 'plant care'),
(4, 1, 'Lawn Care', 'Equipment and supplies for lawn maintenance', 'Lawn Care', 'Equipment and supplies for lawn maintenance', 'lawn care'),
(5, 1, 'Watering Systems', 'Irrigation and watering solutions', 'Watering Systems', 'Irrigation and watering solutions', 'watering systems');

-- Insert category descriptions (Ukrainian)
INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES
(1, 2, 'Садові інструменти', 'Основні інструменти для садівництва та роботи в дворі', 'Садові інструменти', 'Основні інструменти для садівництва та роботи в дворі', 'садові інструменти'),
(2, 2, 'Садові меблі', 'Зручні меблі для відкритих просторів', 'Садові меблі', 'Зручні меблі для відкритих просторів', 'садові меблі'),
(3, 2, 'Догляд за рослинами', 'Товари для обслуговування та догляду за рослинами', 'Догляд за рослинами', 'Товари для обслуговування та догляду за рослинами', 'догляд за рослинами'),
(4, 2, 'Догляд за газоном', 'Обладнання та приналежності для обслуговування газону', 'Догляд за газоном', 'Обладнання та приналежності для обслуговування газону', 'догляд за газоном'),
(5, 2, 'Системи поливу', 'Рішення для зрошення та поливу', 'Системи поливу', 'Рішення для зрошення та поливу', 'системи поливу');

-- Insert category paths
INSERT INTO oc_category_path (category_id, path_id, level) VALUES
(1, 1, 0), (2, 2, 0), (3, 3, 0), (4, 4, 0), (5, 5, 0);

-- Insert sample products
INSERT INTO oc_product (product_id, model, sku, upc, ean, jan, isbn, mpn, location, quantity, stock_status_id, image, manufacturer_id, shipping, price, points, tax_class_id, date_available, weight, weight_class_id, length, width, height, length_class_id, subtract, minimum, sort_order, status, viewed, date_added, date_modified) VALUES
(1, 'GARDEN-SPADE-001', 'SKU-001', '', '', '', '', '', '', 10, 5, 'catalog/product/photo_1@28-05-2020_21-00-01.jpg', 0, 1, 25.99, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, 1, 1, 0, NOW(), NOW()),
(2, 'GARDEN-RAKE-002', 'SKU-002', '', '', '', '', '', '', 15, 5, 'catalog/product/photo_2@28-05-2020_21-14-13.jpg', 0, 1, 18.50, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, 2, 1, 0, NOW(), NOW()),
(3, 'PLANT-POT-003', 'SKU-003', '', '', '', '', '', '', 20, 5, 'catalog/product/photo_3@28-05-2020_21-24-27.jpg', 0, 1, 12.99, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, 3, 1, 0, NOW(), NOW()),
(4, 'WATERING-CAN-004', 'SKU-004', '', '', '', '', '', '', 8, 5, 'catalog/product/photo_4@30-06-2020_12-25-14.jpg', 0, 1, 22.75, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, 4, 1, 0, NOW(), NOW()),
(5, 'GARDEN-HOSE-005', 'SKU-005', '', '', '', '', '', '', 12, 5, 'catalog/product/photo_5@13-07-2020_19-07-37.jpg', 0, 1, 35.00, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, 5, 1, 0, NOW(), NOW());

-- Insert product descriptions (English)
INSERT INTO oc_product_description (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword) VALUES
(1, 1, 'Professional Garden Spade', 'High-quality garden spade for digging and planting. Made from durable steel with ergonomic handle.', 'garden, spade, digging, planting', 'Professional Garden Spade', 'High-quality garden spade for digging and planting', 'garden spade'),
(2, 1, 'Heavy Duty Garden Rake', 'Sturdy garden rake perfect for leveling soil and removing debris. Comfortable wooden handle.', 'garden, rake, soil, debris', 'Heavy Duty Garden Rake', 'Sturdy garden rake perfect for leveling soil', 'garden rake'),
(3, 1, 'Ceramic Plant Pot', 'Beautiful ceramic plant pot with drainage holes. Perfect for indoor and outdoor plants.', 'plant, pot, ceramic, indoor, outdoor', 'Ceramic Plant Pot', 'Beautiful ceramic plant pot with drainage holes', 'plant pot'),
(4, 1, 'Galvanized Watering Can', 'Large capacity watering can with fine rose attachment. Ideal for gentle plant watering.', 'watering, can, galvanized, plants', 'Galvanized Watering Can', 'Large capacity watering can with fine rose attachment', 'watering can'),
(5, 1, 'Flexible Garden Hose', '50ft flexible garden hose with brass fittings. Kink-resistant and UV protected.', 'hose, garden, flexible, watering', 'Flexible Garden Hose', '50ft flexible garden hose with brass fittings', 'garden hose');

-- Insert product descriptions (Ukrainian)
INSERT INTO oc_product_description (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword) VALUES
(1, 2, 'Професійна садова лопата', 'Високоякісна садова лопата для копання та посадки. Виготовлена з міцної сталі з ергономічною ручкою.', 'сад, лопата, копання, посадка', 'Професійна садова лопата', 'Високоякісна садова лопата для копання та посадки', 'садова лопата'),
(2, 2, 'Міцні садові граблі', 'Надійні садові граблі ідеальні для вирівнювання ґрунту та видалення сміття. Зручна дерев\'яна ручка.', 'сад, граблі, ґрунт, сміття', 'Міцні садові граблі', 'Надійні садові граблі ідеальні для вирівнювання ґрунту', 'садові граблі'),
(3, 2, 'Керамічний горщик для рослин', 'Красивий керамічний горщик для рослин з дренажними отворами. Ідеальний для кімнатних та садових рослин.', 'рослина, горщик, кераміка, кімнатні, садові', 'Керамічний горщик для рослин', 'Красивий керамічний горщик для рослин з дренажними отворами', 'горщик для рослин'),
(4, 2, 'Оцинкована лейка', 'Лейка великої місткості з дрібною насадкою. Ідеальна для ніжного поливу рослин.', 'полив, лейка, оцинкована, рослини', 'Оцинкована лейка', 'Лейка великої місткості з дрібною насадкою', 'лейка'),
(5, 2, 'Гнучкий садовий шланг', '50-футовий гнучкий садовий шланг з латунними з\'єднаннями. Стійкий до заломів та захищений від УФ.', 'шланг, сад, гнучкий, полив', 'Гнучкий садовий шланг', '50-футовий гнучкий садовий шланг з латунними з\'єднаннями', 'садовий шланг');

-- Insert product to category relationships
INSERT INTO oc_product_to_category (product_id, category_id, main_category) VALUES
(1, 1, 1), (2, 1, 1), (3, 3, 1), (4, 5, 1), (5, 5, 1);

-- Insert featured products (every 5th product)
INSERT INTO oc_product_featured (product_id) VALUES (5);

-- Insert attributes
INSERT INTO oc_attribute (attribute_id, attribute_group_id, sort_order) VALUES
(1, 1, 1), (2, 1, 2), (3, 1, 3), (4, 1, 4);

-- Insert attribute descriptions (English)
INSERT INTO oc_attribute_description (attribute_id, language_id, name) VALUES
(1, 1, 'Material'), (2, 1, 'Color'), (3, 1, 'Size'), (4, 1, 'Brand');

-- Insert attribute descriptions (Ukrainian)
INSERT INTO oc_attribute_description (attribute_id, language_id, name) VALUES
(1, 2, 'Матеріал'), (2, 2, 'Колір'), (3, 2, 'Розмір'), (4, 2, 'Бренд');

-- Insert banners
INSERT INTO oc_banner (banner_id, name, status) VALUES (1, 'Homepage Banner', 1);

-- Insert banner images (English)
INSERT INTO oc_banner_image (banner_image_id, banner_id, language_id, title, link, image, sort_order) VALUES
(1, 1, 1, 'Welcome to Our Garden Store', '/', 'catalog/product/photo_1@28-05-2020_21-00-01.jpg', 1),
(2, 1, 1, 'Quality Garden Tools', '/index.php?route=product/category&path=1', 'catalog/product/photo_2@28-05-2020_21-14-13.jpg', 2),
(3, 1, 1, 'Beautiful Plants', '/index.php?route=product/category&path=3', 'catalog/product/photo_3@28-05-2020_21-24-27.jpg', 3),
(4, 1, 1, 'Outdoor Furniture', '/index.php?route=product/category&path=2', 'catalog/product/photo_4@30-06-2020_12-25-14.jpg', 4);

-- Insert banner images (Ukrainian)
INSERT INTO oc_banner_image (banner_image_id, banner_id, language_id, title, link, image, sort_order) VALUES
(5, 1, 2, 'Ласкаво просимо до нашого садового магазину', '/', 'catalog/product/photo_1@28-05-2020_21-00-01.jpg', 1),
(6, 1, 2, 'Якісні садові інструменти', '/index.php?route=product/category&path=1', 'catalog/product/photo_2@28-05-2020_21-14-13.jpg', 2),
(7, 1, 2, 'Красиві рослини', '/index.php?route=product/category&path=3', 'catalog/product/photo_3@28-05-2020_21-24-27.jpg', 3),
(8, 1, 2, 'Садові меблі', '/index.php?route=product/category&path=2', 'catalog/product/photo_4@30-06-2020_12-25-14.jpg', 4);