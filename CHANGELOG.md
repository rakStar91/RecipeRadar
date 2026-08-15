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
- **Multi-Select Source Filters**: Flexible multi-select dropdown to filter recipes by acquisition source (Vendors, Trainers, Quests, Mob Drops, World Objects, and Seasonal Holidays).
- **Faction Crest Indicators**: Distinct Alliance Lion and Horde Crest badges displayed on recipe items for faction-restricted skills.
- **TomTom Waypoint Integration**: Clickable NPC names and coordinates for instant TomTom waypoint creation on the world map.
- **Alt Character Tracking**: Comprehensive tooltip integration displaying recipe learned status across all characters on the player's realm and faction.

#### Interface & Usability
- **Smart Draggable Launch Button**: Movable `RR` button attached next to the in-game tradeskill frame with custom drag position saving and automatic screen boundary clamping.
- **Full Reskin Compatibility**: Adaptive anchoring supporting UI overhaul addons (e.g. *DragonflightUI*, *ElvUI*) without overlap or clipping.
- **In-Game Database Explorers**: Full-featured in-game browsers to explore Characters, Accounts, Global Database items, and NPCs (`/rr`, `/rr alts`, `/rr search`, `/rr npc`).
- **Modern Dark UI Theme**: High-contrast dark theme with lossless TrueColor TGA textures and circular gold minimap medallion.
- **Full 10-Language Localization**: Native translations for English, German, French, Russian, Korean, Simplified Chinese, Traditional Chinese, Spanish, Mexican Spanish, and Portuguese.
- **Modular MVC Architecture**: Clean modular structure organized into `Core/`, `Database/`, `Engine/`, and `GUI/` modules for maximum performance and stability.
