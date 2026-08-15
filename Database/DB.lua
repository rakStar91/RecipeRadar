-- ============================================================================
-- RecipeRadar: Database/DB.lua
-- Central database query engine (Classic Era + TBC)
-- ============================================================================

local RR = RecipeRadar
RR.DB = {}

-- Storage for raw database tables
RR.DB.Raw = {
    skills = {},
    items = {},
    npcs = {},
    quests = {},
    objects = {},
    zones = {},
    factions = {},
}

--- Initializes and links raw database tables
function RR.DB:Initialize()
    -- Link Classic data globals if declared
    if RR_DATA then
        self.Raw.skills = RR_DATA["skills"] or {}
        self.Raw.items = RR_DATA["items"] or {}
        self.Raw.npcs = RR_DATA["npcs"] or {}
        self.Raw.quests = RR_DATA["quests"] or {}
        self.Raw.objects = RR_DATA["objects"] or {}
        self.Raw.zones = RR_DATA["zones"] or {}
        self.Raw.factions = RR_DATA["factions"] or {}
    end
end

--- Retrieves all recipes for a specific profession
-- @param professionName string: Name of the profession (e.g. "Tailoring")
-- @return table list of recipes
function RR.DB:GetRecipesForProfession(professionName)
    if not professionName then return {} end
    return (self.Raw.skills and self.Raw.skills[professionName]) or {}
end

--- Looks up detailed NPC info by NPC ID
-- @param npcId number
-- @return table NPC info (name, zone, coords, faction)
function RR.DB:GetNPC(npcId)
    if not (npcId and self.Raw.npcs) then return nil end
    return self.Raw.npcs[npcId]
end

--- Looks up detailed Quest info by Quest ID
-- @param questId number
-- @return table Quest info
function RR.DB:GetQuest(questId)
    if not (questId and self.Raw.quests) then return nil end
    return self.Raw.quests[questId]
end

--- Looks up Item info by Item ID
-- @param itemId number
-- @return table Item info
function RR.DB:GetItem(itemId)
    if not (itemId and self.Raw.items) then return nil end
    return self.Raw.items[itemId]
end

--- Looks up Zone Name by Zone ID
-- @param zoneId number
-- @return string Zone name
function RR.DB:GetZoneName(zoneId)
    if not (zoneId and self.Raw.zones) then return "Unknown Zone" end
    local z = self.Raw.zones[zoneId]
    if z and z.name then
        local locale = GetLocale()
        return z.name[locale] or z.name["English"] or "Unknown Zone"
    end
    return "Unknown Zone"
end
