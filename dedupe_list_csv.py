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


def parse_id(value: str) -> Tuple[int, bool]:
    try:
        n = int(float((value or "").strip() or 0))
        return n, True
    except Exception:
        return 10**12, False  # Non-numeric ids go to the end


def dedupe_and_sort(rows: List[Dict[str, str]]) -> Tuple[List[Dict[str, str]], int]:
    seen: Dict[str, Dict[str, str]] = {}
    duplicates = 0
    for r in rows:
        rid = (r.get("id") or "").strip()
        if rid:
            if rid in seen:
                duplicates += 1
                continue  # Drop subsequent duplicates, keep first occurrence
            seen[rid] = r
        else:
            # Rows without id - assign a transient unique key to avoid accidental drop
            key = f"__noid__{id(r)}"
            seen[key] = r

    unique_rows = list(seen.values())
    # Sort by numeric id asc; non-numeric/no-id go last
    def sort_key(r: Dict[str, str]):
        n, ok = parse_id(r.get("id", ""))
        return (0 if ok else 1, n, (r.get("id") or ""))

    unique_rows.sort(key=sort_key)
    return unique_rows, duplicates


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    list_csv = os.path.join(base_dir, "data", "list.csv")
    rows, fields = load_csv(list_csv)
    new_rows, dup_cnt = dedupe_and_sort(rows)
    write_csv(list_csv, new_rows, fields)
    print(f"Deduplicated: removed {dup_cnt} duplicates; final rows: {len(new_rows)}")


if __name__ == "__main__":
    main()

