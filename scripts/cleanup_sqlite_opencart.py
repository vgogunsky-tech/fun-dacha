#!/usr/bin/env python3
import argparse
import os
import sqlite3
from pathlib import Path

DEFAULT_DB_PATH = Path(os.getenv("OPENCART_DB", "/workspace/opencart-docker/opencart.db"))

TABLES_IN_DEP_ORDER = [
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


def main() -> int:
    parser = argparse.ArgumentParser(description="Cleanup OpenCart oc_* tables in SQLite DB")
    parser.add_argument("--db", dest="db_path", default=str(DEFAULT_DB_PATH), help="Path to SQLite DB file")
    args = parser.parse_args()

    db_path = Path(args.db_path)
    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys = ON;")
    with con:
        for t in TABLES_IN_DEP_ORDER:
            con.execute(f"DELETE FROM {t}")
    con.close()
    print("Cleanup completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())