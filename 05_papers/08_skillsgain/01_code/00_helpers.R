# Skills & the Grade Gain -- shared helpers
# Who learns more in a school year? Socio-emotional skills, family and school SES, and the causal grade gain at age 15 (PISA 2025, 20 systems).
# Builds on the Grade Gain Report (02_scripts/gradegain/): the grade gain gamma is identified by the school-entry cutoff (actual grade D
# instrumented by the theoretical grade Z, school-starting age linear, Avvisati & Givord 2021). Here gamma is allowed to vary with moderators M:
#   endogenous D, D*M ; instruments Z, Z*M ; exogenous 1, r, r*M, M, x      (r = birth month relative to the cutoff)
#   gamma(M) = (b_D + b_DM'M) - 12 (b_r + b_rM'M)  ->  gamma_0 = b_D - 12 b_r (at M = 0)  and  gamma_M = b_DM - 12 b_rM (per SD of M)
# Moderators are standardised within system, so gamma_0 is the grade gain at the system mean and gamma_M its change per SD.
# All estimation is per system (Fay BRR, 80 replicates + Rubin over 10 PVs); cross-system summaries are equal-weight means and
# DerSimonian-Laird random-effects means. Outputs are CSV in 03_outputs/skillsgain/; the report only reads them.
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/gradegain/00_helpers.R")                               # PV(), RW, pisa_est(), wmean(), wsd(), SYS_NAMES, REGION
OUTS <- "03_outputs/skillsgain/"; dir.create(OUTS, recursive = TRUE, showWarnings = FALSE)
os <- function(f) paste0(OUTS, f)

# the study set: 14 systems outside Europe + 6 European OECD systems, all eligible in the Grade Gain Report
SYS_A <- c("KEN", "QCI", "MUS", "TAP", "PRY", "KHM", "PER", "ECU", "BRA", "ARE", "HKG", "BRN", "PHL", "CRI")
SYS_B <- c("CZE", "EST", "DEU", "SVK", "FIN", "HRV")
SYS20 <- c(SYS_A, SYS_B)
GROUP <- setNames(c(rep("Non-European (14)", length(SYS_A)), rep("European OECD (6)", length(SYS_B))), SYS20)

SE6   <- c("PERSEV", "GOALSET", "SELFREG", "CURIO", "ENPROBS", "COGABIL")  # the six socio-emotional scales of PISA 2025
SE_TASK <- c("PERSEV", "GOALSET", "SELFREG")                               # task performance / self-management
SE_OPEN <- c("CURIO", "ENPROBS", "COGABIL")                                # open-mindedness / intellectual engagement
mod_lab <- c(SE = "Socio-emotional index", SE_task = "Self-management (persev., goals, self-reg.)", SE_open = "Open-mindedness (curiosity, problem-solving, adaptability)",
             SE_p = "Socio-emotional index (grade-purged)", SES = "Student SES", schSES = "School SES", SExSES = "SE × student SES", SExschSES = "SE × school SES",
             PERSEV = "Perseverance", GOALSET = "Goal setting", SELFREG = "Self-regulation", CURIO = "Curiosity", ENPROBS = "Enjoyment of problem-solving", COGABIL = "Cognitive adaptability",
             female = "Female", immigrant = "Immigrant", books = "Books at home", books_z = "Books at home", lang_other = "Other home language")
ml <- function(x) ifelse(x %in% names(mod_lab), mod_lab[x], x)
DOMS <- c("SCIE", "MATH", "READ")
OUT4 <- c("ACH", DOMS)                                                     # ACH = mean of the three domains, PV by PV
out_lab4 <- c(ACH = "Achievement (3-domain mean)", SCIE = "Science", MATH = "Mathematics", READ = "Reading")

load_sg <- function() readRDS("01_data/derived/skillsgain_analytic.rds")
zw <- function(x, w) (x - wmean(x, w)) / wsd(x, w)

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
pool <- function(est, se) {
  ok <- !is.na(est) & !is.na(se) & se > 0; y <- est[ok]; s2 <- se[ok]^2; S <- length(y)
  w <- 1 / s2; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- if (S > 1 && C > 0) max(0, (Q - (S - 1)) / C) else 0; wr <- 1 / (s2 + t2); re <- sum(wr * y) / sum(wr)
  data.table(n_sys = S, mean = mean(y), mean_se = sqrt(sum(s2)) / S, median = median(y), re_mean = re, re_se = sqrt(1 / sum(wr)),
             tau_sd = sqrt(t2), I2 = if (Q > 0) max(0, (Q - (S - 1)) / Q) * 100 else 0, Q_p = pchisq(Q, S - 1, lower.tail = FALSE),
             sig_pos = sum(y / sqrt(s2) > 1.96), sig_neg = sum(y / sqrt(s2) < -1.96))
}
# Rubin over plausible values of point estimates that each carry their own sampling SE (forest summaries)
rubin <- function(dt, keys) dt[, .(est = mean(est), se = sqrt(mean(se^2) + (1 + 1 / .N) * if (.N > 1) var(est) else 0), n_pv = .N), by = keys]
log_step <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
