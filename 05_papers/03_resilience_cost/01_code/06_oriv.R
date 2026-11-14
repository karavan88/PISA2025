# The Cost of Resilience -- step 6: two raters of self-regulation (ORIV)
# 17 systems with the parent questionnaire. Student self-regulated learning (SELFREG, frequency of planning/monitoring strategies) and the
# parent's rating of the child's self-regulated learning (PQSELFREG) are two error-ridden measures of the same latent skill. Obviously
# related IV (Gillen, Snowberg & Yariv 2019): instrument each measure with the other and stack the two IV equations (measure-specific
# school FE and controls). With classical, mutually independent errors this removes attenuation; the parent measure also shares no
# questionnaire with the outcome, so the cross-rater OLS (life satisfaction on the parent rating) is free of shared-method bias.
# Threat: parents infer self-regulation from grades (r with achievement 0.20 vs 0.10 for the student) and achievement is negatively
# related to life satisfaction once skills are held -> main specifications control for achievement (PV-wise, system SD).
# Part A (per system, BRR + Rubin, RE pooled): slope of LS on self-regulation -- OLS student, OLS parent (cross-rater), IV each way,
#   stacked ORIV, first stage; with and without the achievement control; SEI as the student measure; parent emotion-management item.
# Part B (pooled 17-system data, weights normalised per system, BRR + Rubin): resilience gap and its moderation by self-regulation,
#   R vs disadvantaged low achievers within school -- OLS student, OLS parent, ORIV (top x SR instrumented by top x the other rater).
# Output: oriv_sys.csv, oriv_pool.csv, oriv_resil.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()[!is.na(PQSELFREG)]
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]
d[, PEMO_z := zw(PA204Q04DA, w), by = CNT]                    # parent: "good at managing emotions when learning" (4-pt agree)
log_step("parent-report sample:", nrow(d), "students,", uniqueN(d$CNT), "systems")

# 2SLS with absorbed group effects: y on endogenous E (instruments Z) and exogenous controls X; returns coefficients on E then X
iv_fe <- function(y, E, Z, X, w, g) {
  E <- as.matrix(E); Z <- as.matrix(Z); X <- as.matrix(X)
  ok <- !is.na(y) & !is.na(w) & w > 0 & complete.cases(E, Z, X) & !is.na(g)
  M <- demean(cbind(y, E, Z, X)[ok, , drop = FALSE], g[ok], w[ok]); ww <- w[ok]
  ny <- 1; nE <- ncol(E); nZ <- ncol(Z)
  yy <- M[, 1]; EE <- M[, 1 + seq_len(nE), drop = FALSE]; ZZ <- M[, 1 + nE + seq_len(nZ), drop = FALSE]; XX <- M[, -(1:(1 + nE + nZ)), drop = FALSE]
  IN <- cbind(ZZ, XX); fs <- lm.wfit(IN, EE, ww)$coefficients; Eh <- IN %*% as.matrix(fs)
  b <- lm.wfit(cbind(Eh, XX), yy, ww)$coefficients; names(b) <- c(colnames(E), colnames(X)); b
}
# stacked ORIV: copy 1 instruments E1 with E2, copy 2 instruments E2 with E1; the coefficient on the stacked endogenous block is the
# ORIV estimate. Controls and group effects are copy-specific. E1, E2 are matrices with the same column names.
oriv_fe <- function(y, E1, E2, X, w, g) {
  E1 <- as.matrix(E1); E2 <- as.matrix(E2); X <- as.matrix(X); n <- length(y)
  ok <- complete.cases(E1, E2)                                 # both raters observed in both copies
  E1[!ok, ] <- NA
  c2 <- rep(0:1, each = n)
  Xs <- rbind(cbind(X, matrix(0, n, ncol(X))), cbind(matrix(0, n, ncol(X)), X)); colnames(Xs) <- c(paste0(colnames(X), "_1"), paste0(colnames(X), "_2"))
  Xs <- cbind(Xs, copy2 = c2)                                  # absorbed anyway by copy-specific groups; harmless
  Es <- rbind(E1, E2); Zs <- rbind(E2, E1)
  gs <- ifelse(is.na(c(g, g)), NA_character_, paste(c(g, g), c2))   # keep missing school IDs missing (ISL, LUX, MAC, MLT)
  iv_fe(c(y, y), Es, Zs, Xs[, -ncol(Xs), drop = FALSE], c(w, w), gs)
}
ctl <- function(s, extra = NULL) { v <- avail(s, c("female", "AGE", "g_m1", "g_p1")); X <- as.matrix(s[, ..v]); if (!is.null(extra)) X <- cbind(X, extra); X }
safe <- function(expr, k) tryCatch(expr, error = function(e) rep(NA_real_, k))

