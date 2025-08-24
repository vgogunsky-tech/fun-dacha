#!/usr/bin/env python3
import csv
import os
import sys
from typing import Dict, List, Tuple, Optional

WORKSPACE_DIR = "/workspace"
CSV_PATH = os.path.join(WORKSPACE_DIR, "list.csv")
CATEGORIES_PATH = os.path.join(WORKSPACE_DIR, "categories_list.csv")

# ID ranges to base categories mapping (product id field from list.csv)
RANGE_TO_CATEGORY = [
    ((0, 99.9999), 100),           # 0-99.999 tomatoes
    ((101, 200), 110),             # cucumbers
    ((201, 244), 120),             # cabbage
    ((241, 274), 130),             # radish (overlaps, but later rules will overwrite)
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


def load_categories() -> Dict[int, Dict[str, str]]:
    with open(CATEGORIES_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return {int(row["id"]): row for row in reader}


def determine_category_id(product_id: float) -> Optional[int]:
    # Prefer exact range rules provided by user. First rule match wins.
    for (start, end), cat in RANGE_TO_CATEGORY:
        # Inclusive for integer ranges; float ids are used in CSV like 7.5
        if product_id >= start and product_id <= end:
            return cat
    return None


def infer_subcategory_id(category_id: int, row: Dict[str, str]) -> Optional[int]:
    text = " ".join([
        row.get("Название (укр)", ""),
        row.get("Название (рус)", ""),
        row.get("Описание (укр)", ""),
        row.get("Описание (рус)", ""),
    ]).lower()

    # Tomato special-case by fruit color/size keywords if heuristic list doesn't match
    rules = HEURISTIC_SUBCATS.get(category_id, [])
    for subcat_id, keywords in rules:
        for kw in keywords:
            if kw.lower() in text:
                return subcat_id

    # Fallbacks
    if category_id == 100:
        # If no clear signal, default to medium height
        return 102
    if category_id == 120:
        # Default to generic cabbage types
        return 124
    if category_id == 140:
        # Default to sweet pepper unless keywords indicate hot
        return 141

    # For categories without subcategory list, leave None
    return None


def main() -> int:
    if not os.path.exists(CSV_PATH):
        print("list.csv not found")
        return 1
    if not os.path.exists(CATEGORIES_PATH):
        print("categories_list.csv not found")
        return 1

    categories = load_categories()

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

    updated = 0
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
            prev = r.get("category_id", "")
            if str(prev).strip() != str(base_category):
                r["category_id"] = str(base_category)
                updated += 1

            # Attempt subcategory inference only when category matches known categories with subcats
            sub_inferred = infer_subcategory_id(base_category, r)
            if sub_inferred is not None:
                r["subcategory_id"] = str(sub_inferred)

    tmp_path = CSV_PATH + ".tmp"
    with open(tmp_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp_path, CSV_PATH)

    print(f"Updated category_id for ~{updated} products. Wrote subcategory_id where inferred.")
    return 0


if __name__ == "__main__":
    sys.exit(main())