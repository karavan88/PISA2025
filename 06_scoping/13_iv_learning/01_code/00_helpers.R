# IV learning -- helpers. The project's own estimators: nothing is sourced from another paper or from the legacy layer.
# Reads central products only. Tested by test_estimators.R against fixest on simulated data.
suppressPackageStartupMessages(library(data.table))
PROJECT <- "06_scoping/13_iv_learning"
ANALYTIC <- "03_outputs/01_harmonized/cutoff/analytic.rds"      # eligible systems: D, Z, r, weights, plausible values
RULES <- "03_outputs/04_entry_rules/entry_rules.csv"            # central entry rules and cutoff verdicts
PV <- function(dom) paste0("PV", 1:10, dom)
RW <- paste0("W_FSTURWT", 1:80)
log_step <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
wmean <- function(x, w) { ok <- !is.na(x) & !is.na(w); sum(x[ok] * w[ok]) / sum(w[ok]) }

# Estimation output goes to a new directory named in PAPER_OUT; an existing directory is never written into.
new_output <- function() {
  out <- Sys.getenv("PAPER_OUT", "")
  if (out == "") stop("Set PAPER_OUT to a new directory under ", PROJECT, "/04_output/")
  if (dir.exists(out)) stop("PAPER_OUT exists: ", out, ". Estimation never overwrites; choose a new directory.")
  dir.create(out, recursive = TRUE); paste0(out, "/")
}

# Weighted two-stage least squares. EX exogenous regressors (with intercept unless demeaned), EN endogenous, IV excluded instruments.
# Rows must be complete. Returns the second-stage coefficients (EX then EN) and the first-stage coefficient matrix.
tsls <- function(y, EX, EN, IV, w) {
  Q <- cbind(EX, IV)
  fs <- as.matrix(lm.wfit(Q, EN, w)$coefficients); rownames(fs) <- colnames(Q); colnames(fs) <- colnames(EN)
  if (anyNA(fs)) stop("collinear instruments")
  hat <- Q %*% fs; colnames(hat) <- colnames(EN)
  b <- lm.wfit(cbind(EX, hat), y, w)$coefficients
  if (anyNA(b)) stop("collinear second stage")
  list(b = b, fs = fs)
}

# Weighted within-group demeaning of every column (school fixed effects); the weight in use is also the demeaning weight.
demean <- function(M, g, w) { M <- as.matrix(M); g <- as.character(g); M - (rowsum(M * w, g) / as.vector(rowsum(w, g)))[g, , drop = FALSE] }

