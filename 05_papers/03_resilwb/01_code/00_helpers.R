# The Cost of Resilience -- shared helpers
# Socio-emotional skills, academic resilience and life satisfaction at 15 (PISA 2025, every system with the measures).
# Resilient = bottom within-system ESCS quartile AND top within-system achievement quartile (mean of math, reading, science; PV by PV).
# Core estimand: the within-school life-satisfaction gap between resilient students and disadvantaged low achievers, how it moves when
# skills and relationships are held fixed, whether it survives response-style controls, and whether it is larger than the
# high-achiever gap among advantaged students.
# Estimation is per system (Fay BRR, 80 replicates + Rubin over 10 PVs, via gradegain's pisa_est); the PV enters through the
# achievement composite, so resilience status is re-derived for every PV and every replicate weight. Cross-system summaries are
# DerSimonian-Laird random-effects means (skillsgain's pool()). Outputs are CSV in 03_outputs/resilwb/.
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/gradegain/00_helpers.R")      # PV(), RW, pisa_est(), wmean(), wsd(), log_step(), SYS_NAMES
OUTR <- "03_outputs/resilwb/"; dir.create(OUTR, recursive = TRUE, showWarnings = FALSE)
orr <- function(f) paste0(OUTR, f)
DERIV <- "01_data/derived/resilwb_analytic.rds"

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
