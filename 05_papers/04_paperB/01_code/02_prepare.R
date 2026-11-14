# Paper B -- analytic file: cutoff detection, running variable, treatment, within-system standardised outcomes
# Input : 01_data/derived/paperB_students.csv.gz (01_build.py)
# Output: 01_data/derived/paperB_analytic.rds; 03_outputs/paperB/cutoffs.csv (one row per system), compliance.csv (P(upper grade) by birth month)
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
d <- fread("01_data/derived/paperB_students.csv.gz")
d <- d[CNT %in% SYS & !is.na(grade) & !is.na(bmonth) & !is.na(byear)]
d[, t := byear * 12 + bmonth]                                        # absolute birth month

# ---- the two main grades and the treatment: being in the upper of the two grades that hold the cohort -----------------------
gr <- d[, .(w = sum(W_FSTUWT)), by = .(CNT, grade)][order(CNT, -w)]
gr <- gr[, .(g_lo = min(grade[1:2]), g_hi = max(grade[1:2]), share_two = sum(w[1:2]) / sum(w)), by = CNT]
d <- merge(d, gr, by = "CNT")
d[, D := as.numeric(grade >= g_hi)]                                  # treatment: upper grade = one more year of schooling by age 15

# ---- compliance profile and cutoff detection: the month with the largest drop in P(D = 1) between adjacent birth months -------
comp <- d[, .(p = wmean(D, W_FSTUWT), n = .N, w = sum(W_FSTUWT)), by = .(CNT, t)][order(CNT, t)]
comp[, drop := shift(p) - p, by = CNT]
cut <- comp[!is.na(drop) & n >= 30, .SD[which.max(drop)], by = CNT][, .(CNT, t_cut = t, jump = drop, p_first_low = p)]
cut <- merge(cut, comp[, .(CNT, t_prev = t + 1, p_before = p)], by.x = c("CNT", "t_cut"), by.y = c("CNT", "t_prev"))
# partial cutoff month: if P(D=1) in the first low month is between .2 and .8 the rule bites inside the month -> that month is a donut
cut[, donut := as.integer(p_first_low > .2 & p_first_low < .8)]
cut[, `:=`(byear_cut = (t_cut - 1) %/% 12, bmonth_cut = (t_cut - 1) %% 12 + 1)]
cut[, cut_label := paste(month.abb[bmonth_cut], byear_cut)]
d <- merge(d, cut[, .(CNT, t_cut, donut)], by = "CNT")
d[, r := t - t_cut]                                                  # running variable: months from the first post-cutoff birth month (r >= 0: born after the cutoff)
d[, Z := as.numeric(r < 0)]                                          # instrument: born before the cutoff
supp <- d[, .(n_left = uniqueN(t[r < 0]), n_right = uniqueN(t[r >= 0])), by = CNT]   # months of support on each side
cut <- merge(cut, supp, by = "CNT"); cut <- merge(cut, gr, by = "CNT")
# a partial cutoff month can only be dropped if another post-cutoff month remains; where the cutoff sits at the edge of the cohort
# (Chile, Israel, Montenegro, New Zealand: one month after the cutoff) the partial month is kept and the fuzzy first stage absorbs it
cut[, donut_flag := donut]; cut[n_right < 2, donut := 0L]
d[, donut := NULL]; d <- merge(d, cut[, .(CNT, donut)], by = "CNT")
cut[, system := SYS_NAMES[CNT]][, region := REGION[CNT]][, tier := TIER[CNT]]
setcolorder(cut, c("CNT", "system", "region", "tier", "g_lo", "g_hi", "share_two", "cut_label", "p_before", "p_first_low", "jump", "donut", "donut_flag", "n_left", "n_right"))
fwrite(cut, op("cutoffs.csv")); print(cut[, .(CNT, g_lo, g_hi, cut_label, p_before = round(p_before, 2), p_first_low = round(p_first_low, 2), jump = round(jump, 2), donut, n_left, n_right)])
comp <- merge(comp, cut[, .(CNT, t_cut)], by = "CNT"); comp[, r := t - t_cut]; comp[, system := SYS_NAMES[CNT]]
fwrite(comp, op("compliance.csv"))

# ---- outcomes: within-system standardisation of the WLE scales (final student weights, whole national sample) ----------------
for (s in c(skill_wle, "BELONG")) d[, paste0(s, "_z") := (get(s) - wmean(get(s), W_FSTUWT)) / wsd(get(s), W_FSTUWT), by = CNT]
d[, ESCS_z := (ESCS - wmean(ESCS, W_FSTUWT)) / wsd(ESCS, W_FSTUWT), by = CNT]
d[, CNT := factor(CNT, levels = SYS)]
saveRDS(d, "01_data/derived/paperB_analytic.rds")
cat("\nanalytic file:\n"); print(d[, .(n = .N, share_D = round(wmean(D, W_FSTUWT), 2), skills_ok = round(mean(complete.cases(.SD[, ..out_skills])), 2), voc = round(mean(vocational), 2)), by = CNT])
