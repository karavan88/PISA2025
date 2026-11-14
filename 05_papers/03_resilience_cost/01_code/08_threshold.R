# The Cost of Resilience -- step 8: threshold model for the life-satisfaction ladder (is the gap LS-specific scale use?)
# Step 3 rules out general response style. What it cannot rule out is that resilient students place the cut-points of THIS item
# differently (a higher bar for a 9 or a 10). PISA 2025 has no anchoring vignettes and no second wellbeing measure, so group-specific
# thresholds are not separately identified from a group difference in latent satisfaction: a model can only show what a reporting
# explanation would have to look like, and test implications that the two readings do not share. Three parts, all on resilient (R)
# vs disadvantaged low achievers (PL), cells re-derived per plausible value and replicate weight, ladder coded <=3, 4, ..., 10:
#   A (per system, BRR + Rubin, RE pooled): ordered probit with one latent shift for R (the model behind a "gap in SD").
#   B (pooled over systems, weights normalised per system, BRR + Rubin; thresholds and covariate effects free in every system):
#     op   one latent shift for R (parallel thresholds)
#     gop  a separate shift at every threshold (group-specific thresholds; equivalent to a full set of R thresholds)
#     hop  gop + every threshold also moves with the four measured scale-use indices (HOPIT-style threshold equation; the indices
#          are content-free, hence excluded from the latent equation) -- same sample as gop "rssample"
#     ls   common thresholds, R differ in latent mean and spread (the "real difference" reading with two parameters)
#     bench  what each reading implies for a resilient student's latent position within an answer category
#   C (per system, RE pooled): external-criterion check. If a resilient 8-10 hides a higher latent satisfaction (reporting), then at
#     the same answer resilient students should stand higher on the relationship scales that go with life satisfaction; if the
#     latent distribution differs (real), they should not. R x answer-category interactions on the relationship composite.
# School effects: weighted school means of every regressor (Mundlak) in the probit models; school fixed effects in the linear part C.
# Output: thr_sys.csv, thr_pool.csv (parts A and C), thr_model.csv (part B and the benchmark for C)
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
CORES <- as.integer(Sys.getenv("THR_CORES", "6"))
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]
# relationship composite: mean of the available scales (bullying reversed), at least two, standardised within system
d[, REL := { M <- cbind(BELONG_z, FAMSUP_z, FEELSAFE_z, -BULLIED_z); m <- rowMeans(M, na.rm = TRUE); m[rowSums(!is.na(M)) < 2] <- NA; zw(m, w) }, by = CNT]
d[, NBULLIED_z := -BULLIED_z]
# every system counts equally in the pooled model (replicate variation is preserved); per-system estimates are unaffected
d[, nf := sum(W_FSTUWT), by = CNT]
for (v in c("W_FSTUWT", RW)) set(d, j = v, value = d[[v]] / d$nf)

DEMO <- c("female", "AGE", "g_m1", "g_p1"); RSZ <- c("ERS_z", "ACQ5_z", "MRS5_z", "ERS5_z")
XCOLS <- c(DEMO, "SEI", paste0("m_", c("top", DEMO, "SEI")))
K <- 7L                                               # thresholds: LS >= 4, ..., LS >= 10
lsc <- function(ls) pmax(as.integer(ls) - 3L, 0L)     # 0 = LS <= 3, 1 = LS 4, ..., 7 = LS 10
KN <- 4:10

