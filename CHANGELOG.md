# Changelog

All notable changes to **RecipeRadar** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-08-16

### Initial Release

#### Core & Tracking
- **Comprehensive Recipe Database**: Complete tracking of recipes, plans, patterns, schematics, and formulas across all primary and secondary professions for World of Warcraft **Classic Era** and **The Burning Crusade** (TBC).
- **Interactive 3-Mode Filter**: Dedicated filtering to toggle between **[ Missing ]**, **[ Known ]**, and **[ All ]** recipes with distinct visual teal highlighting for skills already learned.
- **1-Click Filter Reset**: Instant **[ Reset Filters ]** button restoring search text and all active filters to default across all 10 supported languages.
- **Quick Zone Navigation Bar**: Instant 1-click filtering by **[ Any Zone ]**, **[ Current Zone ]**, and **[ Last Zone ]** with persistent character-specific memory across reloads and sessions.
- **Universal Multi-Select Filter Dropdowns**: Full in-place multi-selection across all 5 filter dropdowns (**Source**, **Faction**, **Reputation**, **Specialization**, and **Phase**) with dynamic button summaries and live list updates.
- **Strict Faction Exclusivity Filtering**:
  - Exact isolation of **Alliance-only** (Lion Crest) and **Horde-only** (Horde Crest) exclusive recipes without leaking shared trainer/neutral recipes.
  - Multi-selection support to combine your faction's exclusive recipes with shared/neutral recipes (`Horde + Neutral` or `Alliance + Neutral`).
- **Dedicated Reputation Filter**:
  - Curated reputation selection featuring authentic faction crests for Argent Dawn, Thorium Brotherhood, Timbermaw Hold, Zandalar Tribe, Hydraxian Waterlords, Darkmoon Faire, Cenarion Circle, and all TBC Outland factions.
- **Expansion & Content Phase Separation**:
  - **Classic Era**: Phases 1–6 (Molten Core through Naxxramas with the Scourge Crest).
  - **The Burning Crusade**: Visual section headers distinguishing **TBC Phases 1–5** (Master's Key, Fel Fire, Warglaive, Troll Head, Holy Inner Fire) from **Classic Era Phases 1–6** with complete expansion metadata isolation.
- **TomTom Waypoint Integration**: Clickable NPC names and coordinates for instant TomTom waypoint creation on the world map.
- **Alt Character Tracking**: Comprehensive tooltip integration displaying recipe learned status across all characters on the player's realm and faction for both recipe scrolls and crafted items.
- **Starter Profession Recipes**: Complete baseline item mappings for auto-learned starter recipes across all professions (Tailoring, Blacksmithing, Leatherworking, Alchemy, Engineering, Cooking, First Aid, Enchanting, Mining, Poisons).
- **Special Action & World Object Details**: Deep inspection and localized notes for world objects, chests, soil nodes, and special quest interactions.

#### Interface & Usability
- **Smart Draggable Launch Button**: Movable `RR` button attached next to the in-game tradeskill frame with custom drag position saving and automatic screen boundary clamping.
- **DragonflightUI & TradeSkill Frame Hooking**: Dynamic parent anchoring ensuring the `RR` button moves synchronously when profession windows are dragged or repositioned by UI overhaul addons (*DragonflightUI Revived*, *ElvUI*).
- **Interactive Recipe Item Hover**: Hovering over recipe names in the detail pane shows authentic item tooltips with stats, quality coloring, and profession requirements without placeholder texture glitches.
- **Mousewheel Scrollable Dropdown Popups**: Fluid hover-scrolling support on long dropdown lists (Zones, Continents, Specializations, Reputation).
- **Modern Dark UI Theme**: High-contrast dark theme with lossless TrueColor 3-slice TGA textures and circular gold minimap medallion.
- **Strict 10-Language Localization**: 100% synchronized native translations across UI and database lookup tables for English, German, French, Spanish, Mexican Spanish, Russian, Simplified Chinese, Traditional Chinese, Korean, and Portuguese via `Core/Localization.lua`.
- **Diagnostic Logging**: Integrated `/rr debug` slash command providing live chat logs for recipe selection, spell ID lookup, and crafted item resolution.
- **Purged Lightweight Asset Pipeline**: Complete removal of unused legacy textures, maintaining a lean footprint of only active high-definition assets.
- **Modular MVC Architecture**: Clean modular structure organized into `Core/`, `Database/`, `Engine/`, and `UI/` modules for maximum performance and stability.
