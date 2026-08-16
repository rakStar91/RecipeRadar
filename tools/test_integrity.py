import re
import glob

def test_validation():
    print("=== AUTOMATED DATABASE INTEGRITY TEST ===")
    
    # 1. Check Classic Era Skills
    classic_orig_text = open("Database/Classic/Skills.lua", encoding="utf-8").read()
    orig_c_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', classic_orig_text))
    
    base_skills_text = ""
    for f in glob.glob("Database/Base/**/skills.lua", recursive=True):
        base_skills_text += open(f, encoding="utf-8").read() + "\n"
    new_c_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', base_skills_text))
    
    print(f"Classic Skills: Orig={len(orig_c_ids)}, New Base={len(new_c_ids)}")
    assert orig_c_ids == new_c_ids, f"Classic skill mismatch: {orig_c_ids ^ new_c_ids}"
    print("  -> Base Skills match 100% with Classic original!")

    # 2. Check Classic Era Items
    classic_orig_items = open("Database/Classic/Items.lua", encoding="utf-8").read()
    orig_item_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', classic_orig_items))
    
    base_items_text = ""
    for f in glob.glob("Database/Base/**/items.lua", recursive=True):
        base_items_text += open(f, encoding="utf-8").read() + "\n"
    new_item_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', base_items_text))
    
    print(f"Classic Items: Orig={len(orig_item_ids)}, New Base={len(new_item_ids)}")
    assert orig_item_ids == new_item_ids, f"Classic item mismatch: {orig_item_ids ^ new_item_ids}"
    print("  -> Base Items match 100% with Classic original!")

    # 3. Check Classic Era Levels
    classic_orig_levels = open("Database/Classic/Levels.lua", encoding="utf-8").read()
    orig_level_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', classic_orig_levels))
    
    base_levels_text = ""
    for f in glob.glob("Database/Base/**/levels.lua", recursive=True):
        base_levels_text += open(f, encoding="utf-8").read() + "\n"
    new_level_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', base_levels_text))
    
    print(f"Classic Levels: Orig={len(orig_level_ids)}, New Base={len(new_level_ids)}")
    assert orig_level_ids == new_level_ids, f"Classic level mismatch: {orig_level_ids ^ new_level_ids}"
    print("  -> Base Levels match 100% with Classic original!")

    # 4. Check Classic Era Specialisations
    classic_orig_specs = open("Database/Classic/Specialisations.lua", encoding="utf-8").read()
    orig_spec_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', classic_orig_specs))
    
    base_specs_text = ""
    for f in glob.glob("Database/Base/**/specialisations.lua", recursive=True):
        base_specs_text += open(f, encoding="utf-8").read() + "\n"
    new_spec_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', base_specs_text))
    
    print(f"Classic Specialisations: Orig={len(orig_spec_ids)}, New Base={len(new_spec_ids)}")
    assert orig_spec_ids == new_spec_ids, f"Classic spec mismatch: {orig_spec_ids ^ new_spec_ids}"
    print("  -> Base Specialisations match 100% with Classic original!")

    # 5. Check TBC Merged Total Skills
    tbc_orig_skills_text = ""
    for f in glob.glob("Database/TBC/**/skills.lua", recursive=True):
        tbc_orig_skills_text += open(f, encoding="utf-8").read() + "\n"
    orig_tbc_skill_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', tbc_orig_skills_text))

    merged_tbc_skills_text = base_skills_text
    for f in glob.glob("Database/Expansions/TBC/**/skills.lua", recursive=True):
        merged_tbc_skills_text += open(f, encoding="utf-8").read() + "\n"
    new_merged_tbc_skill_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', merged_tbc_skills_text))

    print(f"TBC Merged Skills: Orig={len(orig_tbc_skill_ids)}, New Merged={len(new_merged_tbc_skill_ids)}")
    assert orig_tbc_skill_ids.issubset(new_merged_tbc_skill_ids), f"Missing TBC skills: {orig_tbc_skill_ids - new_merged_tbc_skill_ids}"
    print("  -> Base + TBC Delta Skills contain 100% of all TBC skills!")

    # 6. Check TBC Merged Total NPCs
    tbc_orig_npcs_text = open("Database/TBC/npcs.lua", encoding="utf-8").read()
    orig_tbc_npc_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', tbc_orig_npcs_text))

    merged_npc_text = open("Database/Base/npcs.lua", encoding="utf-8").read() + open("Database/Expansions/TBC/npcs.lua", encoding="utf-8").read()
    new_merged_npc_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', merged_npc_text))

    print(f"TBC Merged NPCs: Orig={len(orig_tbc_npc_ids)}, New Merged={len(new_merged_npc_ids)}")
    assert orig_tbc_npc_ids.issubset(new_merged_npc_ids), f"NPC missing in TBC: {orig_tbc_npc_ids - new_merged_npc_ids}"
    print("  -> Base + TBC Delta NPCs contain 100% of all TBC NPCs!")

    # 7. Check TBC Merged Total Quests
    tbc_orig_quests_text = open("Database/TBC/quests.lua", encoding="utf-8").read()
    orig_tbc_quest_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', tbc_orig_quests_text))

    merged_quest_text = open("Database/Base/quests.lua", encoding="utf-8").read() + open("Database/Expansions/TBC/quests.lua", encoding="utf-8").read()
    new_merged_quest_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', merged_quest_text))

    print(f"TBC Merged Quests: Orig={len(orig_tbc_quest_ids)}, New Merged={len(new_merged_quest_ids)}")
    assert orig_tbc_quest_ids.issubset(new_merged_quest_ids), f"Quest missing in TBC: {orig_tbc_quest_ids - new_merged_quest_ids}"
    print("  -> Base + TBC Delta Quests contain 100% of all TBC Quests!")

    # 8. Check TBC Merged Total Zones
    tbc_orig_zones_text = open("Database/TBC/zones.lua", encoding="utf-8").read()
    orig_tbc_zone_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', tbc_orig_zones_text))

    merged_zone_text = open("Database/Base/zones.lua", encoding="utf-8").read() + open("Database/Expansions/TBC/zones.lua", encoding="utf-8").read()
    new_merged_zone_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', merged_zone_text))

    print(f"TBC Merged Zones: Orig={len(orig_tbc_zone_ids)}, New Merged={len(new_merged_zone_ids)}")
    assert orig_tbc_zone_ids.issubset(new_merged_zone_ids), f"Zone missing in TBC: {orig_tbc_zone_ids - new_merged_zone_ids}"
    print("  -> Base + TBC Delta Zones contain 100% of all TBC Zones!")

    # 9. Check TBC Merged Total Factions
    tbc_orig_factions_text = open("Database/TBC/factions.lua", encoding="utf-8").read()
    orig_tbc_fac_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', tbc_orig_factions_text))

    merged_fac_text = open("Database/Base/factions.lua", encoding="utf-8").read() + open("Database/Expansions/TBC/factions.lua", encoding="utf-8").read()
    new_merged_fac_ids = set(re.findall(r'\["id"\]\s*=\s*(\d+)', merged_fac_text))

    print(f"TBC Merged Factions: Orig={len(orig_tbc_fac_ids)}, New Merged={len(new_merged_fac_ids)}")
    assert orig_tbc_fac_ids.issubset(new_merged_fac_ids), f"Faction missing in TBC: {orig_tbc_fac_ids - new_merged_fac_ids}"
    print("  -> Base + TBC Delta Factions contain 100% of all TBC Factions!")

    print("\nALL INTEGRITY CHECKS PASSED 100%!")

if __name__ == "__main__":
    test_validation()