# Grade gain in one system for one outcome vector and one weight vector.
#   treat  endogenous treatment (D = upper grade); instrument Z = born before the cutoff; r = months from the cutoff (linear control)
#   mods   moderators M: adds treat x M (instrumented by Z x M), r x M and M
#   ctrl   exogenous controls; fe = column of school identifiers for school fixed effects
# Returns: fs   first-stage coefficient of Z on the treatment
#          tau  coefficient on the treatment, birth month fixed (HEADLINE: one more grade, a year younger at entry, youngest in class)
#          gamma  tau - 12 x coefficient on r, starting age fixed (shown beside, never the headline)
#          tau:m, gamma:m  change in each per unit of moderator m
#          main:m  coefficient on m itself (its gradient in the lower grade at the cutoff); age:m  change in the yearly age slope per unit of m
grade_gain <- function(dt, y, w, treat = "D", mods = character(0), ctrl = character(0), fe = NULL) {
  k <- length(mods); M <- if (k) as.matrix(dt[, ..mods]) else NULL
  Tr <- dt[[treat]]; Z <- dt$Z; r <- dt$r
  EX <- cbind(r = r, if (k) `colnames<-`(r * M, paste0("r:", mods)), M, if (length(ctrl)) as.matrix(dt[, ..ctrl]))
  EN <- cbind(D = Tr, if (k) `colnames<-`(Tr * M, paste0("D:", mods)))
  IV <- cbind(Z = Z, if (k) `colnames<-`(Z * M, paste0("Z:", mods)))
  ok <- is.finite(y) & is.finite(w) & complete.cases(EX, EN, IV)
  if (!is.null(fe)) ok <- ok & !is.na(dt[[fe]])
  y <- y[ok]; w <- w[ok]; EX <- EX[ok, , drop = FALSE]; EN <- EN[ok, , drop = FALSE]; IV <- IV[ok, , drop = FALSE]
  if (is.null(fe)) EX <- cbind(`(Intercept)` = 1, EX) else {
    g <- dt[[fe]][ok]; y <- drop(demean(y, g, w)); EX <- demean(EX, g, w); EN <- demean(EN, g, w); IV <- demean(IV, g, w)
  }
  f <- tsls(y, EX, EN, IV, w); b <- f$b
  out <- c(fs = unname(f$fs["Z", "D"]), tau = unname(b["D"]), gamma = unname(b["D"] - 12 * b["r"]))
  for (m in mods) { out[paste0("tau:", m)] <- b[paste0("D:", m)]; out[paste0("gamma:", m)] <- b[paste0("D:", m)] - 12 * b[paste0("r:", m)]
    out[paste0("main:", m)] <- b[m]; out[paste0("age:", m)] <- -12 * b[paste0("r:", m)] }
  c(out, n = sum(ok))
}

# Instrumental-variable quantile regression for one quantile q (inverse quantile regression): the grade coefficient alpha is the value
# at which the instrument Z has a zero coefficient in a weighted quantile regression of (y - alpha D) on birth month r and Z.
# That coefficient falls as alpha rises when Z raises D, so the root is found by bisection to within `tol` points. Returns
# tau (alpha: the gain at that quantile, birth month fixed) and gamma (alpha - 12 x the coefficient on r: the yearly gain).
# NA when the bracket [lo, hi] does not contain a sign change. Rows must be complete.
# `extra`: further covariates (a matrix) held fixed in the quantile regression; the quantile is then conditional on them.
ivqr <- function(y, D, Z, r, w, q, lo = -200, hi = 300, tol = 0.5, extra = NULL) {
  X <- cbind(1, r, Z, extra)
  cf <- function(a) quantreg::rq.wfit(X, y - a * D, tau = q, weights = w, method = "fn")$coefficients
  if (!(cf(lo)[3] > 0 && cf(hi)[3] < 0)) return(c(tau = NA_real_, gamma = NA_real_))
  while (hi - lo > tol) { mid <- (lo + hi) / 2; if (cf(mid)[3] > 0) lo <- mid else hi <- mid }
  a <- (lo + hi) / 2; c(tau = a, gamma = a - 12 * unname(cf(a)[2]))
}

# Fay balanced repeated replication (80 replicates, k = 0.5, so variance = sum of squared deviations / 20) on the first plausible value,
# plus the between-plausible-value variance times (1 + 1/10) (Rubin). statfun(dt, y, w) returns a named vector; ys are outcome columns
# (ten plausible values, or one column for a statistic without plausible values).
pisa_est <- function(dt, statfun, ys) {
  th <- vapply(ys, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT), statfun(dt, dt[[ys[1]]], dt$W_FSTUWT))
  if (is.null(dim(th))) th <- matrix(th, nrow = 1, dimnames = list(names(statfun(dt, dt[[ys[1]]], dt$W_FSTUWT)), ys))
  est <- rowMeans(th); v_imp <- if (length(ys) > 1) (1 + 1 / length(ys)) * apply(th, 1, var) else 0
  rep <- vapply(RW, function(rw) statfun(dt, dt[[ys[1]]], dt[[rw]]), th[, 1])
  if (is.null(dim(rep))) rep <- matrix(rep, nrow = 1)
  data.table(term = rownames(th), est = est, se = sqrt(rowSums((rep - th[, 1])^2) / 20 + v_imp))
}

