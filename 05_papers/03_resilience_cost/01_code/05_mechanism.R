# The Cost of Resilience -- step 5: mechanisms
# All models within school, on resilient (R) vs disadvantaged low achievers (PL), controls = demographics + skill index (the "sei" spec
# of step 4). Per system BRR + Rubin; then random-effects pooling and a system-level meta-regression.
#   mod:   where is the gap larger?  top x M, with M =
#            schESCS   leave-one-out school mean ESCS (status mismatch: poor student in a better-off school)
#            schACH    leave-one-out school mean achievement, per PV (big fish / little pond: top of a weak school vs middle of a strong one)
#            female    (high-achieving disadvantaged girls)
#            uni       expects a bachelor's degree or more (aspiration-resource gap: high reference point, few resources)
#            SEI and each of the six skills (which skills go with a smaller cost)
#   acc:   accounting for the gap with candidate channels on a common sample -- science self-efficacy (competence), university
#          expectation, clear career idea (direction) -- gap before/after and Gelbach contributions. Descriptive, not causal mediation.
#   top-box versions of the headline moderators (P(LS = 10)).
# meta-regression: per-system gap (step 4, lad:sei) on system traits: mean LS, share choosing 10, between-school ESCS segregation,
#   mean achievement, share of resilient students in schools with a disadvantaged low achiever.
# Output: mech_sys.csv, mech_pool.csv, meta_reg.csv, system_traits.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), uni = as.integer(EXPECEDU >= 7))]
d[, EXPECEDU_z := zw(EXPECEDU, w), by = CNT]
SEZ <- paste0(SE6, "_z")

loo_mean <- function(v, g, w) {                       # weighted leave-one-out group mean; NA for singletons
  ok <- !is.na(v) & !is.na(w); sw <- ave(ifelse(ok, w, 0), g, FUN = sum); swx <- ave(ifelse(ok, w * v, 0), g, FUN = sum)
  r <- (swx - ifelse(ok, w * v, 0)) / (sw - ifelse(ok, w, 0)); r[!is.finite(r)] <- NA; r
}

stat_mech <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75)); top <- as.integer(y >= q[2]); low <- as.integer(y <= q[1])
  q1 <- s$sesq == 1 & (top == 1 | low == 1)
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1")); C <- as.matrix(s[, ..ctrl])
  az <- (y - wmean(y, w)) / wsd(y, w)
  schACH <- loo_mean(az, s$CNTSCHID, w)               # in system SD of achievement, recomputed per PV and weight
  reg <- function(keep, yv, X, coefs) tryCatch({
    keep <- keep & !is.na(keep); X <- as.matrix(X)[keep, , drop = FALSE]
    X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    b <- fwls(yv[keep], X, w[keep], s$CNTSCHID[keep]); unname(b[coefs]) }, error = function(e) rep(NA_real_, length(coefs)))
  out <- c()
  base <- cbind(top = top, C, SEI = s$SEI)
  M <- list(schESCS = s$schESCS_loo_z, schACH = schACH, female = s$female, uni = s$uni, SEI = s$SEI)
  for (z in avail(s, SEZ)) M[[sub("_z$", "", z)]] <- s[[z]]
  if (length(avail(s, "growth"))) M$growth <- s$growth              # growth mindset, 0/1 (added 15 November 2026)
  for (z in avail(s, c("EFFSCIE_z", "BELONG_z", "JOYSCIE_z"))) M[[sub("_z$", "", z)]] <- s[[z]]   # science self-efficacy, belonging, enjoyment of science (added 15 November 2026)
  for (m in names(M)) {
    mv <- M[[m]]; if (m == "female" && !"female" %in% ctrl) next
    X <- if (m %in% c("SEI", "female")) cbind(base, topX = top * mv) else cbind(base, M = mv, topX = top * mv)
    b <- reg(q1, s$LS_z, X, c("top", "topX"))
    out[paste0("mod:", m, ":top")] <- b[1]; out[paste0("mod:", m, ":topX")] <- b[2]
  }
  for (m in c("schESCS", "schACH", "female", "uni")) {           # top-box versions
    mv <- M[[m]]; if (m == "female" && !"female" %in% ctrl) next
    X <- if (m == "female") cbind(base, topX = top * mv) else cbind(base, M = mv, topX = top * mv)
    out[paste0("mod10:", m, ":topX")] <- reg(q1, s$LS10, X, "topX")
  }
  # accounting on a common sample
  ch <- avail(s, c("EFFSCIE_z", "uni", "SISCO"))
  cc <- q1 & complete.cases(s[, ..ch]) & !is.na(s$SEI)
  out["acc:base"] <- reg(cc, s$LS_z, base, "top")
  bf <- reg(cc, s$LS_z, cbind(base, as.matrix(s[, ..ch])), c("top", ch))
  out["acc:full"] <- bf[1]
  for (j in seq_along(ch)) {
    out[paste0("acc:gamma:", ch[j])] <- reg(cc, s[[ch[j]]], base, "top")                 # how resilient students differ on the channel
    out[paste0("acc:beta:", ch[j])]  <- bf[j + 1]                                         # channel -> LS
    out[paste0("acc:gel:", ch[j])]   <- out[paste0("acc:gamma:", ch[j])] * bf[j + 1]       # contribution to (base - full)
  }
  out["n:R"] <- sum(q1 & top == 1, na.rm = TRUE); out["n:PL"] <- sum(q1 & low == 1, na.rm = TRUE)
  out
}

