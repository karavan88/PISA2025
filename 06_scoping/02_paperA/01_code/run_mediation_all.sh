#!/bin/bash
# Mediation runs, country-level models, parallel over systems (MED_CORES). Reading within-school at full settings; the rest reduced (MED_FAST=1).
cd "$(dirname "$0")/../.."
export MED_CORES=3
PISA_DOMAIN=READ Rscript 02_scripts/paperA/09_causal_mediation.R > 03_outputs/paperA/READ/medpkg.log 2>&1
MED_FAST=1 PISA_DOMAIN=READ Rscript 02_scripts/paperA/09_causal_mediation.R --total > 03_outputs/paperA/READ/medpkg_total.log 2>&1
MED_FAST=1 PISA_DOMAIN=MATH Rscript 02_scripts/paperA/09_causal_mediation.R > 03_outputs/paperA/MATH/medpkg.log 2>&1
MED_FAST=1 PISA_DOMAIN=MATH Rscript 02_scripts/paperA/09_causal_mediation.R --total > 03_outputs/paperA/MATH/medpkg_total.log 2>&1
MED_FAST=1 PISA_DOMAIN=SCIE Rscript 02_scripts/paperA/09_causal_mediation.R > 03_outputs/paperA/SCIE/medpkg.log 2>&1
MED_FAST=1 PISA_DOMAIN=SCIE Rscript 02_scripts/paperA/09_causal_mediation.R --total > 03_outputs/paperA/SCIE/medpkg_total.log 2>&1
for D in READ MATH SCIE; do PISA_DOMAIN=$D Rscript 02_scripts/paperA/09b_joint_rho.R > 03_outputs/paperA/$D/jointrho.log 2>&1; PISA_DOMAIN=$D Rscript 02_scripts/paperA/09b_joint_rho.R --total > 03_outputs/paperA/$D/jointrho_total.log 2>&1; done
echo ALL_MED_DONE > 03_outputs/paperA/med_all_done.flag
