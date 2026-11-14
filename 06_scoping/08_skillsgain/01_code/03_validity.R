# Skills & the Grade Gain -- validity of the design for a moderation analysis
# (1) Balance at the cutoff: the fixed-age contrast tau (2SLS of the variable on D, Z instrument, r linear) for predetermined characteristics
#     (sex, immigrant, SES, books, home language) must be zero; for the moderators (SE index, its parts, school SES) a non-zero tau means
#     the grade itself moves the moderator -- it is then partly an outcome and must be read with care (SE_p removes it).
# (2) Compliance by moderator: the first stage within quartiles of SE and SES. Interacted 2SLS needs the instrument to move grade in every group.
# (3) Baseline grade gain for the 20 systems on the common samples used later (controls: sex, immigrant, SES).
# (4) School structure: the weighted share of students whose school holds both grades (each 10-90% of its sampled cohort). Where the upper
#     grade sits in a different school (transition into upper secondary, often tracked), the school -- and its SES -- is partly an outcome of
#     the grade, so school SES cannot be read as a moderator there. Systems with share >= 0.5 are "same-school", the rest "transition".
# Output: 03_outputs/skillsgain/balance.csv, fs_by_group.csv, baseline.csv, structure.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/skillsgain/00_helpers.R")
a <- load_sg()
sc <- a[, .(pD = wmean(D, W_FSTUWT), w = sum(W_FSTUWT)), by = .(CNT, school)][, mixed := pD >= 0.1 & pD <= 0.9]
structure <- sc[, .(share_mixed_students = sum(w * mixed) / sum(w), share_mixed_schools = mean(mixed), schools = .N), by = CNT]
structure[, structure := fifelse(share_mixed_students >= 0.5, "Same-school", "Transition")]
structure[, `:=`(name = SYS_NAMES[CNT], group = GROUP[CNT])]
fwrite(structure[order(share_mixed_students)], os("structure.csv")); print(structure[order(share_mixed_students)])
BAL <- c("female", "immigrant", "lang_other", "SES", "books_z", "schSES", "SE", "SE_task", "SE_open", "SE_p", SE6)
bal <- list(); fsg <- list(); base <- list()
for (cn in SYS20) {
  s <- a[CNT == cn]
  for (v in BAL) {
    if (mean(!is.na(s[[v]])) < 0.3) next
    e <- est_sys(s, v, ctrl = character(0))
    bal[[length(bal) + 1]] <- data.table(CNT = cn, var = v, e)
  }
  for (g in c("SE_q", "SES_q")) for (q in 1:4) {
    ss <- s[get(g) == q]; if (nrow(ss) < 150) next
    e <- est_sys(ss, "ACH", ctrl = c("female", "immigrant"))
    fsg[[length(fsg) + 1]] <- data.table(CNT = cn, by = g, q = q, e[term %in% c("fs", "gamma")])
  }
  for (o in c("ACH", DOMS)) {
    e1 <- est_sys(s, o, ctrl = c("female", "immigrant", "SES")); base[[length(base) + 1]] <- data.table(CNT = cn, outcome = o, sample = "all", e1)
    ss <- s[!is.na(SE) & !is.na(SES) & !is.na(schSES)]
    if (nrow(ss) > 500) { e2 <- est_sys(ss, o, ctrl = c("female", "immigrant", "SES")); base[[length(base) + 1]] <- data.table(CNT = cn, outcome = o, sample = "skills", e2) }
  }
  log_step(cn, "done")
}
bal <- rbindlist(bal); fsg <- rbindlist(fsg); base <- rbindlist(base)
for (x in list(bal, fsg, base)) x[, `:=`(name = SYS_NAMES[CNT], group = GROUP[CNT])]
fwrite(bal, os("balance.csv")); fwrite(fsg, os("fs_by_group.csv")); fwrite(base, os("baseline.csv"))
print(dcast(bal[term == "tau"], CNT ~ var, value.var = "est", fun.aggregate = function(x) round(x[1], 2))[, c("CNT", "female", "SES", "schSES", "SE", "SE_p"), with = FALSE])
print(bal[term == "tau", .(sig = sum(abs(est / se) > 1.96), n = .N), by = var])
print(dcast(base[term == "gamma" & sample == "all"], CNT ~ outcome, value.var = "est", fun.aggregate = function(x) round(x[1], 1)))
