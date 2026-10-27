# WoW Forever database pipeline

Builds `Database/Forever/` and `RecipeRadar_Camelot.toc` from the Forever client's own DB2 tables.
Forever gets complete skills and items files of its own (not a delta on Base), because Forever reworked parts of Classic.

```
node extract_db2.mjs  ->  cache/<build>/<locale>/<Table>.json  ->  python build_forever.py
```

## Run it

Needs Node 20+ and Python 3. The tables are read from Blizzard's CDN, so the game does not have to be installed.

```powershell
cd tools/forever
npm install

# Forever build (CDN product `wowf`), all 10 languages, with the hotfixes from your local client (optional but recommended)
node extract_db2.mjs --locales enUS,deDE,frFR,esES,esMX,ruRU,zhCN,zhTW,koKR,ptBR `
    --adb "C:/Games/World of Warcraft/_forever_/Cache/ADB" `
    --out cache

# Baseline: what Classic Era already had (recipes in Era are not part of the Forever delta)
node extract_db2.mjs --product wow_classic_era --out cache SkillLineAbility

python build_forever.py --forever 1.60.1.70630 --era 1.15.9.70003
python ../verify_tocs.py   # run from the repo root
```

The build numbers are printed by the first command (`Product ... build ...`). Rerun everything when a new
Forever build comes out. `--adb` only accepts a `DBCache.bin` written for exactly the downloaded build.
`wago.tools` is deliberately not used: its `robots.txt` disallows automated access.

## What comes from where

| Data | Source |
|---|---|
| Recipe spells, crafted item, teaching items, 10 language names, reputation gates, auto-learned flag, profession category | Client DB2: `SkillLineAbility`, `SpellEffect`, `SpellName`, `ItemSparse`, `Item`, `ItemEffect`, `ItemXItemEffect`, `Faction` |
| Trainers, vendors, drops, quests, objects, holidays, specialisations | `Database/Base` (Classic). Entries that carry them get `classic_source = true`; the detail pane shows "not verified for Forever" |
| NPCs, quests, zones, objects, factions (lookup tables), profession rank data | Still loaded from `Database/Base` |

**Recipe set:** all Classic recipes that Forever still has, minus those the client flags as removed
(`SkillLineAbility.AcquireMethod` 3; for Classic these are the Alchemy healing potions, Elixir of Poison
Resistance and Purification Potion), plus every craftable recipe that is not in the Era client.
Craftable rows that exist in the Era client but not in the Classic database (about 340, many of them
Season of Discovery content) are left out on purpose: the client cannot say whether they are obtainable.

**Texts:** Everything the player reads (labels, the "unknown source" and "unverified" notes) lives in
`Core/Localization.lua`. The generated data only carries keys such as the special action `source unknown`
and the names the client provides.

## Recorded sources (player exports)

The Forever build records, while the player plays, where known recipes come from: vendors, trainers, loot and
quest rewards (`Engine/Recorder.lua`). The settings window has a "Sources" tab (Forever only) with the switch,
the counters and the export; `/rr export` opens it. The export is a Lua table in the shapes of the database files:

```lua
RR_OBSERVED = {
    ["format"] = 2, ["build"] = "1.60.1.70630", ["addon"] = "1.1.1", ["locale"] = "German",
    ["npcs"]    = { { ["id"] = 4567, ["name"] = { ["German"] = "Telonis" }, ["location"] = { ["x"] = "64.43", ["y"] = "21.49" },
                      ["zone_id"] = 1657, ["reacts"] = "Alliance", ["xp_level"] = { ["min"] = 40, ["max"] = 40, ["is_elite"] = 0 },
                      ["seen_by"] = { "Alliance" }, ["map_id"] = 1457, ["zone_name"] = "Darnassus" } },
    ["items"]   = { { ["id"] = 250380, ["vendors"] = { ["price"] = 12500, ["sources"] = { 4567 } },
                      ["drops"] = { ["sources"] = { 31337 } }, ["quests"] = { 4321 }, ["objects"] = { 2040 } } },
    ["skills"]  = { { ["id"] = 1250793, ["trainers"] = { ["price"] = 5000, ["sources"] = { 777 } } } },
    ["quests"]  = { { ["id"] = 4321, ["name"] = { ["German"] = "..." }, ["npcs"] = { 2468 } } },
    ["objects"] = { { ["id"] = 2040, ["location"] = { ["x"] = "12.30", ["y"] = "45.60" }, ["zone_id"] = 1657 } },
}
```