# ---------------- Part A: per-system slopes ----------------
stat_a <- function(s, y, w) {
  az <- (y - wmean(y, w)) / wsd(y, w); g <- s$CNTSCHID; out <- c()
  for (spec in c("noach", "ach")) {
    X <- if (spec == "ach") ctl(s, cbind(ach = az)) else ctl(s)
    Ss <- cbind(SR = s$SELFREG_z); Sp <- cbind(SR = s$PQSELFREG_z)
    keep <- complete.cases(Ss, Sp)                             # common sample for every estimator
    yv <- ifelse(keep, s$LS_z, NA)
    out[paste0(spec, ":ols_student")] <- safe(fwls(yv, cbind(SR = Ss[, 1], X), w, g)["SR"], 1)
    out[paste0(spec, ":ols_parent")]  <- safe(fwls(yv, cbind(SR = Sp[, 1], X), w, g)["SR"], 1)
    out[paste0(spec, ":iv_s_by_p")]   <- safe(iv_fe(yv, Ss, Sp, X, w, g)["SR"], 1)
    out[paste0(spec, ":iv_p_by_s")]   <- safe(iv_fe(yv, Sp, Ss, X, w, g)["SR"], 1)
    out[paste0(spec, ":oriv")]        <- safe(oriv_fe(yv, Ss, Sp, X, w, g)["SR"], 1)
    out[paste0(spec, ":fs_s_on_p")]   <- safe(fwls(ifelse(keep, Ss[, 1], NA), cbind(SR = Sp[, 1], X), w, g)["SR"], 1)
    # ORIV slopes are per SD of an observed measure, i.e. inflated by 1/loading. The scale-free quantity is the correlation of LS with
    # the latent skill shared by the two raters: r(y,X*)^2 = r(y,s) r(y,p) / r(s,p) (LS treated as error-free -> a lower bound)
    lr <- out[paste0(spec, ":ols_student")] * out[paste0(spec, ":ols_parent")] / out[paste0(spec, ":fs_s_on_p")]
    out[paste0(spec, ":latent_r")] <- if (is.na(lr)) NA else sign(lr) * sqrt(abs(lr))
    # student skill index (broader construct) vs parent self-regulation rating
    Si <- cbind(SR = s$SEI); ki <- complete.cases(Si, Sp); yi <- ifelse(ki, s$LS_z, NA)
    out[paste0(spec, ":ols_sei")]  <- safe(fwls(yi, cbind(SR = Si[, 1], X), w, g)["SR"], 1)
    out[paste0(spec, ":oriv_sei")] <- safe(oriv_fe(yi, Si, Sp, X, w, g)["SR"], 1)
    # parent-rated emotion management (the SSES skill PISA 2025 lacks), cross-rater
    out[paste0(spec, ":ols_parent_emo")] <- safe(fwls(s$LS_z, cbind(SR = s$PEMO_z, X), w, g)["SR"], 1)
  }
  out["n"] <- sum(complete.cases(s$SELFREG_z, s$PQSELFREG_z, s$LS_z))
  out
}
log_step("part A: per-system slopes")
ra <- run_systems(d, stat_a)
fwrite(ra, orr("oriv_sys.csv"))
pa <- pool_by(ra[term != "n"], "term")
# pooled first-stage strength: (RE mean / RE se)^2 is a crude pooled F; per-system F = (est/se)^2
fsF <- ra[term == "ach:fs_s_on_p", .(CNT, F = (est / se)^2)]
weak <- fsF[F < 10, CNT]
log_step("per-system first-stage F (ach spec):", paste(sprintf("%s=%.0f", fsF$CNT, fsF$F), collapse = " "))
pa_strong <- pool_by(ra[term != "n" & !CNT %in% weak], "term")[, sample := "F>=10"]
pa[, sample := "all"]
fwrite(rbind(pa, pa_strong, fill = TRUE), orr("oriv_pool.csv"))
print(rbind(pa, pa_strong, fill = TRUE)[, .(sample, term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), I2 = round(I2), sig_pos, sig_neg)], nrows = 100)

