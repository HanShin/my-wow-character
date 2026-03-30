#!/usr/bin/env python3
from __future__ import annotations
import datetime as dt
import html
import json
import pathlib
import re
import urllib.request
import urllib.parse


ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "MidnightBisGuide" / "Data" / "SeasonData.lua"
CONTENT_OUTPUT = ROOT / "MidnightBisGuide" / "Data" / "SeasonContent.lua"


SPEC_ENTRIES = [
    {"specID": 250, "classFile": "DEATHKNIGHT", "name": "Blood", "guide": "blood-death-knight-pve-tank-guide"},
    {"specID": 251, "classFile": "DEATHKNIGHT", "name": "Frost", "guide": "frost-death-knight-pve-dps-guide"},
    {"specID": 252, "classFile": "DEATHKNIGHT", "name": "Unholy", "guide": "unholy-death-knight-pve-dps-guide"},
    {"specID": 577, "classFile": "DEMONHUNTER", "name": "Havoc", "guide": "havoc-demon-hunter-pve-dps-guide"},
    {"specID": 581, "classFile": "DEMONHUNTER", "name": "Vengeance", "guide": "vengeance-demon-hunter-pve-tank-guide"},
    {"specID": 1480, "classFile": "DEMONHUNTER", "name": "Devourer", "guide": "devourer-demon-hunter-pve-dps-guide"},
    {"specID": 102, "classFile": "DRUID", "name": "Balance", "guide": "balance-druid-pve-dps-guide"},
    {"specID": 103, "classFile": "DRUID", "name": "Feral", "guide": "feral-druid-pve-dps-guide"},
    {"specID": 104, "classFile": "DRUID", "name": "Guardian", "guide": "guardian-druid-pve-tank-guide"},
    {"specID": 105, "classFile": "DRUID", "name": "Restoration", "guide": "restoration-druid-pve-healing-guide"},
    {"specID": 1467, "classFile": "EVOKER", "name": "Devastation", "guide": "devastation-evoker-pve-dps-guide"},
    {"specID": 1468, "classFile": "EVOKER", "name": "Preservation", "guide": "preservation-evoker-pve-healing-guide"},
    {"specID": 1473, "classFile": "EVOKER", "name": "Augmentation", "guide": "augmentation-evoker-pve-dps-guide"},
    {"specID": 253, "classFile": "HUNTER", "name": "Beast Mastery", "guide": "beast-mastery-hunter-pve-dps-guide"},
    {"specID": 254, "classFile": "HUNTER", "name": "Marksmanship", "guide": "marksmanship-hunter-pve-dps-guide"},
    {"specID": 255, "classFile": "HUNTER", "name": "Survival", "guide": "survival-hunter-pve-dps-guide"},
    {"specID": 62, "classFile": "MAGE", "name": "Arcane", "guide": "arcane-mage-pve-dps-guide"},
    {"specID": 63, "classFile": "MAGE", "name": "Fire", "guide": "fire-mage-pve-dps-guide"},
    {"specID": 64, "classFile": "MAGE", "name": "Frost", "guide": "frost-mage-pve-dps-guide"},
    {"specID": 268, "classFile": "MONK", "name": "Brewmaster", "guide": "brewmaster-monk-pve-tank-guide"},
    {"specID": 270, "classFile": "MONK", "name": "Mistweaver", "guide": "mistweaver-monk-pve-healing-guide"},
    {"specID": 269, "classFile": "MONK", "name": "Windwalker", "guide": "windwalker-monk-pve-dps-guide"},
    {"specID": 65, "classFile": "PALADIN", "name": "Holy", "guide": "holy-paladin-pve-healing-guide"},
    {"specID": 66, "classFile": "PALADIN", "name": "Protection", "guide": "protection-paladin-pve-tank-guide"},
    {"specID": 70, "classFile": "PALADIN", "name": "Retribution", "guide": "retribution-paladin-pve-dps-guide"},
    {"specID": 256, "classFile": "PRIEST", "name": "Discipline", "guide": "discipline-priest-pve-healing-guide"},
    {"specID": 257, "classFile": "PRIEST", "name": "Holy", "guide": "holy-priest-pve-healing-guide"},
    {"specID": 258, "classFile": "PRIEST", "name": "Shadow", "guide": "shadow-priest-pve-dps-guide"},
    {"specID": 259, "classFile": "ROGUE", "name": "Assassination", "guide": "assassination-rogue-pve-dps-guide"},
    {"specID": 260, "classFile": "ROGUE", "name": "Outlaw", "guide": "outlaw-rogue-pve-dps-guide"},
    {"specID": 261, "classFile": "ROGUE", "name": "Subtlety", "guide": "subtlety-rogue-pve-dps-guide"},
    {"specID": 262, "classFile": "SHAMAN", "name": "Elemental", "guide": "elemental-shaman-pve-dps-guide"},
    {"specID": 263, "classFile": "SHAMAN", "name": "Enhancement", "guide": "enhancement-shaman-pve-dps-guide"},
    {"specID": 264, "classFile": "SHAMAN", "name": "Restoration", "guide": "restoration-shaman-pve-healing-guide"},
    {"specID": 265, "classFile": "WARLOCK", "name": "Affliction", "guide": "affliction-warlock-pve-dps-guide"},
    {"specID": 266, "classFile": "WARLOCK", "name": "Demonology", "guide": "demonology-warlock-pve-dps-guide"},
    {"specID": 267, "classFile": "WARLOCK", "name": "Destruction", "guide": "destruction-warlock-pve-dps-guide"},
    {"specID": 71, "classFile": "WARRIOR", "name": "Arms", "guide": "arms-warrior-pve-dps-guide"},
    {"specID": 72, "classFile": "WARRIOR", "name": "Fury", "guide": "fury-warrior-pve-dps-guide"},
    {"specID": 73, "classFile": "WARRIOR", "name": "Protection", "guide": "protection-warrior-pve-tank-guide"},
]


SLOT_MAP = {
    "Head": "HEAD",
    "Neck": "NECK",
    "Shoulder": "SHOULDER",
    "Shoulders": "SHOULDER",
    "Cloak": "BACK",
    "Back": "BACK",
    "Chest": "CHEST",
    "Wrists": "WRIST",
    "Wrist": "WRIST",
    "Hands": "HANDS",
    "Gloves": "HANDS",
    "Belt": "WAIST",
    "Waist": "WAIST",
    "Legs": "LEGS",
    "Feet": "FEET",
    "Ring #1": "FINGER1",
    "Ring #2": "FINGER2",
    "Trinket #1": "TRINKET1",
    "Trinket #2": "TRINKET2",
    "Weapon": "MAINHAND",
    "Weapon #1": "MAINHAND",
    "Weapon #2": "OFFHAND",
    "Main Hand": "MAINHAND",
    "Off-Hand": "OFFHAND",
    "Off Hand": "OFFHAND",
}


HEADERS = {
    "User-Agent": "Mozilla/5.0 MidnightBiSGuide/0.1",
}


