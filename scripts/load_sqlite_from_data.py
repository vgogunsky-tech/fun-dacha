#!/usr/bin/env python3
import argparse
import csv
import json
import os
import sqlite3
import sys
from datetime import datetime
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


DEFAULT_DB_PATH = Path(os.getenv("OPENCART_DB", "/workspace/opencart-docker/opencart.db"))
DEFAULT_DATA_DIR = Path(os.getenv("OPENCART_DATA", "/workspace/data"))


def open_db(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def read_csv(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


def get_language_ids(conn: sqlite3.Connection) -> Tuple[int, int]:
    cur = conn.cursor()
    cur.execute("SELECT language_id, code FROM oc_language")
    rows = cur.fetchall()
    code_to_id = {r[1]: r[0] for r in rows}
    ua_id = code_to_id.get("uk") or code_to_id.get("uk-ua") or next(iter(code_to_id.values()), 1)
    ru_id = code_to_id.get("ru") or code_to_id.get("ru-ru") or ua_id
    return ua_id, ru_id


def parse_float(s: Optional[str], default: float = 0.0) -> float:
    if s is None:
        return default
    raw = str(s).strip()
    if raw == "":
        return default
    # Remove currency symbols and non-numeric separators, normalize decimal comma
    raw = raw.replace("гр", "").replace("грн", "").replace("UAH", "")
    raw = raw.replace(" ", "")
    # Replace comma decimal with dot if appropriate
    # Handle forms like "10,00" or "10,00гр"
    if raw.count(",") == 1 and raw.count(".") == 0:
        raw = raw.replace(",", ".")
    # Remove stray commas
    raw = raw.replace(",", "")
    try:
        return float(raw)
    except Exception:
        # Extract first float-like token
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
    # Remove spaces and non-digit suffixes
    raw = re.sub(r"[^0-9-]+", "", raw)
    try:
        return int(raw)
    except Exception:
        return default


def ensure_category(conn: sqlite3.Connection, row: Dict[str, str]) -> None:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    category_id = int((row.get("id") or "0").strip() or 0)
    parent_id_raw = (row.get("parentId") or "").strip()
    parent_id = int(parent_id_raw) if parent_id_raw else 0
    image = (row.get("primary_image") or "").strip()
    image_path = f"catalog/category/{image}" if image else None
    top = 1 if not parent_id else 0
    # Insert or replace category
    conn.execute(
        """
        INSERT INTO oc_category(category_id, image, parent_id, top, column, sort_order, status, date_added, date_modified)
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(category_id) DO UPDATE SET
            image=excluded.image,
            parent_id=excluded.parent_id,
            top=excluded.top,
            column=excluded.column,
            sort_order=excluded.sort_order,
            status=excluded.status,
            date_modified=excluded.date_modified
        """,
        (
            category_id,
            image_path,
            parent_id,
            top,
            1,
            0,
            1,
            now,
            now,
        ),
    )


def ensure_category_descriptions(conn: sqlite3.Connection, row: Dict[str, str], ua_id: int, ru_id: int) -> None:
    category_id = int(row.get("id") or 0)
    name_ua = (row.get("name") or "").strip()
    desc_ua = (row.get("description (ukr)") or "").strip()
    tag = (row.get("tag") or "").strip()
    # UA
    conn.execute(
        """
        INSERT INTO oc_category_description(category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(category_id, language_id) DO UPDATE SET
            name=excluded.name,
            description=excluded.description,
            meta_title=excluded.meta_title,
            meta_description=excluded.meta_description,
            meta_keyword=excluded.meta_keyword
        """,
        (
            category_id,
            ua_id,
            name_ua,
            desc_ua,
            name_ua or tag,
            (desc_ua or "")[:255],
            tag,
        ),
    )
    # RU fallback duplicates UA (no RU in CSV)
    conn.execute(
        """
        INSERT INTO oc_category_description(category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(category_id, language_id) DO UPDATE SET
            name=excluded.name,
            description=excluded.description,
            meta_title=excluded.meta_title,
            meta_description=excluded.meta_description,
            meta_keyword=excluded.meta_keyword
        """,
        (
            category_id,
            ru_id,
            name_ua,
            desc_ua,
            name_ua or tag,
            (desc_ua or "")[:255],
            tag,
        ),
    )


def upsert_product(conn: sqlite3.Connection, prod: Dict[str, str]) -> int:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    # Base identifiers
    model = (prod.get("model") or prod.get("model ") or prod.get("model\ufeff") or "").strip()
    sku = (prod.get("sku") or prod.get("product_id") or "").strip()
    seo = (prod.get("seo") or "").strip()
    primary_image = (prod.get("primary_image") or "").strip()
    price_raw = prod.get("price")
    base_price = parse_float(price_raw)
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

    # Insert product
    cur = conn.execute(
        """
        INSERT INTO oc_product(
            model, sku, upc, ean, jan, isbn, mpn, location, quantity, stock_status_id,
            image, manufacturer_id, shipping, price, points, tax_class_id, date_available,
            weight, weight_class_id, length, width, height, length_class_id, subtract,
            minimum, sort_order, status, viewed, date_added, date_modified
        ) VALUES (?, ?, '', '', '', '', '', '', ?, ?, ?, 0, ?, ?, 0, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
    product_id = cur.lastrowid
    return product_id


def upsert_product_descriptions(conn: sqlite3.Connection, product_id: int, prod: Dict[str, str], ua_id: int, ru_id: int) -> None:
    name_ua = (prod.get("Название (укр)") or "").strip()
    name_ru = (prod.get("Название (рус)") or name_ua).strip()
    desc_ua = (prod.get("Описание (укр)") or "").strip()
    desc_ru = (prod.get("Описание (рус)") or desc_ua).strip()
    tags = (prod.get("tags") or "").strip()
    # UA
    conn.execute(
        """
        INSERT INTO oc_product_description(product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(product_id, language_id) DO UPDATE SET
            name=excluded.name,
            description=excluded.description,
            tag=excluded.tag,
            meta_title=excluded.meta_title,
            meta_description=excluded.meta_description,
            meta_keyword=excluded.meta_keyword
        """,
        (
            product_id,
            ua_id,
            name_ua,
            desc_ua,
            tags,
            name_ua or "",
            (desc_ua or "")[:255],
            tags,
        ),
    )
    # RU fallback
    conn.execute(
        """
        INSERT INTO oc_product_description(product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(product_id, language_id) DO UPDATE SET
            name=excluded.name,
            description=excluded.description,
            tag=excluded.tag,
            meta_title=excluded.meta_title,
            meta_description=excluded.meta_description,
            meta_keyword=excluded.meta_keyword
        """,
        (
            product_id,
            ru_id,
            name_ru,
            desc_ru,
            tags,
            name_ru or "",
            (desc_ru or "")[:255],
            tags,
        ),
    )


def upsert_product_categories(conn: sqlite3.Connection, product_id: int, prod: Dict[str, str]) -> None:
    cat = (prod.get("subcategory_id") or prod.get("category_id") or "").strip()
    if not cat:
        return
    try:
        category_id = int(cat)
    except ValueError:
        return
    conn.execute(
        """
        INSERT OR IGNORE INTO oc_product_to_category(product_id, category_id)
        VALUES (?, ?)
        """,
        (product_id, category_id),
    )


def upsert_product_images(conn: sqlite3.Connection, product_id: int, prod: Dict[str, str]) -> None:
    images = (prod.get("images") or "").strip()
    if not images:
        return
    parts = [p.strip() for p in images.split(",") if p.strip()]
    for idx, img in enumerate(parts):
        conn.execute(
            """
            INSERT INTO oc_product_image(product_id, image, sort_order)
            VALUES (?, ?, ?)
            """,
            (product_id, f"catalog/product/{img}", idx + 1),
        )


def ensure_option(conn: sqlite3.Connection, ua_id: int, ru_id: int) -> int:
    cur = conn.execute("SELECT option_id FROM oc_option WHERE type = 'select' LIMIT 1")
    row = cur.fetchone()
    if row:
        return row[0]
    cur = conn.execute("INSERT INTO oc_option(type, sort_order) VALUES('select', 0)")
    option_id = cur.lastrowid
    # Names for the option
    conn.execute(
        "INSERT INTO oc_option_description(option_id, language_id, name) VALUES(?, ?, ?)",
        (option_id, ua_id, "Пакування"),
    )
    conn.execute(
        "INSERT INTO oc_option_description(option_id, language_id, name) VALUES(?, ?, ?)",
        (option_id, ru_id, "Упаковка"),
    )
    return option_id


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


def upsert_option_value(
    conn: sqlite3.Connection,
    option_id: int,
    ua_id: int,
    ru_id: int,
    title_ua: str,
    title_ru: str,
) -> int:
    # Look up by (option_id, name ua)
    cur = conn.execute(
        """
        SELECT ov.option_value_id
        FROM oc_option_value ov
        JOIN oc_option_value_description ovd ON ovd.option_value_id = ov.option_value_id AND ovd.language_id = ?
        WHERE ov.option_id = ? AND ovd.name = ?
        LIMIT 1
        """,
        (ua_id, option_id, title_ua),
    )
    row = cur.fetchone()
    if row:
        return row[0]
    cur = conn.execute(
        "INSERT INTO oc_option_value(option_id, image, sort_order) VALUES(?, '', 0)",
        (option_id,),
    )
    option_value_id = cur.lastrowid
    conn.execute(
        "INSERT INTO oc_option_value_description(option_value_id, language_id, option_id, name) VALUES(?, ?, ?, ?)",
        (option_value_id, ua_id, option_id, title_ua),
    )
    conn.execute(
        "INSERT INTO oc_option_value_description(option_value_id, language_id, option_id, name) VALUES(?, ?, ?, ?)",
        (option_value_id, ru_id, option_id, title_ru or title_ua),
    )
    return option_value_id


def ensure_product_option(conn: sqlite3.Connection, product_id: int, option_id: int) -> int:
    cur = conn.execute(
        "SELECT product_option_id FROM oc_product_option WHERE product_id = ? AND option_id = ?",
        (product_id, option_id),
    )
    row = cur.fetchone()
    if row:
        return row[0]
    cur = conn.execute(
        "INSERT INTO oc_product_option(product_id, option_id, value, required) VALUES(?, ?, '', 1)",
        (product_id, option_id),
    )
    return cur.lastrowid


def build_attributes_from_tags(conn: sqlite3.Connection, ua_id: int, ru_id: int, tags_rows: List[Dict[str, str]]) -> Dict[str, int]:
    # Create attribute groups (by group name), then attributes per key
    group_to_id: Dict[str, int] = {}
    key_to_attr_id: Dict[str, int] = {}
    # Groups first
    for r in tags_rows:
        group = (r.get("group") or "").strip()
        if not group or group in group_to_id:
            continue
        cur = conn.execute("INSERT INTO oc_attribute_group(sort_order) VALUES(0)")
        group_id = cur.lastrowid
        conn.execute(
            "INSERT INTO oc_attribute_group_description(attribute_group_id, language_id, name) VALUES(?, ?, ?)",
            (group_id, ua_id, group),
        )
        conn.execute(
            "INSERT INTO oc_attribute_group_description(attribute_group_id, language_id, name) VALUES(?, ?, ?)",
            (group_id, ru_id, group),
        )
        group_to_id[group] = group_id

    # Attributes by (group, key)
    for r in tags_rows:
        group = (r.get("group") or "").strip()
        key = (r.get("key") or "").strip()
        if not group or not key:
            continue
        ua = (r.get("ua") or key).strip()
        ru = (r.get("ru") or ua).strip()
        if key in key_to_attr_id:
            continue
        group_id = group_to_id[group]
        cur = conn.execute(
            "INSERT INTO oc_attribute(attribute_group_id, sort_order) VALUES(?, 0)",
            (group_id,),
        )
        attribute_id = cur.lastrowid
        conn.execute(
            "INSERT INTO oc_attribute_description(attribute_id, language_id, name) VALUES(?, ?, ?)",
            (attribute_id, ua_id, ua),
        )
        conn.execute(
            "INSERT INTO oc_attribute_description(attribute_id, language_id, name) VALUES(?, ?, ?)",
            (attribute_id, ru_id, ru),
        )
        key_to_attr_id[key] = attribute_id

    return key_to_attr_id


def upsert_product_attributes_from_tags(
    conn: sqlite3.Connection,
    product_id: int,
    tags_str: str,
    ua_id: int,
    ru_id: int,
    key_to_attr_id: Dict[str, int],
    tags_rows_index: Dict[str, Dict[str, str]],
) -> None:
    if not tags_str:
        return
    keys = [t.strip() for t in tags_str.split(",") if t.strip()]
    for key in keys:
        attribute_id = key_to_attr_id.get(key)
        if not attribute_id:
            continue
        # Localized value text for attribute
        tag_row = tags_rows_index.get(key)
        ua_val = (tag_row.get("ua") if tag_row else key) or key
        ru_val = (tag_row.get("ru") if tag_row else ua_val) or ua_val
        # UA
        conn.execute(
            """
            INSERT INTO oc_product_attribute(product_id, attribute_id, language_id, text)
            VALUES(?, ?, ?, ?)
            ON CONFLICT(product_id, attribute_id, language_id) DO UPDATE SET text = excluded.text
            """,
            (product_id, attribute_id, ua_id, ua_val),
        )
        # RU
        conn.execute(
            """
            INSERT INTO oc_product_attribute(product_id, attribute_id, language_id, text)
            VALUES(?, ?, ?, ?)
            ON CONFLICT(product_id, attribute_id, language_id) DO UPDATE SET text = excluded.text
            """,
            (product_id, attribute_id, ru_id, ru_val),
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Populate OpenCart SQLite DB from data CSVs")
    parser.add_argument("--db", dest="db_path", default=str(DEFAULT_DB_PATH), help="Path to SQLite DB file")
    parser.add_argument("--data", dest="data_dir", default=str(DEFAULT_DATA_DIR), help="Path to data directory with CSVs")
    parser.add_argument("--clean", dest="clean", action="store_true", help="Clean relevant oc_* tables before import")
    parser.add_argument("--no-clean", dest="no_clean", action="store_true", help="Do not clean tables before import")
    args = parser.parse_args()

    db_path = Path(args.db_path)
    data_dir = Path(args.data_dir)

    conn = open_db(db_path)
    # Optional cleanup (default: clean unless --no-clean specified)
    do_clean = True
    if args.no_clean:
        do_clean = False
    if args.clean:
        do_clean = True

    if do_clean:
        with conn:
            conn.execute("DELETE FROM oc_product_option_value")
            conn.execute("DELETE FROM oc_product_option")
            conn.execute("DELETE FROM oc_option_value_description")
            conn.execute("DELETE FROM oc_option_value")
            conn.execute("DELETE FROM oc_option_description")
            conn.execute("DELETE FROM oc_option")
            conn.execute("DELETE FROM oc_product_attribute")
            conn.execute("DELETE FROM oc_attribute_description")
            conn.execute("DELETE FROM oc_attribute")
            conn.execute("DELETE FROM oc_attribute_group_description")
            conn.execute("DELETE FROM oc_attribute_group")
            conn.execute("DELETE FROM oc_product_image")
            conn.execute("DELETE FROM oc_product_to_category")
            conn.execute("DELETE FROM oc_product_description")
            conn.execute("DELETE FROM oc_product")
            conn.execute("DELETE FROM oc_category_description")
            conn.execute("DELETE FROM oc_category")

    ua_id, ru_id = get_language_ids(conn)

    categories = read_csv(data_dir / "categories_list.csv")
    products = read_csv(data_dir / "list.csv")
    inventory = read_csv(data_dir / "inventory.csv")
    tags_rows = read_csv(data_dir / "tags.csv")

    # Build quick indexes
    inv_by_product: Dict[str, List[Dict[str, str]]] = {}
    for r in inventory:
        pid = (r.get("product_id") or r.get("pid") or "").strip()
        if not pid:
            continue
        inv_by_product.setdefault(pid, []).append(r)

    tags_index: Dict[str, Dict[str, str]] = {}
    for r in tags_rows:
        key = (r.get("key") or "").strip()
        if key:
            tags_index[key] = r

    # Populate categories
    with conn:
        for c in categories:
            ensure_category(conn, c)
            ensure_category_descriptions(conn, c, ua_id, ru_id)

    # Build attributes from tags
    with conn:
        key_to_attr_id = build_attributes_from_tags(conn, ua_id, ru_id, tags_rows)

    # Ensure option for variants exists
    with conn:
        option_id = ensure_option(conn, ua_id, ru_id)

    # Insert products and related
    product_id_map: Dict[str, int] = {}
    with conn:
        for p in products:
            product_sku = (p.get("sku") or p.get("product_id") or "").strip()
            db_product_id = upsert_product(conn, p)
            product_id_map[product_sku] = db_product_id
            upsert_product_descriptions(conn, db_product_id, p, ua_id, ru_id)
            upsert_product_categories(conn, db_product_id, p)
            upsert_product_images(conn, db_product_id, p)
            # Tags -> product attributes
            upsert_product_attributes_from_tags(
                conn,
                db_product_id,
                (p.get("tags") or ""),
                ua_id,
                ru_id,
                key_to_attr_id,
                tags_index,
            )

    # Product options/option values
    with conn:
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
            product_option_id = ensure_product_option(conn, db_product_id, option_id)

            # Decide pricing strategy: base price = min variant sale_price; option price = delta
            variant_prices: List[float] = []
            for r in rows:
                sale = r.get("sale_price")
                orig = r.get("original_price")
                price = float(sale or orig or 0.0)
                variant_prices.append(price)
            base_price = min(variant_prices) if variant_prices else 0.0
            # Update base product price to base_price
            conn.execute("UPDATE oc_product SET price = ? WHERE product_id = ?", (base_price, db_product_id))

            for r in rows:
                title_ua = (r.get("title_ua") or "").strip()
                title_ru = (r.get("title_ru") or title_ua).strip()
                option_value_id = upsert_option_value(conn, option_id, ua_id, ru_id, title_ua, title_ru)
                qty = int((r.get("stock_qty") or 0))
                sale = r.get("sale_price")
                orig = r.get("original_price")
                absolute_price = float(sale or orig or 0.0)
                delta = absolute_price - base_price
                price_prefix = "+" if delta >= 0 else "-"
                price_value = abs(delta)
                weight_value = gram_value_to_kg(r.get("value"), r.get("unit"))
                conn.execute(
                    """
                    INSERT INTO oc_product_option_value(
                        product_option_id, product_id, option_id, option_value_id, quantity, subtract,
                        price, price_prefix, points, points_prefix, weight, weight_prefix
                    ) VALUES (?, ?, ?, ?, ?, 1, ?, ?, 0, '+', ?, '+')
                    """,
                    (
                        product_option_id,
                        db_product_id,
                        option_id,
                        option_value_id,
                        qty,
                        price_value,
                        price_prefix,
                        weight_value,
                    ),
                )

    # Report summary
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM oc_category")
    cat_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_product")
    prod_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_product_description")
    prod_desc_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_product_image")
    prod_img_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_attribute")
    attr_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_product_attribute")
    prod_attr_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_option")
    opt_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_option_value")
    opt_val_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM oc_product_option_value")
    pov_count = cur.fetchone()[0]
    print(json.dumps({
        "categories": cat_count,
        "products": prod_count,
        "product_descriptions": prod_desc_count,
        "product_images": prod_img_count,
        "attributes": attr_count,
        "product_attributes": prod_attr_count,
        "options": opt_count,
        "option_values": opt_val_count,
        "product_option_values": pov_count,
    }, ensure_ascii=False))

    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())

