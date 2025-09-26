#!/usr/bin/env python3
import argparse
import csv
import json
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import pymysql
import time


def read_csv(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def parse_float(s: Optional[str], default: float = 0.0) -> float:
    if s is None:
        return default
    raw = str(s).strip()
    if raw == "":
        return default
    raw = raw.replace("гр", "").replace("грн", "").replace("UAH", "")
    raw = raw.replace(" ", "")
    if raw.count(",") == 1 and raw.count(".") == 0:
        raw = raw.replace(",", ".")
    raw = raw.replace(",", "")
    try:
        return float(raw)
    except Exception:
        m = re.search(r"[-+]?[0-9]*\.?[0-9]+", raw)
        if m:
            try:
                return float(m.group(0))
            except Exception:
                return default
        return default


def parse_int(s: Optional[str], default: int = 0) -> int:
    if s is None:
        return default
    raw = str(s).strip()
    if raw == "":
        return default
    raw = re.sub(r"[^0-9-]+", "", raw)
    try:
        return int(raw)
    except Exception:
        return default


def gram_value_to_kg(value_str: Optional[str], unit: Optional[str]) -> float:
    if value_str is None:
        return 0.0
    try:
        v = float(value_str)
    except Exception:
        return 0.0
    u = (unit or "").strip().lower()
    if u in {"g", "gram", "grams", "гр", "г"}:
        return v / 1000.0
    if u in {"kg", "kgs", "килограмм", "кг"}:
        return v
    return 0.0


def get_language_ids(cur) -> (int, int):
    cur.execute("SELECT language_id, code FROM oc_language")
    code_to_id = {code: lid for (lid, code) in cur.fetchall()}
    ua_id = code_to_id.get("uk") or code_to_id.get("uk-ua") or next(iter(code_to_id.values()), 1)
    ru_id = code_to_id.get("ru") or code_to_id.get("ru-ru") or ua_id
    return int(ua_id), int(ru_id)


def unique_lang_ids(ua_id: int, ru_id: int) -> List[int]:
    return list(dict.fromkeys([ua_id, ru_id]))


def clean_db(conn):
    cur = conn.cursor()
    cur.execute("SET FOREIGN_KEY_CHECKS=0")
    tables = [
        "oc_product_option_value",
        "oc_product_option",
        "oc_option_value_description",
        "oc_option_value",
        "oc_option_description",
        "oc_option",
        "oc_product_attribute",
        "oc_attribute_description",
        "oc_attribute",
        "oc_attribute_group_description",
        "oc_attribute_group",
        "oc_product_image",
        "oc_product_to_category",
        "oc_product_description",
        "oc_product",
        "oc_category_description",
        "oc_category",
    ]
    for t in tables:
        cur.execute(f"TRUNCATE {t}")
    cur.execute("SET FOREIGN_KEY_CHECKS=1")
    conn.commit()


def get_table_columns(cur, table: str) -> List[str]:
    cur.execute(f"SHOW COLUMNS FROM {table}")
    return [r[0] for r in cur.fetchall()]


def build_upsert_sql(table: str, available_cols: Sequence[str], data: Dict[str, object], pk_cols: Sequence[str]) -> Tuple[str, List[object]]:
    cols = [c for c in data.keys() if c in available_cols]
    if not cols:
        raise ValueError(f"No valid columns to insert for {table}")
    placeholders = ["%s"] * len(cols)
    values = [data[c] for c in cols]
    upd_cols = [c for c in cols if c not in pk_cols]
    if upd_cols:
        set_clause = ", ".join([f"{c}=VALUES({c})" for c in upd_cols])
        sql = f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({', '.join(placeholders)}) ON DUPLICATE KEY UPDATE {set_clause}"
    else:
        sql = f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({', '.join(placeholders)})"
    return sql, values


def ensure_category(cur, row, table_cols_cache: Dict[str, List[str]]) -> None:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    category_id = int((row.get("id") or "0").strip() or 0)
    parent_id_raw = (row.get("parentId") or "").strip()
    parent_id = int(parent_id_raw) if parent_id_raw else 0
    image = (row.get("primary_image") or "").strip()
    image_path = f"catalog/category/{image}" if image else None
    top = 1 if not parent_id else 0
    cat_cols = table_cols_cache.setdefault("oc_category", get_table_columns(cur, "oc_category"))
    data = {
        "category_id": category_id,
        "image": image_path,
        "parent_id": parent_id,
        "top": top,
        "column": 1,
        "sort_order": 0,
        "status": 1,
        "date_added": now,
        "date_modified": now,
    }
    sql, vals = build_upsert_sql("oc_category", cat_cols, data, pk_cols=["category_id"])
    cur.execute(sql, vals)


def ensure_category_descriptions(cur, row, ua_id, ru_id, table_cols_cache: Dict[str, List[str]]) -> None:
    category_id = int(row.get("id") or 0)
    name_ua = (row.get("name") or "").strip()
    desc_ua = (row.get("description (ukr)") or "").strip()
    tag = (row.get("tag") or "").strip()
    desc_cols = table_cols_cache.setdefault("oc_category_description", get_table_columns(cur, "oc_category_description"))
    for lang_id in unique_lang_ids(ua_id, ru_id):
        data = {
            "category_id": category_id,
            "language_id": lang_id,
            "name": name_ua,
            "description": desc_ua,
            "meta_title": name_ua or tag,
            "meta_description": (desc_ua or "")[:255],
            "meta_keyword": tag,
        }
        sql, vals = build_upsert_sql("oc_category_description", desc_cols, data, pk_cols=["category_id", "language_id"])
        cur.execute(sql, vals)


def upsert_product(cur, prod, table_cols_cache: Dict[str, List[str]]) -> int:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    model = (prod.get("model") or prod.get("model ") or prod.get("model\ufeff") or "").strip()
    sku = (prod.get("sku") or prod.get("product_id") or "").strip()
    seo = (prod.get("seo") or "").strip()
    primary_image = (prod.get("primary_image") or "").strip()
    base_price = parse_float(prod.get("price"))
    quantity = parse_int(prod.get("quantity"), default=0)
    minimum = parse_int(prod.get("minimum"), default=1)
    subtract = parse_int(prod.get("subtract"), default=1)
    stock_status_id = parse_int(prod.get("stock_status_id"), default=7)
    shipping = parse_int(prod.get("shipping"), default=1)
    weight = parse_float(prod.get("weight"))
    weight_class_id = parse_int(prod.get("weight_class_id"), default=1)
    length = parse_float(prod.get("length"))
    width = parse_float(prod.get("width"))
    height = parse_float(prod.get("height"))
    length_class_id = parse_int(prod.get("length_class_id"), default=1)
    sort_order = parse_int(prod.get("sort_order"), default=0)
    status_val = prod.get("status") or prod.get("validated")
    status = parse_int(status_val, default=1)
    viewed = parse_int(prod.get("viewed"), default=0)
    date_available = (prod.get("date_available") or prod.get("created_at") or now)
    date_added = (prod.get("date_added") or prod.get("created_at") or now)
    date_modified = (prod.get("date_modified") or prod.get("updated_at") or date_added)
    image_path = f"catalog/product/{primary_image}" if primary_image else None

    prod_cols = table_cols_cache.setdefault("oc_product", get_table_columns(cur, "oc_product"))
    data = {
        "model": model or sku or seo or "",
        "sku": sku or seo or "",
        "upc": "",
        "ean": "",
        "jan": "",
        "isbn": "",
        "mpn": "",
        "location": "",
        "quantity": quantity,
        "stock_status_id": stock_status_id,
        "image": image_path,
        "manufacturer_id": 0,
        "shipping": shipping,
        "price": base_price,
        "points": 0,
        "tax_class_id": 0,
        "date_available": date_available,
        "weight": weight,
        "weight_class_id": weight_class_id,
        "length": length,
        "width": width,
        "height": height,
        "length_class_id": length_class_id,
        "subtract": subtract,
        "minimum": minimum,
        "sort_order": sort_order,
        "status": status,
        "viewed": viewed,
        "date_added": date_added,
        "date_modified": date_modified,
    }
    sql, vals = build_upsert_sql("oc_product", prod_cols, data, pk_cols=["product_id"])  # product_id is AUTO_INCREMENT
    cur.execute(sql, vals)
    return int(cur.lastrowid or 0)


def upsert_product_descriptions(cur, product_id: int, prod: Dict[str, str], ua_id: int, ru_id: int, table_cols_cache: Dict[str, List[str]]) -> None:
    name_ua = (prod.get("Название (укр)") or "").strip()
    name_ru = (prod.get("Название (рус)") or name_ua).strip()
    desc_ua = (prod.get("Описание (укр)") or "").strip()
    desc_ru = (prod.get("Описание (рус)") or desc_ua).strip()
    tags = (prod.get("tags") or "").strip()
    pd_cols = table_cols_cache.setdefault("oc_product_description", get_table_columns(cur, "oc_product_description"))
    for lang_id in unique_lang_ids(ua_id, ru_id):
        is_ru = (lang_id == ru_id and ru_id != ua_id)
        data = {
            "product_id": product_id,
            "language_id": lang_id,
            "name": name_ru if is_ru else name_ua,
            "description": desc_ru if is_ru else desc_ua,
            "tag": tags,
            "meta_title": (name_ru if is_ru else name_ua) or "",
            "meta_description": ((desc_ru if is_ru else desc_ua) or "")[:255],
            "meta_keyword": tags,
        }
        sql, vals = build_upsert_sql("oc_product_description", pd_cols, data, pk_cols=["product_id", "language_id"])
        cur.execute(sql, vals)


def upsert_product_categories(cur, product_id: int, prod: Dict[str, str]) -> None:
    cat = (prod.get("subcategory_id") or prod.get("category_id") or "").strip()
    if not cat:
        return
    try:
        category_id = int(cat)
    except ValueError:
        return
    cur.execute(
        "INSERT IGNORE INTO oc_product_to_category(product_id, category_id) VALUES (%s, %s)",
        (product_id, category_id),
    )


def upsert_product_images(cur, product_id: int, prod: Dict[str, str]) -> None:
    images = (prod.get("images") or "").strip()
    if not images:
        return
    parts = [p.strip() for p in images.split(",") if p.strip()]
    for idx, img in enumerate(parts):
        cur.execute(
            "INSERT INTO oc_product_image(product_id, image, sort_order) VALUES (%s, %s, %s)",
            (product_id, f"catalog/product/{img}", idx + 1),
        )


def ensure_option(cur, ua_id: int, ru_id: int) -> int:
    cur.execute("SELECT option_id FROM oc_option WHERE type = 'select' LIMIT 1")
    row = cur.fetchone()
    if row and row[0]:
        return int(row[0])
    cur.execute("INSERT INTO oc_option(type, sort_order) VALUES('select', 0)")
    option_id = cur.lastrowid
    for lang_id, name in zip(unique_lang_ids(ua_id, ru_id), ["Пакування", "Упаковка"]):
        cur.execute("INSERT INTO oc_option_description(option_id, language_id, name) VALUES(%s, %s, %s)", (option_id, lang_id, name))
    return option_id


def upsert_option_value(cur, option_id: int, ua_id: int, ru_id: int, title_ua: str, title_ru: str) -> int:
    cur.execute(
        """
        SELECT ov.option_value_id
        FROM oc_option_value ov
        JOIN oc_option_value_description ovd ON ovd.option_value_id = ov.option_value_id AND ovd.language_id = %s
        WHERE ov.option_id = %s AND ovd.name = %s
        LIMIT 1
        """,
        (ua_id, option_id, title_ua),
    )
    row = cur.fetchone()
    if row and row[0]:
        return int(row[0])
    cur.execute("INSERT INTO oc_option_value(option_id, image, sort_order) VALUES(%s, '', 0)", (option_id,))
    option_value_id = cur.lastrowid
    for lang_id in unique_lang_ids(ua_id, ru_id):
        name = title_ru if (lang_id == ru_id and ru_id != ua_id) else title_ua
        cur.execute(
            "INSERT INTO oc_option_value_description(option_value_id, language_id, option_id, name) VALUES(%s, %s, %s, %s)",
            (option_value_id, lang_id, option_id, name),
        )
    return option_value_id


def build_attributes_from_tags(cur, ua_id: int, ru_id: int, tags_rows: List[Dict[str, str]]):
    group_to_id: Dict[str, int] = {}
    key_to_attr_id: Dict[str, int] = {}
    # groups
    for r in tags_rows:
        group = (r.get("group") or "").strip()
        if not group or group in group_to_id:
            continue
        cur.execute("INSERT INTO oc_attribute_group(sort_order) VALUES(0)")
        group_id = cur.lastrowid
        for lang_id in unique_lang_ids(ua_id, ru_id):
            cur.execute("INSERT INTO oc_attribute_group_description(attribute_group_id, language_id, name) VALUES(%s, %s, %s)", (group_id, lang_id, group))
        group_to_id[group] = group_id
    # attributes
    for r in tags_rows:
        group = (r.get("group") or "").strip()
        key = (r.get("key") or "").strip()
        if not group or not key or key in key_to_attr_id:
            continue
        ua = (r.get("ua") or key).strip()
        ru = (r.get("ru") or ua).strip()
        group_id = group_to_id[group]
        cur.execute("INSERT INTO oc_attribute(attribute_group_id, sort_order) VALUES(%s, 0)", (group_id,))
        attribute_id = cur.lastrowid
        for lang_id in unique_lang_ids(ua_id, ru_id):
            name = ru if (lang_id == ru_id and ru_id != ua_id) else ua
            cur.execute("INSERT INTO oc_attribute_description(attribute_id, language_id, name) VALUES(%s, %s, %s)", (attribute_id, lang_id, name))
        key_to_attr_id[key] = attribute_id
    return key_to_attr_id


def upsert_product_attributes_from_tags(cur, product_id: int, tags_str: str, ua_id: int, ru_id: int, key_to_attr_id: Dict[str, int], tags_index: Dict[str, Dict[str, str]]):
    if not tags_str:
        return
    keys = [t.strip() for t in tags_str.split(",") if t.strip()]
    for key in keys:
        attribute_id = key_to_attr_id.get(key)
        if not attribute_id:
            continue
        tag_row = tags_index.get(key)
        ua_val = (tag_row.get("ua") if tag_row else key) or key
        ru_val = (tag_row.get("ru") if tag_row else ua_val) or ua_val
        for lang_id in unique_lang_ids(ua_id, ru_id):
            text = ru_val if (lang_id == ru_id and ru_id != ua_id) else ua_val
            cur.execute(
                """
                INSERT INTO oc_product_attribute(product_id, attribute_id, language_id, text)
                VALUES(%s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE text = VALUES(text)
                """,
                (product_id, attribute_id, lang_id, text),
            )


def main() -> int:
    parser = argparse.ArgumentParser(description="Populate OpenCart MySQL DB from data CSVs")
    parser.add_argument("--host", default=os.getenv("MYSQL_HOST", "db"))
    parser.add_argument("--port", type=int, default=int(os.getenv("MYSQL_PORT", "3306")))
    parser.add_argument("--user", default=os.getenv("MYSQL_USER", "root"))
    parser.add_argument("--password", default=os.getenv("MYSQL_PASSWORD", "example"))
    parser.add_argument("--database", default=os.getenv("MYSQL_DATABASE", "opencart"))
    parser.add_argument("--data", dest="data_dir", default=str(Path("/workspace/data")), help="Path to data directory with CSVs")
    parser.add_argument("--clean", dest="clean", action="store_true", help="Clean tables before import")
    parser.add_argument("--no-clean", dest="no_clean", action="store_true", help="Skip cleaning")
    args = parser.parse_args()

    def log(msg: str) -> None:
        print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)

    log(f"Connecting to MySQL {args.user}@{args.host}:{args.port}/{args.database}")
    conn = pymysql.connect(host=args.host, port=args.port, user=args.user, password=args.password, database=args.database, charset="utf8mb4")
    cur = conn.cursor()

    do_clean = True
    if args.no_clean:
        do_clean = False
    if args.clean:
        do_clean = True
    if do_clean:
        log("Cleaning target tables (TRUNCATE)...")
        clean_db(conn)
        log("Cleanup complete.")

    ua_id, ru_id = get_language_ids(cur)
    log(f"Language IDs resolved -> UA: {ua_id}, RU: {ru_id}")

    data_dir = Path(args.data_dir)
    categories = read_csv(data_dir / "categories_list.csv")
    products = read_csv(data_dir / "list.csv")
    inventory = read_csv(data_dir / "inventory.csv")
    tags_rows = read_csv(data_dir / "tags.csv")
    log(f"Loaded CSVs -> categories: {len(categories)}, products: {len(products)}, inventory rows: {len(inventory)}, tags: {len(tags_rows)}")

    inv_by_product: Dict[str, List[Dict[str, str]]] = {}
    for r in inventory:
        pid = (r.get("product_id") or r.get("pid") or "").strip()
        if pid:
            inv_by_product.setdefault(pid, []).append(r)

    tags_index: Dict[str, Dict[str, str]] = {}
    for r in tags_rows:
        key = (r.get("key") or "").strip()
        if key:
            tags_index[key] = r

    table_cols_cache: Dict[str, List[str]] = {}

    # Categories
    log("Inserting categories and descriptions...")
    for c in categories:
        ensure_category(cur, c, table_cols_cache)
        ensure_category_descriptions(cur, c, ua_id, ru_id, table_cols_cache)
    conn.commit()
    log(f"Categories upserted: {len(categories)}")

    # Attributes from tags
    unique_groups = len({(r.get('group') or '').strip() for r in tags_rows if (r.get('group') or '').strip()})
    unique_keys = len({(r.get('key') or '').strip() for r in tags_rows if (r.get('key') or '').strip()})
    log(f"Building attributes from tags (groups={unique_groups}, keys={unique_keys})...")
    key_to_attr_id = build_attributes_from_tags(cur, ua_id, ru_id, tags_rows)
    conn.commit()
    log(f"Attributes created: {len(key_to_attr_id)} across {unique_groups} groups")

    # Option
    log("Ensuring product option exists for variants...")
    option_id = ensure_option(cur, ua_id, ru_id)
    conn.commit()
    log(f"Option ready: option_id={option_id}")

    # Products and related
    log("Inserting products, descriptions, categories, and images...")
    product_id_map: Dict[str, int] = {}
    prod_processed = 0
    img_added = 0
    for p in products:
        product_sku = (p.get("sku") or p.get("product_id") or "").strip()
        db_product_id = upsert_product(cur, p, table_cols_cache)
        product_id_map[product_sku] = db_product_id
        upsert_product_descriptions(cur, db_product_id, p, ua_id, ru_id, table_cols_cache)
        upsert_product_categories(cur, db_product_id, p)
        images = (p.get("images") or "").strip()
        if images:
            img_added += len([_ for _ in images.split(",") if _.strip()])
        upsert_product_images(cur, db_product_id, p)
        prod_processed += 1
        if prod_processed % 200 == 0:
            log(f"Products processed: {prod_processed}/{len(products)}")
    conn.commit()
    log(f"Products upserted: {prod_processed}; additional images inserted: {img_added}")

    # Options per product
    log("Linking product options and values with pricing and weights...")
    pov_inserted = 0
    products_with_options = 0
    for p in products:
        sku_or_pid = (p.get("product_id") or p.get("sku") or "").strip()
        if not sku_or_pid:
            continue
        rows = inv_by_product.get(sku_or_pid)
        if not rows:
            continue
        db_product_id = product_id_map.get(sku_or_pid)
        if not db_product_id:
            continue
        variant_prices: List[float] = []
        for r in rows:
            price = parse_float(r.get("sale_price") or r.get("original_price"))
            variant_prices.append(price)
        base_price = min(variant_prices) if variant_prices else 0.0
        cur.execute("UPDATE oc_product SET price = %s WHERE product_id = %s", (base_price, db_product_id))

        cur.execute("SELECT product_option_id FROM oc_product_option WHERE product_id = %s AND option_id = %s", (db_product_id, option_id))
        row = cur.fetchone()
        if row and row[0]:
            product_option_id = int(row[0])
        else:
            cur.execute("INSERT INTO oc_product_option(product_id, option_id, value, required) VALUES(%s, %s, '', 1)", (db_product_id, option_id))
            product_option_id = cur.lastrowid

        for r in rows:
            title_ua = (r.get("title_ua") or "").strip()
            title_ru = (r.get("title_ru") or title_ua).strip()
            option_value_id = upsert_option_value(cur, option_id, ua_id, ru_id, title_ua, title_ru)
            qty = parse_int(r.get("stock_qty"), 0)
            absolute_price = parse_float(r.get("sale_price") or r.get("original_price"))
            delta = absolute_price - base_price
            price_prefix = "+" if delta >= 0 else "-"
            price_value = abs(delta)
            weight_value = gram_value_to_kg(r.get("value"), r.get("unit"))
            cur.execute(
                """
                INSERT INTO oc_product_option_value(
                    product_option_id, product_id, option_id, option_value_id, quantity, subtract,
                    price, price_prefix, points, points_prefix, weight, weight_prefix
                ) VALUES (%s, %s, %s, %s, %s, 1, %s, %s, 0, '+', %s, '+')
                """,
                (product_option_id, db_product_id, option_id, option_value_id, qty, price_value, price_prefix, weight_value),
            )
            pov_inserted += 1
        products_with_options += 1
    conn.commit()
    log(f"Products with options: {products_with_options}; product option values inserted: {pov_inserted}")

    # report
    log("Collecting final stats...")
    stats = {}
    for t in [
        "oc_category", "oc_product", "oc_product_description", "oc_product_image",
        "oc_attribute", "oc_product_attribute", "oc_option", "oc_option_value", "oc_product_option_value"
    ]:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        stats[t] = int(cur.fetchone()[0])
    print(json.dumps(stats, ensure_ascii=False))
    log("Migration complete.")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

