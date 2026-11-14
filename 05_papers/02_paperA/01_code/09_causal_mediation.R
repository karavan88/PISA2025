# Paper A -- causal mediation analysis with the `mediation` package (Imai, Keele & Tingley 2010; Tingley et al. 2014)
# Treatment: set by PISA_TREAT (00_helpers.R): ESCS_PCT = within-system percentile rank / 10 (headline), ESCS = index units (check),
# DEP = deprivation count conditional on ESCS. ACME per unit of the treatment and for the bottom-10% -> top-10% median contrast (DEP: one item).
# Mediators: each disposition in turn (single-mediator models; other skills not in the model). The six WLE scales are
# sample-standardised (02_prepare.R); growth mindset is binary (linear probability mediator model, see below).
# Outcome: PISA achievement in the domain given by PISA_DOMAIN (READ primary; MATH, SCIE parallel).
# Specification: --total = no school controls (total family gradient); default = with school controls (within-school gradient).
# Estimation: weighted lm for mediator and outcome models (final student weights within economy, senate weights in pooled
# units, both rescaled to mean 1); mediate() quasi-Bayesian Monte Carlo per plausible value, combined by Rubin's rules;
# medsens() sensitivity (rho at which ACME = 0; R^2 thresholds) on PV1. Joint mediated effect of the six-skill block =
# total effect minus direct effect from the outcome model with all skills (equals sum of Gelbach contributions).
# Run: PISA_DOMAIN=READ Rscript 02_scripts/paperA/09_causal_mediation.R [--total]
suppressPackageStartupMessages({library(mediation)})
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
a <- a[!is.na(get(TREAT_VAR))]; a[, CNT := droplevels(CNT)]
cat("treatment:", TREAT, "->", TREAT_VAR, "\n")
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- levels(a$bloc); ord <- c(econ$economy, blocs, ALL_LAB)
SCHOOL_CTRL <- !("--total" %in% commandArgs(trailingOnly = TRUE)); suffix <- if (SCHOOL_CTRL) "" else "_total"
FAST <- Sys.getenv("MED_FAST", "0") == "1"   # MED_FAST=1: fewer PVs / simulations (secondary domains and specifications)
PV_ECON <- if (FAST) PV[c(1, 6)] else PV[c(1, 3, 5, 7, 9)]; PV_POOL <- PV[c(1, 5, 9)]
SIMS_ECON <- if (FAST) 200 else 500; SIMS_POOL <- 200; SENS_SIMS <- if (FAST) 40 else 100; RHO_BY <- if (FAST) 0.1 else 0.05
cat("domain:", DOMAIN, " school controls:", SCHOOL_CTRL, "\n")

rubin <- function(est, var) { m <- length(est); c(est = mean(est), se = sqrt(mean(var) + (1 + 1 / m) * var(est))) }