# ---------------- likelihood ----------------
# P(y_i >= k) = pnorm( s_i * ( x_i'gamma_c - tau_ck + sum_m T_im Theta_mk ) ),  Theta = matrix(A %*% theta, M, K),  s_i = exp(-S_i'sigma)
# tau (C x K) and gamma (C x P) are system-specific; theta and sigma are common. Without S the index is linear in the parameters and
# the log-likelihood is concave. Newton with the exact sparse Hessian and step halving. Objective: weighted mean log-likelihood.
oprobit <- function(y, ci, X, Tm, A, w, S = NULL, start = NULL, C = max(ci)) {
  n <- length(y); P <- ncol(X); M <- ncol(Tm); nth <- ncol(A); nS <- if (is.null(S)) 0L else ncol(S); nb <- C * K + C * P + nth; np <- nb + nS
  w <- w / sum(w); hasu <- y >= 1L; hasl <- y < K
  i_tau <- seq_len(C * K); i_gam <- C * K + seq_len(C * P); i_th <- C * K + C * P + seq_len(nth); i_sg <- nb + seq_len(nS)
  rows <- function(k) {                               # d (unscaled index at threshold k_i) / d (tau, gamma, theta): one sparse row per student
    ok <- which(k >= 1L & k <= K); kk <- k[ok]; cc <- ci[ok]; TA <- matrix(0, length(ok), nth)
    for (m in seq_len(M)) TA <- TA + Tm[ok, m] * A[(kk - 1L) * M + m, , drop = FALSE]
    Matrix::drop0(Matrix::sparseMatrix(
      i = c(ok, rep(ok, P), rep(ok, nth)),
      j = c((kk - 1L) * C + cc, C * K + rep((seq_len(P) - 1L) * C, each = length(ok)) + rep(cc, P), C * K + C * P + rep(seq_len(nth), each = length(ok))),
      x = c(rep(-1, length(ok)), as.vector(X[ok, , drop = FALSE]), as.vector(TA)), dims = c(n, nb)))
  }
  Da <- rows(y); Db <- rows(y + 1L); act <- c(which(diff(Da@p) + diff(Db@p) > 0), i_sg)      # parameters that enter (absent covariates stay at 0)
  if (C == 1L) { Da <- as.matrix(Da); Db <- as.matrix(Db) }                                   # one system: dense algebra is faster
  # negligible ridge on the nuisance slopes: a regressor and its school mean coincide when its few carriers sit alone in their schools
  pen <- rep(0, np); pen[i_gam] <- 1e-8
  cold <- {                                           # thresholds from each system's marginal distribution, everything else zero
    tau0 <- t(vapply(seq_len(C), function(cc) { k <- ci == cc; qnorm(pmin(pmax(1 - vapply(1:K, function(j) sum(w[k & y >= j]), 0) / sum(w[k]), 1e-3), 1 - 1e-3)) }, numeric(K)))
    for (j in 2:K) tau0[, j] <- pmax(tau0[, j], tau0[, j - 1] + 0.02)
    c(as.vector(tau0), rep(0, C * P + nth + nS))
  }
  if (is.null(start)) start <- cold
  ev <- function(par, deriv = FALSE) {
    s <- if (nS) exp(-as.vector(S %*% par[i_sg])) else rep(1, n)
    a <- s * as.vector(Da %*% par[seq_len(nb)]); b <- s * as.vector(Db %*% par[seq_len(nb)])
    pa <- pnorm(a); pa[!hasu] <- 1; pb <- pnorm(b); pb[!hasl] <- 0; p <- pa - pb
    if (any(p <= 0)) return(list(ll = -Inf))
    ll <- sum(w * log(p)) - 0.5 * sum(pen * par^2); if (!deriv) return(list(ll = ll))
    fa <- hasu * dnorm(a); fb <- hasl * dnorm(b); la <- w * fa / p; lb <- -w * fb / p
    laa <- w * (-a * fa / p - fa^2 / p^2); lbb <- w * (b * fb / p - fb^2 / p^2); lab <- w * fa * fb / p^2
    g <- as.vector(Matrix::crossprod(Da, s * la) + Matrix::crossprod(Db, s * lb))
    Hab <- Matrix::crossprod(Da, (s^2 * lab) * Db)
    H <- Matrix::crossprod(Da, (s^2 * laa) * Da) + Matrix::crossprod(Db, (s^2 * lbb) * Db) + Hab + Matrix::t(Hab)
    if (nS) {                                         # d a / d sigma = -S a: first- and second-order terms of the scale parameters
      g <- c(g, -as.vector(crossprod(S, la * a + lb * b)))
      Hss <- crossprod(S, (laa * a^2 + lbb * b^2 + 2 * lab * a * b + la * a + lb * b) * S)
      Hsb <- -(Matrix::crossprod(S * (s * (laa * a + lab * b + la)), Da) + Matrix::crossprod(S * (s * (lbb * b + lab * a + lb)), Db))
      H <- rbind(cbind(H, Matrix::t(Hsb)), cbind(Hsb, Matrix::Matrix(Hss, sparse = TRUE)))
    }
    list(ll = ll, g = g - pen * par, H = H - Matrix::Diagonal(x = pen))
  }
  par <- start; v <- ev(par, TRUE); it <- 0L; ok <- FALSE
  if (!is.finite(v$ll)) { par <- cold; v <- ev(par, TRUE) }      # a warm start can be infeasible for another replicate's sample
  repeat {
    gmax <- max(abs(v$g[act])); if (gmax < 1e-9) { ok <- TRUE; break }; if (it >= 200L) break
    mu <- 0; nH <- Matrix::forceSymmetric(-v$H[act, act]); step <- rep(0, np)
    repeat {                                          # the Hessian is negative definite when the index is linear; ridge only if a scale step is not an ascent direction
      st <- tryCatch(as.vector(Matrix::solve(if (mu > 0) nH + Matrix::Diagonal(length(act), mu) else nH, v$g[act])), error = function(e) NULL)
      if (!is.null(st) && sum(v$g[act] * st) > 0) break
      mu <- max(10 * mu, 1e-6); if (mu > 1e3) stop("no ascent direction")
    }
    step[act] <- st; t <- 1; slope <- sum(v$g * step)
    if (slope < 2e-13) { ok <- TRUE; break }          # expected gain below the precision of the objective
    repeat { vn <- ev(par + t * step); if (is.finite(vn$ll) && vn$ll >= v$ll + 1e-4 * t * slope) break; t <- t / 2; if (t < 1e-10) break }
    if (t < 1e-10) break
    par <- par + t * step; v <- ev(par, TRUE); it <- it + 1L
  }
  Tau <- matrix(par[i_tau], C, K); Th <- matrix(A %*% par[i_th], M, K); s <- if (nS) exp(-as.vector(S %*% par[i_sg])) else rep(1, n)
  U <- (rowSums(X * matrix(par[i_gam], C, P)[ci, , drop = FALSE]) - Tau[ci, , drop = FALSE] + Tm %*% Th) * s
  list(par = par, ll = v$ll + 0.5 * sum(pen * par^2), tau = Tau, theta = par[i_th], sigma = par[i_sg], U = U, conv = as.integer(!ok), gmax = gmax, iter = it)
}

