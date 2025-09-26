#!/usr/bin/env python3
import argparse
import csv
import json
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import pymysql


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


def ensure_category(cur, row) -> None:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    category_id = int((row.get("id") or "0").strip() or 0)
    parent_id_raw = (row.get("parentId") or "").strip()
    parent_id = int(parent_id_raw) if parent_id_raw else 0
    image = (row.get("primary_image") or "").strip()
    image_path = f"catalog/category/{image}" if image else None
    top = 1 if not parent_id else 0
    cur.execute(
        """
        INSERT INTO oc_category(category_id, image, parent_id, `top`, `column`, sort_order, status, date_added, date_modified)
        VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            image=VALUES(image), parent_id=VALUES(parent_id), `top`=VALUES(`top`), `column`=VALUES(`column`),
            sort_order=VALUES(sort_order), status=VALUES(status), date_modified=VALUES(date_modified)
        """,
        (category_id, image_path, parent_id, top, 1, 0, 1, now, now),
    )


def ensure_category_descriptions(cur, row, ua_id, ru_id) -> None:
    category_id = int(row.get("id") or 0)
    name_ua = (row.get("name") or "").strip()
    desc_ua = (row.get("description (ukr)") or "").strip()
    tag = (row.get("tag") or "").strip()
    # UA
    cur.execute(
        """
        INSERT INTO oc_category_description(category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            name=VALUES(name), description=VALUES(description), meta_title=VALUES(meta_title),
            meta_description=VALUES(meta_description), meta_keyword=VALUES(meta_keyword)
        """,
        (category_id, ua_id, name_ua, desc_ua, name_ua or tag, (desc_ua or "")[:255], tag),
    )
    # RU duplicate
    cur.execute(
        """
        INSERT INTO oc_category_description(category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            name=VALUES(name), description=VALUES(description), meta_title=VALUES(meta_title),
            meta_description=VALUES(meta_description), meta_keyword=VALUES(meta_keyword)
        """,
        (category_id, ru_id, name_ua, desc_ua, name_ua or tag, (desc_ua or "")[:255], tag),
    )


def upsert_product(cur, prod) -> int:
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

    cur.execute(
        """
        INSERT INTO oc_product(
            model, sku, upc, ean, jan, isbn, mpn, location, quantity, stock_status_id,
            image, manufacturer_id, shipping, price, points, tax_class_id, date_available,
            weight, weight_class_id, length, width, height, length_class_id, subtract,
            minimum, sort_order, status, viewed, date_added, date_modified
        ) VALUES (%s, %s, '', '', '', '', '', '', %s, %s, %s, 0, %s, %s, 0, 0, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """,
        (
            model or sku or seo or "",
            sku or seo or "",
            quantity,
            stock_status_id,
            image_path,
            shipping,
            base_price,
            date_available,
            weight,
            weight_class_id,
            length,
            width,
            height,
            length_class_id,
            subtract,
            minimum,
            sort_order,
            status,
            viewed,
            date_added,
            date_modified,
        ),
    )
    return cur.lastrowid


