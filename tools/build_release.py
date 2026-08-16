import os
import re
import sys
import zipfile
import shutil

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC_CLASSIC = os.path.join(ROOT_DIR, "RecipeRadar.toc")
TOC_BCC = os.path.join(ROOT_DIR, "RecipeRadar-BCC.toc")
CONSTANTS_FILE = os.path.join(ROOT_DIR, "Core", "Constants.lua")
ANNIVERSARY_DIR = r"C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\RecipeRadar"

def get_current_version():
    if os.path.exists(TOC_CLASSIC):
        with open(TOC_CLASSIC, "r", encoding="utf-8") as f:
            for line in f:
                m = re.match(r"^##\s*Version:\s*([^\s]+)", line.strip())
                if m:
                    return m.group(1)
    return "1.0.0"

def bump_semver(ver_str, bump_type="patch"):
    parts = ver_str.split(".")
    major = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else 1
    minor = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
    patch = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
    
    if bump_type == "major":
        return f"{major + 1}.0.0"
    elif bump_type == "minor":
        return f"{major}.{minor + 1}.0"
    else:  # patch
        return f"{major}.{minor}.{patch + 1}"

def update_file_version(filepath, pattern, replacement):
    if not os.path.exists(filepath):
        return
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    new_content = re.sub(pattern, replacement, content)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(new_content)

def sync_to_anniversary():
    if os.path.exists(ANNIVERSARY_DIR):
        print("Synchronizing updated files to _anniversary_...")
        for root, dirs, files in os.walk(ROOT_DIR):
            rel = os.path.relpath(root, ROOT_DIR)
            if rel.startswith(".git"):
                continue
            dst_root = os.path.join(ANNIVERSARY_DIR, rel) if rel != "." else ANNIVERSARY_DIR
            os.makedirs(dst_root, exist_ok=True)
            for file in files:
                src_file = os.path.join(root, file)
                dst_file = os.path.join(dst_root, file)
                shutil.copy2(src_file, dst_file)

def main():
    cur_ver = get_current_version()
    print(f"==================================================")
    print(f" RecipeRadar Release Builder & Version Bumper")
    print(f"==================================================")
    print(f"Current version: {cur_ver}")

    # Determine target version
    target_ver = None
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in ("patch", "minor", "major"):
            target_ver = bump_semver(cur_ver, arg)
        elif re.match(r"^\d+\.\d+(\.\d+)?$", sys.argv[1]):
            target_ver = sys.argv[1]
        else:
            target_ver = bump_semver(cur_ver, "patch")
    else:
        # Default to patch bump when running without arguments
        suggested = bump_semver(cur_ver, "patch")
        target_ver = suggested

    print(f"New release version: {target_ver}")
    print("Updating version in TOC and Lua files...")

    # 1. Update RecipeRadar.toc
    update_file_version(
        TOC_CLASSIC,
        r"(##\s*Version:\s*)([^\s\r\n]+)",
        rf"\g<1>{target_ver}"
    )

    # 2. Update RecipeRadar-BCC.toc
    update_file_version(
        TOC_BCC,
        r"(##\s*Version:\s*)([^\s\r\n]+)",
        rf"\g<1>{target_ver}"
    )

    # 3. Update Core/Constants.lua
    update_file_version(
        CONSTANTS_FILE,
        r'(RR\.VERSION\s*=\s*")[^"]+(")',
        rf'\g<1>{target_ver}\g<2>'
    )

    # 4. Sync to anniversary
    sync_to_anniversary()

    # 5. Build clean zip for CurseForge
    zip_name = f"RecipeRadar-v{target_ver}.zip"
    zip_path = os.path.join(ROOT_DIR, zip_name)

    EXCLUDE_DIRS = {".git", ".vscode", "tools", "__pycache__"}
    EXCLUDE_EXTS = {".py", ".pyc", ".tmp", ".bat", ".sh"}
    EXCLUDE_FILES = {"ToDos.md", ".gitignore", ".gitattributes"}

    print(f"Packaging {zip_name} for CurseForge...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(ROOT_DIR):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            rel_root = os.path.relpath(root, ROOT_DIR)
            for file in files:
                _, ext = os.path.splitext(file)
                if ext in EXCLUDE_EXTS or file in EXCLUDE_FILES:
                    continue
                if file.endswith(".zip"):
                    continue
                abs_path = os.path.join(root, file)
                archive_name = os.path.join("RecipeRadar", rel_root, file) if rel_root != "." else os.path.join("RecipeRadar", file)
                archive_name = archive_name.replace("\\", "/")
                zf.write(abs_path, archive_name)

    size_kb = os.path.getsize(zip_path) / 1024
    print(f"--------------------------------------------------")
    print(f"SUCCESS: Release created successfully!")
    print(f"File: {zip_name}")
    print(f"Size: {size_kb:.1f} KB")
    print(f"Version: {target_ver} applied to TOCs and Constants.")
    print(f"==================================================")

if __name__ == "__main__":
    main()
