"""Generates RecipeRadar's WoW Forever recipe database from extracted DB2 tables.

Run tools/forever/extract_db2.mjs first (see README.md in this folder), then:

    python build_forever.py [--forever 1.60.1.70450] [--era 1.15.9.70003] [--cache cache]

Output goes to Database/Forever/ plus RecipeRadar_Camelot.toc. Forever gets its own complete skills and
items files instead of a delta on top of Base, because Forever reworked parts of the Classic recipes.

Recipe set
  * every recipe of the Classic database (Database/Base) that Forever still has, except those the
    client flags as no longer acquirable (SkillLineAbility.AcquireMethod 3), and
  * every craftable recipe that is new in Forever (in the Forever client but not in the Era client).
Craftable rows that exist in the Era client but never made it into the Classic database (for example
Season of Discovery content) are left out on purpose: the client cannot say whether they are obtainable.

Where the data comes from
  * Client: spell, 10 localized names, crafted item, teaching (recipe) items, reputation gates,
    auto-learned flag, profession category, skill requirement when the client has one.
  * Classic database: trainers, vendors, drops, quests, objects, holidays, reputation, specialisations.
    These are NOT verified for Forever, so every entry that carries them is flagged `classic_source`
    and the addon shows a warning. Recipes without any known source get the "source unknown" special action.
  * Forever has no content phases, so entries carry none and flags.lua sets RR_DATA["no_phases"].
  * Texts shown to the user live in Core/Localization.lua, never in the generated data.
"""
import argparse
import collections
import glob
import json
import os
import re

from lua_tables import read_assignment
from observed import apply_store, load_base_ids, load_store, settle_classic_flags

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "Database", "Forever")
OUT_DIR_REL = "Database\\Forever\\"

# DB2 locale -> key used in the addon's name tables
LOCALES = {
    "enUS": "English", "deDE": "German", "frFR": "French", "esES": "Spanish", "esMX": "Mexican",
    "ruRU": "Russian", "zhCN": "Chinese", "zhTW": "Taiwanese", "koKR": "Korean", "ptBR": "Portuguese",
}

# SkillLine id -> (RR_DATA profession key, folder name)
PROFESSIONS = {
    171: ("Alchemy", "Alchemy"),
    164: ("Blacksmithing", "Blacksmithing"),
    185: ("Cooking", "Cooking"),
    333: ("Enchanting", "Enchanting"),
    202: ("Engineering", "Engineering"),
    129: ("First Aid", "FirstAid"),
    356: ("Fishing", "Fishing"),
    182: ("Herbalism", "Herbalism"),
    165: ("Leatherworking", "Leatherworking"),
    186: ("Mining", "Mining"),
    40: ("Poisons", "Poisons"),
    393: ("Skinning", "Skinning"),
    197: ("Tailoring", "Tailoring"),
}
KEY_TO_LINE = {key: line for line, (key, _folder) in PROFESSIONS.items()}
KEY_TO_FOLDER = {key: folder for key, folder in PROFESSIONS.values()}

# Order of the profession menu in the addon: crafting first, then gathering and fishing (Forever added camp recipes to them)
PROFESSION_MENU_ORDER = [
    "Leatherworking", "Tailoring", "Blacksmithing", "Alchemy", "Engineering", "Enchanting",
    "Cooking", "First Aid", "Poisons", "Mining", "Herbalism", "Skinning", "Fishing",
]

# SpellEffect.Effect values that produce something to craft: create item, enchant item/held item
CRAFT_EFFECTS = {24, 53, 54, 157}
EFFECT_CREATE_ITEM = 24
EFFECT_LEARN_SPELL = 36
TRIGGER_LEARN = 6  # ItemEffect.TriggerType "on learn" used by recipe items
ACQUIRE_AUTO_LEARNED = 1  # SkillLineAbility.AcquireMethod: learned automatically
ACQUIRE_REMOVED = 3  # AcquireMethod 3 is set on recipes Forever no longer hands out (e.g. Alchemy healing potions)
QUALITY = {0: "common", 1: "common", 2: "uncommon", 3: "rare", 4: "epic", 5: "epic", 6: "epic", 7: "epic"}
UNKNOWN_SOURCE = "source unknown"
AUTO_LEARNED = "auto learned"
REPUTATION_LEVEL_OFFSET = 1  # ItemSparse.MinReputation is a ReputationRank (0-based); the addon's level_id is 1-based

