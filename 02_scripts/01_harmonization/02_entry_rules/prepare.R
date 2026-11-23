# Official school-entry rules from the pinned UIS snapshot, set against the PISA 2025 cohort.
# Shared rule construction only. The cutoff month read from PISA grades is not detected here: it is taken
# from the central cutoff definition (cutoff/eligibility.csv, prepare_cutoff_analytic.R). No model is estimated.
suppressPackageStartupMessages({library(data.table); library(jsonlite)})
setDTthreads(1)
HERE <- '02_scripts/01_harmonization/02_entry_rules'
OUT <- '03_outputs/04_entry_rules'; dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
pin <- fromJSON(file.path(HERE, 'uis_pin.json'))
snap <- file.path(Sys.getenv('PISA_DATA', '01_data'), 'external_uis', pin$file)
COHORT <- 2009L  # first birth year of the PISA 2025 cohort in every system

# ---- 1. UIS indicators, one row per country and year ----------------------------------------------
ind <- c('403' = 'start_month', '404' = 'end_month', '299905' = 'age_primary', '299932' = 'dur_primary',
         '999975' = 'age_lowsec', '999977' = 'age_upsec')
r <- as.data.table(fromJSON(snap)$records)
stopifnot(all(r$indicatorId %in% names(ind)))
r[, value := as.numeric(value)][!is.na(magnitude), value := NA_real_]  # NIL / NA are stored as 0
r[, var := ind[indicatorId]]
u <- dcast(r, geoUnit + year ~ var, value.var = 'value')
u[, dur_lowsec := age_upsec - age_lowsec]
setcolorder(u, c('geoUnit', 'year', 'age_primary', 'dur_primary', 'age_lowsec', 'dur_lowsec', 'age_upsec', 'start_month', 'end_month'))

# ---- 2. PISA systems and their UIS country ---------------------------------------------------------
p <- readRDS('03_outputs/01_harmonized/cutoff_provider.rds')
labs <- attr(p$CNT, 'labels'); sysname <- setNames(names(labs), as.character(labs))
d <- data.table(CNT = as.character(p$CNT), grade = as.numeric(p$ST001D01T), by = as.numeric(p$ST003D03T),
                bm = as.numeric(p$ST003D02T), age = as.numeric(p$AGE), rep = as.numeric(p$REPEAT),
                isced = as.numeric(p$ISCEDP), w = as.numeric(p$W_FSTUWT))
rm(p); invisible(gc())
d[by > 2100, by := by - 543]  # Buddhist-era years
# PISA entities that are part of a country take that country's national rule.
part_of <- c(QCI = 'CHN', QKI = 'IRQ', QTJ = 'TJK', QUA = 'UKR')
# Systems UIS does not report take a named neighbour's rule (user's decision, 2026-11-22).
proxy <- c(KSV = 'ALB', TAP = 'CHN')
other <- c(part_of, proxy)
sys <- data.table(CNT = sort(unique(d$CNT)))
sys[, `:=`(name = sysname[CNT], uis_geo = fifelse(CNT %in% names(other), other[CNT], CNT))]
sys[, uis_scope := fifelse(!uis_geo %in% u$geoUnit, 'not in UIS', fifelse(CNT %in% names(proxy), paste('proxy country:', uis_geo),
                   fifelse(CNT %in% names(part_of), 'national rule, regional sample', 'national')))]
sys[uis_scope == 'not in UIS', uis_geo := NA_character_]

long <- merge(sys[!is.na(uis_geo), .(CNT, name, uis_geo)], u, by.x = 'uis_geo', by.y = 'geoUnit')
setcolorder(long, c('CNT', 'name', 'uis_geo', 'year')); setorder(long, CNT, year)
fwrite(long, file.path(OUT, 'uis_rules_long.csv'))

