source("02_scripts/01_harmonization/cutoff_definitions.R")
OUTD <- paste0(Sys.getenv("PISA_RD_OUT", "05_papers/02_fuzzy_rd_learning/04_output"), "/")
dir.create(OUTD,recursive=TRUE,showWarnings=FALSE)
op <- function(f) paste0(OUTD,f)
load_analytic <- function() readRDS("03_outputs/01_harmonized/cutoff/analytic.rds")

wls <- function(X, y, w) { ok <- !is.na(y) & !is.na(w) & complete.cases(X); lm.wfit(X[ok, , drop = FALSE], y[ok], w[ok])$coefficients }
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
