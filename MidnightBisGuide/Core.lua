local addon = MidnightBisGuide
local engine = addon.Engine
local ui = addon.UI

SLASH_MIDNIGHTBISGUIDE1 = "/bis"

SlashCmdList.MIDNIGHTBISGUIDE = function(message)
    local command, argument = message:match("^(%S+)%s*(.-)$")
    command = command and command:lower() or ""
    argument = argument and argument:lower() or ""

    if command == "raid" then
        engine.ToggleProfileKey()
        ui.Refresh()
        print(("Midnight BiS Guide: %s"):format(addon.Constants.PROFILE_LABELS[engine.GetProfileKey()]))
        return
    end

    if command == "spec" then
        if argument == "auto" then
            engine.SetSelectedSpecID(nil)
        elseif argument == "" then
            engine.CycleSelectedSpecID()
        else
            local numeric = tonumber(argument)
            if numeric then
                engine.SetSelectedSpecID(numeric)
            else
                engine.CycleSelectedSpecID()
            end
        end

        ui.Refresh()
        return
    end

    ui.Toggle()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addon.ADDON_NAME then
            return
        end

        engine.InitializeDB()
        engine.BuildDefaultItemIndex()
        ui.Initialize()
        return
    end

    if ui.frame and ui.frame:IsShown() then
        ui.Refresh()
    end
end)
