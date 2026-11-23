# IV learning -- step 9, question 3: does a year add the same across the achievement distribution? Cutoff systems.
# Instrumental-variable quantile regression (ivqr() in 00_helpers.R) at the 10th, 25th, 50th, 75th and 90th percentile of combined
# achievement, per system: gamma_q (yearly gain at that percentile) and tau_q (gain with birth month fixed), and inside every replicate
# the contrasts 90th minus 10th and 75th minus 25th. Ten plausible values and 80 replicate weights.
# A system-quantile whose estimate falls outside -200 to 300 points in the full sample, any plausible value or any replicate has no
# estimate and is left out of the summary for that quantile; the count of usable systems is reported for each.
# The estimates rest on rank similarity: a student's rank in the score distribution is the same in either grade, up to noise.
# Reads central products and step 1's first stage. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/09_quantile_iv.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
STEP1 <- Sys.getenv("STEP1_DIR", file.path(PROJECT, "04_output/estimate_20261122_step1"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
QS <- c(10, 25, 50, 75, 90)
fs <- fread(file.path(STEP1, "first_stage_sys.csv"))[term == "fs", .(CNT, fs = est, share_repeated, flagged)]
SYS <- sort(unique(a$CNT)); log_step("quantile IV on", length(SYS), "systems")
stat <- function(dt, y, w) { ok <- is.finite(y) & is.finite(w)
  e <- sapply(QS / 100, function(q) ivqr(y[ok], dt$D[ok], dt$Z[ok], dt$r[ok], w[ok], q))
  g <- setNames(e["gamma", ], paste0("gamma_", QS)); t <- setNames(e["tau", ], paste0("tau_", QS))
  c(g, t, gamma_90_10 = unname(g["gamma_90"] - g["gamma_10"]), gamma_75_25 = unname(g["gamma_75"] - g["gamma_25"]),
    tau_90_10 = unname(t["tau_90"] - t["tau_10"]), tau_75_25 = unname(t["tau_75"] - t["tau_25"])) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(data.table(CNT = cn, pisa_est(a[CNT == cn], stat, PV("ACH"))), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
g <- merge(rbindlist(res), fs, by = "CNT"); g[, usable := is.finite(est) & is.finite(se) & se > 0]
fwrite(g, paste0(OUT, "quantile_iv_sys.csv"))
k <- g[usable == TRUE]
pl <- rbind(k[, pool(est, se), by = term][, set := "all (Ukraine out)"], k[fs >= .5, pool(est, se), by = term][, set := "first stage 0.5 or more"],
            k[flagged == FALSE, pool(est, se), by = term][, set := "without Israel"], k[share_repeated < .05, pool(est, se), by = term][, set := "repetition under 5%"])
pl <- merge(pl, k[, .(median_se = median(se)), by = term], by = "term")
fwrite(pl, paste0(OUT, "quantile_iv_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "09_quantile_iv", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, quantiles = QS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, file.path(STEP1, "first_stage_sys.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
ord <- c(paste0("gamma_", QS), "gamma_75_25", "gamma_90_10", paste0("tau_", QS), "tau_75_25", "tau_90_10")
for (st in c("all (Ukraine out)", "first stage 0.5 or more", "repetition under 5%")) { cat("\n", st, "\n", sep = "")
  print(pl[set == st][match(ord, term), .(term, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), I2 = round(I2), median_se = round(median_se, 1), pos_05, pos_10, neg_05, neg_10)]) }
cat("\nsystems without an estimate, by term:\n"); print(g[usable == FALSE, .(systems = paste(CNT, collapse = " ")), by = term])
log_step("done"); sink()
