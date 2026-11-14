# EPF post-Soviet paper -- Model 3: linear quantile mixed models (lqmm), one per system, tau = .25 / .50 / .75
#   core   : score ~ grade_c + birth-month dummies + student + household + school inputs, random intercept by school
#   skills : core + Big Five domain scores, skills sample (IPW folded into the cluster weights)
# Weights: lqmm takes cluster-level weights, so the school mean of the final student weight (normalised to mean 1) is used; for the skills
# model it is multiplied by the school mean of the inverse-probability weight. Inference: school block bootstrap (boot.lqmm, R = NBOOT) on PV1
# for the sampling variance; in the FULL profile point estimates are averaged over 10 PVs and the between-PV variance is added (Rubin).
# Usage: PISA_CNT=GEO PISA_DOMAIN=SCIE PISA_PROFILE=FAST Rscript 02_scripts/epf_postsoviet/06_lqmm.R      Output: <DOMAIN>/lqmm_<CNT>.csv
# Rows with tau = "0.25-0.75" carry the quantile contrast and its bootstrap SE (added 1 Oct; present only in outputs produced after that date).
suppressPackageStartupMessages({ library(data.table); library(lqmm) })
source("02_scripts/epf_postsoviet/00_helpers.R")
CNT_RUN <- Sys.getenv("PISA_CNT", "GEO"); TAUS <- c(.25, .5, .75)
a <- load_analytic(); s_all <- a[CNT == CNT_RUN]
if (nrow(s_all) == 0) stop("no data for ", CNT_RUN, " in domain ", DOMAIN)
s_all[, w_school := mean(W_FSTUWT), by = school]; s_all[, w_school := w_school / mean(w_school)]
s_all[, w_school_sk := mean(W_FSTUWT * fifelse(is.na(ipw), 0, ipw)), by = school]; s_all[, w_school_sk := w_school_sk / mean(w_school_sk)]

fit_lqmm <- function(s, rhs, wcol, label) {
  rhs <- rhs[sapply(rhs, function(v) is.factor(s[[v]]) || sd(s[[v]], na.rm = TRUE) > 0)]
  f <- as.formula(paste("y ~", paste(rhs, collapse = " + ")))
  df <- as.data.frame(s)
  pvs <- PV[1:NPV]
  # the score is fitted in hundreds of points: lqmm's C routines overflow (NA/Inf) on raw PISA points once n exceeds ~14,000 (Kazakhstan); coefficients are rescaled x100 below
  fits <- lapply(pvs, function(p) { df$y <- df[[p]] / 100
    lqmm(fixed = f, random = ~1, group = school, tau = TAUS, nK = 7, type = "normal", data = df, weights = df[[wcol]], control = lqmmControl(LP_max_iter = 2000, UP_max_iter = 50)) })
  cf <- lapply(fits, coef)                                          # matrix term x tau
  est <- Reduce(`+`, cf) / length(cf)
  v_imp <- if (length(cf) > 1) (1 + 1 / length(cf)) * Reduce(`+`, lapply(cf, function(m) (m - est)^2)) / (length(cf) - 1) else est * 0
  log_step(CNT_RUN, label, "fits done; bootstrap R =", NBOOT)
  b <- boot(fits[[1]], R = NBOOT, seed = 20260930)                 # array R x term x tau, block bootstrap over schools
  bb <- b[, rownames(est), , drop = FALSE]                           # boot array also carries reStruct and scale: keep fixed effects only
  n_ok <- apply(bb, 3, function(m) sum(complete.cases(m)))          # replicates that converged (a failed replicate returns NA)
  v_samp <- apply(bb, c(2, 3), var, na.rm = TRUE)
  est <- est * 100; v_imp <- v_imp * 1e4; v_samp <- v_samp * 1e4       # back to PISA points
  out <- rbindlist(lapply(seq_along(TAUS), function(j) data.table(term = rownames(est), tau = TAUS[j], est = est[, j], se = sqrt(v_samp[, j] + v_imp[, j]),
                                                                    se_samp = sqrt(v_samp[, j]), se_imp = sqrt(v_imp[, j]), n_boot_ok = n_ok[j])))
  # quantile contrast beta(0.25) - beta(0.75): the test of whether an input compresses (> 0) or widens (< 0) the conditional distribution;
  # its variance comes from the bootstrap draws of the difference, so the positive correlation between the two quantile estimates is respected
  d25 <- bb[, , which(TAUS == .25)] * 100; d75 <- bb[, , which(TAUS == .75)] * 100
  diff_draws <- d25 - d75
  out <- rbind(out, data.table(term = rownames(est), tau = "0.25-0.75", est = est[, 1] - est[, 3], se = apply(diff_draws, 2, sd, na.rm = TRUE),
                               se_samp = apply(diff_draws, 2, sd, na.rm = TRUE), se_imp = sqrt(v_imp[, 1] + v_imp[, 3]), n_boot_ok = min(n_ok)), fill = TRUE)
  out[, `:=`(model = label, CNT = CNT_RUN, n = nrow(s), schools = uniqueN(s$school), n_pv = NPV, n_boot = NBOOT, profile = PROFILE, domain = DOMAIN)]
  out
}
t0 <- Sys.time()
rhs_core <- c("grade_c", "bmonth", student_ctrl, hh_ctrl, school_ctrl)
res <- rbind(fit_lqmm(s_all, rhs_core, "w_school", "core"),
             fit_lqmm(s_all[skills_ok == 1], c(rhs_core, skill_dom), "w_school_sk", "skills"))
fwrite(res, op(paste0("lqmm_", CNT_RUN, ".csv")))
print(dcast(res[term %in% c("grade_c", "ESCS_pct10", "sch_escs_loo", skill_dom)], model + term ~ tau, value.var = "est")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
log_step(CNT_RUN, "lqmm done in", format(Sys.time() - t0))
