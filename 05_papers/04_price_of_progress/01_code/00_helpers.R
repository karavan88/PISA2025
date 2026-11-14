# The price of progress -- paper helpers. Shared survey functions come from the frozen legacy layer; this file only sets the paper's output paths.
# PAPER_OUT redirects estimation output (use it for any re-estimation: never overwrite 04_output in place; see ../README.md).
source("02_scripts/02_legacy/wellbeing_shared/00_survey_helpers.R")
OUTR <- paste0(Sys.getenv("PAPER_OUT", "05_papers/04_price_of_progress/04_output"), "/"); dir.create(OUTR, recursive = TRUE, showWarnings = FALSE)
orr <- function(f) paste0(OUTR, f)

# ---- school-entry cutoff design (20 legacy systems). tsls_m(), est_sys() and pool_iv() are verbatim copies of the legacy
# skillsgain functions (pool_iv was called pool there); the analytic file is the legacy skillsgain build.
# Migration target: 03_outputs/01_harmonized/cutoff/analytic.rds (central, 36 systems) -- a new estimation, not a relocation.
SG_DATA <- file.path(DERIVED, "skillsgain_analytic.rds")
load_sg <- function() readRDS(SG_DATA)
source("05_papers/04_price_of_progress/01_code/systems.R"); SYSTEMS <- function() data.table::copy(SYSTEMS_TABLE)   # CNT, structure, name
# 2SLS with moderators. y outcome; D actual upper grade; Z theoretical grade; r running variable; M matrix of moderators (may have 0 cols);
# X exogenous controls (incl. intercept). Returns the grade gain at M = 0, its change per unit of each moderator, and the first stage.
# extra: named list of functions of the coefficient vector b2 (second stage) for additional quantities computed in the same replicate.
tsls_m <- function(y, D, Z, r, M, X, w, extra = NULL) {
  M <- as.matrix(M); k <- ncol(M)
  DM <- if (k) D * M else NULL; ZM <- if (k) Z * M else NULL; rM <- if (k) r * M else NULL
  if (k) { colnames(DM) <- paste0("D:", colnames(M)); colnames(ZM) <- paste0("Z:", colnames(M)); colnames(rM) <- paste0("r:", colnames(M)) }
  EX <- cbind(X, r = r, rM, M)                                              # exogenous regressors
  EN <- cbind(D = D, DM)                                                    # endogenous
  IN <- cbind(EX, Z = Z, ZM)                                                # full instrument set
  ok <- !is.na(y) & !is.na(w) & complete.cases(IN) & complete.cases(EN)
  IN <- IN[ok, , drop = FALSE]; EN <- EN[ok, , drop = FALSE]; EX <- EX[ok, , drop = FALSE]; yy <- y[ok]; ww <- w[ok]
  fs <- as.matrix(lm.wfit(IN, EN, ww)$coefficients); fs[is.na(fs)] <- 0   # first stages (one column per endogenous); aliased columns drop out
  Ehat <- IN %*% fs; colnames(Ehat) <- colnames(EN)
  b2 <- lm.wfit(cbind(EX, Ehat), yy, ww)$coefficients
  out <- c(fs = unname(as.matrix(fs)["Z", 1]), gamma = unname(b2["D"] - 12 * b2["r"]), tau = unname(b2["D"]))
  if (k) for (m in colnames(M)) out[paste0("gamma:", m)] <- unname(b2[paste0("D:", m)] - 12 * b2[paste0("r:", m)])
  if (!is.null(extra)) for (nm in names(extra)) out[nm] <- extra[[nm]](b2)
  out
}

