local addon = MidnightBisGuide
local util = addon.Util
local concat = table.concat

local KNOWN_PROFESSIONS = {
    Tailoring = true,
    Blacksmithing = true,
    Leatherworking = true,
    Jewelcrafting = true,
    Inscription = true,
    Alchemy = true,
    Engineering = true,
}

local KNOWN_DUNGEONS = {
    ["Algeth'ar Academy"] = true,
    ["Magister's Terrace"] = true,
    ["Maisara Caverns"] = true,
    ["Nexus-Point Xenas"] = true,
    ["Pit of Saron"] = true,
    ["Seat of the Triumvirate"] = true,
    ["Skyreach"] = true,
    ["Windrunner Spire"] = true,
}

local KNOWN_RAID_INSTANCES = {
    ["March on Quel'Danas"] = true,
    ["The Dreamrift"] = true,
    ["Dreamrift"] = true,
    ["The Voidspire"] = true,
    ["Voidspire"] = true,
}

local KNOWN_RAID_BOSSES = {
    ["Belo'ren"] = "March on Quel'Danas",
    ["Chimaerus"] = "The Dreamrift",
    ["Crown of the Cosmos"] = "The Voidspire",
    ["Fallen-King Salhadaar"] = "The Voidspire",
    ["Imperator Averzian"] = "The Voidspire",
    ["Lightblinded Vanguard"] = "The Voidspire",
    ["Midnight Falls"] = "March on Quel'Danas",
    ["Vaelgor and Ezzorak"] = "The Voidspire",
    ["Vorasius"] = "The Voidspire",
}

local function GetLocalizationBucket(bucketName)
    if GetLocale() ~= "koKR" then
        return nil
    end

    local localization = addon.Data.Localization or {}
    return localization[bucketName]
end

local function RequestItemData(itemID)
    if not itemID or not C_Item or not C_Item.RequestLoadItemDataByID then
        return
    end

    addon.State.pendingItemLoads = addon.State.pendingItemLoads or {}
    if addon.State.pendingItemLoads[itemID] then
        return
    end

    addon.State.pendingItemLoads[itemID] = true
    C_Item.RequestLoadItemDataByID(itemID)
end

local function ResolveItemInfo(itemID)
    if not itemID then
        return nil, nil
    end

    local itemName, itemLink = GetItemInfo(itemID)
    if not itemName then
        RequestItemData(itemID)
    end

    return itemName, itemLink
end

local function ParseStructuredSourceName(sourceName)
    if type(sourceName) ~= "string" then
        return nil, nil
    end

    local left, right = sourceName:match("^(.+)%s%-%s(.+)$")
    if left and right then
        return util.Trim(left), util.Trim(right)
    end

    return nil, nil
end

local function NormalizeSourceData(item)
    local sourceType = item and item.sourceType or nil
    local sourceName = item and util.Trim(item.sourceName) or nil
    local bossName = item and util.Trim(item.bossName) or nil
    local extraSource = nil

    if not sourceName or sourceName == "" then
        return {
            sourceType = sourceType,
            sourceName = nil,
            bossName = bossName,
            extraSource = nil,
        }
    end

    local splitLeft, splitRight = ParseStructuredSourceName(sourceName)
    if splitLeft and splitRight then
        if KNOWN_RAID_INSTANCES[splitRight] then
            sourceType = sourceType == "other" and "raid" or sourceType
            bossName = bossName or splitLeft
            sourceName = splitRight
        elseif KNOWN_DUNGEONS[splitRight] then
            sourceType = sourceType == "other" and "dungeon" or sourceType
            bossName = bossName or splitLeft
            sourceName = splitRight
        else
            extraSource = splitRight
            sourceName = splitLeft
        end
    end

    if sourceType == "other" then
        if KNOWN_PROFESSIONS[sourceName] then
            sourceType = "crafted"
        elseif sourceName == "Matrix Catalyst" or sourceName == "Creation Catalyst" then
            sourceType = "catalyst"
        elseif KNOWN_DUNGEONS[sourceName] then
            sourceType = "dungeon"
        elseif KNOWN_RAID_INSTANCES[sourceName] then
            sourceType = "raid"
        elseif KNOWN_RAID_BOSSES[sourceName] then
            sourceType = "raid"
            bossName = bossName or sourceName
            sourceName = KNOWN_RAID_BOSSES[sourceName]
        end
    end

    if sourceType == "raid" and (not sourceName or sourceName == "") and bossName and KNOWN_RAID_BOSSES[bossName] then
        sourceName = KNOWN_RAID_BOSSES[bossName]
    end

    return {
        sourceType = sourceType,
        sourceName = sourceName,
        bossName = bossName,
        extraSource = extraSource,
    }
