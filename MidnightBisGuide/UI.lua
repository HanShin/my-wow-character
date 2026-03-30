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
        return util.GetItemLabel(rowData.currentItemID)
    end
    return "|cff8f8f8f장착 안 됨|r"
end

local ROW_WIDTH = 830
local ROW_HEIGHT = 144
local ROW_SPACING = 148

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

local function CreateItemLinkButton(parent, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height or 20)
    button:RegisterForClicks("LeftButtonUp")

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetAllPoints()
    button.text:SetJustifyH("LEFT")
    button.text:SetJustifyV("TOP")
    button.text:SetWordWrap(true)

    button:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function(self)
        if self.itemLink then
            HandleModifiedItemClick(self.itemLink)
        end
    end)

    return button
end

local function SetItemLinkButton(button, item, emptyText)
    if not button then
        return
    end

    local itemLink = nil
    local label = emptyText or "|cff8f8f8f미설정|r"
    if type(item) == "string" then
        itemLink = item
        label = item
    elseif item then
        itemLink = util.GetItemLink(item)
        label = util.GetItemLabel(item)
    end

    button.itemLink = itemLink
    button.text:SetText(label)
    button:EnableMouse(itemLink ~= nil)
end

local function SetCycleButtonState(button, options, index, formatter)
    button.options = options or {}
    if #button.options == 0 then
        button.currentIndex = 0
        button:SetText("선택 없음")
        button:Disable()
        return
    end

    if not index or index < 1 then
        index = 1
    elseif index > #button.options then
        index = #button.options
    end

    button.currentIndex = index
    button:Enable()

    local value = button.options[index]
    button:SetText(formatter and formatter(value, index, #button.options) or tostring(value))
end

local function FillEditorFromCandidate(candidate)
    if not candidate or not ui.editor then
        return
    end

    ui.editor.highlightedItem = util.DeepCopy(candidate)
    ui.editor.selectionPreview.link:SetText(util.GetItemLabel(candidate))
    ui.editor.selectionPreview.source:SetText(util.GetAcquisitionLabel(candidate))
end

local function GetEditorGroups(editor)
    if not editor.rowData or not editor.sourceType.options or #editor.sourceType.options == 0 then
        return {}
    end

    local sourceType = editor.sourceType.options[editor.sourceType.currentIndex]
    return engine.GetCatalogGroups(sourceType, editor.rowData.slotKey)
end

local function GetEditorBossOptions(editor, groups)
    local group = groups[editor.groupButton.currentIndex]
    if not group then
        return {}
    end

    local bosses = {}
    if #group.bosses > 1 then
        bosses[#bosses + 1] = {
            label = "전체",
            allBosses = true,
        }
    end

    for _, boss in ipairs(group.bosses) do
        bosses[#bosses + 1] = boss
    end

    return bosses
end

local function BuildBossItemList(group, bossOption)
    if not group then
        return {}
    end

    if bossOption and not bossOption.allBosses then
        return bossOption.items or {}
    end

    local items = {}
    for _, boss in ipairs(group.bosses or {}) do
        for _, item in ipairs(boss.items or {}) do
            util.AppendIfMissing(items, item, "itemID")
        end
    end
    return items
end

local function RefreshEditorAssignments(editor)
    SetItemLinkButton(editor.assignment.bestLink, editor.selected.best, "|cff8f8f8f목표 미설정|r")
    SetItemLinkButton(editor.assignment.alt1Link, editor.selected.alt1, "|cff8f8f8f대체 1 미설정|r")
    SetItemLinkButton(editor.assignment.alt2Link, editor.selected.alt2, "|cff8f8f8f대체 2 미설정|r")
end

local function RefreshEditorBrowser(editor)
    local sourceTypes = engine.GetCatalogSourceTypes(editor.rowData.slotKey)
    SetCycleButtonState(editor.sourceType, sourceTypes, editor.sourceType.currentIndex, function(value, index, total)
        return ("획득처: %s (%d/%d)"):format(addon.Constants.SOURCE_TYPE_LABELS[value] or value, index, total)
    end)

    local groups = GetEditorGroups(editor)
    SetCycleButtonState(editor.groupButton, groups, editor.groupButton.currentIndex, function(value, index, total)
        return ("콘텐츠: %s (%d/%d)"):format(util.LocalizeToken(value.label, "sourceNames"), index, total)
    end)

    local bossOptions = GetEditorBossOptions(editor, groups)
    SetCycleButtonState(editor.bossButton, bossOptions, editor.bossButton.currentIndex, function(value, index, total)
        return ("보스: %s (%d/%d)"):format(util.LocalizeToken(value.label, "bossNames"), index, total)
    end)

    local group = groups[editor.groupButton.currentIndex]
    local bossOption = bossOptions[editor.bossButton.currentIndex]
    local items = BuildBossItemList(group, bossOption)
    editor.filteredItems = items

    local pageSize = #editor.itemButtons
    local totalPages = math.max(1, math.ceil(#items / pageSize))
    if editor.pageIndex > totalPages then
        editor.pageIndex = totalPages
    elseif editor.pageIndex < 1 then
        editor.pageIndex = 1
    end
    editor.pageLabel:SetText(("페이지 %d/%d"):format(#items == 0 and 0 or editor.pageIndex, totalPages))

    local pageStart = ((editor.pageIndex - 1) * pageSize) + 1
    for index, button in ipairs(editor.itemButtons) do
        local item = items[pageStart + index - 1]
        button.item = item
        if item then
            local text = util.GetCatalogItemText(item)
            if editor.highlightedItem and editor.highlightedItem.itemID == item.itemID then
                text = "|cff4da3ff" .. text .. "|r"
            end
            button:SetText(text)
            button:Show()
        else
            button:Hide()
        end
    end

    if editor.highlightedItem then
        editor.selectionPreview.link:SetText(util.GetItemLabel(editor.highlightedItem))
        editor.selectionPreview.source:SetText(util.GetAcquisitionLabel(editor.highlightedItem))
    else
        editor.selectionPreview.link:SetText("|cff8f8f8f아이템을 선택하세요|r")
        editor.selectionPreview.source:SetText("획득처 정보 없음")
    end
end

local function OpenEditor(rowData)
    local editor = ui.editor
    editor.rowData = rowData
    editor.title:SetText(rowData.slotLabel .. " 편집")
    editor.selected = {
        best = rowData.best and util.DeepCopy(rowData.best) or nil,
        alt1 = rowData.alternatives[1] and util.DeepCopy(rowData.alternatives[1]) or nil,
        alt2 = rowData.alternatives[2] and util.DeepCopy(rowData.alternatives[2]) or nil,
    }
    editor.highlightedItem = rowData.best and util.DeepCopy(rowData.best) or nil
    editor.pageIndex = 1
    editor.sourceType.currentIndex = 1
    editor.groupButton.currentIndex = 1
    editor.bossButton.currentIndex = 1

    local candidates = engine.GetDefaultCandidates(engine.GetSelectedSpecID(), engine.GetProfileKey(), rowData.slotKey)
    for index, button in ipairs(editor.candidateButtons) do
        local candidate = candidates[index]
        button.candidate = candidate
        if candidate then
            button:SetText(util.GetCatalogItemText(candidate))
            button:Show()
        else
            button:Hide()
        end
    end

    local preferredSource = rowData.best and util.NormalizeSourceData(rowData.best).sourceType or nil
    local sourceTypes = engine.GetCatalogSourceTypes(rowData.slotKey)
    for index, sourceType in ipairs(sourceTypes) do
        if sourceType == preferredSource then
            editor.sourceType.currentIndex = index
            break
        end
    end

    RefreshEditorAssignments(editor)
    RefreshEditorBrowser(editor)
    editor:Show()
end

local function CloseEditor()
    ui.editor:Hide()
    ui.editor.rowData = nil
end

local function BuildEditor(parent)
    local editor = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
    editor:SetSize(620, 610)
    editor:SetPoint("CENTER")
    editor:SetFrameStrata("DIALOG")
    editor:Hide()
    editor.TitleText:SetText("슬롯 편집")

    editor.title = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    editor.title:SetPoint("TOPLEFT", 14, -36)

    editor.tip = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.tip:SetPoint("TOPLEFT", editor.title, "BOTTOMLEFT", 0, -8)
    editor.tip:SetText("좌클릭은 다음 항목, 우클릭은 이전 항목입니다. 현재 시즌 던전/레이드 목록에서 골라 목표와 대체안을 저장할 수 있습니다.")

    editor.candidateButtons = {}
    for index = 1, 4 do
        local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
        button:SetSize(580, 22)
        button:SetPoint("TOPLEFT", 20, -80 - ((index - 1) * 24))
        button:SetScript("OnClick", function(self)
            FillEditorFromCandidate(self.candidate)
            RefreshEditorBrowser(editor)
        end)
        editor.candidateButtons[index] = button
    end

    local function AddLabel(text, anchor, x, y)
        local label = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -16)
        label:SetText(text)
        return label
    end

    local function AddCycleButton(width, anchor)
        local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
        button:SetSize(width, 24)
        button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            if #self.options == 0 then
                return
            end

            local delta = mouseButton == "RightButton" and -1 or 1
            local nextIndex = self.currentIndex + delta
            if nextIndex < 1 then
                nextIndex = #self.options
            elseif nextIndex > #self.options then
                nextIndex = 1
            end
            self.currentIndex = nextIndex

            if self == editor.sourceType then
                editor.groupButton.currentIndex = 1
                editor.bossButton.currentIndex = 1
            elseif self == editor.groupButton then
                editor.bossButton.currentIndex = 1
            end
            editor.pageIndex = 1
            RefreshEditorBrowser(editor)
        end)
        button.options = {}
        button.currentIndex = 1
        return button
    end

    local anchor = editor.candidateButtons[#editor.candidateButtons]
    local browseLabel = AddLabel("시즌 콘텐츠 탐색", anchor, 0, -18)
    editor.sourceType = AddCycleButton(580, browseLabel)
    editor.groupButton = AddCycleButton(580, editor.sourceType)
    editor.bossButton = AddCycleButton(580, editor.groupButton)

    editor.pagePrev = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.pagePrev:SetSize(80, 22)
    editor.pagePrev:SetPoint("TOPLEFT", editor.bossButton, "BOTTOMLEFT", 0, -8)
    editor.pagePrev:SetText("이전 페이지")
    editor.pagePrev:SetScript("OnClick", function()
        editor.pageIndex = math.max(1, (editor.pageIndex or 1) - 1)
        RefreshEditorBrowser(editor)
    end)

    editor.pageNext = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.pageNext:SetSize(80, 22)
    editor.pageNext:SetPoint("LEFT", editor.pagePrev, "RIGHT", 8, 0)
    editor.pageNext:SetText("다음 페이지")
    editor.pageNext:SetScript("OnClick", function()
        editor.pageIndex = (editor.pageIndex or 1) + 1
        RefreshEditorBrowser(editor)
    end)

    editor.pageLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.pageLabel:SetPoint("LEFT", editor.pageNext, "RIGHT", 12, 0)

    local previewLabel = AddLabel("현재 선택", editor.pagePrev, 0, -18)
    editor.selectionPreview = {}
    editor.selectionPreview.link = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    editor.selectionPreview.link:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -4)
    SetMultiline(editor.selectionPreview.link, 580)
    editor.selectionPreview.source = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.selectionPreview.source:SetPoint("TOPLEFT", editor.selectionPreview.link, "BOTTOMLEFT", 0, -4)
    SetMultiline(editor.selectionPreview.source, 580)

    editor.itemButtons = {}
    for index = 1, 6 do
        local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
        button:SetSize(580, 22)
        button:SetPoint("TOPLEFT", editor.selectionPreview.source, "BOTTOMLEFT", 0, -10 - ((index - 1) * 24))
        button:SetScript("OnClick", function(self)
            editor.highlightedItem = util.DeepCopy(self.item)
            RefreshEditorBrowser(editor)
        end)
        editor.itemButtons[index] = button
    end

    local assignAnchor = editor.itemButtons[#editor.itemButtons]
    editor.assignBest = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignBest:SetSize(90, 22)
    editor.assignBest:SetPoint("TOPLEFT", assignAnchor, "BOTTOMLEFT", 0, -10)
    editor.assignBest:SetText("목표로")
    editor.assignBest:SetScript("OnClick", function()
        if editor.highlightedItem then
            editor.selected.best = util.DeepCopy(editor.highlightedItem)
            RefreshEditorAssignments(editor)
        end
    end)

    editor.assignAlt1 = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignAlt1:SetSize(90, 22)
    editor.assignAlt1:SetPoint("LEFT", editor.assignBest, "RIGHT", 8, 0)
    editor.assignAlt1:SetText("대체1로")
    editor.assignAlt1:SetScript("OnClick", function()
        if editor.highlightedItem then
            editor.selected.alt1 = util.DeepCopy(editor.highlightedItem)
            RefreshEditorAssignments(editor)
        end
    end)

    editor.assignAlt2 = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignAlt2:SetSize(90, 22)
    editor.assignAlt2:SetPoint("LEFT", editor.assignAlt1, "RIGHT", 8, 0)
    editor.assignAlt2:SetText("대체2로")
    editor.assignAlt2:SetScript("OnClick", function()
        if editor.highlightedItem then
            editor.selected.alt2 = util.DeepCopy(editor.highlightedItem)
            RefreshEditorAssignments(editor)
        end
    end)

    editor.assignment = {}
    local assignmentLabel = AddLabel("선택된 목표/대체안", editor.assignBest, 0, -12)

    editor.assignment.bestTitle = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.assignment.bestTitle:SetPoint("TOPLEFT", assignmentLabel, "BOTTOMLEFT", 0, -4)
    editor.assignment.bestTitle:SetText("목표")
    editor.assignment.bestLink = CreateItemLinkButton(editor, 520, 20)
    editor.assignment.bestLink:SetPoint("TOPLEFT", editor.assignment.bestTitle, "BOTTOMLEFT", 0, -2)
    editor.assignment.clearBest = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignment.clearBest:SetSize(48, 20)
    editor.assignment.clearBest:SetPoint("LEFT", editor.assignment.bestLink, "RIGHT", 8, 0)
    editor.assignment.clearBest:SetText("해제")
    editor.assignment.clearBest:SetScript("OnClick", function()
        editor.selected.best = nil
        RefreshEditorAssignments(editor)
    end)

    editor.assignment.alt1Title = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.assignment.alt1Title:SetPoint("TOPLEFT", editor.assignment.bestLink, "BOTTOMLEFT", 0, -6)
    editor.assignment.alt1Title:SetText("대체 1")
    editor.assignment.alt1Link = CreateItemLinkButton(editor, 520, 20)
    editor.assignment.alt1Link:SetPoint("TOPLEFT", editor.assignment.alt1Title, "BOTTOMLEFT", 0, -2)
    editor.assignment.clearAlt1 = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignment.clearAlt1:SetSize(48, 20)
    editor.assignment.clearAlt1:SetPoint("LEFT", editor.assignment.alt1Link, "RIGHT", 8, 0)
    editor.assignment.clearAlt1:SetText("해제")
    editor.assignment.clearAlt1:SetScript("OnClick", function()
        editor.selected.alt1 = nil
        RefreshEditorAssignments(editor)
    end)

    editor.assignment.alt2Title = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.assignment.alt2Title:SetPoint("TOPLEFT", editor.assignment.alt1Link, "BOTTOMLEFT", 0, -6)
    editor.assignment.alt2Title:SetText("대체 2")
    editor.assignment.alt2Link = CreateItemLinkButton(editor, 520, 20)
    editor.assignment.alt2Link:SetPoint("TOPLEFT", editor.assignment.alt2Title, "BOTTOMLEFT", 0, -2)
    editor.assignment.clearAlt2 = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.assignment.clearAlt2:SetSize(48, 20)
    editor.assignment.clearAlt2:SetPoint("LEFT", editor.assignment.alt2Link, "RIGHT", 8, 0)
    editor.assignment.clearAlt2:SetText("해제")
    editor.assignment.clearAlt2:SetScript("OnClick", function()
        editor.selected.alt2 = nil
        RefreshEditorAssignments(editor)
    end)

    editor.save = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    editor.save:SetSize(110, 24)
    editor.save:SetPoint("BOTTOMRIGHT", -16, 16)
    editor.save:SetText("저장")
    editor.save:SetScript("OnClick", function()
        local rowData = editor.rowData
        if not rowData then
            return
        end

        if not editor.selected.best then
            UIErrorsFrame:AddMessage("목표 아이템을 선택하세요.", 1, 0.2, 0.2)
            return
        end

        local customProfile = engine.BuildCustomSlotProfile(
            rowData.slotKey,
            editor.selected.best,
            editor.selected.alt1,
            editor.selected.alt2
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
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 6, -6 - ((index - 1) * ROW_SPACING))

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
    row.current = CreateItemLinkButton(row, 220, 24)
    row.current:SetPoint("TOPLEFT", row.currentLabel, "BOTTOMLEFT", 0, -2)

    row.targetLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.targetLabel:SetPoint("TOPLEFT", 350, -10)
    row.targetLabel:SetText("목표")
    row.target = CreateItemLinkButton(row, 170, 24)
    row.target:SetPoint("TOPLEFT", row.targetLabel, "BOTTOMLEFT", 0, -2)

    row.sourceLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sourceLabel:SetPoint("TOPLEFT", 350, -48)
    row.sourceLabel:SetText("획득처")
    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.source:SetPoint("TOPLEFT", row.sourceLabel, "BOTTOMLEFT", 0, -2)
    SetMultiline(row.source, 395)

    row.altLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.altLabel:SetPoint("TOPLEFT", 528, -10)
    row.altLabel:SetText("대체안")
    row.altButtons = {}
    for altIndex = 1, 2 do
        row.altButtons[altIndex] = CreateItemLinkButton(row, 116, 20)
        if altIndex == 1 then
            row.altButtons[altIndex]:SetPoint("TOPLEFT", row.altLabel, "BOTTOMLEFT", 0, -2)
        else
            row.altButtons[altIndex]:SetPoint("LEFT", row.altButtons[altIndex - 1], "RIGHT", 6, 0)
        end
    end
    row.altEmpty = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.altEmpty:SetPoint("TOPLEFT", row.altLabel, "BOTTOMLEFT", 0, -2)
    row.altEmpty:SetText("대체안 없음")

    row.edit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.edit:SetSize(52, 22)
    row.edit:SetPoint("TOPRIGHT", -10, -12)
    row.edit:SetText("편집")

    row.reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.reset:SetSize(52, 22)
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
        if rowData.currentItemLink or rowData.currentItemID then
            SetItemLinkButton(row.current, rowData.currentItemLink or rowData.currentItemID, "|cff8f8f8f장착 안 됨|r")
        else
            SetItemLinkButton(row.current, nil, "|cff8f8f8f장착 안 됨|r")
        end
        SetItemLinkButton(row.target, rowData.best, "|cff8f8f8f데이터 없음|r")
        row.source:SetText(rowData.best and util.GetAcquisitionLabel(rowData.best) or "획득처 정보 없음")

        if rowData.alternatives and #rowData.alternatives > 0 then
            row.altEmpty:Hide()
            for altIndex, button in ipairs(row.altButtons) do
                local altItem = rowData.alternatives[altIndex]
                if altItem then
                    SetItemLinkButton(button, altItem, nil)
                    button:Show()
                else
                    button:Hide()
                end
            end
        else
            row.altEmpty:Show()
            for _, button in ipairs(row.altButtons) do
                button:Hide()
            end
        end

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
    content:SetSize(840, (#addon.Constants.SLOT_ORDER * ROW_SPACING) + 24)
    scrollFrame:SetScrollChild(content)

    for index, _ in ipairs(addon.Constants.SLOT_ORDER) do
        ui.rows[index] = CreateRow(content, index)
    end

    ui.frame = frame
    ui.header = header
    ui.editor = BuildEditor(frame)
    frame:Hide()
end