CLASS_SLUGS = {
    "DEATHKNIGHT": "death-knight",
    "DEMONHUNTER": "demon-hunter",
    "DRUID": "druid",
    "EVOKER": "evoker",
    "HUNTER": "hunter",
    "MAGE": "mage",
    "MONK": "monk",
    "PALADIN": "paladin",
    "PRIEST": "priest",
    "ROGUE": "rogue",
    "SHAMAN": "shaman",
    "WARLOCK": "warlock",
    "WARRIOR": "warrior",
}


CLASS_DISPLAY_NAMES = {
    "DEATHKNIGHT": "Death Knight",
    "DEMONHUNTER": "Demon Hunter",
    "DRUID": "Druid",
    "EVOKER": "Evoker",
    "HUNTER": "Hunter",
    "MAGE": "Mage",
    "MONK": "Monk",
    "PALADIN": "Paladin",
    "PRIEST": "Priest",
    "ROGUE": "Rogue",
    "SHAMAN": "Shaman",
    "WARLOCK": "Warlock",
    "WARRIOR": "Warrior",
}


KNOWN_WOWHEAD_DUNGEONS = {
    "Algeth'ar Academy",
    "Magister's Terrace",
    "Maisara Caverns",
    "Nexus Point Xenas",
    "Nexus-Point Xenas",
    "Pit of Saron",
    "Seat of the Triumvirate",
    "Skyreach",
    "Windrunner Spire",
}


WOWHEAD_RAID_INSTANCE_PATTERNS = [
    ("march-on-quel-danas", "March on Quel'Danas"),
    ("the-voidspire", "The Voidspire"),
    ("the-dreamrift", "The Dreamrift"),
]


DUNGEON_GUIDES = [
    {
        "sourceName": "Magister's Terrace",
        "guideUrl": "https://www.icy-veins.com/wow/magisters-terrace-dungeon-guide",
    },
    {
        "sourceName": "Maisara Caverns",
        "guideUrl": "https://www.icy-veins.com/wow/maisara-caverns-dungeon-guide",
    },
    {
        "sourceName": "Nexus-Point Xenas",
        "guideUrl": "https://www.icy-veins.com/wow/nexus-point-xenas-dungeon-guide",
    },
    {
        "sourceName": "Windrunner Spire",
        "guideUrl": "https://www.icy-veins.com/wow/windrunner-spire-dungeon-guide",
    },
    {
        "sourceName": "Pit of Saron",
        "guideUrl": "https://www.icy-veins.com/wow/pit-of-saron-dungeon-guide",
    },
    {
        "sourceName": "Seat of the Triumvirate",
        "guideUrl": "https://www.icy-veins.com/wow/seat-of-the-triumvirate-dungeon-guide",
    },
    {
        "sourceName": "Skyreach",
        "guideUrl": "https://www.icy-veins.com/wow/skyreach-dungeon-guide",
    },
    {
        "sourceName": "Algeth'ar Academy",
        "guideUrl": "https://www.icy-veins.com/wow/algethar-academy-dungeon-guide",
    },
]


RAID_OVERVIEWS = [
    {
        "sourceName": "The Voidspire",
        "overviewUrl": "https://www.wowhead.com/guide/midnight/raids/the-voidspire-overview-location-rewards-bosses",
    },
    {
        "sourceName": "The Dreamrift",
        "overviewUrl": "https://www.wowhead.com/guide/midnight/raids/the-dreamrift-overview-location-rewards-boss",
    },
    {
        "sourceName": "March on Quel'Danas",
        "overviewUrl": "https://www.wowhead.com/guide/midnight/raids/march-on-quel-danas-overview-location-rewards-bosses",
    },
]


CLASS_ARMOR_TYPES = {
    "DEATHKNIGHT": "plate",
    "DEMONHUNTER": "leather",
    "DRUID": "leather",
    "EVOKER": "mail",
    "HUNTER": "mail",
    "MAGE": "cloth",
    "MONK": "leather",
    "PALADIN": "plate",
    "PRIEST": "cloth",
    "ROGUE": "leather",
    "SHAMAN": "mail",
    "WARLOCK": "cloth",
    "WARRIOR": "plate",
}


SPEC_PRIMARY_STATS = {
    62: "int",
    63: "int",
    64: "int",
    65: "int",
    66: "str",
    70: "str",
    71: "str",
    72: "str",
    73: "str",
    102: "int",
    103: "agi",
    104: "agi",
    105: "int",
    1467: "int",
    1468: "int",
    1473: "int",
    1480: "agi",
    250: "str",
    251: "str",
    252: "str",
    253: "agi",
    254: "agi",
    255: "agi",
    256: "int",
    257: "int",
    258: "int",
    259: "agi",
    260: "agi",
    261: "agi",
    262: "int",
    263: "agi",
    264: "int",
    265: "int",
    266: "int",
    267: "int",
    268: "agi",
    269: "agi",
    270: "int",
    577: "agi",
    581: "agi",
}


SLOTBAK_MAP = {
    1: "HEAD",
    2: "NECK",
    3: "SHOULDER",
    5: "CHEST",
    6: "WAIST",
    7: "LEGS",
    8: "FEET",
    9: "WRIST",
    10: "HANDS",
    11: "FINGER",
    12: "TRINKET",
    13: "WEAPON_1H",
    14: "OFFHAND",
    15: "MAINHAND",
    16: "BACK",
    17: "MAINHAND",
    20: "CHEST",
    21: "MAINHAND",
    22: "OFFHAND",
    23: "OFFHAND",
}


SECONDARY_STAT_LABELS = {
    "critstrkrtng": "Crit",
    "hastertng": "Haste",
    "mastrtng": "Mastery",
    "versrtng": "Vers",
}


PRIMARY_STAT_LABELS = {
    "agi": "Agi",
    "int": "Int",
    "str": "Strength",
}


def fetch(url: str) -> str:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def icy_guide_url(entry: dict) -> str:
    return f"https://www.icy-veins.com/wow/{entry['guide'].replace('-guide', '-gear-best-in-slot')}"


def wowhead_direct_bis_url(entry: dict) -> str:
    class_slug = CLASS_SLUGS[entry["classFile"]]
    guide_slug = entry["guide"]
    for suffix in ("-pve-dps-guide", "-pve-tank-guide", "-pve-healing-guide"):
        if guide_slug.endswith(suffix):
            guide_slug = guide_slug[: -len(suffix)]
            break
    spec_slug = guide_slug
    class_suffix = f"-{class_slug}"
    if spec_slug.endswith(class_suffix):
        spec_slug = spec_slug[: -len(class_suffix)]
    return f"https://www.wowhead.com/guide/classes/{class_slug}/{spec_slug}/bis-gear"


