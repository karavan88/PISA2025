# EPF post-Soviet paper -- Model 2: fuzzy regression discontinuity at the school-entry cutoff (Georgia, Azerbaijan, Kazakhstan)
# Running variable r = birth month relative to the cutoff (months after the cutoff > 0). Students born after the cutoff enter school a
# year later and are one grade lower at 15; the first stage is the jump in grade_c at r = 0, the reduced form the jump in the score,
# and the Wald ratio RF/FS is the effect of one additional grade (school year). Age differs by at most a few months across the cutoff.
#   global : all 12 birth months, linear trend with a slope change at the cutoff, with and without the core covariates (BRR + PV inference)
#   local  : bandwidth of 3 months on each side, same parametrisation (BRR + PV inference)
#   rdrobust: local linear, uniform kernel, h = 3 and h = 2, school-clustered, with covariates; conventional and robust bias-corrected CIs (Rubin over PVs)
#   placebo: the global estimator at fake cutoffs 3 months before and after the true one (reduced form should be ~0)
#   quantile: reduced-form quantile regressions (tau = .25/.50/.75) on the cutoff indicator, school-cluster bootstrap, divided by the first stage
# Output: <DOMAIN>/rd_estimates.csv, rd_placebo.csv, rd_quantile.csv
suppressPackageStartupMessages({ library(data.table); library(rdrobust); library(quantreg) })
source("02_scripts/epf_postsoviet/00_helpers.R")
a <- load_analytic()
covs <- c(student_ctrl, hh_ctrl, school_ctrl)
res <- list(); plc <- list(); qres <- list()

wald_stat <- function(Xfun) function(dt, y, w) {           # returns first stage, reduced form, Wald ratio for one (y, w) pair
  X <- Xfun(dt); fs <- wls(X, dt$grade_c, w)["Z"]; rf <- wls(X, y, w)["Z"]; c(first_stage = unname(fs), reduced_form = unname(rf), wald = unname(rf / fs))
}
for (c in names(RD_SYS)) {
  s <- a[CNT == c]; cut <- RD_SYS[[c]]
  s[, r := as.numeric(bmonth) - cut + 0.5]; s[, Z := as.numeric(r > 0)]
  log_step(c, "cutoff month", cut, "n =", nrow(s), "share after cutoff", round(mean(s$Z), 2))
  for (spec in c("no_covs", "covs")) {
    rhs <- c("Z", "r", "Z:r", if (spec == "covs") covs)
    Xf <- function(dt) build_X(dt, rhs)
    g <- pisa_est(s, wald_stat(Xf)); g[, `:=`(CNT = c, method = "global_linear", spec = spec, h = 6, n = nrow(s))]
    sl <- s[abs(r) <= 3]
    l <- pisa_est(sl, wald_stat(Xf)); l[, `:=`(CNT = c, method = "local_linear_h3", spec = spec, h = 3, n = nrow(sl))]
    res[[paste(c, spec)]] <- rbind(g, l)
  }
  # rdrobust, PV by PV, Rubin-combined; covariates included
  Xc <- build_X(s, covs)[, -1, drop = FALSE]
  for (h in c(3, 2)) {
    out <- lapply(PV, function(p) {
      m <- rdrobust(y = s[[p]], x = s$r, fuzzy = s$grade_c, c = 0, h = h, p = 1, kernel = "uniform", covs = Xc, cluster = as.integer(s$school), masspoints = "adjust", weights = s$W_FSTUWT)
      c(est_conv = m$coef[1], se_conv = m$se[1], est_bc = m$coef[2], se_rob = m$se[3], n_left = m$N_h[1], n_right = m$N_h[2])
    })
    o <- do.call(rbind, out)
    rc <- rubin(o[, "est_conv"], o[, "se_conv"]^2); rb <- rubin(o[, "est_bc"], o[, "se_rob"]^2)
    res[[paste(c, "rdrobust", h)]] <- data.table(term = c("wald", "wald"), est = c(rc$est, rb$est), se = c(rc$se, rb$se), se_samp = NA_real_, se_imp = NA_real_,
                                                 CNT = c, method = c("rdrobust_conventional", "rdrobust_robust_bc"), spec = "covs", h = h, n = o[1, "n_left"] + o[1, "n_right"])
  }
  # placebo cutoffs (global estimator, no covariates): the reduced form should be zero away from the true cutoff
  for (shift in c(-3, 3)) {
    s2 <- copy(s); s2[, r := r - shift]; s2[, Z := as.numeric(r > 0)]
    p <- pisa_est(s2, wald_stat(function(dt) build_X(dt, c("Z", "r", "Z:r")))); p[, `:=`(CNT = c, placebo_shift = shift)]
    plc[[paste(c, shift)]] <- p[term %in% c("first_stage", "reduced_form")]
  }
  # quantile reduced form (ITT) with school-cluster bootstrap, PV1; scaled by the global first stage with covariates
  fs_c <- res[[paste(c, "covs")]][method == "global_linear" & term == "first_stage", est]
  covs_c <- covs[sapply(covs, function(v) sd(s[[v]], na.rm = TRUE) > 0)]           # drop covariates constant in this system (e.g. no private schools)
  fq <- as.formula(paste("y ~ Z + r + Z:r +", paste(covs_c, collapse = " + ")))
  s[, y := get(PV[1])]
  for (tau in c(.25, .5, .75)) {
    m <- rq(fq, tau = tau, data = s, weights = W_FSTUWT)
    sm <- summary(m, se = "boot", R = 200, cluster = as.integer(s$school))
    qres[[paste(c, tau)]] <- data.table(CNT = c, tau = tau, term = c("reduced_form", "wald"), est = c(coef(m)["Z"], coef(m)["Z"] / fs_c),
                                        se = c(sm$coefficients["Z", 2], sm$coefficients["Z", 2] / abs(fs_c)), first_stage = fs_c)
  }
}
res <- rbindlist(res, fill = TRUE); res[, domain := DOMAIN]; fwrite(res, op("rd_estimates.csv"))
fwrite(rbindlist(plc), op("rd_placebo.csv")); fwrite(rbindlist(qres), op("rd_quantile.csv"))
print(res[term == "wald" | method %like% "rdrobust", .(CNT, method, spec, h, term, est = round(est, 1), se = round(se, 1))])
print(res[term != "wald" & method == "global_linear", .(CNT, spec, term, est = round(est, 2), se = round(se, 2))])
log_step("RD written")
