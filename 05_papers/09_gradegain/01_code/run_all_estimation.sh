#!/bin/bash
# Grade Gain Report -- estimation driver (make-like: a step runs only when its output is missing or older than its inputs; FORCE=1 reruns all).
# Whole chain ~10 minutes on 2 cores. Rendering the report never re-estimates anything.
#   step 1 (Mac, python): 02_scripts/gradegain/01_build.py -> 01_data/derived/gradegain_students.csv.gz, gradegain_systems.csv
cd "$(dirname "$0")/../.."
S=02_scripts/gradegain; H=$S/00_helpers.R; O=03_outputs/gradegain; DATA=01_data/derived/gradegain_analytic.rds; mkdir -p $O/logs
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
DEPS="$S/02_prepare.R $H 01_data/derived/gradegain_students.csv.gz"; run $DATA $O/logs/prepare.log Rscript $S/02_prepare.R
DEPS="$S/03_gradegain.R $H $DATA"; run $O/estimates.csv $O/logs/estimates.log Rscript $S/03_gradegain.R
DEPS="$S/04_summary.R $H $O/estimates.csv"; run $O/summary.csv $O/logs/summary.log Rscript $S/04_summary.R
echo "$(date +%H:%M) ALL_DONE"