def wowhead_search_bis_url(entry: dict) -> str | None:
    query = urllib.parse.quote_plus(
        f'{entry["name"]} {CLASS_DISPLAY_NAMES[entry["classFile"]]} Gear and Best in Slot Midnight'
    )
    search_html = fetch(f"https://www.wowhead.com/search?q={query}")
    pattern = rf'"url":"(https:\\/\\/www\\.wowhead\\.com\\/guide\\/classes\\/{CLASS_SLUGS[entry["classFile"]]}\\/[^"]+\\/bis-gear)"'
    match = re.search(pattern, search_html)
    if not match:
        return None
    return match.group(1).replace("\\/", "/")


def fetch_wowhead_bis_page(entry: dict) -> tuple[str, str]:
    direct_url = wowhead_direct_bis_url(entry)
    try:
        return direct_url, fetch(direct_url)
    except Exception:  # noqa: BLE001
        discovered = wowhead_search_bis_url(entry)
        if not discovered:
            raise
        return discovered, fetch(discovered)


def strip_tags(value: str) -> str:
    value = re.sub(r"<br\s*/?>", "\n", value, flags=re.I)
    value = re.sub(r"</p>", "\n", value, flags=re.I)
    value = re.sub(r"<[^>]+>", "", value)
    value = html.unescape(value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def lua_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def extract_table(page_html: str, area_id: str) -> str | None:
    marker = f'<div class="image_block_content" id="{area_id}">'
    start = page_html.find(marker)
    if start == -1:
        return None
    table_start = page_html.find("<table>", start)
    if table_start == -1:
        return None
    table_end = page_html.find("</table>", table_start)
    if table_end == -1:
        return None
    return page_html[table_start:table_end + len("</table>")]


def parse_source(cell_html: str) -> dict:
    anchors = [
        {"href": href, "text": strip_tags(text)}
        for href, text in re.findall(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', cell_html, re.S)
    ]
    text = strip_tags(cell_html)
    lowered = text.lower()

    source_type = "other"
    source_name = text
    boss_name = None
    notes = []

    raid_guide = next((a for a in anchors if "midnight-season-1-raid-guide" in a["href"]), None)
    raid_boss = next((a for a in anchors if "raid-guide" in a["href"] and "midnight-season-1-raid-guide" not in a["href"]), None)
    dungeon = next((a for a in anchors if "dungeon-guide" in a["href"]), None)

    if "crafted" in lowered:
        source_type = "crafted"
        professions = [
            a["text"]
            for a in anchors
            if "professions-" in a["href"] and "making-gold" not in a["href"]
        ]
        source_name = professions[0] if professions else "Crafted"
    elif "great vault" in lowered:
        source_type = "weekly_vault"
        source_name = "Great Vault"
    elif dungeon:
        source_type = "dungeon"
        source_name = dungeon["text"]
    elif raid_guide:
        source_type = "raid"
        source_name = raid_guide["text"]
        boss_name = raid_boss["text"] if raid_boss else None
    elif "matrix catalyst" in lowered:
        source_type = "catalyst"
        source_name = "Matrix Catalyst"
    elif "delve" in lowered:
        source_type = "other"
        source_name = text

    if "matrix catalyst" in lowered and source_type != "catalyst":
        notes.append("Matrix Catalyst")
    if "great vault" in lowered and source_type != "weekly_vault":
        notes.append("Great Vault")

    return {
        "sourceType": source_type,
        "sourceName": source_name,
        "bossName": boss_name,
        "notes": "; ".join(notes) or None,
        "rawText": text,
    }


def parse_item(cell_html: str, slot_key: str, source_data: dict) -> dict | None:
    matches = re.findall(r'data-wowhead="item=(\d+)[^"]*"[^>]*>([^<]+)</span>', cell_html, re.S)
    if not matches:
        return None

    item_id, item_name = matches[0]
    text = strip_tags(cell_html)

    notes = []
    if "(" in text and ")" in text:
        parenthetical = re.findall(r"\(([^)]+)\)", text)
        for note in parenthetical:
            if note:
                notes.append(note)
    if " and " in text and len(matches) > 1:
        notes.append(text)

    item = {
        "itemID": int(item_id),
        "name": html.unescape(item_name).strip(),
        "slotKey": slot_key,
        "sourceType": source_data["sourceType"],
        "sourceName": source_data["sourceName"],
        "bossName": source_data["bossName"],
        "notes": "; ".join(filter(None, [source_data["notes"]] + notes)) or None,
        "isTier": "matrix catalyst" in source_data["rawText"].lower(),
        "isCrafted": source_data["sourceType"] == "crafted",
    }
    return item


def parse_table(table_html: str) -> dict:
    slots = {}
    if not table_html:
        return slots

    rows = re.findall(r"<tr>(.*?)</tr>", table_html, re.S)
    for row_html in rows[1:]:
        cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row_html, re.S)
        if len(cells) < 3:
            continue
        slot_label = strip_tags(cells[0])
        slot_key = SLOT_MAP.get(slot_label)
        if not slot_key:
            continue
        source_data = parse_source(cells[2])
        item = parse_item(cells[1], slot_key, source_data)
        if item:
            slots[slot_key] = item
    return slots


def dedupe_items(items: list[dict | None], excluded_id: int | None = None) -> list[dict]:
    seen = set()
    result = []
    for item in items:
        if not item:
            continue
        item_id = item.get("itemID")
        if item_id is None or item_id == excluded_id or item_id in seen:
            continue
        result.append(item)
        seen.add(item_id)
    return result


def choose_no_raid_best(overall: dict | None, mythic: dict | None) -> tuple[dict | None, list[dict]]:
    if overall and overall.get("sourceType") != "raid":
        return overall, dedupe_items([mythic], overall.get("itemID"))

    if mythic:
        return mythic, []

    return None, []


def build_profiles(overall_slots: dict, mythic_slots: dict, raid_slots: dict) -> dict:
    all_slot_keys = sorted(set(overall_slots) | set(mythic_slots) | set(raid_slots))
    with_raid_slots = {}
    no_raid_slots = {}

    for slot_key in all_slot_keys:
        overall_item = overall_slots.get(slot_key)
        mythic_item = mythic_slots.get(slot_key)
        raid_item = raid_slots.get(slot_key)

        with_best = overall_item or raid_item or mythic_item
        with_alts = dedupe_items([mythic_item, raid_item], with_best.get("itemID") if with_best else None)

        no_best, no_alts = choose_no_raid_best(overall_item, mythic_item)

        with_raid_slots[slot_key] = {
            "best": with_best,
            "alternatives": with_alts,
        }
        no_raid_slots[slot_key] = {
            "best": no_best,
            "alternatives": no_alts,
        }

    return {"withRaid": with_raid_slots, "noRaid": no_raid_slots}


def infer_slot_category(type_label: str) -> str | None:
    lowered = (type_label or "").strip().lower()
    if not lowered:
        return None

    if "neck" in lowered:
        return "NECK"
    if "head" in lowered or "helm" in lowered:
        return "HEAD"
    if "shoulder" in lowered:
        return "SHOULDER"
    if "cloak" in lowered or "back" in lowered:
        return "BACK"
    if "chest" in lowered:
        return "CHEST"
    if "wrist" in lowered or "bracer" in lowered:
        return "WRIST"
    if "hands" in lowered or "gloves" in lowered:
        return "HANDS"
    if "waist" in lowered or "belt" in lowered:
        return "WAIST"
    if "legs" in lowered:
        return "LEGS"
    if "feet" in lowered or "boots" in lowered:
        return "FEET"
    if "ring" in lowered or "finger" in lowered:
        return "FINGER"
    if "trinket" in lowered:
        return "TRINKET"
    if "shield" in lowered or "off-hand" in lowered or "off hand" in lowered or "held in off-hand" in lowered:
        return "OFFHAND"
    if "2h" in lowered or "staff" in lowered or "polearm" in lowered or "bow" in lowered or "gun" in lowered or "crossbow" in lowered:
        return "MAINHAND"
    if "1h" in lowered or "sword" in lowered or "axe" in lowered or "mace" in lowered or "dagger" in lowered or "wand" in lowered or "fist" in lowered or "warglaive" in lowered:
        return "WEAPON_1H"
    return None


def canonical_slot(slot_key: str | None) -> str | None:
    if slot_key in {"FINGER1", "FINGER2"}:
        return "FINGER"
    if slot_key in {"TRINKET1", "TRINKET2"}:
        return "TRINKET"
    return slot_key


def item_matches_slot(item_slot: str | None, target_slot: str | None) -> bool:
    item_slot = canonical_slot(item_slot)
    target_slot = canonical_slot(target_slot)
    if not item_slot or not target_slot:
        return False
    if target_slot == "MAINHAND":
        return item_slot in {"MAINHAND", "WEAPON_1H"}
    if target_slot == "OFFHAND":
        return item_slot in {"OFFHAND", "WEAPON_1H"}
    return item_slot == target_slot


def slotbak_to_slot_category(slotbak: int | None) -> str | None:
    if slotbak is None:
        return None
    return SLOTBAK_MAP.get(int(slotbak))


def build_stats_label(item_info: dict) -> str | None:
    jsonequip = item_info.get("jsonequip", {})
    secondary = [label for key, label in SECONDARY_STAT_LABELS.items() if jsonequip.get(key)]
    if secondary:
        return "/".join(secondary[:2])

    primary = [label for key, label in PRIMARY_STAT_LABELS.items() if jsonequip.get(key)]
    if primary:
        return "/".join(primary[:2])

    return None


def build_item_from_wowhead_data(
    item_id: int,
    item_info: dict,
    *,
    slot_key: str | None = None,
    slot_category: str | None = None,
    source_type: str = "other",
    source_name: str = "Unknown",
    boss_name: str | None = None,
    notes: str | None = None,
    type_label: str | None = None,
    stats: str | None = None,
    is_tier: bool = False,
    is_crafted: bool = False,
) -> dict:
    jsonequip = item_info.get("jsonequip", {})
    derived_slot = slot_category or slot_key or slotbak_to_slot_category(jsonequip.get("slotbak"))
    return {
        "itemID": item_id,
        "name": item_info.get("name_enus") or f"Item {item_id}",
        "slotKey": slot_key or derived_slot or "OTHER",
        "slotCategory": derived_slot or slot_key or "OTHER",
        "sourceType": source_type,
        "sourceName": source_name,
        "bossName": boss_name,
        "typeLabel": type_label,
        "stats": stats or build_stats_label(item_info),
        "notes": notes,
        "isTier": is_tier,
        "isCrafted": is_crafted,
    }


def extract_season_items_index(collections: list[dict]) -> dict[int, dict]:
    index = {}
    for collection in collections:
        for boss in collection["bosses"]:
            for item in boss["items"]:
                index[item["itemID"]] = item
    return index


def parse_dungeon_loot_tables(page_html: str, source_name: str) -> list[dict]:
    loot_heading = re.search(
        r'<h2 id="[^"]+-loot-table">.*?Loot Table</h2>',
        page_html,
        re.I | re.S,
    )
    if not loot_heading:
        return []

    start = loot_heading.start()
    end_match = re.search(r'<div class="heading_container heading_number_2"><span >\d+\.</span> <h2 id="[^"]+">', page_html[start + 1 :], re.S)
    end = start + 1 + end_match.start() if end_match else len(page_html)
    loot_html = page_html[start:end]

    bosses = []
    boss_sections = re.findall(r"<h3 id=\"[^\"]+\">(.*?)</h3>\s*</div>\s*<table>(.*?)</table>", loot_html, re.S)
    for boss_name_html, table_html in boss_sections:
        boss_name = strip_tags(boss_name_html)
        rows = re.findall(r"<tr>(.*?)</tr>", table_html, re.S)
        items = []
        for row_html in rows[1:]:
            cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row_html, re.S)
            if len(cells) < 3:
                continue

            type_label = strip_tags(cells[0])
            slot_category = infer_slot_category(type_label)
            item_match = re.search(r'data-wowhead="item=(\d+)[^"]*"[^>]*>([^<]+)</span>', cells[1], re.S)
            if not item_match:
                continue

            item_id, item_name = item_match.groups()
            items.append(
                {
                    "itemID": int(item_id),
                    "name": html.unescape(item_name).strip(),
                    "slotKey": slot_category or "OTHER",
                    "slotCategory": slot_category or "OTHER",
                    "sourceType": "dungeon",
                    "sourceName": source_name,
                    "bossName": boss_name,
                    "typeLabel": type_label,
                    "stats": strip_tags(cells[2]) or None,
                    "isTier": False,
                    "isCrafted": False,
                }
            )

        bosses.append(
            {
                "name": boss_name,
                "items": items,
            }
        )

    return bosses


