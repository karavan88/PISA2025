# sestransmit -- analytic sample for all PISA 2025 systems.
# Exposure: within-system percentile rank of ESCS (final weights, full national sample), /10 so one unit = 10 percentile points.
# Mediators: the socio-emotional scales each system fielded (>= 20% non-missing; zero otherwise) + binary growth mindset.
# Skills re-standardised to the pooled analytic sample (each system weighted equally); ACMEs and shares are invariant to this choice.
# Controls with item non-response enter with a missing-value indicator (value set to 0) so that the sample is defined by
# exposure, outcome and mediators only.
source("02_scripts/sestransmit/00_helpers.R")
d <- fread("01_data/derived/sestransmit_students.csv.gz")
d <- d[!CNT %in% names(EXCLUDE)]

wrank <- function(x, w) { r <- rep(NA_real_, length(x)); ok <- !is.na(x) & !is.na(w); o <- order(x[ok])
  cw <- cumsum(w[ok][o]); r[which(ok)[o]] <- 100 * (cw - 0.5 * w[ok][o]) / sum(w[ok]); r }
d[, ESCS_pct := wrank(ESCS, W_FSTUWT), by = CNT][, ESCS_pct10 := ESCS_pct / 10]
d[, has_school := !is.na(CNTSCHID)]
loo <- function(x) { n <- sum(!is.na(x)); s <- sum(x, na.rm = TRUE); out <- (s - ifelse(is.na(x), 0, x)) / (n - !is.na(x)); out[n - !is.na(x) < 1] <- NA; out }
d[has_school == TRUE, sch_pct_loo := loo(ESCS_pct10), by = .(CNT, CNTSCHID)]

# fielded mediators and controls per system
fld <- d[, c(lapply(.SD, function(x) mean(!is.na(x)) >= 0.2)), by = CNT, .SDcols = c(skills, stu_ctrl, "private", "urban")]
fwrite(fld, ap("fielded.csv"))
med_list <- setNames(lapply(fld$CNT, function(c) skills[unlist(fld[CNT == c, ..skills])]), fld$CNT)

# complete cases on exposure, science PV, weight and every fielded mediator
d[, complete := !is.na(ESCS_pct10) & !is.na(W_FSTUWT) & !is.na(PV1SCIE)]
for (c in names(med_list)) { m <- med_list[[c]]; d[CNT == c, complete := complete & complete.cases(.SD), .SDcols = m] }
cov <- d[, .(economy = economy[1], OECD = OECD[1], N_all = .N, N_analytic = sum(complete), share = mean(complete),
             escs_all = weighted.mean(ESCS, W_FSTUWT, na.rm = TRUE), escs_analytic = weighted.mean(ESCS[complete], W_FSTUWT[complete], na.rm = TRUE),
             sci_all = weighted.mean(PV1SCIE, W_FSTUWT, na.rm = TRUE), sci_analytic = weighted.mean(PV1SCIE[complete], W_FSTUWT[complete], na.rm = TRUE),
             n_med = length(med_list[[CNT[1]]]), mediators = paste(med_list[[CNT[1]]], collapse = " "),
             icc_sci = { if (all(is.na(CNTSCHID))) NA_real_ else { ok <- !is.na(PV1SCIE) & !is.na(CNTSCHID); sm <- ave(PV1SCIE[ok], CNTSCHID[ok]); 1 - weighted.mean((PV1SCIE[ok] - sm)^2, W_FSTUWT[ok]) / (weighted.mean(PV1SCIE[ok]^2, W_FSTUWT[ok]) - weighted.mean(PV1SCIE[ok], W_FSTUWT[ok])^2) } }), by = CNT]
fwrite(cov, ap("sample_coverage.csv"))

# controls: missing indicator approach (fielded controls only); school controls likewise
for (v in c(stu_ctrl, "private")) { d[, (paste0(v, "_mis")) := as.integer(is.na(get(v)))]; d[is.na(get(v)), (v) := 0] }
d[, urban_mis := as.integer(is.na(urban))]; d[, urban1 := as.integer(urban %in% 1)]; d[, urban2 := as.integer(urban %in% 2)]
d[, sch_pct_loo_mis := as.integer(is.na(sch_pct_loo))]; d[is.na(sch_pct_loo), sch_pct_loo := 0]

a <- d[complete == TRUE]
wz <- function(x, w) { ok <- !is.na(x); m <- sum(w[ok] * x[ok]) / sum(w[ok]); s <- sqrt(sum(w[ok] * (x[ok] - m)^2) / sum(w[ok])); (x - m) / s }
a[, w_senate := W_FSTUWT / sum(W_FSTUWT), by = CNT]
for (s in wle_skills) a[, (s) := wz(get(s), w_senate)]
attr(a, "med_list") <- med_list
saveRDS(a, "01_data/derived/sestransmit_analytic.rds")
saveRDS(d[, .(CNT, CNTSTUID, complete, ESCS_pct10, PV1SCIE, PV1READ, PV1MATH, female, female_mis, AGE, AGE_mis, grade_rel, grade_rel_mis, immig, immig_mis,
              lang_other, lang_other_mis, W_FSTUWT)], "01_data/derived/sestransmit_selection.rds")
cat("systems:", uniqueN(a$CNT), " students:", nrow(a), " of", nrow(d), "\n")
print(cov[order(share)][1:12])
