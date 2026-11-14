# Paper A -- prepare analytic sample
# Reads 01_data/derived/paperA_students.csv(.gz), defines analytic sample, standardises skills, saves RDS.
suppressPackageStartupMessages({library(data.table)})
args <- commandArgs(trailingOnly = TRUE)
IN  <- if (length(args) >= 1) args[1] else "01_data/derived/paperA_students.csv"
OUT <- if (length(args) >= 2) args[2] else "01_data/derived/paperA_analytic.rds"

d <- fread(IN)
d[, bloc := factor(bloc, levels = c("East Asia", "Post-Soviet", "Post-communist Europe"))]
d[, CNT := factor(CNT)]
d[, economy := factor(economy)]
d[, school := ifelse(is.na(CNTSCHID), paste0("MAC_", CNTSTUID), as.character(CNTSCHID))] # Macao: no school id in PUF
d[, escs_grp := factor(escs_grp, levels = 1:3, labels = c("Bottom 40%", "Middle 50%", "Top 10%"))]

# growth mindset: ST420Q01 "You have a certain amount of intelligence, and you really can't do much to change it" (1 strongly disagree .. 4 strongly agree)
# A single item, so it is not scaled: GROWTH = 1 if the student disagrees or strongly disagrees (holds a growth mindset), 0 otherwise.
d[, GROWTH := fifelse(is.na(ST420Q01DA), NA_integer_, as.integer(ST420Q01DA %in% c(1, 2)))]
wle_skills <- c("PERSEV", "CURIO", "ENPROBS", "COGABIL", "GOALSET", "SELFREG")
skills <- c(wle_skills, "GROWTH")
setnames(d, "repeat", "repeated")
controls <- c("female", "AGE", "grade_rel", "repeated", "immig2", "lang_other")

# ESCS as a within-system percentile rank (0-100, final student weights, on every student with ESCS) and its leave-one-out school mean,
# computed on the full national sample before listwise deletion (as sch_escs_loo was). ESCS_pct10 = rank / 10: one unit = 10 percentile points.
wrank <- function(x, w) { r <- rep(NA_real_, length(x)); ok <- !is.na(x) & !is.na(w); o <- order(x[ok]); cw <- cumsum(w[ok][o]); r[ok][o] <- 100 * (cw - 0.5 * w[ok][o]) / sum(w[ok]); r }
d[, ESCS_pct := wrank(ESCS, W_FSTUWT), by = CNT]; d[, ESCS_pct10 := ESCS_pct / 10]
loo <- function(x) { n <- sum(!is.na(x)); if (n <= 1) return(x); (sum(x, na.rm = TRUE) - x) / (n - 1) }
d[, sch_pct_loo := loo(ESCS_pct10), by = .(CNT, school)]
# Material deprivation: number of items the family "cannot afford" (code 2) among the deprivation items fielded in the system
# (ST488Q01/02/08/09 everywhere; ST401Q03-07 are national options, so systems fielded 4 to 6 items). Fielded = answered by >= 90% of
# the system's students who answered any deprivation item; DEP is missing when any fielded item is unanswered. dep_items = number of fielded items.
dep_items_all <- c("ST488Q01DA", "ST488Q02DA", "ST488Q08DA", "ST488Q09DA", "ST401Q03DA", "ST401Q04DA", "ST401Q05DA", "ST401Q06DA", "ST401Q07DA")
fielded_items <- function(M) { any_ans <- rowSums(!is.na(M)) > 0; colMeans(!is.na(M[any_ans, , drop = FALSE])) >= 0.9 }   # among students who reached the module
d[, DEP := { M <- as.matrix(.SD); M <- M[, fielded_items(M), drop = FALSE]; ifelse(rowSums(is.na(M)) > 0, NA_real_, rowSums(M == 2)) }, .SDcols = dep_items_all, by = CNT]
d[, dep_items := { M <- as.matrix(.SD); sum(fielded_items(M)) }, .SDcols = dep_items_all, by = CNT]
d[, sch_dep_loo := loo(DEP), by = .(CNT, school)]
print(d[, .(items = dep_items[1], dep_mean = round(mean(DEP, na.rm = TRUE), 2), dep_any = round(mean(DEP > 0, na.rm = TRUE), 2), miss = round(mean(is.na(DEP)), 3)), by = CNT])

# economies where PERSEV was not fielded
persev_missing <- d[, .(share = mean(!is.na(PERSEV))), by = CNT][share < 0.05, as.character(CNT)]
cat("PERSEV not fielded in:", persev_missing, "\n")
d[, persev_fielded := !(CNT %in% persev_missing)]

