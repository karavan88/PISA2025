# Reporting helpers for "The price of progress". Reads the approved snapshot (../02_results/snapshot) only; estimates nothing.
# Sourced from ../03_manuscript/*.qmd (working directory = that folder). The snapshot is verified by 01_code/snapshot.py check.
suppressPackageStartupMessages(library(data.table))
OUT <- normalizePath(file.path("..", "02_results", "snapshot")); FIGS <- file.path("..", "02_results", "figs")
rd <- function(f) fread(file.path(OUT, f))
T <- list(x = rd("extras_pool.csv"))
oriv <- rd("oriv_pool.csv"); oriv_sys <- rd("oriv_sys.csv")        # two-rater estimates are a snapshot of paper 03's output
cut <- rd("cutoff_pool.csv"); cut_sys <- rd("cutoff_sys.csv"); cov <- rd("coverage.csv")

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
# two raters
orow <- function(term_, sample_ = "all") { r <- oriv[term == term_ & sample == sample_]; if (nrow(r) != 1) stop("oriv row not found: ", term_); r }
o   <- function(term_, sample_ = "all", d = 2) num(orow(term_, sample_)$re_mean, d)
ose <- function(term_, sample_ = "all", d = 3) num(orow(term_, sample_)$re_se, d)
fig <- function(name) file.path(FIGS, paste0(name, ".pdf"))
N <- list(students = sum(cov$n), systems = nrow(cov), iv_students = sum(cut_sys[spec == "base" & outcome == "LS_z" & term == "gamma", n]), iv_systems = uniqueN(cut_sys$CNT),
          par_students = sum(oriv_sys[term == "n", est]), par_systems = uniqueN(oriv_sys$CNT))
