# Paper B -- placebo cutoffs: the reduced form re-estimated at a fake cutoff three months away from the true one, on one side of it only
#   left placebo : students born before the cutoff (r < 0), fake cutoff between r = -4 and r = -3, window r in -6..-1   (needs >= 6 months left)
#   right placebo: students born after the cutoff (r >= 0), fake cutoff between r = 2 and r = 3, window r in 0..5        (needs >= 6 months right)
#   Nothing should jump at a fake cutoff. Separate slopes on each side of the fake cutoff; BRR + Rubin inference as in 03_rd.R.
# Usage: Rscript 02_scripts/paperB/05_placebo.R          Output: 03_outputs/paperB/rd_placebo.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
a <- load_analytic(); res <- list()
rf_stat <- function(X) function(dt, y, w) { ok <- !is.na(y); c(rf = unname(wls(X[ok, , drop = FALSE], y[ok], w[ok])["Zp"])) }
for (cn in SYS) {
  s <- a[CNT == cn]
  for (side in c("left", "right")) {
    w <- if (side == "left") s[r >= -6 & r <= -1] else s[r >= 0 & r <= 5]
    if (uniqueN(w$r) < 6) next
    w[, Zp := as.numeric(if (side == "left") r < -3 else r < 3)]; w[, rp := if (side == "left") r + 3 else r - 3]
    X <- cbind(1, w$Zp, w$rp, w$rp * w$Zp); colnames(X) <- c("(Intercept)", "Zp", "rp", "rpZp")
    for (y in c(out_skills, "growth", "SCIE")) {
      ys <- if (y == "SCIE") PV(y) else y
      if (sum(!is.na(w[[ys[1]]])) < 100) next
      e <- pisa_est(w, rf_stat(X), ys)
      res[[length(res) + 1]] <- data.table(CNT = cn, system = SYS_NAMES[cn], tier = TIER[cn], side = side, outcome = y, outcome_label = out_lab(y), n = sum(!is.na(w[[ys[1]]])), rf = e$est, rf_se = e$se)
    }
  }
  log_step(cn, "placebo done")
}
res <- rbindlist(res); fwrite(res, op("rd_placebo.csv"))
print(res[, .(n_tests = .N, n_sig = sum(abs(rf / rf_se) > 1.96), median_rf = round(median(rf), 3)), by = outcome])
