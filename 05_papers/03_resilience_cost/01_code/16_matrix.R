# The Cost of Resilience -- step 16: the status x achievement matrix (descriptive).
# Groups follow PISA 2025 (Volume I, ch. 2): national quarters of the status index (sesq) crossed with national quarters of
# achievement (reading by default; PAPER_ACH=SCIE for the robustness check). Achievement quarters are re-derived per plausible
# value and replicate with the same boundary rule as the other steps: bottom = y <= 25th percentile, top = y >= 75th percentile,
# the middle split at the median.
# Per system (BRR + Rubin), no controls:
#   mean:S#A#   mean life satisfaction (0-10) in each of the 16 cells (S = status quarter, A = achievement quarter)
#   ls10:S#A#   share answering 10;   share:S#A#   weighted share of the system's students
#   diff:*      differences of cell means for the four corner groups: R = S1A4 (resilient), PL = S1A1, AL = S4A1,
#               AT = S4A4 (advantaged top achievers, the reference): R-AT, R-PL, R-AL, PL-AT, AL-AT
#   n:S#A#      unweighted students in the cell (mean over plausible values)
# No system is dropped here: n:* lets the reporting apply MIN_CELL where a comparison needs it.
# Output: matrix_sys.csv, matrix_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
CELLS <- as.vector(outer(paste0("S", 1:4), paste0("A", 1:4), paste0))

stat_matrix <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .5, .75))
  aq <- fifelse(y <= q[1], 1L, fifelse(y >= q[3], 4L, fifelse(y <= q[2], 2L, 3L)))
  cell <- paste0("S", s$sesq, "A", aq)
  ok <- !is.na(s$sesq) & !is.na(aq) & !is.na(w)
  out <- c()
  for (k in CELLS) {
    i <- ok & cell == k
    out[paste0("mean:", k)]  <- if (any(i)) wmean(s$LS[i], w[i]) else NA_real_
    out[paste0("ls10:", k)]  <- if (any(i)) wmean(s$LS10[i], w[i]) else NA_real_
    out[paste0("share:", k)] <- sum(w[i]) / sum(w[ok])
    out[paste0("n:", k)]     <- sum(i)
  }
  m <- function(k) out[[paste0("mean:", k)]]
  out["diff:R-AT"]  <- m("S1A4") - m("S4A4")
  out["diff:R-PL"]  <- m("S1A4") - m("S1A1")
  out["diff:R-AL"]  <- m("S1A4") - m("S4A1")
  out["diff:PL-AT"] <- m("S1A1") - m("S4A4")
  out["diff:AL-AT"] <- m("S4A1") - m("S4A4")
  out
}

SYS <- unique(d$CNT); if (nzchar(Sys.getenv("PAPER_TEST_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("PAPER_TEST_SYSTEMS"), " ")[[1]])   # testing only
log_step("matrix (", ACH_DOMAIN, ") on", length(SYS), "systems")
res <- run_systems(d, stat_matrix, systems = SYS)
fwrite(res, orr("matrix_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("matrix_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[grepl("^diff:|^mean:S[14]A[14]", term), .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_neg, sig_pos)])