def strip_wowhead_markup(value: str) -> str:
    if not value:
        return ""
    value = re.sub(r"\[/?[^\]]+\]", "", value)
    value = html.unescape(value.replace("\\/", "/"))
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def extract_wowhead_markup(page_html: str) -> str:
    match = re.search(r'WH\.markup\.printHtml\("(.*?)", "guide-body"', page_html, re.S)
    if not match:
        raise ValueError("Could not find Wowhead guide body markup")
    return json.loads(f'"{match.group(1)}"')


def extract_wowhead_data(page_html: str, type_id: int) -> dict:
    match = re.search(rf"WH\.Gatherer\.addData\({type_id}, 1, (\{{.*?\}})\);", page_html, re.S)
    if not match:
        return {}
    return json.loads(match.group(1))


def normalize_wowhead_source(source_markup: str, guide_id: int | None, guide_map: dict) -> dict:
    source_text = strip_wowhead_markup(source_markup)
    guide_matches = [
        (int(match.group(1)), strip_wowhead_markup(match.group(2)))
        for match in re.finditer(r"\[url guide=(\d+)\](.*?)\[/url\]", source_markup, re.S)
    ]
    resolved_guides = [((guide_map.get(str(match_id)) or {}), label) for match_id, label in guide_matches]
    guide_info = (guide_map.get(str(guide_id)) or {}) if guide_id is not None else {}
    guide_name = guide_info.get("name", "")
    guide_url = guide_info.get("url", "")

    if "[skill=" in source_markup or source_text in {"Crafting", "Crafted"} or guide_id == 15942:
        return {
            "sourceType": "crafted",
            "sourceName": "Crafted",
            "bossName": None,
            "notes": None,
        }

    if "Catalyst" in source_text or source_text == "Tier Set" or guide_id == 31892:
        return {
            "sourceType": "catalyst",
            "sourceName": "Tier Set",
            "bossName": None,
            "notes": "Creation Catalyst",
        }

    if "Vault" in source_text or guide_id == 17592:
        return {
            "sourceType": "weekly_vault",
            "sourceName": "Great Vault",
            "bossName": None,
            "notes": None,
        }

    for resolved, label in resolved_guides:
        resolved_name = resolved.get("name", "")
        if "Dungeon Overview" in resolved_name or "Mythic+" in resolved_name or label in KNOWN_WOWHEAD_DUNGEONS:
            dungeon_name = label or resolved_name.split(" Dungeon Overview", 1)[0]
            return {
                "sourceType": "dungeon",
                "sourceName": dungeon_name,
                "bossName": None,
                "notes": None,
            }

    if "Dungeon Overview" in guide_name or "Mythic+" in guide_name or source_text in KNOWN_WOWHEAD_DUNGEONS:
        dungeon_name = source_text or guide_name.split(" Dungeon Overview", 1)[0]
        return {
            "sourceType": "dungeon",
            "sourceName": dungeon_name,
            "bossName": None,
            "notes": None,
        }

    for resolved, label in resolved_guides:
        resolved_name = resolved.get("name", "")
        resolved_url = resolved.get("url", "")
        if "/guide/midnight/raids/" in resolved_url or "Raid Boss Guide" in resolved_name or "Raid Boss Cheatsheet" in resolved_name:
            instance_name = None
            for needle, replacement in WOWHEAD_RAID_INSTANCE_PATTERNS:
                if needle in resolved_url:
                    instance_name = replacement
                    break

            boss_name = label or None
            if not boss_name and resolved_name:
                boss_name = resolved_name.split(" Raid Boss", 1)[0].split(" Cheatsheet", 1)[0].strip()

            return {
                "sourceType": "raid",
                "sourceName": instance_name or "Raid",
                "bossName": boss_name,
                "notes": None,
            }

    if "/guide/midnight/raids/" in guide_url or "Raid Boss Guide" in guide_name or "Raid Boss Cheatsheet" in guide_name:
        instance_name = None
        for needle, replacement in WOWHEAD_RAID_INSTANCE_PATTERNS:
            if needle in guide_url:
                instance_name = replacement
                break

        boss_name = source_text or None
        if not boss_name and guide_name:
            boss_name = guide_name.split(" Raid Boss", 1)[0].split(" Cheatsheet", 1)[0].strip()

        return {
            "sourceType": "raid",
            "sourceName": instance_name or "Raid",
            "bossName": boss_name,
            "notes": None,
        }

    return {
        "sourceType": "other",
        "sourceName": source_text or guide_name or "Unknown",
        "bossName": None,
        "notes": None,
    }


