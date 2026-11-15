# The price of progress -- numerical test of the cutoff estimators in 00_helpers.R. Simulated data only: reads no data, fits nothing
# on PISA, writes nothing. Run from the repository root:  Rscript 05_papers/04_price_of_progress/01_code/test_tsls.R
#   (1) tsls_m() against a direct matrix solution of weighted 2SLS, with 0, 1 and 2 moderators, with and without missing outcomes
#       in the middle of the sample (the case in which the grade-gain project's earlier function misaligned its two stages)
#   (2) tsls_m() without moderators against the grade-gain project's corrected tsls() (05_papers/02_fuzzy_rd_learning)
#   (3) est_sys(fe = "school") against the same matrix solution with one dummy per school
#   (4) est_sys() on a plausible-value outcome: the estimate is the mean of the ten per-value solutions
PAPER_OUT_TMP <- tempfile("pop_test_"); Sys.setenv(PAPER_OUT = PAPER_OUT_TMP)          # 00_helpers.R creates its output directory
source("05_papers/04_price_of_progress/01_code/00_helpers.R")
unlink(PAPER_OUT_TMP, recursive = TRUE)
TOL <- 1e-8; n_checks <- 0L
same <- function(a, b, what) { if (!isTRUE(all.equal(unname(a), unname(b), tolerance = TOL))) stop("MISMATCH: ", what, "  ", format(a, digits = 12), " vs ", format(b, digits = 12)); n_checks <<- n_checks + 1L }

# direct weighted 2SLS: b = (X' P_Q X)^-1 X' P_Q y, weights w; EX exogenous, EN endogenous, IV excluded instruments
m2sls <- function(y, EX, EN, IV, w) {
  ok <- is.finite(y) & complete.cases(EX, EN, IV) & is.finite(w); y <- y[ok]; w <- w[ok]
  X <- cbind(EX, EN)[ok, , drop = FALSE]; Q <- cbind(EX, IV)[ok, , drop = FALSE]
  QQ <- crossprod(Q, w * Q); XQ <- crossprod(X, w * Q)
  b <- drop(solve(XQ %*% solve(QQ, t(XQ)), XQ %*% solve(QQ, crossprod(Q, w * y))))
  fs <- drop(solve(QQ, crossprod(Q, w * EN[ok, 1])))                                    # first stage of the grade itself
  list(b = b, fs = fs)
}

set.seed(20261114); n <- 900
s <- data.table(school = sample(sprintf("s%02d", 1:30), n, replace = TRUE), r = sample(-8:3, n, replace = TRUE),
                female = rbinom(n, 1, .5), immigrant = rbinom(n, 1, .15), lowSES = rbinom(n, 1, .25), skill = rnorm(n))
s[, Z := as.numeric(r < 0)]
s[, D := as.numeric(.7 * Z + .15 * skill - .1 * lowSES + rnorm(n, sd = .5) > .35)]
s[, u := rnorm(30)[as.integer(factor(school))]]
s[, y := 1 + u - .08 * D + .004 * r + .1 * female - .2 * lowSES + .3 * skill - .05 * D * lowSES + rnorm(n)]
s[, W_FSTUWT := runif(n, .5, 3)]
for (j in 1:80) s[, (paste0("W_FSTURWT", j)) := W_FSTUWT * sample(c(.5, 1.5), n, replace = TRUE)]
for (p in 1:10) s[, (paste0("PV", p, "TST")) := 480 + 20 * D - .8 * r + 15 * skill + rnorm(n, sd = 60)]
X <- cbind(`(Intercept)` = 1, as.matrix(s[, .(female, immigrant)]))

