-- ============================================================================
-- RecipeRadar: Core/Constants.lua
-- Global namespace and core constants
-- ============================================================================

RecipeRadar = RecipeRadar or {}
local RR = RecipeRadar

RR.NAME = "RecipeRadar"
RR.VERSION = "1.0.0"
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