# Fields copied from the Classic database; they describe where a recipe is obtained.
SKILL_SOURCE_KEYS = ("trainers", "quests", "reputation", "objects", "special_action")
SKILL_OTHER_KEYS = ("specialisation", "classes", "min_xp_level")
ITEM_SOURCE_KEYS = ("drops", "quests", "vendors", "holiday", "reputation", "objects", "special_action")
ITEM_OTHER_KEYS = ("min_xp_level",)


def load(cache, build, locale, table):
    path = os.path.join(cache, build, locale, table + ".json")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def read_classic(kind):
    """{profession key: {id: entry}} for Database/Base/*/<kind>.lua"""
    out = {}
    for path in sorted(glob.glob(os.path.join(ROOT, "Database", "Base", "*", kind + ".lua"))):
        with open(path, encoding="utf-8") as f:
            for m, table in read_assignment(f.read(), r'RR_DATA\["' + kind + r'"\]\["([^"]+)"\]'):
                out.setdefault(m.group(1), {}).update({e["id"]: e for e in table})
    return out


def read_classic_spell_items():
    path = os.path.join(ROOT, "Database", "Base", "spell_items.lua")
    with open(path, encoding="utf-8") as f:
        return {int(s): int(i) for s, i in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", f.read())}


def lua(value, depth=0):
    """Serializes to Lua with sorted keys and tabs, matching the hand-maintained database files."""
    pad = "\t" * (depth + 1)
    end = "\t" * depth
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(value, list):
        return "{\n" + "".join(f"{pad}{lua(v, depth + 1)},\n" for v in value) + end + "}"
    if isinstance(value, dict):
        return "{\n" + "".join(f"{pad}[{lua(k)}] = {lua(v, depth + 1)},\n" for k, v in sorted(value.items())) + end + "}"
    raise TypeError(type(value))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--forever", default="1.60.1.70450")
    ap.add_argument("--era", default="1.15.9.70003")
    ap.add_argument("--cache", default=os.path.join(os.path.dirname(__file__), "cache"))
    args = ap.parse_args()
    F, E, cache = args.forever, args.era, args.cache

    sla = load(cache, F, "enUS", "SkillLineAbility")
    era_sla = load(cache, E, "enUS", "SkillLineAbility")
    effects = load(cache, F, "enUS", "SpellEffect")
    item_effects = load(cache, F, "enUS", "ItemEffect")
    item_links = load(cache, F, "enUS", "ItemXItemEffect")
    item_table = load(cache, F, "enUS", "Item")
    spell_names = {loc: load(cache, F, loc, "SpellName") for loc in LOCALES}
    item_names = {loc: load(cache, F, loc, "ItemSparse") for loc in LOCALES}
    items_en = item_names["enUS"]

    classic_skills = read_classic("skills")
    classic_items_by_prof = read_classic("items")
    classic_levels = read_classic("levels")
    classic_spell_items = read_classic_spell_items()
    classic_items = {i: (prof, e) for prof, d in classic_items_by_prof.items() for i, e in d.items()}
    level_items = {i for d in classic_levels.values() for lv in d.values() for i in lv.get("items", [])}
    classic_spells = {s for d in classic_skills.values() for s in d}
    era_spells = {a["Spell"] for a in era_sla.values()}

    rows_by_spell = collections.defaultdict(list)
    for a in sla.values():
        rows_by_spell[a["Spell"]].append(a)
    by_spell = collections.defaultdict(list)
    for e in effects.values():
        by_spell[e["SpellID"]].append(e)
    taught_by = collections.defaultdict(list)  # recipe spell -> spells that learn it
    for e in effects.values():
        if e["Effect"] == EFFECT_LEARN_SPELL and e["EffectTriggerSpell"]:
            taught_by[e["EffectTriggerSpell"]].append(e["SpellID"])
    effect_by_id = {i["ID"]: i for i in item_effects.values()}
    items_using = collections.defaultdict(list)  # spell -> (item id, trigger type)
    for link in item_links.values():
        ie = effect_by_id.get(link["ItemEffectID"])
        if ie:
            items_using[ie["SpellID"]].append((link["ItemID"], ie["TriggerType"]))

    def localized(tables, row_id, field):
        out = {}
        for loc, key in LOCALES.items():
            row = tables[loc].get(str(row_id))
            text = row.get(field) if row else None
            if text:
                out[key] = text
        if "English" not in out:
            return None
        for key in LOCALES.values():
            out.setdefault(key, out["English"])  # untranslated rows fall back to English
        return out

    def teaching_items(spell):
        """Items that teach a recipe. They need a row in the Item table; ItemSparse (names) can lag behind."""
        found = set()
        for teacher in taught_by.get(spell, []):
            found.update(i for i, _ in items_using.get(teacher, []))
        found.update(i for i, trig in items_using.get(spell, []) if trig == TRIGGER_LEARN)
        return sorted(i for i in found if str(i) in item_table)

    def pick_row(spell, line):
        rows = rows_by_spell.get(spell, [])
        return next((r for r in rows if r["SkillLine"] == line), rows[0] if rows else None)

    stats = collections.Counter()
    report = collections.defaultdict(list)

    # ---- 1. decide the recipe set -----------------------------------------------------------
    recipes = {}  # spell -> (profession key, SkillLineAbility row, classic entry or None)
    for prof, entries in classic_skills.items():
        for spell, entry in entries.items():
            row = pick_row(spell, KEY_TO_LINE[prof])
            name = entry["name"]["English"]
            if row is None:
                report["Classic recipes missing in Forever"].append((prof, spell, name))
            elif row["AcquireMethod"] == ACQUIRE_REMOVED:
                report["Classic recipes Forever no longer hands out (dropped)"].append((prof, spell, name))
            else:
                recipes[spell] = (prof, row, entry)
                if row["SkillLine"] != KEY_TO_LINE[prof]:
                    report["Classic recipes found in another skill line (kept)"].append((prof, spell, name))
    stats["Classic recipes kept"] = len(recipes)
    for ability in sla.values():
        line, spell = ability["SkillLine"], ability["Spell"]
        if line not in PROFESSIONS or spell in era_spells or spell in classic_spells or spell in recipes:
            continue
        craftable = any(e["Effect"] in CRAFT_EFFECTS for e in by_spell.get(spell, []))
        if not craftable or not localized(spell_names, spell, "Name_lang"):
            stats["skipped (new row, not a craftable recipe)"] += 1
        elif ability["AcquireMethod"] == ACQUIRE_REMOVED:
            stats["skipped (new row, flagged as removed)"] += 1
        else:
            recipes[spell] = (PROFESSIONS[line][0], ability, None)
            stats["new Forever recipes"] += 1

    # ---- 2. build skill and item entries -----------------------------------------------------
    skills, items = collections.defaultdict(list), collections.defaultdict(dict)
    spell_to_item = {}
    kept_items = set()
    # entries whose carried Classic facts a player can never confirm (holidays, special actions, level-range drops,
    # Classic reputation); they keep the "unverified" warning even when all their NPC sources were seen
    unverifiable_items, unverifiable_skills = set(), set()
    # skills whose min_skill is a Classic value or the client's skill line rank (not the number on a recipe item);
    # the rank a trainer asks for in Forever replaces it
    trainer_replaceable = set()

    def make_item(item_id, prof):
        """Entry for one recipe item, or None when neither the client nor the Classic data know its name."""
        classic = classic_items.get(item_id, (None, None))[1]
        sparse = items_en.get(str(item_id))
        name = localized(item_names, item_id, "Display_lang") or (classic or {}).get("name")
        if not name:
            return None
        entry = {"id": item_id, "name": name, "forever": True}
        if sparse:
            entry["quality"] = QUALITY.get(sparse["OverallQualityID"], "common")
        else:
            entry["quality"] = (classic or {}).get("quality", "common")
        carried = False
        if classic:
            for key in ITEM_SOURCE_KEYS + ITEM_OTHER_KEYS:
                if key in classic:
                    entry[key] = classic[key]
                    carried = carried or key in ITEM_SOURCE_KEYS
        if sparse and sparse["MinFactionID"]:  # the client's own reputation gate wins over the Classic one
            entry["reputation"] = {
                "faction_id": sparse["MinFactionID"],
                "level_id": sparse["MinReputation"] + REPUTATION_LEVEL_OFFSET,
            }
        if carried:
            entry["classic_source"] = True
            has_gate = bool(sparse and sparse["MinFactionID"])
            if (any(k in classic for k in ("holiday", "special_action")) or classic.get("drops", {}).get("range")
                    or ("reputation" in classic and not has_gate)):
                unverifiable_items.add(item_id)
        if not classic:
            entry["special_action"] = UNKNOWN_SOURCE
        return entry

    for spell, (prof, row, classic) in sorted(recipes.items()):
        name = localized(spell_names, spell, "Name_lang") or classic["name"]
        entry = {"id": spell, "name": name, "forever": True}

        candidates = sorted(set(teaching_items(spell)) | {i for i in (classic or {}).get("items", []) if str(i) in item_table})
        item_entries = []
        for item_id in candidates:
            item = make_item(item_id, prof)
            if item:
                item_entries.append(item)
        documented = {i["id"] for i in item_entries}
        if candidates:
            entry["items"] = candidates

        # skill requirement: recipe item > client > Classic > estimate from the trivial thresholds
        required = max((items_en[str(i)]["RequiredSkillRank"] for i in candidates if str(i) in items_en), default=0)
        if required > 1:
            entry["min_skill"] = required
        elif row["MinSkillLineRank"] > 1:
            entry["min_skill"] = row["MinSkillLineRank"]
            trainer_replaceable.add(spell)
        elif classic:
            entry["min_skill"] = classic["min_skill"]
            trainer_replaceable.add(spell)
        elif row["AcquireMethod"] == ACQUIRE_AUTO_LEARNED:
            entry["min_skill"] = 1  # learned together with the profession
        # otherwise the requirement is not known: no min_skill, a trainer's export fills it in (merge_observed.py)
        if not classic:
            entry["forever_new"] = True  # shown with the Forever marker in the list

        crafted = next((e["EffectItemType"] for e in by_spell.get(spell, []) if e["Effect"] == EFFECT_CREATE_ITEM and e["EffectItemType"]), 0)
        if crafted:
            entry["item_id"] = crafted
            if classic_spell_items.get(spell) != crafted:
                spell_to_item[spell] = crafted

        carried = False
        if classic:
            for key in SKILL_SOURCE_KEYS + SKILL_OTHER_KEYS:
                if key in classic:
                    if key == "special_action" and classic[key] == AUTO_LEARNED:
                        continue  # decided from the client below
                    entry[key] = classic[key]
                    carried = carried or key in SKILL_SOURCE_KEYS
        if row["AcquireMethod"] == ACQUIRE_AUTO_LEARNED and "special_action" not in entry:
            entry["special_action"] = AUTO_LEARNED
        elif classic and classic.get("special_action") == AUTO_LEARNED and row["AcquireMethod"] != ACQUIRE_AUTO_LEARNED:
            stats["Classic 'auto learned' no longer auto learned in Forever (dropped)"] += 1
        if carried:
            entry["classic_source"] = True
            if classic.get("reputation") or classic.get("special_action") not in (None, AUTO_LEARNED):
                unverifiable_skills.add(spell)
        if not any(k in entry for k in SKILL_SOURCE_KEYS) and not item_entries:
            entry["special_action"] = UNKNOWN_SOURCE

        skills[prof].append(entry)
        for item in item_entries:
            items[prof].setdefault(item["id"], item)
            kept_items.add(item["id"])
        stats["recipes"] += 1
        if classic and entry.get("classic_source") or any(i.get("classic_source") for i in item_entries):
            stats["recipes with Classic sources (flagged unverified)"] += 1
        elif entry.get("special_action") == UNKNOWN_SOURCE or any(i.get("special_action") == UNKNOWN_SOURCE for i in item_entries):
            stats["recipes with unknown source"] += 1

    # Classic items that no kept recipe uses (profession ranks, leftovers) stay available to the rank data.
    removed_only = {i for prof, d in classic_items_by_prof.items() for i in d} - kept_items
    for item_id in sorted(removed_only):
        prof, classic = classic_items[item_id]
        referenced = item_id in level_items or not any(item_id in s.get("items", []) for d in classic_skills.values() for s in d.values())
        if referenced:
            item = make_item(item_id, prof)
            if item:
                items[prof].setdefault(item_id, item)
                stats["Classic items kept without a recipe"] += 1
        else:
            stats["Classic items dropped (recipe removed in Forever)"] += 1

    # ---- 2b. sources recorded by players (tools/forever/observed/observed.json, see merge_observed.py) -----
    observed_report, new_npcs, new_quests, new_objects = apply_store(
        load_store(), skills, items, load_base_ids(), UNKNOWN_SOURCE, trainer_replaceable)
    for key, value in observed_report.items():
        stats[f"recorded sources: {key}"] = value
    stats["recorded sources: new npcs / quests / objects"] = f"{len(new_npcs)} / {len(new_quests)} / {len(new_objects)}"
    stats["recorded sources: entries whose Classic sources are now all confirmed"] = settle_classic_flags(
        skills, items, unverifiable_skills, unverifiable_items)

    # ---- 3. write ----------------------------------------------------------------------------
    header = f"-- Generated by tools/forever/build_forever.py from WoW Forever build {F}. Do not edit by hand.\n"
    banner = lambda title: f"-------------------------------------------------------\n-- {title}\n-------------------------------------------------------\n{header}"
    os.makedirs(OUT_DIR, exist_ok=True)
    for stale in glob.glob(os.path.join(OUT_DIR, "*", "*.lua")) + glob.glob(os.path.join(OUT_DIR, "*.lua")):
        os.remove(stale)
    written = []
    for prof in sorted(set(skills) | set(items)):
        folder = KEY_TO_FOLDER[prof]
        os.makedirs(os.path.join(OUT_DIR, folder), exist_ok=True)
        if skills.get(prof):
            skill_list = sorted(skills[prof], key=lambda s: (s.get("min_skill") or 10**9, s["id"]))
            with open(os.path.join(OUT_DIR, folder, "skills.lua"), "w", encoding="utf-8", newline="\n") as f:
                f.write(banner(f"All skills ({prof}) - WoW Forever"))
                f.write(f'RR_DATA["skills"]["{prof}"] = {lua(skill_list)}\n')
            written.append(f"{OUT_DIR_REL}{folder}\\skills.lua")
        if items.get(prof):
            item_list = sorted(items[prof].values(), key=lambda i: i["id"])
            with open(os.path.join(OUT_DIR, folder, "items.lua"), "w", encoding="utf-8", newline="\n") as f:
                f.write(banner(f"All items ({prof}) - WoW Forever"))
                f.write(f'RR_DATA["items"]["{prof}"] = {lua(item_list)}\n')
            written.append(f"{OUT_DIR_REL}{folder}\\items.lua")

    # Factions that gate recipes but are not part of the Base database (new in Forever).
    with open(os.path.join(ROOT, "Database", "Base", "factions.lua"), encoding="utf-8") as f:
        known_factions = {int(m) for m in re.findall(r'\["id"\] = (\d+)', f.read())}
    gated = {i["reputation"]["faction_id"] for d in items.values() for i in d.values() if "reputation" in i}
    gated |= {s["reputation"]["faction_id"] for lst in skills.values() for s in lst if "reputation" in s}
    faction_rows = load(cache, F, "enUS", "Faction")
    faction_names = {loc: load(cache, F, loc, "Faction") for loc in LOCALES}
    new_factions = [
        {"id": fid, "name": localized(faction_names, fid, "Name_lang")}
        for fid in sorted(gated - known_factions) if str(fid) in faction_rows
    ]
    missing = sorted(gated - known_factions - {f["id"] for f in new_factions})
    if missing:
        print(f"WARNING: reputation factions without a Faction row: {missing}")
    with open(os.path.join(OUT_DIR, "factions.lua"), "w", encoding="utf-8", newline="\n") as f:
        f.write(banner("Factions new in WoW Forever"))
        f.write(f"local forever_factions = {lua(new_factions)}\n\n")
        f.write('for _, faction in ipairs(forever_factions) do\n\ttable.insert(RR_DATA["factions"], faction)\nend\n\n')
        f.write("-- Shown in the reputation filter in addition to the curated Classic list.\n")
        f.write(f'RR_DATA["forever_reputation_factions"] = {lua([f["id"] for f in new_factions])}\n')

    with open(os.path.join(OUT_DIR, "flags.lua"), "w", encoding="utf-8", newline="\n") as f:
        f.write(banner("Data flags - WoW Forever"))
        f.write("-- Forever has no content phases: hides the phase filter/label and skips phase filtering.\n")
        f.write('RR_DATA["no_phases"] = true\n')
        f.write('-- Recipes with the "source unknown" special action exist: offer the "Unknown source" filter.\n')
        f.write('RR_DATA["has_unknown_sources"] = true\n')
        f.write("-- The TOC lists RecipeRadar in the minimap Addons menu; the separate minimap button starts hidden.\n")
        f.write('RR_DATA["addon_compartment"] = true\n')
        f.write("-- Recipes that are new in Forever carry forever_new; the list marks them with the Forever symbol.\n")
        f.write('RR_DATA["new_recipe_marker"] = true\n')
        menu = [p for p in PROFESSION_MENU_ORDER if skills.get(p)]
        f.write("-- Professions offered in the profession menu (the Era/TBC menu is a fixed list without gatherers).\n")
        f.write(f'RR_DATA["profession_menu"] = {lua(menu)}\n')

    # NPCs, quests and objects that Database/Base does not have yet (from recorded sources); Base entries stay as they are
    for kind, entries in (("npcs", new_npcs), ("quests", new_quests), ("objects", new_objects)):
        with open(os.path.join(OUT_DIR, kind + ".lua"), "w", encoding="utf-8", newline="\n") as f:
            f.write(banner(f"{kind.capitalize()} recorded in WoW Forever (appended to the Base {kind})"))
            f.write(f"local forever_{kind} = {lua(entries)}\n\n")
            f.write(f'for _, entry in ipairs(forever_{kind}) do\n\ttable.insert(RR_DATA["{kind}"], entry)\nend\n')

    with open(os.path.join(OUT_DIR, "spell_items.lua"), "w", encoding="utf-8", newline="\n") as f:
        f.write(banner("Spell-ID to crafted Item-ID (additions to Database/Base/spell_items.lua)"))
        for spell, item in sorted(spell_to_item.items()):
            f.write(f'RR_DATA["spell_to_item"][{spell}] = {item}\n')

    # ---- TOC: the Era TOC without Base skills/items, plus the Forever files ---------------------
    with open(os.path.join(ROOT, "RecipeRadar.toc"), encoding="utf-8") as f:
        toc_lines = f.read().split("\n")
    replaced = re.compile(r"^Database\\Base\\[A-Za-z]+\\(skills|items)\.lua$")
    toc = "\n".join(l for l in toc_lines if not replaced.match(l.strip()))
    toc = re.sub(r"^## Interface: .*$", "## Interface: 16001", toc, flags=re.M)
    toc = re.sub(r"^## Notes: .*$", "## Notes: Comprehensive profession recipe and skill tracker with TomTom waypoints for WoW Forever.", toc, flags=re.M)
    # Entry in the minimap "Addons" menu: the game calls the named globals (defined in UI/MinimapButton.lua)
    toc = re.sub(
        r"^## IconTexture: .*$",
        "## IconTexture: Interface\\\\AddOns\\\\RecipeRadar\\\\images\\\\minimap.tga\n"
        "## AddonCompartmentFunc: RecipeRadar_AddonCompartmentClick\n"
        "## AddonCompartmentFuncOnEnter: RecipeRadar_AddonCompartmentEnter\n"
        "## AddonCompartmentFuncOnLeave: RecipeRadar_AddonCompartmentLeave",
        toc, flags=re.M)
    # Source recorder and its export window are part of the Forever build only
    for anchor, addition in (("Engine\\AltTracker.lua", "Engine\\Recorder.lua"), ("UI\\SettingsWindow.lua", "UI\\RecorderPanel.lua")):
        assert anchor in toc, anchor
        toc = toc.replace(anchor, anchor + "\n" + addition, 1)
    block = ["# 2b. Database (WoW Forever recipes; replaces the Base skills and items)"]
    block += [OUT_DIR_REL + n for n in ("flags.lua", "factions.lua", "spell_items.lua", "npcs.lua", "quests.lua", "objects.lua")]
    block += sorted(written)
    toc = toc.replace("# 3. Engine & Scanning", "\n".join(block) + "\n\n# 3. Engine & Scanning")
    with open(os.path.join(ROOT, "RecipeRadar_Camelot.toc"), "w", encoding="utf-8", newline="\n") as f:
        f.write(toc)

    # ---- report ------------------------------------------------------------------------------
    print(f"Forever build {F}: baseline Era {E}")
    for k, v in sorted(stats.items()):
        print(f"  {k}: {v}")
    for title, rows in report.items():
        print(f"  {title}: {len(rows)}")
        for r in rows[:12]:
            print(f"      {r}")
    for prof in sorted(set(skills) | set(items)):
        print(f"  {prof:15} {len(skills.get(prof, [])):4} recipes, {len(items.get(prof, {})):4} items")


if __name__ == "__main__":
    main()
