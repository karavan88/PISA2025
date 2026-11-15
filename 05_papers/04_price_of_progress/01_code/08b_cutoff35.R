# The price of progress -- step 8b: school-entry cutoff IV on the central 35-system input layer (01_inputs.R). Base specification only.
# Headline estimand (user decision, 2026-11-15): gamma = b_D - 12 b_r, the grade gain with starting age fixed (Avvisati & Givord 2021).
# tau = b_D (grade with birth month fixed; also a year younger at entry and the youngest in class) is saved beside it, never the headline.
# Sample: students with life satisfaction. No SES restriction (the central file has no SES composite; the legacy base spec used the SES sample).
# Achievement ACH = mean of the science, maths and reading plausible values, built per plausible value, as in the legacy build.
# Output: cutoff35_sys.csv (per system), cutoff35_pool.csv (DerSimonian-Laird; all 35, and the 20 systems of the earlier analysis).
source("05_papers/04_price_of_progress/01_code/00_helpers.R")   # est_sys, tsls_m, pool_iv, survey helpers; PAPER_OUT sets OUTR
a <- readRDS("05_papers/04_price_of_progress/04_output/cutoff35_students.rds")
setDT(a); a <- a[!is.na(LS)]
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, female := female_any]                      # sex from the sampling frame where ST004D01T is withheld (est_sys drops a control missing for >50%)
OUTS <- c("LS_z", "LS10", "LSle4", "ACH")
log_step("cutoff IV on", uniqueN(a$CNT), "systems,", nrow(a), "students with life satisfaction")
one_system <- function(cn) {
  s <- a[CNT == cn]; if (nrow(s) < 500) return(NULL)
  rbindlist(lapply(OUTS, function(o) tryCatch(data.table(CNT = cn, spec = "base", outcome = o, est_sys(s, o)),
                                              error = function(e) { message(cn, " ", o, ": ", conditionMessage(e)); NULL })))
}
res <- rbindlist(parallel::mclapply(sort(unique(a$CNT)), one_system, mc.cores = 6), fill = TRUE)
fwrite(res, orr("cutoff35_sys.csv"))
OLD20 <- SYSTEMS()$CNT
pl <- rbind(res[, pool_iv(est, se), by = .(spec, outcome, term)][, set := "all 35"],
            res[CNT %in% OLD20, pool_iv(est, se), by = .(spec, outcome, term)][, set := "the 20 earlier systems"],
            res[!CNT %in% OLD20, pool_iv(est, se), by = .(spec, outcome, term)][, set := "the other 15"])
fwrite(pl, orr("cutoff35_pool.csv")); log_step("done")
print(pl[term %in% c("gamma", "tau", "fs")][order(set, outcome, term)][, .(set, outcome, term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 2), I2 = round(I2), sig_pos, sig_neg)], nrows = 100)