def parse_wowhead_overall_bis(page_html: str) -> dict:
    markup = extract_wowhead_markup(page_html)
    item_data = extract_wowhead_data(page_html, 3)
    guide_map = extract_wowhead_data(page_html, 100)

    table_match = re.search(
        r'\[tab name="Overall BiS".*?\[table class=grid[^\]]*\](.*?)\[/table\].*?\[/tab\]',
        markup,
        re.S,
    )
    if not table_match:
        table_match = re.search(
            r'\[tabs[^\]]*name=bis_items[^\]]*\].*?\[table class=grid[^\]]*\](.*?)\[/table\]',
            markup,
            re.S,
        )
    if not table_match:
        raise ValueError("Could not find Overall BiS table on Wowhead page")

    rows = re.findall(r"\[tr\](.*?)\[/tr\]", table_match.group(1), re.S)
    slots = {}
    slot_counts: dict[str, int] = {}

    for row_html in rows[1:]:
        cells = re.findall(r"\[td[^\]]*\](.*?)\[/td\]", row_html, re.S)
        if len(cells) < 3:
            continue

        slot_label = strip_wowhead_markup(cells[0])
        base_slot = SLOT_MAP.get(slot_label)
        if not base_slot:
            continue

        slot_counts[slot_label] = slot_counts.get(slot_label, 0) + 1
        if slot_label == "Ring":
            slot_key = "FINGER1" if slot_counts[slot_label] == 1 else "FINGER2"
        elif slot_label == "Trinket":
            slot_key = "TRINKET1" if slot_counts[slot_label] == 1 else "TRINKET2"
        else:
            slot_key = base_slot

        item_cell = cells[-2]
        source_cell = cells[-1]

        item_match = re.search(r"\[item=(\d+)", item_cell)
        if not item_match:
            continue
        item_id = int(item_match.group(1))

        guide_match = re.search(r"\[url guide=(\d+)\](.*?)\[/url\]", source_cell, re.S)
        guide_id = int(guide_match.group(1)) if guide_match else None
        source_meta = normalize_wowhead_source(source_cell, guide_id, guide_map)

        item_info = item_data.get(str(item_id), {})
        item_name = item_info.get("name_enus") or strip_wowhead_markup(cells[1]) or f"Item {item_id}"
        slots[slot_key] = {
            "itemID": item_id,
            "name": item_name,
            "slotKey": slot_key,
            "sourceType": source_meta["sourceType"],
            "sourceName": source_meta["sourceName"],
            "bossName": source_meta["bossName"],
            "notes": source_meta["notes"],
            "isTier": source_meta["sourceName"] == "Tier Set",
            "isCrafted": source_meta["sourceType"] == "crafted",
        }

    return slots


def normalize_priority_stat(token: str) -> str | None:
    lowered = token.strip().lower()
    if "mastery" in lowered:
        return "Mastery"
    if "critical" in lowered or lowered == "crit":
        return "Crit"
    if "haste" in lowered:
        return "Haste"
    if "versatility" in lowered or lowered == "vers":
        return "Vers"
    return None


def parse_wowhead_stat_priority(page_html: str) -> dict[str, int]:
    markup = extract_wowhead_markup(page_html)
    match = re.search(r"stat priority of:\s*\[b\](.*?)\[/b\]", markup, re.I | re.S)
    if not match:
        return {}

    priority = {}
    weight = 4
    for group in re.split(r">", strip_wowhead_markup(match.group(1))):
        normalized_tokens = []
        for token in re.split(r"=|,", group):
            normalized = normalize_priority_stat(token)
            if normalized and normalized not in normalized_tokens:
                normalized_tokens.append(normalized)
        for normalized in normalized_tokens:
            priority[normalized] = weight
        weight = max(1, weight - 1)

    return priority


