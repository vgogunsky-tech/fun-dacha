#!/usr/bin/env python3
import csv
import os
import re
from typing import Dict, List, Tuple


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
LIST_CSV = os.path.join(DATA_DIR, "list.csv")


def read_products(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [dict(r) for r in reader]
        fields = list(reader.fieldnames or [])
    return rows, fields


def write_products(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in fields})
    os.replace(tmp, path)


def compile_patterns(parts):
    return [re.compile(p, re.IGNORECASE) for p in parts]


def catalog() -> Dict[str, List[re.Pattern]]:
    patterns: Dict[str, List[re.Pattern]] = {}
    # Reuse keys from generator for consistency
    patterns["early"] = compile_patterns([r"\bранн[іий]\b", r"ранній", r"ранний"]) 
    patterns["early_maturing"] = compile_patterns([r"ранньостигл", r"раннеспел"]) 
    patterns["mid_early"] = compile_patterns([r"середньоранн", r"среднеранн"]) 
    patterns["mid_maturing"] = compile_patterns([r"середньостигл", r"среднеспел"]) 
    patterns["mid_late"] = compile_patterns([r"середньопізн", r"среднепозд"]) 
    patterns["late"] = compile_patterns([r"\bпізн[іий]\b", r"пізній", r"поздн"]) 

    patterns["determinate"] = compile_patterns([r"детермінант", r"детерминант"]) 
    patterns["indeterminate"] = compile_patterns([r"індетермінант", r"индетерминант"]) 
    patterns["tall"] = compile_patterns([r"високоросл", r"высокоросл"]) 
    patterns["short"] = compile_patterns([r"низькоросл", r"низкоросл"]) 
    patterns["compact"] = compile_patterns([r"компактн"]) 
    patterns["sprawling"] = compile_patterns([r"розлог", r"раскидист"]) 

    patterns["salad"] = compile_patterns([r"салатн"]) 
    patterns["canning"] = compile_patterns([r"консерв"]) 
    patterns["pickling"] = compile_patterns([r"засол"]) 
    patterns["fresh"] = compile_patterns([r"свіж", r"свеж"]) 
    patterns["juice"] = compile_patterns([r"\bсік\b", r"\bсок"]) 
    patterns["paste"] = compile_patterns([r"паст"]) 
    patterns["sauce"] = compile_patterns([r"соус"]) 
    patterns["baby_food"] = compile_patterns([r"дитяч", r"детск.*питан"]) 
    patterns["universal"] = compile_patterns([r"універсальн", r"универсальн"]) 

    patterns["red"] = compile_patterns([r"червон", r"красн"]) 
    patterns["pink"] = compile_patterns([r"рожев", r"розов"]) 
    patterns["yellow"] = compile_patterns([r"жовт", r"желт"]) 
    patterns["orange"] = compile_patterns([r"оранж"]) 
    patterns["black"] = compile_patterns([r"чорн", r"чёрн", r"черн"]) 
    patterns["raspberry"] = compile_patterns([r"малинов"]) 
    patterns["brown"] = compile_patterns([r"коричнев"]) 

    patterns["round"] = compile_patterns([r"округл", r"кругл"]) 
    patterns["flat_round"] = compile_patterns([r"плоскоокругл"]) 
    patterns["elongated"] = compile_patterns([r"подовжен", r"удлинен"]) 
    patterns["oval"] = compile_patterns([r"овальн"]) 
    patterns["pear"] = compile_patterns([r"грушопод", r"грушевид"]) 
    patterns["cylindrical"] = compile_patterns([r"циліндр", r"цилиндр"]) 
    patterns["plum"] = compile_patterns([r"сливк"]) 

    patterns["sweet"] = compile_patterns([r"солодк", r"сладк"]) 
    patterns["meaty"] = compile_patterns([r"м[’']?ясист"]) 
    patterns["juicy"] = compile_patterns([r"соковит", r"сочн"]) 
    patterns["firm"] = compile_patterns([r"щільн", r"плотн"]) 
    patterns["crunchy"] = compile_patterns([r"хрустк"]) 
    patterns["keeping"] = compile_patterns([r"лежк"]) 
    patterns["transportable"] = compile_patterns([r"транспортабель"]) 

    patterns["disease_resistant"] = compile_patterns([r"стійк.*хвороб", r"устойчив.*болезн"]) 
    patterns["late_blight"] = compile_patterns([r"фітофтор", r"фитофтор"]) 
    patterns["fusarium"] = compile_patterns([r"фузаріоз", r"фузариоз"]) 
    patterns["alternaria"] = compile_patterns([r"альтернаріоз", r"альтернариоз"]) 
    patterns["septoria"] = compile_patterns([r"септор"]) 
    patterns["powdery_mildew"] = compile_patterns([r"мучнист", r"порошкоподібн", r"ложн.*мучнист"]) 
    patterns["drought_tolerant"] = compile_patterns([r"посух", r"засух"]) 
    patterns["cold_tolerant"] = compile_patterns([r"холодостійк|морозостійк", r"устойчив.*понижен"]) 
    patterns["shade_tolerant"] = compile_patterns([r"тіньовинос", r"теневынослив"]) 

    patterns["open_field"] = compile_patterns([r"відкрит.*грунт", r"открыт.*грунт"]) 
    patterns["greenhouse"] = compile_patterns([r"теплиц", r"плівков", r"пленоч"]) 
    patterns["bee_pollinated"] = compile_patterns([r"бджолозапил", r"пчелоопыл"]) 
    patterns["parthenocarpic"] = compile_patterns([r"партенокарп"]) 
    patterns["no_pinch"] = compile_patterns([r"без\s+пасинкуван", r"не\s+нужда.*пасынк"]) 
    patterns["needs_trellis"] = compile_patterns([r"підв'?язк", r"подвязк"]) 

    patterns["high_yield"] = compile_patterns([r"високоврожайн", r"высокоурожайн", r"урожайн(ий|ый)"]) 
    patterns["long_fruiting"] = compile_patterns([r"подовжен(ого)?\s*плодонош", r"продолжительн.*плодонош"]) 
    patterns["uniform_ripening"] = compile_patterns([r"дружн", r"дружн.*созрев"]) 

    patterns["no_green_shoulder"] = compile_patterns([r"без.*зелено.*плям.*плодоніж", r"без.*зел[её]н.*пятн.*плодонож"]) 
    patterns["thin_skin"] = compile_patterns([r"тонк(а|ою).*шкірк|тонк(ая|ой).*кожур"]) 
    patterns["few_seeds"] = compile_patterns([r"малонасінн", r"малосемянн"]) 
    patterns["long_storage"] = compile_patterns([r"довг(е|им).*зберіган|долго.*хран"]) 
    patterns["marketable"] = compile_patterns([r"товарн.*вигл", r"товарн.*вид"]) 
    return patterns


def main() -> int:
    rows, fields = read_products(LIST_CSV)
    if "tags" not in fields:
        fields.append("tags")
        for r in rows:
            r["tags"] = ""

    pats = catalog()
    for r in rows:
        texts = [
            (r.get("Описание (укр)") or ""),
            (r.get("Описание (рус)") or ""),
            (r.get("Название (укр)") or ""),
            (r.get("Название (рус)") or ""),
        ]
        found: List[str] = []
        for key, rx_list in pats.items():
            matched = False
            for t in texts:
                for rx in rx_list:
                    if rx.search(t):
                        matched = True
                        break
                if matched:
                    break
            if matched:
                found.append(key)
        # Keep unique order
        seen = set()
        uniq = []
        for k in found:
            if k in seen:
                continue
            seen.add(k)
            uniq.append(k)
        r["tags"] = ",".join(uniq)

    write_products(LIST_CSV, rows, fields)
    print("Updated tags column in list.csv")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

