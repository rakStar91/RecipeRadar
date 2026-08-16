import os

def check_toc(toc_file):
    print(f"=== Checking TOC: {toc_file} ===")
    missing = []
    total = 0
    with open(toc_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.endswith(".lua"):
                total += 1
                # Normalize path
                norm_path = os.path.normpath(line)
                if not os.path.exists(norm_path):
                    missing.append(norm_path)
    
    print(f"Total lua files referenced: {total}")
    if missing:
        print(f"ERROR: Missing files in {toc_file}:")
        for m in missing:
            print(f"  - {m}")
        return False
    else:
        print("All files exist and are valid!")
        return True

if __name__ == "__main__":
    t1 = check_toc("RecipeRadar.toc")
    t2 = check_toc("RecipeRadar-BCC.toc")
    if t1 and t2:
        print("\nSUCCESS: All TOC files verified 100%!")
    else:
        exit(1)