ONLY <- strsplit(Sys.getenv("MED_ONLY", ""), ",")[[1]]   # MED_ONLY=GROWTH,CURIO re-estimates only these mediators and replaces their rows in the existing output
med_unit <- function(d, label, fe = NULL, pvs, sims) {
  sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV")
  sk_run <- if (length(ONLY)) intersect(sk, ONLY) else sk
  ctrl <- c(TREAT_COV, controls, if (SCHOOL_CTRL) c(SCH_LOO, "private", "urban_f"), fe)
  ctrl <- ctrl[sapply(ctrl, function(v) uniqueN(d[[v]]) > 1)]
  if (all(d$CNT == "MAC")) ctrl <- setdiff(ctrl, SCH_LOO)   # Macao: no school id -> school mean = own value (collinear)
  d[, w := if (is.null(fe)) W_FSTUWT / mean(W_FSTUWT) else w_senate / mean(w_senate)]
  # substantive contrast: bottom-decile -> top-decile median of the treatment (ESCS or its rank); for deprivation, one additional item
  contrast <- if (TREAT == "DEP") 1 else { q <- d[, .(lo = median(get(TREAT_VAR)[escs_grp4 == "Bottom 10%"]), hi = median(get(TREAT_VAR)[escs_grp4 == "Top 10%"])), by = CNT]; mean(q$hi - q$lo) }
  rows <- list()
  for (s in sk_run) {
    f_m <- as.formula(paste(s, "~", TREAT_VAR, "+", paste(ctrl, collapse = " + ")))
    f_y <- as.formula(paste("y ~", s, "+", TREAT_VAR, "+", paste(ctrl, collapse = " + ")))
    acme <- ade <- tot <- prop <- c(); v_acme <- v_ade <- v_tot <- v_prop <- c(); sens <- NULL
    for (i in seq_along(pvs)) {
      d[, y := get(pvs[i])]
      # the binary mediator (growth mindset) gets a linear probability model: with a binary mediator and a linear outcome model the ACME is
      # exactly alpha_1 * beta_2, and mediate()'s simulation for a probit mediator draws Bernoulli mediator values, which inflates the
      # Monte Carlo interval about fourfold at the same point estimate (checked); the LPM also matches the joint block below.
      mm <- lm(f_m, data = d, weights = w); my <- lm(f_y, data = d, weights = w)
      med <- mediate(mm, my, treat = TREAT_VAR, mediator = s, sims = sims, control.value = 0, treat.value = 1)
      acme[i] <- med$d0; ade[i] <- med$z0; tot[i] <- med$tau.coef; prop[i] <- med$n0
      v_acme[i] <- var(as.numeric(med$d0.sims)); v_ade[i] <- var(as.numeric(med$z0.sims)); v_tot[i] <- var(as.numeric(med$tau.sims)); v_prop[i] <- var(as.numeric(med$n0.sims))
      if (i == 1) { se <- medsens(med, rho.by = RHO_BY, sims = SENS_SIMS, effect.type = "indirect")
        sens <- c(rho_star = if (length(se$err.cr.d)) se$err.cr.d[1] else NA_real_, R2star_thresh = if (length(se$R2star.d.thresh)) se$R2star.d.thresh[1] else NA_real_,
                  R2tilde_thresh = if (length(se$R2tilde.d.thresh)) se$R2tilde.d.thresh[1] else NA_real_) }
    }
    r <- c(rubin(acme, v_acme), rubin(ade, v_ade), rubin(tot, v_tot), rubin(prop, v_prop)); names(r) <- c("acme", "acme_se", "ade", "ade_se", "total", "total_se", "prop", "prop_se")
    rows[[s]] <- data.table(unit = label, N = nrow(d), mediator = skill_lab[s], t(r), acme_B10_T10 = unname(r["acme"] * contrast), t(sens), contrast = contrast)
  }
  if (length(ONLY)) return(rbindlist(rows, fill = TRUE))
  # joint block: total effect (no skills) minus direct effect (all skills), per PV, Rubin over PVs with delta-free variance from PV spread + OLS se of difference
  fj <- lapply(seq_along(pvs), function(i) { d[, y := get(pvs[i])]
    m0 <- lm(as.formula(paste("y ~", TREAT_VAR, "+", paste(ctrl, collapse = " + "))), data = d, weights = w)
    m1 <- lm(as.formula(paste("y ~", TREAT_VAR, "+", paste(sk, collapse = " + "), "+", paste(ctrl, collapse = " + "))), data = d, weights = w)
    c(tot = coef(m0)[TREAT_VAR], ade = coef(m1)[TREAT_VAR], v_tot = vcov(m0)[TREAT_VAR, TREAT_VAR], v_ade = vcov(m1)[TREAT_VAR, TREAT_VAR]) })
  FJ <- do.call(rbind, fj); rt <- rubin(FJ[, 1], FJ[, 3]); ra <- rubin(FJ[, 2], FJ[, 4]); joint <- FJ[, 1] - FJ[, 2]
  rows[["joint"]] <- data.table(unit = label, N = nrow(d), mediator = "All skills (joint)", acme = mean(joint), acme_se = NA_real_, ade = ra["est"], ade_se = ra["se"],
                                total = rt["est"], total_se = rt["se"], prop = mean(joint / FJ[, 1]), prop_se = NA_real_, acme_B10_T10 = mean(joint) * contrast,
                                rho_star = NA_real_, R2star_thresh = NA_real_, R2tilde_thresh = NA_real_, contrast = contrast)
  rbindlist(rows, fill = TRUE)
}

