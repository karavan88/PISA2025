# The price of progress -- step 14: the headline gamma with predetermined covariates added, in the full window and the bandwidth windows.
# Base controls (08b): sex, immigrant background. Added here: ESCS, home possessions (HOMEPOS), language other than the test language.
# They are predetermined, so adding them changes precision and any chance imbalance at the cutoff (13_design_tests.R), not the target.
# Same design, estimator and pooling as 08b/13; a student with a missing added control drops out of that specification (n reported).
# Writes to $PAPER_OUT (a NEW directory): covariates_sys.csv, covariates_pool.csv.
source("05_papers/04_price_of_progress/01_code/00_helpers.R")   # est_sys, tsls_m, pool_iv, survey helpers; PAPER_OUT sets OUTR
source("05_papers/04_price_of_progress/01_code/sample_rules.R") # EXCLUDE (Ukraine), FLAG (Israel)
a <- readRDS("05_papers/04_price_of_progress/04_output/cutoff35_students.rds"); setDT(a); a <- a[!is.na(LS) & !CNT %in% EXCLUDE]
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, `:=`(female = female_any, escs = ESCS, home = HOMEPOS, langoth = lang_other, imm = immigrant)]
eligible <- fread(file.path(Sys.getenv("PAPER_DESIGN", "05_papers/04_price_of_progress/05_archive/estimate_20261115_central35"), "design35.csv"))   # from 12_design.R
strict <- merge(eligible, fread("05_papers/02_fuzzy_rd_learning/02_results/eligibility.csv")[, .(CNT, edge)], by = "CNT")[!edge & pmin(months_below, months_above) >= 2, CNT]
CT <- list(base = c("female", "immigrant"), plus = c("female", "immigrant", "escs", "home", "langoth"))
rb <- function(l) rbindlist(l[!vapply(l, is.null, logical(1))], fill = TRUE)
log_step("covariate specifications on", uniqueN(a$CNT), "systems")
res <- rb(parallel::mclapply(sort(unique(a$CNT)), function(cn) rb(lapply(c(99, 6, 4, 3), function(b) {
  s <- a[CNT == cn & r >= -b & r < b]; if (uniqueN(s[Z == 1, r]) < 1 || uniqueN(s[Z == 0, r]) < 1 || nrow(s) < 500) return(NULL)
  s[, LS_z := zw(LS, W_FSTUWT)]
  rb(lapply(names(CT), function(sp) rb(lapply(c("LS_z", "ACH"), function(o) tryCatch(
    data.table(CNT = cn, window = b, spec = sp, outcome = o, months_below = uniqueN(s[Z == 1, r]), months_above = uniqueN(s[Z == 0, r]), n = nrow(s), est_sys(s, o, ctrl = CT[[sp]])[term == "gamma"]),
    error = function(e) { message(cn, " ", b, " ", sp, " ", o, ": ", conditionMessage(e)); NULL }))))) })), mc.cores = 6))
fwrite(res, orr("covariates_sys.csv"))
res[, ok := window == 99 | (months_below >= 2 & months_above >= 2)]
pl <- rbind(res[window == 99, pool_iv(est, se), by = .(spec, outcome, window)][, set := "all (sample rules)"],
            res[window == 99 & CNT %in% strict, pool_iv(est, se), by = .(spec, outcome, window)][, set := "strict design"],
            res[window != 99 & ok & CNT %in% strict, pool_iv(est, se), by = .(spec, outcome, window)][, set := "strict design"])
fwrite(pl, orr("covariates_pool.csv")); log_step("done")
print(pl[, .(set, window = ifelse(window == 99, "full", paste0("|r|<=", window)), outcome, spec, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 1))][order(outcome, set, -nchar(window), window, spec)], nrows = 100)
