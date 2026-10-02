# Changelog

All notable changes to **RecipeRadar** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-10-03

### Added
- **Standalone Settings & Options Window**: Brand-new dedicated configuration interface accessible via `/rr config`, `/rr options`, or by right-clicking the minimap button.
- **Character & Alt Management**:
  - Full management of all tracked characters on the current realm.
  - Toggle individual character visibility in recipe tooltips to mute inactive alts and keep item tooltips clean.
  - Permanent character removal with a safe confirmation dialog to delete retired alts from the database.
  - Interactive profession badges displaying skill rank, gold max-rank indicators, and rich hover tooltips with learned vs. missing recipe statistics.
- **Direct Right-Click Settings Access**: Right-clicking the circular minimap button or the profession attach button now opens the Settings window directly without intermediate menus.
- **Interactive About & Commands Overview**: Dedicated information tab displaying addon version, author credits, 1-click copy boxes with official brand icons for GitHub, CurseForge, and Ko-fi links, and a comprehensive chat commands reference.
- **Universal Multi-Language Localization**: Full native translation of all settings, alt controls, and recipe statistics across all 10 official WoW client languages (`enUS`, `deDE`, `frFR`, `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `koKR`, `ptBR`).

### Changed
- **Streamlined Minimap Controls**: Removed redundant context dropdown and chat notice spam when toggling the minimap button. Button visibility is now cleanly configured inside the Interface settings tab.
- **Neutral Vendor Accessibility**: Correctly classifies recipes sold by neutral vendors (such as traveling Goblin merchants) as accessible to both Alliance and Horde.

### Fixed
- **Recipe Counter Accuracy & Craft Sync**: Fixed an issue where localized profession keys could lead to recipe count discrepancies in tooltips for Craft-based skills (such as Enchanting), introducing automatic data synchronization and accurate faction-based recipe calculations.

---

## [1.0.4] - 2026-09-21

### Fixed
- **Plans: Copper Chain Vest Quest Source**: Added Quest 1578 (*Supplying the Front*) to Item 3609 (*Plans: Copper Chain Vest*), properly registering it as both a world drop and an Alliance quest reward.
- **Classic Era Base Quests**: Added missing Quest 1578 (started by NPC 6031 *Tormus Deepforge* in Ironforge) to `Database/Base/quests.lua` and explicitly marked both Quest 1578 and Quest 1618 (*Gearing Redridge*) with Alliance faction affinity (`reacts = "Alliance"`).
- **Database Cleanup**: Removed duplicate entry for Quest 1578 from `Database/Expansions/TBC/quests.lua` as it is now loaded via the base quest database.

---

## [1.0.3] - 2026-09-18

### Fixed
- **Minimap Button Layering**: Fixed an issue where the circular minimap button had `SetToplevel(true)` enabled and lacked an explicit strata, causing it to render on top of overlapping UI windows (such as character sheets, bags, MBB, and the RecipeRadar main frame).
- **Frame Strata & Toplevel Hierarchy**: Explicitly set the minimap button to `LOW` frame strata with relative frame level (`Minimap:GetFrameLevel() + 8`) and `SetToplevel(false)` so it sits cleanly above the minimap artwork while remaining strictly underneath all standard game panels (`MEDIUM`) and RecipeRadar windows (`HIGH`).

---

## [1.0.2] - 2026-09-08

### Added
- **Optional Minimap Button**: Added full support for hiding and showing the circular minimap button.
- **Minimap Button Context Menu**: Right-clicking the minimap button now opens a quick options menu with a 1-click action to hide the button.
- **Slash Command Toggle**: Added `/rr minimap` (and `/rr mm`) chat command to quickly toggle minimap button visibility on and off.
- **Visibility Persistence**: Minimap button hidden state is now reliably saved in `RecipeRadarDB.profile.minimap.hide` across `/reload` and game sessions.
- **Enhanced Tooltip**: Minimap button tooltip now indicates both left-click (toggle window) and right-click (options menu) actions across supported languages.

---

## [1.0.1] - 2026-08-23

### Fixed
- **Profession Frame Button Layering**: Fixed an issue where the `RR` launch button was rendered in the global `DIALOG` strata, causing it to remain visible on top of other overlapping interfaces (such as the Auction House frame).
- **Frame Parenting & Strata**: Properly parented the `RR` launch button to the active profession window (`TradeSkillFrame`, `CraftFrame`, `DragonflightUIProfessionFrame`, etc.) so it matches the window's frame strata and level.
- **Dynamic Window Visibility**: The attach button now automatically hides when no profession window is open, preventing rogue floating buttons.
- **Candidate Frame Detection**: Added `ProfessionsFrame` to candidate frame lookup for broader compatibility with modern profession UI skins and overhauls.

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
