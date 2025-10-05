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

    if "validated" not in fields:
        fields.append("validated")
        for r in rows:
            r["validated"] = ""

    changed = 0
    for r in rows:
        rid = to_int(r.get("id", ""))
        if rid > 839:
            if r.get("validated") != "0":
                r["validated"] = "0"
                changed += 1

    with open(list_csv, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)

    print(f"validated set to 0 for {changed} rows with id>839")


if __name__ == "__main__":
    main()

