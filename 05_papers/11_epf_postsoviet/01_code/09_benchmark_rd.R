# EPF post-Soviet paper -- positive control for the cutoff design: the same fuzzy-RD estimator applied to systems with a mid-year
# school-entry cutoff where a school year is known to raise PISA scores (Czechia, Austria, Germany, Netherlands, England, Estonia, Chinese
# Taipei, Croatia, Serbia, ...), alongside the seven post-Soviet systems. Also reports the raw (model-free) means three months either side
# of the cutoff and the within-modal-grade age gradient (the upper bound on any relative-age effect that could mask a schooling gain).
# Cutoff: the month after which the weighted mean grade drops most. Sample: modal grade +/- 1 (benchmark: all programmes; post-Soviet: general).
# Output: <DOMAIN>/benchmark_rd.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/epf_postsoviet/00_helpers.R")
b <- fread("01_data/derived/epf_benchmark.csv.gz"); b[, group := "benchmark"]
p <- fread("01_data/derived/epf_students.csv.gz"); p <- p[general == 1]; p[, group := "post-Soviet"]
p[, `:=`(CNTSCHID = school, ST001D01T = grade, ST003D02T = bmonth, ST003D03T = 2009, ST004D01T = fifelse(female == 1, 1, 2))]   # harmonise names with the raw extract
keep <- c("CNT", "CNTSCHID", "ST001D01T", "ST003D02T", "ST003D03T", "ST004D01T", "ESCS", "W_FSTUWT", PV, RW, "group")
d <- rbind(b[, ..keep], p[, ..keep])
d <- d[!is.na(get(PV[1])) & !is.na(ST001D01T) & !is.na(ST003D02T) & !is.na(ESCS) & !is.na(ST004D01T)]
d[, m := (ST003D03T - 2009) * 12 + ST003D02T]              # months since January 2009
d[, female := as.numeric(ST004D01T == 1)]
d[, modal := { t <- tapply(W_FSTUWT, ST001D01T, sum); as.numeric(names(t)[which.max(t)]) }, by = CNT]
d[, grade_c := ST001D01T - modal]; d <- d[abs(grade_c) <= 1]

res <- list()
for (c in sort(unique(d$CNT))) {
  s <- d[CNT == c]
  mg <- s[, .(g = wmean(grade_c, W_FSTUWT), n = .N), by = m][order(m)][n >= 100]
  if (nrow(mg) < 6) next
  drops <- head(mg$g, -1) - tail(mg$g, -1); j <- which.max(drops)
  cut <- mg$m[j]                                                 # last month before the cutoff
  s[, r := m - cut - 0.5]; s[, Z := as.numeric(r > 0)]
  if (mean(s$Z) < 0.1 || mean(s$Z) > 0.9) next
  Xf <- function(dt) build_X(dt, c("Z", "r", "Z:r", "ESCS", "female"))
  stat <- function(dt, y, w) { X <- Xf(dt); fs <- wls(X, dt$grade_c, w)["Z"]; rf <- wls(X, y, w)["Z"]; c(first_stage = unname(fs), reduced_form = unname(rf), wald = unname(rf / fs)) }
  e <- pisa_est(s, stat)
  raw <- s[abs(r) <= 3, .(score = wmean(get(PV[1]), W_FSTUWT), grade = wmean(grade_c, W_FSTUWT), age_m = wmean(m, W_FSTUWT), n = .N), by = .(after = Z)]
  ag <- s[grade_c == 0, { f <- lm(get(PV[1]) ~ I(-m) + ESCS + female, weights = W_FSTUWT); .(slope = coef(f)[2], se = sqrt(diag(vcov(f)))[2]) }]
  res[[c]] <- data.table(CNT = c, group = s$group[1], n = nrow(s), modal_grade = s$modal[1], cutoff_after_month = cut + 1, share_after = round(mean(s$Z), 2),
                         first_stage = e[term == "first_stage", est], fs_se = e[term == "first_stage", se],
                         reduced_form = e[term == "reduced_form", est], rf_se = e[term == "reduced_form", se],
                         wald = e[term == "wald", est], wald_se = e[term == "wald", se],
                         raw_score_before = raw[after == 0, score], raw_score_after = raw[after == 1, score], raw_grade_before = raw[after == 0, grade], raw_grade_after = raw[after == 1, grade],
                         within_grade_pts_per_month_older = ag$slope, within_grade_se = ag$se)
  log_step(c, "cutoff after month", cut + 1, "FS", round(res[[c]]$first_stage, 2), "RF", round(res[[c]]$reduced_form, 1), "Wald", round(res[[c]]$wald, 1))
}
res <- rbindlist(res); res[, domain := DOMAIN]
fwrite(res, op("benchmark_rd.csv"))
print(res[, .(CNT, group, cutoff_after_month, first_stage = round(first_stage, 2), reduced_form = round(reduced_form, 1), rf_se = round(rf_se, 1), wald = round(wald, 1), wald_se = round(wald_se, 1),
              raw_diff = round(raw_score_after - raw_score_before, 1), age_slope = round(within_grade_pts_per_month_older, 2))][order(group, -wald)])
