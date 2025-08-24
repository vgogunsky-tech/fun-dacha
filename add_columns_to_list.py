#!/usr/bin/env python3
import csv
import os

PATH = "/workspace/data/list.csv"


def main() -> int:
    with open(PATH, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    changed = False

    for col in ["validated", "price", "quantity"]:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""
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

    print("Added columns: validated, price, quantity")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())