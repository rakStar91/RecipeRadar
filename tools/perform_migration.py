import os
import re
import shutil
import glob

BASE_DIR = "Database/Base"
TBC_DIR = "Database/Expansions/TBC"

PROF_FOLDER_TO_KEY = {
    "Alchemy": "Alchemy",
    "Blacksmithing": "Blacksmithing",
    "Cooking": "Cooking",
    "Enchanting": "Enchanting",
    "Engineering": "Engineering",
    "FirstAid": "First Aid",
    "Fishing": "Fishing",
    "Herbalism": "Herbalism",
    "Jewelcrafting": "Jewelcrafting",
    "Leatherworking": "Leatherworking",
    "Mining": "Mining",
    "Poisons": "Poisons",
    "Skinning": "Skinning",
    "Tailoring": "Tailoring",
}

def parse_lua_entries(content):
    first_brace = content.find("{")
    last_brace = content.rfind("}")
    if first_brace == -1 or last_brace == -1:
        return []
    
    body = content[first_brace+1:last_brace]
    lines = body.splitlines(True)
    entries = []
    current_entry = []
    depth = 0
    in_entry = False

    for line in lines:
        stripped = line.strip()
        if not in_entry:
            if stripped == "{" or stripped.startswith("{"):
                in_entry = True
                depth = line.count("{") - line.count("}")
                current_entry = [line]
                if depth == 0:
                    entries.append("".join(current_entry))
                    in_entry = False
                    current_entry = []
        else:
            current_entry.append(line)
            depth += line.count("{") - line.count("}")
            if depth <= 0:
                entries.append("".join(current_entry))
                in_entry = False
                current_entry = []
                depth = 0

    return entries

def extract_id(entry_str):
    m = re.search(r'\["id"\]\s*=\s*(\d+)', entry_str)
    return int(m.group(1)) if m else None

