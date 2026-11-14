#!/bin/bash
# Paper B -- estimation driver (make-like): a step runs only when its output is missing or older than its inputs; FORCE=1 reruns all.
# Whole chain ~5 minutes: the RD is closed-form WLS per replicate weight. Rendering the manuscript never re-estimates anything.
cd "$(dirname "$0")/../.."
S=02_scripts/paperB; H=$S/00_helpers.R; O=03_outputs/paperB; DATA=01_data/derived/paperB_analytic.rds; mkdir -p $O/logs
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
DEPS="$S/02_prepare.R $H 01_data/derived/paperB_students.csv.gz"; run $DATA $O/logs/prepare.log Rscript $S/02_prepare.R
DEPS="$S/03_rd.R $H $DATA";        run $O/rd_estimates.csv $O/logs/rd.log        Rscript $S/03_rd.R
DEPS="$S/04_mediation.R $H $DATA"; run $O/med_share.csv    $O/logs/mediation.log Rscript $S/04_mediation.R
DEPS="$S/05_placebo.R $H $DATA";   run $O/rd_placebo.csv   $O/logs/placebo.log   Rscript $S/05_placebo.R
echo "$(date +%H:%M) ALL_DONE"
