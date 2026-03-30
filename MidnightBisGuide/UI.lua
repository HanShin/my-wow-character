local addon = MidnightBisGuide
local util = addon.Util
local engine = addon.Engine

local ui = {
    rows = {},
}

addon.UI = ui

local STATUS_COLORS = {
    complete = "ff3fb950",
    alternative = "ff4da3ff",
    upgrade = "ffffa500",
    missing = "ffff6b6b",
    not_applicable = "ff8f8f8f",
}

local function CreateBackdropFrame(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
    frame:SetBackdropBorderColor(0.35, 0.45, 0.60, 1)
    return frame
end

local function SetMultiline(fs, width)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
end

local function BuildStatusText(rowData)
    local color = STATUS_COLORS[rowData.status] or "ffffffff"
    local text = rowData.statusLabel
    if rowData.duplicateConflict then
        text = text .. " / 중복 주의"
    end
    return util.Colorize(text, color)
end

local function GetCurrentItemText(rowData)
    if rowData.currentItemLink then
        return rowData.currentItemLink
    end
    if rowData.currentItemID then
        return "아이템 #" .. tostring(rowData.currentItemID)
    end
    return "|cff8f8f8f장착 안 됨|r"
end

local function ApplyWindowPosition(frame)
    local windowState = engine.GetWindowState()
    frame:ClearAllPoints()
    if windowState.point then
        frame:SetPoint(
            windowState.point,
            UIParent,
            windowState.relativePoint or windowState.point,
            windowState.x or 0,
            windowState.y or 0
        )
    else
        frame:SetPoint("CENTER")
    end
end

local function SaveWindowPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint()
    local windowState = engine.GetWindowState()
    windowState.point = point
    windowState.relativePoint = relativePoint
    windowState.x = x
    windowState.y = y
end

local function RefreshHeader()
    local summary = engine.GetHeaderSummary()
    ui.header.season:SetText(summary.season)
    ui.header.spec:SetText("스펙: " .. summary.specName)
    ui.header.profile:SetText("모드: " .. summary.profileLabel)
    ui.header.provider:SetText("기본 데이터: " .. summary.provider)
end

local function FillEditorFromCandidate(candidate)
    if not candidate then
        return
    end

    ui.editor.bestItemID:SetText(tostring(candidate.itemID or ""))
    ui.editor.sourceType.currentValue = candidate.sourceType or "other"
    ui.editor.sourceType:SetText(addon.Constants.SOURCE_TYPE_LABELS[ui.editor.sourceType.currentValue] or ui.editor.sourceType.currentValue)
    ui.editor.sourceName:SetText(candidate.sourceName or "")
    ui.editor.bossName:SetText(candidate.bossName or "")
    ui.editor.notes:SetText(candidate.notes or "")
end

local function OpenEditor(rowData)
    local editor = ui.editor
    editor.rowData = rowData
    editor.title:SetText(rowData.slotLabel .. " 편집")

    local best = rowData.best
    local alts = rowData.alternatives or {}

    editor.bestItemID:SetText(best and tostring(best.itemID or "") or "")
    editor.altItemID1:SetText(alts[1] and tostring(alts[1].itemID or "") or "")
    editor.altItemID2:SetText(alts[2] and tostring(alts[2].itemID or "") or "")
    editor.sourceName:SetText(best and best.sourceName or "")
    editor.bossName:SetText(best and best.bossName or "")
    editor.notes:SetText(best and best.notes or "")
    editor.sourceType.currentValue = best and best.sourceType or "other"
    editor.sourceType:SetText(addon.Constants.SOURCE_TYPE_LABELS[editor.sourceType.currentValue] or editor.sourceType.currentValue)

    local candidates = engine.GetDefaultCandidates(engine.GetSelectedSpecID(), engine.GetProfileKey(), rowData.slotKey)
    for index, button in ipairs(editor.candidateButtons) do
        local candidate = candidates[index]
        button.candidate = candidate
        if candidate then
            button:SetText(util.GetItemLabel(candidate))
            button:Show()
        else
            button:Hide()
        end
    end

    editor:Show()
end

local function CloseEditor()
    ui.editor:Hide()
    ui.editor.rowData = nil
end

local function BuildEditor(parent)
    local editor = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
    editor:SetSize(520, 460)
    editor:SetPoint("CENTER")
    editor:SetFrameStrata("DIALOG")
    editor:Hide()
    editor.TitleText:SetText("슬롯 편집")

    editor.title = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    editor.title:SetPoint("TOPLEFT", 14, -36)

    editor.tip = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.tip:SetPoint("TOPLEFT", editor.title, "BOTTOMLEFT", 0, -8)
    editor.tip:SetText("기본 후보를 선택하거나 itemID를 직접 입력할 수 있습니다.")

    editor.candidateButtons = {}
    for index = 1, 4 do
        local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
        button:SetSize(470, 22)
        button:SetPoint("TOPLEFT", 20, -80 - ((index - 1) * 24))
        button:SetScript("OnClick", function(self)
            FillEditorFromCandidate(self.candidate)
        end)
        editor.candidateButtons[index] = button
    end

    local function AddLabel(text, anchor, x, y)
        local label = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -16)
        label:SetText(text)
        return label
    end

    local function AddEditBox(width, height, anchor)
        local box = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
        box:SetAutoFocus(false)
        box:SetSize(width, height or 20)
        box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
        return box
    end

    local anchor = editor.candidateButtons[#editor.candidateButtons]
    local bestLabel = AddLabel("목표 itemID", anchor, 0, -20)
    editor.bestItemID = AddEditBox(140, 24, bestLabel)
    editor.bestItemID:SetNumeric(true)

    local alt1Label = AddLabel("대체 itemID #1", editor.bestItemID, 180, 20)
    editor.altItemID1 = AddEditBox(140, 24, alt1Label)
    editor.altItemID1:SetNumeric(true)

    local alt2Label = AddLabel("대체 itemID #2", editor.altItemID1, 180, 20)
    editor.altItemID2 = AddEditBox(140, 24, alt2Label)
    editor.altItemID2:SetNumeric(true)

    local sourceTypeLabel = AddLabel("출처 타입", editor.bestItemID, 0, -20)
    editor.sourceType = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.sourceType:SetSize(140, 22)
    editor.sourceType:SetPoint("TOPLEFT", sourceTypeLabel, "BOTTOMLEFT", 0, -6)
    editor.sourceType.currentValue = "other"
    editor.sourceType:SetScript("OnClick", function(self)
        local order = addon.Constants.SOURCE_TYPE_ORDER
        local currentIndex = 1
        for index, value in ipairs(order) do
            if value == self.currentValue then
                currentIndex = index
                break
            end
        end
        currentIndex = currentIndex + 1
        if currentIndex > #order then
            currentIndex = 1
        end
        self.currentValue = order[currentIndex]
        self:SetText(addon.Constants.SOURCE_TYPE_LABELS[self.currentValue] or self.currentValue)
    end)

    local sourceNameLabel = AddLabel("출처 이름", editor.sourceType, 0, -18)
    editor.sourceName = AddEditBox(220, 24, sourceNameLabel)

    local bossNameLabel = AddLabel("보스 이름", editor.sourceName, 0, -18)
    editor.bossName = AddEditBox(220, 24, bossNameLabel)

    local notesLabel = AddLabel("메모", editor.bossName, 0, -18)
    editor.notes = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    editor.notes:SetAutoFocus(false)
    editor.notes:SetMultiLine(true)
    editor.notes:SetSize(470, 64)
    editor.notes:SetPoint("TOPLEFT", notesLabel, "BOTTOMLEFT", 0, -6)

    editor.save = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.save:SetSize(110, 24)
    editor.save:SetPoint("BOTTOMRIGHT", -16, 16)
    editor.save:SetText("저장")
    editor.save:SetScript("OnClick", function()
        local rowData = editor.rowData
        if not rowData then
            return
        end

        local bestItemID = tonumber(editor.bestItemID:GetText())
        if not bestItemID then
            UIErrorsFrame:AddMessage("목표 itemID를 입력하세요.", 1, 0.2, 0.2)
            return
        end

        local sourceType = editor.sourceType.currentValue or "other"
        local sourceName = util.Trim(editor.sourceName:GetText())
        local bossName = util.Trim(editor.bossName:GetText())
        local notes = util.Trim(editor.notes:GetText())

        if not engine.GetItemIndex()[bestItemID] and (not sourceName or sourceName == "") then
            UIErrorsFrame:AddMessage("기본 데이터에 없는 itemID는 출처 이름이 필요합니다.", 1, 0.2, 0.2)
            return
        end

        local customProfile = engine.NormalizeCustomSlot(
            bestItemID,
            tonumber(editor.altItemID1:GetText()),
            tonumber(editor.altItemID2:GetText()),
            sourceType,
            sourceName,
            bossName,
            notes
        )

        engine.SaveSlotOverride(engine.GetSelectedSpecID(), engine.GetProfileKey(), rowData.slotKey, customProfile)
        CloseEditor()
        ui.Refresh()
    end)

    editor.cancel = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.cancel:SetSize(110, 24)
    editor.cancel:SetPoint("RIGHT", editor.save, "LEFT", -8, 0)
    editor.cancel:SetText("닫기")
    editor.cancel:SetScript("OnClick", CloseEditor)

    return editor
end

local function CreateRow(parent, index)
    local row = CreateBackdropFrame(parent)
    row:SetSize(830, 88)
    row:SetPoint("TOPLEFT", 6, -6 - ((index - 1) * 92))

    row.slot = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.slot:SetPoint("TOPLEFT", 10, -10)
    row.slot:SetWidth(72)
    row.slot:SetJustifyH("LEFT")

    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.status:SetPoint("TOPLEFT", row.slot, "BOTTOMLEFT", 0, -4)
    row.status:SetWidth(100)
    row.status:SetJustifyH("LEFT")

    row.currentLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.currentLabel:SetPoint("TOPLEFT", 120, -10)
    row.currentLabel:SetText("현재 장비")
    row.current = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.current:SetPoint("TOPLEFT", row.currentLabel, "BOTTOMLEFT", 0, -2)
    SetMultiline(row.current, 220)

    row.targetLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.targetLabel:SetPoint("TOPLEFT", 350, -10)
    row.targetLabel:SetText("목표")
    row.target = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.target:SetPoint("TOPLEFT", row.targetLabel, "BOTTOMLEFT", 0, -2)
    SetMultiline(row.target, 220)

    row.sourceLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sourceLabel:SetPoint("TOPLEFT", 120, -48)
    row.sourceLabel:SetText("획득처")
    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.source:SetPoint("LEFT", row.sourceLabel, "RIGHT", 8, 0)
    row.source:SetWidth(450)
    row.source:SetJustifyH("LEFT")

    row.altLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.altLabel:SetPoint("TOPLEFT", 350, -48)
    row.altLabel:SetText("대체안")
    row.alts = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.alts:SetPoint("LEFT", row.altLabel, "RIGHT", 8, 0)
    row.alts:SetWidth(250)
    row.alts:SetJustifyH("LEFT")

    row.edit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.edit:SetSize(62, 22)
    row.edit:SetPoint("TOPRIGHT", -10, -12)
    row.edit:SetText("편집")

    row.reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.reset:SetSize(62, 22)
    row.reset:SetPoint("TOPRIGHT", -10, -40)
    row.reset:SetText("복원")

    return row
end

function ui.Refresh()
    if not ui.frame then
        return
    end

    RefreshHeader()
    local rows = engine.BuildSlotStates()
    for index, rowData in ipairs(rows) do
        local row = ui.rows[index]
        local capturedRowData = rowData
        row.slot:SetText(rowData.slotLabel)
        row.status:SetText(BuildStatusText(rowData))
        row.current:SetText(GetCurrentItemText(rowData))
        row.target:SetText(rowData.best and util.GetItemLabel(rowData.best) or "|cff8f8f8f데이터 없음|r")
        row.source:SetText(rowData.best and util.GetSourceLabel(rowData.best) or "출처 정보 없음")
        row.alts:SetText(util.FormatAlternatives(rowData.alternatives))

        row.edit:SetScript("OnClick", function()
            OpenEditor(capturedRowData)
        end)

        row.reset:SetScript("OnClick", function()
            engine.ResetSlotOverride(engine.GetSelectedSpecID(), engine.GetProfileKey(), capturedRowData.slotKey)
            ui.Refresh()
        end)
    end
end

function ui.Toggle()
    if not ui.frame then
        return
    end

    if ui.frame:IsShown() then
        ui.frame:Hide()
    else
        ui.frame:Show()
        ui.Refresh()
    end
end

function ui.Initialize()
    if ui.frame then
        return
    end

    local frame = CreateFrame("Frame", "MidnightBisGuideFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(880, 760)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowPosition(self)
    end)
    frame:SetScript("OnHide", function(self)
        SaveWindowPosition(self)
    end)
    frame.TitleText:SetText("Midnight BiS Guide")

    ApplyWindowPosition(frame)

    local header = {}
    header.season = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header.season:SetPoint("TOPLEFT", 16, -34)

    header.spec = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.spec:SetPoint("TOPLEFT", header.season, "BOTTOMLEFT", 0, -8)

    header.profile = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.profile:SetPoint("LEFT", header.spec, "RIGHT", 20, 0)

    header.provider = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.provider:SetPoint("TOPLEFT", header.spec, "BOTTOMLEFT", 0, -6)

    local toggleMode = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    toggleMode:SetSize(120, 24)
    toggleMode:SetPoint("TOPRIGHT", -18, -36)
    toggleMode:SetText("레이드 토글")
    toggleMode:SetScript("OnClick", function()
        engine.ToggleProfileKey()
        ui.Refresh()
    end)

    local cycleSpec = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cycleSpec:SetSize(120, 24)
    cycleSpec:SetPoint("RIGHT", toggleMode, "LEFT", -8, 0)
    cycleSpec:SetText("스펙 변경")
    cycleSpec:SetScript("OnClick", function()
        engine.CycleSelectedSpecID()
        ui.Refresh()
    end)

    local resetProfile = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetProfile:SetSize(120, 24)
    resetProfile:SetPoint("RIGHT", cycleSpec, "LEFT", -8, 0)
    resetProfile:SetText("현재 모드 복원")
    resetProfile:SetScript("OnClick", function()
        engine.ResetProfileOverrides(engine.GetSelectedSpecID(), engine.GetProfileKey())
        ui.Refresh()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -104)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(840, 1500)
    scrollFrame:SetScrollChild(content)

    for index, _ in ipairs(addon.Constants.SLOT_ORDER) do
        ui.rows[index] = CreateRow(content, index)
    end

    ui.frame = frame
    ui.header = header
    ui.editor = BuildEditor(frame)
    frame:Hide()
end
