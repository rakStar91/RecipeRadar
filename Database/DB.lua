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
