# The Cost of Resilience -- analytic file
# Sample: students with life satisfaction, ESCS, achievement PVs and the system's skill index; systems where the six-scale index has
# at least four scales. Builds within-system z-scores, ESCS quartiles, the leave-one-out school ESCS, the response-style indices,
# questionnaire speed flags and the PV-wise achievement composites.
# Output: 01_data/derived/resilwb_analytic.rds, resilwb_coverage.csv   (WELLBEING_DERIVED redirects both, for validation)
source("02_scripts/02_legacy/wellbeing_shared/00_survey_helpers.R")
log_step("read extract")
d <- fread(STUDENTS)
RS4 <- c("ST131Q04NA", "ST131Q10DA", "ST131Q12DA", "ST131Q05DA", "ST131Q13DA", "ST131Q17DA", "ST499Q02DA", "ST499Q04DA", "ST499Q05DA",
         "ST499Q06DA", "ST500Q03DA", "ST500Q05DA", "ST500Q06DA", "ST500Q09DA", "ST501Q03DA", "ST501Q05DA", "ST501Q06DA", "ST501Q07DA")
RS5 <- c("ST307Q01JA", "ST307Q02JA", "ST307Q03JA", "ST307Q07JA", "ST307Q09JA", "ST307Q10JA", "ST301Q01JA", "ST301Q04JA", "ST301Q06JA", "ST301Q08JA", "ST301Q10JA")
REV5 <- c("ST307Q07JA", "ST307Q10JA", "ST301Q08JA")                     # reverse-keyed skill items -> acquiescence from balanced pairs

