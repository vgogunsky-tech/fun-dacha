#!/usr/bin/env python3
import csv
from pathlib import Path

LIST_PATH = Path('data/list.csv')
OUT_PATH = Path('data/inventory.csv')

HEADERS = [
	'id', 'pid', 'product_id', 'top_availability', 'variant_id', 'title_ua', 'title_ru',
	'original_price', 'sale_price', 'currency', 'stock_qty', 'value', 'unit', 'type',
	'values_json', 'availability'
]

SMALL_UA = 'Маленький пакет'
SMALL_RU = 'Маленький  пакет'
MEDIUM_UA = 'Середній пакет'
MEDIUM_RU = 'Средний  пакет'
LARGE_UA = 'Великий пакет'
LARGE_RU = 'Большой  пакет'

SMALL_PRICE = 10.0
MEDIUM_PRICE = 15.0
LARGE_PRICE = 20.0
SALE_PRICE_FOR_CAT100 = 8.0
CURRENCY = 'UAH'
DEFAULT_STOCK = 100

# Products whose primary category_id in [100..200] get quantity template (20 pcs)
# Others get weight template (3 gr)

def should_use_quantity_template(category_id: int) -> bool:
	return 100 <= category_id <= 200


def pick_has_third_option(product_index_in_cat100: int) -> bool:
	# Select some products in 100 to have third option deterministically: every 3rd product
	return (product_index_in_cat100 % 3) == 0


def main():
	if not LIST_PATH.exists():
		raise SystemExit('data/list.csv not found')

	with LIST_PATH.open('r', encoding='utf-8') as f:
		reader = csv.DictReader(f)
		rows = list(reader)

	out_rows = []
	row_id = 1
	cat100_counter = 0
	pid_counter = 1

	for row in rows:
		product_id = row.get('product_id', '').strip()
		if not product_id:
			continue
		try:
			cat_id = int(row.get('category_id') or 0)
		except ValueError:
			cat_id = 0

		use_qty = should_use_quantity_template(cat_id)
		value = 20.0 if use_qty else 3.0
		unit = 'pcs' if use_qty else 'gr'
		type_field = 'quantity' if use_qty else 'weight'

		# Determine sale price applicability
		sale_price = SALE_PRICE_FOR_CAT100 if cat_id == 100 else ''

		# Build two mandatory options
		# SMALL
		out_rows.append({
			'id': str(row_id),
			'pid': str(pid_counter),
			'product_id': product_id,
			'top_availability': '',
			'variant_id': f"{product_id.upper()}-S",
			'title_ua': SMALL_UA,
			'title_ru': SMALL_RU,
			'original_price': f"{SMALL_PRICE}",
			'sale_price': f"{sale_price}" if sale_price != '' else '',
			'currency': CURRENCY,
			'stock_qty': str(DEFAULT_STOCK),
			'value': f"{value}",
			'unit': unit,
			'type': type_field,
			'values_json': '',
			'availability': ''
		})
		row_id += 1

		# LARGE
		out_rows.append({
			'id': str(row_id),
			'pid': str(pid_counter),
			'product_id': product_id,
			'top_availability': '',
			'variant_id': f"{product_id.upper()}-L",
			'title_ua': LARGE_UA,
			'title_ru': LARGE_RU,
			'original_price': f"{LARGE_PRICE}",
			'sale_price': f"{sale_price}" if sale_price != '' else '',
			'currency': CURRENCY,
			'stock_qty': str(DEFAULT_STOCK),
			'value': f"{value}",
			'unit': unit,
			'type': type_field,
			'values_json': '',
			'availability': ''
		})
		row_id += 1

		# Optional third option for some products in category 100
		if cat_id == 100:
			if pick_has_third_option(cat100_counter):
				out_rows.append({
					'id': str(row_id),
					'pid': str(pid_counter),
					'product_id': product_id,
					'top_availability': '',
					'variant_id': f"{product_id.upper()}-M",
					'title_ua': MEDIUM_UA,
					'title_ru': MEDIUM_RU,
					'original_price': f"{MEDIUM_PRICE}",
					'sale_price': f"{SALE_PRICE_FOR_CAT100}",
					'currency': CURRENCY,
					'stock_qty': str(DEFAULT_STOCK),
					'value': f"{value}",
					'unit': unit,
					'type': type_field,
					'values_json': '',
					'availability': ''
				})
				row_id += 1
			cat100_counter += 1

		pid_counter += 1

	# Write output
	OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
	with OUT_PATH.open('w', encoding='utf-8', newline='') as f:
		writer = csv.DictWriter(f, fieldnames=HEADERS)
		writer.writeheader()
		for r in out_rows:
			writer.writerow(r)

	print(f"Generated {len(out_rows)} inventory rows for {pid_counter-1} products → {OUT_PATH}")

if __name__ == '__main__':
	main()