def parse_wowhead_mythic_plus_items(page_html: str, season_item_index: dict[int, dict]) -> list[dict]:
    markup = extract_wowhead_markup(page_html)
    item_data = extract_wowhead_data(page_html, 3)
    match = re.search(r'\[h2[^\]]*toc="Mythic\+ Drops"[^\]]*\](.*?)(?=\[h2|\Z)', markup, re.S)
    if not match:
        return []

    items = []
    seen = set()
    for item_id_text in re.findall(r"\[(?:icon-badge|item)=(\d+)", match.group(1)):
        item_id = int(item_id_text)
        if item_id in seen:
            continue
        seen.add(item_id)

        if item_id in season_item_index:
            items.append(dict(season_item_index[item_id]))
            continue

        item_info = item_data.get(str(item_id), {})
        items.append(
            build_item_from_wowhead_data(
                item_id,
                item_info,
                source_type="dungeon",
                source_name="Mythic+",
            )
        )

    return items


def parse_wowhead_crafted_items(page_html: str) -> list[dict]:
    markup = extract_wowhead_markup(page_html)
    item_data = extract_wowhead_data(page_html, 3)
    match = re.search(r'\[tab name="Best In Slot Crafts"[^\]]*\](.*?)(?=\[/tab\])', markup, re.S)
    if not match:
        match = re.search(r'\[h2[^\]]*toc="Crafted Gear"[^\]]*\](.*?)(?=\[h2|\Z)', markup, re.S)
    if not match:
        return []

    items = []
    seen = set()
    for item_id_text in re.findall(r"\[item=(\d+)", match.group(1)):
        item_id = int(item_id_text)
        if item_id in seen:
            continue

        item_info = item_data.get(str(item_id), {})
        slot_category = slotbak_to_slot_category((item_info.get("jsonequip") or {}).get("slotbak"))
        if not slot_category:
            continue

        seen.add(item_id)
        items.append(
            build_item_from_wowhead_data(
                item_id,
                item_info,
                slot_key=slot_category,
                slot_category=slot_category,
                source_type="crafted",
                source_name="Crafted",
                is_crafted=True,
            )
        )

    return items


def item_matches_armor_type(item: dict, class_file: str, slot_key: str) -> bool:
    if canonical_slot(slot_key) in {"BACK", "NECK", "FINGER", "TRINKET", "MAINHAND", "OFFHAND"}:
        return True

    armor_type = CLASS_ARMOR_TYPES.get(class_file)
    type_label = (item.get("typeLabel") or "").lower()
    if not armor_type or not type_label:
        return True

    armor_tokens = {"cloth", "leather", "mail", "plate"}
    if not any(token in type_label for token in armor_tokens):
        return True

    return armor_type in type_label


def item_matches_primary_stat(item: dict, spec_id: int, slot_key: str) -> bool:
    if canonical_slot(slot_key) not in {"MAINHAND", "OFFHAND", "TRINKET"}:
        return True

    primary = SPEC_PRIMARY_STATS.get(spec_id)
    if not primary:
        return True

    stats = (item.get("stats") or "").lower()
    if not stats:
        return True

    if primary == "int":
        return "int" in stats
    if primary == "agi":
        return "agi" in stats or "agility" in stats
    if primary == "str":
        return "str" in stats or "strength" in stats
    return True


def score_secondary_stats(item: dict, priority: dict[str, int]) -> int:
    if not priority:
        return 0

    stats = (item.get("stats") or "").lower()
    score = 0
    if "mastery" in stats:
        score += priority.get("Mastery", 0)
    if "crit" in stats or "critical" in stats:
        score += priority.get("Crit", 0)
    if "haste" in stats:
        score += priority.get("Haste", 0)
    if "vers" in stats:
        score += priority.get("Vers", 0)
    return score


def select_no_raid_candidates(
    *,
    slot_key: str,
    class_file: str,
    spec_id: int,
    stat_priority: dict[str, int],
    season_item_index: dict[int, dict],
    wowhead_item: dict | None,
    icy_with: dict | None,
    icy_no: dict | None,
    wowhead_mythic_items: list[dict],
    wowhead_crafted_items: list[dict],
) -> list[dict]:
    candidates: list[tuple[int, int, dict]] = []
    seen = set()

    def append_candidate(item: dict | None, source_bonus: int) -> None:
        if not item:
            return
        item_id = item.get("itemID")
        if not item_id or item_id in seen:
            return
        if item.get("sourceType") == "raid":
            return
        if not item_matches_slot(item.get("slotCategory") or item.get("slotKey"), slot_key):
            return
        if not item_matches_armor_type(item, class_file, slot_key):
            return
        if not item_matches_primary_stat(item, spec_id, slot_key):
            return

        score = source_bonus + score_secondary_stats(item, stat_priority)
        candidates.append((score, len(candidates), item))
        seen.add(item_id)

    if wowhead_item and wowhead_item.get("sourceType") != "raid":
        append_candidate(wowhead_item, 500)

    if icy_no:
        append_candidate(icy_no.get("best"), 450)
        for alternative in icy_no.get("alternatives", []):
            append_candidate(alternative, 420)

    if icy_with:
        append_candidate(icy_with.get("best"), 300)
        for alternative in icy_with.get("alternatives", []):
            append_candidate(alternative, 260)

    for crafted in wowhead_crafted_items:
        append_candidate(crafted, 380)

    for mythic in wowhead_mythic_items:
        append_candidate(mythic, 360)

    for season_item in season_item_index.values():
        append_candidate(season_item, 200)

    candidates.sort(key=lambda entry: (-entry[0], entry[1], entry[2].get("name", "")))
    return [dict(candidate) for _, _, candidate in candidates]


def merge_profiles(
    *,
    spec_entry: dict,
    wowhead_slots: dict,
    icy_profiles: dict,
    wowhead_mythic_items: list[dict],
    wowhead_crafted_items: list[dict],
    stat_priority: dict[str, int],
    season_item_index: dict[int, dict],
) -> dict:
    with_raid_slots = icy_profiles["withRaid"]
    no_raid_slots = icy_profiles["noRaid"]
    all_slot_keys = sorted(set(wowhead_slots) | set(with_raid_slots) | set(no_raid_slots))

    final_with_raid = {}
    final_no_raid = {}

    for slot_key in all_slot_keys:
        wowhead_item = wowhead_slots.get(slot_key)
        icy_with = with_raid_slots.get(slot_key)
        icy_no = no_raid_slots.get(slot_key)

        def enrich_from_candidates(item: dict | None) -> dict | None:
            if not item:
                return item
            if item.get("sourceType") != "other" and item.get("sourceName") not in {"", "Unknown", None}:
                return item

            candidates = []
            if icy_with:
                candidates.extend([icy_with.get("best")] + list(icy_with.get("alternatives", [])))
            if icy_no:
                candidates.extend([icy_no.get("best")] + list(icy_no.get("alternatives", [])))

            for candidate in candidates:
                if candidate and candidate.get("itemID") == item.get("itemID"):
                    enriched = dict(item)
                    for field in ("sourceType", "sourceName", "bossName", "notes", "isTier", "isCrafted"):
                        if candidate.get(field) is not None:
                            enriched[field] = candidate.get(field)
                    return enriched
            return item

        wowhead_item = enrich_from_candidates(wowhead_item)

        with_best = wowhead_item or (icy_with or {}).get("best")
        with_alts = dedupe_items(
            [(icy_with or {}).get("best")] + list((icy_with or {}).get("alternatives", [])),
            with_best.get("itemID") if with_best else None,
        )

        no_raid_candidates = select_no_raid_candidates(
            slot_key=slot_key,
            class_file=spec_entry["classFile"],
            spec_id=spec_entry["specID"],
            stat_priority=stat_priority,
            season_item_index=season_item_index,
            wowhead_item=wowhead_item,
            icy_with=icy_with,
            icy_no=icy_no,
            wowhead_mythic_items=wowhead_mythic_items,
            wowhead_crafted_items=wowhead_crafted_items,
        )
        no_best = no_raid_candidates[0] if no_raid_candidates else None
        no_alts = dedupe_items(
            no_raid_candidates[1:] + ([wowhead_item] if wowhead_item and wowhead_item.get("sourceType") != "raid" else []),
            no_best.get("itemID") if no_best else None,
        )

        final_with_raid[slot_key] = {
            "best": with_best,
            "alternatives": with_alts,
        }
        final_no_raid[slot_key] = {
            "best": no_best,
            "alternatives": no_alts,
        }

    return {
        "withRaid": {"slots": final_with_raid},
        "noRaid": {"slots": final_no_raid},
    }


