#!/usr/bin/env python3
import csv
import os
import sys
from typing import Dict, List, Tuple, Optional, Set

WORKSPACE_DIR = "/workspace"
CSV_PATH = os.path.join(WORKSPACE_DIR, "list.csv")
CATEGORIES_PATH = os.path.join(WORKSPACE_DIR, "categories_list.csv")

# ID ranges to base categories mapping (product id field from list.csv)
RANGE_TO_CATEGORY = [
    ((0, 99.9999), 100),           # 0-99.999 tomatoes
    ((101, 200), 110),             # cucumbers
    ((201, 244), 120),             # cabbage
    ((241, 274), 130),             # radish (overlaps: later rules should override earlier ones)
    ((275, 295), 140),             # pepper
    ((296, 303), 150),             # eggplant
    ((304, 324), 160),             # onion
    ((325, 343), 170),             # carrot
    ((344, 370), 180),             # beet
    ((371, 389), 190),             # watermelon
    ((390, 405), 200),             # melon
    ((406, 413), 210),             # pumpkin
    ((414, 429), 220),             # marrow-squash
    ((430, 433), 230),             # squash
    ((434, 469), 240),             # green-crops
]

# Heuristic keyword mapping for subcategories within categories
# Keys are category_id, values list of (subcategory_id, keywords_any)
HEURISTIC_SUBCATS: Dict[int, List[Tuple[int, List[str]]]] = {
    100: [  # tomatoes
        (101, ["індетермінант", "високоросл", "до 2,5", "1,5-2", "2,00м", "індетерминант", "высокоросл"]),
        (102, ["середньоросл", "среднеросл", "в два стебл"]),
        (103, ["низькоросл", "низкоросл", "детерминант", "комнатного", "до 1,2", "0,5-1,2", "штамб", "карлик", "компакт"]),
    ],
    120: [  # cabbage
        (121, ["білокачан", "белокочан", "капуста "]),
        (122, ["цвітн", "цветн", "цвітна"]),
        (123, ["червонокач", "краснокочан"]),
        (124, ["броккол", "пекін", "пекин", "савой", "кольраб", "брюссель", "калраб", "різновид", "разновид"]),
    ],
    140: [  # pepper
        (141, ["солодк", "сладк", "болгар", "sweet"]),
        (142, ["гірк", "горьк", "пекуч", "остр", "чили", "халапеньо", "хабанер"]),
    ],
    280: [  # beans (if used)
        (281, ["спаржев", "лопатк", "стручк", "стулк"]),
        (282, ["зернов", "лущил", "крупн", "сух"]),
    ],
}


def load_categories() -> Tuple[Dict[int, Dict[str, str]], Dict[int, Set[int]]]:
    with open(CATEGORIES_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        id_to_row: Dict[int, Dict[str, str]] = {}
        parent_to_children: Dict[int, Set[int]] = {}
        for row in reader:
            try:
                cid = int(row["id"]) if row.get("id") else None
            except Exception:
                continue
            id_to_row[cid] = row
            parent_raw = (row.get("parentId") or "").strip()
            if parent_raw:
                try:
                    pid = int(parent_raw)
                except Exception:
                    continue
                parent_to_children.setdefault(pid, set()).add(cid)
        return id_to_row, parent_to_children


def determine_category_id(product_id: float) -> Optional[int]:
    # Walk all rules; last match wins to honor later overrides in RANGE_TO_CATEGORY
    chosen: Optional[int] = None
    for (start, end), cat in RANGE_TO_CATEGORY:
        if product_id >= start and product_id <= end:
            chosen = cat
    return chosen


def infer_subcategory_id(category_id: int, row: Dict[str, str], allowed_subcats: Set[int]) -> Optional[int]:
    # If no allowed subcategories defined for this category, do not infer
    if not allowed_subcats:
        return None

    text = " ".join([
        row.get("Название (укр)", ""),
        row.get("Название (рус)", ""),
        row.get("Описание (укр)", ""),
        row.get("Описание (рус)", ""),
    ]).lower()

    rules = HEURISTIC_SUBCATS.get(category_id, [])
    for subcat_id, keywords in rules:
        if subcat_id not in allowed_subcats:
            continue
        for kw in keywords:
            if kw.lower() in text:
                return subcat_id

    # No valid heuristic match
    return None


def main() -> int:
    if not os.path.exists(CSV_PATH):
        print("list.csv not found")
        return 1
    if not os.path.exists(CATEGORIES_PATH):
        print("categories_list.csv not found")
        return 1

    id_to_row, parent_to_children = load_categories()

    with open(CSV_PATH, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames or []
        rows = list(reader)

    # Ensure columns exist
    if "category_id" not in fieldnames:
        fieldnames.append("category_id")
        for r in rows:
            r["category_id"] = ""
    if "subcategory_id" not in fieldnames:
        fieldnames.append("subcategory_id")
        for r in rows:
            r["subcategory_id"] = ""

    updated_categories = 0
    updated_subcats = 0

    for r in rows:
        try:
            pid_str = r.get("id", "").strip()
            if pid_str == "":
                continue
            product_id = float(pid_str)
        except Exception:
            continue

        base_category = determine_category_id(product_id)
        if base_category is not None:
            prev_cat = (r.get("category_id") or "").strip()
            if prev_cat != str(base_category):
                r["category_id"] = str(base_category)
                updated_categories += 1

            # Validate and infer subcategory strictly by parentId mapping
            allowed = parent_to_children.get(base_category, set())
            inferred = infer_subcategory_id(base_category, r, allowed)

            prev_sub = (r.get("subcategory_id") or "").strip()
            if inferred is not None and inferred in allowed:
                if prev_sub != str(inferred):
                    r["subcategory_id"] = str(inferred)
                    updated_subcats += 1
            else:
                # No valid subcategory -> clear
                if prev_sub != "":
                    r["subcategory_id"] = ""
                    updated_subcats += 1
        else:
            # If no base category determined, clear subcategory as well (safety)
            if (r.get("subcategory_id") or "").strip() != "":
                r["subcategory_id"] = ""
                updated_subcats += 1

    tmp_path = CSV_PATH + ".tmp"
    with open(tmp_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp_path, CSV_PATH)

    print(
        f"Updated category_id for ~{updated_categories} products. "
        f"Validated/updated subcategory_id for ~{updated_subcats} products."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())