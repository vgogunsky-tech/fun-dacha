#!/usr/bin/env python3
import csv
from collections import defaultdict
from pathlib import Path

INVENTORY_PATH = Path('data/inventory.csv')
OUT_SQL = Path('inventory_options.sql')

SMALL_UA = 'Маленький пакет'
MEDIUM_UA = 'Середній пакет'
LARGE_UA = 'Великий пакет'

SMALL_RU = 'Маленький  пакет'
MEDIUM_RU = 'Средний  пакет'
LARGE_RU = 'Большой  пакет'

LANG_UA = 2
LANG_RU = 3

HEADERS_REQUIRED = {
	'product_id', 'title_ua', 'title_ru', 'original_price', 'stock_qty'
}


def load_inventory():
	if not INVENTORY_PATH.exists():
		raise SystemExit('data/inventory.csv not found')
	with INVENTORY_PATH.open('r', encoding='utf-8') as f:
		reader = csv.DictReader(f)
		missing = HEADERS_REQUIRED - set(reader.fieldnames or [])
		if missing:
			raise SystemExit(f'inventory.csv missing columns: {missing}')
		by_prod = defaultdict(list)
		for row in reader:
			pid = (row.get('product_id') or '').strip()
			if not pid:
				continue
			by_prod[pid].append(row)
		return by_prod


def write_sql(by_prod):
	lines = []
	lines.append("USE opencart;\n")

	# Ensure single option 'Пакет' exists and get @opt_id
	lines += [
		"-- Ensure option 'Пакет' exists and capture @opt_id",
		"SET @opt_id := (SELECT option_id FROM oc_option_description WHERE name='Пакет' LIMIT 1);",
		"INSERT INTO oc_option (type, sort_order) SELECT 'select', 0 FROM DUAL WHERE @opt_id IS NULL;",
		"SET @opt_id := IFNULL(@opt_id, LAST_INSERT_ID());",
		f"INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, {LANG_UA}, 'Пакет');",
		f"INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, {LANG_RU}, 'Пакет');",
		"",
		"-- Ensure option values exist and capture their ids",
		f"SET @ov_small := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name='{SMALL_UA}' LIMIT 1);",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 1 FROM DUAL WHERE @ov_small IS NULL;",
		"SET @ov_small := IFNULL(@ov_small, LAST_INSERT_ID());",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, {LANG_UA}, @opt_id, '{SMALL_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, {LANG_RU}, @opt_id, '{SMALL_RU}');",
		"",
		f"SET @ov_medium := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name='{MEDIUM_UA}' LIMIT 1);",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 2 FROM DUAL WHERE @ov_medium IS NULL;",
		"SET @ov_medium := IFNULL(@ov_medium, LAST_INSERT_ID());",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, {LANG_UA}, @opt_id, '{MEDIUM_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, {LANG_RU}, @opt_id, '{MEDIUM_RU}');",
		"",
		f"SET @ov_large := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name='{LARGE_UA}' LIMIT 1);",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 3 FROM DUAL WHERE @ov_large IS NULL;",
		"SET @ov_large := IFNULL(@ov_large, LAST_INSERT_ID());",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, {LANG_UA}, @opt_id, '{LARGE_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, {LANG_RU}, @opt_id, '{LARGE_RU}');",
		""
	]

	# Per product, attach option and values with prices
	def parse_price(s):
		try:
			return float(s)
		except:
			return 0.0

	for model, variants in by_prod.items():
		lines += [
			f"-- Attach options for product model={model}",
			f"SET @pid := (SELECT product_id FROM oc_product WHERE model='{model}' LIMIT 1);",
			"-- Ensure product option exists",
			"INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);",
			"SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);",
			"-- Clear previous values for clean reattach",
			"DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;",
		]

		present = {}
		for v in variants:
			tua = (v.get('title_ua') or '').strip()
			price = parse_price(v.get('original_price'))
			qty = 0
			try:
				qty = int((v.get('stock_qty') or '0') or 0)
			except:
				qty = 0
			present[tua] = (price, qty)

		pairs = [
			(SMALL_UA, '@ov_small'),
			(MEDIUM_UA, '@ov_medium'),
			(LARGE_UA, '@ov_large'),
		]
		for name, ov_var in pairs:
			price, qty = present.get(name, (0.0, 0))
			must_have = name in (SMALL_UA, LARGE_UA)
			cond = " OR 1=1" if must_have else ""
			# Insert only if poid resolved and (present or must_have)
			lines.append(
				f"INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) "
				f"SELECT @poid, @pid, @opt_id, {ov_var}, {max(qty,0)}, 1, {price:.2f}, '=', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE {1 if name in present else 0}=1){cond});"
			)
		lines.append("")

	OUT_SQL.write_text("\n".join(lines), encoding='utf-8')
	print(f"Wrote SQL to {OUT_SQL}")


def main():
	by_prod = load_inventory()
	write_sql(by_prod)

if __name__ == '__main__':
	main()