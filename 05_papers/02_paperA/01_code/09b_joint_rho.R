# Paper A -- sensitivity parameter rho* for the joint six-skill block (closed form; complements medsens() for single mediators)
# Under the linear structural equation model of Imai, Keele & Yamamoto (2010), the ACME is zero when the correlation rho between
# the mediator- and outcome-equation errors equals the correlation between the residuals of the mediator model and the residuals
# of the reduced-form outcome model (outcome on treatment and covariates, without the mediator). medsens() computes this for a
# single mediator; for the joint block the mediator is the index M* = sum_k gamma_k M_k, with gamma_k the outcome-model coefficients
# of the skills, so rho*_joint = corr(resid(M* ~ ESCS + X), resid(Y ~ ESCS + X)), weighted, averaged over plausible values.
# Country-level models only. Run: PISA_DOMAIN=READ Rscript 02_scripts/paperA/09b_joint_rho.R [--total]
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
a <- a[!is.na(get(TREAT_VAR))]; a[, CNT := droplevels(CNT)]
SCHOOL_CTRL <- !("--total" %in% commandArgs(trailingOnly = TRUE)); suffix <- if (SCHOOL_CTRL) "" else "_total"
wcor <- function(x, y, w) cov.wt(cbind(x, y), wt = w, cor = TRUE)$cor[1, 2]
cat("domain:", DOMAIN, " school controls:", SCHOOL_CTRL, "\n")

joint_rho <- function(d) {
  sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV")
  ctrl <- c(TREAT_COV, controls, if (SCHOOL_CTRL) c(SCH_LOO, "private", "urban_f"))
  ctrl <- ctrl[sapply(ctrl, function(v) uniqueN(d[[v]]) > 1)]
  if (all(d$CNT == "MAC")) ctrl <- setdiff(ctrl, SCH_LOO)
  d[, w := W_FSTUWT / mean(W_FSTUWT)]
  rho <- sapply(PV, function(pv) { d[, y := get(pv)]
    m0 <- lm(as.formula(paste("y ~", TREAT_VAR, "+", paste(ctrl, collapse = " + "))), data = d, weights = w)
    m1 <- lm(as.formula(paste("y ~", TREAT_VAR, "+", paste(sk, collapse = " + "), "+", paste(ctrl, collapse = " + "))), data = d, weights = w)
    d[, Mstar := as.vector(as.matrix(d[, sk, with = FALSE]) %*% coef(m1)[sk])]
    ms <- lm(as.formula(paste("Mstar ~", TREAT_VAR, "+", paste(ctrl, collapse = " + "))), data = d, weights = w)
    wcor(resid(ms), resid(m0), d$w) })
  data.table(unit = as.character(d$economy[1]), N = nrow(d), mediator = "All skills (joint)", rho_star = mean(rho), rho_sd_pv = sd(rho))
}
R <- rbindlist(lapply(levels(a$CNT), function(c) joint_rho(a[CNT == c])))
R[, domain := DOMAIN]; R[, spec := if (SCHOOL_CTRL) "within-school" else "total"]
R[, treat := TREAT]; fwrite(R, tp(paste0("h1_joint_rho", TSUF, suffix, ".csv")))
print(R[, .(unit, N, rho_star = round(rho_star, 3))]); cat("done joint rho\n")
