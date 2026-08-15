-- ============================================================================
-- RecipeRadar: Database/DB.lua
-- Central database query engine (Classic Era + TBC)
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

        -- Build O(1) lookup maps
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
    end
end

function RR.DB:GetEnglishProfessionName(profName)
    if not profName then return "Tailoring" end
    if self.Raw.skills and self.Raw.skills[profName] then return profName end

    -- Check RR_DATA["professions"]
    if self.Raw.professions then
        for engName, pData in pairs(self.Raw.professions) do
            if type(pData) == "table" and pData.name then
                for _, locName in pairs(pData.name) do
                    if locName == profName then
                        return engName
                    end
                end
            end
        end
    end

    -- Explicit dictionary fallback
    local map = {
        ["Alchemie"] = "Alchemy",
        ["Alchimie"] = "Alchemy",
        ["Schmiedekunst"] = "Blacksmithing",
        ["Kochkunst"] = "Cooking",
        ["Verzauberkunst"] = "Enchanting",
        ["Ingenieurskunst"] = "Engineering",
        ["Erste Hilfe"] = "First Aid",
        ["Angeln"] = "Fishing",
        ["Kräuterkunde"] = "Herbalism",
        ["Lederverarbeitung"] = "Leatherworking",
        ["Bergbau"] = "Mining",
        ["Gifte"] = "Poisons",
        ["Kürschnerei"] = "Skinning",
        ["Schneiderei"] = "Tailoring",
        ["Juwelenschleifen"] = "Jewelcrafting",
    }
    return map[profName] or profName
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