end

local function LocalizeNote(note)
    if type(note) ~= "string" or note == "" then
        return note
    end

    note = note:gsub("Matrix Catalyst", util.LocalizeToken("Matrix Catalyst", "sourceNames"))
    note = note:gsub("Creation Catalyst", util.LocalizeToken("Creation Catalyst", "sourceNames"))
    note = note:gsub("Great Vault", util.LocalizeToken("Great Vault", "sourceNames"))
    return note
end

function util.LocalizeToken(value, bucketName)
    if type(value) ~= "string" or value == "" then
        return value
    end

    local bucket = GetLocalizationBucket(bucketName)
    if not bucket then
        return value
    end

    return bucket[value] or value
end

function util.Trim(value)
    if type(value) ~= "string" then
        return value
    end

    return value:match("^%s*(.-)%s*$")
end

function util.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, nestedValue in pairs(value) do
        result[key] = util.DeepCopy(nestedValue)
    end
    return result
end

function util.ShallowCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, nestedValue in pairs(value) do
        result[key] = nestedValue
    end
    return result
end

function util.TableEquals(left, right)
    if left == right then
        return true
    end

    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    for key, value in pairs(left) do
        if not util.TableEquals(value, right[key]) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

function util.ArrayContains(array, predicate)
    if type(array) ~= "table" then
        return false
    end

    for _, value in ipairs(array) do
        if predicate(value) then
            return true
        end
    end

    return false
end

