#!/usr/bin/env python3
import csv
import os
import re
from typing import Dict, List, Tuple, Set


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
LIST_CSV = os.path.join(DATA_DIR, "list.csv")
OUTPUT_CSV = os.path.join(DATA_DIR, "tags.csv")


def read_products(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [dict(r) for r in reader]
        fields = list(reader.fieldnames or [])
    return rows, fields


def write_tags_csv(path: str, rows: List[Dict[str, str]]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fieldnames = ["category", "group", "key", "ua", "ru"]
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in fieldnames})
    os.replace(tmp, path)


def base_category(cat: str) -> str:
    cat = (cat or "").strip()
    if not cat:
        return ""
    # Normalize numeric id and set last digit to 0
    try:
        n = int(float(cat))
        s = str(n)
        if len(s) >= 1:
            s = s[:-1] + "0"
        return s
    except Exception:
        # Fallback: if endswith digit, replace with 0
        if cat[-1:].isdigit():
            return cat[:-1] + "0"
        return cat


def compile_patterns(parts: List[str]) -> List[re.Pattern]:
    return [re.compile(p, re.IGNORECASE) for p in parts]


def any_match(texts: List[str], patterns: List[re.Pattern]) -> bool:
    for t in texts:
        if not t:
            continue
        for rx in patterns:
            if rx.search(t):
                return True
    return False


