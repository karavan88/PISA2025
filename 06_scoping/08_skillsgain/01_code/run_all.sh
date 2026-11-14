#!/bin/bash
# Skills & the Grade Gain -- estimation driver (make-like: a step runs only when its output is missing or older than its inputs; FORCE=1 reruns all).
# Prerequisites: 02_scripts/gradegain/02_prepare.R has written 01_data/derived/gradegain_analytic.rds; 01_build_extra.py has been run (Mac, python).
# Time on 6 cores: prepare < 1 min, validity ~1 min, heterogeneity ~4 min, forests ~(5 + 2 PVs x 2000 trees) 60-90 min, mediation ~3 min, pool < 1 min.
# The report (04_manuscripts/skillsgain/report.qmd) reads the CSVs only.
cd "$(dirname "$0")/../.."
S=02_scripts/skillsgain; H=$S/00_helpers.R; O=03_outputs/skillsgain; DATA=01_data/derived/skillsgain_analytic.rds; mkdir -p $O/logs
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
DEPS="$S/02_prepare.R $H 01_data/derived/gradegain_analytic.rds 01_data/derived/skillsgain_extra.csv.gz"; run $DATA $O/logs/prepare.log Rscript $S/02_prepare.R
DEPS="$S/03_validity.R $H $DATA";        run $O/baseline.csv  $O/logs/validity.log  Rscript $S/03_validity.R
DEPS="$S/04_heterogeneity.R $H $DATA";   run $O/het.csv       $O/logs/het.log       Rscript $S/04_heterogeneity.R
DEPS="$S/05_forest.R $H $DATA $O/baseline.csv"; run $O/forest_blp_same.csv $O/logs/forest_same.log env SAMPLE=same NPV=5 Rscript $S/05_forest.R
DEPS="$S/05_forest.R $H $DATA $O/baseline.csv"; run $O/forest_blp_all.csv  $O/logs/forest_all.log  env SAMPLE=all NPV=2 Rscript $S/05_forest.R
DEPS="$S/06_mediation.R $H $DATA";       run $O/mediation.csv $O/logs/mediation.log Rscript $S/06_mediation.R
DEPS="$S/07_pool.R $H $O/het.csv $O/mediation.csv $O/forest_scores_same.rds $O/balance.csv"; run $O/pool_het.csv $O/logs/pool.log Rscript $S/07_pool.R
echo "$(date +%H:%M) ALL_DONE"
