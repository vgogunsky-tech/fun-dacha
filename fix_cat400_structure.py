import csv
import os


def to_int(s: str) -> int:
    try:
        return int(float((s or "").strip() or 0))
    except Exception:
        return 0


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    list_csv = os.path.join(base_dir, "data", "list.csv")

    with open(list_csv, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    # Ensure required fields
    if "category_id" not in fields:
        fields.append("category_id")
        for r in rows:
            r["category_id"] = ""
    if "subcategory_id" not in fields:
        fields.append("subcategory_id")
        for r in rows:
            r["subcategory_id"] = ""

    changed = 0
    for r in rows:
        cat_raw = (r.get("category_id") or "").strip()
        cat_num = to_int(cat_raw)
        # For categories starting with 40x (401..499), set parent 400 and move original to subcategory_id
        if cat_num >= 401 and cat_num <= 499:
            if cat_num != 400:
                # Only update if not already in desired shape
                if (r.get("category_id") or "").strip() != "400" or (r.get("subcategory_id") or "").strip() != str(cat_num):
                    r["subcategory_id"] = str(cat_num)
                    r["category_id"] = "400"
                    changed += 1

    with open(list_csv, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)

    print(f"Updated {changed} rows to category_id=400 with subcategory_id from 40x range")


if __name__ == "__main__":
    main()

