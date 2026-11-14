# Grade Gain Report -- summaries across systems: median and IQR (the paper's primary summary) and a random-effects meta-analysis
# (REML, metafor) of the per-system estimates with their BRR standard errors -- the formal counterpart of the median: a pooled mean with
# its SE, the between-system SD of the true effects and I2. Regions are labels; medians by region are reported, never pooled models.
# Usage: Rscript 02_scripts/gradegain/04_summary.R        Output: 03_outputs/gradegain/summary.csv, summary_region.csv, shrunken.csv
suppressPackageStartupMessages({ library(data.table); library(metafor) })
source("02_scripts/gradegain/00_helpers.R")
r <- fread(op("estimates.csv")); elig <- fread(op("eligibility.csv"))
r <- merge(r, elig[, .(CNT, edge, jump)], by = "CNT")
# metafor's rma() evaluates its arguments by name, which fails inside data.table's grouping environment: fit it from a plain loop
rma_safe <- function(yvec, svec) { assign("..y", yvec, envir = .GlobalEnv); assign("..s", svec, envir = .GlobalEnv)
  tryCatch(rma(yi = ..y, sei = ..s, method = "REML"), error = function(e) NULL) }
groups <- unique(r[, .(outcome, spec, term)])
summ <- rbindlist(lapply(seq_len(nrow(groups)), function(i) {
  g <- groups[i]; x <- r[outcome == g$outcome & spec == g$spec & term == g$term]; f <- rma_safe(x$est, x$se)
  data.table(g, n_sys = nrow(x), median = median(x$est), q25 = quantile(x$est, .25), q75 = quantile(x$est, .75), sig_pos = sum(x$est / x$se > 1.96), sig_neg = sum(x$est / x$se < -1.96),
             re_mean = if (is.null(f)) NA_real_ else as.numeric(f$b), re_se = if (is.null(f)) NA_real_ else f$se, re_p = if (is.null(f)) NA_real_ else f$pval,
             tau_sd = if (is.null(f)) NA_real_ else sqrt(f$tau2), I2 = if (is.null(f)) NA_real_ else f$I2) }))
fwrite(summ, op("summary.csv"))
summ_clean <- r[edge == FALSE, .(n_sys = .N, median = median(est), q25 = quantile(est, .25), q75 = quantile(est, .75), sig_pos = sum(est / se > 1.96), sig_neg = sum(est / se < -1.96)), by = .(outcome, spec, term)]
fwrite(summ_clean, op("summary_clean_only.csv"))
reg <- r[, .(n_sys = .N, median = median(est), sig_pos = sum(est / se > 1.96), sig_neg = sum(est / se < -1.96)), by = .(outcome, spec, term, region)]
fwrite(reg, op("summary_region.csv"))
shr <- rbindlist(lapply(unique(r$outcome), function(o) { x <- r[spec == "ag_cov" & term == "gamma" & outcome == o]; f <- rma_safe(x$est, x$se); if (is.null(f)) return(NULL); b <- blup(f)
  data.table(outcome = o, CNT = x$CNT, raw = x$est, raw_se = x$se, shrunk = b$pred, shrunk_se = b$se) }))
fwrite(shr, op("shrunken.csv"))
print(summ[spec == "ag_cov" & term == "gamma", .(outcome, n_sys, median = round(median, 2), q25 = round(q25, 2), q75 = round(q75, 2), sig_pos, sig_neg, re_mean = round(re_mean, 2), re_se = round(re_se, 2), tau_sd = round(tau_sd, 2), I2 = round(I2))])
print(summ[spec == "ag_cov" & term == "tau", .(outcome, median = round(median, 2), sig_pos, sig_neg, re_mean = round(re_mean, 2), re_se = round(re_se, 2))])
print(summ[spec == "lsdv", .(outcome, median_lsdv = round(median, 1), re_mean = round(re_mean, 1))])
