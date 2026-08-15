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
    if event == "ADDON_LOADED" and arg1 == (addonName or "MissingTradeSkillsList") then
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
    
    if cmd == "opt" or cmd == "options" or cmd == "config" then
        RR.UI.MainWindow:Show()
        RR.UI.MainWindow:SelectTab("options")
    elseif cmd == "alts" or cmd == "alt" then
        RR.UI.MainWindow:Show()
        RR.UI.MainWindow:SelectTab("alts")
    elseif cmd == "npc" or cmd == "npcs" or cmd == "world" then
        RR.UI.MainWindow:Show()
        RR.UI.MainWindow:SelectTab("npcs")
    elseif cmd == "help" then
        print(RR.COLORS.TITLE .. RR.L["CMD_HELP_HEADER"])
        print(RR.COLORS.GOLD .. "/rr" .. RR.COLORS.WHITE .. RR.L["CMD_HELP_TOGGLE"])
        print(RR.COLORS.GOLD .. "/rr opt" .. RR.COLORS.WHITE .. RR.L["CMD_HELP_OPT"])
        print(RR.COLORS.GOLD .. "/rr alts" .. RR.COLORS.WHITE .. RR.L["CMD_HELP_ALTS"])
        print(RR.COLORS.GOLD .. "/rr npc" .. RR.COLORS.WHITE .. RR.L["CMD_HELP_NPC"])
    else
        RR.UI.MainWindow:Toggle()
    end
end
