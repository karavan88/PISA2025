# Grade Gain Report -- analytic file: cutoff detection and eligibility on the analysis sample (all programmes), running variable,
# theoretical grade, school-starting age, within-system standardised skill scales.
# Input : 01_data/derived/gradegain_students.csv.gz (01_build.py, all candidate systems)
# Output: 01_data/derived/gradegain_analytic.rds (eligible systems only); 03_outputs/gradegain/eligibility.csv (every candidate, with the verdict),
#         compliance.csv (P(upper grade) and weighted N by birth month, every candidate)
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/01_harmonization/cutoff_definitions.R")
d <- readRDS("03_outputs/01_harmonized/cutoff/students.rds")
d <- d[!is.na(grade) & !is.na(bmonth) & !is.na(byear)]
d[, t := byear * 12 + bmonth]
# the two grades that hold the cohort; the treatment is the upper one
gr <- d[, .(w = sum(W_FSTUWT)), by = .(CNT, grade)][order(CNT, -w)][, .(g_lo = min(grade[1:2]), g_hi = max(grade[1:2]), share_two = sum(w[1:2]) / sum(w)), by = CNT]
d <- merge(d, gr, by = "CNT"); d[, D := as.numeric(grade >= g_hi)]
# compliance profile and the largest adjacent-month drop
comp <- d[, .(p = wmean(D, W_FSTUWT), n = .N, w = sum(W_FSTUWT)), by = .(CNT, t)][order(CNT, t)]
comp[, chg := p - shift(p), by = CNT]                                    # change from the previous month (a cutoff shows as a large negative change)
# A cutoff that falls inside a month splits the drop over two adjacent months (the month itself is partial: 0.2 < P < 0.8). The jump is therefore
# measured both over one month and over two months around a partial month; the larger wins. A partial cutoff month is excluded from the
# estimation (donut) when at least one clean month remains on its side; at the edge of the cohort it is kept and the fuzzy first stage absorbs it.
detect <- function(p, t, n) {
  ok <- n >= 30; p <- p[ok]; t <- t[ok]; k <- length(p)
  if (k < 3) return(list(t_cut = NA_real_, jump = NA_real_, p_before = NA_real_, p_first_low = NA_real_, donut = NA_integer_, max_other = NA_real_, n_left = NA_integer_, n_right = NA_integer_))
  one <- data.table(j = 2:k, jump = p[1:(k - 1)] - p[2:k], donut = 0L)
  two <- if (k >= 3) data.table(j = 3:k, jump = p[1:(k - 2)] - p[3:k], donut = 1L)[p[2:(k - 1)] > .2 & p[2:(k - 1)] < .8] else NULL
  cand <- rbind(one, two)[order(-jump)][1]
  j <- cand$j; donut <- cand$donut
  excl <- if (donut == 1) c(j - 1, j) else j                            # months whose changes belong to the cutoff itself
  chg <- p[2:k] - p[1:(k - 1)]; idx <- 2:k
  other <- abs(chg[!idx %in% excl])
  list(t_cut = t[j], jump = cand$jump, p_before = p[j - 1 - donut], p_first_low = p[j], donut = donut, max_other = if (length(other)) max(other) else 0,
       n_left = sum(t < t[j]) - donut, n_right = sum(t >= t[j]))
}
elig <- comp[, detect(p, t, n), by = CNT]
elig[, partial_first := !is.na(p_first_low) & p_first_low > .2 & p_first_low < .8]
elig[, partial_before := !is.na(p_before) & p_before > .2 & p_before < .8]
elig[, usable_right := n_right - as.integer(partial_first)]              # clean months after the cutoff
elig[, usable_left := n_left - as.integer(partial_before)]
# at the edge of the cohort a side may consist of partial months only; they are then kept (the fuzzy first stage absorbs them) and the system is flagged "edge"
elig[, edge := !is.na(jump) & (usable_right < ELIG$min_side | usable_left < ELIG$min_side) & n_right >= 1 & n_left >= 1]
elig[, reason := fifelse(is.na(jump) | n_left < 1 | n_right < 1, "no month on one side of the cutoff",
               fifelse(jump < ELIG$min_jump, "jump below 0.20",
               fifelse(max_other > ELIG$clean_ratio * jump, "not a single clean cutoff (other changes of comparable size)",
               fifelse(edge, "eligible (edge: partial month kept on one side)", "eligible"))))]
elig[, eligible := reason %like% "^eligible"]
# the partial month inside the cutoff is dropped (donut) only if a clean month remains on its side; the partial first-low month likewise
elig[, drop_month := fifelse(donut == 1 & usable_left >= 1, t_cut - 1, fifelse(partial_first & usable_right >= 1, t_cut, NA_real_))]
elig[, `:=`(byear_cut = (t_cut - 1) %/% 12, bmonth_cut = (t_cut - 1) %% 12 + 1)]; elig[, cut_label := paste(month.abb[bmonth_cut], byear_cut)]
elig <- merge(elig, gr, by = "CNT"); elig <- merge(elig, SYSINFO[, .(CNT, name, OECD, audit_jump)], by = "CNT")
elig[, region := REGION[CNT]]
setcolorder(elig, c("CNT", "name", "region", "OECD", "eligible", "edge", "reason", "g_lo", "g_hi", "cut_label", "p_before", "p_first_low", "jump", "donut", "drop_month", "max_other", "n_left", "n_right", "usable_left", "usable_right", "audit_jump"))
fwrite(elig[order(-eligible, -jump)], op("eligibility.csv"))
cat("eligible:", sum(elig$eligible), "of", nrow(elig), "\n"); print(elig[order(-eligible, -jump), .(CNT, eligible, reason = substr(reason, 1, 28), cut_label, jump = round(jump, 2), donut, other = round(max_other, 2), n_left, n_right)], nrows = 60)
comp <- merge(comp, elig[, .(CNT, t_cut, eligible)], by = "CNT"); comp[, r := t - t_cut]; comp[, name := SYS_NAMES[CNT]]
fwrite(comp, op("compliance.csv"))

# analytic file for the eligible systems
a <- merge(d, elig[eligible == TRUE, .(CNT, t_cut, drop_month)], by = "CNT")
a <- a[is.na(drop_month) | t != drop_month]                              # donut: the partial cutoff month
a[, r := t - t_cut]                                                      # months from the first post-cutoff birth month (r >= 0: born after the cutoff)
a[, Z := as.numeric(r < 0)]                                              # theoretical upper grade (born before the cutoff)
a[, ssa := -r - 12 * D]                                                  # school-starting age in months, up to a system constant: younger at entry if born later or if in the upper grade
for (s in skill_wle) a[, paste0(s, "_z") := (get(s) - wmean(get(s), W_FSTUWT)) / wsd(get(s), W_FSTUWT), by = CNT]
a[, ESCS_z := (ESCS - wmean(ESCS, W_FSTUWT)) / wsd(ESCS, W_FSTUWT), by = CNT]
saveRDS(a, "03_outputs/01_harmonized/cutoff/analytic.rds")
cat("\nanalytic file:\n"); print(a[, .(n = .N, share_D = round(wmean(D, W_FSTUWT), 2), escs = round(mean(!is.na(ESCS)), 2), skills = round(mean(!is.na(CURIO)), 2), persev = round(mean(!is.na(PERSEV)), 2)), by = CNT])
