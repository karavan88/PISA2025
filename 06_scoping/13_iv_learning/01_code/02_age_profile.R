# IV learning -- step 2: test of the pooled design. Can systems without a cutoff inside the cohort supply the age profile?
#   (a) "flat" systems: no eligible cutoff, no drop of 0.15 in the central screen, and mean grade that barely moves with birth month
#       (drift over the cohort and largest month-to-month change both under 0.10 of a grade). There, score on age in months is the
#       age profile at fixed schooling.
#   (b) cutoff systems (the step 1 sample): the age profile the instrument model estimates inside each side of the cutoff (gamma - tau).
#   (c) if the two agree: the same-age gain tau re-estimated with the age slope taken from the flat systems (pooled design), and how
#       much precision that buys. Uncertainty of the borrowed slope is added in two ways: one common slope; a slope that varies across
#       systems with the spread seen among the flat systems.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/02_age_profile.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
FLAT_MAX <- 0.10
rules <- fread(RULES)
p <- readRDS("03_outputs/01_harmonized/cutoff_provider.rds")
keep <- c("CNT", "ST001D01T", "ST003D02T", "ST003D03T", "W_FSTUWT", RW, PV("MATH"), PV("READ"), PV("SCIE"))
d <- as.data.table(lapply(p[keep], function(v) if (is.character(v)) as.character(v) else as.numeric(v))); rm(p); invisible(gc())
setnames(d, c("ST001D01T", "ST003D02T", "ST003D03T"), c("grade", "bm", "by")); d[by > 2100, by := by - 543]
d <- d[!CNT %in% EXCLUDE & !is.na(grade) & !is.na(bm) & !is.na(by)]
for (q in 1:10) d[, (paste0("PV", q, "ACH")) := (get(paste0("PV", q, "MATH")) + get(paste0("PV", q, "READ")) + get(paste0("PV", q, "SCIE"))) / 3]
d[, t := by * 12 + bm]; d[, age_m := max(t) - t, by = CNT]          # months older than the youngest birth month of the system's cohort

# ---- (a) which systems are flat ----
gm <- d[, .(g = wmean(grade, W_FSTUWT), n = .N), by = .(CNT, t)][n >= 30][order(CNT, t)]
flat <- gm[, .(months = .N, drift = unname(coef(lm(g ~ t, weights = n))[2]) * (max(t) - min(t)), max_step = max(abs(diff(g)))), by = CNT]
flat <- merge(flat, rules[, .(CNT, name, pisa_eligible, pisa_screen_jump, pisa_reason, share_repeated, share_modal)], by = "CNT")
flat[, group := fifelse(pisa_eligible == TRUE, "cutoff", fifelse(!is.na(pisa_screen_jump) & pisa_screen_jump < .15 & abs(drift) < FLAT_MAX & max_step < FLAT_MAX, "flat", "neither"))]
fwrite(flat, paste0(OUT, "system_groups.csv"))
log_step("systems:", paste(flat[, .N, by = group][, paste(group, N)], collapse = "; "))

# ---- (a) age slope in the flat systems, points per year older ----
FL <- flat[group == "flat", CNT]
age_flat <- rbindlist(parallel::mclapply(FL, function(cn) { s <- d[CNT == cn]
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) c(age_year = unname(lm.wfit(cbind(1, dt$age_m), y, w)$coefficients[2]) * 12,
    curve = unname(lm.wfit(cbind(1, dt$age_m, (dt$age_m - 5.5)^2), y, w)$coefficients[3])), PV("ACH"))) }, mc.cores = 6))
age_flat[, group := "flat"]
prof <- d[CNT %in% FL & age_m <= 11][, y := rowMeans(.SD), .SDcols = PV("ACH")][, y := y - wmean(y, W_FSTUWT), by = CNT][, .(y = wmean(y, W_FSTUWT)), by = .(CNT, age_m)][, .(score = mean(y), systems = .N), by = age_m][order(age_m)]
fwrite(prof, paste0(OUT, "flat_profile_by_month.csv"))

