# IV learning -- step 15, skills proposal 6 (rigorous version): does a year still add more at the top of the achievement distribution
# among students with the same skills?
# Per system and replicate, on students with the skill index LEARN (step 13):
#   base         quantile instrumental variables as in step 9 (grade, birth month, instrument)
#   skills held  the same with LEARN as a covariate at every quantile, after removing from the score the part of the gain and of the age
#                slope that goes with LEARN (their two-stage least squares estimates, from the same sample and replicate):
#                score - t_L x grade x LEARN - b_L x birth month x LEARN.  The gain is then that of a student with average skills,
#                at each percentile of achievement among students with the same skills.
# Reported at the 10th, 25th, 50th, 75th and 90th percentile: the yearly gain under both, the contrasts 90-10 and 75-25 under both, and
# the change in each contrast (skills held minus base), all inside the replicate so that the change has its own standard error.
# Conditional and unconditional percentiles are not the same students: "the 10th percentile among students with the same skills" is not
# "the 10th percentile". The comparison shows how much of the gradient survives inside skill groups.
# Reads central products and step 1's first stage. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/15_quantile_iv_skills.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
STEP1 <- Sys.getenv("STEP1_DIR", file.path(PROJECT, "04_output/estimate_20261122_step1"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
L6 <- paste0(c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL"), "_z")
a[, LEARN := { m <- as.matrix(.SD); ifelse(rowSums(!is.na(m)) >= 4, rowMeans(m, na.rm = TRUE), NA_real_) }, .SDcols = L6]
a[, LEARN := { m <- wmean(LEARN, W_FSTUWT); (LEARN - m) / sqrt(wmean((LEARN - m)^2, W_FSTUWT)) }, by = CNT]
SYS <- a[, .(ok = mean(!is.na(LEARN)) >= .5), by = CNT][ok == TRUE, sort(CNT)]; a <- a[CNT %in% SYS & !is.na(LEARN)]
QS <- c(10, 25, 50, 75, 90); fs <- fread(file.path(STEP1, "first_stage_sys.csv"))[term == "fs", .(CNT, fs = est, share_repeated, flagged)]
log_step("quantile IV with skills held fixed on", length(SYS), "systems,", nrow(a), "students")
stat <- function(dt, y, w) { ok <- is.finite(y) & is.finite(w); y <- y[ok]; w <- w[ok]; D <- dt$D[ok]; Z <- dt$Z[ok]; r <- dt$r[ok]; L <- dt$LEARN[ok]
  g <- grade_gain(dt[ok], y, w, mods = "LEARN"); ys <- y - g["tau:LEARN"] * D * L + (g["age:LEARN"] / 12) * r * L       # age:LEARN = -12 x coefficient on r x LEARN
  b <- sapply(QS / 100, function(q) ivqr(y, D, Z, r, w, q)["gamma"]); s <- sapply(QS / 100, function(q) ivqr(ys, D, Z, r, w, q, extra = cbind(L = L))["gamma"])
  names(b) <- paste0("base_", QS); names(s) <- paste0("held_", QS)
  c(b, s, base_90_10 = unname(b[5] - b[1]), held_90_10 = unname(s[5] - s[1]), change_90_10 = unname((s[5] - s[1]) - (b[5] - b[1])),
    base_75_25 = unname(b[4] - b[2]), held_75_25 = unname(s[4] - s[2]), change_75_25 = unname((s[4] - s[2]) - (b[4] - b[2])), gain_per_sd_skill = unname(g["gamma:LEARN"])) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(data.table(CNT = cn, pisa_est(a[CNT == cn], stat, PV("ACH"))), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
g <- merge(rbindlist(res), fs, by = "CNT"); g[, usable := is.finite(est) & is.finite(se) & se > 0]; fwrite(g, paste0(OUT, "quantile_iv_skills_sys.csv"))
k <- g[usable == TRUE]
pl <- rbind(k[, pool(est, se), by = term][, set := "all (Ukraine out)"], k[fs >= .5, pool(est, se), by = term][, set := "first stage 0.5 or more"], k[flagged == FALSE, pool(est, se), by = term][, set := "without Israel"])
fwrite(pl, paste0(OUT, "quantile_iv_skills_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "15_quantile_iv_skills", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, quantiles = QS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, file.path(STEP1, "first_stage_sys.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200); ord <- c(paste0("base_", QS), paste0("held_", QS), "base_75_25", "held_75_25", "change_75_25", "base_90_10", "held_90_10", "change_90_10", "gain_per_sd_skill")
for (st in c("all (Ukraine out)", "first stage 0.5 or more")) { cat("\n", st, "\n", sep = "")
  print(pl[set == st][match(ord, term), .(term, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), z = round(re_mean / re_se, 2), sd_across = round(tau_sd, 1), pos_05, pos_10, neg_05, neg_10)]) }
cat("\nsystems without an estimate, by term:\n"); print(g[usable == FALSE, .(systems = paste(CNT, collapse = " ")), by = term])
log_step("done"); sink()
