# Paper B -- fuzzy regression discontinuity at the school-entry cutoff, one system at a time
#   running variable r : birth month relative to the first post-cutoff month (r >= 0 born after the cutoff; r < 0 born before)
#   instrument Z = 1[r < 0]; treatment D = 1[upper grade]; outcome y
#   local linear in months: y = a + rf*Z + b1*r + b2*r*Z + e, D = c + fs*Z + ... ; tau = rf / fs (Wald / 2SLS with a single instrument)
#   specs: "ll" separate slopes on each side (needs >= 2 birth months on each side), "common" one slope, "diff" difference in means
#   bandwidths: h months on each side (left r in -h..-1, right r in 0..h-1; the partial cutoff month r = 0 is dropped where donut = 1)
#   inference: Fay BRR over the 80 replicate weights (schools are the sampling clusters) + Rubin over 10 PVs for achievement outcomes.
#   The running variable is discrete (12 birth months), so the BRR variance covers sampling error, not specification error (Lee & Card 2008):
#   the three specifications and bandwidths are the specification check.
# Usage: Rscript 02_scripts/paperB/03_rd.R [CNT ...]        Output: 03_outputs/paperB/rd_estimates.csv, rd_balance.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
a <- load_analytic()
args <- commandArgs(trailingOnly = TRUE); systems <- if (length(args)) args else SYS

design <- function(w, spec) {
  X <- switch(spec, ll = cbind(1, w$Z, w$r, w$r * w$Z), common = cbind(1, w$Z, w$r), diff = cbind(1, w$Z))
  colnames(X) <- c("(Intercept)", "Z", "r", "rZ")[seq_len(ncol(X))]; X
}
feasible <- function(w, spec) { nl <- uniqueN(w$r[w$Z == 1]); nr <- uniqueN(w$r[w$Z == 0]); if (spec == "ll") nl >= 2 & nr >= 2 else if (spec == "common") nl + nr >= 3 else nl >= 1 & nr >= 1 }
rd_stat <- function(X, D) function(dt, y, w) { ok <- !is.na(y); fs <- wls(X[ok, , drop = FALSE], D[ok], w[ok])["Z"]; rf <- wls(X[ok, , drop = FALSE], y[ok], w[ok])["Z"]; c(fs = unname(fs), rf = unname(rf), tau = unname(rf / fs)) }

res <- list(); bal <- list()
for (cn in systems) {
  s <- a[CNT == cn]; donut <- s$donut[1]
  for (h in BANDWIDTHS) {
    w <- s[r >= -h & r <= h - 1]; if (donut == 1) w <- w[r != 0]
    for (spec in c("ll", "common", "diff")) {
      if (spec == "diff" && h > 3) next                                # difference in means only at the narrow bandwidth
      if (!feasible(w, spec)) next
      X <- design(w, spec)
      for (y in c(out_skills, out_beliefs, PV_DOMS)) {
        ys <- if (y %in% PV_DOMS) PV(y) else y
        if (sum(!is.na(w[[ys[1]]])) < 100) next                           # scale not fielded in this system (e.g. PERSEV in KAZ, skills in USA)
        e <- pisa_est(w, rd_stat(X, w$D), ys)
        e <- dcast(melt(e, id.vars = "term"), . ~ term + variable)[, "." := NULL]
        res[[length(res) + 1]] <- data.table(CNT = cn, outcome = y, h = h, spec = spec, n = sum(!is.na(w[[ys[1]]])), n_left = sum(w$Z == 1 & !is.na(w[[ys[1]]])), n_right = sum(w$Z == 0 & !is.na(w[[ys[1]]])), donut = donut, e)
      }
      for (y in balance_vars) {                                        # covariates that must not jump at the cutoff (reduced form only)
        if (all(is.na(w[[y]]))) next
        e <- pisa_est(w, rd_stat(X, w$D), y)
        bal[[length(bal) + 1]] <- data.table(CNT = cn, covariate = y, h = h, spec = spec, n = sum(!is.na(w[[y]])), rf = e[term == "rf", est], rf_se = e[term == "rf", se], mean_cov = wmean(w[[y]], w$W_FSTUWT))
      }
    }
  }
  log_step(cn, "done")
}
res <- rbindlist(res); setnames(res, c("fs_est", "fs_se", "rf_est", "rf_se", "tau_est", "tau_se"), c("fs", "fs_se", "rf", "rf_se", "tau", "tau_se"), skip_absent = TRUE)
res <- res[, .(CNT, outcome, h, spec, n, n_left, n_right, donut, fs, fs_se, rf, rf_se, tau, tau_se, tau_se_samp = tau_se_samp, tau_se_imp = tau_se_imp)]
res[, `:=`(system = SYS_NAMES[CNT], region = REGION[CNT], tier = TIER[CNT], outcome_label = out_lab(outcome))]
out_file <- op("rd_estimates.csv"); bal_file <- op("rd_balance.csv")
if (length(args) && file.exists(out_file)) { old <- fread(out_file)[!CNT %in% systems]; res <- rbind(old, res, fill = TRUE); oldb <- fread(bal_file)[!CNT %in% systems]; bal <- rbind(oldb, rbindlist(bal), fill = TRUE) } else bal <- rbindlist(bal)
fwrite(res, out_file); fwrite(bal, bal_file)
print(dcast(res[h == 4 & spec %in% c("ll", "common") & outcome %in% c("PERSEV_z", "CURIO_z", "SCIE")][, .SD[1], by = .(CNT, outcome)], CNT ~ outcome, value.var = "tau", fun.aggregate = function(x) round(x[1], 2)))
log_step("rd done")