# analytic sample: ESCS, all fielded skills (incl. the growth-mindset item), controls, science PV, weight
core_skills <- setdiff(skills, "PERSEV")
d[, complete := !is.na(ESCS) & !is.na(W_FSTUWT) & !is.na(PV1SCIE) &
      complete.cases(.SD[, ..core_skills]) & complete.cases(.SD[, ..controls]) &
      (!persev_fielded | !is.na(PERSEV))]
cov <- d[, .(N_all = .N, N_analytic = sum(complete), share = round(mean(complete), 3),
             sci_all = round(mean(PV1SCIE, na.rm = TRUE)), sci_analytic = round(mean(PV1SCIE[complete], na.rm = TRUE))), by = .(bloc, CNT, economy)]
print(cov)
dir.create("03_outputs/paperA/tables", recursive = TRUE, showWarnings = FALSE); fwrite(cov, "03_outputs/paperA/tables/t_sample_coverage.csv")

a <- d[complete == TRUE]

# Rescaling of the WLE skills. The OECD anchoring (mean 0, SD 1 across OECD countries) has no meaning for this non-OECD sample,
# so the six scales are re-standardised to the analytic sample: mean 0, SD 1 across the 20 systems with senate weights (each
# system weighted equally). This keeps one metric across systems ("sample SD"). The OECD-anchored values are kept as *_oecd;
# within-system z-scores (*_zw) are kept for the correlation matrix. GROWTH is binary and is not rescaled.
wz <- function(x, w) { m <- sum(w * x, na.rm = TRUE) / sum(w[!is.na(x)]); s <- sqrt(sum(w * (x - m)^2, na.rm = TRUE) / sum(w[!is.na(x)])); (x - m) / s }
for (s in wle_skills) {
  a[, (paste0(s, "_oecd")) := get(s)]
  a[, (s) := wz(get(s), w_senate)]
  a[, (paste0(s, "_zw")) := wz(get(s), W_FSTUWT), by = CNT]
}
a[, GROWTH_zw := GROWTH]
cat("skills rescaled to the analytic sample (senate-weighted mean 0, SD 1); growth mindset share:", round(sum(a$w_senate * a$GROWTH) / sum(a$w_senate), 3), "\n")
for (v in c("ESCS")) { a[, ESCS_zw := wz(ESCS, W_FSTUWT), by = CNT] }
# weighted ESCS percentile groups within economy: bottom 10 / 10-40 / 40-90 / top 10
wq <- function(x, w, p) { o <- order(x); cw <- cumsum(w[o]) / sum(w); x[o][findInterval(p, cw) + 1] }
a[, `:=`(q10 = wq(ESCS, W_FSTUWT, 0.10), q40 = wq(ESCS, W_FSTUWT, 0.40), q90 = wq(ESCS, W_FSTUWT, 0.90)), by = CNT]
a[, escs_grp4 := factor(fifelse(ESCS <= q10, "Bottom 10%", fifelse(ESCS <= q40, "10-40%", fifelse(ESCS <= q90, "40-90%", "Top 10%"))),
                        levels = c("Bottom 10%", "10-40%", "40-90%", "Top 10%"))]
a[, c("q10", "q40", "q90") := NULL]
# weighted ESCS deciles within economy (1 = poorest, 10 = richest)
wdec <- function(x, w) { o <- order(x); cw <- cumsum(w[o]) / sum(w); d <- integer(length(x)); d[o] <- pmin(10L, findInterval(cw, seq(0, 1, 0.1), rightmost.closed = TRUE)); d }
a[, escs_dec := wdec(ESCS, W_FSTUWT), by = CNT]
print(a[, .N, by = escs_dec][order(escs_dec)])
print(a[, .N, by = .(escs_grp4)][order(escs_grp4)])
# science in pooled-sample SD units (senate weighted), for effect sizes alongside PISA points
pv <- paste0("PV", 1:10, "SCIE")
a[, sci_sd_pooled := { m <- sum(w_senate * PV1SCIE) / sum(w_senate); sqrt(sum(w_senate * (PV1SCIE - m)^2) / sum(w_senate)) }]
cat("pooled science SD (senate-weighted, PV1):", round(a$sci_sd_pooled[1], 1), "\n")

# deprivation in usable form
a[, dep4_any := as.integer(dep4_share > 0)]
a[, dep4_cnt := round(dep4_share * 4)]
a[, dep9_avail := st401_fielded == 1]

saveRDS(a, OUT)
cat("saved", nrow(a), "students,", uniqueN(a$school), "schools\n")
