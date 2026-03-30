#!/usr/bin/env python3
from __future__ import annotations
import datetime as dt
import html
import json
import pathlib
import re
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "MidnightBisGuide" / "Data" / "SeasonData.lua"


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


def fetch(url: str) -> str:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


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


def render_item(item: dict | None, indent: str) -> str:
    if not item:
        return "nil"

    lines = ["{"]
    field_order = ["itemID", "name", "slotKey", "sourceType", "sourceName", "bossName", "notes", "isTier", "isCrafted"]
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


def main() -> None:
    profiles: dict[str, dict[int, dict]] = {}
    errors = []

    for entry in SPEC_ENTRIES:
        gear_url = f"https://www.icy-veins.com/wow/{entry['guide'].replace('-guide', '-gear-best-in-slot')}"
        try:
            page_html = fetch(gear_url)
        except Exception as exc:  # noqa: BLE001
            errors.append({"specID": entry["specID"], "error": str(exc), "url": gear_url})
            continue

        overall_slots = parse_table(extract_table(page_html, "area_1"))
        mythic_slots = parse_table(extract_table(page_html, "area_2"))
        raid_slots = parse_table(extract_table(page_html, "area_3"))
        built = build_profiles(overall_slots, mythic_slots, raid_slots)

        per_class = profiles.setdefault(entry["classFile"], {})
        per_class[entry["specID"]] = {
            "name": entry["name"],
            "guideUrl": gear_url,
            "withRaid": {"slots": built["withRaid"]},
            "noRaid": {"slots": built["noRaid"]},
        }

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
    print(f"Wrote {OUTPUT}")
    if errors:
        print("Generation completed with errors:")
        print(json.dumps(errors, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
