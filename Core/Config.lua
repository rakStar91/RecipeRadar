-- ============================================================================
-- RecipeRadar: Core/Config.lua
-- SavedVariables database management and configuration
-- ============================================================================

local RR = RecipeRadar
RR.Config = {}

local DEFAULT_CONFIG = {
    profile = {
        autoShow = false,
        tooltipAlts = true,
        minimap = { hide = false, angle = 220 },
        buttonPosition = { x = 0, y = 0, isCustom = false },
        filter = {
            mode = "missing",       -- "missing", "known", "all"
            zoneMode = "any",       -- "any", "current", "last"
            sources = {
                trainer = true,
                vendor = true,
                quest = true,
                drop = true,
                object = true,
                holiday = true,
            },
        },
    },
    characters = {},
}

function RR.Config:Initialize()
    if not RecipeRadarDB then
        RecipeRadarDB = {}
    end

    -- Merge default configuration
    for k, v in pairs(DEFAULT_CONFIG) do
        if RecipeRadarDB[k] == nil then
            RecipeRadarDB[k] = CopyTable and CopyTable(v) or v
        end
    end
    for k, v in pairs(DEFAULT_CONFIG.profile) do
        if RecipeRadarDB.profile[k] == nil then
            RecipeRadarDB.profile[k] = v
        end
    end
    for k, v in pairs(DEFAULT_CONFIG.profile.filter) do
        if RecipeRadarDB.profile.filter[k] == nil then
            RecipeRadarDB.profile.filter[k] = v
        end
    end

    -- Ensure current character entry exists
    local realm = GetRealmName() or "UnknownRealm"
    local charName = UnitName("player") or "UnknownChar"
    local _, englishClass = UnitClass("player")
    local faction = UnitFactionGroup("player") or "Neutral"

    RecipeRadarDB.characters[realm] = RecipeRadarDB.characters[realm] or {}
    RecipeRadarDB.characters[realm][charName] = RecipeRadarDB.characters[realm][charName] or {
        faction = faction,
        class = englishClass,
        lastZone = GetRealZoneText() or "",
        professions = {},
    }

    self.db = RecipeRadarDB
    self.char = RecipeRadarDB.characters[realm][charName]
end

function RR.Config:GetProfile()
    return self.db and self.db.profile or DEFAULT_CONFIG.profile
end

function RR.Config:GetCurrentChar()
    return self.char
end

function RR.Config:GetFilterSetting(key)
    local profile = self:GetProfile()
    return profile.filter[key]
end

function RR.Config:SetFilterSetting(key, value)
    local profile = self:GetProfile()
    profile.filter[key] = value
end

function RR.Config:SaveLastZone(zoneName)
    if self.char and zoneName and zoneName ~= "" then
        self.char.lastZone = zoneName
    end
end

function RR.Config:GetLastZone()
    return (self.char and self.char.lastZone) or ""
end
function RR.Config:SaveLastZoneForProfession(profName, zoneData)
    if not profName or profName == "" then return end
    local charData = self:GetCurrentChar()
    if charData then
        charData.lastProfZones = charData.lastProfZones or {}
        charData.lastProfZones[profName] = zoneData
    end
end

function RR.Config:GetLastZoneForProfession(profName)
    if not profName or profName == "" then return nil end
    local charData = self:GetCurrentChar()
    if charData and charData.lastProfZones then
        return charData.lastProfZones[profName]
    end
    return nil
end

function RR.Config:GetButtonOffset()
    local profile = self:GetProfile()
    return profile and profile.buttonOffset
end

function RR.Config:SaveButtonOffset(x, y)
    local profile = self:GetProfile()
    if profile then
        profile.buttonOffset = { x = x, y = y }
    end
end

function RR.Config:ClearButtonOffset()
    local profile = self:GetProfile()
    if profile then
        profile.buttonOffset = nil
    end
end
