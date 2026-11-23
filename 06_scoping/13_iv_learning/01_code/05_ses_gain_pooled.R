# IV learning -- step 5: question 1 by the pooled design (second estimator), on cutoff and drifting systems.
# The age profile and its change with SES are taken from the flat systems (no grade variation with birth month):
#       score = a + B age + B_S age x SES + ...          (flat systems; age in years older than the youngest, SES = ESCS standardised within system)
# In every other system the score is cleared of that profile and age becomes the instrument for grade:
#       score - (B + B_S x SES) x age = a + tau grade + tau_S grade x SES + d SES,   grade and grade x SES instrumented by age and age x SES
#   tau_S   change in the same-age gain per SD of SES (question 1)
# Sets: the cutoff systems (to compare with step 4, which uses the cutoff and each system's own age slope) and the drifting systems with a
# grade slope of 0.3 or more per year (step 3). Left out: Uzbekistan (no scores), the United Kingdom (its cohort spans 20 birth months and
# its score slope by age is three times any other system's), systems without ESCS.
# Uncertainty of the borrowed B_S: its standard error is common to all systems and is added to the pooled standard error.
# Reads central products and the outputs of steps 2 and 3. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/05_ses_gain_pooled.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
STEP2 <- Sys.getenv("STEP2_DIR", file.path(PROJECT, "04_output/estimate_20261122_step2_age_profile"))
STEP3 <- Sys.getenv("STEP3_DIR", file.path(PROJECT, "04_output/estimate_20261122_step3_drifting"))
STEP4 <- Sys.getenv("STEP4_DIR", file.path(PROJECT, "04_output/estimate_20261122_step4_ses"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
grp <- fread(file.path(STEP2, "system_groups.csv")); s3 <- fread(file.path(STEP3, "drifting_sys.csv"))
UNUSABLE <- c("UZB", "GBR")
sets <- rbind(grp[group == "flat", .(CNT, set = "flat")], grp[group == "cutoff", .(CNT, set = "cutoff")],
              s3[group == "neither" & est_fs_grade >= .3, .(CNT, set = "drifting")])[!CNT %in% c(EXCLUDE, UNUSABLE)]

p <- readRDS("03_outputs/01_harmonized/cutoff_provider.rds")
keep <- c("CNT", "ST001D01T", "ST003D02T", "ST003D03T", "ESCS", "W_FSTUWT", RW, PV("MATH"), PV("READ"), PV("SCIE"))
d <- as.data.table(lapply(p[keep], function(v) if (is.character(v)) as.character(v) else as.numeric(v))); rm(p); invisible(gc())
setnames(d, c("ST001D01T", "ST003D02T", "ST003D03T"), c("grade", "bm", "by")); d[by > 2100, by := by - 543]
d <- merge(d[!is.na(grade) & !is.na(bm) & !is.na(by)], sets, by = "CNT")
for (q in 1:10) d[, (paste0("PV", q, "ACH")) := (get(paste0("PV", q, "MATH")) + get(paste0("PV", q, "READ")) + get(paste0("PV", q, "SCIE"))) / 3]
d[, t := by * 12 + bm]; d[, age := (max(t) - t) / 12, by = CNT]
noses <- d[, .(ok = mean(!is.na(ESCS))), by = CNT][ok < .5, CNT]
if (length(noses)) { log_step("left out, ESCS for under half of students:", paste(noses, collapse = " ")); d <- d[!CNT %in% noses] }
d <- d[!is.na(ESCS)]
d[, S := { m <- wmean(ESCS, W_FSTUWT); (ESCS - m) / sqrt(wmean((ESCS - m)^2, W_FSTUWT)) }, by = CNT]
d[, G := grade - wmean(grade, W_FSTUWT), by = CNT]                      # centred, so the coefficient on SES is the gradient at the mean grade
log_step("systems:", paste(d[, uniqueN(CNT), by = set][, paste(set, V1)], collapse = "; "), "; students:", nrow(d))

# ---- age profile and its change with SES, flat systems ----
fl <- rbindlist(parallel::mclapply(d[set == "flat", sort(unique(CNT))], function(cn) { s <- d[CNT == cn]
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) { b <- lm.wfit(cbind(1, age = dt$age, S = dt$S, ageS = dt$age * dt$S), y, w)$coefficients
    c(B = unname(b["age"]), B_S = unname(b["ageS"]), gradient = unname(b["S"])) }, PV("ACH"))) }, mc.cores = 6))
