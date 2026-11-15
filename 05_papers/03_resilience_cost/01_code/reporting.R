# Reporting helpers for "The cost of resilience". Reads the approved snapshot (../02_results/snapshot) only; estimates nothing.
# Sourced from ../03_manuscript/*.qmd (working directory = that folder). The snapshot is verified by 01_code/snapshot.py check.
suppressPackageStartupMessages(library(data.table))
OUT <- normalizePath(file.path("..", "02_results", "snapshot")); FIGS <- file.path("..", "02_results", "figs")
rd <- function(f) fread(file.path(OUT, f))
T <- list(gap = rd("gap_pool.csv"), rs = rd("rs_pool.csv"), mech = rd("mech_pool.csv"), cur = rd("cur_pool.csv"), thr = rd("thr_pool.csv"), foc = rd("foc_pool.csv"),
          bench = rd("bench_pool.csv"),                              # bench: second benchmark, advantaged top achievers (step 12)
          gapw = rd("gap_pool_achw.csv"), rsw = rd("rs_pool_achw.csv"), benchw = rd("bench_pool_achw.csv"),   # *w: achievement as the composite weighted towards reading
          gaps = rd("gap_pool_scie.csv"), gapa = rd("gap_pool_ach.csv"))     # science, or the simple average of the three domains
thrm <- rd("thr_model.csv")                                         # pooled threshold model (step 8): term, est, se
focm <- rd("foc_model.csv")                                         # pooled focal-answer quantities (step 9): term, est, se
orivb <- rd("oriv_resil.csv"); cut <- rd("cutoff_pool.csv")        # cutoff_pool.csv: school-entry cutoff test, estimated in this paper (step 14)
gap_sys <- rd("gap_sys.csv"); cov <- rd("coverage.csv")
rs_sys <- rd("rs_sys.csv")                                          # per-system estimates of step 3, for counts of systems
bench_sys <- rd("bench_sys.csv"); mech_sys <- rd("mech_sys.csv")
fo <- rd("forest_est.csv"); finfo <- rd("forest_info.csv"); rgp <- rd("region_pool.csv")   # rgp: pooled estimates by region (step 15)          # causal forest (step 13): combined over plausible values; sample sizes
# number of systems with a negative ("neg"), positive ("pos") or any ("n") estimate of a per-system term
csys <- function(tab, term_, what = "neg") { x <- tab[term == term_ & !is.na(est)]; if (!nrow(x)) stop("per-system term not found: ", term_); switch(what, neg = sum(x$est < 0), pos = sum(x$est > 0), n = nrow(x)) }
# number of systems in which the estimate of term a is below that of term b
cbelow <- function(tab, a, b) { x <- merge(tab[term == a & !is.na(est), .(CNT, a = est)], tab[term == b & !is.na(est), .(CNT, b = est)], by = "CNT"); if (!nrow(x)) stop("per-system terms not found: ", a, " / ", b); sum(x$a < x$b) }
# number of system estimates within 1.96 of their own standard errors of the pooled mean (the funnel of the skills figure)
cfunnel <- function(sys, tab, term_) { x <- sys[term == term_ & !is.na(est) & se > 0]; sum(abs(x$est - row_(tab, term_)$re_mean) <= 1.96 * x$se) }

