# Paper C -- what does an additional year of schooling do for science and reading? The same 14 sharp-cutoff systems as Paper B.
# This script adds the cross-sectional benchmark the RD is compared with: the "grade coefficient" of an education production function,
# i.e. WLS of the score on the upper-grade indicator D with birth-month dummies (the age-dummy / LSDV design of the 2018 paper), on the
# whole 12-month cohort, (a) without and (b) with student controls (sex, ESCS, immigrant background, home language). It is the
# conditional grade-achievement association, not a causal effect: within a birth month, who is in the upper grade is a family decision
# (early entry) except at the cutoff, where the rule decides -- which is exactly what the RD in 03_rd.R exploits.
# Inference: Fay BRR (80 replicates) + Rubin over 10 PVs.           Output: 03_outputs/paperC/grade_lsdv.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/paperB/00_helpers.R")
a <- load_analytic(); res <- list()
for (cn in SYS) {
  s <- a[CNT == cn]; s[, bm := factor(bmonth)]
  for (dom in PV_DOMS) for (ctrl in c("none", "controls")) {
    rhs <- c("D", "bm", if (ctrl == "controls") c("female", "ESCS", "immigrant", "lang_other"))
    w <- s[complete.cases(s[, c(rhs[rhs != "bm"], "bmonth"), with = FALSE])]
    if (nrow(w) < 200) next                                                          # Costa Rica: no ESCS in the PUF -> no controls version
    X <- model.matrix(as.formula(paste("~", paste(rhs, collapse = " + "))), w)
    e <- pisa_est(w, function(dt, y, wt) c(D = unname(wls(X, y, wt)["D"])), PV(dom))
    res[[length(res) + 1]] <- data.table(CNT = cn, system = SYS_NAMES[cn], region = REGION[cn], tier = TIER[cn], domain = dom, controls = ctrl, n = nrow(w), est = e$est, se = e$se)
  }
  log_step(cn, "done")
}
res <- rbindlist(res); dir.create("03_outputs/paperC", showWarnings = FALSE); fwrite(res, "03_outputs/paperC/grade_lsdv.csv")
print(dcast(res[controls == "controls"], CNT ~ domain, value.var = "est", fun.aggregate = function(x) round(x[1], 1)))
# national score SDs (PV1, final weights) to express effects in SD units of the system's own distribution
sds <- a[, .(SCIE = wsd(PV1SCIE, W_FSTUWT), MATH = wsd(PV1MATH, W_FSTUWT), READ = wsd(PV1READ, W_FSTUWT), mean_SCIE = wmean(PV1SCIE, W_FSTUWT), mean_READ = wmean(PV1READ, W_FSTUWT)), by = CNT]
fwrite(sds, "03_outputs/paperC/score_sd.csv")