fp <- fl[, pool(est, se), by = term]; fwrite(fl, paste0(OUT, "flat_age_by_ses_sys.csv")); fwrite(fp, paste0(OUT, "flat_age_by_ses_pool.csv"))
B <- fp[term == "B", re_mean]; B_S <- fp[term == "B_S", re_mean]; B_S_se <- fp[term == "B_S", re_se]

# ---- question 1 with the borrowed profile ----
SYS <- d[set != "flat", sort(unique(CNT))]
est <- rbindlist(parallel::mclapply(SYS, function(cn) { s <- d[CNT == cn]
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) {
    f <- tsls(y - (B + B_S * dt$S) * dt$age, cbind(`(Intercept)` = 1, S = dt$S), cbind(D = dt$G, DS = dt$G * dt$S), cbind(age = dt$age, ageS = dt$age * dt$S), w)
    c(fs = unname(f$fs["age", "D"]), tau = unname(f$b["D"]), tau_S = unname(f$b["DS"]), gradient = unname(f$b["S"])) }, PV("ACH"))) }, mc.cores = 6))
est <- merge(est, unique(d[, .(CNT, set)]), by = "CNT"); est[, flagged := CNT %in% FLAG]; fwrite(est, paste0(OUT, "ses_gain_pooled_sys.csv"))
w <- dcast(est, CNT + set ~ term, value.var = c("est", "se"))
pool_set <- function(x, lab) rbindlist(lapply(c("tau", "tau_S", "gradient", "fs"), function(tm) { q <- pool(x[[paste0("est_", tm)]], x[[paste0("se_", tm)]])
  if (tm == "tau_S") q[, re_se := sqrt(re_se^2 + (B_S_se * mean(1 / x$est_fs))^2)]      # common error of the borrowed age-by-SES slope
  q[, `:=`(term = tm, set = lab, median_se = median(x[[paste0("se_", tm)]]))] }))
pl <- rbind(pool_set(w[set == "cutoff"], "cutoff systems"), pool_set(w[set == "drifting"], "drifting systems"), pool_set(w, "cutoff and drifting"))
fwrite(pl, paste0(OUT, "ses_gain_pooled_pool.csv"))
s4 <- fread(file.path(STEP4, "ses_gain_sys.csv"))[spec == "base" & outcome == "ACH" & term == "tau:ESCS_z", .(CNT, step4 = est)]
cmp <- merge(w[set == "cutoff", .(CNT, pooled = est_tau_S)], s4, by = "CNT")
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "05_ses_gain_pooled", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  B = B, B_S = B_S, B_S_se = B_S_se, systems = split(sets$CNT, sets$set), excluded = EXCLUDE, unusable = UNUSABLE,
  md5 = as.list(tools::md5sum(c("03_outputs/01_harmonized/cutoff_provider.rds", file.path(STEP2, "system_groups.csv"), file.path(STEP3, "drifting_sys.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
cat("\nflat systems: age slope (B), its change per SD of SES (B_S), SES gradient\n")
print(fp[, .(term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), sd_across = round(tau_sd, 2), pos_05, pos_10, neg_05, neg_10)])
cat("\nquestion 1, pooled design\n")
print(pl[, .(set, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), sd_across = round(tau_sd, 2), I2 = round(I2), median_se = round(median_se, 2), pos_05, pos_10, neg_05, neg_10)][order(set, term)])
cat(sprintf("\ncutoff systems, tau_S: pooled design against step 4, per system: correlation %.2f, n = %d\n", cor(cmp$pooled, cmp$step4), nrow(cmp)))
cat("drifting systems in the model:", paste(w[set == "drifting", CNT], collapse = " "), "\n")
log_step("done"); sink()