# per-system BRR + Rubin wrapper around tsls_m for one outcome (score domain or a single variable)
est_sys <- function(s, outcome, mods = character(0), ctrl = c("female", "immigrant"), extra = NULL, fe = NULL) {
  ys <- if (paste0("PV1", outcome) %in% names(s)) PV(outcome) else outcome  # score domains (SCIE, MATH, READ, ACH) carry 10 PVs
  stopifnot(all(ys %in% names(s)))
  ctrl <- ctrl[vapply(ctrl, function(v) mean(!is.na(s[[v]])) > 0.5, logical(1))]
  X <- matrix(1, nrow(s), 1, dimnames = list(NULL, "(Intercept)")); if (length(ctrl)) X <- cbind(X, as.matrix(s[, ..ctrl]))
  M <- if (length(mods)) as.matrix(s[, ..mods]) else matrix(numeric(0), nrow(s), 0)
  f <- function(dt, y, w) {
    if (is.null(fe)) return(tsls_m(y, dt$D, dt$Z, dt$r, M, X, w, extra))
    # school fixed effects by weighted within-school demeaning of every column (replicate weight used for the demeaning too)
    g <- dt[[fe]]; dm <- function(v) { ok <- !is.na(v) & !is.na(w); m <- tapply(v[ok] * w[ok], g[ok], sum) / tapply(w[ok], g[ok], sum); v - m[as.character(g)] }
    # demeaning a product is not the product of demeaned terms: build the interactions from raw columns, then demean every column
    k <- ncol(M); Dm <- dt$D; Zm <- dt$Z; rr <- dt$r
    cc <- complete.cases(cbind(y, M, X)) & !is.na(w)
    yy <- ifelse(cc, y, NA); EXr <- cbind(rr, if (k) rr * M, M, X[, -1, drop = FALSE]); ENr <- cbind(Dm, if (k) Dm * M); INr <- cbind(Zm, if (k) Zm * M)
    yd <- dm(yy); EXd <- apply(EXr, 2, function(v) dm(ifelse(cc, v, NA))); ENd <- apply(ENr, 2, function(v) dm(ifelse(cc, v, NA))); INd <- apply(INr, 2, function(v) dm(ifelse(cc, v, NA)))
    ok <- cc & complete.cases(EXd, ENd, INd)
    IN <- cbind(EXd, INd)[ok, , drop = FALSE]; fs <- as.matrix(lm.wfit(IN, ENd[ok, , drop = FALSE], w[ok])$coefficients); fs[is.na(fs)] <- 0
    b2 <- lm.wfit(cbind(EXd[ok, , drop = FALSE], IN %*% fs), yd[ok], w[ok])$coefficients; names(b2) <- NULL
    bD <- b2[ncol(EXd) + 1]; br <- b2[1]                                   # column order: r, r*M, M, controls | D, D*M
    out <- c(fs = unname(as.matrix(fs)[ncol(EXd) + 1, 1]), gamma = bD - 12 * br, tau = bD)
    if (k) for (j in seq_len(k)) out[paste0("gamma:", colnames(M)[j])] <- b2[ncol(EXd) + 1 + j] - 12 * b2[1 + j]
    out
  }
  e <- pisa_est(s, f, ys)
  e[, n := sum(complete.cases(cbind(s[[ys[1]]], M, X)))]
  e
}

# cross-system pooling: equal-weight mean (independent samples -> SE = sqrt(sum se^2)/S) and DerSimonian-Laird random effects
pool_iv <- function(est, se) {
  ok <- !is.na(est) & !is.na(se) & se > 0; y <- est[ok]; s2 <- se[ok]^2; S <- length(y)
  w <- 1 / s2; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- if (S > 1 && C > 0) max(0, (Q - (S - 1)) / C) else 0; wr <- 1 / (s2 + t2); re <- sum(wr * y) / sum(wr)
  data.table(n_sys = S, mean = mean(y), mean_se = sqrt(sum(s2)) / S, median = median(y), re_mean = re, re_se = sqrt(1 / sum(wr)),
             tau_sd = sqrt(t2), I2 = if (Q > 0) max(0, (Q - (S - 1)) / Q) * 100 else 0, Q_p = pchisq(Q, S - 1, lower.tail = FALSE),
             sig_pos = sum(y / sqrt(s2) > 1.96), sig_neg = sum(y / sqrt(s2) < -1.96))
}
