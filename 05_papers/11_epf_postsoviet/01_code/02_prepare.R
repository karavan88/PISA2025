# EPF post-Soviet paper -- analytic sample, skill domain scores, inverse-probability weights for skill non-response
# Input : 01_data/derived/epf_students.csv.gz (from 01_build.py)   Output: 01_data/derived/epf_analytic.rds + 03_outputs/epf_postsoviet/sample_flow.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/epf_postsoviet/00_helpers.R")
d <- fread("01_data/derived/epf_students.csv.gz")
d[, CNT := factor(CNT, levels = PS)]
setnames(d, "repeat", "repeated")   # `repeat` is an R reserved word: inside a formula it parses as a loop
d[, bmonth := factor(bmonth, levels = 1:12, labels = month.abb)]
d[, school := factor(school)]
d[, ses_q := factor(ses_q, levels = 1:5, labels = paste0("Q", 1:5))]

# ---- sample flow (kept per system for the attrition table) ----------------------------------------------------------
flow <- d[, .(step = c("All sampled students", "General programme (ISCED 244/344)", "Modal grade +/- 1", "ESCS observed", "Birth month, sex, school covariates observed", "All skill scales observed (skills sample)"),
              n = c(.N, sum(general == 1), sum(in_window == 1), sum(in_window == 1 & !is.na(ESCS)),
                    sum(in_window == 1 & !is.na(ESCS) & !is.na(bmonth) & !is.na(female) & !is.na(sch_escs_loo) & !is.na(rural) & !is.na(clsize) & !is.na(proatce)),
                    sum(in_window == 1 & !is.na(ESCS) & !is.na(bmonth) & !is.na(female) & !is.na(sch_escs_loo) & !is.na(rural) & !is.na(clsize) & !is.na(proatce) & skills_complete == 1))), by = CNT]
flow[, share := round(n / n[1], 3), by = CNT]
dir.create("03_outputs/epf_postsoviet", showWarnings = FALSE, recursive = TRUE)
fwrite(flow, "03_outputs/epf_postsoviet/sample_flow.csv")
print(dcast(flow, step ~ CNT, value.var = "n"))

# ---- core analytic sample: grade window, ESCS, controls ----------------------------------------------------------------
# School covariates with missing values are imputed at the system median so that principal non-response does not drop whole schools;
# a missing indicator is kept for the sensitivity check. Student covariates are not imputed.
sch_num <- c("clsize", "stratio_med", "proatce", "STAFFSHORT", "EDUSHORT")
for (v in sch_num) { d[, paste0(v, "_miss") := as.integer(is.na(get(v)))]; d[, (v) := fifelse(is.na(get(v)), median(get(v), na.rm = TRUE), get(v)), by = CNT] }
for (v in c("rural", "private", "infra_poor", "sel_policy")) d[, (v) := fifelse(is.na(get(v)), 0, get(v))]
a <- d[in_window == 1 & !is.na(ESCS) & !is.na(bmonth) & !is.na(female) & !is.na(sch_escs_loo)]
a[, lang_other := fifelse(is.na(lang_other), 0, lang_other)]; a[, immigrant := fifelse(is.na(immigrant), 0, immigrant)]; a[, repeated := fifelse(is.na(repeated), 0, repeated)]
a[, grade_c := as.numeric(grade_c)]

# ---- skills: standardise to the analytic sample (senate weights: each system counts equally), then domain scores -------------
# PERSEV was not fielded in Kazakhstan: the task-performance score there is the mean of SELFREG and GOALSET.
a[, w_senate := SENWT]
wz <- function(x, w) { m <- wmean(x, w); s <- wsd(x, w); (x - m) / s }
for (s in skill_wle) a[, paste0(s, "_z") := wz(get(s), w_senate)]
a[, task  := rowMeans(cbind(PERSEV_z, SELFREG_z, GOALSET_z), na.rm = TRUE)]
a[persev_fielded == 0, task := rowMeans(cbind(SELFREG_z, GOALSET_z), na.rm = TRUE)]
a[, open  := rowMeans(cbind(CURIO_z, ENPROBS_z), na.rm = TRUE)]
a[, adapt := COGABIL_z]
a[is.nan(task), task := NA_real_]; a[is.nan(open), open := NA_real_]
for (s in c("task", "open", "adapt")) a[, (s) := wz(get(s), w_senate)]      # domain scores in SD units of the pooled sample
a[, skills_ok := as.integer(skills_complete == 1 & !is.na(task) & !is.na(open) & !is.na(adapt) & !is.na(growth))]

# ---- inverse-probability weights for the skills sample (per system; response model includes the PV1 outcome) --------------
a[, ipw := 1]
for (c in levels(a$CNT)) {
  s <- a[CNT == c]
  if (nrow(s) == 0) next
  rhs <- c("ESCS_pct10", "female", "grade_c", "immigrant", "lang_other", "repeated", "rural", "private", "rus_medium", "sch_escs_loo", "PV1SCIE")
  rhs <- rhs[sapply(rhs, function(v) sd(s[[v]], na.rm = TRUE) > 0)]
  m <- glm(as.formula(paste("skills_ok ~", paste(rhs, collapse = "+"))), data = s, family = quasibinomial, weights = W_FSTUWT / mean(W_FSTUWT))
  p <- fitted(m)
  ipw_c <- mean(s$skills_ok) / p                                      # stabilised
  ipw_c <- pmin(ipw_c, quantile(ipw_c, .99))                          # trimmed at the 99th percentile
  a[CNT == c, ipw := ipw_c]
}
a[skills_ok == 0, ipw := NA_real_]
a[, w_skills := W_FSTUWT * ipw]

# school-composition terciles (schools weighted equally within system, on leave-one-out school mean of ESCS)
sch <- unique(a[, .(CNT, school, sch_escs_mean)])
sch[, sch_ter := cut(sch_escs_mean, quantile(sch_escs_mean, c(0, 1/3, 2/3, 1), na.rm = TRUE), include.lowest = TRUE, labels = c("T1 (low)", "T2", "T3 (high)")), by = CNT]
a <- merge(a, sch[, .(CNT, school, sch_ter)], by = c("CNT", "school"), all.x = TRUE)

saveRDS(a, "01_data/derived/epf_analytic.rds")
cat("\nanalytic sample:\n"); print(a[, .(n = .N, schools = uniqueN(school), skills_n = sum(skills_ok), grade_below = round(mean(grade_c < 0), 3), grade_above = round(mean(grade_c > 0), 3),
                                        task_sd = round(sd(task, na.rm = TRUE), 2), ipw_max = round(max(ipw, na.rm = TRUE), 2)), by = CNT])
