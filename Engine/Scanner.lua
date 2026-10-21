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
    -- The last three exist only in clients with the modern profession window (WoW Forever)
    RR.Utils:RegisterEvents(frame, {
        "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED",
        "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE",
        "CRAFT_SHOW", "CRAFT_UPDATE",
        "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED",
    })

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "SKILL_LINES_CHANGED" then
            RR.Scanner:ScanCharacterSkills()
        elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
            RR.Scanner:ScanTradeSkill()
        elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED"
                or event == "NEW_RECIPE_LEARNED" then
            RR.Scanner:QueueScanTradeSkill()
        elseif event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
            RR.Scanner:ScanCraft()
        end
    end)
end

--- True on clients that only have the modern profession API (WoW Forever): no GetTradeSkillLine & co.
local function UsesModernTradeSkillAPI()
    return not (GetTradeSkillLine and GetNumTradeSkills)
        and C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetRecipeInfo
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

--- Returns the current active profession key (e.g. Leatherworking), scanning character skills if needed
function RR.Scanner:GetCurrentProfession()
    if self.currentProfession and self.currentProfession ~= "" then
        return RR.DB:GetEnglishProfessionName(self.currentProfession)
    end

    self:ScanCharacterSkills()

    if self.currentProfession and self.currentProfession ~= "" then
        return RR.DB:GetEnglishProfessionName(self.currentProfession)
    end

    local charData = RR.Config:GetCurrentChar()
    if charData and charData.professions then
        local craftingProfs = RR.DB:GetCustomProfessionMenu()
            or { "Leatherworking", "Tailoring", "Blacksmithing", "Alchemy", "Engineering", "Enchanting", "Jewelcrafting", "Cooking", "First Aid", "Poisons" }
        for _, profKey in ipairs(craftingProfs) do
            local locName = RR.DB:GetProfessionDisplayName(profKey)
            if charData.professions[profKey] or (locName and charData.professions[locName]) then
                self.currentProfession = profKey
                return profKey
            end
        end
    end

    return "Leatherworking"
end

--- Automatically scans character skills tab to register which professions this character has
function RR.Scanner:ScanCharacterSkills()
    local charData = RR.Config:GetCurrentChar()
    if not charData then return end
    charData.professions = charData.professions or {}
    charData.level = (UnitLevel and UnitLevel("player")) or charData.level or 1
    charData.faction = (UnitFactionGroup and UnitFactionGroup("player")) or charData.faction or "Neutral"

    local primaryCraftingProf = nil
    local firstGatheringProf = nil

    if GetNumSkillLines and GetSkillLineInfo then
        local numSkills = GetNumSkillLines()
        for i = 1, numSkills do
            local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
            if not isHeader and skillName then
                local engKey = RR.DB and RR.DB:GetEnglishProfessionName(skillName)
                if engKey and RR.DB.Raw and RR.DB.Raw.professions and RR.DB.Raw.professions[engKey] then
                    charData.professions[engKey] = charData.professions[engKey] or { known = {} }
                    charData.professions[engKey].current = skillRank or 0
                    charData.professions[engKey].max = skillMaxRank or 0
                    charData.professions[skillName] = charData.professions[engKey]

                    -- Exclude gathering-only professions from being the default recipe window
                    local gathering = engKey == "Skinning" or engKey == "Herbalism" or engKey == "Mining" or engKey == "Fishing"
                    if not gathering then
                        primaryCraftingProf = primaryCraftingProf or engKey
                    else
                        firstGatheringProf = firstGatheringProf or engKey
                    end
                end
            end
        end
    end

    if not self.currentProfession then
        -- Only data with its own profession menu (WoW Forever) offers the gathering professions
        self.currentProfession = primaryCraftingProf or (RR.DB:GetCustomProfessionMenu() and firstGatheringProf) or nil
    end

    if UsesModernTradeSkillAPI() then
        self:ScanKnownSpells(charData)
    end
end

--- Marks recipes as known that the spell book reports as known (modern clients only).
-- This works without opening the profession window; it can only add recipes, never remove them.
function RR.Scanner:ScanKnownSpells(charData)
    local isKnown = C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell
    if not isKnown then return end
    for profKey, profData in pairs(charData.professions or {}) do
        -- English keys only: localized keys point to the same table
        if type(profData) == "table" and RR.DB.Raw.professions and RR.DB.Raw.professions[profKey] then
            profData.known = profData.known or {}
            for _, recipe in ipairs(RR.DB:GetRecipesForProfession(profKey)) do
                if not profData.known[recipe.id] and isKnown(recipe.id) == true then
                    profData.known[recipe.id] = true
                end
            end
        end
    end
end

--- Scans standard TradeSkill frame (Blacksmithing, Tailoring, Alchemy, etc.)
function RR.Scanner:ScanTradeSkill()
    if UsesModernTradeSkillAPI() then
        return self:ScanTradeSkillModern()
    end
    if not (GetTradeSkillLine and GetNumTradeSkills) then return end

    local profName, currentRank, maxRank = GetTradeSkillLine()
    if not profName or profName == "UNKNOWN" or profName == "Header" then return end

    local engProf = RR.DB:GetEnglishProfessionName(profName)
    self.currentProfession = engProf
    self.currentRank = currentRank or 0
    self.maxRank = maxRank or 0

    local charData = RR.Config:GetCurrentChar()
    if not charData then return end

    charData.professions[engProf] = charData.professions[engProf] or {
        current = currentRank,
        max = maxRank,
        known = {},
    }
    charData.professions[profName] = charData.professions[engProf]
    local knownTable = charData.professions[engProf].known
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

