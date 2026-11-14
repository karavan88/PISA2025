# Paper A -- H2 (compensation vs cumulative advantage), H3 (level vs rate), H5 (bloc differences in returns)
# Weighted least squares on the analytic sample; inference by Fay BRR (PV1) + PV imputation variance (pisa_est).
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
a[, escs_grp := relevel(escs_grp4, ref = "Top 10%")]   # 4 groups: bottom 10 / 10-40 / 40-90 / top 10
a[, bloc := factor(bloc, levels = c("East Asia", "Post-Soviet", "Post-communist Europe"))]
econ <- fread("01_data/derived/paperA_economies.csv")
ord  <- c(econ$economy, levels(a$bloc), ALL_LAB)

senate <- function(d) { d <- copy(d); d[, W_FSTUWT := w_senate]; for (r in RW) d[, (r) := get(r) / sum(get(r)) * 5000, by = CNT]; d }

# generic: fit WLS with a formula on a unit, return all coefficients with PISA SEs
fit_spec <- function(dt, rhs, label) {
  X <- model.matrix(as.formula(paste("~", rhs)), dt)
  X <- X[, colnames(X) == "(Intercept)" | apply(X, 2, sd) > 0, drop = FALSE]
  res <- pisa_est(dt, function(d, y, w) wls(X, y, w))
  res[, unit := label]; res[, N := nrow(dt)]; res
}
units <- function(a, fe_pool = TRUE) {
  u <- list()
  for (c in levels(droplevels(a$CNT))) u[[c]] <- list(d = a[CNT == c], label = as.character(a[CNT == c, economy][1]), fe = NULL)
  for (b in levels(a$bloc)) u[[b]] <- list(d = senate(a[bloc == b]), label = b, fe = "CNT")
  u[["all"]] <- list(d = senate(a), label = ALL_LAB, fe = "CNT")
  u
}
run_all <- function(a, build_rhs, tag) {
  out <- list()
  for (nm in names(U <- units(a))) {
    u <- U[[nm]]; sk <- if (all(u$d$persev_fielded)) skills else setdiff(skills, "PERSEV")
    fe <- if (!is.null(u$fe) && uniqueN(u$d$CNT) > 1) "CNT" else NULL
    cat(tag, nm, " "); out[[nm]] <- fit_spec(u$d, build_rhs(sk, fe), u$label)
  }
  cat("\n"); R <- rbindlist(out); R <- merge(R, econ[, .(unit = economy, bloc)], by = "unit", all.x = TRUE)
  R[is.na(bloc), bloc := ifelse(unit %in% levels(a$bloc), unit, "Pooled")]; R[, unit := factor(unit, levels = ord)]
  setorder(R, unit); R
}
ctrl <- function(fe) paste(c("ESCS", controls, "sch_escs_loo", "private", "urban_f", fe), collapse = "+")

# ---------- H2a: skill x ESCS group (reference Top 10%) ----------
if (!file.exists(tp("h2a_skill_x_escsgrp_long.csv"))) {
H2 <- run_all(a, function(sk, fe) paste(ctrl(fe), "+ escs_grp +", paste(sk, collapse = "+"), "+", paste0(sk, ":escs_grp", collapse = "+")), "H2a")
fwrite(H2, tp("h2a_skill_x_escsgrp_long.csv"))
# marginal returns by group: slope(Top10) = main; slope(Bottom40) = main + interaction. Compute with covariance-free approximation via re-parameterised fits:
# to get the SE of the Bottom-40 slope directly, refit with Bottom 40% as reference.
a2 <- copy(a); a2[, escs_grp := relevel(escs_grp, ref = "Bottom 10%")]
H2b <- run_all(a2, function(sk, fe) paste(ctrl(fe), "+ escs_grp +", paste(sk, collapse = "+"), "+", paste0(sk, ":escs_grp", collapse = "+")), "H2b")
fwrite(H2b, tp("h2b_skill_x_escsgrp_refB40_long.csv"))
} else { H2 <- fread(tp("h2a_skill_x_escsgrp_long.csv")); H2b <- fread(tp("h2b_skill_x_escsgrp_refB40_long.csv")) }
sl <- rbind(H2[term %in% skills, .(unit, bloc, skill = term, group = "Top 10%", est, se)],
            H2b[term %in% skills, .(unit, bloc, skill = term, group = "Bottom 10%", est, se)],
            H2[grepl("escs_grpBottom 10%:", term), .(unit, bloc, skill = sub(".*:", "", term), group = "Difference (B10 - T10)", est, se)])
sl[, skill := skill_lab[skill]]
fwrite(sl, tp("h2_skill_returns_by_group.csv"))
options(width = 220)
print(dcast(sl[unit %in% c(levels(a$bloc), ALL_LAB)], unit + skill ~ group, value.var = c("est", "se"))[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])

# ---------- H2d: continuous skill x ESCS (within-economy z) interaction ----------
H2d <- run_all(a, function(sk, fe) paste(ctrl(fe), "+ ESCS_zw +", paste(sk, collapse = "+"), "+", paste0(sk, ":ESCS_zw", collapse = "+")), "H2d")
fwrite(H2d, tp("h2d_skill_x_escs_continuous_long.csv"))

