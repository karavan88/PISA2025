# IV learning -- numerical test of the estimators in 00_helpers.R. Simulated data only: reads no data, writes nothing.
#   Rscript 06_scoping/13_iv_learning/01_code/test_estimators.R
#   (1) grade_gain() against fixest::feols IV: no moderator, one moderator, controls, missing outcomes in the middle of the sample
#   (2) grade_gain(fe = ) against feols with school fixed effects
#   (3) pisa_est(): estimate = mean over plausible values; standard error = the stated Fay and Rubin formula, computed by hand
#       pisa_cov(): same estimates, diagonal equal to pisa_est, off-diagonal by hand
#   (4) pool(): against a hand computation on three numbers
#   (6) spread(): recovers a known between-unit spread, bounds it from above, and finds none where there is none
#   (5) ivqr(): recovers a known rank-dependent gain, agrees with a grid search, and differs from ordinary quantile regression
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
suppressPackageStartupMessages(library(fixest))
TOL <- 1e-8; n_checks <- 0L
same <- function(a, b, what) { if (!isTRUE(all.equal(unname(a), unname(b), tolerance = TOL))) stop("MISMATCH: ", what, "  ", format(a, digits = 12), " vs ", format(b, digits = 12)); n_checks <<- n_checks + 1L }

set.seed(20261122); n <- 1200
s <- data.table(school = sample(sprintf("s%02d", 1:40), n, replace = TRUE), r = sample(-8:3, n, replace = TRUE),
                female = rbinom(n, 1, .5), ses = rnorm(n), abil = rnorm(n))
s[, Z := as.numeric(r < 0)]
s[, D := as.numeric(.7 * Z + .2 * abil + .1 * ses + rnorm(n, sd = .5) > .35)]
s[, u := rnorm(40)[as.integer(factor(school))]]
s[, y := 480 + 20 * u + 30 * D - .8 * r + 25 * ses + 20 * abil - 6 * D * ses + rnorm(n, sd = 60)]
s[, W_FSTUWT := runif(n, .5, 3)]
for (j in 1:80) s[, (paste0("W_FSTURWT", j)) := W_FSTUWT * sample(c(.5, 1.5), n, replace = TRUE)]
for (p in 1:10) s[, (paste0("PV", p, "TST")) := y + rnorm(n, sd = 25)]

for (miss in list(integer(), c(3, 17, 28, 62, 84, 119, 400, 401, 733, 1100))) {
  s[, yy := y]; s[miss, yy := NA_real_]; lab <- paste0("[", length(miss), " missing]")
  # (1) no moderator
  g <- grade_gain(s, s$yy, s$W_FSTUWT); f <- feols(yy ~ r | D ~ Z, s, weights = ~W_FSTUWT)
  same(g["tau"], coef(f)["fit_D"], paste("tau", lab)); same(g["gamma"], coef(f)["fit_D"] - 12 * coef(f)["r"], paste("gamma", lab))
  same(g["fs"], coef(f$iv_first_stage$D)["Z"], paste("first stage", lab)); same(g["n"], nobs(f), paste("n", lab))
  # controls
  g <- grade_gain(s, s$yy, s$W_FSTUWT, ctrl = "female"); f <- feols(yy ~ r + female | D ~ Z, s, weights = ~W_FSTUWT)
  same(g["tau"], coef(f)["fit_D"], paste("tau with control", lab))
  # one moderator: D x ses instrumented by Z x ses
  s[, `:=`(Dses = D * ses, Zses = Z * ses, rses = r * ses)]
  g <- grade_gain(s, s$yy, s$W_FSTUWT, mods = "ses"); f <- feols(yy ~ r + rses + ses | D + Dses ~ Z + Zses, s, weights = ~W_FSTUWT)
  same(g["tau"], coef(f)["fit_D"], paste("tau, moderated model", lab)); same(g["tau:ses"], coef(f)["fit_Dses"], paste("tau x ses", lab))
  same(g["gamma:ses"], coef(f)["fit_Dses"] - 12 * coef(f)["rses"], paste("gamma x ses", lab))
  same(g["main:ses"], coef(f)["ses"], paste("main effect of ses", lab)); same(g["age:ses"], -12 * coef(f)["rses"], paste("age slope x ses", lab))
  same(g["gamma:ses"], g["tau:ses"] + g["age:ses"], paste("gamma x ses = tau x ses + age x ses", lab))
  # (2) school fixed effects
  g <- grade_gain(s, s$yy, s$W_FSTUWT, fe = "school"); f <- feols(yy ~ r | school | D ~ Z, s, weights = ~W_FSTUWT)
  same(g["tau"], coef(f)["fit_D"], paste("school FE tau", lab)); same(g["gamma"], coef(f)["fit_D"] - 12 * coef(f)["r"], paste("school FE gamma", lab))
  g <- grade_gain(s, s$yy, s$W_FSTUWT, mods = "ses", fe = "school"); f <- feols(yy ~ r + rses + ses | school | D + Dses ~ Z + Zses, s, weights = ~W_FSTUWT)
  same(g["tau:ses"], coef(f)["fit_Dses"], paste("school FE tau x ses", lab)); same(g["main:ses"], coef(f)["ses"], paste("school FE main effect", lab))
  # another treatment column
  s[, yrs := D + rbinom(n, 1, .1)]
  g <- grade_gain(s, s$yy, s$W_FSTUWT, treat = "yrs"); f <- feols(yy ~ r | yrs ~ Z, s, weights = ~W_FSTUWT)
  same(g["tau"], coef(f)["fit_yrs"], paste("other treatment", lab))
}

