# Skills & the Grade Gain -- analytic file for the 20 study systems
# Input : 01_data/derived/gradegain_analytic.rds (02_scripts/gradegain/02_prepare.R: cutoff, D, Z, r, ssa, within-system z of the scales)
#         01_data/derived/skillsgain_extra.csv.gz (01_build_extra.py: books at home and SES components)
# Output: 01_data/derived/skillsgain_analytic.rds ; 03_outputs/skillsgain/coverage.csv, scale_corr.csv
# Constructs (all standardised within system with the final student weight):
#   SES      student SES = ESCS; Costa Rica has no ESCS (nor any component) and uses books at home (flag ses_src)
#   schSES   school SES = leave-one-out weighted mean of the student SES measure among sampled schoolmates (>= 5), standardised
#   SE       socio-emotional index = mean of the available z-scores of the six scales (>= 2), restandardised;
#            SE_task (perseverance, goal setting, self-regulation) and SE_open (curiosity, problem-solving, adaptability), any available.
#            Fielded scales: six everywhere except Brazil and Kenya (no perseverance), Mauritius (perseverance and curiosity only), Cambodia (none)
#   SE_p     SE purged of the causal effect of the upper grade on SE (SE - tau_SE * D, tau_SE from the per-system 2SLS): a moderator
#            that cannot carry the grade's own effect on self-reports (frame-of-reference, schooling)
#   PVkACH   overall achievement = mean of the k-th plausible value in science, mathematics and reading
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/skillsgain/00_helpers.R")
a <- readRDS("01_data/derived/gradegain_analytic.rds")[CNT %in% SYS20]
ex <- fread("01_data/derived/skillsgain_extra.csv.gz")
a <- merge(a, ex, by = "CNTSTUID", all.x = TRUE)
a[, group := GROUP[CNT]]; a[, school := as.character(CNTSCHID)]
for (k in 1:10) a[, paste0("PV", k, "ACH") := (get(paste0("PV", k, "SCIE")) + get(paste0("PV", k, "MATH")) + get(paste0("PV", k, "READ"))) / 3]

# student SES
a[, ses_src := fifelse(CNT == "CRI", "books", "ESCS")]
a[, ses_raw := fifelse(CNT == "CRI", as.numeric(books), ESCS)]
a[, SES := zw(ses_raw, W_FSTUWT), by = CNT]
a[, books_z := zw(as.numeric(books), W_FSTUWT), by = CNT]
# school SES, leave-one-out
a[, `:=`(sw = sum(W_FSTUWT[!is.na(ses_raw)]), swx = sum((W_FSTUWT * ses_raw)[!is.na(ses_raw)]), sn = sum(!is.na(ses_raw))), by = school]
a[, sch_raw := fifelse(!is.na(ses_raw), (swx - W_FSTUWT * ses_raw) / (sw - W_FSTUWT), swx / sw)]
a[, sn_other := sn - as.integer(!is.na(ses_raw))]; a[sn_other < 5, sch_raw := NA]
a[, schSES := zw(sch_raw, W_FSTUWT), by = CNT]
a[, c("sw", "swx", "sn", "sn_other") := NULL]

# socio-emotional indices
zcols <- paste0(SE6, "_z")
rmean <- function(cols, min_n) { m <- as.matrix(a[, ..cols]); n <- rowSums(!is.na(m)); v <- rowMeans(m, na.rm = TRUE); v[n < min_n] <- NA; v }
a[, SE_raw := rmean(zcols, 2)]; a[, SE_task_raw := rmean(paste0(SE_TASK, "_z"), 1)]; a[, SE_open_raw := rmean(paste0(SE_OPEN, "_z"), 1)]
a[, `:=`(SE = zw(SE_raw, W_FSTUWT), SE_task = zw(SE_task_raw, W_FSTUWT), SE_open = zw(SE_open_raw, W_FSTUWT)), by = CNT]
for (s in SE6) a[, (s) := get(paste0(s, "_z"))]                          # the single scales enter as within-system z-scores under their own names

# grade-purged SE: remove the fixed-age effect of the upper grade on SE (point estimate per system)
for (cn in intersect(SYS20, a[!is.na(SE), unique(CNT)])) {
  s <- a[CNT == cn]; X <- cbind(1, s$female, s$immigrant); X[is.na(X)] <- 0
  tau_se <- unname(tsls_m(s$SE, s$D, s$Z, s$r, matrix(nrow = nrow(s), ncol = 0), X, s$W_FSTUWT)["tau"])   # (not "t": a column of that name exists)
  a[CNT == cn, SE_p := zw(SE - tau_se * D, W_FSTUWT)]
}
# interactions and groups (products of within-system z-scores; groups are within-system weighted quartiles)
a[, `:=`(SExSES = SE * SES, SExschSES = SE * schSES)]
wq <- function(x, w, k = 4) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); q <- rep(NA_integer_, length(x)); q[which(ok)[o]] <- pmin(k, floor(cw * k - 1e-9) + 1L); q }
a[, `:=`(SE_q = wq(SE, W_FSTUWT), SES_q = wq(SES, W_FSTUWT), schSES_q = wq(schSES, W_FSTUWT)), by = CNT]
saveRDS(a, "01_data/derived/skillsgain_analytic.rds")

cov <- a[, .(n = .N, share_upper = wmean(D, W_FSTUWT), ses_src = ses_src[1], p_SES = mean(!is.na(SES)), p_schSES = mean(!is.na(schSES)), p_SE = mean(!is.na(SE)),
             p_both = mean(!is.na(SE) & !is.na(SES)), n_scales = sum(sapply(SE6, function(v) mean(!is.na(get(v))) > 0.5)), schools = uniqueN(school),
             r_SE_SES = cor(SE, SES, use = "pairwise"), r_SE_schSES = cor(SE, schSES, use = "pairwise"), r_SES_schSES = cor(SES, schSES, use = "pairwise")), by = .(CNT, group)]
cov[, name := SYS_NAMES[CNT]]; setcolorder(cov, c("CNT", "name", "group"))
fwrite(cov[order(group, CNT)], os("coverage.csv"))
cm <- cor(as.matrix(a[, c(SE6, "SE", "SES", "schSES"), with = FALSE]), use = "pairwise")
fwrite(data.table(var = rownames(cm), round(cm, 3)), os("scale_corr.csv"))
print(cov[, .(CNT, group, n, ses_src, p_SES = round(p_SES, 2), p_schSES = round(p_schSES, 2), p_SE = round(p_SE, 2), n_scales, r_SE_SES = round(r_SE_SES, 2), r_SES_sch = round(r_SES_schSES, 2))])
print(round(cm, 2))