def extract_expansion(entry_str):
    m = re.search(r'\["expansion"\]\s*=\s*(\d+)', entry_str)
    return int(m.group(1)) if m else None

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def run():
    print("=== STARTING FULL DATABASE MIGRATION ===")
    
    if os.path.exists(BASE_DIR):
        shutil.rmtree(BASE_DIR)
    if os.path.exists(TBC_DIR):
        shutil.rmtree(TBC_DIR)

    # 1. Global Variables for Base
    write_file(f"{BASE_DIR}/global_variables.lua", """-------------------------------------------------------
-- RecipeRadar: Database/Base/global_variables.lua
-- Central database storage table
-------------------------------------------------------
RR_DATA = {
    ["continents"] = {},
    ["currencies"] = {},
    ["factions"] = {},
    ["holidays"] = {},
    ["items"] = {},
    ["levels"] = {},
    ["npcs"] = {},
    ["objects"] = {},
    ["profession_ranks"] = {},
    ["professions"] = {},
    ["quests"] = {},
    ["reputation_levels"] = {},
    ["skills"] = {},
    ["special_actions"] = {},
    ["specialisations"] = {},
    ["spell_to_item"] = {},
    ["zones"] = {},
}
""")

    # 2. Base Global Files
    global_files_classic = {
        "Continents.lua": "continents.lua",
        "Factions.lua": "factions.lua",
        "Holidays.lua": "holidays.lua",
        "NPCs.lua": "npcs.lua",
        "Objects.lua": "objects.lua",
        "ProfessionRanks.lua": "profession_ranks.lua",
        "Professions.lua": "professions.lua",
        "Quests.lua": "quests.lua",
        "Reputations.lua": "reputation_levels.lua",
        "SpecialActions.lua": "special_actions.lua",
        "SpellItems.lua": "spell_items.lua",
        "Zones.lua": "zones.lua",
    }

    for src_name, dst_name in global_files_classic.items():
        src_path = f"Database/Classic/{src_name}"
        if os.path.exists(src_path):
            content = open(src_path, encoding="utf-8").read()
            write_file(f"{BASE_DIR}/{dst_name}", content)
            print(f"Migrated Base global: {dst_name}")

    # 3. Base Skills (from Classic Skills.lua)
    classic_skills_raw = open("Database/Classic/Skills.lua", encoding="utf-8").read()
    for folder, key in PROF_FOLDER_TO_KEY.items():
        if folder == "Jewelcrafting": continue
        pattern = r'\["' + re.escape(key) + r'"\]\s*=\s*\{'
        m = re.search(pattern, classic_skills_raw)
        if m:
            start_pos = m.end() - 1
            depth = 0
            end_pos = start_pos
            for i in range(start_pos, len(classic_skills_raw)):
                if classic_skills_raw[i] == '{': depth += 1
                elif classic_skills_raw[i] == '}':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        break
            prof_block = classic_skills_raw[start_pos:end_pos]
            write_file(f"{BASE_DIR}/{folder}/skills.lua", f"""-------------------------------------------------------
-- All skills ({key}) - Classic Era
-------------------------------------------------------
RR_DATA["skills"]["{key}"] = {prof_block}
""")
            print(f"Created Base skills: {folder}/skills.lua")

    # 4. Base Items (from Classic Items.lua)
    classic_items_raw = open("Database/Classic/Items.lua", encoding="utf-8").read()
    for folder, key in PROF_FOLDER_TO_KEY.items():
        if folder == "Jewelcrafting": continue
        pattern = r'\["' + re.escape(key) + r'"\]\s*=\s*\{'
        m = re.search(pattern, classic_items_raw)
        if m:
            start_pos = m.end() - 1
            depth = 0
            end_pos = start_pos
            for i in range(start_pos, len(classic_items_raw)):
                if classic_items_raw[i] == '{': depth += 1
                elif classic_items_raw[i] == '}':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        break
            prof_block = classic_items_raw[start_pos:end_pos]
            write_file(f"{BASE_DIR}/{folder}/items.lua", f"""-------------------------------------------------------
-- All items ({key}) - Classic Era
-------------------------------------------------------
RR_DATA["items"]["{key}"] = {prof_block}
""")
            print(f"Created Base items: {folder}/items.lua")

    # 5. Base Levels (from Classic Levels.lua)
    classic_levels_raw = open("Database/Classic/Levels.lua", encoding="utf-8").read()
    for folder, key in PROF_FOLDER_TO_KEY.items():
        if folder == "Jewelcrafting": continue
        pattern = r'\["' + re.escape(key) + r'"\]\s*=\s*\{'
        m = re.search(pattern, classic_levels_raw)
        if m:
            start_pos = m.end() - 1
            depth = 0
            end_pos = start_pos
            for i in range(start_pos, len(classic_levels_raw)):
                if classic_levels_raw[i] == '{': depth += 1
                elif classic_levels_raw[i] == '}':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        break
            prof_block = classic_levels_raw[start_pos:end_pos]
            write_file(f"{BASE_DIR}/{folder}/levels.lua", f"""-------------------------------------------------------
-- All levels ({key}) - Classic Era
-------------------------------------------------------
RR_DATA["levels"]["{key}"] = {prof_block}
""")
            print(f"Created Base levels: {folder}/levels.lua")

    # 6. Base Specialisations (from Classic Specialisations.lua)
    classic_specs_raw = open("Database/Classic/Specialisations.lua", encoding="utf-8").read()
    for folder, key in PROF_FOLDER_TO_KEY.items():
        pattern = r'\["' + re.escape(key) + r'"\]\s*=\s*\{'
        m = re.search(pattern, classic_specs_raw)
        if m:
            start_pos = m.end() - 1
            depth = 0
            end_pos = start_pos
            for i in range(start_pos, len(classic_specs_raw)):
                if classic_specs_raw[i] == '{': depth += 1
                elif classic_specs_raw[i] == '}':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        break
            prof_block = classic_specs_raw[start_pos:end_pos]
            write_file(f"{BASE_DIR}/{folder}/specialisations.lua", f"""-------------------------------------------------------
-- Specialisations ({key}) - Classic Era
-------------------------------------------------------
RR_DATA["specialisations"]["{key}"] = {prof_block}
""")
            print(f"Created Base specialisations: {folder}/specialisations.lua")

    # ----------------------------------------------------
    # TBC DELTAS GENERATION
    # ----------------------------------------------------
    print("\n--- Generating TBC Expansion Deltas ---")

    write_file(f"{TBC_DIR}/continents.lua", open("Database/TBC/continents.lua", encoding="utf-8").read())
    write_file(f"{TBC_DIR}/currencies.lua", open("Database/TBC/currencies.lua", encoding="utf-8").read())
    write_file(f"{TBC_DIR}/data_tbc.lua", open("Database/TBC/data_tbc.lua", encoding="utf-8").read())

    def create_delta_table(src_tbc_path, classic_id_source_path, dest_path, table_name, file_header):
        tbc_content = open(src_tbc_path, encoding="utf-8").read()
        classic_content = open(classic_id_source_path, encoding="utf-8").read() if classic_id_source_path else ""
        classic_ids = set(int(x) for x in re.findall(r'\["id"\]\s*=\s*(\d+)', classic_content))
        
        entries = parse_lua_entries(tbc_content)
        delta_entries = []
        for e in entries:
            eid = extract_id(e)
            exp = extract_expansion(e)
            if exp == 2 or (eid is not None and eid not in classic_ids):
                delta_entries.append(e.strip())

        print(f"TBC Delta {table_name}: {len(delta_entries)} new entries (out of {len(entries)} total in TBC)")
        body = ",\n\t".join(delta_entries)
        out = f"""-------------------------------------------------------
-- {file_header} - The Burning Crusade Delta
-------------------------------------------------------
local tbc_{table_name} = 
{{
\t{body}
}}

for _, entry in ipairs(tbc_{table_name}) do
\ttable.insert(RR_DATA["{table_name}"], entry)
end
"""
        write_file(dest_path, out)

    create_delta_table("Database/TBC/npcs.lua", "Database/Classic/NPCs.lua", f"{TBC_DIR}/npcs.lua", "npcs", "All npcs")
    create_delta_table("Database/TBC/quests.lua", "Database/Classic/Quests.lua", f"{TBC_DIR}/quests.lua", "quests", "All quests")
    create_delta_table("Database/TBC/zones.lua", "Database/Classic/Zones.lua", f"{TBC_DIR}/zones.lua", "zones", "All zones")
    create_delta_table("Database/TBC/factions.lua", "Database/Classic/Factions.lua", f"{TBC_DIR}/factions.lua", "factions", "All factions")

    # Jewelcrafting (Whole profession goes into TBC)
    for jc_file in ["skills.lua", "items.lua", "levels.lua"]:
        src_jc = f"Database/TBC/Jewelcrafting/{jc_file}"
        if os.path.exists(src_jc):
            write_file(f"{TBC_DIR}/Jewelcrafting/{jc_file}", open(src_jc, encoding="utf-8").read())
            print(f"Copied full Jewelcrafting: {jc_file}")

    # Profession Deltas (Skills, Items, Levels, Specialisations)
    for folder, key in PROF_FOLDER_TO_KEY.items():
        if folder == "Jewelcrafting": continue

        # Skills Delta (Find anything with expansion == 2 or not in Base)
        src_skills = f"Database/TBC/{folder}/skills.lua"
        base_skills_path = f"{BASE_DIR}/{folder}/skills.lua"
        base_skill_ids = set()
        if os.path.exists(base_skills_path):
            base_skill_ids = set(int(x) for x in re.findall(r'\["id"\]\s*=\s*(\d+)', open(base_skills_path, encoding="utf-8").read()))

        if os.path.exists(src_skills):
            entries = parse_lua_entries(open(src_skills, encoding="utf-8").read())
            delta = [e.strip() for e in entries if extract_expansion(e) == 2 or (extract_id(e) is not None and extract_id(e) not in base_skill_ids)]
            if delta:
                body = ",\n\t".join(delta)
                out = f"""-------------------------------------------------------
-- All skills ({key}) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["skills"]["{key}"] then RR_DATA["skills"]["{key}"] = {{}} end
local tbc_skills = 
{{
\t{body}
}}

for _, skill in ipairs(tbc_skills) do
\ttable.insert(RR_DATA["skills"]["{key}"], skill)
end
"""
                write_file(f"{TBC_DIR}/{folder}/skills.lua", out)
                print(f"Created TBC Delta skills: {folder}/skills.lua ({len(delta)} skills)")

        # Items Delta
        src_items = f"Database/TBC/{folder}/items.lua"
        base_items_path = f"{BASE_DIR}/{folder}/items.lua"
        base_item_ids = set()
        if os.path.exists(base_items_path):
            base_item_ids = set(int(x) for x in re.findall(r'\["id"\]\s*=\s*(\d+)', open(base_items_path, encoding="utf-8").read()))

        if os.path.exists(src_items):
            entries = parse_lua_entries(open(src_items, encoding="utf-8").read())
            delta = [e.strip() for e in entries if extract_expansion(e) == 2 or (extract_id(e) is not None and extract_id(e) not in base_item_ids)]
            if delta:
                body = ",\n\t".join(delta)
                out = f"""-------------------------------------------------------
-- All items ({key}) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["items"]["{key}"] then RR_DATA["items"]["{key}"] = {{}} end
local tbc_items = 
{{
\t{body}
}}

for _, item in ipairs(tbc_items) do
\ttable.insert(RR_DATA["items"]["{key}"], item)
end
"""
                write_file(f"{TBC_DIR}/{folder}/items.lua", out)
                print(f"Created TBC Delta items: {folder}/items.lua ({len(delta)} items)")

        # Levels Delta
        src_levels = f"Database/TBC/{folder}/levels.lua"
        base_levels_path = f"{BASE_DIR}/{folder}/levels.lua"
        base_level_ids = set()
        if os.path.exists(base_levels_path):
            base_level_ids = set(int(x) for x in re.findall(r'\["id"\]\s*=\s*(\d+)', open(base_levels_path, encoding="utf-8").read()))

        if os.path.exists(src_levels):
            entries = parse_lua_entries(open(src_levels, encoding="utf-8").read())
            delta = [e.strip() for e in entries if extract_expansion(e) == 2 or (extract_id(e) is not None and extract_id(e) not in base_level_ids)]
            if delta:
                body = ",\n\t".join(delta)
                out = f"""-------------------------------------------------------
-- All levels ({key}) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["{key}"] then RR_DATA["levels"]["{key}"] = {{}} end
local tbc_levels = 
{{
\t{body}
}}

for _, level in ipairs(tbc_levels) do
\ttable.insert(RR_DATA["levels"]["{key}"], level)
end
"""
                write_file(f"{TBC_DIR}/{folder}/levels.lua", out)
                print(f"Created TBC Delta levels: {folder}/levels.lua ({len(delta)} levels)")

        # Specialisations Delta
        src_specs = f"Database/TBC/{folder}/specialisations.lua"
        base_specs_path = f"{BASE_DIR}/{folder}/specialisations.lua"
        base_spec_ids = set()
        if os.path.exists(base_specs_path):
            base_spec_ids = set(int(x) for x in re.findall(r'\["id"\]\s*=\s*(\d+)', open(base_specs_path, encoding="utf-8").read()))

        if os.path.exists(src_specs):
            entries = parse_lua_entries(open(src_specs, encoding="utf-8").read())
            delta = [e.strip() for e in entries if extract_expansion(e) == 2 or (extract_id(e) is not None and extract_id(e) not in base_spec_ids)]
            if delta:
                body = ",\n\t".join(delta)
                out = f"""-------------------------------------------------------
-- Specialisations ({key}) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["specialisations"]["{key}"] then RR_DATA["specialisations"]["{key}"] = {{}} end
local tbc_specs = 
{{
\t{body}
}}

for _, spec in ipairs(tbc_specs) do
\ttable.insert(RR_DATA["specialisations"]["{key}"], spec)
end
"""
                write_file(f"{TBC_DIR}/{folder}/specialisations.lua", out)
                print(f"Created TBC Delta specs: {folder}/specialisations.lua ({len(delta)} specs)")

    print("\n=== MIGRATION GENERATION COMPLETE ===")

if __name__ == "__main__":
    run()