# (3) replicate weights and plausible values
stat <- function(dt, y, w) grade_gain(dt, y, w)[c("fs", "tau", "gamma")]
e <- pisa_est(s, stat, PV("TST"))
th <- sapply(PV("TST"), function(p) stat(s, s[[p]], s$W_FSTUWT)); rp <- sapply(RW, function(rw) stat(s, s$PV1TST, s[[rw]]))
same(e$est, rowMeans(th), "pisa_est estimate")
same(e$se, sqrt(rowSums((rp - th[, 1])^2) / 20 + 1.1 * apply(th, 1, var)), "pisa_est standard error")
e1 <- pisa_est(s, function(dt, y, w) c(fs = unname(grade_gain(dt, y, w)["fs"])), "y")
same(e1$se, sqrt(sum((sapply(RW, function(rw) grade_gain(s, s$y, s[[rw]])["fs"]) - grade_gain(s, s$y, s$W_FSTUWT)["fs"])^2) / 20), "pisa_est, single column")

cv <- pisa_cov(s, stat, PV("TST"))
same(cv$est, e$est, "pisa_cov estimate"); same(sqrt(diag(cv$V)), e$se, "pisa_cov diagonal = pisa_est standard errors")
same(cv$V["tau", "gamma"], sum((rp["tau", ] - th["tau", 1]) * (rp["gamma", ] - th["gamma", 1])) / 20 + 1.1 * cov(th["tau", ], th["gamma", ]), "pisa_cov off-diagonal")

# (4) random-effects pooling by hand
y <- c(10, 20, 45); se <- c(4, 5, 6); v <- se^2; w <- 1 / v; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2)
t2 <- max(0, (Q - 2) / (sum(w) - sum(w^2) / sum(w))); wr <- 1 / (v + t2); p <- pool(y, se)
same(p$re_mean, sum(wr * y) / sum(wr), "pool mean"); same(p$re_se, sqrt(1 / sum(wr)), "pool se"); same(p$tau_sd, sqrt(t2), "pool tau")
same(c(p$pos_05, p$pos_10), c(3, 3), "pool significance counts")
# (5) quantile instrumental variables: a simulated population whose gain rises with the student's rank, 8 at the 10th percentile,
# 20 at the median, 32 at the 90th, with grade chosen partly on that rank (so ordinary quantile regression is biased).
# The estimator must recover the three values within sampling error, must agree with a plain grid search, and ordinary
# quantile regression must miss; the age slope is 12 points a year at every rank, so gamma = tau + 12.
set.seed(7); N <- 60000; U <- runif(N); rr <- sample(-8:3, N, replace = TRUE); ZZ <- as.numeric(rr < 0)
DD <- as.numeric(.7 * ZZ + 1.2 * (U - .5) + rnorm(N, sd = .4) > .35); ww <- runif(N, .5, 3)
YY <- 500 + 20 * qnorm(U) + (20 + 30 * (U - .5)) * DD - rr          # a tight score distribution, so that sampling error is small enough to test against
near <- function(a, b, tol, what) { if (!is.finite(a) || abs(a - b) > tol) stop("MISMATCH: ", what, "  ", format(a), " vs ", format(b)); n_checks <<- n_checks + 1L }
for (q in c(.1, .5, .9)) { truth <- 20 + 30 * (q - .5); e <- ivqr(YY, DD, ZZ, rr, ww, q)
  near(e["tau"], truth, 6, paste("ivqr tau at", q)); near(e["gamma"], truth + 12, 7, paste("ivqr gamma at", q))
  grid <- seq(truth - 15, truth + 15, by = 1); gz <- sapply(grid, function(al) abs(quantreg::rq.wfit(cbind(1, rr, ZZ), YY - al * DD, tau = q, weights = ww, method = "fn")$coefficients[3]))
  near(e["tau"], grid[which.min(gz)], 1.5, paste("ivqr against grid search at", q))
  naive <- quantreg::rq.wfit(cbind(1, rr, DD), YY, tau = q, weights = ww, method = "fn")$coefficients[3]
  if (abs(naive - truth) < 8) stop("the simulated selection is too weak to test anything at ", q); n_checks <<- n_checks + 1L }
# with a covariate that shifts the score by 15 points per unit and is held fixed, the same gains must come back
cv <- rnorm(N); for (q in c(.1, .5, .9)) near(ivqr(YY + 15 * cv, DD, ZZ, rr, ww, q, extra = cbind(cv))["tau"], 20 + 30 * (q - .5), 6, paste("ivqr with a covariate at", q))
if (!all(is.na(ivqr(YY, DD, ZZ, rr, ww, .5, lo = 100, hi = 300)))) stop("ivqr must return NA when the bracket misses the root"); n_checks <- n_checks + 1L
# (6) between-unit spread: simulated units with a known spread and unequal standard errors. The estimate must sit near the truth, the
# upper bound above it, and with no spread the estimate must be near zero and the homogeneity test must not reject.
set.seed(11); J <- 4000; se_j <- runif(J, 20, 60)
for (true_sd in c(0, 15)) { yj <- 10 + rnorm(J, sd = true_sd) + rnorm(J, sd = se_j); sp <- spread(yj, se_j)
  near(sp$mean, 10, 2.5, paste("spread mean, true sd", true_sd)); near(sp$sd, true_sd, 4.5, paste("spread sd, true sd", true_sd))
  if (true_sd > 0 && !(sp$upper_sd > true_sd && sp$p < .01)) stop("spread(): upper bound or test fails with a real spread")
  if (true_sd == 0 && sp$p < .01) stop("spread(): homogeneity rejected without a spread"); n_checks <- n_checks + 1L }
same(spread(c(10, 20, 45), c(4, 5, 6))$sd, pool(c(10, 20, 45), c(4, 5, 6))$tau_sd, "spread sd = pool tau_sd")

cat("PASS:", n_checks, "comparisons (exact ones within", TOL, "; quantile ones within stated sampling tolerances)\n")