# The same estimator with the full covariance matrix of the statistics, for ratios and sums of quantities estimated together.
pisa_cov <- function(dt, statfun, ys) {
  th <- vapply(ys, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT), statfun(dt, dt[[ys[1]]], dt$W_FSTUWT))
  rep <- vapply(RW, function(rw) statfun(dt, dt[[ys[1]]], dt[[rw]]), th[, 1]) - th[, 1]
  list(est = rowMeans(th), V = tcrossprod(rep) / 20 + if (length(ys) > 1) (1 + 1 / length(ys)) * cov(t(th)) else 0)
}

# Across systems: DerSimonian-Laird random effects. Significance is counted at both p < 0.05 and p < 0.10 (two-sided, normal).
pool <- function(est, se) {
  ok <- is.finite(est) & is.finite(se) & se > 0; y <- est[ok]; v <- se[ok]^2; S <- length(y); z <- y / sqrt(v)
  w <- 1 / v; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- if (S > 1 && C > 0) max(0, (Q - (S - 1)) / C) else 0; wr <- 1 / (v + t2); re <- sum(wr * y) / sum(wr)
  data.table(n_sys = S, median = median(y), re_mean = re, re_se = sqrt(1 / sum(wr)), tau_sd = sqrt(t2),
             I2 = if (Q > 0) max(0, (Q - (S - 1)) / Q) * 100 else 0,
             pos_05 = sum(z > qnorm(.975)), pos_10 = sum(z > qnorm(.95)), neg_05 = sum(z < -qnorm(.975)), neg_10 = sum(z < -qnorm(.95)))
}

