#!/bin/bash
# EPF post-Soviet paper -- estimation driver (make-like). A step runs only when its output is missing or older than its inputs,
# so rendering the manuscript never re-estimates anything. FORCE=1 reruns everything.
#   PISA_PROFILE=FAST (default): PV1 in lqmm, 30 bootstrap draws  -- development, ~1.5-3 h for all systems on 2 cores
#   PISA_PROFILE=FULL          : 10 PVs for lqmm point estimates, 200 bootstrap draws -- overnight (several hours per domain)
# Usage: 02_scripts/epf_postsoviet/run_all_estimation.sh [DOMAINS="SCIE MATH READ"] [SYSTEMS="GEO AZE ..."] [JOBS=2] [HET_LQMM=1]
cd "$(dirname "$0")/../.."
export PISA_PROFILE=${PISA_PROFILE:-FAST}
DOMAINS=${DOMAINS:-"SCIE"}; SYSTEMS=${SYSTEMS:-"GEO AZE ARM MDA KGZ UZB KAZ"}; JOBS=${JOBS:-2}; export HET_LQMM=${HET_LQMM:-0}
S=02_scripts/epf_postsoviet; H=$S/00_helpers.R; DATA=01_data/derived/epf_analytic.rds; LOGD=03_outputs/epf_postsoviet/logs; mkdir -p $LOGD
needs_run() { local target=$1; shift; [ "${FORCE:-0}" = "1" ] && return 0; [ -f "$target" ] || return 0; for dep in "$@"; do [ "$dep" -nt "$target" ] && return 0; done; return 1; }
run() { local target=$1 log=$2; shift 2; if needs_run "$target" $DEPS; then echo "$(date +%H:%M) run  $target"; "$@" > "$log" 2>&1 || echo "  FAILED: see $log"; else echo "$(date +%H:%M) skip $target (up to date)"; fi; }

DEPS="$S/02_prepare.R $H 01_data/derived/epf_students.csv.gz"
run $DATA $LOGD/prepare.log Rscript $S/02_prepare.R
for D in $DOMAINS; do export PISA_DOMAIN=$D; O=03_outputs/epf_postsoviet/$D
  DEPS="$S/03_descriptives.R $H $DATA";  run $O/desc_systems.csv $LOGD/desc_$D.log Rscript $S/03_descriptives.R
  DEPS="$S/04_mean_models.R $H $DATA";   run $O/mean_models.csv  $LOGD/mean_$D.log Rscript $S/04_mean_models.R
  if [ "${RUN_RD:-0}" = "1" ]; then DEPS="$S/05_rd.R $H $DATA"; run $O/rd_estimates.csv $LOGD/rd_$D.log Rscript $S/05_rd.R; fi   # appendix only
  # heavy per-system steps, JOBS in parallel
  for C in $SYSTEMS; do
    [ "$D" != "SCIE" ] && [ "$C" = "UZB" ] && continue
    ( export PISA_CNT=$C
      DEPS="$S/06_lqmm.R $H $DATA";          run $O/lqmm_$C.csv $LOGD/lqmm_${D}_$C.log Rscript $S/06_lqmm.R
      DEPS="$S/07_heterogeneity.R $H $DATA"; run $O/het_$C.csv  $LOGD/het_${D}_$C.log  Rscript $S/07_heterogeneity.R
      DEPS="$S/10_mediation.R $H $DATA";     run $O/mediation_$C.csv $LOGD/med_${D}_$C.log Rscript $S/10_mediation.R ) &
    while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do sleep 20; done
  done
  wait
done
echo "$(date +%H:%M) ALL_DONE ($PISA_PROFILE)" | tee 03_outputs/epf_postsoviet/all_done.flag
