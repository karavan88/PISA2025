# The Cost of Resilience -- step 3: is the resilience gap a response-style artefact?
# If low achievers simply tick the top of the 0-10 ladder more often (extreme responding), the "cost of resilience" is a scale-use
# difference, not a wellbeing difference. Checks, per system (BRR + Rubin), all within school unless noted:
#   (a) descriptives by cell: mean LS, share choosing 10, share <= 4, extreme/acquiescent/midpoint response indices, speeders
#   (b) the resilient-vs-disadvantaged-low-achiever gap: demographics -> + skill index -> + response-style indices
#   (c) the gap after dropping questionnaire speeders (absolute < 1 s/item and system bottom 5%)
#   (d) the gap along the ladder: P(LS >= k) for k = 4, 6, 8, 9, 10 -- a pure top-box effect would show up only at k = 10
# Output: 05_papers/03_resilience_cost/04_output/rs_sys.csv (per system), rs_pool.csv (random-effects summaries)
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), LSle4 = as.integer(LS <= 4))]
for (k in c(4, 6, 8, 9)) d[, (paste0("LSge", k)) := as.integer(LS >= k)]
CELLS <- c(R = "resilient", PL = "disadv. low achiever", AT = "advantaged top", AL = "advantaged low")
DESC <- c("LS", "LS10", "LSle4", "ERS_z", "ARS_z", "ACQ5_z", "MRS5_z", "ERS5_z", "SEI", "speeder")
THR <- c("LSge4", "LSge6", "LSge8", "LSge9", "LS10")
PLAC <- c("EFF1", "EFF2", "EFFQ")

stat_rs <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75))
  cell <- fifelse(s$sesq == 1 & y >= q[2], "R", fifelse(s$sesq == 1 & y <= q[1], "PL",
          fifelse(s$sesq == 4 & y >= q[2], "AT", fifelse(s$sesq == 4 & y <= q[1], "AL", NA_character_))))
  out <- c()
  for (cc in names(CELLS)) for (v in DESC) out[paste0("mean:", cc, ":", v)] <- wmean(s[[v]][cell %in% cc], w[cell %in% cc])
  for (v in DESC) { out[paste0("diff:R-PL:", v)] <- out[paste0("mean:R:", v)] - out[paste0("mean:PL:", v)]
                    out[paste0("diff:AT-AL:", v)] <- out[paste0("mean:AT:", v)] - out[paste0("mean:AL:", v)] }
  q1 <- cell %in% c("R", "PL"); top <- as.integer(cell == "R")
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1"))
  ctrl <- ctrl[vapply(ctrl, function(v) var(s[[v]][q1], na.rm = TRUE) > 0, logical(1))]
  X0 <- cbind(top = top, as.matrix(s[, ..ctrl]))[q1, , drop = FALSE]
  sch <- s$CNTSCHID[q1]; ww <- w[q1]; ss <- s[q1]
  rs <- avail(ss, c("ERS_z", "ACQ5_z", "MRS5_z", "ERS5_z"))
  reg <- function(yv, X, g = sch, keep = rep(TRUE, length(yv))) tryCatch({
    b <- fwls(yv[keep], X[keep, , drop = FALSE], ww[keep], if (is.null(g)) NULL else g[keep]); unname(b["top"]) }, error = function(e) NA_real_)
  out["gap:demo"]    <- reg(ss$LS_z, X0)
  out["gap:sei"]     <- reg(ss$LS_z, cbind(X0, SEI = ss$SEI))
  out["gap:sei_rs"]  <- if (length(rs)) reg(ss$LS_z, cbind(X0, SEI = ss$SEI, as.matrix(ss[, ..rs]))) else NA
  # same sample as gap:sei_rs but without the response-style indices -> the change is attributable to them, not to sample loss
  out["gap:sei_rssample"] <- if (length(rs)) reg(ss$LS_z, cbind(X0, SEI = ss$SEI), keep = complete.cases(ss[, ..rs])) else NA
  out["gap:sei_nospeed"]  <- reg(ss$LS_z, cbind(X0, SEI = ss$SEI), keep = ss$speeder %in% 0 & ss$speeder_rel %in% 0)
  out["gap:sei_points"]   <- reg(ss$LS, cbind(X0, SEI = ss$SEI))                      # in 0-10 ladder points
  out["gap:sei_nofe"]     <- reg(ss$LS_z, cbind(X0, SEI = ss$SEI), g = NULL)          # between + within school
  for (t in THR) out[paste0("thr:", t)] <- reg(ss[[t]], cbind(X0, SEI = ss$SEI))
  # does response style differ by resilience once skills are held fixed?  (top coefficient on the RS index itself)
  for (r in rs) out[paste0("rsgap:", r)] <- reg(ss[[r]], cbind(X0, SEI = ss$SEI))
  # (e) placebo: top-box use on the 1-10 effort thermometers. If high achievers avoid 10 on these too, the life-satisfaction
  #     top-box gap is (at least partly) numeric-scale use. Gap in P(10) and in the mean, plus the LS top-box gap net of it.
  for (p in PLAC) { out[paste0("plac:", p, "_10")] <- reg(ss[[paste0(p, "_10")]], cbind(X0, SEI = ss$SEI))
                    out[paste0("plac:", p, "_z")]  <- reg(ss[[paste0(p, "_z")]], cbind(X0, SEI = ss$SEI)) }
  pc <- paste0(PLAC, "_10")
  out["thr:LS10_netplac"] <- reg(ss$LS10, cbind(X0, SEI = ss$SEI, as.matrix(ss[, ..pc])), keep = complete.cases(ss[, ..pc]))
  out["thr:LS10_placsample"] <- reg(ss$LS10, cbind(X0, SEI = ss$SEI), keep = complete.cases(ss[, ..pc]))
  out["gap:sei_netplac"] <- reg(ss$LS_z, cbind(X0, SEI = ss$SEI, as.matrix(ss[, ..pc])), keep = complete.cases(ss[, ..pc]))
  for (cc in c("R", "PL", "AT", "AL")) for (p in pc) out[paste0("mean:", cc, ":", p)] <- wmean(s[[p]][cell %in% cc], w[cell %in% cc])
  out["n:R"] <- sum(cell == "R", na.rm = TRUE); out["n:PL"] <- sum(cell == "PL", na.rm = TRUE)
  out
}

# template so that every system returns the same names (systems too small for the contrast return NA)
log_step("response-style checks on", uniqueN(d$CNT), "systems")
res <- run_systems(d, stat_rs)
# drop systems whose contrasted cells are too small (PV1 counts)
small <- res[term %in% c("n:R", "n:PL") & est < MIN_CELL, unique(CNT)]
log_step("systems below", MIN_CELL, "students in a cell:", paste(small, collapse = " "))
res <- res[!CNT %in% small]
fwrite(res, orr("rs_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("rs_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems")
print(pl[grepl("^(gap|thr|rsgap|diff)", term)], digits = 3)