def parse_wowhead_raid_boss_list(page_html: str) -> list[dict]:
    guide_map = extract_wowhead_data(page_html, 100)
    bosses = []
    for guide in guide_map.values():
        url = guide.get("url", "")
        name = guide.get("name", "")
        if "/guide/midnight/raids/" not in url or "boss-strategy-abilities" not in url:
            continue
        if "all-boss-cheat-sheets" in url or "overview" in url or "rewards-gear-loot" in url:
            continue

        boss_name = name
        boss_match = re.match(r"^(.*?) (?:The Dreamrift|Voidspire|March on Quel[’']Danas) Raid Boss", name)
        if boss_match:
            boss_name = boss_match.group(1).strip()
        else:
            boss_name = boss_name.split(" Raid Boss", 1)[0].split(" Cheatsheet", 1)[0].strip()

        bosses.append(
            {
                "name": boss_name,
                "guideUrl": url,
            }
        )

    return bosses


def parse_wowhead_raid_boss_loot(page_html: str, source_name: str, boss_name: str) -> list[dict]:
    markup = extract_wowhead_markup(page_html)
    item_data = extract_wowhead_data(page_html, 3)
    items = []
    seen = set()

    sections = []
    section_match = re.search(r'\[h2[^\]]*toc="Loot"[^\]]*\](.*?)(?=\[h2|\Z)', markup, re.S)
    if section_match:
        loot_markup = section_match.group(1)
        sections.extend(re.findall(r'\[h3[^\]]*\](.*?)\[/h3\](.*?)(?=\[h3|\Z)', loot_markup, re.S))
    else:
        for toc_value in ("Tier Sets", "Boss Drops"):
            for match in re.finditer(rf'\[h2[^\]]*toc="{toc_value}"[^\]]*\](.*?)(?=\[h2|\Z)', markup, re.S):
                sections.append((toc_value, match.group(1)))

    for section_title_markup, section_body in sections:
        section_title = strip_wowhead_markup(section_title_markup)
        tables = re.findall(r'\[table[^\]]*\](.*?)\[/table\]', section_body, re.S)
        for table_html in tables:
            current_group = None
            current_headers = []
            for row_html in re.findall(r'\[tr[^\]]*\](.*?)\[/tr\]', table_html, re.S):
                cells = re.findall(r'\[td[^\]]*\](.*?)\[/td\]', row_html, re.S)
                if not cells:
                    continue

                plain_cells = [strip_wowhead_markup(cell) for cell in cells]
                if "Item" in plain_cells:
                    current_headers = plain_cells
                    continue

                item_match = re.search(r"\[item=(\d+)", cells[0])
                if not item_match:
                    if plain_cells[0]:
                        current_group = plain_cells[0]
                        current_headers = []
                    continue

                item_id = int(item_match.group(1))
                if item_id in seen:
                    continue
                seen.add(item_id)

                item_info = item_data.get(str(item_id), {})
                type_label = current_group
                stats = None
                slot_category = None

                if current_headers and len(current_headers) >= 2:
                    second_header = current_headers[1]
                    second_value = plain_cells[1] if len(plain_cells) > 1 else ""
                    third_value = plain_cells[2] if len(plain_cells) > 2 else ""
                    if second_header in {"Slot", "Armor Slot"}:
                        slot_category = infer_slot_category(second_value) or infer_slot_category(current_group)
                        type_label = second_value or current_group
                        stats = third_value or None
                    elif second_header in {"Eligible Classes", "Classes"}:
                        slot_category = infer_slot_category(current_group) or slotbak_to_slot_category((item_info.get("jsonequip") or {}).get("slotbak"))
                        if not slot_category and section_title == "Tier Sets":
                            slot_category = "CHEST"
                        type_label = current_group or "Tier Set"
                    elif second_header == "Type":
                        type_label = second_value or current_group
                        slot_category = infer_slot_category(second_value) or infer_slot_category(current_group)
                        stats = third_value or None
                    elif second_header == "Stats":
                        slot_category = infer_slot_category(current_group) or ("TRINKET" if section_title == "Trinkets" else None)
                        stats = second_value or None

                is_tier = section_title == "Tier Sets" or "tier set" in (current_group or "").lower() or "tier" in (type_label or "").lower()
                item = build_item_from_wowhead_data(
                    item_id,
                    item_info,
                    slot_category=slot_category,
                    source_type="raid",
                    source_name=source_name,
                    boss_name=boss_name,
                    type_label=type_label,
                    stats=stats,
                    is_tier=is_tier,
                )
                items.append(item)

    return items


def render_item(item: dict | None, indent: str) -> str:
    if not item:
        return "nil"

    lines = ["{"]
    field_order = [
        "itemID",
        "name",
        "slotKey",
        "slotCategory",
        "sourceType",
        "sourceName",
        "bossName",
        "typeLabel",
        "stats",
        "notes",
        "isTier",
        "isCrafted",
    ]
    for field in field_order:
        value = item.get(field)
        if value is None:
            continue
        if isinstance(value, bool):
            rendered = "true" if value else "false"
        elif isinstance(value, int):
            rendered = str(value)
        else:
            rendered = f'"{lua_escape(str(value))}"'
        lines.append(f"{indent}    {field} = {rendered},")
    lines.append(f"{indent}}}")
    return "\n".join(lines)