# ---------- H2c: material deprivation at fixed ESCS (dep4_any), main effect and skill x deprivation ----------
if (!file.exists(tp("h3_skill_x_grade.csv"))) {
a3 <- a[!is.na(dep4_any)]
H2c_base <- run_all(a3, function(sk, fe) paste(ctrl(fe), "+ dep4_any"), "H2c-base")
H2c_full <- run_all(a3, function(sk, fe) paste(ctrl(fe), "+ dep4_any +", paste(sk, collapse = "+")), "H2c-full")
H2c_int  <- run_all(a3, function(sk, fe) paste(ctrl(fe), "+ dep4_any +", paste(sk, collapse = "+"), "+", paste0(sk, ":dep4_any", collapse = "+")), "H2c-int")
dep <- rbind(H2c_base[term == "dep4_any", .(unit, bloc, term = "Deprivation penalty (base)", est, se)],
             H2c_full[term == "dep4_any", .(unit, bloc, term = "Deprivation penalty (with skills)", est, se)],
             H2c_int[grepl(":dep4_any", term), .(unit, bloc, term = paste0("Skill x deprived: ", skill_lab[sub(":.*", "", term)]), est, se)])
fwrite(dep, tp("h2c_deprivation.csv"))
print(dep[unit %in% c(levels(a$bloc), ALL_LAB)][, .(unit, term, est = round(est, 2), se = round(se, 2))])

# ---------- H3: skill x grade (learning gain per grade) ----------
H3 <- run_all(a, function(sk, fe) paste(ctrl(fe), "+", paste(sk, collapse = "+"), "+", paste0(sk, ":grade_rel", collapse = "+")), "H3")
fwrite(H3, tp("h3_skill_x_grade_long.csv"))
h3 <- H3[term == "grade_rel" | grepl(":grade_rel", term), .(unit, bloc, term, est = round(est, 2), se = round(se, 2))]
h3[, term := ifelse(term == "grade_rel", "Grade (learning gain)", paste0("Grade x ", skill_lab[sub(":.*", "", term)]))]
fwrite(h3, tp("h3_skill_x_grade.csv"))
print(h3[unit %in% c(levels(a$bloc), ALL_LAB)])

# ---------- H5: bloc x skill in the pooled model ----------
sk5 <- setdiff(skills, "PERSEV")  # PERSEV not fielded in KAZ, ALB
d <- senate(a)
X5 <- model.matrix(as.formula(paste("~", ctrl("CNT"), "+ bloc +", paste(sk5, collapse = "+"), "+", paste0(sk5, ":bloc", collapse = "+"))), d)
X5 <- X5[, colnames(X5) == "(Intercept)" | apply(X5, 2, sd) > 0, drop = FALSE]
H5 <- pisa_est(d, function(dd, y, w) wls(X5, y, w))
fwrite(H5, tp("h5_bloc_x_skill_long.csv"))
print(H5[term %in% sk5 | grepl(":bloc", term), .(term, est = round(est, 2), se = round(se, 2))])
# with PERSEV, excluding KAZ and ALB
d2 <- senate(a[persev_fielded == TRUE]); d2[, CNT := droplevels(CNT)]
X6 <- model.matrix(as.formula(paste("~", ctrl("CNT"), "+ bloc +", paste(skills, collapse = "+"), "+", paste0(skills, ":bloc", collapse = "+"))), d2)
X6 <- X6[, colnames(X6) == "(Intercept)" | apply(X6, 2, sd) > 0, drop = FALSE]
H5p <- pisa_est(d2, function(dd, y, w) wls(X6, y, w)); fwrite(H5p, tp("h5_bloc_x_skill_withPERSEV_long.csv"))
cat("done H2/H3/H5\n")
}

# ---------- H3b: restricted test -- economies where grade dispersion is entry-timing driven (>=10% below modal), students in modal or modal-1 grade ----------
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
below <- a[, .(share_below = weighted.mean(grade_rel < 0, W_FSTUWT)), by = CNT][share_below >= 0.10, as.character(CNT)]
cat("H3b economies:", below, "\n")
a3b <- a[CNT %in% below & grade_rel %in% c(-1, 0)]; a3b[, CNT := droplevels(CNT)]; a3b[, bloc := droplevels(bloc)]
H3b <- run_all(a3b, function(sk, fe) paste(ctrl(fe), "+", paste(sk, collapse = "+"), "+", paste0(sk, ":grade_rel", collapse = "+")), "H3b")
fwrite(H3b, tp("h3b_skill_x_grade_restricted_long.csv"))
h3b <- H3b[term == "grade_rel" | grepl(":grade_rel", term), .(unit, bloc, term, est = round(est, 2), se = round(se, 2))]
h3b[, term := ifelse(term == "grade_rel", "Grade (learning gain)", paste0("Grade x ", skill_lab[sub(":.*", "", term)]))]
fwrite(h3b, tp("h3b_skill_x_grade_restricted.csv")); print(h3b)
cat("done H3b\n")
