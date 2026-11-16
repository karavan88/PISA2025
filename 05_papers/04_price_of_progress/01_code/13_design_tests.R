# The price of progress -- step 13: design tests of the school-entry cutoff on the central 35-system input layer (01_inputs.R).
# Per system, Fay BRR + Rubin over plausible values via est_sys(); pooled by DerSimonian-Laird. Writes to $PAPER_OUT (a NEW directory).
#   (a) by_month      weighted mean of D, achievement and life satisfaction by birth month relative to the cutoff r, pooled over systems
#   (b) reduced_form  the jump at the cutoff in D (first stage), achievement and life satisfaction: est_sys() with the assigned grade Z in the
#                     place of D, so the "tau" row is the jump at the cutoff given one linear birth-month slope, as in the main model
#   (c) balance       the same jump in predetermined covariates (should be zero): sex, ESCS, immigrant background, home possessions, language
#   (d) density       students per birth month just below and above the cutoff, by system (ratio of the adjacent months, and a pooled test)
#   (e) bandwidth     gamma (grade gain, the headline) when only birth months within b of the cutoff are kept, for b = 6, 4, 3; systems that keep at
#                     least two months on each side; compared with the full-window estimate in the SAME systems
# A quadratic birth-month term is not run: the estimator is linear in r by construction (tsls_m), and in a one-year cohort with 1-3 months on a
# side a quadratic is not identified; the bandwidth windows are the functional-form check.
source("05_papers/04_price_of_progress/01_code/00_helpers.R")   # est_sys, tsls_m, pool_iv, survey helpers; PAPER_OUT sets OUTR
source("05_papers/04_price_of_progress/01_code/sample_rules.R") # EXCLUDE (Ukraine), FLAG (Israel)
a <- readRDS("05_papers/04_price_of_progress/04_output/cutoff35_students.rds"); setDT(a); a <- a[!CNT %in% EXCLUDE]
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, female := female_any]; a[, `:=`(sex_f = female_any, escs = ESCS, imm = immigrant, home = HOMEPOS, langoth = lang_other)]
syst <- sort(unique(a$CNT)); log_step("design tests on", length(syst), "systems")
rb <- function(l) rbindlist(l[!vapply(l, is.null, logical(1))], fill = TRUE)
poolit <- function(d, by) d[, pool_iv(est, se), by = by]

# (a) by birth month
bm <- a[!is.na(LS), .(D = weighted.mean(D, W_FSTUWT), ACH = weighted.mean(PV1ACH, W_FSTUWT, na.rm = TRUE), LS = weighted.mean(LS, W_FSTUWT), n = .N), by = .(CNT, r)]
fwrite(bm[, .(D = mean(D), ACH = mean(ACH), LS = mean(LS), systems = .N, n = sum(n)), by = r][order(r)], orr("design_by_month.csv"))

# (b) reduced form and (c) balance: Z replaces D, so the term "tau" is the jump at the cutoff given the linear trend in r
jump <- function(cn, outs, ctrl) { s <- a[CNT == cn]; s[, D := Z]; rb(lapply(outs, function(o) tryCatch(
  data.table(CNT = cn, outcome = o, est_sys(s[!is.na(get(o))], o, ctrl = ctrl)[term == "tau"]), error = function(e) NULL))) }
rf <- rb(parallel::mclapply(syst, function(cn) { s <- a[CNT == cn & !is.na(LS)]; s[, `:=`(LS_z = zw(LS, W_FSTUWT))]
  x <- copy(s); x[, D := Z]; rb(lapply(c("ACH", "LS_z", "LS10"), function(o) tryCatch(data.table(CNT = cn, outcome = o, est_sys(x, o)[term == "tau"]), error = function(e) NULL))) }, mc.cores = 6))
fs <- rb(parallel::mclapply(syst, function(cn) { s <- a[CNT == cn & !is.na(LS)]; est_sys(s, "ACH")[term == "fs"][, `:=`(CNT = cn, outcome = "D")] }, mc.cores = 6))
red <- rbind(rf, fs, fill = TRUE); fwrite(red, orr("design_reduced_form_sys.csv"))
fwrite(poolit(red, "outcome"), orr("design_reduced_form_pool.csv"))
bal <- rb(parallel::mclapply(syst, function(cn) jump(cn, c("sex_f", "escs", "imm", "home", "langoth"), ctrl = character(0)), mc.cores = 6))
fwrite(bal, orr("design_balance_sys.csv")); fwrite(poolit(bal, "outcome"), orr("design_balance_pool.csv"))

# (d) density of birth months around the cutoff (students in the analytic file, unweighted and weighted)
den <- a[, .(n_below = sum(r == max(r[Z == 1])), n_above = sum(r == min(r[Z == 0])), w_below = sum(W_FSTUWT[r == max(r[Z == 1])]), w_above = sum(W_FSTUWT[r == min(r[Z == 0])])), by = CNT]
den[, ratio := n_below / n_above]; fwrite(den, orr("design_density_sys.csv"))

# (e) bandwidth: keep birth months with -b <= r < b (r < 0 is the lower side)
bw <- rb(parallel::mclapply(syst, function(cn) rb(lapply(c(99, 6, 4, 3), function(b) { s <- a[CNT == cn & !is.na(LS) & r >= -b & r < b]
  nb <- uniqueN(s[Z == 1, r]); na_ <- uniqueN(s[Z == 0, r]); if (nb < 1 || na_ < 1 || nrow(s) < 500) return(NULL)
  s[, LS_z := zw(LS, W_FSTUWT)]
  rb(lapply(c("LS_z", "ACH"), function(o) tryCatch(data.table(CNT = cn, window = b, months_below = nb, months_above = na_, n = nrow(s), outcome = o, est_sys(s, o)), error = function(e) NULL))) })), mc.cores = 6))
fwrite(bw, orr("design_bandwidth_sys.csv"))
cmp <- bw[term == "gamma" & ((window == 99) | (months_below >= 2 & months_above >= 2))]
ok <- cmp[window != 99, unique(CNT), by = window]
pl <- rb(lapply(c(6, 4, 3), function(b) { cn <- ok[window == b, V1]; if (!length(cn)) return(NULL)
  rbind(poolit(cmp[window == b & CNT %in% cn], "outcome")[, `:=`(window = paste0("|r| <= ", b), sample = "restricted window")],
        poolit(cmp[window == 99 & CNT %in% cn], "outcome")[, `:=`(window = paste0("|r| <= ", b), sample = "full window, same systems")], fill = TRUE) }))
fwrite(pl, orr("design_bandwidth_pool.csv")); log_step("done")
cat("\nReduced form and first stage, pooled (RE):\n"); print(poolit(red, "outcome")[, .(outcome, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 1), I2 = round(I2))])
cat("\nBalance at the cutoff, pooled (RE; should be ~0):\n"); print(poolit(bal, "outcome")[, .(outcome, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 1), sig = sig_pos + sig_neg)])
cat("\nDensity: ratio of the month just below to the month just above the cutoff; median", round(median(den$ratio), 2), " range", round(range(den$ratio), 2), "\n")
cat("\nBandwidth (gamma):\n"); print(pl[, .(window, sample, outcome, n_sys, re = round(re_mean, 3), se = round(re_se, 3))][order(outcome, window, sample)])
