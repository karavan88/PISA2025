# IV learning -- step 16: an instrumental forest as a robustness check on the skills results (steps 13 and 14). Exploratory.
# Question: does a flexible method find differences in the gain from a grade by the student's skills and family background that the
# straight-line interactions missed?
# What the forest estimates: the gain with birth month fixed (tau), not the yearly gain. The instrument is a function of birth month, so
# birth month cannot be a forest covariate; its linear trend is removed from the score beforehand with each system's own slope
# (score* = score - b r, b from the system's two-stage least squares), and the forest compares the two birth sides.
# Set-up (grf): outcome = score* (mean of the ten plausible values of combined achievement; the package takes one outcome), treatment
# = upper grade, instrument = born before the cutoff, covariates = the seven skill scales, ESCS, sex and immigrant background, all
# standardised within the system (missing values allowed). System means are taken out through the nuisance estimates; each system has
# the same total weight; schools are the clusters; the compliance score is the system's difference in grade between the birth sides.
# No leakage: no covariate is built from other students or from the outcome, and every judgement of the forest is made on schools it
# was not trained on. Schools are split in two halves inside each system; a forest trained on one half ranks the students of the
# other, and the ranking is scored there (rank-weighted average treatment effect, RATE): a ranking that picks out students who truly
# gain more gives a positive RATE. The skill index and ESCS are scored as rankings in the same way.
# Not handled by the package: replicate weights and plausible values. Standard errors are the package's, clustered by school.
# PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/16_forest.R        (FOREST_TREES, FOREST_FRAC for a quick trial)
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
suppressPackageStartupMessages(library(grf))
TREES <- as.integer(Sys.getenv("FOREST_TREES", "1000")); FRAC <- as.numeric(Sys.getenv("FOREST_FRAC", "1")); THREADS <- 6L; SEED <- 20261123L
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, y := rowMeans(.SD), .SDcols = PV("ACH")]
L6 <- paste0(c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL"), "_z"); SK <- c(L6, "BELONG_z")
a[, LEARN := { m <- as.matrix(.SD); ifelse(rowSums(!is.na(m)) >= 4, rowMeans(m, na.rm = TRUE), NA_real_) }, .SDcols = L6]
a[, LEARN := { m <- wmean(LEARN, W_FSTUWT); (LEARN - m) / sqrt(wmean((LEARN - m)^2, W_FSTUWT)) }, by = CNT]
SYS <- a[, .(ok = mean(!is.na(ESCS)) > 0 & mean(!is.na(LEARN)) >= .5), by = CNT][ok == TRUE, sort(CNT)]
a <- a[CNT %in% SYS & is.finite(y) & is.finite(W_FSTUWT)]
set.seed(SEED)
sch <- unique(a[, .(CNT, CNTSCHID)]); sch[, `:=`(u = runif(.N), cl = .I)]
if (FRAC < 1) sch <- sch[u < quantile(u, FRAC)]                              # trial runs only
sch[, fold := 1L + (rank(u) > .N / 2), by = CNT]                             # two halves of schools inside each system
a <- merge(a, sch[, .(CNT, CNTSCHID, cl, fold)], by = c("CNT", "CNTSCHID"))
# each system's age slope, the score cleared of it, system means, and the compliance score
a[, b := { g <- grade_gain(.SD, y, W_FSTUWT); (g["tau"] - g["gamma"]) / 12 }, by = CNT, .SDcols = c("D", "Z", "r")]
a[, ys := y - b * r]
a[, wt := W_FSTUWT / sum(W_FSTUWT), by = CNT]; a[, wt := wt / mean(wt)]                # every system has the same total weight
a[, `:=`(mY = wmean(ys, wt), mD = wmean(D, wt), pZ = wmean(Z, wt), comp = wmean(D[Z == 1], wt[Z == 1]) - wmean(D[Z == 0], wt[Z == 0])), by = .(CNT, fold)]
FEAT <- c(SK, "ESCS_z", "female", "immigrant"); X <- as.matrix(a[, ..FEAT])
log_step("forest on", length(SYS), "systems,", nrow(a), "students,", uniqueN(a$cl), "schools;", TREES, "trees; fraction of schools", FRAC)
fit <- function(i) { t0 <- Sys.time(); d <- a[i]; Xi <- X[i, , drop = FALSE]
  yh <- d$mY + predict(regression_forest(Xi, d$ys - d$mY, sample.weights = d$wt, clusters = d$cl, num.trees = 500, min.node.size = 50, num.threads = THREADS, seed = SEED))$predictions
  wh <- d$mD + predict(regression_forest(Xi, d$D - d$mD, sample.weights = d$wt, clusters = d$cl, num.trees = 500, min.node.size = 50, num.threads = THREADS, seed = SEED))$predictions
  wh <- pmin(pmax(wh, .01), .99)   # a centring value for grade, kept strictly inside 0 to 1 (the package refuses exact 0 or 1 and may still warn that values come close)
  f <- instrumental_forest(Xi, d$ys, d$D, d$Z, Y.hat = yh, W.hat = wh, Z.hat = d$pZ, sample.weights = d$wt, clusters = d$cl, num.trees = TREES, min.node.size = 100, num.threads = THREADS, seed = SEED)
  log_step("forest fitted on", nrow(d), "students in", round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min"); f }
iA <- which(a$fold == 1); iB <- which(a$fold == 2); fA <- fit(iA); fB <- fit(iB)
res <- list(); add <- function(what, half, est, se, extra = "") res[[length(res) + 1]] <<- data.table(what = what, half = half, est = est, se = se, note = extra)
rate <- function(f, idx, prio, lab, half) for (tg in c("AUTOC", "QINI")) { ok <- is.finite(prio)
  r <- rank_average_treatment_effect(f, prio[ok], target = tg, subset = ok, compliance.score = a$comp[idx], R = 200); add(paste(lab, tg), half, r$estimate, r$std.err) }
for (h in 1:2) { f <- list(fA, fB)[[h]]; idx <- list(iA, iB)[[h]]; other <- list(fB, fA)[[h]]; half <- c("trained on B, scored on A", "trained on A, scored on B")[h]
  ate <- average_treatment_effect(f, compliance.score = a$comp[idx]); add("average same-age gain", c("A", "B")[h], ate[["estimate"]], ate[["std.err"]])
  rate(f, idx, predict(other, X[idx, , drop = FALSE], num.threads = THREADS)$predictions, "RATE, forest ranking", half)
  rate(f, idx, a$LEARN[idx], "RATE, ranking by the skill index", c("A", "B")[h]); rate(f, idx, a$ESCS_z[idx], "RATE, ranking by ESCS", c("A", "B")[h])
  cc <- complete.cases(X[idx, c(SK, "ESCS_z"), drop = FALSE])
  if (mean(cc) > .3) { bl <- best_linear_projection(f, X[idx, c(SK, "ESCS_z"), drop = FALSE][cc, , drop = FALSE], subset = cc, compliance.score = a$comp[idx])
    for (k in rownames(bl)) add(paste("projection of the gain on", k), c("A", "B")[h], bl[k, "Estimate"], bl[k, "Std. Error"], sprintf("complete cases %.0f%%", 100 * mean(cc))) }
  vi <- variable_importance(f); for (k in seq_along(FEAT)) add(paste("importance", FEAT[k]), c("A", "B")[h], vi[k], NA_real_)
  pr <- predict(f)$predictions; add("spread of predicted gains (SD, out of bag)", c("A", "B")[h], sd(pr), NA_real_) }
r <- rbindlist(res); fwrite(r, paste0(OUT, "forest_results.csv"))
# the two halves are separate schools: average them, standard error from the two
k <- r[is.finite(se)][, `:=`(key = sub(" (AUTOC|QINI)$", " \\1", what))][, .(est = mean(est), se = sqrt(sum(se^2)) / .N, halves = .N), by = what][, z := est / se]
imp <- r[what %like% "^importance"][, .(importance = mean(est)), by = what][order(-importance)]
fwrite(k, paste0(OUT, "forest_summary.csv")); fwrite(imp, paste0(OUT, "forest_importance.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "16_forest", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE), grf = as.character(packageVersion("grf")),
  systems = SYS, trees = TREES, fraction = FRAC, seed = SEED, features = FEAT, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
cat("\nboth halves together (points for the gain and the projections; RATE in points)\n"); print(k[, .(what, est = round(est, 2), se = round(se, 2), z = round(z, 2), p = round(2 * pnorm(-abs(z)), 3), halves)], nrows = 60)
cat("\nvariable importance (share of splits, mean of the two halves)\n"); print(imp[, .(feature = sub("importance ", "", what), importance = round(importance, 3))])
cat("\nspread of predicted gains across students (SD):", paste(round(r[what %like% "^spread", est], 2), collapse = " and "), "\n")
log_step("done"); sink()
