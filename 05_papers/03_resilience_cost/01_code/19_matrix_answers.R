# The Cost of Resilience -- step 19: where on the 0-10 scale the gap lies, and whether it is a matter of scale use (author's design,
# 15 November 2026). Same groups, students and estimator as step 17 (matrix_helpers.R): 16 status x achievement cells, advantaged top
# achievers omitted, school fixed effects. Contrasts of resilient students: R-AT (= the S1A4 coefficient), R-PL, R-AL.
# Per system, BRR + Rubin, random-effects pooling:
#   ans:<M>:<k>:<contrast>     share giving answer k (0..10), percentage-point scale as a share (0-1)            M3 and M5
#   thr:<M>:<t>:<contrast>     share at or above 4, 6, 8, 9, 10 (ge4 ... ge10) and at most 3 (le3)               M3 and M5
#   rs:M3:<contrast>           life satisfaction (SD) in model 3 on the students with every response-style index observed
#   rs:M3rs:<contrast>         the same with the four response-style indices (extreme, acquiescent, midpoint and extreme on a 5-point
#                              pool, built from items unrelated to wellbeing) as controls
#   rsgap:<index>:<contrast>   the response-style index itself as the outcome of model 3 (do the groups differ in scale use?)
#   rs:M3nospeed:<contrast>    model 3 without questionnaire speeders (absolute < 1 s per item, or bottom 5% in the system)
#   plac:<item>:<contrast>     placebo: share answering 10 on the 1-10 effort thermometers (EFF1_10, EFF2_10, EFFQ_10), model 3
#   plac:LS10:<contrast>, plac:LS10net:<contrast>   share answering 10 on life satisfaction, model 3, on the students with every
#                              thermometer observed, without and with the three thermometer top-box indicators as controls
#   n:S#A#                     students per cell in the model sample (mean over plausible values)
# Model 3 = cells + school fixed effects + sex, age, grade; model 5 = model 3 + skills, mindsets and relationships (step 17).
# Systems without school IDs or with fewer than MIN_CELL students in a corner cell are dropped, as in step 17.
# Output: mxans_sys.csv, mxans_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
source("05_papers/03_resilience_cost/01_code/matrix_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), LS10 = as.numeric(LS10))]
ANS <- paste0("a", 0:10); for (k in 0:10) d[, (paste0("a", k)) := as.integer(LS == k)]
THR <- c(ge4 = 4, ge6 = 6, ge8 = 8, ge9 = 9, ge10 = 10); for (t in names(THR)) d[, (t) := as.integer(LS >= THR[[t]])]
d[, le3 := as.integer(LS <= 3)]
RSI <- c("ERS_z", "ACQ5_z", "MRS5_z", "ERS5_z"); PLAC <- c("EFF1_10", "EFF2_10", "EFFQ_10")

stat_ans <- function(s, y, w) {
  cell <- mx_cell(s, y, w); D <- mx_dummies(cell); ct <- mx_controls(s); keep <- mx_keep(s, cell, ct); g <- s$CNTSCHID
  C3 <- as.matrix(s[, ct$demo, with = FALSE]); C5 <- cbind(C3, as.matrix(s[, c(ct$skmi, ct$rel), with = FALSE]))
  fit <- function(Y, X, k = keep) tryCatch(wls(Y, X, w, k, g), error = function(e) NULL)
  con <- function(f, j = 1) if (is.null(f)) setNames(rep(NA_real_, 3), names(CON)) else mx_contrasts(pick(f, EST, j))
  out <- c()
  put <- function(prefix, v) out[paste0(prefix, ":", names(v))] <<- v
  OUTC <- c(ANS, names(THR), "le3"); Y <- as.matrix(s[, ..OUTC])
  for (m in c("M3", "M5")) {
    f <- fit(Y, cbind(D, if (m == "M3") C3 else C5))
    for (j in seq_along(OUTC)) {
      o <- OUTC[j]; lab <- if (o %in% ANS) paste0("ans:", m, ":", sub("^a", "", o)) else paste0("thr:", m, ":", o)
      put(lab, con(f, j))
    }
  }
  # response styles: same students with and without the indices, and the indices as outcomes
  rsi <- avail(s, RSI)
  if (length(rsi)) {
    kr <- keep & complete.cases(s[, ..rsi]); R <- as.matrix(s[, ..rsi])
    put("rs:M3", con(fit(s$LS_z, cbind(D, C3), kr)))
    put("rs:M3rs", con(fit(s$LS_z, cbind(D, C3, R), kr)))
    fr <- fit(R, cbind(D, C3), kr); for (j in seq_along(rsi)) put(paste0("rsgap:", rsi[j]), con(fr, j))
  }
  put("rs:M3all", con(fit(s$LS_z, cbind(D, C3))))
  put("rs:M3nospeed", con(fit(s$LS_z, cbind(D, C3), keep & s$speeder %in% 0 & s$speeder_rel %in% 0)))
  # placebo: top box on the effort thermometers
  pc <- avail(s, PLAC)
  if (length(pc)) {
    kp <- keep & complete.cases(s[, ..pc]); P <- as.matrix(s[, ..pc])
    fp <- fit(P, cbind(D, C3), kp); for (j in seq_along(pc)) put(paste0("plac:", pc[j]), con(fp, j))
    put("plac:LS10", con(fit(s$LS10, cbind(D, C3), kp)))
    put("plac:LS10net", con(fit(s$LS10, cbind(D, C3, P), kp)))
  }
  for (k in CELLS) out[paste0("n:", k)] <- sum(keep & cell %in% k)
  out
}

SYS <- unique(d$CNT); if (nzchar(Sys.getenv("PAPER_TEST_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("PAPER_TEST_SYSTEMS"), " ")[[1]])   # testing only
noid <- d[CNT %in% SYS, .(ok = mean(!is.na(CNTSCHID)) > .5), by = CNT][ok == FALSE, CNT]
log_step("systems without school IDs (dropped):", paste(noid, collapse = " ")); SYS <- setdiff(SYS, noid)
log_step("answers and scale use (", ACH_DOMAIN, ") on", length(SYS), "systems")
res <- run_systems(d, stat_ans, systems = SYS)
small <- res[term %in% paste0("n:", CORNERS) & est < MIN_CELL, unique(CNT)]
log_step("systems below", MIN_CELL, "students in a corner cell:", paste(small, collapse = " "))
res <- res[!CNT %in% small]
fwrite(res, orr("mxans_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term) & !is.na(est) & !is.na(se) & se > 0], "term")
fwrite(pl, orr("mxans_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[grepl("^(ans:M3|thr:M3|rs|plac)", term) & grepl("R-AT$", term), .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), sig_neg, sig_pos)], nrows = 100)