# ---------------- Part B: resilience gap x self-regulation, pooled over systems ----------------
# normalise the final and replicate weights per system so every system counts equally (replicate variation is preserved)
d[, nf := sum(W_FSTUWT), by = CNT]
for (v in c("W_FSTUWT", RW)) set(d, j = v, value = d[[v]] / d$nf)
stat_b <- function(s, y, w) {
  # resilience cells per system (quartiles within system, with the weight in use)
  top <- low <- integer(nrow(s)); az <- numeric(nrow(s))
  for (cn in unique(s$CNT)) { i <- which(s$CNT == cn); q <- wquant(y[i], w[i], c(.25, .75))
    top[i] <- as.integer(y[i] >= q[2]); low[i] <- as.integer(y[i] <= q[1]); az[i] <- (y[i] - wmean(y[i], w[i])) / wsd(y[i], w[i]) }
  q1 <- s$sesq == 1 & (top == 1 | low == 1) & complete.cases(s$SELFREG_z, s$PQSELFREG_z)
  g <- s$CNTSCHID; out <- c()
  for (spec in c("noach", "ach")) {
    X <- ctl(s, if (spec == "ach") cbind(ach = az) else NULL)                # continuous achievement on top of the cell contrast (halo control)
    X <- cbind(top = top, X)
    yv <- ifelse(q1, s$LS_z, NA)
    mk <- function(sr) cbind(SR = sr, topXSR = top * sr)
    Ss <- mk(s$SELFREG_z); Sp <- mk(s$PQSELFREG_z)
    b1 <- safe(fwls(yv, cbind(Ss, X), w, g)[c("top", "SR", "topXSR")], 3)
    b2 <- safe(fwls(yv, cbind(Sp, X), w, g)[c("top", "SR", "topXSR")], 3)
    b3 <- safe({ b <- oriv_fe(yv, Ss, Sp, X, w, g); c(mean(b[c("top_1", "top_2")]), b[c("SR", "topXSR")]) }, 3)   # controls are copy-specific
    b0 <- safe(fwls(yv, X, w, g)["top"], 1)
    out[paste0(spec, ":gap_noSR")] <- b0
    out[paste0(spec, ":ols_student:", c("top", "SR", "topXSR"))] <- b1
    out[paste0(spec, ":ols_parent:", c("top", "SR", "topXSR"))]  <- b2
    out[paste0(spec, ":oriv:", c("top", "SR", "topXSR"))]        <- b3
  }
  out["n:R"] <- sum(q1 & top == 1); out["n:PL"] <- sum(q1 & low == 1)
  out
}
log_step("part B: pooled resilience x self-regulation")
rb <- rbind(pisa_est(d, stat_b, ACH)[, sample := "all"],
            pisa_est(d[!CNT %in% weak], stat_b, ACH)[, sample := "F>=10"])
rb[, `:=`(t = est / se)]
fwrite(rb, orr("oriv_resil.csv"))
print(rb, digits = 3, nrows = 100)
log_step("done; weak first stage (F<10):", paste(weak, collapse = " "))