def tags_catalog() -> Dict[str, Dict[str, Dict]]:
    # Structure: group -> key -> {ua, ru, patterns}
    G: Dict[str, Dict[str, Dict]] = {}

    # Maturity
    G.setdefault("Maturity", {})
    G["Maturity"]["early"] = {
        "ua": "Ранній",
        "ru": "Ранний",
        "patterns": compile_patterns([r"\bранн[іий]\b", r"\bранній\b", r"\bранний\b"]),
    }
    G["Maturity"]["early_maturing"] = {
        "ua": "Ранньостиглий",
        "ru": "Раннеспелый",
        "patterns": compile_patterns([r"ранньостигл", r"раннеспел"]),
    }
    G["Maturity"]["mid_early"] = {
        "ua": "Середньоранній",
        "ru": "Среднеранний",
        "patterns": compile_patterns([r"середньоранн", r"среднеранн"]),
    }
    G["Maturity"]["mid_maturing"] = {
        "ua": "Середньостиглий",
        "ru": "Среднеспелый",
        "patterns": compile_patterns([r"середньостигл", r"среднеспел"]),
    }
    G["Maturity"]["mid_late"] = {
        "ua": "Середньопізній",
        "ru": "Среднепоздний",
        "patterns": compile_patterns([r"середньопізн", r"среднепозд"]),
    }
    G["Maturity"]["late"] = {
        "ua": "Пізній",
        "ru": "Поздний",
        "patterns": compile_patterns([r"\bпізн[іий]\b", r"\bпізній\b", r"\bпоздн[ий]\b"]),
    }

    # Growth
    G.setdefault("Growth", {})
    G["Growth"]["determinate"] = {"ua": "Детермінантний", "ru": "Детерминантный", "patterns": compile_patterns([r"детермінант", r"детерминант"])}
    G["Growth"]["indeterminate"] = {"ua": "Індетермінантний", "ru": "Индетерминантный", "patterns": compile_patterns([r"індетермінант", r"индетерминант"])}
    G["Growth"]["tall"] = {"ua": "Високорослий", "ru": "Высокорослый", "patterns": compile_patterns([r"високоросл", r"высокоросл"])}
    G["Growth"]["short"] = {"ua": "Низькорослий", "ru": "Низкорослый", "patterns": compile_patterns([r"низькоросл", r"низкоросл"])}
    G["Growth"]["compact"] = {"ua": "Компактний", "ru": "Компактный", "patterns": compile_patterns([r"компактн"])}
    G["Growth"]["sprawling"] = {"ua": "Розлогий", "ru": "Раскидистый", "patterns": compile_patterns([r"розлог", r"раскидист"])}

    # Usage
    G.setdefault("Usage", {})
    G["Usage"]["salad"] = {"ua": "Салатний", "ru": "Салатный", "patterns": compile_patterns([r"салатн"])}
    G["Usage"]["canning"] = {"ua": "Консервування", "ru": "Консервирование", "patterns": compile_patterns([r"консерв"])}
    G["Usage"]["pickling"] = {"ua": "Засолювання", "ru": "Засолка", "patterns": compile_patterns([r"засол"])}
    G["Usage"]["fresh"] = {"ua": "Свіже споживання", "ru": "Свежее потребление", "patterns": compile_patterns([r"свіж", r"свеж"])}
    G["Usage"]["juice"] = {"ua": "Сік", "ru": "Сок", "patterns": compile_patterns([r"\bсік\b", r"\bсок"])}
    G["Usage"]["paste"] = {"ua": "Паста", "ru": "Паста", "patterns": compile_patterns([r"паст"])}
    G["Usage"]["sauce"] = {"ua": "Соус", "ru": "Соус", "patterns": compile_patterns([r"соус"])}
    G["Usage"]["baby_food"] = {"ua": "Дитяче харчування", "ru": "Детское питание", "patterns": compile_patterns([r"дитяч", r"детск.*питан"]) }
    G["Usage"]["universal"] = {"ua": "Універсальний", "ru": "Универсальный", "patterns": compile_patterns([r"універсальн", r"универсальн"])}

    # Color
    G.setdefault("Color", {})
    G["Color"]["red"] = {"ua": "Червоний", "ru": "Красный", "patterns": compile_patterns([r"червон", r"красн"]) }
    G["Color"]["pink"] = {"ua": "Рожевий", "ru": "Розовый", "patterns": compile_patterns([r"рожев", r"розов"]) }
    G["Color"]["yellow"] = {"ua": "Жовтий", "ru": "Жёлтый", "patterns": compile_patterns([r"жовт", r"желт"]) }
    G["Color"]["orange"] = {"ua": "Оранжевий", "ru": "Оранжевый", "patterns": compile_patterns([r"оранж"]) }
    G["Color"]["black"] = {"ua": "Чорний", "ru": "Чёрный", "patterns": compile_patterns([r"чорн", r"чёрн", r"черн"]) }
    G["Color"]["raspberry"] = {"ua": "Малиновий", "ru": "Малиновый", "patterns": compile_patterns([r"малинов"]) }
    G["Color"]["brown"] = {"ua": "Коричневий", "ru": "Коричневый", "patterns": compile_patterns([r"коричнев"]) }

    # Shape
    G.setdefault("Shape", {})
    G["Shape"]["round"] = {"ua": "Округлий", "ru": "Округлый", "patterns": compile_patterns([r"округл", r"кругл"]) }
    G["Shape"]["flat_round"] = {"ua": "Плоскоокруглий", "ru": "Плоскоокруглый", "patterns": compile_patterns([r"плоскоокругл"]) }
    G["Shape"]["elongated"] = {"ua": "Подовжений", "ru": "Удлинённый", "patterns": compile_patterns([r"подовжен", r"удлинен"]) }
    G["Shape"]["oval"] = {"ua": "Овальний", "ru": "Овальный", "patterns": compile_patterns([r"овальн"]) }
    G["Shape"]["pear"] = {"ua": "Грушоподібний", "ru": "Грушевидный", "patterns": compile_patterns([r"грушопод", r"грушевид"]) }
    G["Shape"]["cylindrical"] = {"ua": "Циліндричний", "ru": "Цилиндрический", "patterns": compile_patterns([r"циліндр", r"цилиндр"]) }
    G["Shape"]["plum"] = {"ua": "Сливка", "ru": "Сливка", "patterns": compile_patterns([r"сливк"]) }

    # Texture/Taste
    G.setdefault("Texture", {})
    G["Texture"]["sweet"] = {"ua": "Солодкий", "ru": "Сладкий", "patterns": compile_patterns([r"солодк", r"сладк"]) }
    G["Texture"]["meaty"] = {"ua": "М'ясистий", "ru": "Мясистый", "patterns": compile_patterns([r"м[’']?ясист"]) }
    G["Texture"]["juicy"] = {"ua": "Соковитий", "ru": "Сочный", "patterns": compile_patterns([r"соковит", r"сочн"]) }
    G["Texture"]["firm"] = {"ua": "Щільний", "ru": "Плотный", "patterns": compile_patterns([r"щільн", r"плотн"]) }
    G["Texture"]["crunchy"] = {"ua": "Хрусткий", "ru": "Хрустящий", "patterns": compile_patterns([r"хрустк"]) }
    G["Texture"]["keeping"] = {"ua": "Лежкий", "ru": "Лёжкий", "patterns": compile_patterns([r"лежк"]) }
    G["Texture"]["transportable"] = {"ua": "Транспортабельний", "ru": "Транспортабельный", "patterns": compile_patterns([r"транспортабель"]) }

    # Resistance/Tolerance
    G.setdefault("Resistance", {})
    G["Resistance"]["disease_resistant"] = {"ua": "Стійкий до хвороб", "ru": "Устойчив к болезням", "patterns": compile_patterns([r"стійк.*хвороб", r"устойчив.*болезн"]) }
    G["Resistance"]["late_blight"] = {"ua": "Фітофтороз", "ru": "Фитофтороз", "patterns": compile_patterns([r"фітофтор", r"фитофтор"]) }
    G["Resistance"]["fusarium"] = {"ua": "Фузаріоз", "ru": "Фузариоз", "patterns": compile_patterns([r"фузаріоз", r"фузариоз"]) }
    G["Resistance"]["alternaria"] = {"ua": "Альтернаріоз", "ru": "Альтернариоз", "patterns": compile_patterns([r"альтернаріоз", r"альтернариоз"]) }
    G["Resistance"]["septoria"] = {"ua": "Септоріоз", "ru": "Септориоз", "patterns": compile_patterns([r"септор"]) }
    G["Resistance"]["powdery_mildew"] = {"ua": "Мучниста роса", "ru": "Мучнистая роса", "patterns": compile_patterns([r"мучнист", r"порошкоподібн", r"ложн.*мучнист"]) }
    G["Resistance"]["drought_tolerant"] = {"ua": "Посухостійкий", "ru": "Засухоустойчивый", "patterns": compile_patterns([r"посух", r"засух"]) }
    G["Resistance"]["cold_tolerant"] = {"ua": "Холодостійкий", "ru": "Холодостойкий", "patterns": compile_patterns([r"холодостійк|морозостійк", r"устойчив.*понижен"]) }
    G["Resistance"]["shade_tolerant"] = {"ua": "Тіньовитривалий", "ru": "Теневыносливый", "patterns": compile_patterns([r"тіньовинос", r"теневынослив"]) }

    # Cultivation
    G.setdefault("Cultivation", {})
    G["Cultivation"]["open_field"] = {"ua": "Відкритий ґрунт", "ru": "Открытый грунт", "patterns": compile_patterns([r"відкрит.*грунт", r"открыт.*грунт"]) }
    G["Cultivation"]["greenhouse"] = {"ua": "Теплиця/укриття", "ru": "Теплица/укрытия", "patterns": compile_patterns([r"теплиц", r"плівков", r"пленоч"]) }
    G["Cultivation"]["bee_pollinated"] = {"ua": "Бджолозапилюваний", "ru": "Пчелоопыляемый", "patterns": compile_patterns([r"бджолозапил", r"пчелоопыл"]) }
    G["Cultivation"]["parthenocarpic"] = {"ua": "Партенокарпічний", "ru": "Партенокарпический", "patterns": compile_patterns([r"партенокарп"]) }
    G["Cultivation"]["no_pinch"] = {"ua": "Без пасинкування", "ru": "Без пасынкования", "patterns": compile_patterns([r"без\s+пасинкуван", r"не\s+нужда.*пасынк"]) }
    G["Cultivation"]["needs_trellis"] = {"ua": "Потребує підв'язки", "ru": "Требует подвязки", "patterns": compile_patterns([r"підв'?язк", r"подвязк"]) }

    # Yield
    G.setdefault("Yield", {})
    G["Yield"]["high_yield"] = {"ua": "Високоврожайний", "ru": "Высокоурожайный", "patterns": compile_patterns([r"високоврожайн", r"высокоурожайн", r"урожайн(ий|ый)"]) }
    G["Yield"]["long_fruiting"] = {"ua": "Тривале плодоношення", "ru": "Длительное плодоношение", "patterns": compile_patterns([r"подовжен(ого)?\s*плодонош", r"продолжительн.*плодонош"]) }
    G["Yield"]["uniform_ripening"] = {"ua": "Дружнє дозрівання", "ru": "Дружное созревание", "patterns": compile_patterns([r"дружн", r"дружн.*созрев"]) }

    # Traits
    G.setdefault("Traits", {})
    G["Traits"]["no_green_shoulder"] = {"ua": "Без зеленої плями біля плодоніжки", "ru": "Без зелёного пятна у плодоножки", "patterns": compile_patterns([r"без.*зелено.*плям.*плодоніж", r"без.*зел[её]н.*пятн.*плодонож"]) }
    G["Traits"]["thin_skin"] = {"ua": "Тонка шкірка", "ru": "Тонкая кожура", "patterns": compile_patterns([r"тонк(а|ою).*шкірк|тонк(ая|ой).*кожур"]) }
    G["Traits"]["few_seeds"] = {"ua": "Малонасінневий", "ru": "Малосемянный", "patterns": compile_patterns([r"малонасінн", r"малосемянн"]) }
    G["Traits"]["long_storage"] = {"ua": "Довге зберігання", "ru": "Долгое хранение", "patterns": compile_patterns([r"довг(е|им).*зберіган|долго.*хран"]) }
    G["Traits"]["marketable"] = {"ua": "Товарний вигляд", "ru": "Товарный вид", "patterns": compile_patterns([r"товарн.*вигл", r"товарн.*вид"]) }

    return G


