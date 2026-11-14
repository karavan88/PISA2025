# The Cost of Resilience -- step 7: is the curiosity moderation real?
# Step 5 found the resilience gap ~0.06 SD larger per SD of curiosity. Curiosity has no second rater, so this step attacks it from
# inside the student questionnaire. Within school, R vs disadvantaged low achievers, base = top + demographics + skill index; the
# coefficient reported is top x curiosity unless noted. Per system BRR + Rubin, RE pooled.
#   base      replicate step 5
#   ladder    outcome P(LS = 10), P(LS >= 9), P(LS <= 4): top-box vs misery
#   rs        + content-free extreme responding, acquiescence, midpoint responding, each also interacted with top
#   purged    curiosity residualised on the response-style indices (within system)
#   items     curiosity from the positive items only; from the reversed item only ("learning new things is boring", reversed --
#             acquiescence pushes it the other way); from the comparative item only ("more curious than most people I know")
#   nospeed   drop questionnaire speeders
#   joint     all six skills and their top interactions together (curiosity's unique part)
#   nosei     without the skill index in the base
#   q4        the same interaction among advantaged students (AT vs AL): resilience-specific or a high-achiever pattern?
# Output: cur_sys.csv, cur_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), LSge9 = as.integer(LS >= 9), LSle4 = as.integer(LS <= 4))]
# item-level curiosity (not kept in the analytic file)
it <- fread(STUDENTS, select = c("CNTSTUID", "ST301Q01JA", "ST301Q04JA", "ST301Q06JA", "ST301Q08JA", "ST301Q10JA"))
d <- merge(d, it, by = "CNTSTUID", all.x = TRUE, sort = FALSE)
d[, `:=`(cur_pos = rowMeans(cbind(ST301Q01JA, ST301Q04JA, ST301Q06JA, ST301Q10JA), na.rm = TRUE), cur_rev = 6 - ST301Q08JA, cur_cmp = ST301Q06JA)]
d[is.nan(cur_pos), cur_pos := NA]
for (v in c("cur_pos", "cur_rev", "cur_cmp")) d[, (paste0(v, "_z")) := if (sum(!is.na(get(v))) > 50) zw(get(v), w) else NA_real_, by = CNT]
RSV <- c("ERS_z", "ACQ5_z", "MRS5_z")
d[, CURIO_pz := { ok <- complete.cases(CURIO_z, ERS_z, ACQ5_z, MRS5_z); r <- rep(NA_real_, .N)
  if (sum(ok) > 50) { X <- cbind(1, ERS_z, ACQ5_z, MRS5_z)[ok, ]; b <- lm.wfit(X, CURIO_z[ok], w[ok])$coefficients; r[ok] <- CURIO_z[ok] - X %*% b; r <- zw(r, w) }
  r }, by = CNT]
SEZ <- paste0(SE6, "_z")
log_step("curiosity checks on", uniqueN(d$CNT), "systems")

stat_cur <- function(s, y, w) {
  q <- wquant(y, w, c(.25, .75)); top <- as.integer(y >= q[2]); low <- as.integer(y <= q[1])
  q1 <- s$sesq == 1 & (top == 1 | low == 1); q4 <- s$sesq == 4 & (top == 1 | low == 1)
  ctrl <- avail(s, c("female", "AGE", "g_m1", "g_p1")); C <- as.matrix(s[, ..ctrl]); g <- s$CNTSCHID
  reg <- function(keep, yv, X, coefs = "topX") tryCatch({
    keep <- keep & !is.na(keep); X <- as.matrix(X)[keep, , drop = FALSE]
    X <- X[, apply(X, 2, function(v) var(v, na.rm = TRUE) > 0), drop = FALSE]
    unname(fwls(yv[keep], X, w[keep], g[keep])[coefs]) }, error = function(e) rep(NA_real_, length(coefs)))
  base <- cbind(top = top, C, SEI = s$SEI)
  withM <- function(m, B = base) cbind(B, M = m, topX = top * m)
  cur <- s$CURIO_z; out <- c()
  if (all(is.na(cur))) return(NULL)
  rsok <- complete.cases(s[, ..RSV])
  out["base"]       <- reg(q1, s$LS_z, withM(cur))
  out["base_rssample"] <- reg(q1 & rsok, s$LS_z, withM(cur))
  out["ladder:LS10"]  <- reg(q1, s$LS10, withM(cur))
  out["ladder:LSge9"] <- reg(q1, s$LSge9, withM(cur))
  out["ladder:LSle4"] <- reg(q1, s$LSle4, withM(cur))
  RS <- as.matrix(s[, ..RSV]); colnames(RS) <- RSV
  out["rs"]         <- reg(q1 & rsok, s$LS_z, cbind(withM(cur), RS, top * RS))
  out["purged"]     <- reg(q1, s$LS_z, withM(s$CURIO_pz))
  out["items:pos"]  <- reg(q1, s$LS_z, withM(s$cur_pos_z))
  out["items:rev"]  <- reg(q1, s$LS_z, withM(s$cur_rev_z))
  out["items:cmp"]  <- reg(q1, s$LS_z, withM(s$cur_cmp_z))
  out["nospeed"]    <- reg(q1 & s$speeder %in% 0 & s$speeder_rel %in% 0, s$LS_z, withM(cur))
  sez <- avail(s, SEZ); SZ <- as.matrix(s[, ..sez]); TZ <- top * SZ; colnames(TZ) <- paste0("top:", sez)
  bj <- reg(q1, s$LS_z, cbind(top = top, C, SZ, TZ), paste0("top:", sez)); names(bj) <- paste0("joint:", sub("_z$", "", sez))
  out <- c(out, bj)
  out["nosei"]      <- reg(q1, s$LS_z, cbind(top = top, C, M = cur, topX = top * cur))
  out["q4"]         <- reg(q4, s$LS_z, withM(cur))
  out["q4:LS10"]    <- reg(q4, s$LS10, withM(cur))
  # descriptive: do resilient students differ in curiosity (net of the skill index)?
  out["level:R_vs_PL"] <- reg(q1, cur, base, "top")
  out["n:R"] <- sum(q1 & top == 1, na.rm = TRUE); out["n:PL"] <- sum(q1 & low == 1, na.rm = TRUE)
  out
}
res <- run_systems(d[!is.na(CURIO_z)], stat_cur)
small <- res[term %in% c("n:R", "n:PL") & est < MIN_CELL, unique(CNT)]
res <- res[!CNT %in% small]
fwrite(res, orr("cur_sys.csv"))
pl <- pool_by(res[!grepl("^n:", term)], "term")
fwrite(pl, orr("cur_pool.csv"))
log_step("done:", uniqueN(res$CNT), "systems; dropped", paste(small, collapse = " "))
print(pl[, .(term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 2), n_neg, sig_pos, sig_neg, I2 = round(I2))], nrows = 100)
