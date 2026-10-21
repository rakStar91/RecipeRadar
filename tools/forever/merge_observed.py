"""Merges source exports of RecipeRadar's recorder (/rr export) into tools/forever/observed/observed.json.

    python merge_observed.py export1.lua [export2.lua ...] [--dry-run] [--store PATH] [--allow-build]

Each export is checked first: format, Forever build, ids of known recipe items and spells, coordinates,
names. Invalid parts are skipped with a warning, the rest is merged without creating duplicates. Run
`python build_forever.py` afterwards to put the merged sources into Database/Forever.
"""
import argparse
import sys

from lua_tables import read_assignment
from observed import STORE_PATH, clean_export, load_base_ids, load_known, load_store, merge_into_store, save_store, zone_map


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("exports", nargs="+", help="export files (the text from /rr export saved as a file)")
    ap.add_argument("--store", default=STORE_PATH)
    ap.add_argument("--dry-run", action="store_true", help="check and report, do not write the store")
    ap.add_argument("--allow-build", action="store_true", help="accept exports from a build other than 1.60.*")
    args = ap.parse_args()

    known_items, known_spells = load_known()
    store = load_store(args.store)
    failed = 0
    for path in args.exports:
        try:
            with open(path, encoding="utf-8") as f:
                parsed = [table for _, table in read_assignment(f.read(), r"RR_OBSERVED")]
            if len(parsed) != 1:
                raise ValueError("expected exactly one RR_OBSERVED table")
            clean, warnings = clean_export(parsed[0], known_items, known_spells, args.allow_build)
        except (OSError, ValueError, KeyError, IndexError) as error:
            print(f"{path}: REJECTED - {error}")
            failed += 1
            continue
        stats = merge_into_store(store, clean)
        summary = ", ".join(f"{kind} +{new}/~{changed}" for kind, (new, changed) in stats.items())
        print(f"{path}: build {clean['build']} merged ({summary}; + new, ~ extended)")
        for warning in warnings[:10]:
            print(f"   warning: {warning}")
        if len(warnings) > 10:
            print(f"   ... and {len(warnings) - 10} more warnings")

    zones = zone_map(store)
    unresolved = sorted({f"{n.get('zone_name', '?')} (map {n['map_id']})" for n in store["npcs"].values()
                         if "zone_id" not in n and "location" in n and n.get("map_id") not in zones})
    if unresolved:
        print(f"{len(unresolved)} zone(s) without a RecipeRadar zone id (NPCs there show no zone): {', '.join(unresolved)}")
    # Only NPCs and quests that Database/Base does not have need names from players; Base entries already have all 10 languages
    base = load_base_ids()
    named = [e for e in store["npcs"].values() if e["id"] not in base["npcs"]] \
        + [e for e in store["quests"].values() if e["id"] not in base["quests"]]
    no_english = sum(1 for e in named if "English" not in e.get("name", {}))
    if no_english:
        print(f"{no_english} new NPC/quest name(s) have no English name yet. Other languages show the name that is known until "
              f"someone exports from a client in that language (the game only gives the names of its own language).")
    print(f"store: {len(store['npcs'])} npcs, {len(store['items'])} items, {len(store['skills'])} skills, "
          f"{len(store['quests'])} quests, {len(store['objects'])} objects from {store['imports']} export(s)")
    if args.dry_run:
        print("dry run: store not written")
    elif failed < len(args.exports):
        save_store(store, args.store)
        print(f"written: {args.store}\nnext: python build_forever.py")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
