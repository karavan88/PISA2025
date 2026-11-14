# Paper A -- H2 by SEPARATE estimation: the full model is fitted within each ESCS group
# (bottom 10 / 10-40 / 40-90 / top 10) and within deprived / non-deprived, so all coefficients differ across groups.
# Returns to skills are then compared across groups; difference SE = sqrt(se1^2 + se2^2) (independent subsamples).
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- levels(a$bloc); ord <- c(econ$economy, blocs, ALL_LAB)
senate <- function(d) { d <- copy(d); d[, W_FSTUWT := w_senate]; for (r in RW) d[, (r) := get(r) / sum(get(r)) * 5000, by = CNT]; d }
ctrl <- function(fe) paste(c("ESCS", controls, "sch_escs_loo", "private", "urban_f", fe), collapse = "+")
fit_spec <- function(dt, rhs, label, group) {
  X <- model.matrix(as.formula(paste("~", rhs)), dt)
  X <- X[, colnames(X) == "(Intercept)" | apply(X, 2, sd) > 0, drop = FALSE]
  res <- pisa_est(dt, function(d, y, w) wls(X, y, w)); res[, `:=`(unit = label, group = group, N = nrow(dt))]; res
}
units <- function(a) {
  u <- list()
  for (c in levels(a$CNT)) u[[c]] <- list(d = a[CNT == c], label = as.character(a[CNT == c, economy][1]), fe = NULL)
  for (b in blocs) u[[b]] <- list(d = senate(a[bloc == b]), label = b, fe = "CNT")
  u[["all"]] <- list(d = senate(a), label = ALL_LAB, fe = "CNT")
  u
}
run_groups <- function(a, gvar, tag) {
  out <- list()
  for (nm in names(U <- units(a))) {
    u <- U[[nm]]; fe <- if (!is.null(u$fe) && uniqueN(u$d$CNT) > 1) "CNT" else NULL
    for (g in levels(factor(u$d[[gvar]]))) {
      d <- u$d[get(gvar) == g]; if (!is.null(fe)) d[, CNT := droplevels(CNT)]
      fe_g <- if (!is.null(fe) && uniqueN(d$CNT) > 1) "CNT" else NULL
      sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV")
      out[[paste(nm, g)]] <- fit_spec(d, paste(ctrl(fe_g), "+", paste(sk, collapse = "+")), u$label, g)
    }
    cat(tag, nm, " ")
  }
  cat("\n"); R <- rbindlist(out); R <- merge(R, econ[, .(unit = economy, bloc)], by = "unit", all.x = TRUE)
  R[is.na(bloc), bloc := ifelse(unit %in% blocs, unit, "Pooled")]; R[, unit := factor(unit, levels = ord)]; setorder(R, unit); R
}

# ---- by ESCS group ----
G <- run_groups(a, "escs_grp4", "sep-ESCS"); fwrite(G, tp("h2sep_by_escsgrp_long.csv"))
ret <- G[term %in% skills, .(unit, bloc, group, skill = skill_lab[term], est, se, N)]
w <- dcast(ret, unit + bloc + skill ~ group, value.var = c("est", "se", "N"))
w[, `:=`(diff_B10_T10 = `est_Bottom 10%` - `est_Top 10%`, se_diff = sqrt(`se_Bottom 10%`^2 + `se_Top 10%`^2))]
w[, `:=`(diff_B40_T10 = `est_10-40%` - `est_Top 10%`, se_diff40 = sqrt(`se_10-40%`^2 + `se_Top 10%`^2))]
fwrite(w, tp("h2sep_skill_returns_by_group.csv"))
options(width = 240)
show <- w[unit %in% c(blocs, ALL_LAB), .(unit, skill, B10 = round(`est_Bottom 10%`, 1), se_B10 = round(`se_Bottom 10%`, 1), `10-40` = round(`est_10-40%`, 1), `40-90` = round(`est_40-90%`, 1),
  T10 = round(`est_Top 10%`, 1), se_T10 = round(`se_Top 10%`, 1), diff = round(diff_B10_T10, 1), se_diff = round(se_diff, 1), N_B10 = `N_Bottom 10%`, N_T10 = `N_Top 10%`)]
print(show)
e <- w[!unit %in% c(blocs, ALL_LAB)]; e[, sig := abs(diff_B10_T10) > 1.96 * se_diff]
print(e[, .(pos_sig = sum(diff_B10_T10 > 0 & sig, na.rm = TRUE), neg_sig = sum(diff_B10_T10 < 0 & sig, na.rm = TRUE), n = .N, mean_diff = round(mean(diff_B10_T10, na.rm = TRUE), 1)), by = skill])

# ---- by material deprivation (at given ESCS, ESCS stays in the model) ----
a3 <- a[!is.na(dep4_any)]; a3[, dep_grp := factor(ifelse(dep4_any == 1, "Deprived", "Not deprived"))]
D <- run_groups(a3, "dep_grp", "sep-DEP"); fwrite(D, tp("h2sep_by_deprivation_long.csv"))
rd <- D[term %in% skills, .(unit, bloc, group, skill = skill_lab[term], est, se, N)]
wd <- dcast(rd, unit + bloc + skill ~ group, value.var = c("est", "se", "N"))
wd[, `:=`(diff = est_Deprived - `est_Not deprived`, se_diff = sqrt(se_Deprived^2 + `se_Not deprived`^2))]
fwrite(wd, tp("h2sep_skill_returns_by_deprivation.csv"))
print(wd[unit %in% c(blocs, ALL_LAB), .(unit, skill, deprived = round(est_Deprived, 1), se_d = round(se_Deprived, 1), not_deprived = round(`est_Not deprived`, 1), se_nd = round(`se_Not deprived`, 1), diff = round(diff, 1), se_diff = round(se_diff, 1), N_dep = N_Deprived)])
cat("done separate estimation\n")
