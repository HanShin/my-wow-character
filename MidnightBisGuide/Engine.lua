local addon = MidnightBisGuide
local util = addon.Util
local engine = {}

addon.Engine = engine

local STATUS = addon.Constants.STATUS
local PROFILE_KEYS = addon.Constants.PROFILE_KEYS

local function EnsureTable(parent, key)
    if not parent[key] then
        parent[key] = {}
    end
    return parent[key]
end

function engine.InitializeDB()
    MidnightBisGuideDB = MidnightBisGuideDB or {}
    MidnightBisGuideDB.characters = MidnightBisGuideDB.characters or {}
    MidnightBisGuideDB.window = MidnightBisGuideDB.window or {}
end

function engine.GetCharacterKey()
    local name, realm = UnitName("player")
    local normalizedRealm = realm and realm ~= "" and realm or GetRealmName() or "Unknown"
    return ("%s-%s"):format(normalizedRealm, name or "Unknown")
end

function engine.GetCharacterState()
    local characters = MidnightBisGuideDB.characters
    local characterKey = engine.GetCharacterKey()
    local state = characters[characterKey]
    if state then
        return state
    end

    state = {
        profileKey = PROFILE_KEYS.WITH_RAID,
        selectedSpecID = nil,
        custom = {},
    }

    characters[characterKey] = state
    return state
end

