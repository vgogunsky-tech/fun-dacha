#!/usr/bin/env python3
import csv
import os
from typing import List, Dict

LIST_PATH = "/workspace/data/list.csv"
CATS_PATH = "/workspace/data/categories_list.csv"


def to_int_str(value: str) -> str:
    if value is None:
        return ""
    s = str(value).strip()
    if s == "":
        return ""
    try:
        f = float(s)
        i = int(f)
        return str(i)
    except Exception:
        return s


def migrate_list() -> None:
    with open(LIST_PATH, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows: List[Dict[str, str]] = list(reader)
        fields = reader.fieldnames or []

    for r in rows:
        r["id"] = to_int_str(r.get("id", ""))
        r["category_id"] = to_int_str(r.get("category_id", ""))
        r["subcategory_id"] = to_int_str(r.get("subcategory_id", ""))

    tmp = LIST_PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, LIST_PATH)


def migrate_categories() -> None:
    with open(CATS_PATH, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows: List[Dict[str, str]] = list(reader)
        fields = reader.fieldnames or []

    for r in rows:
        r["id"] = to_int_str(r.get("id", ""))
        r["parentId"] = to_int_str(r.get("parentId", ""))

    tmp = CATS_PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, CATS_PATH)


def main() -> int:
    migrate_list()
    migrate_categories()
    print("Migrated ID columns to integers in list.csv and categories_list.csv")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())