POOLED <- Sys.getenv("MED_POOLED", "0") == "1"   # bloc / pooled fixed-effects models are optional; the paper uses country-level models only
NCORES <- as.integer(Sys.getenv("MED_CORES", "4"))
part <- tp(paste0("h1_mediation_pkg", TSUF, suffix, if (length(ONLY)) "_only" else "", "_partial.csv"))
econs <- levels(a$CNT)
one <- function(c) { t0 <- Sys.time(); f <- sub("_partial", paste0("_", c), part)
  if (file.exists(f)) { cat(c, "cached\n"); return(fread(f)) }   # resume: reuse a finished system
  r <- tryCatch(med_unit(a[CNT == c], as.character(a[CNT == c, economy][1]), NULL, PV_ECON, SIMS_ECON), error = function(e) { cat(c, "ERROR:", conditionMessage(e), "\n"); NULL })
  if (!is.null(r)) fwrite(r, f); cat(c, round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n"); r }
out <- if (NCORES > 1) parallel::mclapply(econs, one, mc.cores = NCORES, mc.preschedule = FALSE) else lapply(econs, one)
names(out) <- econs
if (POOLED) {
  for (b in blocs) { t0 <- Sys.time(); d <- a[bloc == b]; d[, CNT := droplevels(CNT)]
    out[[b]] <- med_unit(d, b, if (uniqueN(d$CNT) > 1) "CNT" else NULL, PV_POOL, SIMS_POOL); cat(b, round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n") }
  t0 <- Sys.time(); out[[ALL_LAB]] <- med_unit(copy(a), ALL_LAB, "CNT", PV_POOL, SIMS_POOL); cat("pooled", round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n")
}
R <- rbindlist(out, fill = TRUE); R <- merge(R, econ[, .(unit = economy, bloc)], by = "unit", all.x = TRUE)
R[is.na(bloc), bloc := ifelse(unit %in% blocs, unit, "Pooled")]; R[, unit := factor(unit, levels = ord)]; setorder(R, unit)
R[, domain := DOMAIN]; R[, spec := if (SCHOOL_CTRL) "within-school" else "total"]; R[, treat := TREAT]
outf <- tp(paste0("h1_mediation_pkg", TSUF, suffix, ".csv"))
if (length(ONLY) && file.exists(outf)) { old <- fread(outf); old <- old[!mediator %in% skill_lab[ONLY]]; R <- rbind(old, R, fill = TRUE); R[, unit := factor(unit, levels = ord)]; R[, mediator := factor(mediator, levels = c(skill_lab, "All skills (joint)"))]; setorder(R, unit, mediator); R[, mediator := as.character(mediator)] }
fwrite(R, outf)
for (f in list.files(dirname(part), pattern = paste0("^h1_mediation_pkg", TSUF, suffix, if (length(ONLY)) "_only" else "", "_[A-Z]{3}\\.csv$"), full.names = TRUE)) file.remove(f)   # per-system caches, removed only after the combined file exists
options(width = 240)
print(R[, .(unit, mediator, acme = round(acme, 2), acme_se = round(acme_se, 2), total = round(total, 1), prop = round(100 * prop, 1), prop_se = round(100 * prop_se, 1), acme_B10_T10 = round(acme_B10_T10, 1), rho_star, R2tilde_thresh = round(R2tilde_thresh, 3))])
cat("done mediation package run\n")
