-- ============================================================================
-- RecipeRadar: Core/Constants.lua
-- Global namespace and core constants
-- ============================================================================

RecipeRadar = RecipeRadar or {}
local RR = RecipeRadar

-- Global Raw Game Database Table Container
RR_DATA = RR_DATA or {
    continents = {},
    currencies = {},
    expansions = {},
    factions = {},
    holidays = {},
    items = {},
    levels = {},
    npcs = {},
    objects = {},
    profession_ranks = {},
    professions = {},
    quests = {},
    reputations = {},
    reputation_levels = {},
    skills = {},
    special_actions = {},
    specialisations = {},
    zones = {},
}

RR.NAME = "RecipeRadar"
RR.VERSION = "1.2.0"
RR.AUTHOR = "rakStar"

-- Addon path
local addonName = ...
RR.ADDON_PATH = "Interface\\AddOns\\" .. (addonName or "RecipeRadar")

-- Origin markers of the recipe list: the game's own icons, read from the client by file id, so no copy of the artwork
-- ships with the addon. "crop" is the emblem inside the texture in pixels (left, right, top, bottom). The game has no
-- emblem of its own for Classic and The Burning Crusade, so both use the WoW icon of the friends list; The Burning
-- Crusade has it desaturated and tinted green.
--   classic: Interface\FriendsFrame\Battlenet-WoWicon (374212, 32x32)
--   tbc:     the same icon, desaturated and tinted green
--   forever: Interface\Glues\Common\Glues-WoW-ForeverLogo-Infinity (8363869, 512x256)
RR.ORIGIN_ICON_SIZE = 14
RR.ORIGIN_ICONS = {
    classic = { file = 374212, texW = 32, texH = 32, crop = { 0, 32, 0, 32 }, label = "ORIGIN_CLASSIC" },
    tbc = { file = 374212, texW = 32, texH = 32, crop = { 0, 32, 0, 32 }, label = "ORIGIN_TBC",
        desaturate = true, tint = { 0.55, 1, 0.35 } },
    forever = { file = 8363869, texW = 512, texH = 256, crop = { 43, 299, 0, 256 }, label = "FOREVER_NEW_RECIPE" },
}
for _, icon in pairs(RR.ORIGIN_ICONS) do
    local c = icon.crop
    icon.texCoord = { c[1] / icon.texW, c[2] / icon.texW, c[3] / icon.texH, c[4] / icon.texH }
    -- the escape cannot desaturate, so a tinted icon is only approximated in tooltips and the detail pane
    local color = ""
    if icon.tint then
        local r, g, b = unpack(icon.tint)
        color = string.format(":%d:%d:%d", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
    icon.escape = string.format("|T%d:%d:%d:0:0:%d:%d:%d:%d:%d:%d%s|t", icon.file, RR.ORIGIN_ICON_SIZE,
        RR.ORIGIN_ICON_SIZE, icon.texW, icon.texH, c[1], c[2], c[3], c[4], color)
end
RR.ORIGIN_COLUMN_WIDTH = RR.ORIGIN_ICON_SIZE

-- Profession IDs and English Names
RR.PROFESSIONS = {
    ALCHEMY = "Alchemy",
    BLACKSMITHING = "Blacksmithing",
    COOKING = "Cooking",
    ENCHANTING = "Enchanting",
    ENGINEERING = "Engineering",
    FIRST_AID = "First Aid",
    FISHING = "Fishing",
    HERBALISM = "Herbalism",
    JEWELCRAFTING = "Jewelcrafting",
    LEATHERWORKING = "Leatherworking",
    MINING = "Mining",
    POISONS = "Poisons",
    SKINNING = "Skinning",
    TAILORING = "Tailoring",
}

-- Standard Blizzard Profession Texture Icons
RR.PROFESSION_ICONS = {
    [RR.PROFESSIONS.ALCHEMY]        = "Interface\\Icons\\Trade_Alchemy",
    [RR.PROFESSIONS.BLACKSMITHING]  = "Interface\\Icons\\Trade_BlackSmithing",
    [RR.PROFESSIONS.COOKING]        = "Interface\\Icons\\INV_Misc_Food_15",
    [RR.PROFESSIONS.ENCHANTING]     = "Interface\\Icons\\Trade_Engraving",
    [RR.PROFESSIONS.ENGINEERING]    = "Interface\\Icons\\Trade_Engineering",
    [RR.PROFESSIONS.FIRST_AID]      = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    [RR.PROFESSIONS.FISHING]        = "Interface\\Icons\\Trade_Fishing",
    [RR.PROFESSIONS.HERBALISM]      = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    [RR.PROFESSIONS.JEWELCRAFTING]  = "Interface\\Icons\\INV_Misc_Gem_01",
    [RR.PROFESSIONS.LEATHERWORKING] = "Interface\\Icons\\Trade_LeatherWorking",
    [RR.PROFESSIONS.MINING]         = "Interface\\Icons\\Trade_Mining",
    [RR.PROFESSIONS.POISONS]        = "Interface\\Icons\\Trade_BrewPoison",
    [RR.PROFESSIONS.SKINNING]       = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    [RR.PROFESSIONS.TAILORING]      = "Interface\\Icons\\Trade_Tailoring",
}

-- Acquisition Source Types
RR.SOURCE_TYPES = {
    TRAINER = 1,
    VENDOR = 2,
    QUEST = 3,
    DROP = 4,
    OBJECT = 5,
    HOLIDAY = 6,
    CUSTOM = 7,
}

-- Faction Bitmasks / Strings
RR.FACTIONS = {
    ALLIANCE = "Alliance",
    HORDE = "Horde",
    NEUTRAL = "Neutral",
}

-- Quality Colors (Standard WoW Hex)
RR.QUALITY_COLORS = {
    POOR = "9d9d9d",
    COMMON = "ffffff",
    UNCOMMON = "1eff00",
    RARE = "0070dd",
    EPIC = "a335ee",
    LEGENDARY = "ff8000",
}

-- UI Theme Colors
RR.COLORS = {
    TITLE = "|cfff7d070",
    GOLD = "|cffffd100",
    TEAL = "|cff2dd4bf",
    WHITE = "|cffffffff",
    GREY = "|cff9ca3af",
    GREEN = "|cff4ade80",
    RED = "|cfff87171",
    BLUE = "|cff60a5fa",
    ORANGE = "|cfff59e0b",
}
