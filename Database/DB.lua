-- ============================================================================
-- RecipeRadar: Database/DB.lua
-- Central database query engine (Classic Era + TBC)
-- Fully ID-driven & dynamic Blizzard API localization across all languages
-- ============================================================================

local RR = RecipeRadar
RR.DB = {}

RR.DB.Raw = {
    skills = {},
    items = {},
    npcs = {},
    quests = {},
    objects = {},
    zones = {},
    factions = {},
    professions = {},
}

RR.DB.npcMap = {}
RR.DB.zoneMap = {}
RR.DB.questMap = {}
RR.DB.itemMap = {}
RR.DB.profNameToKey = {}

-- Official Blizzard Profession Spell-IDs (Universal across all locales)
local LOCALE_TO_DB_KEY = {
    ["deDE"] = "German",
    ["enUS"] = "English",
    ["enGB"] = "English",
    ["frFR"] = "French",
    ["esES"] = "Spanish",
    ["esMX"] = "Mexican",
    ["ruRU"] = "Russian",
    ["zhCN"] = "Chinese",
    ["zhTW"] = "Taiwanese",
    ["koKR"] = "Korean",
    ["ptBR"] = "Portuguese",
}

function RR.DB:GetLocalizedText(nameTable)
    if not nameTable then return "" end
    if type(nameTable) == "string" then return nameTable end
    local locale = GetLocale()
    local dbKey = LOCALE_TO_DB_KEY[locale] or "English"
    return nameTable[dbKey] or nameTable[locale] or nameTable["German"] or nameTable["English"] or ""
end

local PROFESSION_SPELL_IDS = {
    ["Alchemy"] = 2259,
    ["Blacksmithing"] = 2018,
    ["Cooking"] = 2550,
    ["Enchanting"] = 7411,
    ["Engineering"] = 4036,
    ["First Aid"] = 3273,
    ["Fishing"] = 7620,
    ["Herbalism"] = 2366,
    ["Jewelcrafting"] = 25229,
    ["Leatherworking"] = 2108,
    ["Mining"] = 2575,
    ["Poisons"] = 2842,
    ["Skinning"] = 8613,
    ["Tailoring"] = 3908,
}

function RR.DB:Initialize()
    if RR_DATA then
        self.Raw.skills = RR_DATA["skills"] or {}
        self.Raw.items = RR_DATA["items"] or {}
        self.Raw.npcs = RR_DATA["npcs"] or {}
        self.Raw.quests = RR_DATA["quests"] or {}
        self.Raw.objects = RR_DATA["objects"] or {}
        self.Raw.zones = RR_DATA["zones"] or {}
        self.Raw.factions = RR_DATA["factions"] or {}
        self.Raw.professions = RR_DATA["professions"] or {}

        -- 1. Build O(1) Lookup Maps
        self.npcMap = {}
        for _, npc in pairs(self.Raw.npcs) do
            if type(npc) == "table" and npc.id then
                self.npcMap[npc.id] = npc
            end
        end

        self.zoneMap = {}
        for _, z in pairs(self.Raw.zones) do
            if type(z) == "table" and z.id then
                self.zoneMap[z.id] = z
            end
        end

        self.questMap = {}
        for _, q in pairs(self.Raw.quests) do
            if type(q) == "table" and q.id then
                self.questMap[q.id] = q
            end
        end

        self.itemMap = {}
        for prof, list in pairs(self.Raw.items) do
            if type(list) == "table" then
                for _, item in pairs(list) do
                    if type(item) == "table" and item.id then
                        self.itemMap[item.id] = item
                    end
                end
            end
        end

        -- 2. Build Dynamic Multilingual Profession Name Resolver via Blizzard API & DB
        self.profNameToKey = {}
        
        -- Query Blizzard Spell API for the active client language
        for engKey, spellId in pairs(PROFESSION_SPELL_IDS) do
            local spellName = nil
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellId)
                spellName = info and info.name
            elseif GetSpellInfo then
                spellName = GetSpellInfo(spellId)
            end

            if spellName then
                self.profNameToKey[spellName] = engKey
            end
            self.profNameToKey[engKey] = engKey
        end

        -- Also index all 10 language dictionaries from Database/Classic/Professions.lua
        if self.Raw.professions then
            for engName, pData in pairs(self.Raw.professions) do
                if type(pData) == "table" and pData.name then
                    for _, locName in pairs(pData.name) do
                        if locName and locName ~= "" then
                            self.profNameToKey[locName] = engName
                        end
                    end
                end
            end
        end
    end
end

function RR.DB:GetEnglishProfessionName(profName)
    if not profName then return "Tailoring" end
    return self.profNameToKey[profName] or profName
end

function RR.DB:GetRecipesForProfession(professionName)
    local engName = self:GetEnglishProfessionName(professionName)
    return (self.Raw.skills and self.Raw.skills[engName]) or {}
end

