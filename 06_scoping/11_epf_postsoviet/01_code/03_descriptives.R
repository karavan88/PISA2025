# EPF post-Soviet paper -- descriptives: sample table, achievement, ICC, correlation matrix, birth-month patterns
# Output: 03_outputs/epf_postsoviet/<DOMAIN>/desc_*.csv
suppressPackageStartupMessages({ library(data.table); library(lme4) })
source("02_scripts/epf_postsoviet/00_helpers.R")
a <- load_analytic()
L2 <- c(SCIE = 409.54, MATH = 420.07, READ = 407.47)[DOMAIN]     # PISA Level 2 lower bound (minimum proficiency, SDG 4.1.1)

# ---- 1. system table: weighted means with PISA inference ----------------------------------------------------------------
stat_desc <- function(dt, y, w) c(score = wmean(y, w), sd = wsd(y, w), below_L2 = wmean(as.numeric(y < L2), w), p25 = wquant(y, w, .25), p50 = wquant(y, w, .5), p75 = wquant(y, w, .75))
desc <- rbindlist(lapply(levels(a$CNT), function(c) { s <- a[CNT == c]; r <- pisa_est(s, stat_desc); r[, CNT := c]; r }))
desc_w <- dcast(desc, CNT ~ term, value.var = c("est", "se"))
cov_means <- a[, .(n = .N, schools = uniqueN(school), ESCS = wmean(ESCS, W_FSTUWT), female = wmean(female, W_FSTUWT), lang_other = wmean(lang_other, W_FSTUWT),
                   repeated = wmean(repeated, W_FSTUWT), rus_medium = wmean(rus_medium, W_FSTUWT), rural = wmean(rural, W_FSTUWT), private = wmean(private, W_FSTUWT),
                   grade_below = wmean(as.numeric(grade_c < 0), W_FSTUWT), grade_above = wmean(as.numeric(grade_c > 0), W_FSTUWT), modal_grade = modal_grade[1],
                   skills_n = sum(skills_ok), sel_policy = wmean(sel_policy, W_FSTUWT), clsize = wmean(clsize, W_FSTUWT), proatce = wmean(proatce, W_FSTUWT)), by = CNT]
desc_w <- merge(cov_means, desc_w, by = "CNT"); desc_w[, economy := PS_NAMES[as.character(CNT)]]
fwrite(desc_w, op("desc_systems.csv"))

# ---- 2. ICC from the null model (school random intercept), each PV, Rubin-combined; on the core sample --------------------
icc <- rbindlist(lapply(levels(a$CNT), function(c) {
  s <- a[CNT == c]
  v <- sapply(PV, function(p) { m <- lmer(as.formula(paste(p, "~ 1 + (1 | school)")), data = s, REML = TRUE); vc <- as.data.frame(VarCorr(m)); vc$vcov[1] / sum(vc$vcov) })
  data.table(CNT = c, icc = mean(v), icc_pv_sd = sd(v))
}))
fwrite(icc, op("desc_icc.csv")); print(icc)

# ---- 3. correlation matrix: skills x ESCS x achievement (PV1), senate-weighted, per system ---------------------------------
wcor <- function(x, y, w) { ok <- complete.cases(x, y, w); x <- x[ok]; y <- y[ok]; w <- w[ok]; mx <- wmean(x, w); my <- wmean(y, w); sum(w * (x - mx) * (y - my)) / sqrt(sum(w * (x - mx)^2) * sum(w * (y - my)^2)) }
vars <- c(skill_wle, "growth", "task", "open", "adapt", "ESCS_pct", PV[1])
cm <- rbindlist(lapply(levels(a$CNT), function(c) { s <- a[CNT == c & skills_ok == 1]
  rbindlist(lapply(vars, function(x) rbindlist(lapply(vars, function(y) data.table(CNT = c, x = x, y = y, r = wcor(s[[x]], s[[y]], s$w_senate)))))) }))
cm[y == PV[1], y := "score"]; cm[x == PV[1], x := "score"]
fwrite(cm, op("desc_corr.csv"))

# ---- 4. birth-month patterns (all students in the grade window): share above / below modal, weighted mean score --------------
bm <- a[, .(n = .N, share_above = wmean(as.numeric(grade_c > 0), W_FSTUWT), share_below = wmean(as.numeric(grade_c < 0), W_FSTUWT),
            mean_grade_c = wmean(grade_c, W_FSTUWT), score = wmean(get(PV[1]), W_FSTUWT), ESCS = wmean(ESCS, W_FSTUWT)), by = .(CNT, bmonth)]
setorder(bm, CNT, bmonth); fwrite(bm, op("desc_birthmonth.csv"))
# within-birth-month ESCS gap between students above/below the modal grade and those in it (selection diagnostic)
gap <- a[, { hi <- grade_c > 0; lo <- grade_c < 0; md <- grade_c == 0
  .(escs_gap_above = if (sum(hi) > 20) wmean(ESCS[hi], W_FSTUWT[hi]) - wmean(ESCS[md], W_FSTUWT[md]) else NA_real_,
    escs_gap_below = if (sum(lo) > 20) wmean(ESCS[lo], W_FSTUWT[lo]) - wmean(ESCS[md], W_FSTUWT[md]) else NA_real_, n_above = sum(hi), n_below = sum(lo)) }, by = .(CNT, bmonth)]
gap_sys <- gap[, .(escs_gap_above = weighted.mean(escs_gap_above, n_above, na.rm = TRUE), escs_gap_below = weighted.mean(escs_gap_below, n_below, na.rm = TRUE)), by = CNT]
fwrite(gap_sys, op("desc_entry_selection.csv")); print(gap_sys)

# ---- 5. skills descriptives ----------------------------------------------------------------------------------------------
sk <- a[skills_ok == 1, c(list(n = .N), lapply(.SD, function(x) wmean(x, W_FSTUWT))), .SDcols = c(skill_wle, "growth", "task", "open", "adapt"), by = CNT]
fwrite(sk, op("desc_skills.csv"))
log_step("descriptives written to", OUTD)
