# Wellbeing papers -- shared survey-estimation helpers (FROZEN shared layer; legacy, not yet migrated to 02_scripts/01_harmonization).
# Used by 05_papers/03_resilience_cost and 05_papers/04_price_of_progress. Neither paper session edits this folder; a change here
# alters both papers and must be made deliberately, with both papers re-estimated into fresh output directories and compared.
# Contents: plausible-value / replicate-weight names, Fay BRR + Rubin estimator, weighted moments and quantiles, within-group
# demeaning and WLS with absorbed school effects, DerSimonian-Laird pooling, the per-system parallel runner.
# pisa_est(), wmean(), wsd(), PV(), RW and log_step() are verbatim copies of the functions the pipeline used on 2026-11-14
# (then sourced from the grade-gain project); they are kept here so the wellbeing papers do not depend on another project's code.
suppressPackageStartupMessages({ library(data.table) })
PV  <- function(dom) paste0("PV", 1:10, dom)
RW  <- paste0("W_FSTURWT", 1:80)
pisa_est <- function(dt, statfun, ys, brr = TRUE) {            # Fay BRR (k = 0.5) + Rubin over PVs; statfun(dt, y, w) -> named vector
  th_pv <- sapply(ys, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT))
  if (is.null(dim(th_pv))) th_pv <- matrix(th_pv, nrow = 1, dimnames = list(names(statfun(dt, dt[[ys[1]]], dt$W_FSTUWT)), ys))   # scalar statistic: keep its own name
  est <- rowMeans(th_pv); v_imp <- if (length(ys) > 1) (1 + 1 / length(ys)) * apply(th_pv, 1, var) else 0; v_samp <- 0
  if (brr) { th_r <- sapply(RW, function(r) statfun(dt, dt[[ys[1]]], dt[[r]])); if (is.null(dim(th_r))) th_r <- matrix(th_r, nrow = 1); v_samp <- rowSums((th_r - th_pv[, 1])^2) / 20 }
  data.table(term = names(est), est = est, se = sqrt(v_samp + v_imp))
}
wmean <- function(x, w) { ok <- !is.na(x) & !is.na(w); sum(x[ok] * w[ok]) / sum(w[ok]) }
wsd   <- function(x, w) { ok <- !is.na(x) & !is.na(w); m <- wmean(x[ok], w[ok]); sqrt(sum(w[ok] * (x[ok] - m)^2) / sum(w[ok])) }
log_step <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")

# prepared inputs (written by 02_prepare.R in this folder). WELLBEING_DERIVED redirects them for validation runs.
DERIVED <- Sys.getenv("WELLBEING_DERIVED", "01_data/derived")
DERIV <- file.path(DERIVED, "resilwb_analytic.rds")
STUDENTS <- file.path(DERIVED, "resilwb_students.csv.gz")       # item-level extract (01_build.py)
SE6 <- c("PERSEV", "CURIO", "ENPROBS", "COGABIL", "GOALSET", "SELFREG")
CTX <- c("BELONG", "BULLIED", "FAMSUP", "FEELSAFE")
ACH <- paste0("ACH", 1:10)                         # PV-wise achievement composites, built in 02_prepare.R
MIN_CELL <- 80                                     # minimum unweighted students per contrasted cell in a system

load_rw <- function() readRDS(DERIV)
zw <- function(x, w) (x - wmean(x, w)) / wsd(x, w)
wquant <- function(x, w, p) { k <- !is.na(x) & !is.na(w); x <- x[k]; w <- w[k]; o <- order(x); cw <- cumsum(w[o]) / sum(w); x[o][findInterval(p, cw) + 1] }
# 1 = bottom quartile ... 4 = top quartile, weighted, within the data passed (call per system)
wquartile <- function(x, w) { q <- wquant(x, w, c(.25, .5, .75)); ifelse(is.na(x), NA_integer_, 1L + findInterval(x, q, left.open = TRUE)) }

# weighted within-group demeaning of a matrix (school fixed effects); rows with any NA are dropped first
demean <- function(M, g, w) {
  M <- as.matrix(M); sw <- rowsum(w, g); mu <- rowsum(M * w, g) / as.vector(sw)
  M - mu[match(g, rownames(mu)), , drop = FALSE]
}
# WLS of y on X with optional absorbed group effects; returns named coefficient vector (NA for aliased columns)
fwls <- function(y, X, w, g = NULL) {
  X <- as.matrix(X); ok <- !is.na(y) & !is.na(w) & w > 0 & complete.cases(X) & (if (is.null(g)) TRUE else !is.na(g))
  y <- y[ok]; X <- X[ok, , drop = FALSE]; w <- w[ok]
  if (!is.null(g)) { g <- g[ok]; Z <- demean(cbind(y, X), g, w); y <- Z[, 1]; X <- Z[, -1, drop = FALSE] }
  else X <- cbind(`(Intercept)` = 1, X)
  b <- lm.wfit(X, y, w)$coefficients; b
}
# controls that exist in this system (>50% non-missing) -- Germany has no sex variable
avail <- function(s, v) v[vapply(v, function(x) x %in% names(s) && mean(!is.na(s[[x]])) > 0.5, logical(1))]

# DerSimonian-Laird random-effects pooling across systems (same as skillsgain)
pool <- function(est, se) {
  ok <- !is.na(est) & !is.na(se) & se > 0; y <- est[ok]; s2 <- se[ok]^2; S <- length(y)
  if (S == 0) return(data.table(n_sys = 0))
  w <- 1 / s2; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- if (S > 1 && C > 0) max(0, (Q - (S - 1)) / C) else 0; wr <- 1 / (s2 + t2); re <- sum(wr * y) / sum(wr)
  data.table(n_sys = S, re_mean = re, re_se = sqrt(1 / sum(wr)), median = median(y), tau_sd = sqrt(t2),
             I2 = if (Q > 0) max(0, (Q - (S - 1)) / Q) * 100 else 0, n_neg = sum(y < 0),
             sig_pos = sum(y / sqrt(s2) > 1.96), sig_neg = sum(y / sqrt(s2) < -1.96))
}
pool_by <- function(dt, keys) dt[, pool(est, se), by = keys]

# run statfun on every system in parallel; statfun(dt, y = achievement composite, w) -> named vector
run_systems <- function(d, statfun, systems = unique(d$CNT), cores = 6) {
  res <- parallel::mclapply(systems, function(cn) {
    s <- d[CNT == cn]
    out <- tryCatch(pisa_est(s, statfun, ACH), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL })
    if (!is.null(out)) out[, CNT := cn]
    out
  }, mc.cores = cores)
  rbindlist(res, fill = TRUE)
}
