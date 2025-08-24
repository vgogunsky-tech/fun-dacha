#!/usr/bin/env python3
import csv
import os

BASE = "/workspace/data"
CATS = os.path.join(BASE, "categories_list.csv")
IMG_DIR = os.path.join(BASE, "images", "categories")

PRIORITY_PATTERNS = [
    "c{cid}.jpg",
    "{cid}.jpg",
]


def main() -> int:
    with open(CATS, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    updated = 0

    for r in rows:
        cid_raw = (r.get("id") or "").strip()
        if not cid_raw:
            continue
        try:
            cid = int(float(cid_raw))
        except Exception:
            continue

        # Skip if already set to a file that exists
        cur = (r.get("primary_image") or "").strip()
        if cur and os.path.isfile(os.path.join(IMG_DIR, os.path.basename(cur))):
            continue

        # Try patterns
        chosen = None
        for pattern in PRIORITY_PATTERNS:
            filename = pattern.format(cid=cid)
            if os.path.isfile(os.path.join(IMG_DIR, filename)):
                chosen = filename
                break

        if chosen:
            if r.get("primary_image") != chosen:
                r["primary_image"] = chosen
                updated += 1

    tmp = CATS + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, CATS)

    print(f"Updated {updated} categories with available images.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())