# ---------------- design ----------------
# contrast sample and regressors for the systems in s, with the achievement composite y and weight w in use
build <- function(s, y, w, rs = FALSE) {
  sys <- unique(s$CNT); parts <- vector("list", length(sys)); idx <- split(seq_len(nrow(s)), s$CNT)
  for (c1 in seq_along(sys)) {
    i <- idx[[sys[c1]]]; q <- wquant(y[i], w[i], c(.25, .75))
    top <- as.integer(y[i] >= q[2]); cell <- s$sesq[i] == 1 & (top == 1 | y[i] <= q[1])
    ctrl <- c(avail(s[i, ..DEMO], DEMO), "SEI"); need <- c("LS", "CNTSCHID", ctrl, if (rs) RSZ)
    j <- which(cell & complete.cases(s[i, ..need]) & w[i] > 0); r <- i[j]; ww <- w[r]; tp <- top[j]
    R <- cbind(top = tp, as.matrix(s[r, ..ctrl])); g <- s$CNTSCHID[r]
    mu <- rowsum(R * ww, g) / as.vector(rowsum(ww, g)); B <- mu[match(g, rownames(mu)), , drop = FALSE]; colnames(B) <- paste0("m_", colnames(R))
    Z <- cbind(R[, -1, drop = FALSE], B); X <- matrix(0, length(r), length(XCOLS), dimnames = list(NULL, XCOLS))
    for (v in colnames(Z)) { m <- wmean(Z[, v], ww); sdv <- wsd(Z[, v], ww); if (is.finite(sdv) && sdv > 1e-8) X[, v] <- (Z[, v] - m) / sdv }   # centred and scaled within system: nuisance effects only
    parts[[c1]] <- list(r = r, ci = rep(c1, length(r)), y = lsc(s$LS[r]), top = tp, X = X, w = ww)
  }
  o <- list(r = unlist(lapply(parts, `[[`, "r")), ci = unlist(lapply(parts, `[[`, "ci")), y = unlist(lapply(parts, `[[`, "y")),
            top = unlist(lapply(parts, `[[`, "top")), X = do.call(rbind, lapply(parts, `[[`, "X")), w = unlist(lapply(parts, `[[`, "w")), C = length(sys))
  if (rs) o$Z <- as.matrix(s[o$r, ..RSZ])
  o
}
no_sei <- function(X) { X[, c("SEI", "m_SEI")] <- 0; X }
tmean <- function(m, sd, a, b) { al <- (a - m) / sd; be <- (b - m) / sd; pr <- pnorm(be) - pnorm(al); list(mean = m + sd * (dnorm(al) - dnorm(be)) / pr, p = pr) }