def render_slot_profile(slot_profile: dict, indent: str) -> str:
    best_block = render_item(slot_profile.get("best"), indent + "    ")
    lines = ["{", f"{indent}    best = {best_block},"]
    lines.append(f"{indent}    alternatives = {{")
    for alt in slot_profile.get("alternatives", []):
        lines.append(f"{indent}        {render_item(alt, indent + '        ')},")
    lines.append(f"{indent}    }},")
    lines.append(f"{indent}}}")
    return "\n".join(lines)


def render_profiles(spec_profiles: dict) -> str:
    lines = []
    for class_file in sorted(spec_profiles):
        by_spec = spec_profiles[class_file]
        lines.append(f'        ["{class_file}"] = {{')
        for spec_id in sorted(by_spec):
            payload = by_spec[spec_id]
            lines.append(f"            [{spec_id}] = {{")
            lines.append(f'                name = "{lua_escape(payload["name"])}",')
            lines.append(f'                guideUrl = "{payload["guideUrl"]}",')
            for profile_key in ("withRaid", "noRaid"):
                lines.append(f"                {profile_key} = {{")
                lines.append("                    slots = {")
                for slot_key in sorted(payload[profile_key]["slots"]):
                    slot_profile = payload[profile_key]["slots"][slot_key]
                    lines.append(f'                        ["{slot_key}"] = {render_slot_profile(slot_profile, "                        ")},')
                lines.append("                    },")
                lines.append("                },")
            lines.append("            },")
        lines.append("        },")
    return "\n".join(lines)


def render_generation_errors(errors: list[dict]) -> str:
    if not errors:
        return "{}"

    lines = ["{"]
    for error in errors:
        lines.append("        {")
        lines.append(f'            specID = {error["specID"]},')
        lines.append(f'            url = "{lua_escape(error["url"])}",')
        lines.append(f'            error = "{lua_escape(error["error"])}",')
        lines.append("        },")
    lines.append("    }")
    return "\n".join(lines)


def render_content_collections(collections: list[dict]) -> str:
    lines = []
    for dungeon in collections:
        lines.append("        {")
        lines.append(f'            sourceName = "{lua_escape(dungeon["sourceName"])}",')
        lines.append(f'            guideUrl = "{lua_escape(dungeon["guideUrl"])}",')
        lines.append("            bosses = {")
        for boss in dungeon["bosses"]:
            lines.append("                {")
            lines.append(f'                    name = "{lua_escape(boss["name"])}",')
            lines.append("                    items = {")
            for item in boss["items"]:
                lines.append(f'                        {render_item(item, "                        ")},')
            lines.append("                    },")
            lines.append("                },")
        lines.append("            },")
        lines.append("        },")
    return "\n".join(lines)


def main() -> None:
    profiles: dict[str, dict[int, dict]] = {}
    errors = []
    dungeons = []
    raids = []

    for dungeon_entry in DUNGEON_GUIDES:
        try:
            page_html = fetch(dungeon_entry["guideUrl"])
            bosses = parse_dungeon_loot_tables(page_html, dungeon_entry["sourceName"])
        except Exception as exc:  # noqa: BLE001
            errors.append({"specID": 0, "error": str(exc), "url": dungeon_entry["guideUrl"]})
            continue

        dungeons.append(
            {
                "sourceName": dungeon_entry["sourceName"],
                "guideUrl": dungeon_entry["guideUrl"],
                "bosses": bosses,
            }
        )

    season_item_index = extract_season_items_index(dungeons)

    for entry in SPEC_ENTRIES:
        gear_url = icy_guide_url(entry)
        try:
            page_html = fetch(gear_url)
        except Exception as exc:  # noqa: BLE001
            errors.append({"specID": entry["specID"], "error": str(exc), "url": gear_url})
            continue

        overall_slots = parse_table(extract_table(page_html, "area_1"))
        mythic_slots = parse_table(extract_table(page_html, "area_2"))
        raid_slots = parse_table(extract_table(page_html, "area_3"))
        icy_built = build_profiles(overall_slots, mythic_slots, raid_slots)

        wowhead_url = None
        wowhead_slots = {}
        wowhead_mythic_items = []
        wowhead_crafted_items = []
        stat_priority = {}
        try:
            wowhead_url, wowhead_html = fetch_wowhead_bis_page(entry)
            wowhead_slots = parse_wowhead_overall_bis(wowhead_html)
            wowhead_mythic_items = parse_wowhead_mythic_plus_items(wowhead_html, season_item_index)
            wowhead_crafted_items = parse_wowhead_crafted_items(wowhead_html)
            stat_priority = parse_wowhead_stat_priority(wowhead_html)
        except Exception as exc:  # noqa: BLE001
            errors.append(
                {
                    "specID": entry["specID"],
                    "error": f"Wowhead fallback failed: {exc}",
                    "url": wowhead_url or wowhead_direct_bis_url(entry),
                }
            )

        built = merge_profiles(
            spec_entry=entry,
            wowhead_slots=wowhead_slots,
            icy_profiles=icy_built,
            wowhead_mythic_items=wowhead_mythic_items,
            wowhead_crafted_items=wowhead_crafted_items,
            stat_priority=stat_priority,
            season_item_index=season_item_index,
        )

        per_class = profiles.setdefault(entry["classFile"], {})
        per_class[entry["specID"]] = {
            "name": entry["name"],
            "guideUrl": wowhead_url or gear_url,
            "withRaid": built["withRaid"],
            "noRaid": built["noRaid"],
        }

    for raid_entry in RAID_OVERVIEWS:
        try:
            overview_html = fetch(raid_entry["overviewUrl"])
            raid_bosses = []
            for boss_entry in parse_wowhead_raid_boss_list(overview_html):
                boss_html = fetch(boss_entry["guideUrl"])
                raid_bosses.append(
                    {
                        "name": boss_entry["name"],
                        "items": parse_wowhead_raid_boss_loot(boss_html, raid_entry["sourceName"], boss_entry["name"]),
                    }
                )
        except Exception as exc:  # noqa: BLE001
            errors.append({"specID": 0, "error": str(exc), "url": raid_entry["overviewUrl"]})
            continue

        raids.append(
            {
                "sourceName": raid_entry["sourceName"],
                "guideUrl": raid_entry["overviewUrl"],
                "bosses": raid_bosses,
            }
        )

    generated_at = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

    lua_output = f"""local addon = MidnightBisGuide

addon.Data.SeasonData = {{
    seasonID = "midnight-season-1",
    generatedAt = "{generated_at}",
    profiles = {{
{render_profiles(profiles)}
    }},
    generationErrors = {render_generation_errors(errors)},
}}
"""

    OUTPUT.write_text(lua_output, encoding="utf-8")
    content_output = f"""local addon = MidnightBisGuide

addon.Data.SeasonContent = {{
    seasonID = "midnight-season-1",
    generatedAt = "{generated_at}",
    dungeons = {{
{render_content_collections(dungeons)}
    }},
    raids = {{
{render_content_collections(raids)}
    }},
}}
"""
    CONTENT_OUTPUT.write_text(content_output, encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    print(f"Wrote {CONTENT_OUTPUT}")
    if errors:
        print("Generation completed with errors:")
        print(json.dumps(errors, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
