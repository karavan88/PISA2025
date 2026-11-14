#!/bin/bash
# Run the full Paper A model pipeline for one outcome domain: bash scripts/run_domain.sh READ
set -e
export PISA_DOMAIN=$1
LOG=03_outputs/paperA/$1.log; mkdir -p 03_outputs/paperA/$1
echo "== $1 start $(date)" > $LOG
Rscript 02_scripts/paperA/03_descriptives.R      >> $LOG 2>&1
Rscript 02_scripts/paperA/04_h1_gelbach.R        >> $LOG 2>&1
Rscript 02_scripts/paperA/04_h1_gelbach.R --total >> $LOG 2>&1
Rscript 02_scripts/paperA/05_h2_h3_h5.R          >> $LOG 2>&1
Rscript 02_scripts/paperA/05c_deprivation_int.R  >> $LOG 2>&1
Rscript 02_scripts/paperA/05b_postprocess.R      >> $LOG 2>&1
Rscript 02_scripts/paperA/06_figures.R           >> $LOG 2>&1
echo "== $1 done $(date)" >> $LOG