# ---------------- part A and C: per system ----------------
stat_sys <- function(s, y, w) {
  D <- build(s, y, w); out <- c(); Tt <- cbind(top = D$top); A1 <- matrix(1, K, 1)
  f <- oprobit(D$y, D$ci, no_sei(D$X), Tt, A1, D$w); out["op:demo"] <- if (f$conv == 0) f$theta else NA_real_
  f <- oprobit(D$y, D$ci, D$X, Tt, A1, D$w);         out["op:sei"]  <- if (f$conv == 0) f$theta else NA_real_
  # part C: relationship composite on answer category, R, and R x upper categories; school fixed effects
  ss <- s[D$r]; g <- ss$CNTSCHID; ctrl <- avail(s[, ..DEMO], DEMO); ctrl <- ctrl[vapply(ctrl, function(v) var(ss[[v]]) > 0, logical(1))]
  cat <- vapply(1:K, function(k) as.numeric(D$y == k), numeric(length(D$y))); colnames(cat) <- paste0("c", KN)
  top <- D$top; Cm <- as.matrix(ss[, ..ctrl])
  reg <- function(yv, X, coefs) tryCatch(unname(fwls(yv, X, D$w, g)[coefs]), error = function(e) rep(NA_real_, length(coefs)))
  jump <- cbind(x8 = top * cat[, "c8"], x9 = top * cat[, "c9"], x10 = top * cat[, "c10"]); up <- cbind(x8plus = top * (D$y >= 5L))
  out[paste0("crit:sei:", c("top", "x8", "x9", "x10", colnames(cat)))] <- reg(ss$REL, cbind(top = top, cat, jump, Cm, SEI = ss$SEI), c("top", "x8", "x9", "x10", colnames(cat)))
  out["crit:sei:x8plus"]  <- reg(ss$REL, cbind(top = top, cat, up, Cm, SEI = ss$SEI), "x8plus")
  out["crit:demo:x8plus"] <- reg(ss$REL, cbind(top = top, cat, up, Cm), "x8plus")
  # the whole profile (R x every category, reference LS <= 3), and the excess at 8-10 over what the lower categories predict: the
  # composite may simply be tied more closely to life satisfaction among resilient students (a slope difference along the whole
  # ladder, which says nothing about thresholds). Latent position of a category = normal score from the low achievers' distribution.
  shp <- vapply(0:K, function(k) sum(D$w[D$top == 0 & D$y == k]), 0); shp <- pmax(shp / sum(shp), 1e-6); tq <- qnorm(cumsum(shp / sum(shp))[1:K])
  mlat <- tmean(0, 1, c(-Inf, tq), c(tq, Inf))$mean[D$y + 1L]; sat <- top * cat; colnames(sat) <- paste0("x", KN)
  out[paste0("crit:sat:x", KN)] <- reg(ss$REL, cbind(top = top, cat, sat, Cm, SEI = ss$SEI), paste0("x", KN))
  out[paste0("crit:xs:", c("topXlat", "x8", "x9", "x10"))] <- reg(ss$REL, cbind(top = top, cat, topXlat = top * mlat, jump, Cm, SEI = ss$SEI), c("topXlat", "x8", "x9", "x10"))
  for (v in c("BELONG_z", "FAMSUP_z", "FEELSAFE_z", "NBULLIED_z"))
    out[paste0("crit:sei:x8plus:", v)] <- if (mean(!is.na(ss[[v]])) > 0.5) reg(ss[[v]], cbind(top = top, cat, up, Cm, SEI = ss$SEI), "x8plus") else NA_real_
  out["n:R"] <- sum(D$top == 1); out["n:PL"] <- sum(D$top == 0); out["n:R10"] <- sum(D$top == 1 & D$y == K)
  out
}