# ---- (b) age slope inside the cutoff systems ----
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
for (q in 1:10) a[, (paste0("PV", q, "ACH")) := (get(paste0("PV", q, "MATH")) + get(paste0("PV", q, "READ")) + get(paste0("PV", q, "SCIE"))) / 3]
wald <- function(y, D, Z, w) (wmean(y[Z == 1], w[Z == 1]) - wmean(y[Z == 0], w[Z == 0])) / (wmean(D[Z == 1], w[Z == 1]) - wmean(D[Z == 0], w[Z == 0]))
CU <- sort(unique(a$CNT))
age_cut <- rbindlist(parallel::mclapply(CU, function(cn) { s <- a[CNT == cn]
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) { g <- grade_gain(dt, y, w)
    c(age_year = unname(g["gamma"] - g["tau"]), tau = unname(g["tau"]), wald_y = wald(y, dt$D, dt$Z, w), wald_r = wald(dt$r, dt$D, dt$Z, w)) }, PV("ACH"))) }, mc.cores = 6))
age_cut[, group := "cutoff"]
ages <- rbind(age_flat, age_cut[term == "age_year"]); fwrite(rbind(age_flat, age_cut), paste0(OUT, "age_profile_sys.csv"))
pl <- ages[term == "age_year", pool(est, se), by = group]
fwrite(pl, paste0(OUT, "age_profile_pool.csv"))
bf <- pl[group == "flat"]; bc <- pl[group == "cutoff"]
dif <- bc$re_mean - bf$re_mean; dif_se <- sqrt(bc$re_se^2 + bf$re_se^2)

# ---- (c) pooled design: tau with the flat systems' age slope ----
# score = a + tau D - (age_year / 12) r: with the slope fixed, tau is the instrument estimate of score + (age_year / 12) r on grade.
b <- bf$re_mean / 12; b_se <- bf$re_se / 12; b_sd <- bf$tau_sd / 12
pd <- rbindlist(parallel::mclapply(CU, function(cn) { s <- a[CNT == cn]
  data.table(CNT = cn, pisa_est(s, function(dt, y, w) c(tau_pooled = wald(y + b * dt$r, dt$D, dt$Z, w)), PV("ACH"))) }, mc.cores = 6))
pd <- merge(pd[, .(CNT, tau_pooled = est, se_fixed_slope = se)], dcast(age_cut[term %in% c("tau", "wald_r")], CNT ~ term, value.var = c("est", "se")), by = "CNT")
pd[, se_varying_slope := sqrt(se_fixed_slope^2 + (b_sd * est_wald_r)^2)]     # the system's own slope may differ from the flat mean
setnames(pd, c("est_tau", "se_tau"), c("tau_step1", "se_step1")); fwrite(pd, paste0(OUT, "pooled_design_sys.csv"))
common <- b_se * abs(mean(pd$est_wald_r))                                     # error of the borrowed mean slope, shared by all systems
pp <- rbind(pd[, pool(tau_step1, se_step1)][, design := "step 1: slope estimated in each system"],
            pd[, pool(tau_pooled, se_fixed_slope)][, design := "pooled: one common slope"],
            pd[, pool(tau_pooled, se_varying_slope)][, design := "pooled: slope varies across systems"])
pp[design != "step 1: slope estimated in each system", re_se := sqrt(re_se^2 + common^2)]
fwrite(pp, paste0(OUT, "pooled_design_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "02_age_profile", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  flat = FL, cutoff = CU, excluded = EXCLUDE, flat_threshold = FLAT_MAX, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, "03_outputs/01_harmonized/cutoff_provider.rds", code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
cat("\nflat systems:", paste(FL, collapse = " "), "\n\nage slope, points per year older\n")
print(pl[, .(group, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)])
cat(sprintf("cutoff minus flat: %.1f (SE %.1f), z = %.2f\n", dif, dif_se, dif / dif_se))
cat("curvature in flat systems (per month squared):"); print(age_flat[term == "curve", pool(est, se)][, .(re = round(re_mean, 3), se = round(re_se, 3), pos_05, pos_10, neg_05, neg_10)])
cat("\nprofile in flat systems, system-demeaned score by months older than the youngest\n"); print(prof[, .(age_m, score = round(score, 1), systems)])
cat("linear fit of the 12 points: R2 =", round(summary(lm(score ~ age_m, prof))$r.squared, 3), "\n\nsame-age gain tau\n")
print(pp[, .(design, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)])
cat("median per-system SE: step 1", round(median(pd$se_step1), 1), "| pooled, common slope", round(median(pd$se_fixed_slope), 1), "| pooled, varying slope", round(median(pd$se_varying_slope), 1), "\n")
log_step("done"); sink()
