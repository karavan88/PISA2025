# Paper A -- random-slopes mixed model, estimated SEPARATELY for each economy (reading = primary outcome):
#   Y = fixed(ESCS, controls, school controls, all fielded skills) + u_school + random slope of each skill by ESCS decile
# i.e. the return to each skill is allowed to vary across the ten within-economy ESCS deciles (uncorrelated random slopes),
# as in the SSES-paper design (city-level models, skill slopes by SES group). Decile-specific return = fixed slope + BLUP.
# Weights: final student weights rescaled to mean 1 within economy (lme4 precision weights). PVs combined by Rubin's rules.
# Run: PISA_DOMAIN=READ Rscript 02_scripts/paperA/10_random_slopes.R [npv]
suppressPackageStartupMessages(library(lme4))
source("02_scripts/paperA/00_helpers.R")
args <- commandArgs(trailingOnly = TRUE); NPV <- if (length(args)) as.integer(args[1]) else 10
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
a[, dec := factor(escs_dec, levels = 1:10)]
a[, w1 := W_FSTUWT / mean(W_FSTUWT), by = CNT]
econ <- fread("01_data/derived/paperA_economies.csv")
ctrl <- lmerControl(optimizer = "bobyqa", calc.derivs = FALSE, optCtrl = list(maxfun = 2e5))

fit_economy <- function(d) {
  cnt <- as.character(d$CNT[1]); sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV")
  has_school <- cnt != "MAC"
  keep <- c("ESCS", controls, if (has_school) c("sch_escs_loo", "private", "urban_f")); keep <- keep[sapply(keep, function(v) uniqueN(d[[v]]) > 1)]
  fixed <- paste(c(keep, sk), collapse = " + ")
  f_rs <- as.formula(paste("y ~", fixed, if (has_school) "+ (1 | school)", "+ (0 +", paste(sk, collapse = " + "), "|| dec)"))
  f_ri <- as.formula(paste("y ~", fixed, if (has_school) "+ (1 | school)" else "+ (1 | dec)"))
  fx <- list(); bl <- list(); sds <- list(); lrt <- NULL
  for (i in seq_len(NPV)) {
    d[, y := get(PV[i])]
    m <- suppressMessages(lmer(f_rs, data = d, weights = w1, REML = TRUE, control = ctrl))
    fx[[i]] <- fixef(m)[sk]
    vc <- as.data.frame(VarCorr(m)); sds[[i]] <- vc[vc$grp != "Residual" & !is.na(vc$var1) & vc$var1 %in% sk, c("var1", "sdcor")]
    RE <- ranef(m, condVar = TRUE)$dec; pv <- attr(RE, "postVar")
    getcv <- function(j) if (is.list(pv)) as.numeric(pv[[j]][1, 1, ]) else as.numeric(pv[j, j, ])
    b <- rbindlist(lapply(seq_along(sk), function(j) data.table(dec = as.integer(rownames(RE)), skill = sk[j], blup = RE[[sk[j]]], cv = getcv(j))))
    b[, pv := i]; bl[[i]] <- b
    if (i == 1) { m0 <- suppressMessages(lmer(f_ri, data = d, weights = w1, REML = TRUE, control = ctrl)); an <- anova(m0, m, refit = FALSE)
      lrt <- data.table(CNT = cnt, chisq = an$Chisq[2], df = an$Df[2], p = an$`Pr(>Chisq)`[2]) }
  }
  FX <- do.call(rbind, fx); fixed_dt <- data.table(CNT = cnt, skill = sk, fixed = colMeans(FX), se_fixed_imp = sqrt((1 + 1 / NPV) * apply(FX, 2, var)))
  SD <- rbindlist(sds)[, .(slope_sd = mean(sdcor)), by = .(skill = var1)][, CNT := cnt]
  B <- rbindlist(bl)[, .(blup = mean(blup), var_cond = mean(cv), var_pv = if (.N > 1) var(blup) else 0), by = .(dec, skill)]
  B <- merge(B, fixed_dt[, .(skill, fixed)], by = "skill"); B[, `:=`(return = fixed + blup, se = sqrt(var_cond + (1 + 1 / NPV) * var_pv), CNT = cnt)]
  list(fixed = fixed_dt, sd = SD, dec = B, lrt = lrt)
}

out <- list()
for (c in levels(a$CNT)) { t0 <- Sys.time(); out[[c]] <- fit_economy(a[CNT == c]); cat(c, round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n") }
FX <- rbindlist(lapply(out, `[[`, "fixed")); SD <- rbindlist(lapply(out, `[[`, "sd")); DEC <- rbindlist(lapply(out, `[[`, "dec")); LRT <- rbindlist(lapply(out, `[[`, "lrt"))
for (x in list(FX, SD, DEC, LRT)) NULL
FX <- merge(FX, econ[, .(CNT, economy, bloc)], by = "CNT"); SD <- merge(SD, econ[, .(CNT, economy, bloc)], by = "CNT"); DEC <- merge(DEC, econ[, .(CNT, economy, bloc)], by = "CNT"); LRT <- merge(LRT, econ[, .(CNT, economy, bloc)], by = "CNT")
FX[, skill_lab := skill_lab[skill]]; SD[, skill_lab := skill_lab[skill]]; DEC[, skill_lab := skill_lab[skill]]
fwrite(FX, tp("h2rs_fixed_slopes_by_economy.csv")); fwrite(SD, tp("h2rs_slope_sd_by_economy.csv")); fwrite(DEC, tp("h2rs_decile_returns.csv")); fwrite(LRT, tp("h2rs_lrt_by_economy.csv"))

options(width = 230)
cat("\nRandom-slope SD across ESCS deciles (points per SD of skill), by economy:\n")
print(dcast(SD, bloc + economy ~ skill_lab, value.var = "slope_sd")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
cat("\nLRT random slopes by decile vs none (PV1):\n"); print(LRT[, .(economy, chisq = round(chisq, 1), df, p = signif(p, 2))])
# decile profile: return in decile 1 vs decile 10 and slope of return over deciles
prof <- DEC[, .(ret_d1 = return[dec == 1], ret_d10 = return[dec == 10], se_d1 = se[dec == 1], se_d10 = se[dec == 10],
                trend = coef(lm(return ~ dec))[2]), by = .(bloc, economy, skill_lab)]
prof[, `:=`(diff_d1_d10 = ret_d1 - ret_d10, se_diff = sqrt(se_d1^2 + se_d10^2))]
fwrite(prof, tp("h2rs_decile_profile.csv"))
cat("\nReturn in poorest vs richest decile (shrunken), and linear trend over deciles (points per decile):\n")
print(prof[, .(bloc, economy, skill_lab, d1 = round(ret_d1, 1), d10 = round(ret_d10, 1), diff = round(diff_d1_d10, 1), se_diff = round(se_diff, 1), trend = round(trend, 2))])
cat("\nBloc means of decile returns:\n")
print(dcast(DEC[, .(m = round(mean(return), 1)), by = .(bloc, skill_lab, dec)], bloc + skill_lab ~ dec, value.var = "m"))
cat("done random slopes by economy\n")
