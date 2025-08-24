#!/usr/bin/env python3
import csv
import os
import shutil

BASE = "/workspace/data"
CATS = os.path.join(BASE, "categories_list.csv")
IMG_DIR = os.path.join(BASE, "images", "categories")


def main() -> int:
    with open(CATS, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    renamed = 0
    updated = 0

    for r in rows:
        cid_raw = (r.get("id") or "").strip()
        if not cid_raw:
            continue
        try:
            cid = int(float(cid_raw))
        except Exception:
            continue
        current = (r.get("primary_image") or "").strip()
        if not current:
            continue
        src_path = os.path.join(IMG_DIR, os.path.basename(current))
        if not os.path.isfile(src_path):
            continue
        dest_name = f"c{cid}.jpg"
        dest_path = os.path.join(IMG_DIR, dest_name)
        if os.path.abspath(src_path) != os.path.abspath(dest_path):
            shutil.copy2(src_path, dest_path)
            renamed += 1
        if r.get("primary_image") != dest_name:
            r["primary_image"] = dest_name
            updated += 1

    tmp = CATS + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, CATS)

    print(f"Renamed {renamed} images; updated {updated} category rows.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())