-- Simple Language Setup for OpenCart
-- This script adds Ukrainian and Russian languages without problematic columns

USE opencart;

-- Check if languages already exist and add them if they don't
INSERT IGNORE INTO oc_language (language_id, name, code, locale, directory, sort_order, status) 
VALUES (2, 'Українська', 'ua', 'ua_UA.UTF-8', 'ukrainian', 2, 1);

INSERT IGNORE INTO oc_language (language_id, name, code, locale, directory, sort_order, status) 
VALUES (3, 'Русский', 'ru', 'ru_RU.UTF-8', 'russian', 3, 1);

-- Ensure English is language_id = 1
UPDATE oc_language SET language_id = 1, sort_order = 1 WHERE code = 'en' AND language_id != 1;

-- Set default language to Ukrainian
INSERT IGNORE INTO oc_setting (store_id, code, `key`, value, serialized) VALUES
(0, 'config', 'config_language', '2', 0);

-- Verify language setup
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;