def main() -> int:
    products, fields = read_products(LIST_CSV)
    cat_tags: Dict[str, Dict[str, Set[str]]] = {}
    catalog = tags_catalog()

    for r in products:
        cat = base_category(r.get("category_id", ""))
        if not cat:
            continue
        texts = [
            (r.get("Описание (укр)") or ""),
            (r.get("Описание (рус)") or ""),
            (r.get("Название (укр)") or ""),
            (r.get("Название (рус)") or ""),
        ]
        for group_name, tags in catalog.items():
            for key, meta in tags.items():
                if any_match(texts, meta.get("patterns", [])):
                    cat_tags.setdefault(cat, {}).setdefault(group_name, set()).add(key)

    # Build CSV rows
    out_rows: List[Dict[str, str]] = []
    for cat in sorted(cat_tags.keys(), key=lambda x: (len(x), x)):
        group_map = cat_tags[cat]
        for group_name in sorted(group_map.keys()):
            for key in sorted(group_map[group_name]):
                meta = catalog[group_name][key]
                out_rows.append({
                    "category": cat,
                    "group": group_name,
                    "key": key,
                    "ua": meta["ua"],
                    "ru": meta["ru"],
                })

    write_tags_csv(OUTPUT_CSV, out_rows)
    print(f"Wrote {len(out_rows)} tag rows to {OUTPUT_CSV}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

