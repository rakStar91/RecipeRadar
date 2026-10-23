"""Validation, merging and applying of source exports from RecipeRadar's recorder (WoW Forever).

The recorder (Engine/Recorder.lua, /rr export) writes a Lua table `RR_OBSERVED = { ... }` in the shapes of
the database files. merge_observed.py checks such exports and merges them into one store,
observed/observed.json. build_forever.py applies the store to the generated Forever data on every run,
so merged sources survive regeneration.

Merge rules (all idempotent, importing the same export twice changes nothing):
  * sources (vendors, drops, trainers, quests, objects) are united
  * a scalar that is already known (price, location, zone) is kept, a missing one is filled in
  * names are kept per language; a language only gets a name when somebody played in it
  * NPC level ranges widen; the reaction of an NPC is kept per observing faction
"""
import collections
import json
import os
import re

from lua_tables import read_assignment

EXPORT_FORMAT = 2
BUILD_PREFIX = "1.60."  # Forever; exports from other game versions are rejected
LOCALE_KEYS = ("English", "German", "French", "Spanish", "Mexican", "Russian", "Chinese", "Taiwanese", "Korean", "Portuguese")
FACTIONS = ("Alliance", "Horde")
REACTS = ("Alliance", "Horde", "Neutral", "Hostile")
MAX_ENTRIES = 20000
MAX_SOURCES = 500
STORE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "observed", "observed.json")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

_COORD = re.compile(r"^\d{1,3}(\.\d{1,3})?$")
_CONTROL = re.compile(r"[\x00-\x1f\x7f]")


def empty_store():
    return {"format": EXPORT_FORMAT, "builds": [], "imports": 0, "npcs": {}, "items": {}, "skills": {}, "quests": {}, "objects": {}}


def load_store(path=STORE_PATH):
    if not os.path.exists(path):
        return empty_store()
    with open(path, encoding="utf-8") as f:
        store = json.load(f)
    for key, default in empty_store().items():
        store.setdefault(key, default)
    return store


# Version of the names in the store (2: an English name is never a copy of the German one)
NAMES_VERSION = 2


def reset_copied_names(store):
    """Earlier scraper runs wrote the German name into the English slot as well. An English name that equals the German
    one tells nothing and is wrong for every translated name, so it is dropped once; the next scrape or export fills
    it with the real one (the build falls back to the German name for what stays empty, as before)."""
    removed = 0
    for kind in ("npcs", "quests"):
        for entry in store[kind].values():
            names = entry.get("name", {})
            if "English" in names and names["English"] == names.get("German"):
                del names["English"]
                removed += 1
    store["names_version"] = NAMES_VERSION
    return removed


def referenced_npcs(store):
    """Ids of the NPCs that a recipe source or a quest still points to; only these end up in Database/Forever."""
    referenced = {n for kind in ("items", "skills") for e in store[kind].values()
                  for source in ("vendors", "drops", "trainers") for n in e.get(source, {}).get("sources", [])}
    referenced.update(n for q in store["quests"].values() for n in q.get("npcs", []))
    return referenced


