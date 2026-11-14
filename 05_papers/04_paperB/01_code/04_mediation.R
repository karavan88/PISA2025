# Paper B -- how much of the schooling effect on science runs through the induced change in skills?
#   For each system: tau_Y  = fuzzy-RD effect of the extra school year on the science score
#                    tau_Mk = fuzzy-RD effect on skill k (six scales in SD units + growth mindset)
#                    beta_k = return to skill k in science, WLS of the score on the seven skills jointly, the treatment, the running-variable
#                             terms and student controls (sex, ESCS, immigrant background, home language), window sample
#   share_k = beta_k * tau_Mk / tau_Y; share = sum_k share_k; "direct" = tau_Y - sum_k beta_k * tau_Mk.
#   This is a product-of-coefficients decomposition (Baron-Kenny / Gelbach-type), not the Imai causal-mediation estimand: beta_k is an
#   association net of schooling, so the share says what part of the schooling effect the induced skill change would account for IF the
#   cross-sectional return to skills were causal. Inference: BRR over 80 replicates on PV1 + Rubin over 10 PVs (everything recomputed per replicate).
# Usage: Rscript 02_scripts/paperB/04_mediation.R          Output: 03_outputs/paperB/med_share.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
a <- load_analytic()
med_skills_all <- c(paste0(skill_wle, "_z"), "growth")
ctrl <- c("female", "ESCS_z", "immigrant", "lang_other")
res <- list()
for (cn in SYS) {
  s <- a[CNT == cn]; donut <- s$donut[1]
  for (h in BANDWIDTHS) {
    w <- s[r >= -h & r <= h - 1]; if (donut == 1) w <- w[r != 0]
    nl <- uniqueN(w$r[w$Z == 1]); nr <- uniqueN(w$r[w$Z == 0]); spec <- if (nl >= 2 & nr >= 2) "ll" else "common"
    med_skills <- med_skills_all[sapply(med_skills_all, function(m) mean(!is.na(w[[m]])) > 0.5)]   # drop scales not fielded in this system
    w <- w[complete.cases(w[, c(med_skills, ctrl), with = FALSE])]
    if (nrow(w) < 200) next                                              # skills or ESCS not fielded in this system
    for (v in ctrl) w[, (v) := get(v) - wmean(get(v), W_FSTUWT)]
    Xr <- if (spec == "ll") cbind(1, w$Z, w$r, w$r * w$Z) else cbind(1, w$Z, w$r); colnames(Xr) <- c("(Intercept)", "Z", "r", "rZ")[seq_len(ncol(Xr))]
    M <- as.matrix(w[, ..med_skills]); C <- as.matrix(w[, ..ctrl])
    Xb <- cbind(Xr, D = w$D, M, C)
    statfun <- function(dt, y, wt) {
      fs <- wls(Xr, dt$D, wt)["Z"]; rfY <- wls(Xr, y, wt)["Z"]; tauY <- rfY / fs
      tauM <- sapply(med_skills, function(m) wls(Xr, dt[[m]], wt)["Z"] / fs)
      beta <- wls(Xb, y, wt)[med_skills]
      via <- beta * tauM
      c(tau_y = unname(tauY), setNames(tauM, paste0("tauM_", med_skills)), setNames(beta, paste0("beta_", med_skills)), setNames(via, paste0("via_", med_skills)),
        via_total = sum(via), direct = unname(tauY) - sum(via), share_total = sum(via) / unname(tauY), setNames(via / unname(tauY), paste0("share_", med_skills)))
    }
    e <- pisa_est(w, statfun, PV("SCIE"))
    e[, `:=`(CNT = cn, h = h, spec = spec, n = nrow(w), system = SYS_NAMES[cn], region = REGION[cn], tier = TIER[cn])]
    res[[length(res) + 1]] <- e
  }
  log_step(cn, "done")
}
res <- rbindlist(res); setcolorder(res, c("CNT", "system", "region", "h", "spec", "n", "term", "est", "se"))
fwrite(res, op("med_share.csv"))
print(dcast(res[h == 4 & term %in% c("tau_y", "via_total", "direct", "share_total")], CNT ~ term, value.var = "est", fun.aggregate = function(x) round(x[1], 2)))
log_step("mediation done")
