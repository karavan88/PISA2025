#!/bin/bash
# The Cost of Resilience -- driver (make-like: a step runs only when its output is missing or older than its inputs; FORCE=1 reruns all).
# Time on 6 cores: build ~2 min (python, pyreadstat), prepare ~20 s, response style ~1 min, gap ~1 min.
cd "$(dirname "$0")/../.."
S=02_scripts/resilwb; H=$S/00_helpers.R; G=02_scripts/gradegain/00_helpers.R; O=03_outputs/resilwb; mkdir -p $O/logs
RAW=01_data/derived/resilwb_students.csv.gz; DATA=01_data/derived/resilwb_analytic.rds
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
DEPS="$S/01_build.py";                  run $RAW               $O/logs/build.log   python3 -I $S/01_build.py
DEPS="$S/02_prepare.R $H $G $RAW";      run $DATA              $O/logs/prepare.log Rscript $S/02_prepare.R
DEPS="$S/03_response_style.R $H $DATA"; run $O/rs_pool.csv     $O/logs/rs.log      Rscript $S/03_response_style.R
DEPS="$S/04_gap.R $H $DATA";            run $O/gap_pool.csv    $O/logs/gap.log     Rscript $S/04_gap.R
DEPS="$S/05_mechanism.R $H $DATA $O/gap_pool.csv"; run $O/mech_pool.csv $O/logs/mech.log Rscript $S/05_mechanism.R
DEPS="$S/06_oriv.R $H $DATA";           run $O/oriv_resil.csv  $O/logs/oriv.log    Rscript $S/06_oriv.R
echo "$(date +%H:%M) ALL_DONE"