# ---- 3. The rule that applied to the cohort --------------------------------------------------------
mo <- function(x) { x <- x[!is.na(x)]; if (!length(x)) NA_real_ else as.numeric(names(which.max(table(x)))) }
rule <- function(g) {
  z <- u[geoUnit == g]; at <- function(v, y) mo(z[year %in% y][[v]])
  # Entry age a is the one for which the official age in year COHORT + a equals a.
  cand <- Filter(function(a) isTRUE(at('age_primary', COHORT + a) == a), 4:8)
  a <- if (length(cand)) min(cand) else at('age_primary', COHORT + 6L)
  ey <- COHORT + a
  now <- function(v) { x <- z[year <= 2025 & !is.na(get(v))]; if (nrow(x)) x[which.max(year)][[v]] else NA_real_ }
  vars <- c('age_primary', 'dur_primary', 'age_lowsec', 'age_upsec')
  e <- sapply(vars, at, y = ey); n <- sapply(vars, now)
  ch <- vars[!is.na(e) & !is.na(n) & e != n]
  sm <- z[year >= ey - 1 & year <= 2025 & !is.na(start_month), start_month]
  # UIS start months flip in single years in some countries. At the test, take the most frequent value
  # of 2022-2025 and keep the entry-year value when it is among the most frequent.
  m_e <- at('start_month', (ey - 1):(ey + 1)); tb <- table(z[year %in% 2022:2025 & !is.na(start_month), start_month])
  m_t <- if (!length(tb)) m_e else if (!is.na(m_e) && as.character(m_e) %in% names(tb)[tb == max(tb)]) m_e else as.numeric(names(tb)[which.max(tb)])
  data.table(uis_geo = g, entry_age = a, entry_year = ey, entry_age_unique = length(cand) == 1L,
             dur_primary = e[['dur_primary']], age_lowsec = e[['age_lowsec']], age_upsec = e[['age_upsec']],
             dur_lowsec = e[['age_upsec']] - e[['age_lowsec']],
             levels_add_up = e[['age_primary']] + e[['dur_primary']] == e[['age_lowsec']],
             start_month_entry = m_e, end_month_entry = at('end_month', (ey - 1):(ey + 1)),
             start_month_test = m_t, end_month_test = at('end_month', 2022:2025),
             start_month_values = paste(sort(unique(sm)), collapse = ' '),
             dur_primary_2025 = n[['dur_primary']], age_lowsec_2025 = n[['age_lowsec']], age_upsec_2025 = n[['age_upsec']],
             structure_changed = if (length(ch)) paste(sprintf('%s %g>%g', ch, e[ch], n[ch]), collapse = '; ') else '')
}
rules <- rbindlist(lapply(na.omit(unique(sys$uis_geo)), rule))
sys <- merge(sys, rules, by = 'uis_geo', all.x = TRUE); setorder(sys, CNT)
setcolorder(sys, c('CNT', 'name', 'uis_geo', 'uis_scope'))

# ---- 4. The grade the rule assigns to each student -------------------------------------------------
# b, t: birth and test month as month counts. AGE is (test - birth) in years, so t follows exactly.
d[, `:=`(b = by * 12 + bm, t = round(by * 12 + bm + age * 12))]
d <- merge(d, sys[, .(CNT, a = entry_age, m_e = start_month_entry, m_t = start_month_test)], by = 'CNT')
# School year in session at the test: the one that started most recently.
d[, ys := (t - 1) %/% 12 - as.integer((t - 1) %% 12 + 1 < m_t)]
# Two readings of "official entrance age a", the only ones the UIS data support:
#  S  a child must have turned a before the school year starts (cutoff = start month of the school year);
#  C  a child enters in the calendar year in which they turn a (cutoff = 1 January).
d[, `:=`(gS = ys - (floor((b + 12 * a - m_e) / 12) + 1) + 1, gC = ys - (by + a) + 1)]

