#!/bin/bash
# Estimation driver (make-like): each step runs only when its output is missing or older than its inputs (script, helpers, analytic data),
# so a change to one script or to the manuscript never triggers a full re-estimation. FORCE=1 reruns everything.
# Treatments (PISA_TREAT): ESCS_PCT = percentile rank of ESCS (headline; reading within-school at full settings, the rest MED_FAST=1),
# DEP = deprivation count conditional on ESCS (reading only), ESCS = index units (appendix check, MED_FAST=1). One model per system.
# Usage: scripts/run_all_estimation.sh [TREATS="ESCS_PCT DEP ESCS"] [DOMAINS="READ MATH SCIE"]
cd "$(dirname "$0")/../.."
export MED_CORES=${MED_CORES:-3}
TREATS=${TREATS:-"ESCS_PCT DEP ESCS"}; DOMAINS=${DOMAINS:-"READ MATH SCIE"}
DATA=01_data/derived/paperA_analytic.rds; H=02_scripts/paperA/00_helpers.R
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0
  for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }
suf() { case $1 in ESCS_PCT) echo _pct;; DEP) echo _dep;; *) echo "";; esac; }
for T in $TREATS; do S=$(suf $T); export PISA_TREAT=$T
  DOMS=$DOMAINS; [ "$T" = "DEP" ] && DOMS="READ"
  for D in $DOMS; do export PISA_DOMAIN=$D; O=03_outputs/paperA/$D/tables
    DEPS="02_scripts/paperA/04_h1_gelbach.R $H $DATA"
    run $O/h1_gelbach_long$S.csv       03_outputs/paperA/$D/gelbach$S.log       Rscript 02_scripts/paperA/04_h1_gelbach.R
    run $O/h1_gelbach_long${S}_total.csv 03_outputs/paperA/$D/gelbach${S}_total.log Rscript 02_scripts/paperA/04_h1_gelbach.R --total
    DEPS="02_scripts/paperA/09_causal_mediation.R $H $DATA"
    if [ "$T" = "ESCS_PCT" ] && [ "$D" = "READ" ]; then FAST=0; else FAST=1; fi
    MED_FAST=$FAST run $O/h1_mediation_pkg$S.csv       03_outputs/paperA/$D/medpkg$S.log       Rscript 02_scripts/paperA/09_causal_mediation.R
    MED_FAST=1     run $O/h1_mediation_pkg${S}_total.csv 03_outputs/paperA/$D/medpkg${S}_total.log Rscript 02_scripts/paperA/09_causal_mediation.R --total
    DEPS="02_scripts/paperA/09b_joint_rho.R $H $DATA"
    run $O/h1_joint_rho$S.csv       03_outputs/paperA/$D/jointrho$S.log       Rscript 02_scripts/paperA/09b_joint_rho.R
    run $O/h1_joint_rho${S}_total.csv 03_outputs/paperA/$D/jointrho${S}_total.log Rscript 02_scripts/paperA/09b_joint_rho.R --total
    if [ "$D" = "READ" ]; then DEPS="02_scripts/paperA/07_robustness.R $H $DATA $O/h1_gelbach_long$S.csv"
      run $O/rob_gelbach_table$S.csv       03_outputs/paperA/$D/rob$S.log       Rscript 02_scripts/paperA/07_robustness.R
      run $O/rob_gelbach_table${S}_total.csv 03_outputs/paperA/$D/rob${S}_total.log Rscript 02_scripts/paperA/07_robustness.R --total
    fi
  done
done
echo "$(date +%H:%M) ALL_DONE" | tee 03_outputs/paperA/all_done.flag
