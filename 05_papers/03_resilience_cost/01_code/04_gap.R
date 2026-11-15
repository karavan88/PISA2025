# The Cost of Resilience -- step 4: the gap, its decomposition, and whether it is specific to disadvantaged high achievers
# Per system (BRR + Rubin; resilience re-derived per PV and replicate):
#   ladder:  resilient (R) vs disadvantaged low achievers (PL), within school:
#            demo -> + skill index -> + six skills -> + skill index + relationships (belonging, bullying, family support, safety)
#            alt. comparison group: R vs all other bottom-quartile-ESCS students
#   q4:      the same high-vs-low-achiever contrast among advantaged students (AT vs AL), demo + skill index
#   did:     difference in the two achiever gaps from one model on Q1+Q4 (top x Q1), school FE, demo + skill index
#   cont:    continuous version on everyone: LS ~ ach*ESCS + skill index + demo | school  (achievement and ESCS in system SD)
#   gelbach: decomposition of (gap demo) - (gap full) into the skill index and each relationship scale (Gelbach 2016)
# Output: 05_papers/03_resilience_cost/04_output/gap_sys.csv, gap_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]
SEZ <- paste0(SE6, "_z"); CTZ <- paste0(CTX, "_z")

stat_gap <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75))
  top <- as.integer(y >= q[2]); low <- as.integer(y <= q[1])
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1"))
  sez <- avail(s, SEZ); ctz <- avail(s, CTZ)
  out <- c()
  reg <- function(keep, yv, X, g = s$CNTSCHID, coefs = "top") tryCatch({
    keep <- keep & !is.na(keep); X <- as.matrix(X)[keep, , drop = FALSE]
    X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    b <- fwls(yv[keep], X, w[keep], if (is.null(g)) NULL else g[keep]); unname(b[coefs]) }, error = function(e) rep(NA_real_, length(coefs)))
  C <- as.matrix(s[, ..ctrl])
  q1 <- s$sesq == 1 & (top == 1 | low == 1); q4 <- s$sesq == 4 & (top == 1 | low == 1)
  full_cc <- complete.cases(s[, c("SEI", ctz), with = FALSE])                # common sample for the ladder (relationships available)
  # ladder (common sample so that steps are comparable)
  out["lad:demo"]   <- reg(q1 & full_cc, s$LS_z, cbind(top = top, C))
  out["lad:sei"]    <- reg(q1 & full_cc, s$LS_z, cbind(top = top, C, SEI = s$SEI))
  out["lad:se6"]    <- reg(q1 & full_cc, s$LS_z, cbind(top = top, C, as.matrix(s[, ..sez])))
  out["lad:full"]   <- reg(q1 & full_cc, s$LS_z, cbind(top = top, C, SEI = s$SEI, as.matrix(s[, ..ctz])))
  out["lad:nofe_demo"] <- reg(q1 & full_cc, s$LS_z, cbind(top = top, C), g = NULL)
  # growth mindset (binary; not fielded in every system) held fixed next to the skill index, and the same sample without it
  gm <- q1 & full_cc & !is.na(s$growth)
  out["lad:sei_growth"]  <- if (sum(gm) > 0) reg(gm, s$LS_z, cbind(top = top, C, SEI = s$SEI, growth = s$growth)) else NA
  out["lad:sei_gsample"] <- if (sum(gm) > 0) reg(gm, s$LS_z, cbind(top = top, C, SEI = s$SEI)) else NA
  out["gro:contrib"]     <- if (sum(gm) > 0) reg(gm, s$growth, cbind(top = top, C, SEI = s$SEI)) * reg(gm, s$LS_z, cbind(top = top, C, SEI = s$SEI, growth = s$growth), coefs = "growth") else NA
  out["lad:full_points"] <- reg(q1 & full_cc, s$LS, cbind(top = top, C, SEI = s$SEI, as.matrix(s[, ..ctz])))
  # alternative comparison: resilient vs every other bottom-quartile student
  out["alt:sei"] <- reg(s$sesq == 1, s$LS_z, cbind(top = top, C, SEI = s$SEI))
  # Gelbach decomposition on the ladder sample: gap(demo) - gap(full) = sum_k Gamma_k * beta_k
  kk <- c("SEI", ctz); Xf <- cbind(top = top, C, as.matrix(s[, ..kk]))
  bfull <- reg(q1 & full_cc, s$LS_z, Xf, coefs = kk)
  for (j in seq_along(kk)) out[paste0("gel:", kk[j])] <- reg(q1 & full_cc, s[[kk[j]]], cbind(top = top, C)) * bfull[j]
  # advantaged high vs low achievers, and the difference in gaps
  out["q4:demo"] <- reg(q4, s$LS_z, cbind(top = top, C))
  out["q4:sei"]  <- reg(q4, s$LS_z, cbind(top = top, C, SEI = s$SEI))
  out["q1:demo_q1q4"] <- reg(q1, s$LS_z, cbind(top = top, C))
  out["q1:sei_q1q4"]  <- reg(q1, s$LS_z, cbind(top = top, C, SEI = s$SEI))
  Q1 <- as.integer(s$sesq == 1)
  out["did:demo"] <- reg(q1 | q4, s$LS_z, cbind(top = top, topQ1 = top * Q1, Q1 = Q1, C), coefs = "topQ1")
  out["did:sei"]  <- reg(q1 | q4, s$LS_z, cbind(top = top, topQ1 = top * Q1, Q1 = Q1, C, SEI = s$SEI, SEIQ1 = s$SEI * Q1), coefs = "topQ1")
  # continuous: achievement x ESCS on the whole sample
  az <- (y - wmean(y, w)) / wsd(y, w)
  bc <- reg(rep(TRUE, nrow(s)), s$LS_z, cbind(ach = az, ESCS_z = s$ESCS_z, achXses = az * s$ESCS_z, C, SEI = s$SEI), coefs = c("ach", "ESCS_z", "achXses", "SEI"))
  out[c("cont:ach", "cont:ESCS", "cont:achXses", "cont:SEI")] <- bc
  out["n:R"] <- sum(q1 & top == 1, na.rm = TRUE); out["n:PL"] <- sum(q1 & low == 1, na.rm = TRUE)
  out
}

log_step("gap models on", uniqueN(d$CNT), "systems")
res <- run_systems(d, stat_gap)
small <- res[term %in% c("n:R", "n:PL") & est < MIN_CELL, unique(CNT)]
log_step("systems below", MIN_CELL, "students in a cell:", paste(small, collapse = " "))
res <- res[!CNT %in% small]
fwrite(res, orr("gap_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("gap_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_pos, sig_neg, I2 = round(I2))])