def upsert_product_descriptions(cur, product_id: int, prod: Dict[str, str], ua_id: int, ru_id: int) -> None:
    name_ua = (prod.get("Название (укр)") or "").strip()
    name_ru = (prod.get("Название (рус)") or name_ua).strip()
    desc_ua = (prod.get("Описание (укр)") or "").strip()
    desc_ru = (prod.get("Описание (рус)") or desc_ua).strip()
    tags = (prod.get("tags") or "").strip()
    cur.execute(
        """
        INSERT INTO oc_product_description(product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            name=VALUES(name), description=VALUES(description), tag=VALUES(tag),
            meta_title=VALUES(meta_title), meta_description=VALUES(meta_description), meta_keyword=VALUES(meta_keyword)
        """,
        (product_id, ua_id, name_ua, desc_ua, tags, name_ua or "", (desc_ua or "")[:255], tags),
    )
    cur.execute(
        """
        INSERT INTO oc_product_description(product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            name=VALUES(name), description=VALUES(description), tag=VALUES(tag),
            meta_title=VALUES(meta_title), meta_description=VALUES(meta_description), meta_keyword=VALUES(meta_keyword)
        """,
        (product_id, ru_id, name_ru, desc_ru, tags, name_ru or "", (desc_ru or "")[:255], tags),
    )


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
    cur.execute("INSERT INTO oc_option_description(option_id, language_id, name) VALUES(%s, %s, %s)", (option_id, ua_id, "Пакування"))
    cur.execute("INSERT INTO oc_option_description(option_id, language_id, name) VALUES(%s, %s, %s)", (option_id, ru_id, "Упаковка"))
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
    cur.execute(
        "INSERT INTO oc_option_value_description(option_value_id, language_id, option_id, name) VALUES(%s, %s, %s, %s)",
        (option_value_id, ua_id, option_id, title_ua),
    )
    cur.execute(
        "INSERT INTO oc_option_value_description(option_value_id, language_id, option_id, name) VALUES(%s, %s, %s, %s)",
        (option_value_id, ru_id, option_id, title_ru or title_ua),
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
        cur.execute("INSERT INTO oc_attribute_group_description(attribute_group_id, language_id, name) VALUES(%s, %s, %s)", (group_id, ua_id, group))
        cur.execute("INSERT INTO oc_attribute_group_description(attribute_group_id, language_id, name) VALUES(%s, %s, %s)", (group_id, ru_id, group))
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
        cur.execute("INSERT INTO oc_attribute_description(attribute_id, language_id, name) VALUES(%s, %s, %s)", (attribute_id, ua_id, ua))
        cur.execute("INSERT INTO oc_attribute_description(attribute_id, language_id, name) VALUES(%s, %s, %s)", (attribute_id, ru_id, ru))
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
        for lang_id, text in ((ua_id, ua_val), (ru_id, ru_val)):
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

    conn = pymysql.connect(host=args.host, port=args.port, user=args.user, password=args.password, database=args.database, charset="utf8mb4")
    cur = conn.cursor()

    do_clean = True
    if args.no_clean:
        do_clean = False
    if args.clean:
        do_clean = True
    if do_clean:
        clean_db(conn)

    ua_id, ru_id = get_language_ids(cur)

    data_dir = Path(args.data_dir)
    categories = read_csv(data_dir / "categories_list.csv")
    products = read_csv(data_dir / "list.csv")
    inventory = read_csv(data_dir / "inventory.csv")
    tags_rows = read_csv(data_dir / "tags.csv")

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

    # Categories
    for c in categories:
        ensure_category(cur, c)
        ensure_category_descriptions(cur, c, ua_id, ru_id)
    conn.commit()

    # Attributes from tags
    key_to_attr_id = build_attributes_from_tags(cur, ua_id, ru_id, tags_rows)
    conn.commit()

    # Option
    option_id = ensure_option(cur, ua_id, ru_id)
    conn.commit()

    # Products and related
    product_id_map: Dict[str, int] = {}
    for p in products:
        product_sku = (p.get("sku") or p.get("product_id") or "").strip()
        db_product_id = upsert_product(cur, p)
        product_id_map[product_sku] = db_product_id
        upsert_product_descriptions(cur, db_product_id, p, ua_id, ru_id)
        upsert_product_categories(cur, db_product_id, p)
        upsert_product_images(cur, db_product_id, p)
        upsert_product_attributes_from_tags(cur, db_product_id, (p.get("tags") or ""), ua_id, ru_id, key_to_attr_id, tags_index)
    conn.commit()

    # Options per product
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
        # pricing
        variant_prices: List[float] = []  # type: ignore
        for r in rows:
            price = parse_float(r.get("sale_price") or r.get("original_price"))
            variant_prices.append(price)
        base_price = min(variant_prices) if variant_prices else 0.0
        cur.execute("UPDATE oc_product SET price = %s WHERE product_id = %s", (base_price, db_product_id))

        # ensure product_option row
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
    conn.commit()

    # report
    stats = {}
    for t in [
        "oc_category", "oc_product", "oc_product_description", "oc_product_image",
        "oc_attribute", "oc_product_attribute", "oc_option", "oc_option_value", "oc_product_option_value"
    ]:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        stats[t] = int(cur.fetchone()[0])
    print(json.dumps(stats, ensure_ascii=False))

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