--- Returns the English profession key for a ProfessionInfo of the modern profession API.
local function ResolveProfessionKey(info)
    for _, name in ipairs({ info.professionName, info.parentProfessionName }) do
        if name and not IsSecret(name) and name ~= "" then
            local key = RR.DB:GetEnglishProfessionName(name)
            if RR.DB.Raw.professions and RR.DB.Raw.professions[key] then
                return key, name
            end
        end
    end
end

--- Reads which profession the game's profession window currently shows (modern API) and makes it
-- the current profession. Returns the key and the ProfessionInfo, or nil when none is open.
function RR.Scanner:ReadOpenProfession()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if type(info) ~= "table" or IsSecret(info) then return nil end
    local key, name = ResolveProfessionKey(info)
    if not key then return nil end

    self.currentProfession = key
    self.currentRank = info.skillLevel or 0
    self.maxRank = info.maxSkillLevel or 0
    return key, info, name
end

--- Called when the RR window opens: follow the profession shown in the game's profession window.
-- Classic clients do this through the TRADE_SKILL events, so only modern clients need it here.
function RR.Scanner:SyncWithOpenProfession()
    if not UsesModernTradeSkillAPI() then return end
    local window = _G.ProfessionsFrame
    if window and window:IsShown() then
        self:ReadOpenProfession()
    end
end

--- Scans the profession window of clients without GetTradeSkillLine (WoW Forever)
function RR.Scanner:ScanTradeSkillModern()
    local key, info, name = self:ReadOpenProfession()
    if not key then return end

    local charData = RR.Config:GetCurrentChar()
    if not charData then return end
    charData.professions = charData.professions or {}

    local profData = charData.professions[key] or { known = {} }
    profData.known = profData.known or {}
    profData.current = self.currentRank
    profData.max = self.maxRank
    charData.professions[key] = profData
    charData.professions[name] = profData

    for _, recipe in ipairs(RR.DB:GetRecipesForProfession(key)) do
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipe.id)
        if type(recipeInfo) == "table" and not IsSecret(recipeInfo) and not IsSecret(recipeInfo.learned)
                and recipeInfo.learned == true then
            profData.known[recipe.id] = true
            if recipeInfo.name and not IsSecret(recipeInfo.name) then
                profData.known[recipeInfo.name] = true
            end
        end
    end

    if RR.UI and RR.UI.MainWindow and RR.UI.MainWindow.IsShown and RR.UI.MainWindow:IsShown() then
        RR.UI.MainWindow:Refresh()
    end
end

--- The modern profession window fires list updates in bursts (every search/filter change), so scans are merged.
function RR.Scanner:QueueScanTradeSkill()
    if self.scanQueued then return end
    if not (C_Timer and C_Timer.After) then
        return self:ScanTradeSkill()
    end
    self.scanQueued = true
    C_Timer.After(0.2, function()
        self.scanQueued = false
        self:ScanTradeSkill()
    end)
end

--- Scans Craft frame (Enchanting / Beast Training)
function RR.Scanner:ScanCraft()
    if not (GetCraftDisplaySkillLine and GetNumCrafts) then return end

    local profName, currentRank, maxRank = GetCraftDisplaySkillLine()
    if not profName or profName == "UNKNOWN" then return end

    local engProf = (RR.DB and RR.DB:GetEnglishProfessionName(profName)) or profName
    self.currentProfession = engProf
    self.currentRank = currentRank or 0
    self.maxRank = maxRank or 0

    local charData = RR.Config:GetCurrentChar()
    if not charData then return end

    charData.professions[engProf] = charData.professions[engProf] or {
        current = currentRank,
        max = maxRank,
        known = {},
    }
    charData.professions[profName] = charData.professions[engProf]
    local knownTable = charData.professions[engProf].known
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
-- Automatically heals and merges split entries (e.g. "Verzauberkunst" vs "Enchanting")
-- @param charData table
-- @param profName string
-- @return table or nil
function RR.Scanner:GetProfessionData(charData, profName)
    if not (charData and charData.professions and profName) then return nil end

    local engKey = (RR.DB and RR.DB:GetEnglishProfessionName(profName)) or profName
    local locKey = (RR.DB and RR.DB:GetProfessionDisplayName(engKey)) or profName

    local engTable = charData.professions[engKey]
    local locTable = charData.professions[locKey]

    -- If both tables exist as separate instances, merge them into one canonical table
    if engTable and locTable and engTable ~= locTable then
        if type(locTable.known) == "table" and type(engTable.known) == "table" then
            for k, v in pairs(locTable.known) do
                engTable.known[k] = v
            end
        end
        engTable.current = math.max(engTable.current or 0, locTable.current or 0)
        engTable.max = math.max(engTable.max or 0, locTable.max or 0)
        charData.professions[locKey] = engTable
        return engTable
    end

    if engTable then return engTable end
    if locTable then
        charData.professions[engKey] = locTable
        return locTable
    end

    -- 3. Match across any other localized variation stored on this char
    if RR.DB then
        for pName, pData in pairs(charData.professions) do
            if RR.DB:GetEnglishProfessionName(pName) == engKey then
                charData.professions[engKey] = pData
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
