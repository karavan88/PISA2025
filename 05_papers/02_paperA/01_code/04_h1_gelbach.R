# Paper A -- H1: how much of the ESCS gradient in science runs through socio-emotional skills?
# Gelbach (2016) decomposition: beta_base - beta_full = sum_k gamma_k * pi_k, exact for WLS on an identical sample.
# One model per education system. Inference: Fay BRR (PV1) + PV imputation variance. Treatment set by PISA_TREAT (00_helpers.R).
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]   # Macao: no school id -> own ESCS (absorbed)
a[, urban_f := factor(urban)]
a <- a[!is.na(get(TREAT_VAR))]   # deprivation index missing for a few students
cat("treatment:", TREAT, "->", TREAT_VAR, "\n")

make_gelbach <- function(dt, sk, fe = NULL, school_controls = TRUE) {
  rhs_ctrl <- c(TREAT_VAR, TREAT_COV, controls, if (school_controls) c(SCH_LOO, "private", "urban_f"), fe)
  if (all(dt$CNT == "MAC")) rhs_ctrl <- setdiff(rhs_ctrl, SCH_LOO)   # Macao: no school id -> school mean = own value
  Xb <- model.matrix(as.formula(paste("~", paste(rhs_ctrl, collapse = "+"))), dt)
  Xb <- Xb[, colnames(Xb) == "(Intercept)" | apply(Xb, 2, sd) > 0, drop = FALSE]
  Xf <- cbind(Xb, as.matrix(dt[, ..sk]))
  S  <- as.matrix(dt[, ..sk])
  function(d, y, w) {
    bb <- wls(Xb, y, w); bf <- wls(Xf, y, w)
    gam <- bf[sk]
    pis <- sapply(seq_along(sk), function(j) wls(Xb, S[, j], w)[TREAT_VAR]); names(pis) <- sk
    delta <- gam * pis
    out <- c(beta_base = unname(bb[TREAT_VAR]), beta_full = unname(bf[TREAT_VAR]), explained = unname(bb[TREAT_VAR] - bf[TREAT_VAR]),
             share_explained = unname((bb[TREAT_VAR] - bf[TREAT_VAR]) / bb[TREAT_VAR]))
    c(out, setNames(delta, paste0("delta_", sk)), setNames(delta / bb[TREAT_VAR], paste0("share_", sk)),
      setNames(gam, paste0("gamma_", sk)), setNames(pis, paste0("pi_", sk)))
  }
}

run_unit <- function(dt, label, fe = NULL) {
  sk <- if (all(dt$persev_fielded)) skills else setdiff(skills, "PERSEV")
  res <- pisa_est(dt, make_gelbach(dt, sk, fe, school_controls = SCHOOL_CTRL))
  res[, unit := label]; res[, N := nrow(dt)]
  res
}

SCHOOL_CTRL <- !("--total" %in% commandArgs(trailingOnly = TRUE))
suffix <- if (SCHOOL_CTRL) "" else "_total"
cat("school controls:", SCHOOL_CTRL, "\n")
res <- list()
for (c in levels(droplevels(a$CNT))) { cat(c, " "); res[[c]] <- run_unit(a[CNT == c], as.character(a[CNT == c, economy][1])) }
R <- rbindlist(res)
econ <- fread("01_data/derived/paperA_economies.csv")
R <- merge(R, econ[, .(unit = economy, bloc)], by = "unit", all.x = TRUE)
fwrite(R, paste0(tp("h1_gelbach_long"), TSUF, suffix, ".csv"))

# ---- compact table ----
W <- dcast(R, bloc + unit + N ~ term, value.var = c("est", "se"))
tab <- W[, .(bloc, unit, N,
  beta_base = round(est_beta_base, 1), se_base = round(se_beta_base, 1),
  beta_full = round(est_beta_full, 1), se_full = round(se_beta_full, 1),
  explained = round(est_explained, 1), se_explained = round(se_explained, 1),
  share = round(100 * est_share_explained, 1), se_share = round(100 * se_share_explained, 1),
  CURIO = round(100 * est_share_CURIO, 1), PERSEV = round(100 * est_share_PERSEV, 1), ENPROBS = round(100 * est_share_ENPROBS, 1),
  COGABIL = round(100 * est_share_COGABIL, 1), GOALSET = round(100 * est_share_GOALSET, 1), SELFREG = round(100 * est_share_SELFREG, 1))]
ord <- econ$economy
tab <- tab[order(match(unit, ord))]
fwrite(tab, paste0(tp("h1_gelbach_table"), TSUF, suffix, ".csv"))
options(width = 200); print(tab)
cat("done H1\n")
