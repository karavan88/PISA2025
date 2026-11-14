#!/bin/bash
# School Inputs & the Grade Gain -- estimation driver (make-like; FORCE=1 reruns all). Prerequisites: the skills pipeline's analytic file and
# structure.csv (02_scripts/skillsgain/02_prepare.R, 03_validity.R) and 01_build.py (Mac, python). Time on 6 cores: flows ~10 min,
# stress tests ~5 min, forest ~1.5-2 h (5 PVs x 2000 trees + honest-split RATE), decomposition ~10 min, mechanism ~5 min.
cd "$(dirname "$0")/../.."
S=02_scripts/schoolgain; H="$S/00_helpers.R 02_scripts/skillsgain/00_helpers.R"; O=03_outputs/schoolgain; DATA=01_data/derived/schoolgain_analytic.rds; mkdir -p $O/logs
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
DEPS="$S/02_prepare.R $H 01_data/derived/skillsgain_analytic.rds 01_data/derived/schoolgain_school.csv 01_data/derived/schoolgain_stu.csv.gz"; run $DATA $O/logs/prepare.log Rscript $S/02_prepare.R
DEPS="$S/02b_skills.R $H 01_data/derived/skillsgain_analytic.rds"; run $O/skills_levels.csv $O/logs/skills.log Rscript $S/02b_skills.R
DEPS="$S/03_flow_level.R $H $DATA"; run $O/flow_level.csv $O/logs/flow_level.log Rscript $S/03_flow_level.R
DEPS="$S/03b_top.R $H $DATA";       run $O/top.csv        $O/logs/top.log        Rscript $S/03b_top.R
DEPS="$S/04_forest.R $H $DATA";     run $O/forest_blp.csv $O/logs/forest.log     Rscript $S/04_forest.R
DEPS="$S/05_decompose.R $H $O/forest_scores.rds"; run $O/decomp.csv $O/logs/decomp.log Rscript $S/05_decompose.R
DEPS="$S/06_mechanism.R $H $DATA";  run $O/mechanism.csv  $O/logs/mechanism.log  Rscript $S/06_mechanism.R
DEPS="$S/07_pool.R $H $O/flow_level.csv $O/top.csv $O/mechanism.csv"; run $O/pool_flow_level.csv $O/logs/pool.log Rscript $S/07_pool.R
echo "$(date +%H:%M) ALL_DONE"
