# sestransmit -- validation of the cross-product estimator (03_estimate.R) against lm() and mediation::mediate()/medsens()
# Hong Kong, science, student-adjusted specification, curiosity as mediator. Writes 03_outputs/sestransmit/audit/validation.csv
source("02_scripts/sestransmit/00_helpers.R")
suppressPackageStartupMessages(library(mediation))
a <- readRDS("01_data/derived/sestransmit_analytic.rds"); med_list <- attr(a, "med_list")
R <- fread(tp("estimates_long.csv"))[run == "main" & domain == "SCIE" & spec == "student" & CNT == "HKG"]
dt <- a[CNT == "HKG"]; meds <- med_list[["HKG"]]
ctrl <- c(stu_ctrl, paste0(stu_ctrl, "_mis")); ctrl <- ctrl[sapply(ctrl, function(v) var(dt[[v]]) > 0)]
cs <- paste(ctrl, collapse = " + ")
pvs <- paste0("PV", 1:10, "SCIE")
# lm-based estimates, averaged over ten plausible values
fit <- rbindlist(lapply(pvs, function(p) {
  m0 <- lm(as.formula(paste(p, "~ ESCS_pct10 +", cs)), dt, weights = W_FSTUWT)
  mj <- lm(as.formula(paste(p, "~ ESCS_pct10 +", paste(meds, collapse = "+"), "+", cs)), dt, weights = W_FSTUWT)
  mm <- lm(as.formula(paste("CURIO ~ ESCS_pct10 +", cs)), dt, weights = W_FSTUWT)
  my <- lm(as.formula(paste(p, "~ CURIO + ESCS_pct10 +", cs)), dt, weights = W_FSTUWT)
  data.table(stat = c("beta_tot", "beta_dir", "pi_CURIO", "b_CURIO", "acme_CURIO", "gamma_CURIO"),
             lm = c(coef(m0)["ESCS_pct10"], coef(mj)["ESCS_pct10"], coef(mm)["ESCS_pct10"], coef(my)["CURIO"],
                    coef(mm)["ESCS_pct10"] * coef(my)["CURIO"], coef(mj)["CURIO"]))
}))[, .(lm = mean(lm)), by = stat]
cmp <- merge(fit, R[, .(stat, crossprod = est)], by = "stat")
# mediate() on PV1: quasi-Bayesian point estimate of the ACME; medsens() rho at which the ACME is zero
set.seed(1)
mm <- lm(as.formula(paste("CURIO ~ ESCS_pct10 +", cs)), dt, weights = W_FSTUWT)
my <- lm(as.formula(paste("PV1SCIE ~ CURIO + ESCS_pct10 +", cs)), dt, weights = W_FSTUWT)
med <- mediate(mm, my, treat = "ESCS_pct10", mediator = "CURIO", sims = 500, control.value = 0, treat.value = 1)
sens <- medsens(med, rho.by = 0.01, sims = 100, effect.type = "indirect")
pv1 <- data.table(stat = c("acme_CURIO (PV1)", "rho_CURIO (PV1)"),
                  lm = c(coef(mm)["ESCS_pct10"] * coef(my)["CURIO"], NA),
                  package = c(med$d0, if (length(sens$err.cr.d)) sens$err.cr.d[1] else NA_real_))
# crossprod rho* on PV1 recomputed directly: partial correlation of CURIO and PV1SCIE given controls and exposure
rM <- resid(mm); rY <- resid(lm(as.formula(paste("PV1SCIE ~ ESCS_pct10 +", cs)), dt, weights = W_FSTUWT))
pv1[stat == "rho_CURIO (PV1)", crossprod_formula := sum(dt$W_FSTUWT * rM * rY) / sqrt(sum(dt$W_FSTUWT * rM^2) * sum(dt$W_FSTUWT * rY^2))]
out <- rbind(cmp, pv1, fill = TRUE)
out[, rho_star_10pv := R[stat == "rho_CURIO", est]]
fwrite(out, ap("validation.csv")); options(digits = 6); print(out)
