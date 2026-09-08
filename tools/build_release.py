import os
import re
import sys
import zipfile

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC_CLASSIC = os.path.join(ROOT_DIR, "RecipeRadar.toc")
TOC_BCC = os.path.join(ROOT_DIR, "RecipeRadar-BCC.toc")
CONSTANTS_FILE = os.path.join(ROOT_DIR, "Core", "Constants.lua")

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
    with open(filepath, "r", encoding="utf-8", newline="") as f:
        content = f.read()
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        with open(filepath, "w", encoding="utf-8", newline="") as f:
            f.write(new_content)

def main():
    cur_ver = get_current_version()
    print("==================================================")
    print(" RecipeRadar Release Builder")
    print("==================================================")
    print(f"Current version: {cur_ver}")

    # Determine target version
    target_ver = cur_ver
    is_bump = False

    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in ("patch", "minor", "major"):
            target_ver = bump_semver(cur_ver, arg)
            is_bump = True
        elif re.match(r"^\d+\.\d+(\.\d+)?$", sys.argv[1]):
            target_ver = sys.argv[1]
            if target_ver != cur_ver:
                is_bump = True
        elif arg in ("current", "rebuild", "build"):
            target_ver = cur_ver
            is_bump = False
        else:
            print(f"Unknown argument '{sys.argv[1]}'.")
            print("Usage: build_release.py [current | patch | minor | major | <version>]")
            return
    else:
        # Default behavior: build current version without bumping
        target_ver = cur_ver
        is_bump = False

    if is_bump:
        print(f"Bumping release version: {cur_ver} -> {target_ver}")
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
    else:
        print(f"Packaging current version v{target_ver} (no version bump)...")

    # Build clean zip for CurseForge
    zip_name = f"RecipeRadar-v{target_ver}.zip"
    zip_path = os.path.join(ROOT_DIR, zip_name)

    EXCLUDE_DIRS = {".git", ".vscode", ".agents", "tools", "__pycache__"}
    EXCLUDE_EXTS = {".py", ".pyc", ".tmp", ".bat", ".sh", ".jpg", ".png"}
    EXCLUDE_FILES = {"ToDos.md", ".gitignore", ".gitattributes", ".pkgmeta"}

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
    print("--------------------------------------------------")
    print("SUCCESS: Release created successfully!")
    print(f"File: {zip_name}")
    print(f"Size: {size_kb:.1f} KB")
    print(f"Version: {target_ver}")
    print("==================================================")

if __name__ == "__main__":
    main()