def save_store(store, path=STORE_PATH):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(store, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")


# ---- reading the data the exports must refer to ----------------------------------------------------

def load_known(root=ROOT):
    """Recipe item ids and recipe spell ids of the generated Forever data (what the recorder is allowed to report)."""
    items, spells = set(), set()
    for path in sorted(os.listdir(os.path.join(root, "Database", "Forever"))):
        folder = os.path.join(root, "Database", "Forever", path)
        if not os.path.isdir(folder):
            continue
        for kind, target in (("items", items), ("skills", spells)):
            file = os.path.join(folder, kind + ".lua")
            if os.path.exists(file):
                with open(file, encoding="utf-8") as f:
                    for _, table in read_assignment(f.read(), r'RR_DATA\["' + kind + r'"\]\["[^"]+"\]'):
                        target.update(e["id"] for e in table)
    return items, spells


def load_base_ids(root=ROOT):
    """Ids of the NPCs, quests and objects that Database/Base already has (they stay as they are)."""
    ids = {}
    for kind in ("npcs", "quests", "objects"):
        with open(os.path.join(root, "Database", "Base", kind + ".lua"), encoding="utf-8") as f:
            ids[kind] = {e["id"] for _, table in read_assignment(f.read(), r'RR_DATA\["' + kind + r'"\]') for e in table}
    return ids


# ---- validation -------------------------------------------------------------------------------------

def _int(value, low=1, high=2**31 - 1):
    if isinstance(value, bool) or not isinstance(value, int) or not low <= value <= high:
        return None
    return value


def _text(value, limit=80):
    if not isinstance(value, str):
        return None
    value = value.strip()
    if not value or len(value) > limit or _CONTROL.search(value):
        return None
    return value


def _names(value):
    if not isinstance(value, dict):
        return {}
    out = {}
    for key, text in value.items():
        text = _text(text)
        if key in LOCALE_KEYS and text:
            out[key] = text
    return out


def _drop_range(value):
    """{"min_xp_level", "max_xp_level"} of mobs that drop an item, or None."""
    if not isinstance(value, dict):
        return None
    low, high = _int(value.get("min_xp_level"), 1, 100), _int(value.get("max_xp_level"), 1, 100)
    return {"min_xp_level": low, "max_xp_level": high} if low and high and low <= high else None


def _location(value):
    if not isinstance(value, dict):
        return None
    x, y = value.get("x"), value.get("y")
    if not (isinstance(x, str) and isinstance(y, str) and _COORD.match(x) and _COORD.match(y)):
        return None
    if not (0 <= float(x) <= 100 and 0 <= float(y) <= 100):
        return None
    return {"x": f"{float(x):.2f}", "y": f"{float(y):.2f}"}


def _ids(value):
    if not isinstance(value, list):
        return []
    return sorted({i for i in (_int(v) for v in value) if i})[:MAX_SOURCES]


def _where(entry):
    """location, zone and map data shared by NPCs and objects"""
    out = {}
    location = _location(entry.get("location"))
    if location:
        out["location"] = location
        zone_id, map_id = _int(entry.get("zone_id")), _int(entry.get("map_id"))
        if zone_id:
            out["zone_id"] = zone_id
        if map_id:
            out["map_id"] = map_id
        zone_name = _text(entry.get("zone_name"), 60)
        if zone_name:
            out["zone_name"] = zone_name
    return out


def clean_export(data, known_items, known_spells, allow_build=False):
    """Returns (clean data, warnings). Raises ValueError when the export is unusable as a whole."""
    if not isinstance(data, dict) or data.get("format") != EXPORT_FORMAT:
        raise ValueError(f"unsupported export format (expected {EXPORT_FORMAT})")
    build = _text(data.get("build"), 40)
    if not build or not (allow_build or build.startswith(BUILD_PREFIX)):
        raise ValueError(f"build {build!r} is not a Forever build ({BUILD_PREFIX}*); use --allow-build to override")
    warnings = []
    clean = {"build": build, "npcs": [], "items": [], "skills": [], "quests": [], "objects": []}

    for kind in ("npcs", "items", "skills", "quests", "objects"):
        if not isinstance(data.get(kind, []), list):
            raise ValueError(f"'{kind}' is not a list")
        if len(data.get(kind, [])) > MAX_ENTRIES:
            raise ValueError(f"too many '{kind}' entries")

    for e in data.get("npcs", []):
        npc_id = _int(e.get("id")) if isinstance(e, dict) else None
        if not npc_id:
            warnings.append("npc without a valid id skipped"); continue
        entry = {"id": npc_id, "name": _names(e.get("name"))}
        entry.update(_where(e))
        xp = e.get("xp_level")
        if isinstance(xp, dict) and _int(xp.get("min"), 1, 100) and _int(xp.get("max"), 1, 100):
            entry["xp_level"] = {"min": xp["min"], "max": xp["max"], "is_elite": 1 if xp.get("is_elite") == 1 else 0}
        seen_by = [f for f in (e.get("seen_by") or []) if f in FACTIONS] if isinstance(e.get("seen_by"), list) else []
        if e.get("reacts") in REACTS and seen_by:
            entry["obs_react"] = {seen_by[0]: e["reacts"]}
        clean["npcs"].append(entry)

    def priced(source):
        if not isinstance(source, dict):
            return None
        out = {"sources": _ids(source.get("sources"))}
        price = _int(source.get("price"), 1, 10_000_000)  # copper
        if price:
            out["price"] = price
        return out if out["sources"] else None

    for e in data.get("items", []):
        item_id = _int(e.get("id")) if isinstance(e, dict) else None
        if not item_id:
            warnings.append("item without a valid id skipped"); continue
        if item_id not in known_items:
            warnings.append(f"item {item_id} is not a known Forever recipe item, skipped"); continue
        entry = {"id": item_id}
        vendors = priced(e.get("vendors"))
        if vendors:
            entry["vendors"] = vendors
        drops = e.get("drops")
        if isinstance(drops, dict):
            clean_drops = {}
            if _ids(drops.get("sources")):
                clean_drops["sources"] = _ids(drops["sources"])
            if _drop_range(drops.get("range")):
                clean_drops["range"] = _drop_range(drops["range"])
            if clean_drops:
                entry["drops"] = clean_drops
        for key in ("quests", "objects"):
            if _ids(e.get(key)):
                entry[key] = _ids(e[key])
        if len(entry) > 1:
            clean["items"].append(entry)

    for e in data.get("skills", []):
        spell_id = _int(e.get("id")) if isinstance(e, dict) else None
        if not spell_id:
            warnings.append("skill without a valid id skipped"); continue
        if spell_id not in known_spells:
            warnings.append(f"spell {spell_id} is not a known Forever recipe, skipped"); continue
        entry = {"id": spell_id}
        trainers = priced(e.get("trainers"))
        if trainers:
            entry["trainers"] = trainers
            min_skill = _int(e.get("min_skill"), 1, 450)  # skill rank the trainer asks for
            if min_skill:
                entry["min_skill"] = min_skill
        if _ids(e.get("quests")):
            entry["quests"] = _ids(e["quests"])
        if len(entry) > 1:
            clean["skills"].append(entry)

    for e in data.get("quests", []):
        quest_id = _int(e.get("id")) if isinstance(e, dict) else None
        if not quest_id:
            warnings.append("quest without a valid id skipped"); continue
        clean["quests"].append({"id": quest_id, "name": _names(e.get("name")), "npcs": _ids(e.get("npcs"))})

    for e in data.get("objects", []):
        object_id = _int(e.get("id")) if isinstance(e, dict) else None
        if not object_id:
            warnings.append("object without a valid id skipped"); continue
        entry = {"id": object_id}
        entry.update(_where(e))
        clean["objects"].append(entry)
    return clean, warnings


# ---- merging ----------------------------------------------------------------------------------------

def _union(existing, new):
    return sorted(set(existing) | set(new))


def _merge_where(store_entry, new):
    # location, zone and map belong together; the first complete set wins
    if "location" not in store_entry and "location" in new:
        for key in ("location", "zone_id", "map_id", "zone_name"):
            if key in new:
                store_entry[key] = new[key]
    elif "zone_id" not in store_entry and "zone_id" in new:
        # the zone arrives later (older exports could not resolve it): take its name too, it replaces a building name
        store_entry["zone_id"] = new["zone_id"]
        if "zone_name" in new:
            store_entry["zone_name"] = new["zone_name"]


def _merge_names(store_entry, names):
    """The first name of a language wins. The exception is an English name that equals the German one: exports from
    before the scraper read the English page carry such copies, so a real English name replaces it."""
    if names:
        target = store_entry.setdefault("name", {})
        for locale, text in names.items():
            copied = locale == "English" and target.get("English") == target.get("German") and text != target.get("English")
            if locale not in target or copied:
                target[locale] = text


def _merge_priced(entry, key, new):
    current = entry.setdefault(key, {"sources": []})
    current["sources"] = _union(current["sources"], new["sources"])
    if "price" not in current and "price" in new:
        current["price"] = new["price"]


def merge_into_store(store, clean):
    """Merges one cleaned export into the store and returns {kind: (new, changed)} counts."""
    stats = {}

    def merge(kind, entries, apply):
        added = changed = 0
        for e in entries:
            key = str(e["id"])
            entry = store[kind].get(key)
            before = json.dumps(entry, sort_keys=True) if entry is not None else None
            entry = entry if entry is not None else {"id": e["id"]}
            apply(entry, e)
            store[kind][key] = entry
            if before is None:
                added += 1
            elif before != json.dumps(entry, sort_keys=True):
                changed += 1
        stats[kind] = (added, changed)

    def npc(entry, e):
        _merge_names(entry, e["name"])
        _merge_where(entry, e)
        if "xp_level" in e:
            old = entry.get("xp_level")
            entry["xp_level"] = {
                "min": min(e["xp_level"]["min"], old["min"]) if old else e["xp_level"]["min"],
                "max": max(e["xp_level"]["max"], old["max"]) if old else e["xp_level"]["max"],
                "is_elite": max(e["xp_level"]["is_elite"], old["is_elite"]) if old else e["xp_level"]["is_elite"],
            }
        for faction, react in e.get("obs_react", {}).items():
            entry.setdefault("obs_react", {}).setdefault(faction, react)

    def item(entry, e):
        if "vendors" in e:
            _merge_priced(entry, "vendors", e["vendors"])
        if "drops" in e:
            old = entry.get("drops", {})
            new_drops = {}
            if "sources" in e["drops"]:
                new_drops["sources"] = _union(old.get("sources", []), e["drops"]["sources"])
            elif "range" not in e["drops"]:
                new_drops["sources"] = old.get("sources", [])
            # a level range without mobs says "world drop": the mobs recorded earlier are replaced by it
            ranges = [r for r in (old.get("range"), e["drops"].get("range")) if r]
            if ranges:  # the level range widens
                new_drops["range"] = {"min_xp_level": min(r["min_xp_level"] for r in ranges),
                                      "max_xp_level": max(r["max_xp_level"] for r in ranges)}
            if new_drops:
                entry["drops"] = new_drops
        for key in ("quests", "objects"):
            if key in e:
                entry[key] = _union(entry.get(key, []), e[key])

    def skill(entry, e):
        if "trainers" in e:
            _merge_priced(entry, "trainers", e["trainers"])
        if "min_skill" in e:
            entry.setdefault("min_skill", e["min_skill"])
        if "quests" in e:
            entry["quests"] = _union(entry.get("quests", []), e["quests"])

    def quest(entry, e):
        _merge_names(entry, e["name"])
        if e["npcs"]:
            entry["npcs"] = _union(entry.get("npcs", []), e["npcs"])

    def obj(entry, e):
        _merge_where(entry, e)

    merge("npcs", clean["npcs"], npc)
    merge("items", clean["items"], item)
    merge("skills", clean["skills"], skill)
    merge("quests", clean["quests"], quest)
    merge("objects", clean["objects"], obj)
    if clean["build"] not in store["builds"]:
        store["builds"] = sorted(store["builds"] + [clean["build"]])
    store["imports"] += 1
    return stats


# ---- applying the store to the generated data -------------------------------------------------------

def zone_map(store):
    """map id -> zone id, learned from NPCs and objects that have both (the most frequent pairing wins)."""
    votes = collections.defaultdict(collections.Counter)
    for kind in ("npcs", "objects"):
        for entry in store[kind].values():
            if "map_id" in entry and "zone_id" in entry:
                votes[entry["map_id"]][entry["zone_id"]] += 1
    return {map_id: counter.most_common(1)[0][0] for map_id, counter in votes.items()}


def final_reacts(obs_react):
    """The database's 'reacts' value from what each faction saw. A friendly NPC seen by one faction only is
    credited to that faction, which is a guess until the other faction has seen it too."""
    friendly = {f for f, v in obs_react.items() if v == f}
    if len(friendly) == 2:
        return "Neutral"
    if len(friendly) == 1:
        return next(iter(friendly))
    return "Neutral" if "Neutral" in obs_react.values() else "Hostile"


def _fill_names(names, fallback):
    """Name table for all ten languages. Languages nobody played in get the English (or any known) name."""
    names = names or {}
    default = names.get("English") or next(iter(names.values()), fallback)
    return {locale: names.get(locale, default) for locale in LOCALE_KEYS}


def apply_store(store, skills, items, base_ids, unknown_source, auto_learned, trainer_replaceable=()):
    """Applies the store to the generated entries and returns the report plus the new npcs, quests and objects.

    skills: {profession: [skill entry]}, items: {profession: {item id: item entry}}. Entries are changed in place.
    """
    item_by_id = {i: entry for per_prof in items.values() for i, entry in per_prof.items()}
    skill_by_id = {s["id"]: s for lst in skills.values() for s in lst}
    report = {"items": 0, "skills": 0, "items missing": 0, "skills missing": 0, "npcs known": 0, "guessed faction": 0}

    for key, o in store["items"].items():
        entry = item_by_id.get(int(key))
        if entry is None:
            report["items missing"] += 1
            continue
        if "vendors" in o:
            current = entry.get("vendors", {"sources": []})
            entry["vendors"] = {"sources": _union(current.get("sources", []), o["vendors"]["sources"])}
            price = current.get("price") or o["vendors"].get("price")
            if price:
                entry["vendors"]["price"] = price
        if "drops" in o:
            current = entry.get("drops", {})
            entry["drops"] = dict(current)
            sources = _union(current.get("sources", []), o["drops"].get("sources", []))
            if sources:
                entry["drops"]["sources"] = sources
            if "range" in o["drops"]:  # what Forever shows beats the Classic level range
                entry["drops"]["range"] = o["drops"]["range"]
        for field in ("quests", "objects"):
            if field in o:
                entry[field] = _union(entry.get(field, []), o[field])
        if entry.get("special_action") == unknown_source:
            del entry["special_action"]
        verified = {}
        if "vendors" in o:
            verified["vendors"] = list(o["vendors"]["sources"])
        if o.get("drops", {}).get("sources"):
            verified["drops"] = list(o["drops"]["sources"])
        for field in ("quests", "objects"):
            if field in o:
                verified[field] = list(o[field])
        if verified:
            entry["verified"] = verified
        report["items"] += 1

    for key, o in store["skills"].items():
        entry = skill_by_id.get(int(key))
        if entry is None:
            report["skills missing"] += 1
            continue
        # learned together with the profession: nobody teaches it, whatever a trainer list showed
        taught = entry.get("special_action") != auto_learned
        if "trainers" in o and taught:
            current = entry.get("trainers", {"sources": []})
            entry["trainers"] = {"sources": _union(current.get("sources", []), o["trainers"]["sources"])}
            price = current.get("price") or o["trainers"].get("price")
            if price:
                entry["trainers"]["price"] = price
            entry.setdefault("verified", {})["trainers"] = list(o["trainers"]["sources"])
        if "quests" in o and taught:
            entry["quests"] = _union(entry.get("quests", []), o["quests"])
            entry.setdefault("verified", {})["quests"] = list(o["quests"])
        if entry.get("special_action") == unknown_source:
            del entry["special_action"]
        if "min_skill" in o:
            if "min_skill" not in entry:
                entry["min_skill"] = o["min_skill"]
                report["skill levels learned"] = report.get("skill levels learned", 0) + 1
            elif entry["id"] in trainer_replaceable and entry["min_skill"] != o["min_skill"]:
                # what the trainer asks for in Forever beats the value carried over from Classic
                entry["min_skill"] = o["min_skill"]
                report["skill levels corrected"] = report.get("skill levels corrected", 0) + 1
        report["skills"] += 1

    zones = zone_map(store)
    new_npcs, new_quests, new_objects = [], [], []
    # only NPCs that a source still points to; the store keeps the others (e.g. mobs that a level range replaced)
    referenced = referenced_npcs(store)
    for key in sorted(store["npcs"], key=int):
        o = store["npcs"][key]
        if o["id"] in base_ids["npcs"]:
            report["npcs known"] += 1
            continue
        if o["id"] not in referenced:
            report["npcs left out (no source uses them)"] = report.get("npcs left out (no source uses them)", 0) + 1
            continue
        entry = {"id": o["id"], "name": _fill_names(o.get("name"), f"NPC {o['id']}")}
        zone_id = o.get("zone_id") or zones.get(o.get("map_id"))
        if zone_id and "location" in o:
            entry["location"] = o["location"]
            entry["zone_id"] = zone_id
        else:
            # Coordinates only make sense with a zone. Without one they are coordinates of a continent map (Wowhead
            # lists some NPCs there) and would send the player to the wrong place, so they are left out ("-" is the
            # Base marker for an unknown position)
            entry["location"] = {"x": "-", "y": "-"}
            if zone_id:
                entry["zone_id"] = zone_id
            if "location" in o:
                report["npcs without a zone (coordinates left out)"] = \
                    report.get("npcs without a zone (coordinates left out)", 0) + 1
        if o.get("obs_react"):
            entry["reacts"] = final_reacts(o["obs_react"])
            if len([v for f, v in o["obs_react"].items() if v == f]) == 1 and len(o["obs_react"]) == 1:
                report["guessed faction"] += 1
        if "xp_level" in o:
            entry["xp_level"] = o["xp_level"]
        new_npcs.append(entry)
    for key in sorted(store["quests"], key=int):
        o = store["quests"][key]
        if o["id"] in base_ids["quests"]:
            continue
        entry = {"id": o["id"], "name": _fill_names(o.get("name"), f"Quest {o['id']}")}
        if o.get("npcs"):
            entry["npcs"] = o["npcs"]
        new_quests.append(entry)
    for key in sorted(store["objects"], key=int):
        o = store["objects"][key]
        if o["id"] in base_ids["objects"]:
            continue
        entry = {"id": o["id"], "location": o.get("location", {"x": "-", "y": "-"})}
        if "zone_id" in o:
            entry["zone_id"] = o["zone_id"]
        elif o.get("map_id") in zones:
            entry["zone_id"] = zones[o["map_id"]]
        new_objects.append(entry)
    return report, new_npcs, new_quests, new_objects


def _unverified_sources(entry):
    """True while the entry lists a source that no player has seen in Forever (so it still comes from Classic only)."""
    verified = entry.get("verified", {})
    for kind in ("vendors", "drops", "trainers"):
        if kind in entry and set(entry[kind].get("sources", [])) - set(verified.get(kind, [])):
            return True
    for kind in ("quests", "objects"):
        if kind in entry and set(entry[kind]) - set(verified.get(kind, [])):
            return True
    return False


def settle_classic_flags(skills, items, unverifiable_skills, unverifiable_items):
    """Drops the `classic_source` warning flag from entries whose Classic sources have all been confirmed.

    A source counts as confirmed when it is in the entry's `verified` lists (a player saw it in Forever).
    Carried facts the recorder cannot observe (holidays, special actions, level-range drops, reputation taken from
    Classic) keep the flag: unverifiable_* hold the ids of such entries.
    """
    cleared = 0
    for per_prof in items.values():
        for item_id, entry in per_prof.items():
            if entry.get("classic_source") and item_id not in unverifiable_items and not _unverified_sources(entry):
                del entry["classic_source"]
                cleared += 1
    for lst in skills.values():
        for entry in lst:
            if entry.get("classic_source") and entry["id"] not in unverifiable_skills and not _unverified_sources(entry):
                del entry["classic_source"]
                cleared += 1
    return cleared