# ---------------- part B: pooled ----------------
WS <- new.env()                                        # warm starts: the full-sample first-plausible-value solution of each model
fit <- function(key, ...) {
  f <- oprobit(..., start = WS[[key]])
  if (f$conv != 0) stop("no convergence: ", key)
  if (!isTRUE(WS$frozen)) assign(key, f$par, envir = WS)
  f
}
shifts <- function(b, lab) { v <- c(b, mean(b[1:4]), mean(b[6:7]), mean(b[6:7]) - mean(b[1:4])); names(v) <- paste0(lab, c(paste0("b", KN), "low", "hi", "hi_minus_low")); v }
stat_pool <- function(s, y, w) {
  D <- build(s, y, w); Tt <- cbind(top = D$top); A1 <- matrix(1, K, 1); AK <- diag(K); out <- c()
  f1d <- fit("op_demo", D$y, D$ci, no_sei(D$X), Tt, A1, D$w, C = D$C); out["op:demo:top"] <- f1d$theta
  f2d <- fit("gop_demo", D$y, D$ci, no_sei(D$X), Tt, AK, D$w, C = D$C); out <- c(out, shifts(f2d$theta, "gop:demo:"))
  f1 <- fit("op_sei", D$y, D$ci, D$X, Tt, A1, D$w, C = D$C); out["op:sei:top"] <- f1$theta
  f2 <- fit("gop_sei", D$y, D$ci, D$X, Tt, AK, D$w, C = D$C); out <- c(out, shifts(f2$theta, "gop:sei:"))
  # gap in P(LS >= k) implied by the group-specific thresholds, averaged over resilient students (comparable with step 3, thr:*)
  isR <- D$top == 1; wr <- D$w[isR] / sum(D$w[isR])
  out[paste0("gop:sei:ape", KN)] <- vapply(1:K, function(k) sum(wr * (pnorm(f2$U[isR, k]) - pnorm(f2$U[isR, k] - f2$theta[k]))), 0)
  f5 <- fit("ls_sei", D$y, D$ci, D$X, Tt, A1, D$w, S = Tt, C = D$C); out[c("ls:sei:mu", "ls:sei:lnsd")] <- c(f5$theta, f5$sigma)
  out[c("fit:ll_op", "fit:ll_gop", "fit:ll_ls")] <- c(f1$ll, f2$ll, f5$ll); out["fit:ls_share"] <- (f5$ll - f1$ll) / (f2$ll - f1$ll)
  # benchmark for part C: latent position (conditional on covariates, in latent SD) of R minus PL within an answer category, by reading.
  #   shift: same latent distribution, R thresholds moved as estimated (gop).   real: common thresholds, R latent N(mu, sd) (ls).
  lo <- 1:5; bench <- function(dR, pR) c(x8 = dR[6], x9 = dR[7], x10 = dR[8], x8plus = sum(pR[6:8] * dR[6:8]) / sum(pR[6:8])) - sum(pR[lo] * dR[lo]) / sum(pR[lo])
  bs <- br <- matrix(NA_real_, D$C, 4); pm <- pp <- ds <- dr <- matrix(NA_real_, D$C, K + 1L)
  for (cc in seq_len(D$C)) {
    t2 <- f2$tau[cc, ]; a <- tmean(0, 1, c(-Inf, t2), c(t2, Inf)); b <- tmean(0, 1, c(-Inf, t2 - f2$theta), c(t2 - f2$theta, Inf))
    bs[cc, ] <- bench(b$mean - a$mean, b$p); pm[cc, ] <- a$mean; pp[cc, ] <- a$p; ds[cc, ] <- b$mean - a$mean
    t5 <- f5$tau[cc, ]; a5 <- tmean(0, 1, c(-Inf, t5), c(t5, Inf)); b5 <- tmean(f5$theta, exp(f5$sigma), c(-Inf, t5), c(t5, Inf))
    br[cc, ] <- bench(b5$mean - a5$mean, b5$p); dr[cc, ] <- b5$mean - a5$mean
  }
  nm <- c("x8", "x9", "x10", "x8plus")
  out[paste0("bench:shift:", nm)] <- colMeans(bs); out[paste0("bench:real:", nm)] <- colMeans(br)
  out[paste0("bench:shift:d", c(3, KN))] <- colMeans(ds); out[paste0("bench:real:d", c(3, KN))] <- colMeans(dr)
  out[paste0("bench:PLmean:c", c(3, KN))] <- colMeans(pm); out[paste0("bench:PLshare:c", c(3, KN))] <- colMeans(pp)
  out[paste0("tau:", KN)] <- colMeans(f2$tau)
  # measured scale use in the thresholds (same sample with and without)
  Dz <- build(s, y, w, rs = TRUE); Tz <- cbind(top = Dz$top, Dz$Z); M <- ncol(Tz)
  Ag <- matrix(0, M * K, K); Ag[cbind((seq_len(K) - 1L) * M + 1L, seq_len(K))] <- 1          # top free at every threshold, indices excluded
  f3 <- fit("gop_rs", Dz$y, Dz$ci, Dz$X, Tz, Ag, Dz$w, C = Dz$C); out <- c(out, shifts(f3$theta, "gop:sei_rssample:"))
  f4 <- fit("hop_rs", Dz$y, Dz$ci, Dz$X, Tz, diag(M * K), Dz$w, C = Dz$C); Th <- matrix(f4$theta, M, K)
  out <- c(out, shifts(Th[1, ], "hop:sei:"))
  for (m in 2:M) out[paste0("hop:sei:", RSZ[m - 1], ":t", KN)] <- Th[m, ]
  out[c("fit:ll_gop_rs", "fit:ll_hop_rs")] <- c(f3$ll, f4$ll)
  out[c("n:R", "n:PL", "n:sys", "n:R_rs", "n:PL_rs")] <- c(sum(D$top == 1), sum(D$top == 0), D$C, sum(Dz$top == 1), sum(Dz$top == 0))
  out["chk:gmax"] <- max(f1d$gmax, f2d$gmax, f1$gmax, f2$gmax, f5$gmax, f3$gmax, f4$gmax)
  out
}
# pisa_est with the plausible values and replicate weights run in parallel (same Fay BRR + Rubin formulas as the shared helper)
pisa_est_par <- function(dt, statfun, ys, cores) {
  first <- statfun(dt, dt[[ys[1]]], dt$W_FSTUWT); WS$frozen <- TRUE          # every other fit starts from this solution
  jobs <- c(lapply(ys[-1], function(p) c(p, "W_FSTUWT")), lapply(RW, function(r) c(ys[1], r)))
  res <- parallel::mclapply(jobs, function(j) statfun(dt, dt[[j[1]]], dt[[j[2]]]), mc.cores = cores, mc.preschedule = FALSE)
  bad <- !vapply(res, is.numeric, logical(1)); if (any(bad)) stop("pooled fit failed for: ", paste(vapply(jobs[bad], paste, "", collapse = "/"), collapse = " "), "\n", res[bad][[1]])
  th_pv <- cbind(first, do.call(cbind, res[seq_along(ys[-1])])); th_r <- do.call(cbind, res[-seq_along(ys[-1])])
  est <- rowMeans(th_pv); v_imp <- (1 + 1 / length(ys)) * apply(th_pv, 1, var); v_samp <- rowSums((th_r - th_pv[, 1])^2) / 20
  data.table(term = names(est), est = est, se = sqrt(v_samp + v_imp))
}

