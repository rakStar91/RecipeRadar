-- ============================================================================
-- RecipeRadar: RecipeRadar.lua
-- Main lifecycle coordinator and slash command handler
-- ============================================================================

local RR = RecipeRadar
local addonName = ...

local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")

coreFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == (addonName or "RecipeRadar") then
        -- 1. Initialize Configuration & SavedVariables
        RR.Config:Initialize()

        -- 2. Initialize Database & Scanner
        RR.DB:Initialize()
        RR.Scanner:Initialize()

        -- 3. Initialize UI Components
        RR.UI.AttachButton:Initialize()
        RR.UI.MinimapButton:Initialize()
        RR.UI.Tooltips:Initialize()

    elseif event == "PLAYER_LOGIN" then
        print(RR.COLORS.TITLE .. "RecipeRadar " .. RR.COLORS.WHITE .. "v" .. RR.VERSION .. RR.COLORS.GREY .. " (by " .. RR.AUTHOR .. ") " .. RR.L["LOADED_WELCOME"])
    end
end)

-- ----------------------------------------------------------------------------
-- Slash Commands
-- ----------------------------------------------------------------------------
SLASH_RECIPERADAR1 = "/rr"
SLASH_RECIPERADAR2 = "/reciperadar"

SlashCmdList["RECIPERADAR"] = function(msg)
    local cmd = msg and string.lower(strtrim(msg)) or ""
    
    if cmd == "help" then
        print(RR.COLORS.TITLE .. (RR.L["CMD_HELP_HEADER"] or "RecipeRadar Commands:"))
        print(RR.COLORS.GOLD .. "/rr" .. RR.COLORS.WHITE .. (RR.L["CMD_HELP_TOGGLE"] or " - Toggle RecipeRadar window"))
        print(RR.COLORS.GOLD .. "/rr minimap" .. RR.COLORS.WHITE .. (RR.L["CMD_HELP_MINIMAP"] or " - Toggle minimap button"))
        print(RR.COLORS.GOLD .. "/rr debug" .. RR.COLORS.WHITE .. " - Toggle verbose debug logging")
    elseif cmd == "minimap" or cmd == "mm" then
        local isShown = RR.UI.MinimapButton:Toggle()
        if isShown then
            print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. (RR.L["CMD_MINIMAP_SHOWN"] or "Minimap button is now shown."))
        else
            print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. (RR.L["CMD_MINIMAP_HIDDEN"] or "Minimap button is now hidden. Type '/rr minimap' to show it again."))
        end
    elseif cmd == "debug" then
        RR.Debug = not RR.Debug
        print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. "Debug logging is now " .. (RR.Debug and "|cff33ff33ENABLED|r" or "|cffff4444DISABLED|r"))
    else
        RR.UI.MainWindow:Toggle()
    end
end
