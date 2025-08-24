#!/usr/bin/env python3
import csv
import os

PATH = "/workspace/data/list.csv"

NEW_COLS = [
    ("weight", ""),           # grams
    ("availability", ""),     # 0,1,2
]

def main() -> int:
    with open(PATH, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    changed = False
    for name, default in NEW_COLS:
        if name not in fields:
            fields.append(name)
            for r in rows:
                r[name] = default
            changed = True

    if not changed:
        print("No changes; columns already present.")
        return 0

    tmp = PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, PATH)

    print("Added columns: weight, availability")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())