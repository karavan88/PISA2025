# Reporting helpers for "The cost of resilience". Reads the approved snapshot (../02_results/snapshot) only; estimates nothing.
# Sourced from ../03_manuscript/*.qmd (working directory = that folder). The snapshot is verified by 01_code/snapshot.py check.
suppressPackageStartupMessages(library(data.table))
OUT <- normalizePath(file.path("..", "02_results", "snapshot")); FIGS <- file.path("..", "02_results", "figs")
rd <- function(f) fread(file.path(OUT, f))
T <- list(gap = rd("gap_pool.csv"), rs = rd("rs_pool.csv"), mech = rd("mech_pool.csv"), cur = rd("cur_pool.csv"))
orivb <- rd("oriv_resil.csv"); cut <- rd("cutoff_pool.csv")        # cutoff_pool.csv is a snapshot of paper 04's estimate
gap_sys <- rd("gap_sys.csv"); cov <- rd("coverage.csv")

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