function RR.DB:GetNPC(npcId)
    if not npcId then return nil end
    return self.npcMap and self.npcMap[npcId]
end

function RR.DB:GetQuest(questId)
    if not questId then return nil end
    return self.questMap and self.questMap[questId]
end

function RR.DB:GetItem(itemId)
    if not itemId then return nil end
    return self.itemMap and self.itemMap[itemId]
end

function RR.DB:GetZoneName(zoneId)
    if not zoneId then return "Unknown Zone" end
    local z = self.zoneMap and self.zoneMap[zoneId]
    if z and z.name then
        local locale = GetLocale()
        return z.name[locale] or z.name["German"] or z.name["English"] or "Unknown Zone"
    end
    return "Unknown Zone"
end

--- Returns comprehensive acquisition metadata for a recipe
function RR.DB:GetRecipeAcquisitionMetadata(recipe)
    local meta = {
        zones = {},
        continents = {},
        sourceTypes = {},
        factions = {},
        phase = recipe.phase or 1,
        reputationFactionId = nil,
    }

    local function addNPC(npcId, sType)
        local npc = self:GetNPC(npcId)
        if npc then
            local zId = (npc.location and npc.location.zone_id) or npc.zone_id
            if zId then
                meta.zones[zId] = true
                local z = self.zoneMap and self.zoneMap[zId]
                if z and z.continent_id then
                    meta.continents[z.continent_id] = true
                end
            end
            if sType then meta.sourceTypes[sType] = true end
            if npc.faction then meta.factions[npc.faction] = true end
        end
    end

    local function addQuest(qId)
        local q = self:GetQuest(qId)
        if q then
            if q.zone_id then
                meta.zones[q.zone_id] = true
                local z = self.zoneMap and self.zoneMap[q.zone_id]
                if z and z.continent_id then
                    meta.continents[z.continent_id] = true
                end
            end
            meta.sourceTypes["quest"] = true
            if q.givers and q.givers.npcs then
                for _, nId in ipairs(q.givers.npcs) do addNPC(nId, "quest") end
            end
        end
    end

    -- Direct trainers
    local tr = recipe.trainers and (recipe.trainers.sources or (type(recipe.trainers) == "table" and recipe.trainers))
    if tr and type(tr) == "table" then
        for _, id in ipairs(tr) do addNPC(id, "trainer") end
    end

    -- Direct vendors
    local vn = recipe.vendors and (recipe.vendors.sources or (type(recipe.vendors) == "table" and recipe.vendors))
    if vn and type(vn) == "table" then
        for _, id in ipairs(vn) do addNPC(id, "vendor") end
    end

    -- Direct quests
    local qs = recipe.quests and (recipe.quests.sources or (type(recipe.quests) == "table" and recipe.quests))
    if qs and type(qs) == "table" then
        for _, id in ipairs(qs) do addQuest(id) end
    end

    -- Direct drops
    local dr = recipe.drops and (recipe.drops.sources or (type(recipe.drops) == "table" and recipe.drops))
    if dr and type(dr) == "table" then
        for _, id in ipairs(dr) do addNPC(id, "drop") end
    end

    -- Items (Teaching items)
    if recipe.items and type(recipe.items) == "table" then
        for _, itemId in ipairs(recipe.items) do
            local itm = self:GetItem(itemId)
            if itm then
                if itm.phase then meta.phase = itm.phase end
                if itm.vendors then
                    local iv = itm.vendors.sources or itm.vendors
                    if type(iv) == "table" then
                        for _, id in ipairs(iv) do addNPC(id, "vendor") end
                    end
                end
                if itm.quests then
                    local iq = itm.quests.sources or itm.quests
                    if type(iq) == "table" then
                        for _, id in ipairs(iq) do addQuest(id) end
                    end
                end
                if itm.drops then
                    local idr = itm.drops.sources or itm.drops
                    if type(idr) == "table" then
                        for _, id in ipairs(idr) do addNPC(id, "drop") end
                    end
                end
                if itm.reputation then
                    meta.sourceTypes["reputation"] = true
                    meta.reputationFactionId = itm.reputation.faction_id
                end
                if itm.holiday then meta.sourceTypes["holiday"] = true end
            end
        end
    end

    if recipe.reputation then
        meta.sourceTypes["reputation"] = true
        meta.reputationFactionId = recipe.reputation.faction_id
    end
    if recipe.holiday then meta.sourceTypes["holiday"] = true end

    return meta
end

--- Returns current player zone ID in Classic DB
function RR.DB:GetCurrentZoneId()
    local zName = GetRealZoneText() or ""
    if zName == "" then return nil end
    local locale = GetLocale()

    if self.zoneMap then
        for id, z in pairs(self.zoneMap) do
            if z.name then
                if z.name[locale] == zName or z.name["German"] == zName or z.name["English"] == zName then
                    return id
                end
            end
        end
    end
    return nil
end
