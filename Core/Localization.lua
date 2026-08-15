-- ============================================================================
-- RecipeRadar: Core/Localization.lua
-- Multi-language dictionary (10 languages supported with German and English core)
-- ============================================================================

local RR = RecipeRadar
RR.L = {}

local locale = GetLocale()

local defaultStrings = {
    -- Navigation & Main Tabs
    ["ADDON_NAME"] = "RecipeRadar",
    ["RECIPES"] = "Recipes",
    ["ALTS"] = "Alts / Twinks",
    ["NPCS"] = "World & NPCs",
    ["OPTIONS"] = "Options",
    ["SEARCH_PLACEHOLDER"] = "Search recipes, items, NPCs...",

    -- Mode Filters
    ["MODE_MISSING"] = "Missing",
    ["MODE_KNOWN"] = "Known",
    ["MODE_ALL"] = "All",

    -- Dropdown Headers
    ["DROPDOWN_SOURCE"] = "Source ▾",
    ["DROPDOWN_FACTION"] = "Faction ▾",
    ["DROPDOWN_ZONE"] = "Zone / Region ▾",
    ["DROPDOWN_PHASE"] = "Phase ▾",

    -- Source Filters
    ["SOURCE_ALL"] = "All Sources",
    ["SOURCE_TRAINER"] = "Trainer",
    ["SOURCE_VENDOR"] = "Vendor",
    ["SOURCE_QUEST"] = "Quest",
    ["SOURCE_DROP"] = "Mob Drop",
    ["SOURCE_OBJECT"] = "Object / World",
    ["SOURCE_HOLIDAY"] = "Holiday / Seasonal",
    ["SOURCE_REPUTATION"] = "Reputation",

    -- Faction Filters
    ["FACTION_ALL"] = "All Factions",
    ["FACTION_ALLIANCE"] = "Alliance",
    ["FACTION_HORDE"] = "Horde",
    ["FACTION_NEUTRAL"] = "Neutral",

    -- Zone & Region Filters
    ["ZONE_ALL"] = "All Zones",
    ["ZONE_CURRENT"] = "Current Zone",
    ["CONTINENT_KALIMDOR"] = "Kalimdor",
    ["CONTINENT_EASTERN_KINGDOMS"] = "Eastern Kingdoms",
    ["CONTINENT_DUNGEONS"] = "Dungeons & Raids",

    -- Phase Filters
    ["PHASE_ALL"] = "All Phases",
    ["PHASE_1"] = "Phase 1",
    ["PHASE_2"] = "Phase 2",
    ["PHASE_3"] = "Phase 3",
    ["PHASE_4"] = "Phase 4",
    ["PHASE_5"] = "Phase 5",
    ["PHASE_6"] = "Phase 6",

    -- Detail Inspector Attribute Labels
    ["LABEL_NAME"] = "Name:",
    ["LABEL_PHASE"] = "Phase:",
    ["LABEL_NEEDS_SKILL"] = "Needs skill level:",
    ["LABEL_NEEDS_XP"] = "Needs XP level:",
    ["LABEL_NEEDS_REP"] = "Needs reputation:",
    ["LABEL_SPECIALISATION"] = "Specialisation:",
    ["LABEL_HOLIDAY"] = "Holiday:",
    ["LABEL_PRICE"] = "Price:",
    ["LABEL_LEARNED_FROM"] = "Learned from:",
    ["LABEL_OBTAINED_FROM"] = "Obtained from:",

    -- Source Suffixes
    ["TAG_TRAINER"] = "(Trainer)",
    ["TAG_VENDOR"] = "(Vendor)",
    ["TAG_QUEST"] = "(Quest)",
    ["TAG_DROP"] = "(Drop)",

    -- Progress, Reagents & Alts
    ["TOMTOM_WAYPOINT"] = "TomTom Waypoint",
    ["TOMTOM_ADDED"] = "Added waypoint to %s in %s (%s, %s)",
    ["TOMTOM_NOT_INSTALLED"] = "TomTom is not installed! Location: ",
    ["PROGRESS"] = "Progress",
    ["REAGENTS"] = "Required Materials",
    ["ACQUISITION"] = "Acquisition Source",
    ["ALTS_STATUS"] = "Realm Character Status",
    ["LEARNED"] = "Learned",
    ["REQUIRES_SKILL"] = "Requires %s (%d)",
    ["NO_RECIPES_FOUND"] = "No recipes found matching current filters.",
    ["NO_MATERIALS"] = "No materials data available.",
    ["SOURCE_DETAILS"] = "Source details",
    ["NO_REAGENTS"] = "No reagents required.",
    ["UNKNOWN_SOURCE"] = "Unknown Source",
    ["SELECT_A_RECIPE"] = "Select a Recipe",
    ["REQUIRES_PROFESSION"] = "Requires Profession",
    ["NO_ALTS_REALM"] = "No alts on this realm.",
    ["FREE"] = "Free",

    -- Tooltips & Slash Commands
    ["TOOLTIP_TOGGLE"] = "Left Click: Toggle RecipeRadar tracker",
    ["TOOLTIP_DRAG"] = "Right Drag: Move button position",
    ["TOOLTIP_MINIMAP_DRAG"] = "Left Drag: Move around minimap",
    ["LOADED_WELCOME"] = "loaded! Type /rr to open.",
    ["CMD_HELP_HEADER"] = "RecipeRadar Commands:",
    ["CMD_HELP_TOGGLE"] = " - Toggle RecipeRadar window",
    ["CMD_HELP_OPT"] = " - Open options",
    ["CMD_HELP_ALTS"] = " - Open alt character tracker",
    ["CMD_HELP_NPC"] = " - Open NPC / World explorer",
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

        ["DROPDOWN_SOURCE"] = "Quelle ▾",
        ["DROPDOWN_FACTION"] = "Fraktion ▾",
        ["DROPDOWN_ZONE"] = "Zone / Region ▾",
        ["DROPDOWN_PHASE"] = "Phase ▾",

        ["SOURCE_ALL"] = "Alle Quellen",
        ["SOURCE_TRAINER"] = "Lehrer",
        ["SOURCE_VENDOR"] = "Händler",
        ["SOURCE_QUEST"] = "Quest",
        ["SOURCE_DROP"] = "Gegner-Beute (Drop)",
        ["SOURCE_OBJECT"] = "Objekt / Welt",
        ["SOURCE_HOLIDAY"] = "Weltereignis",
        ["SOURCE_REPUTATION"] = "Ruf",

        ["FACTION_ALL"] = "Alle Fraktionen",
        ["FACTION_ALLIANCE"] = "Allianz",
        ["FACTION_HORDE"] = "Horde",
        ["FACTION_NEUTRAL"] = "Neutral",

        ["ZONE_ALL"] = "Alle Zonen",
        ["ZONE_CURRENT"] = "Aktuelle Zone",
        ["CONTINENT_KALIMDOR"] = "Kalimdor",
        ["CONTINENT_EASTERN_KINGDOMS"] = "Östliche Königreiche",
        ["CONTINENT_DUNGEONS"] = "Instanzen & Schlachtzüge",

        ["PHASE_ALL"] = "Alle Phasen",
        ["PHASE_1"] = "Phase 1",
        ["PHASE_2"] = "Phase 2",
        ["PHASE_3"] = "Phase 3",
        ["PHASE_4"] = "Phase 4",
        ["PHASE_5"] = "Phase 5",
        ["PHASE_6"] = "Phase 6",

        ["LABEL_NAME"] = "Name:",
        ["LABEL_PHASE"] = "Phase:",
        ["LABEL_NEEDS_SKILL"] = "Benötigter Skill:",
        ["LABEL_NEEDS_XP"] = "Spielerstufe:",
        ["LABEL_NEEDS_REP"] = "Ruf:",
        ["LABEL_SPECIALISATION"] = "Spezialisierung:",
        ["LABEL_HOLIDAY"] = "Weltereignis:",
        ["LABEL_PRICE"] = "Preis:",
        ["LABEL_LEARNED_FROM"] = "Erlernt von:",
        ["LABEL_OBTAINED_FROM"] = "Fundort:",

        ["TAG_TRAINER"] = "(Lehrer)",
        ["TAG_VENDOR"] = "(Händler)",
        ["TAG_QUEST"] = "(Quest)",
        ["TAG_DROP"] = "(Beute)",

        ["TOMTOM_WAYPOINT"] = "TomTom Wegpunkt",
        ["PROGRESS"] = "Fortschritt",
        ["REAGENTS"] = "Benötigte Materialien",
        ["ACQUISITION"] = "Bezugsquelle",
        ["ALTS_STATUS"] = "Twink Status (Dieser Realm)",
        ["LEARNED"] = "Gelernt",
        ["REQUIRES_SKILL"] = "Benötigt %s (%d)",
        ["NO_RECIPES_FOUND"] = "Keine Rezepte für die aktuellen Filter gefunden.",
        ["NO_MATERIALS"] = "Keine Materialdaten verfügbar.",
        ["SOURCE_DETAILS"] = "Fundort-Details",
        ["NO_REAGENTS"] = "Keine Reagenzien erforderlich.",
        ["UNKNOWN_SOURCE"] = "Unbekannte Quelle",
        ["SELECT_A_RECIPE"] = "Wähle ein Rezept aus",
        ["REQUIRES_PROFESSION"] = "Benötigt Beruf",
        ["NO_ALTS_REALM"] = "Keine Twinks auf diesem Realm.",
        ["FREE"] = "Kostenlos",

        ["TOOLTIP_TOGGLE"] = "Linksklick: RecipeRadar öffnen / schließen",
        ["TOOLTIP_DRAG"] = "Rechtsklick + Ziehen: Position verschieben",
        ["TOOLTIP_MINIMAP_DRAG"] = "Linksklick + Ziehen: Um Minimap bewegen",
        ["LOADED_WELCOME"] = "geladen! Gib /rr ein zum Öffnen.",
        ["CMD_HELP_HEADER"] = "RecipeRadar Befehle:",
        ["CMD_HELP_TOGGLE"] = " - RecipeRadar Fenster öffnen/schließen",
        ["CMD_HELP_OPT"] = " - Optionen öffnen",
        ["CMD_HELP_ALTS"] = " - Twink-Übersicht öffnen",
        ["CMD_HELP_NPC"] = " - NPC / Welt-Explorer öffnen",
    },
}

-- Metatable Fallback
setmetatable(RR.L, {
    __index = function(_, key)
        local t = translations[locale]
        if t and t[key] then
            return t[key]
        end
        return defaultStrings[key] or key
    end,
})