if (!nzchar(Sys.getenv("THR_NO_RUN"))) {
  # systems: school identifiers and at least MIN_CELL students in each cell (mean over plausible values), as in steps 3-5
  cells <- rbindlist(lapply(ACH, function(p) d[, { q <- wquant(get(p), W_FSTUWT, c(.25, .75)); .(R = sum(sesq == 1 & get(p) >= q[2]), PL = sum(sesq == 1 & get(p) <= q[1])) }, by = CNT]))[, .(R = mean(R), PL = mean(PL)), by = CNT]
  SYS <- sort(intersect(cells[R >= MIN_CELL & PL >= MIN_CELL, CNT], d[!is.na(CNTSCHID), unique(CNT)]))
  if (nzchar(Sys.getenv("THR_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("THR_SYSTEMS"), " ")[[1]])     # testing only
  d <- d[CNT %in% SYS]; setkey(d, CNT)
  log_step("threshold model on", length(SYS), "systems; part A/C per system")
  res <- run_systems(d, stat_sys, SYS, cores = CORES)
  if (uniqueN(res$CNT) != length(SYS)) stop("per-system part failed for: ", paste(setdiff(SYS, res$CNT), collapse = " "))
  fwrite(res, orr("thr_sys.csv"))
  pl <- pool_by(res[!grepl("^n:", term)], "term"); fwrite(pl, orr("thr_pool.csv"))
  print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), I2 = round(I2), n_neg, sig_pos, sig_neg)], nrows = 100)
  log_step("part B pooled")
  pm <- pisa_est_par(d, stat_pool, ACH, CORES)
  # part C benchmark in units of the relationship composite: slope of the composite on the latent position across answer categories
  # of disadvantaged low achievers, times the within-category latent difference each reading implies (point values, no SE)
  g <- function(tm) pm[match(tm, term), est]; cn <- paste0("c", KN)
  cm <- c(0, pl[match(paste0("crit:sei:", cn), term), re_mean]); lm_ <- g(paste0("bench:PLmean:c", c(3, KN))); sh <- g(paste0("bench:PLshare:c", c(3, KN)))
  bW <- unname(coef(lm(cm ~ lm_, weights = sh))[2]); nm <- c("x8", "x9", "x10", "x8plus")
  pr <- c("pred:bW" = bW); lo <- 1:5
  for (h in c("shift", "real")) {
    dk <- g(paste0("bench:", h, ":d", c(3, KN))); ln <- coef(lm(dk[lo] ~ lm_[lo], weights = sh[lo]))      # what the lower categories predict for 8-10
    pr[paste0("pred:", h, ":", nm)] <- bW * g(paste0("bench:", h, ":", nm))
    pr[paste0("pred:", h, ":sat:x", KN)] <- bW * (dk[-1] - dk[1])
    pr[paste0("pred:", h, ":xs:", c("topXlat", "x8", "x9", "x10"))] <- bW * c(ln[2], dk[6:8] - (ln[1] + ln[2] * lm_[6:8]))
  }
  pm <- rbind(pm, data.table(term = names(pr), est = unname(pr), se = NA_real_))
  pm[, t := est / se]
  fwrite(pm, orr("thr_model.csv"))
  print(pm, digits = 3, nrows = 200)
  log_step("done:", length(SYS), "systems")
}
