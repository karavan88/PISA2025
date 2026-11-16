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
orivb <- rd("oriv_resil.csv")
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
# resilience x self-regulation, two raters
ob  <- function(term_, sample_ = "all", what = "est", d = 3) num(orivb[term == term_ & sample == sample_][[what]], d)
fig <- function(name) file.path(FIGS, paste0(name, ".pdf"))
N <- list(students = sum(cov$n), systems = nrow(cov), R = sum(gap_sys[term == "n:R", est]), PL = sum(gap_sys[term == "n:PL", est]),
          parR = orivb[term == "n:R" & sample == "all", est], parPL = orivb[term == "n:PL" & sample == "all", est])

# ------------------------------------------------------------------ status x achievement matrix (steps 16-18): Data section, Table 1, Appendix Table A1
source(file.path("..", "01_code", "system_names.R"))                # NAMES: system names by PISA code (shared with the figures)
desc <- rd("desc_sys.csv"); mx_sys <- rd("mxmod_sys.csv"); mxp <- rd("mxmod_pool.csv"); mat_sys <- rd("matrix_sys.csv")
MX_SYS <- sort(unique(mx_sys$CNT)); stopifnot(all(MX_SYS %in% names(NAMES)), setequal(MX_SYS, unique(desc$CNT)))
# a cell statistic of the matrix (mean, ls10, share), mean over the systems in the models (each system weighted equally)
mat <- function(stat, cell) mat_sys[CNT %in% MX_SYS & term == paste0(stat, ":", cell), mean(est)]
mat_rshare <- function() mat_sys[CNT %in% MX_SYS & grepl("^share:S1A", term), .(r = est[term == "share:S1A4"] / sum(est)), by = CNT][, mean(r)]   # resilient share of disadvantaged students
N_mx <- list(systems = length(MX_SYS), students = sum(desc[var == "n_model", mean]), all = sum(desc[var == "n_students", mean]),
             R = sum(desc[var == "n:S1A4", mean]), PL = sum(desc[var == "n:S1A1", mean]), AL = sum(desc[var == "n:S4A1", mean]), AT = sum(desc[var == "n:S4A4", mean]))
DASH <- "\u2013"                                                 # en dash; tables use literal characters so that pandoc sizes columns by their visible width
# value of one variable in one system, formatted; "–" where the system did not field it (fewer than half the students observed)
dval <- function(cnt, v, f) { r <- desc[CNT == cnt & var == v]; if (nrow(r) != 1) stop("descriptive not found: ", cnt, " / ", v); if (!is.na(r$obs) && r$obs < .5) DASH else f(r$mean) }
tnum <- function(x, d) sub("&minus;", "\u2212", num(x, d), fixed = TRUE)
f0 <- function(x) tnum(x, 0); f1 <- function(x) tnum(x, 1); f2 <- function(x) tnum(x, 2); fpc <- function(x) tnum(100 * x, 0); fbig <- function(x) big(x)
# Table 1: one row per system, one column per variable (means), and the mean of systems
T1 <- list(n_students = c("N", "fbig"), LS = c("Life sat.", "f2"), LS10 = c("Ans. 10 %", "fpc"), READ = c("Read.", "f0"), SCIE = c("Sci.", "f0"),
           ESCS = c("ESCS", "f2"), female = c("Fem. %", "fpc"), AGE = c("Age", "f1"), below_grade = c("Below gr. %", "fpc"),
           PERSEV = c("Pers.", "f2"), CURIO = c("Cur.", "f2"), ENPROBS = c("Enj. PS", "f2"), COGABIL = c("Cog. ad.", "f2"), GOALSET = c("Goal", "f2"),
           SELFREG = c("Self-reg.", "f2"), growth = c("Growth %", "fpc"), EFFSCIE = c("Sci. eff.", "f2"), JOYSCIE = c("Sci. enj.", "f2"),
           BELONG = c("Belong.", "f2"), BULLIED = c("Bullied", "f2"), FAMSUP = c("Fam. sup.", "f2"), FEELSAFE = c("Safe", "f2"))
