# Paper A -- robustness of the joint mediated share (Gelbach decomposition = total minus direct effect of the six-skill block):
#   (a) students in the modal grade only (removes grade composition from both the skill and the achievement gradients);
#   (b) analytic sample re-weighted to the full sample on the inverse probability of completing the skill items.
#   (Standardising skills within economy is immaterial with one model per system: the explained share is scale-free.)
# Run: PISA_DOMAIN=READ Rscript 02_scripts/paperA/07_robustness.R [--total]   (default = within-school specification)
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
a <- a[!is.na(get(TREAT_VAR))]; a[, CNT := droplevels(CNT)]
SCHOOL_CTRL <- !("--total" %in% commandArgs(trailingOnly = TRUE)); suffix <- if (SCHOOL_CTRL) "" else "_total"
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- levels(a$bloc)
cat("domain:", DOMAIN, " school controls:", SCHOOL_CTRL, "\n")

make_gelbach <- function(dt, sk) {
  rhs_ctrl <- c(TREAT_VAR, TREAT_COV, controls, if (SCHOOL_CTRL) c(SCH_LOO, "private", "urban_f"))
  if (all(dt$CNT == "MAC")) rhs_ctrl <- setdiff(rhs_ctrl, SCH_LOO)
  Xb <- model.matrix(as.formula(paste("~", paste(rhs_ctrl, collapse = "+"))), dt)
  Xb <- Xb[, colnames(Xb) == "(Intercept)" | apply(Xb, 2, sd) > 0, drop = FALSE]
  Xf <- cbind(Xb, as.matrix(dt[, ..sk])); S <- as.matrix(dt[, ..sk])
  function(d, y, w) { bb <- wls(Xb, y, w); bf <- wls(Xf, y, w); gam <- bf[sk]
    pis <- sapply(seq_along(sk), function(j) wls(Xb, S[, j], w)[TREAT_VAR]); names(pis) <- sk
    c(beta_base = unname(bb[TREAT_VAR]), beta_full = unname(bf[TREAT_VAR]), explained = unname(bb[TREAT_VAR] - bf[TREAT_VAR]), explained_CURIO = unname(gam["CURIO"] * pis["CURIO"])) } }

run_check <- function(dt, label) {   # one BRR+PV estimation per system
  rbindlist(lapply(levels(droplevels(dt$CNT)), function(c) { d <- dt[CNT == c]; cat(c, " ")
    sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV")
    r <- pisa_est(d, make_gelbach(d, sk)); r[, `:=`(check = label, unit = as.character(d$economy[1]), N = nrow(d))]; r }))
}

out <- list()
# (a) modal-grade students only
cat("\nmodal grade: "); out$modal <- run_check(a[grade_rel == 0], "Modal-grade students only")
# (b) non-response re-weighting: P(complete | achievement PV1, sex, grade, age) within economy; weights and replicate weights x 1/p
full <- fread("01_data/derived/paperA_students.csv", select = c("CNTSTUID", "CNT", PV[1], "ST004D01T", "ST001D01T", "AGE"))
full <- full[!is.na(get(PV[1]))]; full[, complete := CNTSTUID %in% a$CNTSTUID]
full[, p := { m <- glm(as.formula(paste("complete ~", PV[1], "+ factor(ST004D01T) + factor(ST001D01T) + AGE")), family = binomial, data = .SD); as.numeric(predict(m, newdata = .SD, type = "response")) }, by = CNT]
aw <- merge(a, full[, .(CNTSTUID, p)], by = "CNTSTUID")
aw[, W_FSTUWT := W_FSTUWT / p]; for (r in RW) aw[, (r) := get(r) / p]
cat("\nnon-response re-weighting: "); out$ipw <- run_check(aw, "Re-weighted for item non-response")
# reference: main specification from 04_h1_gelbach.R (same estimator, same systems)
ref <- fread(paste0(tp("h1_gelbach_long"), TSUF, suffix, ".csv"))[!unit %in% c(blocs, ALL_LAB) & term %in% c("beta_base", "beta_full", "explained", "delta_CURIO")]
ref[term == "delta_CURIO", term := "explained_CURIO"]; ref[, check := paste0("Main: ", dom_lab, if (SCHOOL_CTRL) ", within-school gradient" else ", total gradient")]
R <- rbind(rbindlist(out), ref[, .(term, est, se, se_samp = NA_real_, se_imp = NA_real_, check, unit, N)], fill = TRUE)
R <- merge(R, econ[, .(unit = economy, bloc)], by = "unit", all.x = TRUE)
fwrite(R, paste0(tp("rob_gelbach_long"), TSUF, suffix, ".csv"))

# ---- summary table: median across systems [p25, p75]; the share is each system's own explained / total effect ----
W <- dcast(R, check + unit + bloc + N ~ term, value.var = c("est", "se"))
W[, share_explained := 100 * est_explained / est_beta_base]; W[, share_CURIO := 100 * est_explained_CURIO / est_beta_base]
q <- function(x, p) unname(quantile(x, p, na.rm = TRUE))
tab <- W[, .(systems = .N, beta_base = median(est_beta_base), beta_base_lo = q(est_beta_base, .25), beta_base_hi = q(est_beta_base, .75),
             beta_full = median(est_beta_full), explained = median(est_explained), explained_lo = q(est_explained, .25), explained_hi = q(est_explained, .75),
             share_explained = median(share_explained), share_explained_lo = q(share_explained, .25), share_explained_hi = q(share_explained, .75),
             share_CURIO = median(share_CURIO)), by = check]
tab <- tab[order(match(check, unique(c(grep("^Main", check, value = TRUE), check))))]
tab <- tab[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)]
fwrite(tab, paste0(tp("rob_gelbach_table"), TSUF, suffix, ".csv")); options(width = 220); print(tab)
cat("\nrobustness done\n")
