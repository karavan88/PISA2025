# IV learning -- step 3: birth month as the instrument, age slope borrowed from the flat systems (exploratory).
# In many systems grade drifts with birth month without one clean cutoff. With the age slope B (points per year older) taken from the
# flat systems of step 2, the same-age gain is
#       tau = (score slope per year older - B) / (grade slope per year older)
# that is, the instrument estimate of (score - B x age) on grade with age in months as the instrument.
#   (a) validation where a benchmark exists: the same estimator in the cutoff systems, against step 1's tau (own age slope, cutoff instrument)
#   (b) the drifting systems, with grade and with years in school (grade + 1 for repeaters) as the treatment. If years in school do not
#       drift although grade does, the drift is repetition, not exposure to school, and the system cannot say what a year of school adds.
# Uncertainty of B: common error of its mean, and a slope that varies across systems (spread among flat systems; spread among cutoff systems).
# Reads central products and the outputs of steps 1 and 2. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/03_drifting_systems.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
STEP1 <- Sys.getenv("STEP1_DIR", file.path(PROJECT, "04_output/estimate_20261122_step1"))
STEP2 <- Sys.getenv("STEP2_DIR", file.path(PROJECT, "04_output/estimate_20261122_step2_age_profile"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
ap <- fread(file.path(STEP2, "age_profile_pool.csv")); grp <- fread(file.path(STEP2, "system_groups.csv"))
B <- ap[group == "flat", re_mean]; B_se <- ap[group == "flat", re_se]; SD_FLAT <- ap[group == "flat", tau_sd]; SD_CUT <- ap[group == "cutoff", tau_sd]
log_step(sprintf("borrowed age slope %.2f points per year (SE %.2f); spread across systems: flat %.1f, cutoff %.1f", B, B_se, SD_FLAT, SD_CUT))

p <- readRDS("03_outputs/01_harmonized/cutoff_provider.rds")
keep <- c("CNT", "ST001D01T", "ST003D02T", "ST003D03T", "REPEAT", "W_FSTUWT", RW, PV("MATH"), PV("READ"), PV("SCIE"))
d <- as.data.table(lapply(p[keep], function(v) if (is.character(v)) as.character(v) else as.numeric(v))); rm(p); invisible(gc())
setnames(d, c("ST001D01T", "ST003D02T", "ST003D03T"), c("grade", "bm", "by")); d[by > 2100, by := by - 543]
d <- d[CNT %in% grp[group != "flat", CNT] & !is.na(grade) & !is.na(bm) & !is.na(by)]
for (q in 1:10) d[, (paste0("PV", q, "ACH")) := (get(paste0("PV", q, "MATH")) + get(paste0("PV", q, "READ")) + get(paste0("PV", q, "SCIE"))) / 3]
d[, t := by * 12 + bm]; d[, age_m := max(t) - t, by = CNT]; d[, yrs := grade + as.numeric(REPEAT == 1)]
noscore <- d[, .(ok = mean(!is.na(PV1ACH))), by = CNT][ok < .5, CNT]      # Uzbekistan has no plausible values in the PISA 2025 file
if (length(noscore)) { log_step("left out, no test scores:", paste(noscore, collapse = " ")); d <- d[!CNT %in% noscore] }

slope <- function(v, a, w) { ok <- is.finite(v) & is.finite(w); unname(lm.wfit(cbind(1, a[ok]), v[ok], w[ok])$coefficients[2]) * 12 }
est <- rbindlist(parallel::mclapply(sort(unique(d$CNT)), function(cn) { s <- d[CNT == cn]; has_rep <- mean(!is.na(s$yrs)) > .5
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) { fg <- slope(dt$grade, dt$age_m, w); sy <- slope(y, dt$age_m, w)
    o <- c(fs_grade = fg, score_slope = sy, tau_grade = (sy - B) / fg)
    if (has_rep) { k <- !is.na(dt$yrs); fy <- slope(dt$yrs[k], dt$age_m[k], w[k]); o <- c(o, fs_years = fy, tau_years = (slope(y[k], dt$age_m[k], w[k]) - B) / fy) }
    o }, PV("ACH"))) }, mc.cores = 6))