tab_systems <- function() {
  ord <- MX_SYS[order(NAMES[MX_SYS])]
  rows <- lapply(ord, function(cn) c(NAMES[[cn]], vapply(names(T1), function(v) dval(cn, v, get(T1[[v]][2])), "")))
  avg <- c(sprintf("Mean of %d systems", length(ord)), vapply(names(T1), function(v) { x <- desc[CNT %in% ord & var == v & (is.na(obs) | obs >= .5), mean]; get(T1[[v]][2])(mean(x)) }, ""))
  m <- do.call(rbind, c(rows, list(avg))); colnames(m) <- c("System", vapply(T1, `[`, "", 1))
  m[nrow(m), ] <- paste0("**", m[nrow(m), ], "**")
  knitr::kable(m, format = "pipe", align = c("l", rep("r", ncol(m) - 1)))
}
# Appendix Table A1: model sample and the share of students observed on each variable (– = not fielded)
TA <- list(LS = "Life sat.", ESCS = "ESCS", female = "Sex", PERSEV = "Pers.", CURIO = "Cur.", ENPROBS = "Enj. PS", COGABIL = "Cog. ad.", GOALSET = "Goal",
           SELFREG = "Self-reg.", growth = "Growth", EFFSCIE = "Sci. eff.", JOYSCIE = "Sci. enj.", BELONG = "Belong.", BULLIED = "Bullied", FAMSUP = "Fam. sup.", FEELSAFE = "Safe")
tab_avail <- function() {
  ord <- MX_SYS[order(NAMES[MX_SYS])]
  g <- function(cn, v) desc[CNT == cn & var == v, mean]
  rows <- lapply(ord, function(cn) c(NAMES[[cn]], big(g(cn, "n_students")), big(g(cn, "n_model")), big(g(cn, "n:S1A4")), big(g(cn, "n:S1A1")), big(g(cn, "n:S4A1")), big(g(cn, "n:S4A4")),
                                    fpc(desc[CNT == cn & var == "school_id", obs]),
                                    vapply(names(TA), function(v) { o <- desc[CNT == cn & var == v, obs]; if (o < .5) DASH else fpc(o) }, "")))
  m <- do.call(rbind, rows); colnames(m) <- c("System", "Students", "Model", "Resil.", "Dis. low", "Adv. low", "Adv. top", "School ID", unlist(TA))
  knitr::kable(m, format = "pipe", align = c("l", rep("r", ncol(m) - 1)))
}

# ------------------------------------------------------------------ nested models on the matrix (step 17): Table 2 and the Results text
# term of step 17: contrast t (S1A4, S1A1, S4A1, R-PL, R-AL, DiD) in model m (M1..M6), outcome y (z = SD, pt = 0-10 points)
mxt  <- function(t, m, y = "z") paste0("mm:", y, ":", m, ":", t)
mrow <- function(term_) { r <- mxp[term == term_]; if (nrow(r) != 1) stop("step-17 term not found: ", term_); r }
me   <- function(t, m, d = 2, y = "z") num(mrow(mxt(t, m, y))$re_mean, d)
mea  <- function(t, m, d = 2, y = "z") num(abs(mrow(mxt(t, m, y))$re_mean), d)
mse  <- function(t, m, d = 3, y = "z") num(mrow(mxt(t, m, y))$re_se, d)
mes  <- function(t, m, d = 2, y = "z") sprintf("%s (SE %s)", me(t, m, d, y), mse(t, m, max(d, 3), y))
mn   <- function(t, m) mrow(mxt(t, m))$n_sys
# systems with the estimate negative, or significantly negative / positive at 5 per cent (two-sided)
mx_s <- function(t, m) mx_sys[term == mxt(t, m) & !is.na(est) & !is.na(se) & se > 0]
mneg <- function(t, m) sum(mx_s(t, m)$est < 0)
msig <- function(t, m, dir = "neg") { x <- mx_s(t, m); if (dir == "neg") sum(x$est / x$se < -1.96) else sum(x$est / x$se > 1.96) }
# systems in which resilient students are significantly below all three other groups (each one-sided test at 5 per cent)
mall3 <- function(m) { x <- mx_sys[term %in% mxt(c("S1A4", "R-PL", "R-AL"), m) & !is.na(est) & se > 0]; x[, .(ok = .N == 3 && all(est / se < -1.645)), by = CNT][, sum(ok)] }
# Gelbach contribution (M3 -> M5) of variable or block v to contrast c (R-AT, R-PL, R-AL)
gl   <- function(c, v, d = 3) { r <- mxp[term == paste0("gel:", c, ":", v)]; if (nrow(r) != 1) stop("Gelbach term not found: ", c, " / ", v); num(r$re_mean, d) }
gla  <- function(c, v, d = 3) { r <- mxp[term == paste0("gel:", c, ":", v)]; num(abs(r$re_mean), d) }
glse <- function(c, v, d = 3) num(mxp[term == paste0("gel:", c, ":", v)]$re_se, d)
# Table 2: six nested models, coefficient with its standard error below
tab_models <- function() {
  M <- paste0("M", 1:6); cf <- function(t) vapply(M, function(m) tnum(mrow(mxt(t, m))$re_mean, 2), ""); sf <- function(t) vapply(M, function(m) paste0("(", tnum(mrow(mxt(t, m))$re_se, 3), ")"), "")
  rows <- list(c("*A. Against advantaged top achievers*", rep("", 6)),
               c("Resilient students", cf("S1A4")), c("", sf("S1A4")),
               c("Disadvantaged low achievers", cf("S1A1")), c("", sf("S1A1")),
               c("Advantaged low achievers", cf("S4A1")), c("", sf("S4A1")),
               c("*B. Contrasts from the same model*", rep("", 6)),
               c("Resilient \u2212 advantaged low achievers", cf("R-AL")), c("", sf("R-AL")),
               c("Resilient \u2212 disadvantaged low achievers", cf("R-PL")), c("", sf("R-PL")),
               c("Resilient \u2212 all other disadvantaged", cf("R-PO")), c("", sf("R-PO")),
               c("Achievement gap, disadvantaged \u2212 advantaged", cf("DiD")), c("", sf("DiD")),
               c("  the same over all achievement levels", cf("DiD2")), c("", sf("DiD2")),
               c("*C. Systems where resilient students are significantly lower*", rep("", 6)),
               c("than advantaged top achievers", vapply(M, function(m) as.character(msig("S1A4", m)), "")),
               c("than advantaged low achievers", vapply(M, function(m) as.character(msig("R-AL", m)), "")),
               c("than disadvantaged low achievers", vapply(M, function(m) as.character(msig("R-PL", m)), "")),
               c("than all three (one-sided tests)", vapply(M, function(m) as.character(mall3(m)), "")),
               c("School fixed effects", "", "Yes", "Yes", "Yes", "Yes", ""),
               c("Sex, age, grade", "", "", "Yes", "Yes", "Yes", "Yes"),
               c("Skills and mindsets", "", "", "", "Yes", "Yes", "Yes"),
               c("Relationships", "", "", "", "", "Yes", "Yes"),
               c("Systems", vapply(M, function(m) as.character(mn("S1A4", m)), "")),
               c("Students", rep(big(N_mx$students), 6)))
  m <- do.call(rbind, rows); colnames(m) <- c("", paste0("(", 1:6, ")"))
  knitr::kable(m, format = "pipe", align = c("l", rep("c", 6)))
}

