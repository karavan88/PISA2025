"""Compatibility entry point: use the central build; no paper-local variable construction."""
from pathlib import Path
import subprocess, sys
root = Path(__file__).resolve().parents[3]
subprocess.run([sys.executable, str(root/"02_scripts/00_tools/build_shared.py")], cwd=root, check=True)
