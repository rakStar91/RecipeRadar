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
RR.VERSION = "1.1.0"
RR.AUTHOR = "rakStar"

-- Addon path
local addonName = ...
RR.ADDON_PATH = "Interface\\AddOns\\" .. (addonName or "RecipeRadar")

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