The fields are the ones the database uses (`vendors`/`trainers` = `{ price, sources }`, `drops` = `{ sources }`, `quests` and
`objects` = id lists, NPCs with one location, zone and reaction). `seen_by`, `map_id` and `zone_name` are extras for the merge.
The location is where the player stood while talking to the NPC (a few yards away). There are no counters or drop rates,
because the database has none. The export carries no character, realm, account or GUID data.

Merging exports (save each pasted export as a file):

```
python update.py export.lua
```

That is all: it merges the export into `observed/observed.json` and rebuilds `Database/Forever`. Several files can be
given at once. The two steps can also be run by hand (`python merge_observed.py export.lua`, then `python build_forever.py`);
`merge_observed.py export.lua --dry-run` only checks an export. A new Forever build needs the commands in "Run it".

`merge_observed.py` rejects exports of other game versions, skips ids that are not Forever recipes and invalid
coordinates or names, and merges the rest without duplicates: sources are united, known prices and locations are kept
and missing ones filled in, names are kept per language, level ranges widen. Importing the same export twice changes
nothing, so exports can be sent in again safely. `observed/observed.json` is the store; commit it. `build_forever.py`
applies it on every run: sources are added to the recipes' items and skills (the "source unknown" note disappears), and
NPCs, quests and objects that `Database/Base` does not have are written to `Database/Forever/npcs.lua`, `quests.lua`
and `objects.lua`. NPCs that Base already has stay as they are. A friendly NPC seen by one faction only is credited to
that faction until the other faction has seen it too.

**Confirmed sources:** Sources that come from Classic are not verified for Forever. When a player's export contains a source
(vendor, trainer, drop, quest reward or object), `build_forever.py` lists it in the entry's `verified` table. While a recipe
still has Classic-only sources, the detail pane splits its list into two groups under headings, "Confirmed in Forever"
(with a check mark in front of each line) and "From Classic, not verified for Forever". Once every Classic source of
a recipe is confirmed, the warning flag (`classic_source`) is dropped and the headings disappear.
Facts the recorder cannot observe (holidays, special actions, level-range drops, reputation taken from Classic) keep the
warning. One player sees only the vendors of their own faction, so an entry with vendors of both factions keeps the
warning until both have been confirmed.

## Known gaps

The client does not contain server-side knowledge, so:

* **New recipes have no source** (trainer, vendor, drop, quest, NPC coordinates). They carry the special action
  `source unknown` and show up under the "Unknown source" filter. This has to be filled in by hand or from
  in-game observation; Questie's Forever provider has the same gap for new content.
* **Classic sources are unverified.** Forever may have moved a vendor or changed a drop.
* **Skill requirement**: `SkillLineAbility.MinSkillLineRank` is 1 for all new recipes. The recipe item's
  `RequiredSkillRank` is used when set, recipes that are learned together with the profession get 1. For the rest
  the requirement is unknown, so there is no `min_skill` (no estimate): the list shows `[?]` and sorts these recipes
  last. The recorder writes the rank a trainer asks for ("Requires Cooking (50)") as `min_skill` into the export, and
  `build_forever.py` fills it in. A rank a trainer asks for also replaces a value that only came from Classic or from the client's skill line rank (Forever lowered many of them), but never the rank printed on a recipe item.
* **New recipes**: Recipes that are not in the Classic database carry `forever_new`. The list and the detail pane
  mark them with the game's own Forever logo (`Interface\Glues\Common\Glues-WoW-ForeverLogo-Infinity`, read from the
  client, nothing copied into the addon; see `RR.ORIGIN_ICONS` in `Core/Constants.lua`). Classic and TBC recipes carry
  the WoW icon of the friends list in the same column (green for TBC), in every client.
* **Phase**: Forever has no content phases. Entries carry none, and `flags.lua` sets `RR_DATA["no_phases"]`,
  which hides the phase filter and the phase row in the detail pane.
