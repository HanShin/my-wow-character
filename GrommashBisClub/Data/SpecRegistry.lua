local addon = MidnightBisGuide

addon.Data.SpecRegistry = {
    bySpecID = {
        [250] = { classFile = "DEATHKNIGHT", name = "Blood", slug = "blood-death-knight" },
        [251] = { classFile = "DEATHKNIGHT", name = "Frost", slug = "frost-death-knight" },
        [252] = { classFile = "DEATHKNIGHT", name = "Unholy", slug = "unholy-death-knight" },
        [577] = { classFile = "DEMONHUNTER", name = "Havoc", slug = "havoc-demon-hunter" },
        [581] = { classFile = "DEMONHUNTER", name = "Vengeance", slug = "vengeance-demon-hunter" },
        [1480] = { classFile = "DEMONHUNTER", name = "Devourer", slug = "devourer-demon-hunter" },
        [102] = { classFile = "DRUID", name = "Balance", slug = "balance-druid" },
        [103] = { classFile = "DRUID", name = "Feral", slug = "feral-druid" },
        [104] = { classFile = "DRUID", name = "Guardian", slug = "guardian-druid" },
        [105] = { classFile = "DRUID", name = "Restoration", slug = "restoration-druid" },
        [1467] = { classFile = "EVOKER", name = "Devastation", slug = "devastation-evoker" },
        [1468] = { classFile = "EVOKER", name = "Preservation", slug = "preservation-evoker" },
        [1473] = { classFile = "EVOKER", name = "Augmentation", slug = "augmentation-evoker" },
        [253] = { classFile = "HUNTER", name = "Beast Mastery", slug = "beast-mastery-hunter" },
        [254] = { classFile = "HUNTER", name = "Marksmanship", slug = "marksmanship-hunter" },
        [255] = { classFile = "HUNTER", name = "Survival", slug = "survival-hunter" },
        [62] = { classFile = "MAGE", name = "Arcane", slug = "arcane-mage" },
        [63] = { classFile = "MAGE", name = "Fire", slug = "fire-mage" },
        [64] = { classFile = "MAGE", name = "Frost", slug = "frost-mage" },
        [268] = { classFile = "MONK", name = "Brewmaster", slug = "brewmaster-monk" },
        [270] = { classFile = "MONK", name = "Mistweaver", slug = "mistweaver-monk" },
        [269] = { classFile = "MONK", name = "Windwalker", slug = "windwalker-monk" },
        [65] = { classFile = "PALADIN", name = "Holy", slug = "holy-paladin" },
        [66] = { classFile = "PALADIN", name = "Protection", slug = "protection-paladin" },
        [70] = { classFile = "PALADIN", name = "Retribution", slug = "retribution-paladin" },
        [256] = { classFile = "PRIEST", name = "Discipline", slug = "discipline-priest" },
        [257] = { classFile = "PRIEST", name = "Holy", slug = "holy-priest" },
        [258] = { classFile = "PRIEST", name = "Shadow", slug = "shadow-priest" },
        [259] = { classFile = "ROGUE", name = "Assassination", slug = "assassination-rogue" },
        [260] = { classFile = "ROGUE", name = "Outlaw", slug = "outlaw-rogue" },
        [261] = { classFile = "ROGUE", name = "Subtlety", slug = "subtlety-rogue" },
        [262] = { classFile = "SHAMAN", name = "Elemental", slug = "elemental-shaman" },
        [263] = { classFile = "SHAMAN", name = "Enhancement", slug = "enhancement-shaman" },
        [264] = { classFile = "SHAMAN", name = "Restoration", slug = "restoration-shaman" },
        [265] = { classFile = "WARLOCK", name = "Affliction", slug = "affliction-warlock" },
        [266] = { classFile = "WARLOCK", name = "Demonology", slug = "demonology-warlock" },
        [267] = { classFile = "WARLOCK", name = "Destruction", slug = "destruction-warlock" },
        [71] = { classFile = "WARRIOR", name = "Arms", slug = "arms-warrior" },
        [72] = { classFile = "WARRIOR", name = "Fury", slug = "fury-warrior" },
        [73] = { classFile = "WARRIOR", name = "Protection", slug = "protection-warrior" },
    },
}

addon.Data.SpecRegistry.byClass = {}

for specID, specInfo in pairs(addon.Data.SpecRegistry.bySpecID) do
    local byClass = addon.Data.SpecRegistry.byClass[specInfo.classFile]
    if not byClass then
        byClass = {}
        addon.Data.SpecRegistry.byClass[specInfo.classFile] = byClass
    end

    byClass[specID] = specInfo
end
