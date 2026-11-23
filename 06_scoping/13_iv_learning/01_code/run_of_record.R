# IV learning -- the run of record: the run directory that the reporting scripts (07 figures, 18 tables, 19 text numbers) read.
#   PAPER_RUN=<run name>   reads another run under 04_output/
#   STEPn_DIR=<directory>  overrides one step (run_all.sh exports these for the estimation steps)
# Runs of record so far:
#   estimate_20261122_step* and estimate_20261123_step*   35 systems, Israel kept and flagged (separate folders per step)
#   run_20261123_no_israel                                34 systems, Israel excluded (user's decision of 2026-11-23); current
RUN <- Sys.getenv("PAPER_RUN", "run_20261123_no_israel")
.STEPDIR <- c("1" = "step01_first_stage_base", "2" = "step02_age_profile", "3" = "step03_drifting", "4" = "step04_ses", "5" = "step05_ses_pooled", "6" = "step06_gap_years",
              "6B" = "step06b_scale", "8" = "step08_school_ses", "9" = "step09_quantile_iv", "10" = "step10_school_spread", "11" = "step11_spread_placebo",
              "12" = "step12_school_types", "13" = "step13_skills", "14" = "step14_skills_catchup", "15" = "step15_quantile_iv_skills", "16" = "step16_forest", "17" = "step17_gain_by_sex")
step_dir <- function(n) { n <- toupper(as.character(n)); d <- Sys.getenv(paste0("STEP", n, "_DIR"), file.path("06_scoping/13_iv_learning/04_output", RUN, .STEPDIR[[n]]))
  if (!dir.exists(d)) stop("no results for step ", n, " in ", d, call. = FALSE); d }