w <- dcast(est, CNT ~ term, value.var = c("est", "se"))
w <- merge(w, grp[, .(CNT, name, group, drift, share_repeated)], by = "CNT")
s1 <- fread(file.path(STEP1, "grade_gain_sys.csv"))[spec == "base" & outcome == "ACH" & term == "tau", .(CNT, tau_step1 = est, se_step1 = se)]
w <- merge(w, s1, by = "CNT", all.x = TRUE)
# standard errors that let the system's own age slope differ from the borrowed mean
w[, `:=`(se_grade_flat = sqrt(se_tau_grade^2 + (SD_FLAT / est_fs_grade)^2), se_grade_cut = sqrt(se_tau_grade^2 + (SD_CUT / est_fs_grade)^2),
         se_years_flat = sqrt(se_tau_years^2 + (SD_FLAT / est_fs_years)^2), se_years_cut = sqrt(se_tau_years^2 + (SD_CUT / est_fs_years)^2))]
w[, flagged := CNT %in% FLAG]; fwrite(w, paste0(OUT, "drifting_sys.csv"))

pool_set <- function(x, lab, tr) { if (!nrow(x)) return(NULL); e <- x[[paste0("est_tau_", tr)]]; f <- x[[paste0("est_fs_", tr)]]
  common <- B_se * abs(mean(1 / f))
  rbindlist(lapply(c(fixed = paste0("se_tau_", tr), flat = paste0("se_", tr, "_flat"), cut = paste0("se_", tr, "_cut")), function(col) {
    q <- pool(e, x[[col]]); q[, `:=`(re_se = sqrt(re_se^2 + common^2), median_se = median(x[[col]]))]; q }), idcol = "slope_uncertainty")[, `:=`(set = lab, treatment = tr)] }
dr <- w[group == "neither"]
pl <- rbind(pool_set(w[group == "cutoff"], "cutoff systems (validation)", "grade"),
            pool_set(dr[est_fs_grade >= .3], "drifting, grade slope 0.3 or more", "grade"),
            pool_set(dr[est_fs_grade >= .5], "drifting, grade slope 0.5 or more", "grade"),
            pool_set(dr[est_fs_grade >= .3 & !is.na(est_fs_years) & est_fs_years >= .3], "drifting, years-in-school slope 0.3 or more", "years"),
            pool_set(dr[est_fs_grade >= .5 & !is.na(est_fs_years) & est_fs_years >= .5], "drifting, years-in-school slope 0.5 or more", "years"))
fwrite(pl, paste0(OUT, "drifting_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "03_drifting_systems", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  borrowed_slope = B, borrowed_slope_se = B_se, excluded = EXCLUDE,
  md5 = as.list(tools::md5sum(c("03_outputs/01_harmonized/cutoff_provider.rds", file.path(STEP2, "age_profile_pool.csv"), file.path(STEP2, "system_groups.csv"), file.path(STEP1, "grade_gain_sys.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)

options(width = 220)
v <- w[group == "cutoff"]
cat("\n(a) validation in the", nrow(v), "cutoff systems: birth-month estimator with the borrowed slope against step 1\n")
cat(sprintf("correlation %.2f; mean difference %.1f; median absolute difference %.1f; step 1 median SE %.1f\n", cor(v$est_tau_grade, v$tau_step1), mean(v$est_tau_grade - v$tau_step1), median(abs(v$est_tau_grade - v$tau_step1)), median(v$se_step1)))
cat("\n(b) drifting systems, by grade slope\n")
print(dr[order(-est_fs_grade), .(CNT, rep = share_repeated, fs_grade = round(est_fs_grade, 2), fs_years = round(est_fs_years, 2), score_slope = round(est_score_slope, 1), tau_grade = round(est_tau_grade, 1),
  se = round(se_tau_grade, 1), se_flat = round(se_grade_flat, 1), se_cut = round(se_grade_cut, 1), tau_years = round(est_tau_years, 1), se_y = round(se_tau_years, 1))], nrows = 60)
cat("\npooled (random effects); slope_uncertainty: fixed = borrowed slope exact for every system; flat / cut = system slopes vary with the spread among flat / cutoff systems\n")
print(pl[, .(set, treatment, slope_uncertainty, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), median_se = round(median_se, 1), pos_05, pos_10, neg_05, neg_10)], nrows = 60)
log_step("done"); sink()
