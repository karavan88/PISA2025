# The Cost of Resilience -- step 9: focal answers (do low achievers use the 0-10 ladder more coarsely?)
# Barrington-Leigh (2024, J Public Econ 230) shows in PISA 2018 that the share of answers 0, 5 and 10 falls with mathematics score and
# attributes it to less numerate respondents simplifying the scale to its bottom, middle and top. If disadvantaged low achievers (PL) do
# this more than resilient students (R), part of the shortfall of 10s among R is a difference in scale use, not in satisfaction and not
# in the standard for a 10. The reading has implications away from the top of the ladder, where the other two readings have none:
# PL should also over-use 0 and 5. Resilience cells are re-derived per plausible value and replicate weight.
#   A (per system, within school, BRR + Rubin, RE pooled), R vs PL, demographics + skill index unless noted:
#     ans   gap in the share giving each answer 0..10                       loc   answer 5 against its neighbours 4 and 6; 0 against 1
#     foc   gap in the share answering 0, 5 or 10; and 0 or 5 (the focal answers that are not the top), with and without response-style indices
#     bin   comparisons that do not depend on how a simplifier rounds within a band: share at 7+, 8+, at most 2, at most 3
#     heap  among students answering 4-6, the share answering 5; among 9-10, the share answering 10
#     grad  the same quantities on achievement (per SD) among ALL bottom-quartile students, and among top-quartile students (grad4)
#   B (pooled over systems, system fixed effects, weights normalised per system, BRR + Rubin): too few R answer 0-1 for a per-system model
#     share answer distribution of each group      heap  heaping at 0 (among 0-1), 5 (among 4-6) and 10 (among 9-10), R minus PL
#     top   heaping at 10 beyond the heaping seen at 0 and 5 (the part a general coarse use of the scale does not predict)
#     mix   share of each group that answers only 0, 5 or 10, read off the excess of 5s, and the gap at 10 once their answers are removed
# Output: foc_sys.csv, foc_pool.csv (part A), foc_model.csv (part B)
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0))]
DEMO <- c("female", "AGE", "g_m1", "g_p1"); RSZ <- c("ERS_z", "ACQ5_z", "MRS5_z", "ERS5_z")
ind <- function(x) as.numeric(x)

stat_foc <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75)); top <- as.integer(y >= q[2]); low <- y <= q[1]; LS <- s$LS
  q1 <- s$sesq %in% 1 & (top == 1 | low); g <- s$CNTSCHID; out <- c()
  ctrl <- avail(s, DEMO); C <- as.matrix(s[, ..ctrl]); rs <- avail(s, RSZ); R <- as.matrix(s[, ..rs])
  reg <- function(keep, yv, X, coef = "top") tryCatch({
    keep <- keep & !is.na(keep); X <- as.matrix(X)[keep, , drop = FALSE]; X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    unname(fwls(yv[keep], X, w[keep], g[keep])[coef]) }, error = function(e) NA_real_)
  Xd <- cbind(top = top, C); Xs <- cbind(Xd, SEI = s$SEI)
  for (k in 0:10) { out[paste0("ans:sei:", k)] <- reg(q1, ind(LS == k), Xs); out[paste0("ans:demo:", k)] <- reg(q1, ind(LS == k), Xd) }
  out["loc:sei:5"] <- out["ans:sei:5"] - (out["ans:sei:4"] + out["ans:sei:6"]) / 2; out["loc:sei:0"] <- out["ans:sei:0"] - out["ans:sei:1"]
  any3 <- ind(LS %in% c(0, 5, 10)); any05 <- ind(LS %in% c(0, 5))
  out["foc:sei:any"] <- reg(q1, any3, Xs); out["foc:sei:any05"] <- reg(q1, any05, Xs); out["foc:demo:any05"] <- reg(q1, any05, Xd)
  rsc <- complete.cases(R)                                              # same sample with and without the response-style indices
  out["foc:sei_rs:any05"] <- reg(q1 & rsc, any05, cbind(Xs, R)); out["foc:sei_rssample:any05"] <- reg(q1 & rsc, any05, Xs)
  out["ans:sei_rs:5"] <- reg(q1 & rsc, ind(LS == 5), cbind(Xs, R)); out["ans:sei_rs:10"] <- reg(q1 & rsc, ind(LS == 10), cbind(Xs, R))
  out["bin:sei:ge7"] <- reg(q1, ind(LS >= 7), Xs); out["bin:sei:ge8"] <- reg(q1, ind(LS >= 8), Xs)
  out["bin:sei:le2"] <- reg(q1, ind(LS <= 2), Xs); out["bin:sei:le3"] <- reg(q1, ind(LS <= 3), Xs)
  out["heap:sei:5"] <- reg(q1 & LS %in% 4:6, ind(LS == 5), Xs); out["heap:sei:10"] <- reg(q1 & LS %in% 9:10, ind(LS == 10), Xs)
  # achievement gradient of focal answering inside a status quartile (achievement in system SD; within school)
  az <- (y - wmean(y, w)) / wsd(y, w); Xa <- cbind(az = az, C, SEI = s$SEI)
  for (qq in c(1, 4)) { lab <- if (qq == 1) "grad:" else "grad4:"; k <- s$sesq %in% qq
    out[paste0(lab, "any05")] <- reg(k, any05, Xa, "az"); out[paste0(lab, "LS10")] <- reg(k, ind(LS == 10), Xa, "az")
    out[paste0(lab, "heap5")] <- reg(k & LS %in% 4:6, ind(LS == 5), Xa, "az"); out[paste0(lab, "heap10")] <- reg(k & LS %in% 9:10, ind(LS == 10), Xa, "az") }
  out["n:R"] <- sum(q1 & top == 1); out["n:PL"] <- sum(q1 & low); out["n:R_4to6"] <- sum(q1 & top == 1 & LS %in% 4:6); out["n:R_0to1"] <- sum(q1 & top == 1 & LS <= 1)
  out
}

