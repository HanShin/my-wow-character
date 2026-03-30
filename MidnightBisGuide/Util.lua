local addon = MidnightBisGuide
local util = addon.Util

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

    if item.name and item.name ~= "" then
        return item.name
    end

    if item.itemID then
        return "아이템 #" .. tostring(item.itemID)
    end

    return "미설정"
end

function util.GetSourceLabel(item)
    if not item then
        return "출처 정보 없음"
    end

    local labels = addon.Constants.SOURCE_TYPE_LABELS
    local parts = {}

    if item.sourceType and labels[item.sourceType] then
        parts[#parts + 1] = labels[item.sourceType]
    end

    if item.sourceName and item.sourceName ~= "" then
        parts[#parts + 1] = item.sourceName
    end

    if item.bossName and item.bossName ~= "" then
        parts[#parts + 1] = "(" .. item.bossName .. ")"
    end

    if #parts == 0 then
        return "출처 정보 없음"
    end

    return table.concat(parts, " ")
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

function util.FormatAlternatives(alternatives)
    if type(alternatives) ~= "table" or #alternatives == 0 then
        return "대체안 없음"
    end

    local labels = {}
    for _, alt in ipairs(alternatives) do
        labels[#labels + 1] = util.GetItemLabel(alt)
    end

    return table.concat(labels, ", ")
end

function util.SafeSpecName(specID)
    local registry = addon.Data.SpecRegistry.bySpecID[specID]
    if registry then
        return registry.name
    end

    return tostring(specID)
end
