# Changelog

All notable changes to **RecipeRadar** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-10-21

### Added
- **Support for World of Warcraft: Forever (experimental)**: RecipeRadar now has a recipe database of its own for Forever, built from the game's data: the 1243 Classic recipes that still exist plus 934 recipes that are new in Forever (Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking, Tailoring and the new camping recipes of Mining, Herbalism, Skinning and Fishing), with names in all 10 languages and reputation requirements. The 8 Classic recipes Forever no longer hands out are left out. Forever has no Jewelcrafting and no TBC content, so none is shown. Classic Era and TBC Anniversary are not affected.
- **Works with Forever's profession windows**: The "RR" button appears on the profession window and the profession overview, the RecipeRadar window opens on the profession you have open, learned recipes are read from the new profession window, and Mining, Herbalism, Skinning and Fishing are in the profession menu.
- **Forever minimap "Addons" menu**: RecipeRadar is listed there (left click opens the window, right click the settings). The separate minimap button starts hidden in Forever; `/rr minimap` or the settings bring it back.
- **Forever logo on new recipes**: Recipes that are new in Forever show the game's Forever logo in the recipe list and the detail pane, with the tooltip "New in WoW Forever".
- **Sources recorded by players (Forever)**: The sources of new recipes are not in the game's data, so RecipeRadar notes them while you play: vendors that sell a recipe, trainers that teach one, recipe items in loot and recipes offered as quest rewards, with the NPC, its zone and its position. The new "Sources" tab in the settings switches recording on or off and offers the recorded data to copy and share. `/rr export` opens it, `/rr record [on|off|clear]` works from the chat, and both are listed in the About tab. Only facts about recipes are kept, nothing is sent anywhere, and no character, realm or account names are included.
- **Confirmed and unverified sources (Forever)**: Sources carried over from Classic are not verified for Forever. While a recipe still has such sources, its list is split under the headings "Confirmed in Forever" (with a check mark in front of each source) and "From Classic, not verified for Forever". Once everything is confirmed, the headings disappear.
- **Unknown sources and skill levels (Forever)**: Recipes without a documented source are labeled "Unknown source" and can be filtered. Skill requirements come from the recipe items and from the trainers you visit, which also corrects Classic values that Forever lowered. Where a requirement is not known yet it shows "?", and these recipes are listed last.
- **Hint about incomplete data (Forever)**: The detail pane ends with a note that the source data may be incomplete and that `/rr export` helps to complete it.
- **Skins**: The look of RecipeRadar can be switched in the settings (Interface tab, "Appearance"). "Classic Era" is the dark look you know, "WoW Forever" is warm bronze like Forever's profession window, and "The Burning Crusade" is dark with fel green. The choice applies right away to the windows, buttons, drop-downs and title banners and is remembered.
- **Statues on the title banner**: Gryphons or wyverns sit on both ends of the title banner, either in the Classic look or in the WoW Forever look, or you can turn them off ("Statues" in the same settings section). They are part of the addon, so they show on every client. Until you choose, Horde characters get wyverns and everyone else gets gryphons.
- **Each skin remembers its statues**: When you change the skin, the statues change to the same kind in the matching look (for example Forever gryphons for the WoW Forever skin). What you pick for a skin stays picked when you switch away and back.


### Changed
- **Tooltip settings preview**: The box at the bottom of the tooltip settings was a fixed picture that never changed. It is now a live preview with an explanation. It shows what recipe and item tooltips and spellbook tooltips really get, follows the three options above it, and scrolls when it does not fit.
- **Forever has no phases**: The phase filter and the phase row in the detail pane are hidden.
- **Faction of new Forever recipes**: A recipe that is new in Forever is no longer shown as Alliance-only or Horde-only just because the only trainer recorded so far belongs to one faction.
- **Forever start**: Parts of the interface that the Forever client does not have are skipped, so RecipeRadar starts there and its buttons appear.
- **Profession menu**: The list under the window title is now split into "Primary Professions" and "Secondary Professions" and sorted alphabetically in your language.
- **Title banner**: The banner is now plain, without the golden dragons.


### Fixed
- **World map**: The RecipeRadar windows no longer cover the world map. They move behind it while it is open and come back when it closes.
- **Profession menu width**: The menu is now exactly as wide as the title bar instead of sticking out on both sides.

---

## [1.1.2] - 2026-10-26

### Fixed
- **Quest names**: The recipe details always showed quest names in German, whatever language your game client uses. They now follow the client language.

---

## [1.1.1] - 2026-10-11

### Changed
- **Standard Minimap Button**: The minimap button is now a standard launcher button, so minimap button manager addons (such as DragonflightUI's "Hide Minimap Buttons" option) can collect, hide, and arrange it like any other addon button.
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
