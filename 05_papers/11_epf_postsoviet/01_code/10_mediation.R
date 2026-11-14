# EPF post-Soviet paper -- causal mediation of the socio-economic gradient through socio-emotional skills, one system per run
# (Imai, Keele & Tingley 2010; `mediation` package). Exposures: ESCS percentile rank / 10 (individual, conditional on the LOO school mean)
# and the leave-one-out school-mean ESCS (composition, conditional on individual ESCS). Mediators: Big Five domain scores (task performance,
# open-mindedness, adaptability; sample-standardised) and growth mindset (binary, linear-probability mediator model). Outcome model:
# quantile regression at tau = 0.25 (headline: the low-achiever end of the distribution) and the mean (lm) for comparison.
# Covariates: core specification (grade, birth-month dummies, student controls, school inputs). Skills sample, IPW x student weights.
# Joint mediation of the four-skill block: total effect minus the direct effect of an outcome model with all four mediators.
# Inference: quasi-Bayesian Monte Carlo (mediate), PV1 in FAST, PVs 1/3/5/7/9 Rubin-combined in FULL.
# Usage: PISA_CNT=GEO PISA_DOMAIN=SCIE PISA_PROFILE=FAST Rscript 02_scripts/epf_postsoviet/10_mediation.R   Output: <DOMAIN>/mediation_<CNT>.csv
suppressPackageStartupMessages({ library(data.table); library(quantreg); library(mediation) })
source("02_scripts/epf_postsoviet/00_helpers.R")
CNT_RUN <- Sys.getenv("PISA_CNT", "GEO")
SIMS <- if (PROFILE == "FULL") 1000 else 200
PVS  <- if (PROFILE == "FULL") PV[c(1, 3, 5, 7, 9)] else PV[1]
a <- load_analytic(); s <- a[CNT == CNT_RUN & skills_ok == 1]
s[, w := W_FSTUWT * ipw]; s[, w := w / mean(w)]
s[, sch_escs_sd := sd(sch_escs_loo)]                                   # within-system SD of the composition measure, for a substantive contrast
exposures <- c(ESCS_pct10 = "individual ESCS (per 10 percentile points)", sch_escs_loo = "school-mean ESCS (per index unit)")
base_ctrl <- c("grade_c", "bmonth", student_ctrl, school_ctrl)
d <- as.data.frame(s)
res <- list()
for (tr in names(exposures)) {
  ctrl <- c(setdiff(c(hh_ctrl, "sch_escs_loo"), tr), setdiff(base_ctrl, "sch_escs_loo"))
  ctrl <- ctrl[sapply(ctrl, function(v) is.factor(d[[v]]) || sd(d[[v]], na.rm = TRUE) > 0)]
  for (om in c("q25", "mean")) {
    fit_y <- function(f, dd) if (om == "q25") rq(f, tau = .25, data = dd, weights = w) else lm(f, data = dd, weights = w)
    for (m in skill_dom) {
      f_m <- as.formula(paste(m, "~", tr, "+", paste(ctrl, collapse = " + ")))
      f_y <- as.formula(paste("y ~", m, "+", tr, "+", paste(ctrl, collapse = " + ")))
      acme <- ade <- tot <- prop <- v_acme <- v_ade <- v_tot <- v_prop <- numeric(0)
      for (i in seq_along(PVS)) {
        d$y <- d[[PVS[i]]]
        mm <- lm(f_m, data = d, weights = w); my <- fit_y(f_y, d)
        med <- mediate(mm, my, treat = tr, mediator = m, sims = SIMS, control.value = 0, treat.value = 1)
        acme[i] <- med$d0; ade[i] <- med$z0; tot[i] <- med$tau.coef; prop[i] <- med$n0
        v_acme[i] <- var(as.numeric(med$d0.sims)); v_ade[i] <- var(as.numeric(med$z0.sims)); v_tot[i] <- var(as.numeric(med$tau.sims)); v_prop[i] <- var(as.numeric(med$n0.sims))
      }
      r <- list(rubin(acme, v_acme), rubin(ade, v_ade), rubin(tot, v_tot), rubin(prop, v_prop))
      res[[paste(tr, om, m)]] <- data.table(CNT = CNT_RUN, exposure = tr, exposure_label = exposures[[tr]], outcome_model = om, mediator = m,
        acme = r[[1]]$est, acme_se = r[[1]]$se, ade = r[[2]]$est, ade_se = r[[2]]$se, total = r[[3]]$est, total_se = r[[3]]$se, prop = r[[4]]$est, prop_se = r[[4]]$se)
      log_step(CNT_RUN, tr, om, m, "ACME", round(r[[1]]$est, 2), "share", round(r[[4]]$est, 3))
    }
    # joint block: total effect (no mediators) minus direct effect (all four mediators), PV1; se by school-cluster bootstrap of the difference
    d$y <- d[[PVS[1]]]
    f_t <- as.formula(paste("y ~", tr, "+", paste(ctrl, collapse = " + "))); f_d <- as.formula(paste("y ~", paste(skill_dom, collapse = " + "), "+", tr, "+", paste(ctrl, collapse = " + ")))
    bt <- function(dd) { coef(fit_y(f_t, dd))[tr] - coef(fit_y(f_d, dd))[tr] }
    joint <- bt(d); tot1 <- coef(fit_y(f_t, d))[tr]
    set.seed(20260930); schools <- unique(d$school); B <- if (PROFILE == "FULL") 200 else 50
    bs <- replicate(B, { sm <- sample(schools, replace = TRUE); dd <- do.call(rbind, lapply(sm, function(k) d[d$school == k, ])); bt(dd) })
    res[[paste(tr, om, "joint")]] <- data.table(CNT = CNT_RUN, exposure = tr, exposure_label = exposures[[tr]], outcome_model = om, mediator = "joint_block",
      acme = unname(joint), acme_se = sd(bs), ade = unname(tot1 - joint), ade_se = NA_real_, total = unname(tot1), total_se = NA_real_, prop = unname(joint / tot1), prop_se = sd(bs) / abs(tot1))
    log_step(CNT_RUN, tr, om, "joint block share", round(joint / tot1, 3))
  }
}
res <- rbindlist(res); res[, `:=`(n = nrow(s), sch_escs_sd = s$sch_escs_sd[1], n_pv = length(PVS), sims = SIMS, profile = PROFILE, domain = DOMAIN)]
fwrite(res, op(paste0("mediation_", CNT_RUN, ".csv")))
print(dcast(res[, .(exposure, outcome_model, mediator, prop = round(prop, 3))], exposure + mediator ~ outcome_model, value.var = "prop"))
log_step(CNT_RUN, "mediation done")
