# School Inputs & the Grade Gain -- analytic file
# Input : 01_data/derived/skillsgain_analytic.rds (cutoff design variables, SES, skills, PVkACH; 02_scripts/skillsgain/02_prepare.R)
#         01_data/derived/schoolgain_school.csv, schoolgain_stu.csv.gz (01_build.py); 03_outputs/skillsgain/structure.csv
# Output: 01_data/derived/schoolgain_analytic.rds ; 03_outputs/schoolgain/coverage_inputs.csv, input_corr.csv
# Constructs (every moderator standardised within system with the student weight):
#   school questionnaire inputs; PRIVATE = SC013 private; URBAN = community of 100,000+ (SC001 >= 4)
#   s_*      leave-one-out school means of student-reported climate (disciplinary climate, teacher support, cognitive activation, bullying,
#            feeling safe), >= 5 other respondents
#   peer_SES leave-one-out school mean of student SES (ESCS; books in Costa Rica) = schSES from the skills pipeline
#   peer_ach leave-one-out mean achievement of LOWER-grade schoolmates (>= 3), after removing the system's birth-month and grade means.
#            Upper-grade schoolmates are excluded because their scores contain the school's own grade gain -- the outcome -- which would
#            make the moderator mechanically correlated with it. peer_ach_all (all schoolmates) is kept for robustness.
#   controls HISEI, PAREDINT, HOMEPOS (z within system), books for Costa Rica; CURIO, PERSEV, ENPROBS; missing set to 0 with a flag
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
a <- load_sg()
st <- fread("03_outputs/skillsgain/structure.csv"); a <- merge(a, st[, .(CNT, structure)], by = "CNT")
sch <- fread("01_data/derived/schoolgain_school.csv"); stu <- fread("01_data/derived/schoolgain_stu.csv.gz")
a <- merge(a, sch, by = "CNTSCHID", all.x = TRUE); a <- merge(a, stu, by = "CNTSTUID", all.x = TRUE)
a[, `:=`(STRATIO = STRATIO_Q, SCHSIZE = SCHSIZE_Q, PRIVATE = as.numeric(SC013Q01TA == 2), URBAN = as.numeric(SC001Q01TA >= 4))]

loo <- function(x, w, g, min_n) {                                          # leave-one-out weighted mean within group g
  ok <- !is.na(x); sw <- ave(ifelse(ok, w, 0), g, FUN = sum); swx <- ave(ifelse(ok, w * x, 0), g, FUN = sum); n <- ave(as.numeric(ok), g, FUN = sum)
  m <- ifelse(ok, (swx - w * x) / (sw - w), swx / sw); m[(n - ok) < min_n] <- NA; m
}
clim <- c(DISC = "DISCLISCI", TSUP = "TEACHSUP", COGA = "COGACSC", BULL = "BULLIED", SAFE = "FEELSAFE")
for (k in names(clim)) a[, paste0("s_", k) := loo(get(clim[[k]]), W_FSTUWT, school, 5)]

# peer achievement: residual of each PV on the system's grade x birth-month cell means, averaged over PVs; LOO among lower-grade peers
a[, ach_res := {
  X <- model.matrix(~ factor(D) * factor(r)); rowMeans(sapply(PV("ACH"), function(p) { y <- get(p); b <- lm.wfit(X, y, W_FSTUWT)$coefficients; b[is.na(b)] <- 0; y - drop(X %*% b) })) }, by = CNT]
a[, peer_ach := loo(fifelse(D == 0, ach_res, NA_real_), W_FSTUWT, school, 3)]
a[, peer_ach_all := loo(ach_res, W_FSTUWT, school, 5)]
a[, peer_SES := schSES]

# standardise moderators within system
for (v in setdiff(INPUTS$var, "peer_SES")) a[, (v) := zw(as.numeric(get(v)), W_FSTUWT), by = CNT]
a[, peer_ach_all := zw(peer_ach_all, W_FSTUWT), by = CNT]

# controls: decomposed ESCS + skills, missing -> 0 with flags
for (v in c("HISEI", "PAREDINT", "HOMEPOS")) a[, paste0(v, "_z") := zw(as.numeric(get(v)), W_FSTUWT), by = CNT]
a[, books_cri := fifelse(CNT == "CRI", books_z, NA_real_)]
a[, ses_mis := as.numeric(CNT != "CRI" & (is.na(HISEI_z) | is.na(PAREDINT_z) | is.na(HOMEPOS_z)) | (CNT == "CRI" & is.na(books_cri)))]
for (v in c("HISEI_z", "PAREDINT_z", "HOMEPOS_z")) a[CNT != "CRI" & is.na(get(v)), (v) := 0]   # Costa Rica keeps NA -> dropped from its controls
a[CNT == "CRI" & is.na(books_cri), books_cri := 0]                          # books_cri is NA elsewhere -> dropped there
for (v in SKILL3) a[, paste0(v, "_c") := fifelse(is.na(get(v)), 0, get(v))]
a[, skill_mis := as.numeric(is.na(CURIO) | (is.na(PERSEV) & !CNT %in% c("BRA", "KEN")) | (is.na(ENPROBS) & CNT != "MUS"))]
a[is.na(immigrant), immigrant := 0]
# engagement mediators (06_mechanism.R), standardised within system: skipping, lateness, own victimisation, belonging, test effort
for (v in c("SKIPPING", "TARDYSD", "BULLIED", "BELONG", "EFFORT1")) a[, paste0("m_", v) := zw(as.numeric(get(v)), W_FSTUWT), by = CNT]
saveRDS(a, "01_data/derived/schoolgain_analytic.rds")

same <- a[structure == "Same-school"]
cov <- same[, lapply(.SD, function(x) round(mean(!is.na(x)), 2)), by = CNT, .SDcols = INPUTS$var]
fwrite(cov, og("coverage_inputs.csv")); print(cov)
cm <- cor(as.matrix(same[, INPUTS$var, with = FALSE]), use = "pairwise"); fwrite(data.table(var = rownames(cm), round(cm, 3)), og("input_corr.csv"))
print(same[, .(n = .N, schools = uniqueN(school), r_peer = round(cor(peer_ach, peer_SES, use = "pairwise"), 2), r_peer_all = round(cor(peer_ach, peer_ach_all, use = "pairwise"), 2)), by = CNT])
