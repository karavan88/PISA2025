# EPF post-Soviet paper -- Model 4: heterogeneity by separate estimation (no interaction terms), one system per run
#   by ESCS quintile (within-system, weighted)        : core WLS model, skills WLS model, and (HET_LQMM=1) the core lqmm at tau = .25/.50/.75
#   by school-composition tercile (LOO school mean)   : core WLS model
# ESCS_pct10 stays in the within-group models (variation inside a quintile); sch_escs_loo stays in the within-tercile models.
# Usage: PISA_CNT=GEO [HET_LQMM=1] Rscript 02_scripts/epf_postsoviet/07_heterogeneity.R     Output: <DOMAIN>/het_<CNT>.csv
suppressPackageStartupMessages({ library(data.table); library(lqmm) })
source("02_scripts/epf_postsoviet/00_helpers.R")
CNT_RUN <- Sys.getenv("PISA_CNT", "GEO"); HET_LQMM <- Sys.getenv("HET_LQMM", "0") == "1"; TAUS <- c(.25, .5, .75)
a <- load_analytic(); s_all <- a[CNT == CNT_RUN]
rhs_core <- c("grade_c", "bmonth", student_ctrl, hh_ctrl, school_ctrl); rhs_skills <- c(rhs_core, skill_dom)
fit_wls <- function(s, rhs, wcol = "W_FSTUWT") {
  X <- build_X(s, rhs)
  if (wcol != "W_FSTUWT") { s <- copy(s); f <- s[[wcol]] / s$W_FSTUWT; s[, W_FSTUWT := get(wcol)]; for (r in RW) s[, (r) := get(r) * f] }
  pisa_est(s, function(dt, y, w) wls(X, y, w))
}
res <- list()
for (q in levels(s_all$ses_q)) {
  s <- s_all[ses_q == q]; sk <- s[skills_ok == 1]
  r1 <- fit_wls(s, rhs_core); r1[, `:=`(model = "wls_core", group_var = "ses_quintile", group = q, n = nrow(s))]
  r2 <- fit_wls(sk, rhs_skills, "w_skills"); r2[, `:=`(model = "wls_skills", group_var = "ses_quintile", group = q, n = nrow(sk))]
  res[[paste("q", q)]] <- rbind(r1, r2)
  if (HET_LQMM) {
    s[, w_school := mean(W_FSTUWT), by = school]; s[, w_school := w_school / mean(w_school)]
    rhs <- rhs_core[sapply(rhs_core, function(v) is.factor(s[[v]]) || sd(s[[v]]) > 0)]
    df <- as.data.frame(s); df$y <- df[[PV[1]]] / 100            # hundreds of points (see 06_lqmm.R); rescaled below
    fit <- lqmm(fixed = as.formula(paste("y ~", paste(rhs, collapse = " + "))), random = ~1, group = school, tau = TAUS, nK = 7, data = df, weights = df$w_school, control = lqmmControl(LP_max_iter = 2000, UP_max_iter = 50))
    b <- boot(fit, R = NBOOT, seed = 20260930); cf <- coef(fit); vs <- apply(b[, rownames(cf), , drop = FALSE], c(2, 3), var, na.rm = TRUE); cf <- cf * 100; vs <- vs * 1e4
    r3 <- rbindlist(lapply(seq_along(TAUS), function(j) data.table(term = rownames(cf), est = cf[, j], se = sqrt(vs[, j]), se_samp = sqrt(vs[, j]), se_imp = 0, tau = TAUS[j])))
    r3[, `:=`(model = "lqmm_core", group_var = "ses_quintile", group = q, n = nrow(s))]
    res[[paste("lq", q)]] <- r3
    log_step(CNT_RUN, "quintile", q, "lqmm done")
  }
}
for (tg in levels(droplevels(s_all$sch_ter))) {
  s <- s_all[sch_ter == tg]
  r1 <- fit_wls(s, rhs_core); r1[, `:=`(model = "wls_core", group_var = "school_tercile", group = tg, n = nrow(s))]
  res[[paste("t", tg)]] <- r1
}
res <- rbindlist(res, fill = TRUE); res[, `:=`(CNT = CNT_RUN, domain = DOMAIN, profile = PROFILE)]
fwrite(res, op(paste0("het_", CNT_RUN, ".csv")))
print(dcast(res[term == "grade_c" & model == "wls_core"], group_var + group ~ ., value.var = "est", fun.aggregate = function(x) round(x[1], 1)))
log_step(CNT_RUN, "heterogeneity done")
