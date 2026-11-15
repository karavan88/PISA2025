# The Cost of Resilience -- step 14: does an exogenous push forward in school cost disadvantaged students more? (school-entry cutoff)
# The cross-sectional difference between the gaps of disadvantaged and advantaged students (step 4, did:*) cannot rule out that selection
# into high achievement differs by family background. In 20 systems a school-entry cutoff places otherwise similar students one grade
# higher at the time of the test. The actual grade D is instrumented by the theoretical grade Z implied by the cutoff and the birth
# month, with the running variable r linear (Avvisati and Givord 2021). gamma = b_D - 12 b_r is the effect of one extra grade at a
# given age; gamma:lowSES is its difference for students in the bottom status quartile. BRR + Rubin per system, random-effects pooling.
# A grade also changes curriculum, peers and sometimes the school: gamma is the effect of school progression, not of achievement.
# Estimated inside this paper since 15 November 2026 so that the paper does not depend on another paper's results. tsls_m(), est_sys()
# and pool_iv() are copies of the functions of the legacy grade-gain design; the analytic file is the legacy grade-gain build.
#   base    LS_z, LS10 and achievement on the sample with status observed
#   lowses  the same with the interaction of the grade with the bottom status quartile
# Output: cutoff_sys.csv, cutoff_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
tsls_m <- function(y, D, Z, r, M, X, w) {             # 2SLS with moderators; returns the first stage, gamma, and gamma:<moderator>
  M <- as.matrix(M); k <- ncol(M)
  DM <- if (k) D * M else NULL; ZM <- if (k) Z * M else NULL; rM <- if (k) r * M else NULL
  if (k) { colnames(DM) <- paste0("D:", colnames(M)); colnames(ZM) <- paste0("Z:", colnames(M)); colnames(rM) <- paste0("r:", colnames(M)) }
  EX <- cbind(X, r = r, rM, M); EN <- cbind(D = D, DM); IN <- cbind(EX, Z = Z, ZM)
  ok <- !is.na(y) & !is.na(w) & complete.cases(IN) & complete.cases(EN)
  IN <- IN[ok, , drop = FALSE]; EN <- EN[ok, , drop = FALSE]; EX <- EX[ok, , drop = FALSE]; yy <- y[ok]; ww <- w[ok]
  fs <- as.matrix(lm.wfit(IN, EN, ww)$coefficients); fs[is.na(fs)] <- 0
  Ehat <- IN %*% fs; colnames(Ehat) <- colnames(EN)
  b2 <- lm.wfit(cbind(EX, Ehat), yy, ww)$coefficients
  out <- c(fs = unname(as.matrix(fs)["Z", 1]), gamma = unname(b2["D"] - 12 * b2["r"]), tau = unname(b2["D"]))
  if (k) for (m in colnames(M)) out[paste0("gamma:", m)] <- unname(b2[paste0("D:", m)] - 12 * b2[paste0("r:", m)])
  out
}
est_sys <- function(s, outcome, mods = character(0), ctrl = c("female", "immigrant")) {
  ys <- if (paste0("PV1", outcome) %in% names(s)) PV(outcome) else outcome
  stopifnot(all(ys %in% names(s)))
  ctrl <- ctrl[vapply(ctrl, function(v) mean(!is.na(s[[v]])) > 0.5, logical(1))]
  X <- matrix(1, nrow(s), 1, dimnames = list(NULL, "(Intercept)")); if (length(ctrl)) X <- cbind(X, as.matrix(s[, ..ctrl]))
  M <- if (length(mods)) as.matrix(s[, ..mods]) else matrix(numeric(0), nrow(s), 0)
  e <- pisa_est(s, function(dt, y, w) tsls_m(y, dt$D, dt$Z, dt$r, M, X, w), ys)
  e[, n := sum(complete.cases(cbind(s[[ys[1]]], M, X)))]; e
}
pool_iv <- function(est, se) {                        # same columns as the pooled files of the cutoff design
  ok <- !is.na(est) & !is.na(se) & se > 0; y <- est[ok]; s2 <- se[ok]^2; S <- length(y)
  w <- 1 / s2; fe <- sum(w * y) / sum(w); Q <- sum(w * (y - fe)^2); C <- sum(w) - sum(w^2) / sum(w)
  t2 <- if (S > 1 && C > 0) max(0, (Q - (S - 1)) / C) else 0; wr <- 1 / (s2 + t2); re <- sum(wr * y) / sum(wr)
  data.table(n_sys = S, mean = mean(y), mean_se = sqrt(sum(s2)) / S, median = median(y), re_mean = re, re_se = sqrt(1 / sum(wr)),
             tau_sd = sqrt(t2), I2 = if (Q > 0) max(0, (Q - (S - 1)) / Q) * 100 else 0, Q_p = pchisq(Q, S - 1, lower.tail = FALSE),
             sig_pos = sum(y / sqrt(s2) > 1.96), sig_neg = sum(y / sqrt(s2) < -1.96))
}
a <- readRDS(file.path(DERIVED, "skillsgain_analytic.rds"))[!CNT %in% EXCLUDE]
a <- merge(a, fread(STUDENTS, select = c("CNTSTUID", "ST016Q01NA")), by = "CNTSTUID", all.x = TRUE, sort = FALSE)[!is.na(ST016Q01NA)]
a[, `:=`(LS = ST016Q01NA, LS10 = as.integer(ST016Q01NA == 10), lowSES = as.integer(SES_q == 1))][, LS_z := zw(LS, W_FSTUWT), by = CNT]
SPECS <- list(base = character(0), lowses = "lowSES"); OUTS <- c("LS_z", "LS10", "ACH")
log_step("cutoff design on", uniqueN(a$CNT), "systems,", nrow(a), "students with life satisfaction")
one_system <- function(cn) { s0 <- a[CNT == cn]; res <- list()
  for (sp in names(SPECS)) { m <- SPECS[[sp]]; s <- if (length(m)) s0[complete.cases(s0[, ..m])] else s0[!is.na(SES)]   # base on the status sample, so that base and lowses compare
    if (nrow(s) < 500) next
    for (o in OUTS) res[[length(res) + 1]] <- tryCatch(data.table(CNT = cn, spec = sp, outcome = o, est_sys(s, o, mods = m)), error = function(e) { message(cn, " ", sp, " ", o, ": ", conditionMessage(e)); NULL }) }
  rbindlist(res, fill = TRUE) }
res <- rbindlist(parallel::mclapply(unique(a$CNT), one_system, mc.cores = 6), fill = TRUE)
fwrite(res, orr("cutoff_sys.csv"))
pl <- res[, pool_iv(est, se), by = .(spec, outcome, term)][, set := paste("all", uniqueN(res$CNT))]
fwrite(pl, orr("cutoff_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[term != "tau", .(spec, outcome, term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 2), I2 = round(I2), sig_pos, sig_neg)])
