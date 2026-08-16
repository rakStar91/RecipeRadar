import os
import re
import zipfile
import shutil

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC_FILE = os.path.join(ROOT_DIR, "RecipeRadar.toc")

# Read version from TOC
version = "1.0.0"
if os.path.exists(TOC_FILE):
    with open(TOC_FILE, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^##\s*Version:\s*([^\s]+)", line.strip())
            if m:
                version = m.group(1)
                break

zip_name = f"RecipeRadar-v{version}.zip"
zip_path = os.path.join(ROOT_DIR, zip_name)

# Exclude patterns
EXCLUDE_DIRS = {".git", ".vscode", "tools", "__pycache__"}
EXCLUDE_EXTS = {".py", ".pyc", ".tmp", ".bat", ".sh"}
EXCLUDE_FILES = {"ToDos.md", ".gitignore", ".gitattributes"}

print(f"=== Packaging RecipeRadar v{version} for CurseForge ===")

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(ROOT_DIR):
        # Filter out directories
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        rel_root = os.path.relpath(root, ROOT_DIR)
        
        for file in files:
            _, ext = os.path.splitext(file)
            if ext in EXCLUDE_EXTS or file in EXCLUDE_FILES:
                continue
            if file == zip_name or file.endswith(".zip"):
                continue
            
            abs_path = os.path.join(root, file)
            # In zip, everything goes into RecipeRadar/...
            archive_name = os.path.join("RecipeRadar", rel_root, file) if rel_root != "." else os.path.join("RecipeRadar", file)
            archive_name = archive_name.replace("\\", "/")
            
            zf.write(abs_path, archive_name)

print(f"SUCCESS: Package created at {zip_name} (Size: {os.path.getsize(zip_path) / 1024:.1f} KB)")