# Between-unit spread of an effect from unit estimates y with standard errors se (used for schools within a system).
# Returns the mean, the DerSimonian-Laird between-unit standard deviation, the homogeneity test, the smallest spread the design could
# detect (one-sided 5% test of homogeneity: Q has variance 2(J - 1) when there is no spread) and a one-sided 95% upper bound on the
# spread from the Q profile (the largest spread the data do not reject).
spread <- function(y, se) {
  ok <- is.finite(y) & is.finite(se) & se > 0; y <- y[ok]; v <- se[ok]^2; J <- length(y)
  w <- 1 / v; mu <- sum(w * y) / sum(w); Q <- sum(w * (y - mu)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- max(0, (Q - (J - 1)) / C)
  qprof <- function(t) { ww <- 1 / (v + t); m <- sum(ww * y) / sum(ww); sum(ww * (y - m)^2) - qchisq(.05, J - 1) }
  hi <- max(100 * max(v), 1e4); upper <- if (qprof(0) < 0) 0 else if (qprof(hi) > 0) NA_real_ else uniroot(qprof, c(0, hi), tol = 1e-8)$root
  data.table(units = J, mean = mu, sd = sqrt(t2), var_raw = (Q - (J - 1)) / C, Q = Q, df = J - 1, p = pchisq(Q, J - 1, lower.tail = FALSE), C = C,
             detectable_sd = sqrt(qnorm(.95) * sqrt(2 * (J - 1)) / C), upper_sd = sqrt(upper), median_se = median(sqrt(v)))
}

# Between-school spread of a within-school contrast, with a permutation reference (steps 10 and 11).
#   s      students of one system (CNTSCHID, r, W_FSTUWT and the outcome columns `ycols`); z their 0/1 group; pi the scaling (first stage)
# Per outcome column: the age slope and the common contrast are estimated within schools; the school contrast is the difference of the
# two group means of (outcome - slope x r), divided by pi, with its sampling variance from the two within-school variances. Q is the
# precision-weighted dispersion of the school contrasts, averaged over the outcome columns. Reference: the common contrast is removed,
# z is shuffled among the students of each school (the same shuffle for every column) and Q recomputed, nperm times.
sch_gains <- function(ys, z, w, sch, pi) {
  sw1 <- rowsum(w * z, sch, reorder = TRUE)[, 1]; sw0 <- rowsum(w * (1 - z), sch)[, 1]
  m1 <- rowsum(w * z * ys, sch)[, 1] / sw1; m0 <- rowsum(w * (1 - z) * ys, sch)[, 1] / sw0
  n1 <- rowsum(z, sch)[, 1]; n0 <- rowsum(1 - z, sch)[, 1]; d <- ys - ifelse(z == 1, m1[sch], m0[sch])
  v1 <- rowsum(w^2 * z * d^2, sch)[, 1] / sw1^2 * n1 / (n1 - 1); v0 <- rowsum(w^2 * (1 - z) * d^2, sch)[, 1] / sw0^2 * n0 / (n0 - 1)
  list(g = (m1 - m0) / pi, v = (v1 + v0) / pi^2) }
sch_q <- function(x) { ok <- is.finite(x$g) & is.finite(x$v) & x$v > 0; w <- 1 / x$v[ok]; mu <- sum(w * x$g[ok]) / sum(w)
  c(Q = sum(w * (x$g[ok] - mu)^2), C = sum(w) - sum(w^2) / sum(w), J = sum(ok), mean = mu, med_se = median(sqrt(x$v[ok]))) }
school_spread <- function(s, z, pi, ycols, nperm) {
  w <- s$W_FSTUWT; g <- s$CNTSCHID; sch <- as.integer(factor(g)); J <- max(sch)
  X <- demean(cbind(Z = z, r = s$r), g, w)
  ys <- lapply(ycols, function(p) { cf <- lm.wfit(X, drop(demean(s[[p]], g, w)), w)$coefficients; if (anyNA(cf)) stop("group and birth month are collinear within schools")
    list(obs = s[[p]] - cf["r"] * s$r, null = s[[p]] - cf["r"] * s$r - cf["Z"] * z) })
  ob <- sapply(ys, function(y) sch_q(sch_gains(y$obs, z, w, sch, pi)))
  perm <- vapply(seq_len(nperm), function(b) { zp <- z[order(sch, runif(length(sch)))][rank(sch, ties.method = "first")]      # shuffle within school
    mean(sapply(ys, function(y) sch_q(sch_gains(y$null, zp, w, sch, pi))["Q"])) }, 0)
  Q <- mean(ob["Q", ]); C <- mean(ob["C", ]); v <- (Q - mean(perm)) / C
  list(sys = data.table(schools = J, mean_gain = mean(ob["mean", ]), median_school_se = mean(ob["med_se", ]), Q = Q, C = C, df = J - 1,
         Q_perm_mean = mean(perm), p_perm = (1 + sum(perm >= Q)) / (1 + nperm), p_chisq = pchisq(Q, J - 1, lower.tail = FALSE), var = v, sd = sqrt(max(0, v)),
         sd_lo = sqrt(max(0, (Q - quantile(perm, .95)) / C)), sd_hi = sqrt(max(0, (Q - quantile(perm, .05)) / C)), detectable_sd = sqrt(qnorm(.95) * sd(perm) / C)),
       perm = perm) }
# several systems together: sums of Q, C and of the permuted Q (permutation by permutation)
spread_overall <- function(d, perms, lab, nperm) { pm <- Reduce(`+`, perms[d$CNT]); Q <- sum(d$Q); C <- sum(d$C); v <- (Q - mean(pm)) / C
  data.table(set = lab, systems = nrow(d), schools = sum(d$schools), Q = Q, Q_perm_mean = mean(pm), df = sum(d$df), p_perm = (1 + sum(pm >= Q)) / (1 + nperm), sd = sqrt(max(0, v)),
             sd_lo = sqrt(max(0, (Q - quantile(pm, .95)) / C)), sd_hi = sqrt(max(0, (Q - quantile(pm, .05)) / C)), detectable_sd = sqrt(qnorm(.95) * sd(pm) / C)) }

