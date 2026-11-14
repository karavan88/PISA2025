# Grade Gain Report -- estimation, one system at a time
# Headline (Avvisati & Givord 2021): y = a + beta*ssa + gamma*grade + delta'x + e, actual grade (D = upper grade) instrumented by the theoretical
#   grade Z = 1[born before the cutoff]; ssa = school-starting age in months (linear); x = female, immigrant, ESCS (within-system z); whole cohort.
#   Within a one-year cohort ssa = const - r - 12*D, so the 2SLS of y on [D, r, x] with instrument Z gives
#     coef_D = tau   : fixed-age contrast (one more year of school, one year younger at entry -- youngest in the grade)
#     -12*coef_r = beta : one more year of age at test (= one more year of starting age) inside a grade
#     gamma = tau + beta : one more year of schooling with its year of age, starting age fixed -- the "grade gain" of record
#   Variants: ag_cov (headline), ag_nocov (no covariates). Benchmark: lsdv = WLS of y on D + birth-month dummies + covariates, whole cohort
#   (the "grade coefficient" of cross-sectional production functions; selection into early entry and out of repetition included).
# Outcomes: science, mathematics, reading (points, 10 PVs); seven scales (within-system SD); growth mindset (probability).
# Inference: Fay BRR over 80 replicate weights + Rubin over PVs; every quantity recomputed per replicate so gamma's SE respects covariances.
# Usage: Rscript 02_scripts/gradegain/03_gradegain.R [CNT ...]      Output: 03_outputs/gradegain/estimates.csv (long: CNT, outcome, spec, term, est, se)
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/gradegain/00_helpers.R")
a <- load_analytic(); args <- commandArgs(trailingOnly = TRUE); systems <- if (length(args)) args else sort(unique(as.character(a$CNT)))
tsls <- function(y, D, Z, W, w) {
  ok <- !is.na(y) & complete.cases(W) & !is.na(D) & !is.na(w)
  X1 <- cbind(W, Z = Z)[ok, , drop = FALSE]; b1 <- lm.wfit(X1, D[ok], w[ok])$coefficients; Dhat <- as.numeric(X1 %*% b1)
  X2 <- cbind(W, D = Dhat)[ok, , drop = FALSE]; b2 <- lm.wfit(X2, y[ok], w[ok])$coefficients
  c(fs = unname(b1["Z"]), tau = unname(b2["D"]), beta = unname(-12 * b2["r"]), gamma = unname(b2["D"] - 12 * b2["r"]))
}
res <- list()
for (cn in systems) {
  s <- a[CNT == cn]
  covs <- c("female", "immigrant", "ESCS_z"); covs <- covs[sapply(covs, function(v) mean(!is.na(s[[v]])) > 0.5)]   # a covariate missing for most students is dropped (e.g. ESCS in Costa Rica)
  for (spec in c("ag_cov", "ag_nocov", "lsdv")) {
    ss <- if (spec == "ag_nocov") s else s[complete.cases(s[, ..covs])]
    if (nrow(ss) < 200) next
    if (spec == "lsdv") { ss[, bm := factor(bmonth)]; X <- model.matrix(as.formula(paste("~ D + bm +", paste(covs, collapse = " + "))), ss) }
    else W <- if (spec == "ag_cov") cbind(1, r = ss$r, as.matrix(ss[, ..covs])) else cbind(1, r = ss$r)
    for (o in OUTCOMES) {
      ys <- if (is_score(o)) PV(o) else o
      if (sum(!is.na(ss[[ys[1]]])) < 100) next                             # scale not fielded in this system
      e <- if (spec == "lsdv") pisa_est(ss, function(dt, y, wt) c(lsdv = unname(wls(X, y, wt)["D"])), ys)
           else pisa_est(ss, function(dt, y, wt) tsls(y, dt$D, dt$Z, W, wt), ys)
      res[[length(res) + 1]] <- data.table(CNT = cn, name = SYS_NAMES[cn], region = REGION[cn], outcome = o, spec = spec, covariates = if (spec == "ag_nocov") "" else paste(covs, collapse = "+"), n = sum(!is.na(ss[[ys[1]]])), e)
    }
  }
  log_step(cn, "done")
}
res <- rbindlist(res)
out <- op("estimates.csv")
if (length(args) && file.exists(out)) res <- rbind(fread(out)[!CNT %in% systems], res, fill = TRUE)
fwrite(res, out)
print(dcast(res[spec == "ag_cov" & outcome == "SCIE"], CNT ~ term, value.var = "est", fun.aggregate = function(x) round(x[1], 1)))
log_step("estimation done")
