-- ============================================================================
-- RecipeRadar: Core/Localization.lua
-- Multi-language dictionary (10 languages)
-- ============================================================================

local RR = RecipeRadar
RR.L = {}

local locale = GetLocale()

local defaultStrings = {
    ["ADDON_NAME"] = "RecipeRadar",
    ["RECIPES"] = "Recipes",
    ["ALTS"] = "Alts / Twinks",
    ["NPCS"] = "World & NPCs",
    ["OPTIONS"] = "Options",
    ["SEARCH_PLACEHOLDER"] = "Search recipes, items, NPCs...",
    ["MODE_MISSING"] = "Missing",
    ["MODE_KNOWN"] = "Known",
    ["MODE_ALL"] = "All",
    ["ZONE_ANY"] = "Any Zone",
    ["ZONE_CURRENT"] = "Current Zone",
    ["ZONE_LAST"] = "Last Zone",
    ["SOURCE_ALL"] = "All Sources",
    ["SOURCE_TRAINER"] = "Trainer",
    ["SOURCE_VENDOR"] = "Vendor",
    ["SOURCE_QUEST"] = "Quest",
    ["SOURCE_DROP"] = "Mob Drop",
    ["SOURCE_OBJECT"] = "Object / World",
    ["SOURCE_HOLIDAY"] = "Holiday / Seasonal",
    ["TOMTOM_WAYPOINT"] = "TomTom Waypoint",
    ["TOMTOM_ADDED"] = "Added waypoint to %s in %s (%s, %s)",
    ["PROGRESS"] = "Progress",
    ["REAGENTS"] = "Required Materials",
    ["ACQUISITION"] = "Acquisition Source",
    ["ALTS_STATUS"] = "Realm Character Status",
    ["LEARNED"] = "Learned",
    ["REQUIRES_SKILL"] = "Requires %s (%d)",
    ["NO_RECIPES_FOUND"] = "No recipes found matching current filters.",
}

local translations = {
    deDE = {
        ["RECIPES"] = "Rezepte",
        ["ALTS"] = "Twinks / Alts",
        ["NPCS"] = "Welt & NPCs",
        ["OPTIONS"] = "Optionen",
        ["SEARCH_PLACEHOLDER"] = "Rezept, Item oder NPC suchen...",
        ["MODE_MISSING"] = "Fehlend",
        ["MODE_KNOWN"] = "Gelernt",
        ["MODE_ALL"] = "Alle",
        ["ZONE_ANY"] = "Alle Zonen",
        ["ZONE_CURRENT"] = "Aktuelle Zone",
        ["ZONE_LAST"] = "Letzte Zone",
        ["SOURCE_ALL"] = "Alle Quellen",
        ["SOURCE_TRAINER"] = "Lehrer",
        ["SOURCE_VENDOR"] = "Händler",
        ["SOURCE_QUEST"] = "Quest",
        ["SOURCE_DROP"] = "Gegner-Beute",
        ["SOURCE_OBJECT"] = "Objekt / Welt",
        ["SOURCE_HOLIDAY"] = "Weltereignis",
        ["TOMTOM_WAYPOINT"] = "TomTom Wegpunkt",
        ["PROGRESS"] = "Fortschritt",
        ["REAGENTS"] = "Benötigte Materialien",
        ["ACQUISITION"] = "Bezugsquelle",
        ["ALTS_STATUS"] = "Twink Status (Dieser Realm)",
        ["LEARNED"] = "Gelernt",
        ["REQUIRES_SKILL"] = "Benötigt %s (%d)",
        ["NO_RECIPES_FOUND"] = "Keine Rezepte für die aktuellen Filter gefunden.",
    },
    frFR = {
        ["RECIPES"] = "Recettes",
        ["ALTS"] = "Personnages",
        ["OPTIONS"] = "Options",
        ["MODE_MISSING"] = "Manquant",
        ["MODE_KNOWN"] = "Connu",
        ["MODE_ALL"] = "Tout",
        ["ZONE_ANY"] = "Toutes les zones",
        ["PROGRESS"] = "Progression",
        ["REAGENTS"] = "Composants requis",
        ["LEARNED"] = "Appris",
    },
    ruRU = {
        ["RECIPES"] = "Рецепты",
        ["ALTS"] = "Твинки",
        ["OPTIONS"] = "Настройки",
        ["MODE_MISSING"] = "Не изучено",
        ["MODE_KNOWN"] = "Изучено",
        ["MODE_ALL"] = "Все",
        ["ZONE_ANY"] = "Любая зона",
        ["PROGRESS"] = "Прогресс",
        ["REAGENTS"] = "Реагенты",
        ["LEARNED"] = "Изучено",
    },
    zhCN = {
        ["RECIPES"] = "配方",
        ["ALTS"] = "小号",
        ["OPTIONS"] = "选项",
        ["MODE_MISSING"] = "未学习",
        ["MODE_KNOWN"] = "已学习",
        ["MODE_ALL"] = "全部",
        ["ZONE_ANY"] = "任意区域",
        ["PROGRESS"] = "进度",
        ["REAGENTS"] = "所需材料",
        ["LEARNED"] = "已学习",
    },
    zhTW = {
        ["RECIPES"] = "配方",
        ["ALTS"] = "分身",
        ["OPTIONS"] = "選項",
        ["MODE_MISSING"] = "未學習",
        ["MODE_KNOWN"] = "已學習",
        ["MODE_ALL"] = "全部",
        ["ZONE_ANY"] = "所有區域",
        ["PROGRESS"] = "進度",
        ["REAGENTS"] = "所需材料",
        ["LEARNED"] = "已學習",
    },
}

-- Metatable fallback to default English strings
local currentLocaleStrings = translations[locale] or {}
setmetatable(RR.L, {
    __index = function(_, key)
        return currentLocaleStrings[key] or defaultStrings[key] or key
    end
})
