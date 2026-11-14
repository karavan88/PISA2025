# Cost of Resilience / Price of Progress -- step 9: quantities the two reports need that steps 3-8 did not write.
# New outputs only; nothing from steps 3-8 is overwritten.
#   (a) per system, BRR + Rubin, within school, demographics + ESCS: the achievement slope of life satisfaction without and with the
#       skill index (whole sample and by ESCS quartile); the slope on P(LS = 10) and P(LS <= 4); how the skill index rises with achievement
#   (b) descriptives on PV1 with every system weighted equally: the 0-10 distribution by SES x achievement cell; mean life satisfaction
#       by within-system achievement decile and ESCS quartile, raw and net of the skill index
# Output: extras_sys.csv, extras_pool.csv, desc_dist.csv, desc_decile.csv
source("05_papers/04_price_of_progress/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), LSle4 = as.integer(LS <= 4))]

stat_x <- function(s, y, w) {
  az <- (y - wmean(y, w)) / wsd(y, w); g <- s$CNTSCHID
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1")); C <- as.matrix(s[, ..ctrl])
  reg <- function(keep, yv, X, coef = "ach") tryCatch({
    keep <- keep & !is.na(keep) & !is.na(s$SEI); X <- as.matrix(X)[keep, , drop = FALSE]     # SEI sample throughout: with/without comparable
    X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    unname(fwls(yv[keep], X, w[keep], g[keep])[coef]) }, error = function(e) NA_real_)
  all <- rep(TRUE, nrow(s)); out <- c()
  B0 <- cbind(ach = az, ESCS_z = s$ESCS_z, C); B1 <- cbind(B0, SEI = s$SEI)
  out["all:ach_noskill"] <- reg(all, s$LS_z, B0); out["all:ach_skill"] <- reg(all, s$LS_z, B1)
  out["all:SEI"] <- reg(all, s$LS_z, B1, "SEI")
  out["all:sei_on_ach"] <- reg(all, s$SEI, B0)
  for (o in c("LS10", "LSle4")) { out[paste0(o, ":ach_noskill")] <- reg(all, s[[o]], B0); out[paste0(o, ":ach_skill")] <- reg(all, s[[o]], B1) }
  for (q in 1:4) { k <- s$sesq == q
    out[paste0("q", q, ":ach_noskill")] <- reg(k, s$LS_z, cbind(ach = az, C)); out[paste0("q", q, ":ach_skill")] <- reg(k, s$LS_z, cbind(ach = az, C, SEI = s$SEI)) }
  out
}
log_step("extras on", uniqueN(d$CNT), "systems")
res <- run_systems(d, stat_x)
fwrite(res, orr("extras_sys.csv")); pl <- pool_by(res, "term"); fwrite(pl, orr("extras_pool.csv"))
print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_pos, sig_neg, I2 = round(I2))])

# ---- descriptives, PV1, each system weighted equally
d[, wn := w / sum(w), by = CNT]
d[, c("q25", "q75") := as.list(wquant(ACH1, w, c(.25, .75))), by = CNT]
d[, cell := fifelse(sesq == 1 & ACH1 >= q75, "R", fifelse(sesq == 1 & ACH1 <= q25, "PL", fifelse(sesq == 4 & ACH1 >= q75, "AT", fifelse(sesq == 4 & ACH1 <= q25, "AL", NA_character_))))]
dist <- d[!is.na(cell), .(wt = sum(wn)), by = .(cell, LS)][, share := wt / sum(wt), by = cell][order(cell, LS)]
fwrite(dist[, .(cell, LS, share)], orr("desc_dist.csv"))
d[, dec := { q <- wquant(ACH1, w, seq(.1, .9, .1)); 1L + findInterval(ACH1, q, left.open = TRUE) }, by = CNT]
d[, LS_adj := { ok <- !is.na(SEI); r <- rep(NA_real_, .N); b <- lm.wfit(cbind(1, SEI[ok]), LS_z[ok], w[ok])$coefficients; r[ok] <- LS_z[ok] - b[2] * SEI[ok]; r }, by = CNT]
dc <- d[!is.na(SEI), .(raw = wmean(LS_z, w), adj = wmean(LS_adj, w), sei = wmean(SEI, w), n = .N), by = .(CNT, sesq, dec)]
dc <- dc[n >= 15, .(raw = mean(raw), adj = mean(adj), sei = mean(sei), n_sys = .N), by = .(sesq, dec)][order(sesq, dec)]
fwrite(dc, orr("desc_decile.csv")); print(dc[sesq %in% c(1, 4)])
log_step("done")