# pooled part: every system counts equally; system fixed effects (the 0-1 band holds too few resilient students for school effects)
stat_pool <- function(s, y, w) {
  top <- low <- integer(nrow(s))
  for (i in IDX) { q <- wquant(y[i], w[i], c(.25, .75)); top[i] <- as.integer(y[i] >= q[2]); low[i] <- as.integer(y[i] <= q[1]) }
  q1 <- s$sesq %in% 1 & (top == 1 | low == 1); LS <- s$LS; g <- s$CNT; out <- c(); X <- cbind(top = top, as.matrix(s[, ..DEMO]), SEI = s$SEI)
  for (grp in c("R", "PL")) { k <- q1 & (if (grp == "R") top == 1 else low == 1); out[paste0("share:", grp, ":", 0:10)] <- vapply(0:10, function(a) sum(w[k & LS == a]) / sum(w[k]), 0) }
  reg <- function(keep, yv, Xm = X) unname(fwls(ifelse(keep, yv, NA), Xm, w, g)["top"])
  out["heap:sei:0"] <- reg(q1 & LS %in% 0:1, ind(LS == 0)); out["heap:sei:5"] <- reg(q1 & LS %in% 4:6, ind(LS == 5)); out["heap:sei:10"] <- reg(q1 & LS %in% 9:10, ind(LS == 10))
  out["heap:demo:0"] <- reg(q1 & LS %in% 0:1, ind(LS == 0), X[, colnames(X) != "SEI"]); out["heap:demo:5"] <- reg(q1 & LS %in% 4:6, ind(LS == 5), X[, colnames(X) != "SEI"])
  out["heap:demo:10"] <- reg(q1 & LS %in% 9:10, ind(LS == 10), X[, colnames(X) != "SEI"])
  oth <- (out["heap:sei:0"] + out["heap:sei:5"]) / 2
  out["top:heap_other"] <- oth; out["top:heap10_excess"] <- out["heap:sei:10"] - oth; out["top:share_general"] <- oth / out["heap:sei:10"]
  # the same in percentage points of the answer 10: heaping gap times the share of resilient students answering 9 or 10
  r910 <- sum(out[paste0("share:R:", 9:10)]); out["top:pp10_general"] <- oth * r910; out["top:pp10_excess"] <- (out["heap:sei:10"] - oth) * r910
  # mixture arithmetic on the two answer distributions: a share s of a group answers only 0, 5 or 10, the rest use the whole scale and
  # would answer 5 as often as the mean of 4 and 6. The excess of 5s then gives s, and removing the simplifiers' 10s gives the share of
  # 10 among full-scale users. Two rounding rules for simplifiers: nearest focal value (8-10 -> 10) and rounding up from 7 (7-10 -> 10).
  mixf <- function(P, mid, hi) { b5 <- (P["4"] + P["6"]) / 2; r <- (P["5"] - b5) / (sum(P[as.character(setdiff(mid, 5))]) + b5)
    c(s = unname(r / (1 + r)), f10 = unname(P["10"] - r * sum(P[as.character(setdiff(hi, 10))]))) }
  PR <- setNames(out[paste0("share:R:", 0:10)], 0:10); PP <- setNames(out[paste0("share:PL:", 0:10)], 0:10); raw <- unname(PR["10"] - PP["10"])
  for (rule in c("near", "up7")) { mid <- if (rule == "near") 3:7 else 3:6; hi <- if (rule == "near") 8:10 else 7:10
    a <- mixf(PR, mid, hi); b <- mixf(PP, mid, hi)
    out[paste0("mix:", rule, ":", c("s_R", "s_PL", "f10_R", "f10_PL", "gap10_net", "share_explained"))] <- c(a["s"], b["s"], a["f10"], b["f10"], a["f10"] - b["f10"], 1 - (a["f10"] - b["f10"]) / raw) }
  out["mix:gap10_raw"] <- raw
  out[c("n:R", "n:PL", "n:R_0to1", "n:R_4to6", "n:R_9to10")] <- c(sum(q1 & top == 1), sum(q1 & low == 1), sum(q1 & top == 1 & LS <= 1), sum(q1 & top == 1 & LS %in% 4:6), sum(q1 & top == 1 & LS >= 9))
  out
}

