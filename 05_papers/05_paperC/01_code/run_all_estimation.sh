#!/bin/bash
# Paper C -- estimation driver. Paper C reads Paper B's RD outputs (03_outputs/paperB/rd_estimates.csv etc.) and adds the LSDV grade benchmark.
cd "$(dirname "$0")/../.."
[ -f 03_outputs/paperB/rd_estimates.csv ] || bash 02_scripts/paperB/run_all_estimation.sh
if [ "${FORCE:-0}" = "1" ] || [ ! -f 03_outputs/paperC/grade_lsdv.csv ] || [ 02_scripts/paperC/01_grade_lsdv.R -nt 03_outputs/paperC/grade_lsdv.csv ] || [ 01_data/derived/paperB_analytic.rds -nt 03_outputs/paperC/grade_lsdv.csv ]; then
  echo "$(date +%H:%M) run grade_lsdv"; Rscript 02_scripts/paperC/01_grade_lsdv.R > 03_outputs/paperC/grade_lsdv.log 2>&1 || echo "  FAILED"
else echo "skip grade_lsdv (up to date)"; fi
if [ "${FORCE:-0}" = "1" ] || [ ! -f 03_outputs/paperC/age_decomposition.csv ] || [ 02_scripts/paperC/02_age_decomposition.R -nt 03_outputs/paperC/age_decomposition.csv ]; then echo "$(date +%H:%M) run age_decomposition"; Rscript 02_scripts/paperC/02_age_decomposition.R > 03_outputs/paperC/age_decomposition.log 2>&1 || echo "  FAILED"; else echo "skip age_decomposition (up to date)"; fi
echo "$(date +%H:%M) ALL_DONE"
