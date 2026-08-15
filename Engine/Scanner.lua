-- ============================================================================
-- RecipeRadar: Engine/Scanner.lua
-- Native Blizzard TradeSkill & Craft frame scanner
-- ============================================================================

local RR = RecipeRadar
RR.Scanner = {}

RR.Scanner.currentProfession = nil
RR.Scanner.currentRank = 0
RR.Scanner.maxRank = 0

--- Initializes event hooks for scanning
function RR.Scanner:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SKILL_LINES_CHANGED")
    frame:RegisterEvent("TRADE_SKILL_SHOW")
    frame:RegisterEvent("TRADE_SKILL_UPDATE")
    frame:RegisterEvent("CRAFT_SHOW")
    frame:RegisterEvent("CRAFT_UPDATE")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "SKILL_LINES_CHANGED" then
            RR.Scanner:ScanCharacterSkills()
        elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
            RR.Scanner:ScanTradeSkill()
        elseif event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
            RR.Scanner:ScanCraft()
        end
    end)
end

--- Automatically scans character skills tab to register which professions this character has
function RR.Scanner:ScanCharacterSkills()
    local charData = RR.Config:GetCurrentChar()
    if not charData then return end
    charData.professions = charData.professions or {}

    if GetNumSkillLines and GetSkillLineInfo then
        local numSkills = GetNumSkillLines()
        for i = 1, numSkills do
            local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
            if not isHeader and skillName then
                local engKey = RR.DB and RR.DB:GetEnglishProfessionName(skillName)
                if engKey and RR.DB.Raw and RR.DB.Raw.professions and RR.DB.Raw.professions[engKey] then
                    charData.professions[skillName] = charData.professions[skillName] or { known = {} }
                    charData.professions[skillName].current = skillRank or 0
                    charData.professions[skillName].max = skillMaxRank or 0
                end
            end
        end
    end
end

--- Scans standard TradeSkill frame (Blacksmithing, Tailoring, Alchemy, etc.)
function RR.Scanner:ScanTradeSkill()
    if not (GetTradeSkillLine and GetNumTradeSkills) then return end
    
    local profName, currentRank, maxRank = GetTradeSkillLine()
    if not profName or profName == "UNKNOWN" or profName == "Header" then return end

    self.currentProfession = profName
    self.currentRank = currentRank or 0
    self.maxRank = maxRank or 0

    local charData = RR.Config:GetCurrentChar()
    if not charData then return end

    charData.professions[profName] = charData.professions[profName] or {
        current = currentRank,
        max = maxRank,
        known = {},
    }
    local knownTable = charData.professions[profName].known
    charData.professions[profName].current = currentRank
    charData.professions[profName].max = maxRank

    local numSkills = GetNumTradeSkills()
    for i = 1, numSkills do
        local skillName, skillType = GetTradeSkillInfo(i)
        if skillName and skillType ~= "header" then
            local itemLink = GetTradeSkillItemLink(i)
            local recipeLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i)
            
            -- Extract spell ID or item ID
            local spellId = nil
            if recipeLink then
                spellId = tonumber(string.match(recipeLink, "enchant:(%d+)"))
            end
            if not spellId and itemLink then
                spellId = tonumber(string.match(itemLink, "item:(%d+)"))
            end

            if spellId then
                knownTable[spellId] = true
            end
            -- Also store by exact name for fallback lookup
            knownTable[skillName] = true
        end
    end

    -- Trigger UI refresh if main window is open
    if RR.UI and RR.UI.MainWindow and RR.UI.MainWindow.IsShown and RR.UI.MainWindow:IsShown() then
        RR.UI.MainWindow:Refresh()
    end
end

--- Scans Craft frame (Enchanting / Beast Training)
function RR.Scanner:ScanCraft()
    if not (GetCraftDisplaySkillLine and GetNumCrafts) then return end

    local profName, currentRank, maxRank = GetCraftDisplaySkillLine()
    if not profName or profName == "UNKNOWN" then return end

    self.currentProfession = profName
    self.currentRank = currentRank or 0
    self.maxRank = maxRank or 0

    local charData = RR.Config:GetCurrentChar()
    if not charData then return end

    charData.professions[profName] = charData.professions[profName] or {
        current = currentRank,
        max = maxRank,
        known = {},
    }
    local knownTable = charData.professions[profName].known
    charData.professions[profName].current = currentRank
    charData.professions[profName].max = maxRank

    local numCrafts = GetNumCrafts()
    for i = 1, numCrafts do
        local craftName, craftSubSpellName, craftType = GetCraftInfo(i)
        if craftName and craftType ~= "header" then
            local craftLink = GetCraftItemLink and GetCraftItemLink(i)
            local spellId = nil
            if craftLink then
                spellId = tonumber(string.match(craftLink, "enchant:(%d+)"))
            end

            if spellId then
                knownTable[spellId] = true
            end
            knownTable[craftName] = true
        end
    end

    -- Trigger UI refresh
    if RR.UI and RR.UI.MainWindow and RR.UI.MainWindow.IsShown and RR.UI.MainWindow:IsShown() then
        RR.UI.MainWindow:Refresh()
    end
end

--- Safely retrieves profession data table for a character regardless of localized key (German, English, etc.)
-- @param charData table
-- @param profName string
-- @return table or nil
function RR.Scanner:GetProfessionData(charData, profName)
    if not (charData and charData.professions and profName) then return nil end
    
    -- 1. Direct match (e.g. "Schneiderei" or "Tailoring")
    if charData.professions[profName] then
        return charData.professions[profName]
    end

    -- 2. English key match
    local engKey = RR.DB and RR.DB:GetEnglishProfessionName(profName)
    if engKey and charData.professions[engKey] then
        return charData.professions[engKey]
    end

    -- 3. Match across any localized variation stored on this char
    if RR.DB then
        local targetEng = engKey or profName
        for pName, pData in pairs(charData.professions) do
            if RR.DB:GetEnglishProfessionName(pName) == targetEng then
                return pData
            end
        end
    end

    return nil
end

--- Returns whether the active character knows a given recipe
-- @param profName string
-- @param spellId number or string
-- @return boolean
function RR.Scanner:IsRecipeKnown(profName, spellId, spellName)
    local charData = RR.Config:GetCurrentChar()
    local profData = self:GetProfessionData(charData, profName)
    if not (profData and profData.known) then return false end
    local known = profData.known

    if spellId and known[spellId] then return true end
    if spellName and known[spellName] then return true end
    return false
end
