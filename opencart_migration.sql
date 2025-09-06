-- OpenCart Database Migration SQL
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

CREATE TABLE IF NOT EXISTS oc_product_attribute (
    product_id int(11) NOT NULL,
    attribute_id int(11) NOT NULL,
    language_id int(11) NOT NULL,
    text text NOT NULL,
    PRIMARY KEY (product_id, attribute_id, language_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert categories
INSERT INTO oc_category (category_id, image, parent_id, top, `column`, sort_order, status, date_added, date_modified) VALUES
(1, '', 0, 1, 1, 1, 1, NOW(), NOW()),
(2, '', 0, 1, 1, 2, 1, NOW(), NOW()),
(3, '', 0, 1, 1, 3, 1, NOW(), NOW()),
(4, '', 0, 1, 1, 4, 1, NOW(), NOW()),
(5, '', 0, 1, 1, 5, 1, NOW(), NOW()),
(6, '', 0, 1, 1, 6, 1, NOW(), NOW()),
(7, '', 0, 1, 1, 7, 1, NOW(), NOW()),
(8, '', 0, 1, 1, 8, 1, NOW(), NOW()),
(9, '', 0, 1, 1, 9, 1, NOW(), NOW()),
(10, '', 0, 1, 1, 10, 1, NOW(), NOW()),
(11, '', 0, 1, 1, 11, 1, NOW(), NOW()),
(12, '', 0, 1, 1, 12, 1, NOW(), NOW()),
(13, '', 0, 1, 1, 13, 1, NOW(), NOW()),
(14, '', 0, 1, 1, 14, 1, NOW(), NOW()),
(15, '', 0, 1, 1, 15, 1, NOW(), NOW()),
(16, '', 0, 1, 1, 16, 1, NOW(), NOW()),
(17, '', 0, 1, 1, 17, 1, NOW(), NOW()),
(18, '', 0, 1, 1, 18, 1, NOW(), NOW()),
(19, '', 0, 1, 1, 19, 1, NOW(), NOW()),
(20, '', 0, 1, 1, 20, 1, NOW(), NOW()),
(21, '', 0, 1, 1, 21, 1, NOW(), NOW()),
(22, '', 0, 1, 1, 22, 1, NOW(), NOW()),
(23, '', 0, 1, 1, 23, 1, NOW(), NOW()),
(24, '', 0, 1, 1, 24, 1, NOW(), NOW()),
(25, '', 0, 1, 1, 25, 1, NOW(), NOW()),
(26, '', 0, 1, 1, 26, 1, NOW(), NOW()),
(27, '', 0, 1, 1, 27, 1, NOW(), NOW()),
(28, '', 0, 1, 1, 28, 1, NOW(), NOW()),
(29, '', 0, 1, 1, 29, 1, NOW(), NOW()),
(30, '', 0, 1, 1, 30, 1, NOW(), NOW()),
(31, '', 0, 1, 1, 31, 1, NOW(), NOW()),
(32, '', 0, 1, 1, 32, 1, NOW(), NOW()),
(33, '', 0, 1, 1, 33, 1, NOW(), NOW()),
(34, '', 0, 1, 1, 34, 1, NOW(), NOW()),
(35, '', 0, 1, 1, 35, 1, NOW(), NOW()),
(36, '', 0, 1, 1, 36, 1, NOW(), NOW()),
(37, '', 0, 1, 1, 37, 1, NOW(), NOW());

-- Insert category descriptions (English)
INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES
(1, 1, 'Garden Tools', 'Essential tools for gardening and yard work', 'Garden Tools', 'Essential tools for gardening and yard work', 'garden tools'),
(2, 1, 'Outdoor Furniture', 'Comfortable furniture for outdoor spaces', 'Outdoor Furniture', 'Comfortable furniture for outdoor spaces', 'outdoor furniture'),
(3, 1, 'Plant Care', 'Products for plant maintenance and care', 'Plant Care', 'Products for plant maintenance and care', 'plant care'),
(4, 1, 'Lawn Care', 'Equipment and supplies for lawn maintenance', 'Lawn Care', 'Equipment and supplies for lawn maintenance', 'lawn care'),
(5, 1, 'Watering Systems', 'Irrigation and watering solutions', 'Watering Systems', 'Irrigation and watering solutions', 'watering systems'),
(6, 1, 'Decorative Items', 'Beautiful decorations for outdoor spaces', 'Decorative Items', 'Beautiful decorations for outdoor spaces', 'decorative items'),
(7, 1, 'Lighting', 'Outdoor lighting solutions', 'Lighting', 'Outdoor lighting solutions', 'lighting'),
(8, 1, 'Storage Solutions', 'Storage options for outdoor equipment', 'Storage Solutions', 'Storage options for outdoor equipment', 'storage solutions'),
(9, 1, 'Pest Control', 'Products for pest management', 'Pest Control', 'Products for pest management', 'pest control'),
(10, 1, 'Soil & Fertilizers', 'Soil amendments and plant nutrition', 'Soil & Fertilizers', 'Soil amendments and plant nutrition', 'soil fertilizers'),
(11, 1, 'Seeds & Plants', 'Seeds and live plants for your garden', 'Seeds & Plants', 'Seeds and live plants for your garden', 'seeds plants'),
(12, 1, 'Garden Structures', 'Structures like greenhouses and sheds', 'Garden Structures', 'Structures like greenhouses and sheds', 'garden structures'),
(13, 1, 'Composting', 'Composting bins and accessories', 'Composting', 'Composting bins and accessories', 'composting'),
(14, 1, 'Garden Art', 'Artistic elements for garden decoration', 'Garden Art', 'Artistic elements for garden decoration', 'garden art'),
(15, 1, 'Seasonal Items', 'Items for different seasons', 'Seasonal Items', 'Items for different seasons', 'seasonal items'),
(16, 1, 'Pet Supplies', 'Supplies for garden pets', 'Pet Supplies', 'Supplies for garden pets', 'pet supplies'),
(17, 1, 'Safety Equipment', 'Safety gear for outdoor work', 'Safety Equipment', 'Safety gear for outdoor work', 'safety equipment'),
(18, 1, 'Garden Books', 'Books and guides for gardening', 'Garden Books', 'Books and guides for gardening', 'garden books'),
(19, 1, 'Gift Items', 'Gift ideas for garden enthusiasts', 'Gift Items', 'Gift ideas for garden enthusiasts', 'gift items'),
(20, 1, 'Specialty Tools', 'Specialized gardening tools', 'Specialty Tools', 'Specialized gardening tools', 'specialty tools'),
(21, 1, 'Water Features', 'Fountains and water decorations', 'Water Features', 'Fountains and water decorations', 'water features'),
(22, 1, 'Garden Maintenance', 'Maintenance supplies and tools', 'Garden Maintenance', 'Maintenance supplies and tools', 'garden maintenance'),
(23, 1, 'Outdoor Cooking', 'Cooking equipment for outdoor use', 'Outdoor Cooking', 'Cooking equipment for outdoor use', 'outdoor cooking'),
(24, 1, 'Garden Accessories', 'Various garden accessories', 'Garden Accessories', 'Various garden accessories', 'garden accessories'),
(25, 1, 'Planters & Pots', 'Containers for plants', 'Planters & Pots', 'Containers for plants', 'planters pots'),
(26, 1, 'Garden Edging', 'Edging materials for garden beds', 'Garden Edging', 'Edging materials for garden beds', 'garden edging'),
(27, 1, 'Mulch & Ground Cover', 'Ground covering materials', 'Mulch & Ground Cover', 'Ground covering materials', 'mulch ground cover'),
(28, 1, 'Garden Markers', 'Markers and labels for plants', 'Garden Markers', 'Markers and labels for plants', 'garden markers'),
(29, 1, 'Weather Protection', 'Protection from weather elements', 'Weather Protection', 'Protection from weather elements', 'weather protection'),
(30, 1, 'Garden Games', 'Games and activities for outdoor fun', 'Garden Games', 'Games and activities for outdoor fun', 'garden games'),
(31, 1, 'Wildlife Care', 'Products for attracting and caring for wildlife', 'Wildlife Care', 'Products for attracting and caring for wildlife', 'wildlife care'),
(32, 1, 'Garden Technology', 'Technology solutions for gardens', 'Garden Technology', 'Technology solutions for gardens', 'garden technology'),
(33, 1, 'Seasonal Decorations', 'Decorations for different seasons', 'Seasonal Decorations', 'Decorations for different seasons', 'seasonal decorations'),
(34, 1, 'Garden Pathways', 'Materials for garden paths', 'Garden Pathways', 'Materials for garden paths', 'garden pathways'),
(35, 1, 'Garden Screening', 'Screening and privacy solutions', 'Garden Screening', 'Screening and privacy solutions', 'garden screening'),
(36, 1, 'Garden Irrigation', 'Advanced irrigation systems', 'Garden Irrigation', 'Advanced irrigation systems', 'garden irrigation'),
(37, 1, 'Garden Tools Storage', 'Storage solutions for garden tools', 'Garden Tools Storage', 'Storage solutions for garden tools', 'garden tools storage');

-- Insert category descriptions (Ukrainian)
INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES
(1, 2, 'Садові інструменти', 'Основні інструменти для садівництва та роботи в дворі', 'Садові інструменти', 'Основні інструменти для садівництва та роботи в дворі', 'садові інструменти'),
(2, 2, 'Садові меблі', 'Зручні меблі для відкритих просторів', 'Садові меблі', 'Зручні меблі для відкритих просторів', 'садові меблі'),
(3, 2, 'Догляд за рослинами', 'Товари для обслуговування та догляду за рослинами', 'Догляд за рослинами', 'Товари для обслуговування та догляду за рослинами', 'догляд за рослинами'),
(4, 2, 'Догляд за газоном', 'Обладнання та приналежності для обслуговування газону', 'Догляд за газоном', 'Обладнання та приналежності для обслуговування газону', 'догляд за газоном'),
(5, 2, 'Системи поливу', 'Рішення для зрошення та поливу', 'Системи поливу', 'Рішення для зрошення та поливу', 'системи поливу'),
(6, 2, 'Декоративні предмети', 'Красиві прикраси для відкритих просторів', 'Декоративні предмети', 'Красиві прикраси для відкритих просторів', 'декоративні предмети'),
(7, 2, 'Освітлення', 'Рішення для зовнішнього освітлення', 'Освітлення', 'Рішення для зовнішнього освітлення', 'освітлення'),
(8, 2, 'Рішення для зберігання', 'Варіанти зберігання для зовнішнього обладнання', 'Рішення для зберігання', 'Варіанти зберігання для зовнішнього обладнання', 'рішення для зберігання'),
(9, 2, 'Боротьба зі шкідниками', 'Товари для боротьби зі шкідниками', 'Боротьба зі шкідниками', 'Товари для боротьби зі шкідниками', 'боротьба зі шкідниками'),
(10, 2, 'Грунт та добрива', 'Покращення грунту та живлення рослин', 'Грунт та добрива', 'Покращення грунту та живлення рослин', 'грунт добрива'),
(11, 2, 'Насіння та рослини', 'Насіння та живі рослини для вашого саду', 'Насіння та рослини', 'Насіння та живі рослини для вашого саду', 'насіння рослини'),
(12, 2, 'Садові споруди', 'Споруди як теплиці та сараї', 'Садові споруди', 'Споруди як теплиці та сараї', 'садові споруди'),
(13, 2, 'Компостування', 'Контейнери для компосту та аксесуари', 'Компостування', 'Контейнери для компосту та аксесуари', 'компостування'),
(14, 2, 'Садове мистецтво', 'Художні елементи для прикраси саду', 'Садове мистецтво', 'Художні елементи для прикраси саду', 'садове мистецтво'),
(15, 2, 'Сезонні товари', 'Товари для різних сезонів', 'Сезонні товари', 'Товари для різних сезонів', 'сезонні товари'),
(16, 2, 'Товари для тварин', 'Приналежності для садових тварин', 'Товари для тварин', 'Приналежності для садових тварин', 'товари для тварин'),
(17, 2, 'Засоби безпеки', 'Засоби захисту для роботи на відкритому повітрі', 'Засоби безпеки', 'Засоби захисту для роботи на відкритому повітрі', 'засоби безпеки'),
(18, 2, 'Садові книги', 'Книги та посібники з садівництва', 'Садові книги', 'Книги та посібники з садівництва', 'садові книги'),
(19, 2, 'Подарункові товари', 'Ідеї подарунків для любителів саду', 'Подарункові товари', 'Ідеї подарунків для любителів саду', 'подарункові товари'),
(20, 2, 'Спеціальні інструменти', 'Спеціалізовані садові інструменти', 'Спеціальні інструменти', 'Спеціалізовані садові інструменти', 'спеціальні інструменти'),
(21, 2, 'Водні об\'єкти', 'Фонтани та водні прикраси', 'Водні об\'єкти', 'Фонтани та водні прикраси', 'водні об\'єкти'),
(22, 2, 'Обслуговування саду', 'Приналежності та інструменти для обслуговування', 'Обслуговування саду', 'Приналежності та інструменти для обслуговування', 'обслуговування саду'),
(23, 2, 'Зовнішнє приготування їжі', 'Кухонне обладнання для зовнішнього використання', 'Зовнішнє приготування їжі', 'Кухонне обладнання для зовнішнього використання', 'зовнішнє приготування їжі'),
(24, 2, 'Садові аксесуари', 'Різні садові аксесуари', 'Садові аксесуари', 'Різні садові аксесуари', 'садові аксесуари'),
(25, 2, 'Горщики та кашпо', 'Контейнери для рослин', 'Горщики та кашпо', 'Контейнери для рослин', 'горщики кашпо'),
(26, 2, 'Садове обмеження', 'Матеріали для обмеження садових ділянок', 'Садове обмеження', 'Матеріали для обмеження садових ділянок', 'садове обмеження'),
(27, 2, 'Мульча та покриття', 'Матеріали для покриття ґрунту', 'Мульча та покриття', 'Матеріали для покриття ґрунту', 'мульча покриття'),
(28, 2, 'Садові маркери', 'Маркери та етикетки для рослин', 'Садові маркери', 'Маркери та етикетки для рослин', 'садові маркери'),
(29, 2, 'Захист від погоди', 'Захист від погодних умов', 'Захист від погоди', 'Захист від погодних умов', 'захист від погоди'),
(30, 2, 'Садові ігри', 'Ігри та активності для веселощів на відкритому повітрі', 'Садові ігри', 'Ігри та активності для веселощів на відкритому повітрі', 'садові ігри'),
(31, 2, 'Догляд за дикою природою', 'Товари для залучення та догляду за дикою природою', 'Догляд за дикою природою', 'Товари для залучення та догляду за дикою природою', 'догляд за дикою природою'),
(32, 2, 'Садова технологія', 'Технологічні рішення для садів', 'Садова технологія', 'Технологічні рішення для садів', 'садова технологія'),
(33, 2, 'Сезонні прикраси', 'Прикраси для різних сезонів', 'Сезонні прикраси', 'Прикраси для різних сезонів', 'сезонні прикраси'),
(34, 2, 'Садові доріжки', 'Матеріали для садових доріжок', 'Садові доріжки', 'Матеріали для садових доріжок', 'садові доріжки'),
(35, 2, 'Садове екранування', 'Рішення для екранування та приватності', 'Садове екранування', 'Рішення для екранування та приватності', 'садове екранування'),
(36, 2, 'Садове зрошення', 'Розширені системи зрошення', 'Садове зрошення', 'Розширені системи зрошення', 'садове зрошення'),
(37, 2, 'Зберігання садових інструментів', 'Рішення для зберігання садових інструментів', 'Зберігання садових інструментів', 'Рішення для зберігання садових інструментів', 'зберігання садових інструментів');

-- Insert category paths
INSERT INTO oc_category_path (category_id, path_id, level) VALUES
(1, 1, 0), (2, 2, 0), (3, 3, 0), (4, 4, 0), (5, 5, 0), (6, 6, 0), (7, 7, 0), (8, 8, 0), (9, 9, 0), (10, 10, 0),
(11, 11, 0), (12, 12, 0), (13, 13, 0), (14, 14, 0), (15, 15, 0), (16, 16, 0), (17, 17, 0), (18, 18, 0), (19, 19, 0), (20, 20, 0),
(21, 21, 0), (22, 22, 0), (23, 23, 0), (24, 24, 0), (25, 25, 0), (26, 26, 0), (27, 27, 0), (28, 28, 0), (29, 29, 0), (30, 30, 0),
(31, 31, 0), (32, 32, 0), (33, 33, 0), (34, 34, 0), (35, 35, 0), (36, 36, 0), (37, 37, 0);