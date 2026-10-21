"""Merges recorder exports into the Forever database.

    python update.py export.lua [more.lua ...]
"""
import subprocess
import sys

if len(sys.argv) < 2:
    sys.exit(__doc__)

for command in ([sys.executable, "merge_observed.py", *sys.argv[1:]], [sys.executable, "build_forever.py"]):
    if subprocess.run(command).returncode != 0:
        sys.exit(1)
