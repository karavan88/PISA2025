# Skills & the Grade Gain -- are socio-emotional skills a channel of the grade gain? Causal mediation.
# (1) Per system, BRR + Rubin, all quantities computed inside each replicate so their covariances are respected:
#       total    gamma_Y           grade gain in the score (2SLS, controls sex, immigrant, SES)
#       a-path   gamma_M           grade gain in the mediator M (causal: same instrument)
#       direct   gamma_Y|M         grade gain with M held fixed (M added as a control)
#       b-path   coefficient on M in the direct model (NOT protected by the instrument: needs sequential ignorability)
#       indirect total - direct (= a x b in a linear model); share = indirect / total
#     Mediators: SE (all four outcomes), SE_task and SE_open (achievement).
# (2) Pooled, the potential-outcomes mediation of Imai, Keele & Tingley (2010) with the theoretical grade Z as the treatment (intention-to-treat
#     scale; Z is as good as random given system and a system-specific linear birth-month trend) and the sensitivity analysis of Imai, Keele
#     & Yamamoto (2010): the correlation rho between the mediator and outcome errors at which the indirect effect would vanish.
# Output: 03_outputs/skillsgain/mediation.csv, mediation_pooled.csv
suppressPackageStartupMessages({ library(data.table); library(mediation) })
source("02_scripts/skillsgain/00_helpers.R")
a <- load_sg()
med_sys <- function(s, outcome, M) {
  ys <- PV(outcome); ctrl <- c("female", "immigrant", "SES"); ctrl <- ctrl[vapply(ctrl, function(v) mean(!is.na(s[[v]])) > 0.5, logical(1))]
  s <- s[complete.cases(s[, c(M, ctrl), with = FALSE])]
  X0 <- cbind(`(Intercept)` = 1, as.matrix(s[, ..ctrl])); XM <- cbind(X0, s[[M]]); colnames(XM)[ncol(XM)] <- "MED"; E <- matrix(numeric(0), nrow(s), 0)
  f <- function(dt, y, w) {
    tot <- tsls_m(y, dt$D, dt$Z, dt$r, E, X0, w)["gamma"]
    am  <- tsls_m(dt[[M]], dt$D, dt$Z, dt$r, E, X0, w)["gamma"]
    di  <- tsls_m(y, dt$D, dt$Z, dt$r, E, XM, w, extra = list(b = function(b2) unname(b2["MED"])))
    c(total = unname(tot), a_path = unname(am), direct = unname(di["gamma"]), b_path = unname(di["b"]), indirect = unname(tot - di["gamma"]), prod = unname(am * di["b"]))
  }
  e <- pisa_est(s, f, ys); e[, n := nrow(s)]; e
}
res <- parallel::mclapply(SYS20, function(cn) {
  s <- a[CNT == cn & !is.na(SE)]; if (nrow(s) < 500) return(NULL)
  out <- rbind(rbindlist(lapply(OUT4, function(o) data.table(CNT = cn, mediator = "SE", outcome = o, med_sys(s, o, "SE")))),
               rbindlist(lapply(c("SE_task", "SE_open"), function(m) data.table(CNT = cn, mediator = m, outcome = "ACH", med_sys(s, "ACH", m)))))
  log_step(cn, "done"); out }, mc.cores = as.integer(Sys.getenv("NCORES", "6")), mc.preschedule = FALSE)
res <- rbindlist(res); res[, `:=`(name = SYS_NAMES[CNT], group = GROUP[CNT])]
fwrite(res, os("mediation.csv"))
print(dcast(res[mediator == "SE" & outcome == "ACH"], CNT ~ term, value.var = "est", fun.aggregate = function(x) round(x[1], 2)))

# (2) pooled ITT mediation with sensitivity analysis (point estimates on the mean of the 10 PVs; quasi-Bayesian CIs), all systems with scales
#     and the same-school systems. Sex is missing for all of Germany (absorbed by its fixed effect), immigrant for Costa Rica and Mauritius.
st <- fread(os("structure.csv"))
p0 <- a[!is.na(SE) & !is.na(SES)]
p0[, ACHm := rowMeans(.SD), .SDcols = PV("ACH")]
p0[, wn := W_FSTUWT / sum(W_FSTUWT) * 1e4, by = CNT]
p0[is.na(female), female := 0]; p0[, immigrant_mis := as.numeric(is.na(immigrant))]; p0[is.na(immigrant), immigrant := 0]
fm <- SE ~ Z + CNT + CNT:r + female + immigrant + immigrant_mis + SES
fy <- ACHm ~ Z + SE + CNT + CNT:r + female + immigrant + immigrant_mis + SES
pooled <- list(); sens <- list()
for (nm in c("All with scales (19)", "Same-school (13 with scales)")) {
  p <- if (nm %like% "^All") copy(p0) else p0[CNT %in% st[structure == "Same-school", CNT]]
  p[, CNT := factor(CNT)]
  mm <- lm(fm, data = p, weights = wn); my <- lm(fy, data = p, weights = wn)
  for (m in list(mm, my)) if (any(is.na(coef(m)))) stop("aliased: ", paste(names(coef(m))[is.na(coef(m))], collapse = " "))
  set.seed(2025)
  mo <- mediate(mm, my, treat = "Z", mediator = "SE", sims = as.integer(Sys.getenv("MED_SIMS", "100")))
  ms <- medsens(mo, rho.by = 0.05, sims = as.integer(Sys.getenv("MED_SIMS", "100")), effect.type = "indirect")
  fs_pool <- coef(lm(D ~ Z + CNT + CNT:r + female + immigrant + immigrant_mis + SES, data = p, weights = wn))["Z"]
  pooled[[nm]] <- data.table(sample = nm, quantity = c("ACME (indirect, ITT)", "ADE (direct, ITT)", "Total (ITT)", "Proportion mediated", "First stage (pooled)", "rho at which ACME = 0", "R2*_M x R2*_Y at which ACME = 0"),
                       est = c(mo$d.avg, mo$z.avg, mo$tau.coef, mo$n.avg, fs_pool, ms$err.cr.d[1], ms$R2star.d.thresh[1]),
                       lo = c(mo$d.avg.ci[1], mo$z.avg.ci[1], mo$tau.ci[1], mo$n.avg.ci[1], NA, NA, NA), hi = c(mo$d.avg.ci[2], mo$z.avg.ci[2], mo$tau.ci[2], mo$n.avg.ci[2], NA, NA, NA), n = nobs(my))
  sens[[nm]] <- data.table(sample = nm, rho = ms$rho, acme = as.numeric(ms$d0), lo = as.numeric(ms$lower.d0), hi = as.numeric(ms$upper.d0))
  log_step(nm, "pooled mediation done")
}
fwrite(rbindlist(pooled), os("mediation_pooled.csv")); fwrite(rbindlist(sens), os("mediation_sens.csv"))
print(rbindlist(pooled))
