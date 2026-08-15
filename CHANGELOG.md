# Changelog

All notable changes to **RecipeRadar** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-08-15

### Initial Release

#### Core & Tracking
- **Comprehensive Recipe Database**: Complete tracking of recipes, plans, patterns, schematics, and formulas across all primary and secondary professions for World of Warcraft **Classic Era** and **The Burning Crusade** (TBC).
- **Interactive 3-Mode Filter**: Dedicated filtering to toggle between **[ Missing ]**, **[ Known ]**, and **[ All ]** recipes with distinct visual teal highlighting for skills already learned.
- **Quick Zone Navigation Bar**: Instant 1-click filtering by **[ Any Zone ]**, **[ Current Zone ]**, and **[ Last Zone ]** with persistent character-specific memory across reloads and sessions.
- **Multi-Select Source Filters**: Flexible multi-select dropdown with intuitive icons (including loot pouch for mob drops) to filter recipes by acquisition source (Vendors, Trainers, Quests, Mob Drops, World Objects, and Seasonal Holidays).
- **Faction & Reputation System**: Authentic Alliance Lion, Horde Crest, and dual Neutral Crest indicators for faction-restricted and neutral/multi-faction recipes, plus dedicated reputation dropdown filters with PVP banner icons.
- **Phase 1–6 Filtering**: Clean raid phase filters featuring the Scourge Crest (`Spell_Shadow_DeathPact`) for Phase 6 (Naxxramas).
- **TomTom Waypoint Integration**: Clickable NPC names and coordinates for instant TomTom waypoint creation on the world map.
- **Alt Character Tracking**: Comprehensive tooltip integration displaying recipe learned status across all characters on the player's realm and faction for both recipe scrolls and crafted items.
- **Starter Profession Recipes**: Complete baseline item mappings for auto-learned starter recipes across all 10 professions (Tailoring, Blacksmithing, Leatherworking, Alchemy, Engineering, Cooking, First Aid, Enchanting, Mining, Poisons).
- **Special Action & World Object Details**: Deep inspection and localized notes for world objects, chests, soil nodes, and special quest interactions.

#### Interface & Usability
- **Smart Draggable Launch Button**: Movable `RR` button attached next to the in-game tradeskill frame with custom drag position saving and automatic screen boundary clamping.
- **DragonflightUI & TradeSkill Frame Hooking**: Dynamic parent anchoring ensuring the `RR` button moves synchronously when profession windows are dragged or repositioned by UI overhaul addons (*DragonflightUI Revived*, *ElvUI*).
- **Interactive Recipe Item Hover**: Hovering over recipe names in the detail pane shows authentic item tooltips with stats, quality coloring, and profession requirements without placeholder texture glitches.
- **Mousewheel Scrollable Dropdown Popups**: Fluid hover-scrolling support on long dropdown lists (Zones, Continents, Specializations).
- **Modern Dark UI Theme**: High-contrast dark theme with lossless TrueColor 3-slice TGA textures and circular gold minimap medallion.
- **Strict 10-Language Localization**: 100% synchronized native translations across UI and database lookup tables for English, German, French, Spanish, Mexican Spanish, Russian, Simplified Chinese, Traditional Chinese, Korean, and Portuguese.
- **Diagnostic Logging**: Integrated `/rr debug` slash command providing live chat logs for recipe selection, spell ID lookup, and crafted item resolution.
- **Purged Lightweight Asset Pipeline**: Complete removal of unused legacy textures, maintaining a lean footprint of only active high-definition assets.
- **Modular MVC Architecture**: Clean modular structure organized into `Core/`, `Database/`, `Engine/`, and `UI/` modules for maximum performance and stability.
