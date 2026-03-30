local addonName = ...

MidnightBisGuide = MidnightBisGuide or {}

local addon = MidnightBisGuide

addon.ADDON_NAME = addonName or "GrommashBisClub"
addon.VERSION = "0.1.0"
addon.DB_NAME = "MidnightBisGuideDB"

addon.Data = addon.Data or {}
addon.State = addon.State or {}
addon.Constants = addon.Constants or {}
addon.Util = addon.Util or {}

addon.Constants.PROFILE_KEYS = {
    WITH_RAID = "withRaid",
    NO_RAID = "noRaid",
}

addon.Constants.PROFILE_LABELS = {
    withRaid = "레이드 가능",
    noRaid = "레이드 불가",
}

addon.Constants.SLOT_ORDER = {
    "HEAD",
    "NECK",
    "SHOULDER",
    "BACK",
    "CHEST",
    "WRIST",
    "HANDS",
    "WAIST",
    "LEGS",
    "FEET",
    "FINGER1",
    "FINGER2",
    "TRINKET1",
    "TRINKET2",
    "MAINHAND",
    "OFFHAND",
}

addon.Constants.SLOT_LABELS = {
    HEAD = "머리",
    NECK = "목",
    SHOULDER = "어깨",
    BACK = "등",
    CHEST = "가슴",
    WRIST = "손목",
    HANDS = "손",
    WAIST = "허리",
    LEGS = "다리",
    FEET = "발",
    FINGER1 = "반지 1",
    FINGER2 = "반지 2",
    TRINKET1 = "장신구 1",
    TRINKET2 = "장신구 2",
    MAINHAND = "주무기",
    OFFHAND = "보조장비",
}

addon.Constants.SLOT_TO_INVENTORY = {
    HEAD = 1,
    NECK = 2,
    SHOULDER = 3,
    CHEST = 5,
    WAIST = 6,
    LEGS = 7,
    FEET = 8,
    WRIST = 9,
    HANDS = 10,
    FINGER1 = 11,
    FINGER2 = 12,
    TRINKET1 = 13,
    TRINKET2 = 14,
    BACK = 15,
    MAINHAND = 16,
    OFFHAND = 17,
}

addon.Constants.SOURCE_TYPE_LABELS = {
    dungeon = "신화쐐기돌",
    raid = "레이드",
    weekly_vault = "주간 금고",
    crafted = "제작",
    catalyst = "촉매",
    other = "기타",
}

addon.Constants.SOURCE_TYPE_ORDER = {
    "dungeon",
    "raid",
    "weekly_vault",
    "crafted",
    "catalyst",
    "other",
}

addon.Constants.STATUS = {
    COMPLETE = "complete",
    ALTERNATIVE = "alternative",
    UPGRADE = "upgrade",
    MISSING = "missing",
    NOT_APPLICABLE = "not_applicable",
}

addon.Constants.STATUS_LABELS = {
    complete = "완료",
    alternative = "대체 장착",
    upgrade = "업그레이드 필요",
    missing = "데이터 없음",
    not_applicable = "해당 없음",
}