function engine.GetAvailableSpecIDs()
    local _, _, classID = UnitClass("player")
    if not classID then
        return {}
    end

    local specIDs = {}
    local specCount = GetNumSpecializationsForClassID(classID) or 0
    for index = 1, specCount do
        local specID = GetSpecializationInfoForClassID(classID, index)
        if specID then
            specIDs[#specIDs + 1] = specID
        end
    end
    return specIDs
end

function engine.GetActiveSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then
        return nil
    end

    local specID = GetSpecializationInfo(specIndex)
    return specID
end

function engine.GetSelectedSpecID()
    local state = engine.GetCharacterState()
    return state.selectedSpecID or engine.GetActiveSpecID()
end

function engine.SetSelectedSpecID(specID)
    local state = engine.GetCharacterState()
    state.selectedSpecID = specID
end

function engine.CycleSelectedSpecID()
    local available = engine.GetAvailableSpecIDs()
    if #available == 0 then
        return nil
    end

    local selected = engine.GetSelectedSpecID()
    for index, candidate in ipairs(available) do
        if candidate == selected then
            local nextIndex = index + 1
            if nextIndex > #available then
                nextIndex = 1
            end
            engine.SetSelectedSpecID(available[nextIndex])
            return available[nextIndex]
        end
    end

    engine.SetSelectedSpecID(available[1])
    return available[1]
end

function engine.GetProfileKey()
    local state = engine.GetCharacterState()
    return state.profileKey or PROFILE_KEYS.WITH_RAID
end

function engine.SetProfileKey(profileKey)
    local state = engine.GetCharacterState()
    state.profileKey = profileKey
end

function engine.ToggleProfileKey()
    local current = engine.GetProfileKey()
    if current == PROFILE_KEYS.WITH_RAID then
        engine.SetProfileKey(PROFILE_KEYS.NO_RAID)
    else
        engine.SetProfileKey(PROFILE_KEYS.WITH_RAID)
    end
    return engine.GetProfileKey()
end

function engine.GetSpecData(specID)
    local registry = addon.Data.SpecRegistry.bySpecID[specID]
    if not registry then
        return nil
    end

    local classProfiles = addon.Data.SeasonData.profiles[registry.classFile]
    if not classProfiles then
        return nil
    end

    return classProfiles[specID]
end

function engine.BuildDefaultItemIndex()
    local index = {}
    local profiles = addon.Data.SeasonData.profiles or {}

    local function AddItem(item)
        if not item or not item.itemID then
            return
        end

        local normalized = util.NormalizeItem(item)
        if not index[item.itemID] then
            index[item.itemID] = normalized
            return
        end

        local existing = index[item.itemID]
        for key, value in pairs(normalized) do
            if existing[key] == nil or existing[key] == "" then
                existing[key] = value
            end
        end
    end

    for _, classProfiles in pairs(profiles) do
        for _, specData in pairs(classProfiles) do
            for _, profileKey in pairs(addon.Constants.PROFILE_KEYS) do
                local slots = specData[profileKey] and specData[profileKey].slots or {}
                for _, slotProfile in pairs(slots) do
                    AddItem(slotProfile.best)
                    for _, alt in ipairs(slotProfile.alternatives or {}) do
                        AddItem(alt)
                    end
                end
            end
        end
    end

    local seasonContent = addon.Data.SeasonContent or {}
    for _, contentType in ipairs({ "dungeons", "raids" }) do
        for _, collection in ipairs(seasonContent[contentType] or {}) do
            for _, boss in ipairs(collection.bosses or {}) do
                for _, item in ipairs(boss.items or {}) do
                    AddItem(item)
                end
            end
        end
    end

    addon.State.itemIndex = index
    addon.State.editorCatalog = nil
    return index
end

function engine.GetItemIndex()
    if not addon.State.itemIndex then
        return engine.BuildDefaultItemIndex()
    end
    return addon.State.itemIndex
end

local function CopySlotProfileToKey(slotProfile, slotKey)
    local copied = util.NormalizeSlotProfile(slotProfile)
    if not copied then
        return nil
    end

    if copied.best then
        copied.best.slotKey = slotKey
    end

    for _, alt in ipairs(copied.alternatives or {}) do
        alt.slotKey = slotKey
    end

    return copied
end

local function GetIndexedItem(item)
    if not item or not item.itemID then
        return item
    end

    local indexed = engine.GetItemIndex()[item.itemID]
    if not indexed then
        return item
    end

    local merged = util.DeepCopy(indexed)
    for key, value in pairs(item) do
        if merged[key] == nil or merged[key] == "" then
            merged[key] = value
        end
    end

    return merged
end

local function GetDefaultSlotProfile(specID, profileKey, slotKey)
    local specData = engine.GetSpecData(specID)
    if not specData or not specData[profileKey] then
        return nil
    end

    local slots = specData[profileKey].slots or {}
    local defaultSlot = slots[slotKey]
    if defaultSlot then
        return util.NormalizeSlotProfile(defaultSlot)
    end

    if slotKey ~= "OFFHAND" then
        return nil
    end

    local oneHandSlot = slots["WEAPON_1H"]
    if oneHandSlot and oneHandSlot.best then
        return CopySlotProfileToKey(oneHandSlot, "OFFHAND")
    end

    local currentOffhand = GetInventoryItemID("player", addon.Constants.SLOT_TO_INVENTORY.OFFHAND)
    if not currentOffhand then
        return nil
    end

    local mainhand = slots["MAINHAND"]
    if not mainhand or not mainhand.best then
        return nil
    end

    local bestItem = GetIndexedItem(mainhand.best)
    local slotToken = bestItem and (bestItem.slotCategory or bestItem.slotKey)
    if slotToken == "WEAPON_1H" or slotToken == "MAINHAND" then
        return CopySlotProfileToKey(mainhand, "OFFHAND")
    end

    return nil
end

local function SortByLabel(list)
    table.sort(list, function(left, right)
        return tostring(left.label or "") < tostring(right.label or "")
    end)
end

function engine.BuildEditorCatalog()
    local catalog = {
        bySourceType = {
            dungeon = {},
            raid = {},
            crafted = {},
            weekly_vault = {},
            catalyst = {},
            other = {},
        },
    }

    local function EnsureGroup(sourceType, label)
        local groups = catalog.bySourceType[sourceType]
        for _, group in ipairs(groups) do
            if group.label == label then
                return group
            end
        end

        local group = {
            label = label,
            bosses = {},
        }
        groups[#groups + 1] = group
        return group
    end

    local function EnsureBoss(group, label)
        for _, boss in ipairs(group.bosses) do
            if boss.label == label then
                return boss
            end
        end

        local boss = {
            label = label,
            items = {},
        }
        group.bosses[#group.bosses + 1] = boss
        return boss
    end

    local function AppendItem(sourceType, groupLabel, bossLabel, item)
        if not item or not item.itemID then
            return
        end

        local group = EnsureGroup(sourceType, groupLabel or "기타")
        local boss = EnsureBoss(group, bossLabel or "전체")
        util.AppendIfMissing(boss.items, util.NormalizeItem(item), "itemID")
    end

    local seasonContent = addon.Data.SeasonContent or {}
    for _, contentType in ipairs({ "dungeons", "raids" }) do
        for _, collection in ipairs(seasonContent[contentType] or {}) do
            local sourceType = contentType == "raids" and "raid" or "dungeon"
            for _, boss in ipairs(collection.bosses or {}) do
                for _, item in ipairs(boss.items or {}) do
                    AppendItem(sourceType, collection.sourceName, boss.name, item)
                end
            end
        end
    end

    for _, item in pairs(engine.GetItemIndex()) do
        local normalized = util.NormalizeSourceData(item)
        local sourceType = normalized.sourceType or item.sourceType or "other"
        if sourceType ~= "dungeon" and sourceType ~= "raid" then
            AppendItem(
                sourceType,
                normalized.sourceName or item.sourceName or addon.Constants.SOURCE_TYPE_LABELS[sourceType] or "기타",
                normalized.bossName or item.bossName or "전체",
                item
            )
        end
    end

    for _, groups in pairs(catalog.bySourceType) do
        for _, group in ipairs(groups) do
            for _, boss in ipairs(group.bosses) do
                table.sort(boss.items, function(left, right)
                    return util.GetPlainItemName(left) < util.GetPlainItemName(right)
                end)
            end
            SortByLabel(group.bosses)
        end
        SortByLabel(groups)
    end

    addon.State.editorCatalog = catalog
    return catalog
end

function engine.GetEditorCatalog()
    if not addon.State.editorCatalog then
        return engine.BuildEditorCatalog()
    end
    return addon.State.editorCatalog
end

function engine.GetCatalogSourceTypes(slotKey)
    local catalog = engine.GetEditorCatalog()
    local sourceTypes = {}

    for _, sourceType in ipairs(addon.Constants.SOURCE_TYPE_ORDER) do
        local groups = catalog.bySourceType[sourceType] or {}
        for _, group in ipairs(groups) do
            local hasMatch = false
            for _, boss in ipairs(group.bosses or {}) do
                for _, item in ipairs(boss.items or {}) do
                    if util.ItemMatchesSlot(item, slotKey) then
                        hasMatch = true
                        break
                    end
                end
                if hasMatch then
                    break
                end
            end

            if hasMatch then
                sourceTypes[#sourceTypes + 1] = sourceType
                break
            end
        end
    end

    return sourceTypes
end

function engine.GetCatalogGroups(sourceType, slotKey)
    local groups = {}
    local catalogGroups = engine.GetEditorCatalog().bySourceType[sourceType] or {}

    for _, group in ipairs(catalogGroups) do
        local filteredBosses = {}
        for _, boss in ipairs(group.bosses or {}) do
            local filteredItems = {}
            for _, item in ipairs(boss.items or {}) do
                if util.ItemMatchesSlot(item, slotKey) then
                    filteredItems[#filteredItems + 1] = util.DeepCopy(item)
                end
            end
            if #filteredItems > 0 then
                filteredBosses[#filteredBosses + 1] = {
                    label = boss.label,
                    items = filteredItems,
                }
            end
        end

        if #filteredBosses > 0 then
            groups[#groups + 1] = {
                label = group.label,
                bosses = filteredBosses,
            }
        end
    end

    return groups
end

function engine.BuildCustomSlotProfile(slotKey, bestItem, alt1Item, alt2Item)
    local result = {
        best = nil,
        alternatives = {},
    }

    local function CopyIntoSlot(item)
        if not item then
            return nil
        end

        local copied = util.DeepCopy(item)
        copied.slotKey = slotKey
        return util.NormalizeItem(copied)
    end

    result.best = CopyIntoSlot(bestItem)
    if alt1Item then
        result.alternatives[#result.alternatives + 1] = CopyIntoSlot(alt1Item)
    end
    if alt2Item then
        result.alternatives[#result.alternatives + 1] = CopyIntoSlot(alt2Item)
    end

    return util.NormalizeSlotProfile(result)
end

function engine.GetCharacterCustomRoot(specID, profileKey)
    local registry = addon.Data.SpecRegistry.bySpecID[specID]
    if not registry then
        return nil
    end

    local state = engine.GetCharacterState()
    local custom = EnsureTable(state.custom, registry.classFile)
    local perSpec = EnsureTable(custom, tostring(specID))
    return EnsureTable(perSpec, profileKey)
end

local function GetCustomSlotOverride(specID, profileKey, slotKey)
    local root = engine.GetCharacterCustomRoot(specID, profileKey)
    return root and root[slotKey] or nil
end

local function SetCustomSlotOverride(specID, profileKey, slotKey, slotProfile)
    local root = engine.GetCharacterCustomRoot(specID, profileKey)
    root[slotKey] = slotProfile
end

function engine.ResetSlotOverride(specID, profileKey, slotKey)
    local root = engine.GetCharacterCustomRoot(specID, profileKey)
    if root then
        root[slotKey] = nil
    end
end

function engine.ResetProfileOverrides(specID, profileKey)
    local registry = addon.Data.SpecRegistry.bySpecID[specID]
    if not registry then
        return
    end

    local state = engine.GetCharacterState()
    local custom = state.custom[registry.classFile]
    if custom and custom[tostring(specID)] then
        custom[tostring(specID)][profileKey] = {}
    end
end

function engine.NormalizeCustomSlot(bestItemID, alt1ItemID, alt2ItemID, sourceType, sourceName, bossName, notes)
    local itemIndex = engine.GetItemIndex()

    local function BuildItem(itemID)
        if not itemID then
            return nil
        end

        local numericID = tonumber(itemID)
        if not numericID then
            return nil
        end

        local indexed = itemIndex[numericID]
        if indexed then
            return util.DeepCopy(indexed)
        end

        return util.NormalizeItem({
            itemID = numericID,
            sourceType = sourceType or "other",
            sourceName = sourceName or "",
            bossName = bossName,
            notes = notes,
            name = "아이템 #" .. tostring(numericID),
        })
    end

    local result = {
        best = BuildItem(bestItemID),
        alternatives = {},
    }

    if alt1ItemID then
        result.alternatives[#result.alternatives + 1] = BuildItem(alt1ItemID)
    end
    if alt2ItemID then
        result.alternatives[#result.alternatives + 1] = BuildItem(alt2ItemID)
    end

    if result.best and not itemIndex[result.best.itemID] then
        result.best.sourceType = sourceType or result.best.sourceType
        result.best.sourceName = sourceName or result.best.sourceName
        result.best.bossName = bossName or result.best.bossName
        result.best.notes = notes or result.best.notes
    end

    for _, alt in ipairs(result.alternatives) do
        if alt and not itemIndex[alt.itemID] then
            alt.sourceType = sourceType or alt.sourceType
            alt.sourceName = sourceName or alt.sourceName
            alt.bossName = bossName or alt.bossName
            alt.notes = notes or alt.notes
        end
    end

    return util.NormalizeSlotProfile(result)
end

function engine.SaveSlotOverride(specID, profileKey, slotKey, customProfile)
    local defaultProfile = GetDefaultSlotProfile(specID, profileKey, slotKey)

    if defaultProfile and util.TableEquals(customProfile, util.NormalizeSlotProfile(defaultProfile)) then
        engine.ResetSlotOverride(specID, profileKey, slotKey)
        return
    end

    SetCustomSlotOverride(specID, profileKey, slotKey, customProfile)
end

function engine.GetEffectiveSlotProfile(specID, profileKey, slotKey)
    local customSlot = GetCustomSlotOverride(specID, profileKey, slotKey)
    if customSlot then
        return util.NormalizeSlotProfile(customSlot)
    end

    return GetDefaultSlotProfile(specID, profileKey, slotKey)
end

function engine.GetDefaultCandidates(specID, profileKey, slotKey)
    local candidates = {}

    local function AppendCandidates(fromProfileKey)
        local slotProfile = GetDefaultSlotProfile(specID, fromProfileKey, slotKey)
        if not slotProfile then
            return
        end

        if slotProfile.best then
            util.AppendIfMissing(candidates, slotProfile.best, "itemID")
        end
        for _, alt in ipairs(slotProfile.alternatives or {}) do
            util.AppendIfMissing(candidates, alt, "itemID")
        end
    end

    AppendCandidates(profileKey)
    if profileKey == PROFILE_KEYS.WITH_RAID then
        AppendCandidates(PROFILE_KEYS.NO_RAID)
    else
        AppendCandidates(PROFILE_KEYS.WITH_RAID)
    end

    return candidates
end

local function GetEquippedItemID(slotKey)
    local inventorySlot = addon.Constants.SLOT_TO_INVENTORY[slotKey]
    if not inventorySlot then
        return nil
    end

    return GetInventoryItemID("player", inventorySlot)
end

local function GetEquippedItemLink(slotKey)
    local inventorySlot = addon.Constants.SLOT_TO_INVENTORY[slotKey]
    if not inventorySlot then
        return nil
    end

    return GetInventoryItemLink("player", inventorySlot)
end

local function BuildPairLookup(slotKeys)
    local lookup = {}
    for _, slotKey in ipairs(slotKeys) do
        local itemID = GetEquippedItemID(slotKey)
        if itemID then
            lookup[itemID] = true
        end
    end
    return lookup
end

local function ResolveDuplicateBest(slotMap, slotA, slotB)
    local first = slotMap[slotA]
    local second = slotMap[slotB]

    if not first or not second then
        return
    end

    local firstBest = first.best
    local secondBest = second.best
    if not firstBest or not secondBest or firstBest.itemID ~= secondBest.itemID then
        return
    end

    for _, alternative in ipairs(second.alternatives or {}) do
        if alternative.itemID ~= firstBest.itemID then
            second.best = util.DeepCopy(alternative)
            return
        end
    end

    second.duplicateConflict = true
end

function engine.BuildResolvedProfile(specID, profileKey)
    local resolved = {}
    for _, slotKey in ipairs(addon.Constants.SLOT_ORDER) do
        resolved[slotKey] = engine.GetEffectiveSlotProfile(specID, profileKey, slotKey)
    end

    ResolveDuplicateBest(resolved, "FINGER1", "FINGER2")
    ResolveDuplicateBest(resolved, "TRINKET1", "TRINKET2")

    return resolved
end

function engine.BuildSlotStates()
    local specID = engine.GetSelectedSpecID()
    if not specID then
        return {}
    end

    local profileKey = engine.GetProfileKey()
    local resolved = engine.BuildResolvedProfile(specID, profileKey)
    local ringLookup = BuildPairLookup({ "FINGER1", "FINGER2" })
    local trinketLookup = BuildPairLookup({ "TRINKET1", "TRINKET2" })
    local rows = {}

    for _, slotKey in ipairs(addon.Constants.SLOT_ORDER) do
        local slotProfile = resolved[slotKey]
        local currentItemID = GetEquippedItemID(slotKey)
        local equippedLookup = nil
        if slotKey == "FINGER1" or slotKey == "FINGER2" then
            equippedLookup = ringLookup
        elseif slotKey == "TRINKET1" or slotKey == "TRINKET2" then
            equippedLookup = trinketLookup
        end

        local status = STATUS.MISSING
        if slotKey == "OFFHAND" and (not slotProfile or not slotProfile.best) and not currentItemID then
            status = STATUS.NOT_APPLICABLE
        elseif slotProfile and slotProfile.best then
            local isBestEquipped = equippedLookup and equippedLookup[slotProfile.best.itemID]
                or currentItemID == slotProfile.best.itemID

            if isBestEquipped then
                status = STATUS.COMPLETE
            else
                local hasAlternative = false
                for _, alternative in ipairs(slotProfile.alternatives or {}) do
                    local isAltEquipped = equippedLookup and equippedLookup[alternative.itemID]
                        or currentItemID == alternative.itemID
                    if isAltEquipped then
                        hasAlternative = true
                        break
                    end
                end

                if hasAlternative then
                    status = STATUS.ALTERNATIVE
                else
                    status = STATUS.UPGRADE
                end
            end
        end

        rows[#rows + 1] = {
            slotKey = slotKey,
            slotLabel = addon.Constants.SLOT_LABELS[slotKey] or slotKey,
            status = status,
            statusLabel = addon.Constants.STATUS_LABELS[status] or status,
            currentItemID = currentItemID,
            currentItemLink = GetEquippedItemLink(slotKey),
            best = slotProfile and slotProfile.best or nil,
            alternatives = slotProfile and slotProfile.alternatives or {},
            duplicateConflict = slotProfile and slotProfile.duplicateConflict or false,
        }
    end

    return rows
end

function engine.GetHeaderSummary()
    local specID = engine.GetSelectedSpecID()

    return {
        season = addon.Data.SeasonMeta.label,
        profileLabel = addon.Constants.PROFILE_LABELS[engine.GetProfileKey()],
        specID = specID,
        specName = specID and util.SafeSpecName(specID) or "알 수 없음",
        provider = addon.Data.SeasonMeta.provider,
    }
end

function engine.GetWindowState()
    return MidnightBisGuideDB.window
end
