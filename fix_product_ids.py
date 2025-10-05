import csv
import os
from typing import List, Dict, Tuple


def load_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []
    return rows, fields


def write_csv(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def to_int(s: str) -> int:
    try:
        return int(float((s or "").strip() or 0))
    except Exception:
        return 0


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    list_csv = os.path.join(base_dir, "data", "list.csv")
    rows, fields = load_csv(list_csv)

    # Ensure 'product_id' field exists in header
    if "product_id" not in fields:
        fields.append("product_id")
        for r in rows:
            r["product_id"] = ""

    fixes = 0
    for r in rows:
        pid_num = to_int(r.get("id", ""))
        cat_num = to_int(r.get("category_id", ""))
        if pid_num <= 0 or cat_num <= 0:
            continue
        expected = f"p{cat_num}{pid_num}"
        current = (r.get("product_id") or "").strip()
        if current != expected:
            r["product_id"] = expected
            fixes += 1

    write_csv(list_csv, rows, fields)
    print(f"product_id fixes applied: {fixes}")


if __name__ == "__main__":
    main()