num <- function(x, d = 2) { s <- formatC(round(x, d), format = "f", digits = d); s <- sub("^-(0\\.0+)$", "\\1", s); sub("^-", "&minus;", s) }   # pandoc entity for a true minus; no "-0.00"
big <- function(x) formatC(round(x), format = "d", big.mark = ",")
row_ <- function(tab, term_) { r <- T[[tab]][term == term_]; if (nrow(r) != 1) stop("term not found: ", tab, " / ", term_); r }
e   <- function(tab, term_, d = 2) num(row_(tab, term_)$re_mean, d)                 # pooled estimate
se  <- function(tab, term_, d = 3) num(row_(tab, term_)$re_se, d)
es  <- function(tab, term_, d = 2) sprintf("%s (SE %s)", e(tab, term_, d), se(tab, term_, max(d, 3)))
esp <- function(tab, term_, d = 2) sprintf("%s, SE %s", e(tab, term_, d), se(tab, term_, max(d, 3)))          # for use inside parentheses
ea  <- function(tab, term_, d = 2) num(abs(row_(tab, term_)$re_mean), d)            # magnitude, for "smaller by ..." sentences
esa <- function(tab, term_, d = 2) sprintf("%s (SE %s)", ea(tab, term_, d), se(tab, term_, max(d, 3)))
ppa <- function(tab, term_, d = 1) num(abs(100 * row_(tab, term_)$re_mean), d)
pp  <- function(tab, term_, d = 1) num(100 * row_(tab, term_)$re_mean, d)           # share -> percentage points
tt  <- function(tab, term_) num(row_(tab, term_)$re_mean / row_(tab, term_)$re_se, 1)
nsys <- function(tab, term_) row_(tab, term_)$n_sys
nneg <- function(tab, term_) row_(tab, term_)$n_neg
sneg <- function(tab, term_) row_(tab, term_)$sig_neg
spos <- function(tab, term_) row_(tab, term_)$sig_pos
i2  <- function(tab, term_) num(row_(tab, term_)$I2, 0)
# pooled threshold model: estimate (or se), optionally as a magnitude or scaled (100 for percentage points)
tm  <- function(term_, d = 2, what = "est", mag = FALSE, scale = 1, tab = thrm) { r <- tab[term == term_]; if (nrow(r) != 1) stop("pooled-model term not found: ", term_); v <- scale * r[[what]]; num(if (mag) abs(v) else v, d) }
fm  <- function(...) tm(..., tab = focm)                            # the same for the focal-answer quantities
pps <- function(tab, term_, d = 1) num(100 * row_(tab, term_)$re_se, d)             # standard error in percentage points
# number of systems whose estimate of a per-system term is significantly negative ("neg") or positive ("pos") at 5 per cent
csig <- function(tab, term_, dir = "neg") { x <- tab[term == term_ & !is.na(est) & !is.na(se) & se > 0]; if (!nrow(x)) stop("per-system term not found: ", term_); if (dir == "neg") sum(x$est / x$se < -1.96) else sum(x$est / x$se > 1.96) }
# causal forest: one quantity of block (ate, calib, blp, blp_common, level, ols, ...) and model ("fe" = within schools, "nofe")
frow <- function(block_, term_, model_ = "fe") { r <- fo[model == model_ & block == block_ & term == term_]; if (nrow(r) != 1) stop("forest row not found: ", block_, " / ", term_, " / ", model_); r }
f_  <- function(block_, term_, d = 2, model_ = "fe") num(frow(block_, term_, model_)$est, d)
fse <- function(block_, term_, d = 3, model_ = "fe") num(frow(block_, term_, model_)$se, d)
fes <- function(block_, term_, d = 2, model_ = "fe") sprintf("%s (SE %s)", f_(block_, term_, d, model_), fse(block_, term_, max(d, 3), model_))
fesp <- function(block_, term_, d = 2, model_ = "fe") sprintf("%s, SE %s", f_(block_, term_, d, model_), fse(block_, term_, max(d, 3), model_))
fz  <- function(block_, term_, model_ = "fe") frow(block_, term_, model_)$est / frow(block_, term_, model_)$se
fp1 <- function(block_, term_, model_ = "fe") { p <- pnorm(fz(block_, term_, model_), lower.tail = FALSE); if (p < 0.001) "< 0.001" else formatC(p, format = "f", digits = if (p < 0.01) 3 else 2) }   # one-sided, for the calibration test
# pooled estimate of one region (or "All systems") for file gap / bench / rs and one term
rrow <- function(region_, file_, term_) { r <- rgp[region == region_ & file == file_ & term == term_]; if (nrow(r) != 1) stop("region row not found: ", region_, " / ", term_); r }
rmin <- function(file_, term_) rgp[file == file_ & term == term_ & region != "All systems"][which.min(re_mean)]    # region with the most negative estimate
rmax <- function(file_, term_) rgp[file == file_ & term == term_ & region != "All systems"][which.max(re_mean)]
# cutoff IV (pooled, legacy skillsgain format)
krow <- function(spec_, outcome_, term_ = "gamma", set_ = "all 20") { r <- cut[spec == spec_ & outcome == outcome_ & term == term_ & set == set_]; if (nrow(r) != 1) stop("cutoff row not found"); r }
k   <- function(spec_, outcome_, term_ = "gamma", set_ = "all 20", d = 3, scale = 1) num(scale * krow(spec_, outcome_, term_, set_)$re_mean, d)
kse <- function(spec_, outcome_, term_ = "gamma", set_ = "all 20", d = 3, scale = 1) num(scale * krow(spec_, outcome_, term_, set_)$re_se, d)
kt  <- function(spec_, outcome_, term_ = "gamma", set_ = "all 20") num(krow(spec_, outcome_, term_, set_)$re_mean / krow(spec_, outcome_, term_, set_)$re_se, 1)
ksig <- function(spec_, outcome_, term_ = "gamma", set_ = "all 20", dir = "neg") krow(spec_, outcome_, term_, set_)[[paste0("sig_", dir)]]
# resilience x self-regulation, two raters
ob  <- function(term_, sample_ = "all", what = "est", d = 3) num(orivb[term == term_ & sample == sample_][[what]], d)
fig <- function(name) file.path(FIGS, paste0(name, ".pdf"))
N <- list(students = sum(cov$n), systems = nrow(cov), R = sum(gap_sys[term == "n:R", est]), PL = sum(gap_sys[term == "n:PL", est]),
          parR = orivb[term == "n:R" & sample == "all", est], parPL = orivb[term == "n:PL" & sample == "all", est])
