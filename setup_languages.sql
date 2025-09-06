-- Setup Ukrainian and Russian Languages for OpenCart
-- This script adds proper language support to OpenCart

USE opencart;

-- Add Ukrainian language (language_id = 2)
INSERT IGNORE INTO oc_language (language_id, name, code, locale, image, directory, sort_order, status) 
VALUES (2, 'Українська', 'ua', 'ua_UA.UTF-8', 'ua.png', 'ukrainian', 2, 1);

-- Add Russian language (language_id = 3) 
INSERT IGNORE INTO oc_language (language_id, name, code, locale, image, directory, sort_order, status) 
VALUES (3, 'Русский', 'ru', 'ru_RU.UTF-8', 'ru.png', 'russian', 3, 1);

-- Update English language to be language_id = 1 (if not already)
UPDATE oc_language SET language_id = 1, sort_order = 1 WHERE code = 'en' AND language_id != 1;

-- Ensure we have the correct language IDs
-- Ukrainian = 2, Russian = 3, English = 1

-- Update store settings to support multiple languages
UPDATE oc_setting SET value = '1,2,3' WHERE `key` = 'config_language' AND store_id = 0;
UPDATE oc_setting SET value = '2' WHERE `key` = 'config_admin_language' AND store_id = 0;

-- Add language-specific store settings
INSERT IGNORE INTO oc_setting (store_id, code, `key`, value, serialized) VALUES
(0, 'config', 'config_language', '2', 0),  -- Default to Ukrainian
(0, 'config', 'config_admin_language', '2', 0);

-- Update existing product descriptions to ensure proper language mapping
-- Ukrainian descriptions (language_id = 2)
UPDATE oc_product_description SET language_id = 2 WHERE language_id = 1 AND name LIKE '%укр%';

-- Russian descriptions (language_id = 3) 
UPDATE oc_product_description SET language_id = 3 WHERE language_id = 1 AND name LIKE '%рус%';

-- Update existing category descriptions to ensure proper language mapping
-- Ukrainian descriptions (language_id = 2)
UPDATE oc_category_description SET language_id = 2 WHERE language_id = 1 AND name LIKE '%укр%';

-- Russian descriptions (language_id = 3)
UPDATE oc_category_description SET language_id = 3 WHERE language_id = 1 AND name LIKE '%рус%';

-- Update existing attribute descriptions to ensure proper language mapping
-- Ukrainian descriptions (language_id = 2)
UPDATE oc_attribute_description SET language_id = 2 WHERE language_id = 1 AND name LIKE '%укр%';

-- Russian descriptions (language_id = 3)
UPDATE oc_attribute_description SET language_id = 3 WHERE language_id = 1 AND name LIKE '%рус%';

-- Add language-specific information pages
INSERT IGNORE INTO oc_information_description (information_id, language_id, title, description, meta_title, meta_description, meta_keyword) VALUES
(1, 2, 'Про нас', 'Інформація про наш магазин', 'Про нас', 'Інформація про наш магазин', 'про нас, інформація'),
(1, 3, 'О нас', 'Информация о нашем магазине', 'О нас', 'Информация о нашем магазине', 'о нас, информация'),
(2, 2, 'Політика конфіденційності', 'Політика конфіденційності нашого магазину', 'Політика конфіденційності', 'Політика конфіденційності нашого магазину', 'політика, конфіденційність'),
(2, 3, 'Политика конфиденциальности', 'Политика конфиденциальности нашего магазина', 'Политика конфиденциальности', 'Политика конфиденциальности нашего магазина', 'политика, конфиденциальность'),
(3, 2, 'Умови використання', 'Умови використання нашого магазину', 'Умови використання', 'Умови використання нашого магазину', 'умови, використання'),
(3, 3, 'Условия использования', 'Условия использования нашего магазина', 'Условия использования', 'Условия использования нашего магазина', 'условия, использование');

-- Add language-specific store information
INSERT IGNORE INTO oc_setting (store_id, code, `key`, value, serialized) VALUES
(0, 'config', 'config_name_2', 'Фун-дача', 0),  -- Ukrainian store name
(0, 'config', 'config_name_3', 'Фун-дача', 0),  -- Russian store name
(0, 'config', 'config_owner_2', 'Фун-дача', 0),  -- Ukrainian owner name
(0, 'config', 'config_owner_3', 'Фун-дача', 0),  -- Russian owner name
(0, 'config', 'config_address_2', 'Україна', 0),  -- Ukrainian address
(0, 'config', 'config_address_3', 'Украина', 0),  -- Russian address
(0, 'config', 'config_meta_title_2', 'Фун-дача - Сімена та садівництво', 0),  -- Ukrainian meta title
(0, 'config', 'config_meta_title_3', 'Фун-дача - Семена и садоводство', 0),  -- Russian meta title
(0, 'config', 'config_meta_description_2', 'Інтернет-магазин сімен та садівничих товарів', 0),  -- Ukrainian meta description
(0, 'config', 'config_meta_description_3', 'Интернет-магазин семян и садоводческих товаров', 0);  -- Russian meta description

-- Verify language setup
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;

SELECT 'Store settings updated:' as status;
SELECT `key`, value FROM oc_setting WHERE `key` LIKE '%language%' AND store_id = 0;