# --- achievement composites, one per PV
for (p in 1:10) d[, (paste0("ACH", p)) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
d[, `:=`(LS = ST016Q01NA, female = fifelse(ST004D01T == 1, 1, fifelse(ST004D01T == 2, 0, NA_real_)))]
d[is.na(female) & !is.na(MALE), female := 1 - MALE]       # 14 systems withhold ST004D01T; MALE from the sampling frame ("female/other" = 0)

# --- response style (computed before sample restrictions; needs >= 8 answered items)
A4 <- as.matrix(d[, ..RS4]); n4 <- rowSums(!is.na(A4))
d[, ERS := fifelse(n4 >= 8, rowSums(A4 == 1 | A4 == 4, na.rm = TRUE) / n4, NA_real_)]     # extreme responding, content-free pool
d[, ARS := fifelse(n4 >= 8, rowSums(A4 >= 3, na.rm = TRUE) / n4, NA_real_)]               # agreement share (content-contaminated; secondary)
A5 <- as.matrix(d[, ..RS5]); n5 <- rowSums(!is.na(A5))
d[, ERS5 := fifelse(n5 >= 6, rowSums(A5 == 1 | A5 == 5, na.rm = TRUE) / n5, NA_real_)]
d[, MRS5 := fifelse(n5 >= 6, rowSums(A5 == 3, na.rm = TRUE) / n5, NA_real_)]               # midpoint responding
# acquiescence from the balanced skill items: agreeing with an item AND with its reversal is content-free
Ap <- as.matrix(d[, .SD, .SDcols = setdiff(RS5, REV5)]); Ar <- as.matrix(d[, ..REV5])
d[, ACQ5 := fifelse(n5 >= 6, (rowMeans(Ap, na.rm = TRUE) + rowMeans(Ar, na.rm = TRUE)) / 2 - 3, NA_real_)]   # 0 = balanced
d[, LS10 := as.integer(LS == 10)]
# placebo thermometers (1-10): top-box use on a numeric scale whose content is not wellbeing
d[, `:=`(EFF1 = EFFORT1, EFF2 = EFFORT2, EFFQ = ST331Q03JA)]
d[, `:=`(EFF1_10 = as.integer(EFF1 == 10), EFF2_10 = as.integer(EFF2 == 10), EFFQ_10 = as.integer(EFFQ == 10))]

# --- sample
d <- d[!is.na(LS) & !is.na(ESCS) & !is.na(ACH1) & !is.na(W_FSTUWT)]
cov_se <- d[, lapply(.SD, function(x) mean(!is.na(x))), by = CNT, .SDcols = SE6]
se_ok <- melt(cov_se, id.vars = "CNT")[value > 0.5, .(se_scales = paste(variable, collapse = " "), n_se = .N), by = CNT]
keep <- se_ok[n_se >= 4, CNT]
log_step("systems kept:", length(keep), "| dropped for <4 skill scales:", paste(setdiff(unique(d$CNT), keep), collapse = " "))
d <- d[CNT %in% keep]

# --- within-system standardisation and derived variables (final student weight)
d[, w := W_FSTUWT]
zvars <- c("LS", SE6, CTX, "EFFSCIE", "ESCS", "HOMEPOS", "ERS", "ARS", "ERS5", "MRS5", "ACQ5", "PQSELFREG", "EFF1", "EFF2", "EFFQ")
for (v in zvars) d[, (paste0(v, "_z")) := if (sum(!is.na(get(v))) > 50) zw(get(v), w) else NA_real_, by = CNT]
d[, SEI := { M <- as.matrix(.SD); M[, colMeans(is.na(M)) > 0.5] <- NA; m <- rowMeans(M, na.rm = TRUE)
             m[rowSums(!is.na(M)) < 3] <- NA; zw(m, w) }, by = CNT, .SDcols = paste0(SE6, "_z")]
d[, sesq := wquartile(ESCS, w), by = CNT]
# leave-one-out weighted school mean ESCS (status-mismatch mechanism)
d[, `:=`(sw = sum(w * !is.na(ESCS)), swx = sum(w * ESCS, na.rm = TRUE), nsch = .N), by = CNTSCHID]
d[, schESCS_loo := fifelse(nsch > 1, (swx - w * ESCS) / (sw - w), NA_real_)]
d[, schESCS_loo_z := (schESCS_loo - wmean(ESCS, w)) / wsd(ESCS, w), by = CNT]            # in units of the system's student ESCS SD
d[, c("sw", "swx", "nsch") := NULL]
# careless responding: absolute (< 1 s per item) and relative (bottom 5% within system)
d[, speeder := as.integer(sec_per_item < 1)]
d[, speeder_rel := as.integer(sec_per_item < wquant(sec_per_item, w, .05)), by = CNT]
d[, grade_c := factor(GRADE)]

keepcols <- c("CNT", "CNTSCHID", "CNTSTUID", "female", "AGE", "GRADE", "W_FSTUWT", RW, "w", ACH, "LS", "LS10", "SEI", "sesq", "ESCS",
              "schESCS_loo_z", "speeder", "speeder_rel", "sec_per_item", "SISCO", "EXPECEDU", "PQSELFREG", "PA204Q04DA", SE6, CTX,
              "ERS", "ARS", "ERS5", "MRS5", "ACQ5", "EFF1", "EFF2", "EFFQ", "EFF1_10", "EFF2_10", "EFFQ_10", grep("_z$", names(d), value = TRUE))
d <- d[, unique(keepcols), with = FALSE]
saveRDS(d, DERIV)

cov <- d[, .(n = .N, se_scales = se_ok[match(.BY$CNT, CNT), se_scales], LS_mean = round(wmean(LS, w), 2), LS10 = round(wmean(LS10, w), 3),
             SEI = mean(!is.na(SEI)), ERS = mean(!is.na(ERS)), ACQ5 = mean(!is.na(ACQ5)), timing = mean(!is.na(sec_per_item)),
             speeder = round(wmean(speeder, w), 3), parent = mean(!is.na(PQSELFREG)), female = mean(!is.na(female))), by = CNT]
fwrite(cov, file.path(DERIVED, "resilwb_coverage.csv"))
log_step("saved", nrow(d), "students,", uniqueN(d$CNT), "systems")
print(cov[order(CNT)])