function util.AppendIfMissing(array, candidate, keyName)
    if type(candidate) ~= "table" then
        return
    end

    local key = keyName and candidate[keyName] or candidate
    for _, existing in ipairs(array) do
        local existingKey = keyName and existing[keyName] or existing
        if existingKey == key then
            return
        end
    end

    array[#array + 1] = util.DeepCopy(candidate)
end

function util.GetItemLabel(item)
    if not item then
        return "미설정"
    end

    local itemID = type(item) == "table" and item.itemID or tonumber(item)
    if itemID then
        local itemName, itemLink = ResolveItemInfo(itemID)
        if itemLink then
            return itemLink
        end

        if itemName and itemName ~= "" then
            return itemName
        end
    end

    if type(item) == "table" and item.name and item.name ~= "" then
        return item.name
    end

    if itemID then
        return "아이템 #" .. tostring(itemID)
    end

    return "미설정"
end

function util.GetPlainItemName(item)
    if not item then
        return "미설정"
    end

    local itemID = type(item) == "table" and item.itemID or tonumber(item)
    if itemID then
        local itemName = ResolveItemInfo(itemID)
        if itemName and itemName ~= "" then
            return itemName
        end
    end

    if type(item) == "table" and item.name and item.name ~= "" then
        return item.name
    end

    if itemID then
        return "아이템 #" .. tostring(itemID)
    end

    return "미설정"
end

function util.GetItemLink(item)
    if not item then
        return nil
    end

    local itemID = type(item) == "table" and item.itemID or tonumber(item)
    if not itemID then
        return nil
    end

    local _, itemLink = ResolveItemInfo(itemID)
    return itemLink
end

function util.GetSourceLabel(item)
    if not item then
        return "출처 정보 없음"
    end

    local normalized = NormalizeSourceData(item)

    local labels = addon.Constants.SOURCE_TYPE_LABELS
    local parts = {}

    if normalized.sourceType and labels[normalized.sourceType] then
        parts[#parts + 1] = labels[normalized.sourceType]
    end

    if normalized.sourceName and normalized.sourceName ~= "" then
        parts[#parts + 1] = util.LocalizeToken(normalized.sourceName, "sourceNames")
    end

    if normalized.bossName and normalized.bossName ~= "" then
        parts[#parts + 1] = "(" .. util.LocalizeToken(normalized.bossName, "bossNames") .. ")"
    end

    if #parts == 0 then
        return "출처 정보 없음"
    end

    return concat(parts, " ")
end

function util.GetAcquisitionLabel(item)
    if not item then
        return "획득처 정보 없음"
    end

    local normalized = NormalizeSourceData(item)
    local lines = {}

    if normalized.sourceType == "raid" then
        lines[#lines + 1] = "레이드: " .. util.LocalizeToken(normalized.sourceName or "미상", "sourceNames")
        if normalized.bossName and normalized.bossName ~= "" then
            lines[#lines + 1] = "보스: " .. util.LocalizeToken(normalized.bossName, "bossNames")
        end
    elseif normalized.sourceType == "dungeon" then
        lines[#lines + 1] = "던전: " .. util.LocalizeToken(normalized.sourceName or "미상", "sourceNames")
        if normalized.bossName and normalized.bossName ~= "" then
            lines[#lines + 1] = "보스: " .. util.LocalizeToken(normalized.bossName, "bossNames")
        end
    elseif normalized.sourceType == "crafted" then
        lines[#lines + 1] = "제작: " .. util.LocalizeToken(normalized.sourceName or "전문기술", "sourceNames")
    elseif normalized.sourceType == "catalyst" then
        lines[#lines + 1] = "촉매: " .. util.LocalizeToken(normalized.sourceName or "촉매", "sourceNames")
    elseif normalized.sourceType == "weekly_vault" then
        lines[#lines + 1] = "주간 금고"
    elseif normalized.sourceName and normalized.sourceName ~= "" then
        lines[#lines + 1] = "획득처: " .. util.LocalizeToken(normalized.sourceName, "sourceNames")
        if normalized.bossName and normalized.bossName ~= "" then
            lines[#lines + 1] = "대상: " .. util.LocalizeToken(normalized.bossName, "bossNames")
        end
    else
        lines[#lines + 1] = "획득처 정보 없음"
    end

    if normalized.extraSource and normalized.extraSource ~= "" then
        lines[#lines + 1] = "구역: " .. util.LocalizeToken(normalized.extraSource, "sourceNames")
    end

    if item.notes and item.notes ~= "" then
        local note = LocalizeNote(item.notes)
        if note:find("촉매") or note:find("Catalyst") then
            lines[#lines + 1] = "추가 경로: " .. note
        elseif note:find("금고") or note:find("Vault") then
            lines[#lines + 1] = "추가 경로: " .. note
        elseif normalized.sourceType == "other" then
            lines[#lines + 1] = "비고: " .. note
        end
    end

    return concat(lines, "\n")
end

function util.Colorize(text, colorCode)
    return ("|c%s%s|r"):format(colorCode, tostring(text))
end

function util.ItemIDFromLink(itemLink)
    if not itemLink then
        return nil
    end

    local itemID = itemLink:match("item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

function util.NormalizeItem(item)
    if not item then
        return nil
    end

    local result = util.DeepCopy(item)
    result.itemID = tonumber(result.itemID)
    result.slotKey = result.slotKey and tostring(result.slotKey) or nil
    result.sourceType = result.sourceType or "other"
    result.sourceName = util.Trim(result.sourceName) or ""
    result.bossName = util.Trim(result.bossName) or nil
    result.notes = util.Trim(result.notes) or nil
    result.name = util.Trim(result.name) or ("아이템 #" .. tostring(result.itemID or "?"))
    return result
end

function util.NormalizeSlotProfile(slotProfile)
    if not slotProfile then
        return nil
    end

    local normalized = {
        best = util.NormalizeItem(slotProfile.best),
        alternatives = {},
    }

    if type(slotProfile.alternatives) == "table" then
        for _, alt in ipairs(slotProfile.alternatives) do
            normalized.alternatives[#normalized.alternatives + 1] = util.NormalizeItem(alt)
        end
    end

    return normalized
end

function util.FormatAlternatives(alternatives, useLinks)
    if type(alternatives) ~= "table" or #alternatives == 0 then
        return "대체안 없음"
    end

    local labels = {}
    for _, alt in ipairs(alternatives) do
        if useLinks then
            labels[#labels + 1] = util.GetItemLabel(alt)
        else
            labels[#labels + 1] = util.GetPlainItemName(alt)
        end
    end

    return table.concat(labels, ", ")
end

function util.SafeSpecName(specID)
    if GetSpecializationInfoByID then
        local first, second = GetSpecializationInfoByID(specID)
        if type(second) == "string" and second ~= "" then
            return second
        end
        if type(first) == "string" and first ~= "" then
            return first
        end
    end

    local registry = addon.Data.SpecRegistry.bySpecID[specID]
    if registry then
        return registry.name
    end

    return tostring(specID)
end
