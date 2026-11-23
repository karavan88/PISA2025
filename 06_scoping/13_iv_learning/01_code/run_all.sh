#!/bin/sh
# IV learning -- run every estimation step into one new run directory. From the repository root:
#     sh 06_scoping/13_iv_learning/01_code/run_all.sh <run name> [resume]
# Writes 06_scoping/13_iv_learning/04_output/<run name>/stepNN_*/ and refuses an existing run name. Steps run one after another,
# each on six cores; about 50 minutes in all. Order matters: step 13 reads step 9, steps 9 and 15 read step 1.
# "resume" continues a run that stopped: finished steps (those with run.json) are kept, the folder of an unfinished step is renamed
# failed_<step>_<time> inside the run and the step is run again. Use it only if no code or input changed since the run began.
# Figures (07), tables (18) and text numbers (19) are reporting and are run separately afterwards.
set -e
[ -n "$1" ] || { echo "usage: run_all.sh <run name>"; exit 1; }
C=06_scoping/13_iv_learning/01_code; BASE=06_scoping/13_iv_learning/04_output/$1
[ -e "$BASE" ] && [ "$2" != "resume" ] && { echo "$BASE exists; choose a new run name, or pass resume"; exit 1; }
mkdir -p "$BASE"; export RENV_PROJECT="$PWD" R_PROFILE_USER="$PWD/.Rprofile"
export STEP1_DIR=$BASE/step01_first_stage_base STEP2_DIR=$BASE/step02_age_profile STEP3_DIR=$BASE/step03_drifting STEP4_DIR=$BASE/step04_ses
export STEP5_DIR=$BASE/step05_ses_pooled STEP6_DIR=$BASE/step06_gap_years STEP6B_DIR=$BASE/step06b_scale STEP8_DIR=$BASE/step08_school_ses STEP9_DIR=$BASE/step09_quantile_iv
export STEP10_DIR=$BASE/step10_school_spread STEP11_DIR=$BASE/step11_spread_placebo STEP12_DIR=$BASE/step12_school_types STEP13_DIR=$BASE/step13_skills
export STEP14_DIR=$BASE/step14_skills_catchup STEP15_DIR=$BASE/step15_quantile_iv_skills STEP16_DIR=$BASE/step16_forest STEP17_DIR=$BASE/step17_gain_by_sex
step() { [ -e "$2/run.json" ] && { echo "$(date +%H:%M:%S) $1 already done"; return 0; }
  [ -e "$2" ] && mv "$2" "$BASE/failed_$(basename $2)_$(date +%H%M%S)"
  echo "$(date +%H:%M:%S) $1"; PAPER_OUT=$2 Rscript $C/$1 > "$BASE/$(basename $2).console.txt" 2>&1 || { echo "FAILED: $1 (see $BASE/$(basename $2).console.txt)"; exit 1; }; }
echo "$(date +%H:%M:%S) estimator test"; Rscript $C/test_estimators.R > "$BASE/test_estimators.console.txt" 2>&1 || { echo "FAILED: estimator test"; exit 1; }
step 01_first_stage_base.R $STEP1_DIR; step 02_age_profile.R $STEP2_DIR; step 03_drifting_systems.R $STEP3_DIR; step 04_ses_gain.R $STEP4_DIR
step 05_ses_gain_pooled.R $STEP5_DIR; step 06_gap_years.R $STEP6_DIR; step 06b_scale.R $STEP6B_DIR; step 08_school_ses.R $STEP8_DIR; step 10_school_spread.R $STEP10_DIR
step 11_school_spread_placebo.R $STEP11_DIR; step 12_school_types.R $STEP12_DIR; step 17_gain_by_sex.R $STEP17_DIR; step 09_quantile_iv.R $STEP9_DIR; step 13_skills.R $STEP13_DIR
step 14_skills_catchup.R $STEP14_DIR; step 15_quantile_iv_skills.R $STEP15_DIR; step 16_forest.R $STEP16_DIR
echo "$(date +%H:%M:%S) all steps done in $BASE"
