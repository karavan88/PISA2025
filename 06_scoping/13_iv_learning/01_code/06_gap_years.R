# IV learning -- step 6: the socio-economic gap at 15 in years of learning. Cutoff systems with ESCS.
# Per system, estimated together in every replicate weight and plausible value (so their covariance is known):
#   gap3    mean achievement of the high SES third minus the low third (weighted thirds of ESCS within the system)
#   gapSD   achievement per standard deviation of SES (weighted regression of the score on ESCS_z)
#   gamma   yearly gain: one grade further and a year older (step 1's base model);  tau = schooling at a given age;  age = gamma - tau
# Yardstick: G, the random-effects mean of gamma across systems. A system's gap in school years is gap3 / G; its interval reflects the
# system's own sampling error, and the yardstick's error (common to all systems) is reported separately.
# Summary: R = mean gap3 / G. Its standard error is a jackknife over systems (each system left out in turn, both means recomputed),
# which carries the differences between systems and the covariance of gap and gain; the delta-method figure from sampling
# covariances alone is saved beside it as a check.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/06_gap_years.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]
SYS <- a[, .(escs = mean(!is.na(ESCS))), by = CNT][escs > 0, sort(CNT)]
TERMS <- c("gap3", "gapSD", "gamma", "tau", "age")
log_step("gap in school years on", length(SYS), "systems")
res <- parallel::mclapply(SYS, function(cn) { s <- a[CNT == cn]
  pisa_cov(s, function(dt, y, w) { g <- grade_gain(dt, y, w); k <- !is.na(dt$ESCS_z)
    c(gap3 = wmean(y[dt$ses3 == 3], w[dt$ses3 == 3]) - wmean(y[dt$ses3 == 1], w[dt$ses3 == 1]),
      gapSD = unname(lm.wfit(cbind(1, dt$ESCS_z[k]), y[k], w[k])$coefficients[2]),
      gamma = unname(g["gamma"]), tau = unname(g["tau"]), age = unname(g["gamma"] - g["tau"])) }, PV("ACH")) }, mc.cores = 6)
stopifnot(!any(vapply(res, function(x) inherits(x, "try-error") || is.null(x), logical(1))))
names(res) <- SYS
sy <- rbindlist(lapply(SYS, function(cn) { e <- res[[cn]]$est; V <- res[[cn]]$V
  data.table(CNT = cn, t(e), t(setNames(sqrt(diag(V)), paste0("se_", TERMS))), cov_gap3_gamma = V["gap3", "gamma"], cov_gapSD_gamma = V["gapSD", "gamma"]) }))
P <- function(d, tm) pool(d[[tm]], d[[paste0("se_", tm)]])
ratio <- function(d, gap) P(d, gap)$re_mean / P(d, "gamma")$re_mean
G <- P(sy, "gamma"); pl <- rbindlist(lapply(TERMS, function(tm) cbind(term = tm, P(sy, tm))))
summ <- rbindlist(lapply(c("gap3", "gapSD"), function(gap) { A <- P(sy, gap); R <- A$re_mean / G$re_mean; n <- nrow(sy)
  jk <- vapply(seq_len(n), function(i) ratio(sy[-i], gap), 0)
  wA <- 1 / (sy[[paste0("se_", gap)]]^2 + A$tau_sd^2); wG <- 1 / (sy$se_gamma^2 + G$tau_sd^2)
  cAG <- sum(wA * wG * sy[[paste0("cov_", gap, "_gamma")]]) / (sum(wA) * sum(wG))
  data.table(gap = gap, gap_points = A$re_mean, gap_se = A$re_se, yearly_gain = G$re_mean, yearly_gain_se = G$re_se, years = R,
             se_jackknife = sqrt((n - 1) / n * sum((jk - mean(jk))^2)), jackknife_min = min(jk), jackknife_max = max(jk),
             se_delta = sqrt(A$re_se^2 / G$re_mean^2 + A$re_mean^2 * G$re_se^2 / G$re_mean^4 - 2 * A$re_mean * cAG / G$re_mean^3)) }))
sy <- merge(sy, rules[, .(CNT, name)], by = "CNT")
sy[, `:=`(years3 = gap3 / G$re_mean, years3_se_system = se_gap3 / G$re_mean, years3_se_total = sqrt((se_gap3 / G$re_mean)^2 + (gap3 * G$re_se / G$re_mean^2)^2),
          yearsSD = gapSD / G$re_mean, yearsSD_se_system = se_gapSD / G$re_mean,
          own_years3 = gap3 / gamma, own_years3_se = sqrt(se_gap3^2 / gamma^2 + gap3^2 * se_gamma^2 / gamma^4 - 2 * gap3 * cov_gap3_gamma / gamma^3),
          own_gain_usable = gamma / se_gamma > qnorm(.975), flagged = CNT %in% FLAG)]
fwrite(sy, paste0(OUT, "gap_years_sys.csv")); fwrite(pl, paste0(OUT, "gap_years_pool.csv")); fwrite(summ, paste0(OUT, "gap_years_summary.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "06_gap_years", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
cat("\nrandom-effects means across systems, points\n"); print(pl[, .(term, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)])
cat("\nthe gap in school years\n"); print(summ[, .(gap, gap_points = round(gap_points, 1), yearly_gain = round(yearly_gain, 1), years = round(years, 2), se_jackknife = round(se_jackknife, 2), se_delta = round(se_delta, 2), jk_min = round(jackknife_min, 2), jk_max = round(jackknife_max, 2))])
cat(sprintf("split of the yearly gain: schooling at a given age %.1f, age %.1f; schooling share %.0f%%\n", pl[term == "tau", re_mean], pl[term == "age", re_mean], 100 * pl[term == "tau", re_mean] / G$re_mean))
cat("\nper system, gap between the high and low third in school years (common yardstick)\n")
print(sy[order(-years3), .(CNT, gap3 = round(gap3, 1), se = round(se_gap3, 1), years = round(years3, 2), lo = round(years3 - 1.96 * years3_se_system, 2), hi = round(years3 + 1.96 * years3_se_system, 2), own_gain = round(gamma, 1), own_years = ifelse(own_gain_usable, round(own_years3, 1), NA))], nrows = 40)
cat("systems whose own yearly gain is significant at 5%:", sy[own_gain_usable == TRUE, .N], "of", nrow(sy), "\n")
log_step("done"); sink()