if (!nzchar(Sys.getenv("FOC_NO_RUN"))) {
  SYS <- sort(unique(d$CNT)); if (nzchar(Sys.getenv("FOC_SYSTEMS"))) SYS <- intersect(SYS, strsplit(Sys.getenv("FOC_SYSTEMS"), " ")[[1]])     # testing only
  log_step("focal answers on", length(SYS), "systems; part A per system")
  res <- run_systems(d, stat_foc, SYS)
  small <- res[term %in% c("n:R", "n:PL") & est < MIN_CELL, unique(CNT)]                  # same rule as steps 3-5
  log_step("systems below", MIN_CELL, "students in a cell:", paste(small, collapse = " "))
  res <- res[!CNT %in% small]
  res[!grepl("^n:", term) & !is.na(se) & se < 1e-8, `:=`(est = NA_real_, se = NA_real_)]   # degenerate fits (no within-school variation left in a small band)
  fwrite(res, orr("foc_sys.csv"))
  pl <- pool_by(res[!grepl("^n:", term)], "term"); fwrite(pl, orr("foc_pool.csv"))
  print(pl[, .(term, n_sys, re = round(re_mean, 4), se = round(re_se, 4), t = round(re_mean / re_se, 1), I2 = round(I2), n_neg, sig_neg, sig_pos)], nrows = 200)
  # part B on the systems that enter the within-school models (school identifiers, both cells large enough)
  keep <- res[term == "ans:sei:10" & !is.na(est), unique(CNT)]; d <- d[CNT %in% keep]; setkey(d, CNT)
  d[, nf := sum(W_FSTUWT), by = CNT]; for (v in c("W_FSTUWT", RW)) set(d, j = v, value = d[[v]] / d$nf)
  IDX <- split(seq_len(nrow(d)), d$CNT)
  log_step("part B pooled on", length(keep), "systems")
  pm <- pisa_est(d, stat_pool, ACH); pm[, t := est / se]; fwrite(pm, orr("foc_model.csv"))
  print(pm, digits = 3, nrows = 100)
  log_step("done:", uniqueN(res$CNT), "systems")
}
