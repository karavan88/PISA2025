# Paper C -- the three bundles. Age at test = school-starting age + years of schooling, so one cross-section identifies two contrasts, never three.
#   tau   : fixed-age contrast at the cutoff   = +1 year of schooling, -1 year of school-starting age (youngest instead of oldest in the grade)
#   beta  : within-grade slope of the score on birth month, per year = +1 year of age at test AND +1 year of school-starting age (the two move together inside a grade)
#   gamma : tau + beta                           = +1 year of schooling, +1 year of age at test, starting age held fixed -- the Avvisati & Givord (2021) estimand
# Estimation: y = a + rf*Z + b*r (common slope in months r), D = c + fs*Z + d*r on the whole cohort window (h = 6, partial month dropped where donut = 1);
#   tau = rf/fs; beta = -12*b (r increases with later birth = younger at test, so b < 0 means older students score higher); gamma = tau + beta.
#   Fay BRR (80 replicates) + Rubin (10 PVs); all three quantities recomputed per replicate so gamma's SE respects their covariance.
# Usage: Rscript 02_scripts/paperC/02_age_decomposition.R        Output: 03_outputs/paperC/age_decomposition.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
a <- load_analytic(); res <- list()
for (cn in SYS) {
  s <- a[CNT == cn]; donut <- s$donut[1]
  for (h in c(4, 6)) {
    w <- s[r >= -h & r <= h - 1]; if (donut == 1) w <- w[r != 0]
    if (uniqueN(w$r) < 3 | uniqueN(w$Z) < 2) next
    X <- cbind(1, Z = w$Z, r = w$r)
    statfun <- function(dt, y, wt) { ok <- !is.na(y); cy <- wls(X[ok, , drop = FALSE], y[ok], wt[ok]); cd <- wls(X[ok, , drop = FALSE], dt$D[ok], wt[ok])
      tau <- cy["Z"] / cd["Z"]; beta <- -12 * cy["r"]; c(fs = unname(cd["Z"]), tau = unname(tau), beta = unname(beta), gamma = unname(tau + beta)) }
    for (dom in c(PV_DOMS, out_skills, "growth")) {                     # achievement domains and, for Paper B, the skill scales (SD units) and growth mindset
      ys <- if (dom %in% PV_DOMS) PV(dom) else dom
      if (sum(!is.na(w[[ys[1]]])) < 100) next
      e <- pisa_est(w, statfun, ys)
      res[[length(res) + 1]] <- data.table(CNT = cn, system = SYS_NAMES[cn], region = REGION[cn], tier = TIER[cn], domain = dom, h = h, n = sum(!is.na(w[[ys[1]]])), e)
    }
  }
  log_step(cn, "done")
}
res <- rbindlist(res); fwrite(res, "03_outputs/paperC/age_decomposition.csv")
print(dcast(res[h == 6 & domain == "SCIE" & tier == "sharp"], CNT ~ term, value.var = "est", fun.aggregate = function(x) round(x[1], 1)))

# Avvisati & Givord (2021), OECD Education Working Paper 257, Table 5.1: IV estimates (SE) of the effect of one more grade with school-starting age
# held fixed (= one more year of schooling and one more year of age), PISA 2018. Transcribed for the systems that overlap with this paper's two tiers.
ag <- fread(text = "CNT,MATH,MATH_se,READ,READ_se,SCIE,SCIE_se
TAP,10.9,4.8,7.6,4.0,8.4,4.5
KOR,18.8,8.3,8.7,7.2,12.3,8.4
QCI,12.9,5.9,17.0,5.6,17.2,6.4
HKG,27.5,5.3,20.4,5.7,23.5,4.7
EST,37.9,4.3,27.2,4.6,29.8,4.5
FIN,16.0,3.8,17.8,3.9,20.2,4.4
SVK,19.1,5.3,31.0,5.5,24.9,4.4
HRV,19.0,3.5,17.3,4.1,14.4,3.7
SRB,9.5,7.1,18.1,7.1,20.3,7.2
ALB,1.9,6.6,9.2,5.8,10.6,5.9
CRI,18.7,5.2,27.5,5.1,25.3,5.5")
fwrite(ag, "03_outputs/paperC/avvisati_givord_2021_table51.csv")