# ------------------------------------------------------------------ answer scale and scale use (step 19), science versions (steps 17, 19), funnel
mxa <- rd("mxans_pool.csv"); mxa_sys <- rd("mxans_sys.csv"); mxps <- rd("mxmod_pool_scie.csv"); mxas <- rd("mxans_pool_scie.csv")
arow <- function(t, tab = mxa) { r <- tab[term == t]; if (nrow(r) != 1) stop("step-19 term not found: ", t); r }
app  <- function(t, d = 1, tab = mxa) num(100 * arow(t, tab)$re_mean, d)             # share difference in percentage points
appa <- function(t, d = 1, tab = mxa) num(abs(100 * arow(t, tab)$re_mean), d)
apse <- function(t, d = 1, tab = mxa) num(100 * arow(t, tab)$re_se, d)
ae   <- function(t, d = 2, tab = mxa) num(arow(t, tab)$re_mean, d)                    # in SD
aea  <- function(t, d = 2, tab = mxa) num(abs(arow(t, tab)$re_mean), d)
ase  <- function(t, d = 3, tab = mxa) num(arow(t, tab)$re_se, d)
asneg <- function(t, tab = mxa) arow(t, tab)$sig_neg
msc  <- function(t, m, d = 2) { r <- mxps[term == mxt(t, m)]; if (nrow(r) != 1) stop("science term not found"); num(r$re_mean, d) }   # science version of a step-17 contrast
mscn <- function(t, m) mxps[term == mxt(t, m)]$n_sys
mI2  <- function(t, m) num(mrow(mxt(t, m))$I2, 0)
mtau <- function(t, m) num(mrow(mxt(t, m))$tau_sd, 2)
# systems whose estimate lies within 1.96 of its own standard errors of the pooled mean (inside the funnel of the RQ2 figure)
mfun <- function(t, m) { x <- mx_s(t, m); sum(abs(x$est - mrow(mxt(t, m))$re_mean) <= 1.96 * x$se) }
mfun_out <- function(t, m) { x <- mx_s(t, m); n <- sort(NAMES[x[abs(est - mrow(mxt(t, m))$re_mean) > 1.96 * se, CNT]]); n <- sub("^Philippines$", "the Philippines", n); if (length(n) < 2) n else paste(paste(head(n, -1), collapse = ", "), "and", tail(n, 1)) }
mse_range <- function(t, m) { x <- mx_s(t, m)$se; sprintf("%s to %s", num(min(x), 2), num(max(x), 2)) }
