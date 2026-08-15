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
    ["DROPDOWN_SOURCE"] = "Source v",
    ["DROPDOWN_FACTION"] = "Faction v",
    ["DROPDOWN_ZONE"] = "Zone v",
    ["DROPDOWN_PHASE"] = "Phase v",

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
    ["ZONE_LAST"] = "Last Zone",
    ["CONTINENT_KALIMDOR"] = "Kalimdor",
    ["CONTINENT_EASTERN_KINGDOMS"] = "Eastern Kingdoms",
    ["CONTINENT_DUNGEONS"] = "Dungeons & Raids",

    -- Phase Filters
    ["PHASE_ALL"] = "All Phases",
    ["PHASE_1"] = "Phase 1: Molten Core & Onyxia",
    ["PHASE_2"] = "Phase 2: Dire Maul & World Bosses",
    ["PHASE_3"] = "Phase 3: Blackwing Lair (BWL)",
    ["PHASE_4"] = "Phase 4: Zul'Gurub (ZG)",
    ["PHASE_5"] = "Phase 5: Gates of Ahn'Qiraj (AQ)",
    ["PHASE_6"] = "Phase 6: Naxxramas & Scourge",

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

    -- Tooltip Strings for Header, Filters and Controls
    ["TOOLTIP_CLOSE_TITLE"] = "Close Window",
    ["TOOLTIP_CLOSE_DESC"] = "Closes the RecipeRadar overview.",
    ["TOOLTIP_SEARCH_TITLE"] = "Recipe Search",
    ["TOOLTIP_SEARCH_DESC"] = "Filters recipes by name. Type a keyword and press Enter or click Search.",
    ["TOOLTIP_SEARCH_BTN_TITLE"] = "Search",
    ["TOOLTIP_SEARCH_BTN_DESC"] = "Applies the search keyword filter to the recipe list.",
    ["TOOLTIP_MODE_MISSING_TITLE"] = "Missing Recipes",
    ["TOOLTIP_MODE_MISSING_DESC"] = "Shows only recipes that your current character has not learned yet.",
    ["TOOLTIP_MODE_KNOWN_TITLE"] = "Learned Recipes",
    ["TOOLTIP_MODE_KNOWN_DESC"] = "Shows only recipes that your character already knows.",
    ["TOOLTIP_MODE_ALL_TITLE"] = "All Recipes",
    ["TOOLTIP_MODE_ALL_DESC"] = "Shows all available recipes for this profession.",
    ["TOOLTIP_SOURCE_FILTER_TITLE"] = "Source Filter",
    ["TOOLTIP_SOURCE_FILTER_DESC"] = "Filters recipes by acquisition type (e.g. Trainer, Vendor, Drop, Quest).",
    ["TOOLTIP_FACTION_FILTER_TITLE"] = "Faction & Reputation Filter",
    ["TOOLTIP_FACTION_FILTER_DESC"] = "Filters recipes by faction or faction reputation requirement (Alliance, Horde, Neutral, Thorium Brotherhood, etc.).",
    ["TOOLTIP_SPEC_FILTER_TITLE"] = "Specialisation Filter",
    ["TOOLTIP_SPEC_FILTER_DESC"] = "Filters recipes by profession specialisation.",
    ["TOOLTIP_PHASE_FILTER_TITLE"] = "Phase Filter",
    ["TOOLTIP_PHASE_FILTER_DESC"] = "Filters recipes by the WoW Classic content phase they were introduced in.",
    ["TOOLTIP_REGION_FILTER_TITLE"] = "Region Filter",
    ["TOOLTIP_REGION_FILTER_DESC"] = "Filters recipes by continent or category (Kalimdor, Eastern Kingdoms, Dungeons, etc.).",
    ["TOOLTIP_ZONE_FILTER_TITLE"] = "Zone Filter",
    ["TOOLTIP_ZONE_FILTER_DESC"] = "Filters recipes to those available in a specific zone.",
    ["TOOLTIP_QUICK_ANY_TITLE"] = "Any Zone",
    ["TOOLTIP_QUICK_ANY_DESC"] = "Clears zone and region filters to show recipes from all zones worldwide.",
    ["TOOLTIP_QUICK_CURRENT_TITLE"] = "Current Zone",
    ["TOOLTIP_QUICK_CURRENT_DESC"] = "Filters recipes to your character's current zone.",
    ["TOOLTIP_QUICK_LAST_TITLE"] = "Last Selected Zone",
    ["TOOLTIP_QUICK_LAST_DESC"] = "Restores the last zone selected from the zone dropdown.",
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

        ["DROPDOWN_SOURCE"] = "Quelle v",
        ["DROPDOWN_FACTION"] = "Fraktion v",
        ["DROPDOWN_ZONE"] = "Zone v",
        ["DROPDOWN_PHASE"] = "Phase v",

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
        ["ZONE_LAST"] = "Letzte Zone",
        ["CONTINENT_KALIMDOR"] = "Kalimdor",
        ["CONTINENT_EASTERN_KINGDOMS"] = "Östliche Königreiche",
        ["CONTINENT_DUNGEONS"] = "Instanzen & Schlachtzüge",

        ["PHASE_ALL"] = "Alle Phasen",
        ["PHASE_1"] = "Phase 1: Geschmolzener Kern & Onyxia",
        ["PHASE_2"] = "Phase 2: Düsterbruch & Weltbosse",
        ["PHASE_3"] = "Phase 3: Pechschwingenhort (BWL)",
        ["PHASE_4"] = "Phase 4: Zul'Gurub (ZG)",
        ["PHASE_5"] = "Phase 5: Tore von Ahn'Qiraj (AQ)",
        ["PHASE_6"] = "Phase 6: Naxxramas & Geißelinvasion",

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

        -- Tooltip Strings for Header, Filters and Controls
        ["TOOLTIP_CLOSE_TITLE"] = "Fenster schließen",
        ["TOOLTIP_CLOSE_DESC"] = "Schließt die RecipeRadar-Übersicht.",
        ["TOOLTIP_SEARCH_TITLE"] = "Rezeptsuche",
        ["TOOLTIP_SEARCH_DESC"] = "Filtert Rezepte nach dem eingegebenen Namen. Gib ein Suchwort ein und drücke Enter oder klicke auf Suche.",
        ["TOOLTIP_SEARCH_BTN_TITLE"] = "Suche ausführen",
        ["TOOLTIP_SEARCH_BTN_DESC"] = "Wendet den Suchfilter auf die Rezeptliste an.",
        ["TOOLTIP_MODE_MISSING_TITLE"] = "Fehlende Rezepte",
        ["TOOLTIP_MODE_MISSING_DESC"] = "Zeigt nur Rezepte an, die dein aktueller Charakter noch nicht erlernt hat.",
        ["TOOLTIP_MODE_KNOWN_TITLE"] = "Erlernte Rezepte",
        ["TOOLTIP_MODE_KNOWN_DESC"] = "Zeigt nur Rezepte an, die dein Charakter bereits erlernt hat.",
        ["TOOLTIP_MODE_ALL_TITLE"] = "Alle Rezepte",
        ["TOOLTIP_MODE_ALL_DESC"] = "Zeigt alle verfügbaren Rezepte für diesen Beruf an.",
        ["TOOLTIP_SOURCE_FILTER_TITLE"] = "Quellen-Filter",
        ["TOOLTIP_SOURCE_FILTER_DESC"] = "Filtert nach der Herkunft des Rezepts (z. B. Lehrer, Händler, Drop oder Quest).",
        ["TOOLTIP_FACTION_FILTER_TITLE"] = "Fraktions- & Ruf-Filter",
        ["TOOLTIP_FACTION_FILTER_DESC"] = "Filtert Rezepte nach Fraktionszugehörigkeit oder Ruf-Voraussetzung (Allianz, Horde, Neutral, Thoriumbruderschaft etc.).",
        ["TOOLTIP_SPEC_FILTER_TITLE"] = "Spezialisierungs-Filter",
        ["TOOLTIP_SPEC_FILTER_DESC"] = "Filtert Rezepte nach Berufsspezialisierung (z. B. Drachenleder, Rüstungsschmied).",
        ["TOOLTIP_PHASE_FILTER_TITLE"] = "Phasen-Filter",
        ["TOOLTIP_PHASE_FILTER_DESC"] = "Filtert Rezepte nach der WoW Classic Content-Phase, in der sie hinzugefügt wurden.",
        ["TOOLTIP_REGION_FILTER_TITLE"] = "Regions-Filter",
        ["TOOLTIP_REGION_FILTER_DESC"] = "Filtert Rezepte nach Kontinent oder Kategorie (Kalimdor, Östliche Königreiche, Dungeons, etc.).",
        ["TOOLTIP_ZONE_FILTER_TITLE"] = "Zonen-Filter",
        ["TOOLTIP_ZONE_FILTER_DESC"] = "Wähle eine bestimmte Zone aus, um nur dort erhältliche Rezepte anzuzeigen.",
        ["TOOLTIP_QUICK_ANY_TITLE"] = "Jede Zone",
        ["TOOLTIP_QUICK_ANY_DESC"] = "Entfernt alle Zonenfilter und zeigt Rezepte weltweit aus allen Regionen an.",
        ["TOOLTIP_QUICK_CURRENT_TITLE"] = "Aktuelle Zone",
        ["TOOLTIP_QUICK_CURRENT_DESC"] = "Filtert sofort nach der Zone, in der sich dein Charakter gerade aufhält.",
        ["TOOLTIP_QUICK_LAST_TITLE"] = "Letzte gewählte Zone",
        ["TOOLTIP_QUICK_LAST_DESC"] = "Springt direkt zur zuletzt im Dropdown ausgewählten Zone zurück.",
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
