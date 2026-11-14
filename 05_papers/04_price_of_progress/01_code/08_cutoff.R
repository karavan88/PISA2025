# The Cost of Resilience -- step 8: exogenous academic progression (school-entry cutoff IV)
# The cross-section cannot separate "high achievement lowers life satisfaction" from selection into high achievement. The grade-gain
# design gives an exogenous push forward: in the 20 systems of the grade-gain study, the actual grade D is instrumented by the theoretical
# grade Z implied by the school-entry cutoff and the birth month, with the running variable r linear (Avvisati & Givord 2021).
# gamma = b_D - 12 b_r is the effect of one extra grade at a given age (skillsgain/00_helpers.R::tsls_m / est_sys; BRR + Rubin).
# Questions:
#   base    does an extra grade change life satisfaction (mean, P(LS = 10), P(LS <= 4))?  ACH alongside for scale
#   lowses  is the effect different for bottom-quartile-SES students (gamma:lowSES)?  -- the causal analogue of the resilience gap
#   ses     same with continuous SES
#   se/cur  does the skill index / curiosity moderate it?
#   joint   lowSES + skill index
#   fe      base with school FE (same-school systems: within-school grade contrast)
# Exclusion is NOT "the grade works only through achievement": a grade also changes curriculum, peers and (in transition systems) the
# school. Read gamma(LS) as the effect of school progression; gamma(LS)/gamma(ACH) is a scaling, not an achievement effect.
# Output: cutoff_sys.csv, cutoff_pool.csv
source("05_papers/04_price_of_progress/01_code/00_helpers.R")   # load_sg, est_sys, tsls_m, pool_iv, survey helpers
a <- load_sg()
ls <- fread(STUDENTS, select = c("CNTSTUID", "ST016Q01NA"))
a <- merge(a, ls, by = "CNTSTUID", all.x = TRUE, sort = FALSE)
a <- a[!is.na(ST016Q01NA)]
a[, `:=`(LS = ST016Q01NA, LS10 = as.integer(ST016Q01NA == 10), LSle4 = as.integer(ST016Q01NA <= 4), lowSES = as.integer(SES_q == 1))]
a[, LS_z := zw(LS, W_FSTUWT), by = CNT]
STRUCT <- SYSTEMS()[, .(CNT, structure)]
# the grade moves the skills too, so the skill moderator is skillsgain's grade-purged index SE_p (SE net of the grade's own effect);
# curiosity is used raw (the grade effect on CURIO is small in the grade-gain report) -- treat its interaction with that caveat
SPECS <- list(base = character(0), lowses = "lowSES", ses = "SES", se = "SE_p", cur = "CURIO_z", joint = c("lowSES", "SE_p"))
OUTS <- c("LS_z", "LS10", "LSle4", "ACH")
log_step("cutoff IV on", uniqueN(a$CNT), "systems,", nrow(a), "students with life satisfaction")

one_system <- function(cn) {
  s0 <- a[CNT == cn]; res <- list()
  for (sp in names(SPECS)) {
    m <- SPECS[[sp]]
    s <- if (length(m)) s0[complete.cases(s0[, ..m])] else s0[!is.na(SES)]   # base on the SES sample so base and lowses compare
    if (nrow(s) < 500) next
    for (o in OUTS) res[[length(res) + 1]] <- tryCatch(data.table(CNT = cn, spec = sp, outcome = o, est_sys(s, o, mods = m)),
                                                      error = function(e) { message(cn, " ", sp, " ", o, ": ", conditionMessage(e)); NULL })
  }
  if (STRUCT[CNT == cn, structure] == "Same-school")
    for (o in c("LS_z", "ACH")) res[[length(res) + 1]] <- tryCatch(data.table(CNT = cn, spec = "fe", outcome = o, est_sys(s0[!is.na(SES)], o, fe = "school")),
                                                                  error = function(e) NULL)
  rbindlist(res, fill = TRUE)
}
res <- rbindlist(parallel::mclapply(unique(a$CNT), one_system, mc.cores = 6), fill = TRUE)
res <- merge(res, STRUCT, by = "CNT")
fwrite(res, orr("cutoff_sys.csv"))
pl <- rbind(res[, pool_iv(est, se), by = .(spec, outcome, term)][, set := "all 20"],
            res[structure == "Same-school", pool_iv(est, se), by = .(spec, outcome, term)][, set := "same-school 14"],
            res[structure == "Transition", pool_iv(est, se), by = .(spec, outcome, term)][, set := "transition 6"])
fwrite(pl, orr("cutoff_pool.csv"))
log_step("done")
show <- pl[term != "tau" & set != "transition 6"][order(set, spec, outcome, term)]
print(show[, .(set, spec, outcome, term, n_sys, re = round(re_mean, 3), se = round(re_se, 3), t = round(re_mean / re_se, 2), I2 = round(I2), sig_pos, sig_neg)], nrows = 300)
# scaling: life-satisfaction SD per 100 achievement points of an extra grade (RE means; descriptive)
sc <- dcast(pl[spec == "base" & term == "gamma"], set ~ outcome, value.var = "re_mean")
sc[, LS_per_100pts := 100 * LS_z / ACH]; print(sc)