wm <- function(x, w) { ok <- !is.na(x) & !is.na(w); if (!any(ok)) NA_real_ else sum(x[ok] * w[ok]) / sum(w[ok]) }
ym <- function(i) if (!is.finite(i)) NA_character_ else sprintf('%d-%02d', as.integer((i - 1) %/% 12), as.integer((i - 1) %% 12 + 1))
one <- function(z) {
  z <- z[!is.na(grade) & !is.na(w)]
  if (!nrow(z)) return(NULL)
  gs <- z[, .(s = sum(w)), by = grade][, s := s / sum(s)][order(-s)]
  top <- sort(gs$grade[seq_len(min(2, nrow(gs)))])
  up <- z[!is.na(isced), .(s = wm(as.numeric(isced >= 300), w), n = .N), by = grade][n >= 30 & s > .5]
  res <- data.table(n_students = nrow(z), cohort_first = ym(suppressWarnings(min(z$b, na.rm = TRUE))),
    cohort_last = ym(suppressWarnings(max(z$b, na.rm = TRUE))), test_month = ym(mo(z$t)),
    modal_grade = gs$grade[1], share_modal = gs$s[1], second_grade = if (nrow(gs) > 1) gs$grade[2] else NA_real_,
    share_second = if (nrow(gs) > 1) gs$s[2] else 0, grades_5pct = sum(gs$s >= .05),
    share_repeated = wm(as.numeric(z$rep == 1), z$w),
    first_upsec_grade_pisa = if (nrow(up)) min(up$grade) else NA_real_)
  res[, top2_cross_levels := length(top) == 2 && !is.na(first_upsec_grade_pisa) && top[1] < first_upsec_grade_pisa && top[2] >= first_upsec_grade_pisa]
  k <- z[!is.na(gS)]
  if (!nrow(k)) return(res)
  fit <- c(S = wm(as.numeric(k$grade == k$gS), k$w), C = wm(as.numeric(k$grade == k$gC), k$w))
  # A whole-grade shift between the rule and the PISA grade (national grade 1 is not the first UIS primary
  # year, or the cohort entered at another age than UIS records) is reported, never silently absorbed.
  off <- function(g) k[, .(s = sum(w)), by = .(o = grade - g)][which.max(s), o]
  o <- c(S = off(k$gS), C = off(k$gC))
  fit_o <- c(S = wm(as.numeric(k$grade == k$gS + o[['S']]), k$w), C = wm(as.numeric(k$grade == k$gC + o[['C']]), k$w))
  use <- if (fit_o[['C']] > fit_o[['S']] + .02) 'C' else 'S'
  k[, g0 := (if (use == 'S') gS else gC) + o[[use]]]
  as_ <- k[, .(s = sum(w)), by = g0][, s := s / sum(s)][s >= .02][order(g0)]
  hi <- max(as_$g0); two <- nrow(as_) >= 2
  cbind(res, data.table(fit_S = fit[['S']], fit_C = fit[['C']], reading = use, grade_offset = o[[use]],
    assigned_grades = paste(as_$g0, collapse = '/'), share_assigned_upper = if (two) as_[g0 == hi, s] else NA_real_,
    # rule-based first stage: difference in mean actual grade between the two assigned grades
    grade_jump = if (two) wm(k[g0 == hi, grade], k[g0 == hi, w]) - wm(k[g0 == hi - 1, grade], k[g0 == hi - 1, w]) else NA_real_,
    share_on_rule = wm(as.numeric(k$grade == k$g0), k$w), share_behind = wm(as.numeric(k$grade < k$g0), k$w),
    share_ahead = wm(as.numeric(k$grade > k$g0), k$w),
    # students who never repeated: behind = entered late, ahead = entered early
    late_entry = wm(as.numeric(k[rep == 0, grade < g0]), k[rep == 0, w]),
    early_entry = wm(as.numeric(k[rep == 0, grade > g0]), k[rep == 0, w])))
}
pisa <- rbindlist(lapply(split(d, by = 'CNT'), one), fill = TRUE, idcol = 'CNT')
sys <- merge(sys, pisa, by = 'CNT', all.x = TRUE)
sys[, first_upsec_grade_uis := dur_primary_2025 + (age_upsec_2025 - age_lowsec_2025) + 1]

# ---- 4b. The cutoff month the PISA grades show (central cutoff definition, not re-derived here) ----
# pisa_cut is the first birth month on the lower-grade side. pisa_partial_month: the month before it is
# split between the two grades, so the cutoff falls inside that month.
CUT <- '03_outputs/01_harmonized/cutoff'
el <- fread(file.path(CUT, 'eligibility.csv')); au <- fread(file.path(CUT, 'cutoff_audit_all.csv'))
pc <- el[, .(CNT, pisa_cut = sprintf('%d-%02d', byear_cut, bmonth_cut), pisa_cut_month = bmonth_cut, pisa_jump = jump,
             pisa_partial_month = donut == 1, pisa_other_change = max_other, pisa_grades = paste(g_lo, g_hi, sep = '/'),
             pisa_eligible = eligible, pisa_reason = reason)]
sys <- merge(sys, au[, .(CNT, pisa_screen_jump = jump)], by = 'CNT', all.x = TRUE)
sys <- merge(sys, pc, by = 'CNT', all.x = TRUE)
sys[is.na(pisa_eligible) & !is.na(pisa_screen_jump), `:=`(pisa_eligible = FALSE, pisa_reason = 'no drop of 0.15 or more between adjacent birth months')]
sys[is.na(pisa_eligible), pisa_reason := 'not screened (no grade or birth month, or fewer than 500 students)']
# Month in which the UIS reading switches grade (S: school-year start month; C: January), and PISA minus UIS in months.
sys[, uis_cut_month := fifelse(reading == 'S', as.numeric(start_month_entry), fifelse(reading == 'C', 1, NA_real_))]
sys[, pisa_minus_uis_months := ((pisa_cut_month - uis_cut_month + 6) %% 12) - 6]
num <- names(sys)[sapply(sys, is.double)]
sys[, (num) := lapply(.SD, round, 3), .SDcols = num]
fwrite(sys, file.path(OUT, 'entry_rules.csv'))

# ---- 5. Grade by birth month, for figures and first-stage checks -----------------------------------
bmn <- d[!is.na(grade) & !is.na(b) & !is.na(w), .(n = .N, mean_grade = round(wm(grade, w), 3),
  grade_S = mo(gS), grade_C = mo(gC), share_repeated = round(wm(as.numeric(rep == 1), w), 3)), by = .(CNT, b)][order(CNT, b)]
bmn[, birth := sapply(b, ym)][, b := NULL]; setcolorder(bmn, c('CNT', 'birth'))
fwrite(bmn, file.path(OUT, 'grade_by_birth_month.csv'))
cat(nrow(sys), 'systems;', sys[uis_scope != 'not in UIS', .N], 'with a UIS rule;', sys[!is.na(reading), .N], 'set against PISA grades\n')
