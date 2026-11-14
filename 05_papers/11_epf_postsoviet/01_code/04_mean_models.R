# EPF post-Soviet paper -- Model 1: mean education production functions, one per system
#   M1a  gross      : score ~ grade_c + birth-month dummies                                   (conditional grade association, no controls)
#   M1b  core       : + student, household (ESCS percentile rank) and school inputs           (headline LSDV specification)
#   M1c  skills     : core + Big Five domain scores, skills sample, IPW x student weights     (RQ4)
#   M1d  within     : core with school fixed effects (weighted within-school transformation)  (school-level inputs absorbed)
#   M1e  lmer       : core with a school random intercept (continuity with the 2018 paper; unweighted); conditional ICC
# Inference: Fay BRR (80 replicate weights) on PV1 + Rubin over 10 PVs (M1a-d); lmer: Rubin over PVs of model-based SEs.
# Output: <DOMAIN>/mean_models.csv (long), <DOMAIN>/mean_icc.csv
suppressPackageStartupMessages({ library(data.table); library(lme4) })
source("02_scripts/epf_postsoviet/00_helpers.R")
a <- load_analytic()
# Age specification (PISA_AGE): bmonth = 11 birth-month dummies (default, the 2018-style age fixed effects); linear = age in months; none = no age term.
AGE_SPEC <- Sys.getenv("PISA_AGE", "bmonth"); AGE_SUF <- c(bmonth = "", linear = "_agelinear", none = "_agenone")[AGE_SPEC]
a[, age_months := 12 - as.numeric(bmonth)]                     # months older than a December-born student
age_term <- list(bmonth = "bmonth", linear = "age_months", none = character(0))[[AGE_SPEC]]
rhs_gross  <- c("grade_c", age_term)
rhs_core   <- c(rhs_gross, student_ctrl, hh_ctrl, school_ctrl)
rhs_skills <- c(rhs_core, skill_dom)

fit_wls <- function(s, rhs, wcol = "W_FSTUWT", label) {
  X <- build_X(s, rhs)
  if (wcol != "W_FSTUWT") { s <- copy(s); f <- s[[wcol]] / s$W_FSTUWT; s[, W_FSTUWT := get(wcol)]; for (r in RW) s[, (r) := get(r) * f] }   # IPW scales every replicate weight
  r <- pisa_est(s, function(dt, y, w) wls(X, y, w)); r[, model := label]; r
}
fit_within <- function(s, rhs, label) {                     # school fixed effects by weighted demeaning of y and X within school (per weight vector)
  rhs <- setdiff(rhs, school_ctrl); X <- build_X(s, rhs); X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  g <- s$school
  dm <- function(M, w) { M - rowsum(M * w, g)[as.character(g), , drop = FALSE] / rowsum(w, g)[as.character(g), 1] }
  r <- pisa_est(s, function(dt, y, w) { Xw <- dm(X, w); yw <- dm(matrix(y), w)[, 1]; f <- lm.wfit(Xw, yw, w); f$coefficients }); r[, model := label]; r
}
fit_lmer <- function(s, rhs, label) {
  f <- as.formula(paste("y ~", paste(rhs, collapse = " + "), "+ (1 | school)"))
  fits <- lapply(PV, function(p) { s2 <- copy(s); s2[, y := get(p)]; lmer(f, data = s2, REML = FALSE) })
  cf <- sapply(fits, fixef); se <- sapply(fits, function(m) sqrt(diag(as.matrix(vcov(m)))))
  est <- rowMeans(cf); v <- rowMeans(se^2) + (1 + 1 / length(PV)) * apply(cf, 1, var)
  icc <- sapply(fits, function(m) { vc <- as.data.frame(VarCorr(m)); vc$vcov[1] / sum(vc$vcov) })
  list(coef = data.table(term = names(est), est = est, se = sqrt(v), se_samp = NA_real_, se_imp = NA_real_, model = label), icc = mean(icc))
}

res <- list(); iccs <- list()
for (c in levels(a$CNT)) {
  s <- a[CNT == c]; sk <- s[skills_ok == 1]
  log_step(c, "n =", nrow(s), "skills n =", nrow(sk))
  r <- rbindlist(list(fit_wls(s, rhs_gross, label = "M1a_gross"), fit_wls(s, rhs_core, label = "M1b_core"),
                      fit_wls(sk, rhs_skills, wcol = "w_skills", label = "M1c_skills"), fit_wls(sk, rhs_core, wcol = "w_skills", label = "M1c_core_on_skills_sample"),
                      fit_within(s, rhs_core, label = "M1d_within")))
  lm <- fit_lmer(s, rhs_core, "M1e_lmer"); r <- rbind(r, lm$coef)
  r[, CNT := c]; r[, n := fifelse(model %in% c("M1c_skills", "M1c_core_on_skills_sample"), nrow(sk), nrow(s))]
  res[[c]] <- r; iccs[[c]] <- data.table(CNT = c, icc_conditional = lm$icc)
}
res <- rbindlist(res); res[, domain := DOMAIN]; res[, t := est / se]
res[, age_spec := AGE_SPEC]
fwrite(res, op(paste0("mean_models", AGE_SUF, ".csv"))); fwrite(rbindlist(iccs), op(paste0("mean_icc", AGE_SUF, ".csv")))
print(dcast(res[term == "grade_c"], CNT ~ model, value.var = "est")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])
log_step("mean models written")