for (miss in list(integer(), c(3, 17, 28, 62, 84, 119, 400, 401, 733))) {
  yy <- s$y; yy[miss] <- NA_real_
  for (mods in list(character(0), "lowSES", c("lowSES", "skill"))) {
    k <- length(mods); M <- if (k) as.matrix(s[, ..mods]) else matrix(numeric(0), n, 0); lab <- paste0("[", length(miss), " missing, moderators: ", paste(mods, collapse = "+"), "]")
    EX <- cbind(X, r = s$r, if (k) `colnames<-`(s$r * M, paste0("r:", mods)), if (k) M)
    EN <- cbind(D = s$D, if (k) `colnames<-`(s$D * M, paste0("D:", mods)))
    IV <- cbind(Z = s$Z, if (k) `colnames<-`(s$Z * M, paste0("Z:", mods)))
    ref <- m2sls(yy, EX, EN, IV, s$W_FSTUWT); b <- ref$b
    got <- tsls_m(yy, s$D, s$Z, s$r, M, X, s$W_FSTUWT)
    same(got["tau"], b["D"], paste("tsls_m tau", lab)); same(got["gamma"], b["D"] - 12 * b["r"], paste("tsls_m gamma", lab))
    same(got["fs"], ref$fs["Z"], paste("tsls_m first stage", lab))
    for (m in mods) same(got[paste0("gamma:", m)], b[paste0("D:", m)] - 12 * b[paste0("r:", m)], paste("tsls_m interaction", m, lab))

    # (3) school fixed effects: within-school demeaning in est_sys() against one dummy per school
    s[, y_t := yy]
    fe <- est_sys(s, "y_t", mods = mods, fe = "school"); g <- function(tm) fe[term == tm, est]
    S <- model.matrix(~ 0 + school, s)
    refF <- m2sls(yy, cbind(S, EX[, -1, drop = FALSE]), EN, IV, s$W_FSTUWT); bF <- refF$b
    same(g("tau"), bF["D"], paste("school FE tau", lab)); same(g("gamma"), bF["D"] - 12 * bF["r"], paste("school FE gamma", lab))
    same(g("fs"), refF$fs["Z"], paste("school FE first stage", lab))
    for (m in mods) same(g(paste0("gamma:", m)), bF[paste0("D:", m)] - 12 * bF[paste0("r:", m)], paste("school FE interaction", m, lab))
    stopifnot(all(is.finite(fe$se)), all(fe$se > 0)); s[, y_t := NULL]
  }

  # (2) the grade-gain project's corrected function, no moderators
  GG <- "05_papers/02_fuzzy_rd_learning/01_code/model_functions.R"
  if (file.exists(GG)) {
    e <- new.env(); sys.source(GG, envir = e)
    a <- e$tsls(yy, s$D, s$Z, cbind(1, r = s$r, as.matrix(s[, .(female, immigrant)])), s$W_FSTUWT)
    b0 <- tsls_m(yy, s$D, s$Z, s$r, matrix(numeric(0), n, 0), X, s$W_FSTUWT)
    for (tm in c("fs", "tau", "gamma")) same(b0[tm], a[tm], paste("tsls_m vs grade-gain tsls:", tm, "[", length(miss), "missing ]"))
  } else cat("NOT RUN: comparison with the grade-gain project's tsls() (", GG, "not found)\n")
}

# (4) plausible-value outcome: point estimate = mean over the ten values of the per-value solution
pv <- est_sys(s, "TST")
per <- sapply(PV("TST"), function(v) { b <- m2sls(s[[v]], cbind(X, r = s$r), cbind(D = s$D), cbind(Z = s$Z), s$W_FSTUWT)$b; c(tau = unname(b["D"]), gamma = unname(b["D"] - 12 * b["r"])) })
same(pv[term == "tau", est], mean(per["tau", ]), "plausible values: tau"); same(pv[term == "gamma", est], mean(per["gamma", ]), "plausible values: gamma")

cat("PASS:", n_checks, "comparisons within", TOL, "- tsls_m() and est_sys() agree with direct weighted 2SLS (moderators, missing outcomes, school fixed effects, plausible values) and with the grade-gain project's tsls().\n")