log_step("mechanism models on", uniqueN(d$CNT), "systems")
res <- run_systems(d, stat_mech)
small <- res[term %in% c("n:R", "n:PL") & est < MIN_CELL, unique(CNT)]
res <- res[!CNT %in% small]
fwrite(res, orr("mech_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("mech_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems; dropped", paste(small, collapse = " "))
print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), n_neg, sig_pos, sig_neg, I2 = round(I2))], nrows = 200)

# ---------------- system-level meta-regression of the step-4 gap ----------------
gs <- fread(orr("gap_sys.csv"))[term == "lad:sei", .(CNT, est, se)]
tr <- d[, {
  q <- wquant(ACH1, w, c(.25, .75)); cell <- fifelse(sesq == 1 & ACH1 >= q[2], "R", fifelse(sesq == 1 & ACH1 <= q[1], "PL", NA_character_))
  sm <- data.table(sch = CNTSCHID, cell)[!is.na(cell), .(hasPL = any(cell == "PL"), nR = sum(cell == "R")), by = sch]
  bw <- { m <- ave(ESCS * w, CNTSCHID, FUN = sum) / ave(w, CNTSCHID, FUN = sum); wsd(m, w)^2 / wsd(ESCS, w)^2 }
  one <- uniqueN(CNTSCHID) == 1                      # ISL, LUX, MAC, MLT: school IDs suppressed in the public file
  list(LS_mean = wmean(LS, w), LS10 = wmean(LS10, w), seg_ESCS = if (one) NA_real_ else bw, ach_mean = wmean(ACH1, w),
       R_mixed = if (one) NA_real_ else sum(sm[hasPL == TRUE, nR]) / max(1, sum(sm$nR)), one_school_id = one)
}, by = CNT]
fwrite(tr, orr("system_traits.csv"))
md <- merge(gs, tr, by = "CNT")[!is.na(est) & !is.na(se) & se > 0]
log_step("meta-regression on", nrow(md), "systems")
tau2 <- pool(md$est, md$se)$tau_sd^2
metareg <- function(vars) {
  m <- md[complete.cases(md[, ..vars])]
  X <- cbind(1, scale(as.matrix(m[, ..vars]))); W <- 1 / (m$se^2 + tau2)
  V <- solve(crossprod(X * sqrt(W))); b <- V %*% crossprod(X * W, m$est)
  data.table(model = paste(vars, collapse = "+"), n_sys = nrow(m), term = c("(Intercept)", vars), b = as.vector(b), se = sqrt(diag(V)))[, t := b / se][]
}
TR <- c("LS_mean", "LS10", "seg_ESCS", "ach_mean", "R_mixed")
mr <- rbind(rbindlist(lapply(TR, metareg)), metareg(TR))
fwrite(mr, orr("meta_reg.csv"))
cat("\n== meta-regression of the resilience gap (per SD of the system trait; tau2 =", round(tau2, 4), ") ==\n")
print(mr[term != "(Intercept)"], digits = 3)
