# The Cost of Resilience -- step 12: a second benchmark. Resilient students (R) against advantaged top achievers (AT), the group with
# the highest mean life satisfaction. Steps 3-9 compare R with disadvantaged low achievers (PL): same status, different achievement.
# This step holds achievement fixed and lets status differ. It complements the main comparison and does not replace it: the difference
# between R and AT includes the general association of family status with life satisfaction.
# Per system (BRR + Rubin; groups re-derived per PV and replicate), then random-effects pooling:
#   pair:AT:*   R vs AT on top achievers of the bottom and top status quartiles; coefficient of the bottom-quartile indicator
#               demo / sei (skill index held fixed) / nofe_demo / nofe_sei (no school fixed effects) / sei_points (0-10 points)
#               LS10_demo / LS10_sei (share answering 10) / SEI (difference in the skill index itself, demo controls, within school)
#   cell:*      one model on the four cells (bottom and top status quartile x bottom and top achievement quartile), AT omitted:
#               cell:R, cell:PL, cell:AL = difference of each cell from AT, with demo or demo + skill index, school fixed effects
#   n:R, n:AT   unweighted cell sizes (first plausible value, final weight); systems with a cell below MIN_CELL are dropped
# Output: bench_sys.csv, bench_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]

stat_bench <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75)); top <- as.integer(y >= q[2]); low <- as.integer(y <= q[1])
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1")); C <- as.matrix(s[, ..ctrl])
  reg <- function(keep, yv, X, g = s$CNTSCHID, coefs = "Q1") tryCatch({
    keep <- keep & !is.na(keep); X <- as.matrix(X)[keep, , drop = FALSE]
    X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    b <- fwls(yv[keep], X, w[keep], if (is.null(g)) NULL else g[keep]); unname(b[coefs]) }, error = function(e) rep(NA_real_, length(coefs)))
  Q1 <- as.integer(s$sesq == 1); out <- c()
  tp <- top == 1 & s$sesq %in% c(1, 4) & !is.na(s$SEI)                       # top achievers, bottom or top status quartile, skill index observed
  out["pair:AT:demo"]       <- reg(tp, s$LS_z, cbind(Q1 = Q1, C))
  out["pair:AT:sei"]        <- reg(tp, s$LS_z, cbind(Q1 = Q1, C, SEI = s$SEI))
  out["pair:AT:nofe_demo"]  <- reg(tp, s$LS_z, cbind(Q1 = Q1, C), g = NULL)
  out["pair:AT:nofe_sei"]   <- reg(tp, s$LS_z, cbind(Q1 = Q1, C, SEI = s$SEI), g = NULL)
  out["pair:AT:sei_points"] <- reg(tp, s$LS, cbind(Q1 = Q1, C, SEI = s$SEI))
  out["pair:AT:LS10_demo"]  <- reg(tp, s$LS10, cbind(Q1 = Q1, C))
  out["pair:AT:LS10_sei"]   <- reg(tp, s$LS10, cbind(Q1 = Q1, C, SEI = s$SEI))
  out["pair:AT:SEI"]        <- reg(tp, s$SEI, cbind(Q1 = Q1, C))
  # four cells in one model, advantaged top achievers omitted
  four <- (top == 1 | low == 1) & s$sesq %in% c(1, 4) & !is.na(s$SEI)
  cells <- cbind(R = Q1 * top, PL = Q1 * low, AL = (1 - Q1) * low)
  out[c("cell:R:demo", "cell:PL:demo", "cell:AL:demo")] <- reg(four, s$LS_z, cbind(cells, C), coefs = c("R", "PL", "AL"))
  out[c("cell:R:sei", "cell:PL:sei", "cell:AL:sei")]    <- reg(four, s$LS_z, cbind(cells, C, SEI = s$SEI), coefs = c("R", "PL", "AL"))
  out["n:R"] <- sum(tp & Q1 == 1, na.rm = TRUE); out["n:AT"] <- sum(tp & Q1 == 0, na.rm = TRUE)
  out
}

SYS <- unique(d$CNT); if (nzchar(Sys.getenv("PAPER_TEST_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("PAPER_TEST_SYSTEMS"), " ")[[1]])   # testing only
log_step("benchmark models on", length(SYS), "systems")
res <- run_systems(d, stat_bench, systems = SYS)
small <- res[term %in% c("n:R", "n:AT") & est < MIN_CELL, unique(CNT)]
log_step("systems below", MIN_CELL, "students in a cell:", paste(small, collapse = " "))
res <- res[!CNT %in% small]
fwrite(res, orr("bench_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("bench_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_pos, sig_neg, I2 = round(I2))])
