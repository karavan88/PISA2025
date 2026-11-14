#!/bin/sh
# sestransmit -- full pipeline (run from the repo root). Estimation ~4 min on 6 cores; the manuscript render reads saved CSVs only.
set -e
python3 02_scripts/sestransmit/01_build.py
Rscript 02_scripts/sestransmit/02_prepare.R
ST_CORES=${ST_CORES:-6} Rscript 02_scripts/sestransmit/03_estimate.R
Rscript 02_scripts/sestransmit/04_validate.R
Rscript 02_scripts/sestransmit/05_figures.R
Rscript 02_scripts/sestransmit/06_tables.R
cd 04_manuscripts/sestransmit && quarto render paper.qmd --to html && quarto render paper.qmd --to pdf
