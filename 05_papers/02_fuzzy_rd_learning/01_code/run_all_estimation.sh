#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
exec python3 "$ROOT/05_papers/02_fuzzy_rd_learning/01_code/run_all.py" estimate "$@"
