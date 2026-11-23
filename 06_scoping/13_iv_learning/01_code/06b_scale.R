# IV learning -- step 6b: descriptive quantities that put the estimates on a scale. No model is fitted.
#   sd_ach            within-system standard deviation of combined achievement (mean over the ten plausible values), to express
#                     the yearly gain in standard deviations
#   rank_low/high     mean achievement percentile (within the system) of students in the low and the high SES third, to translate
#                     the gradient along the achievement distribution into an expected difference between the thirds
#   n, schools        students and schools in the analytic file; share of students in the two main grades; OECD membership
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/06b_scale.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
wsd <- function(x, w) { m <- wmean(x, w); sqrt(wmean((x - m)^2, w)) }
wrank <- function(x, w) { o <- order(x); r <- numeric(length(x)); r[o] <- (cumsum(w[o]) - w[o] / 2) / sum(w); 100 * r }
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]
one <- function(s) { w <- s$W_FSTUWT; k <- !is.na(s$ses3)
  rk <- sapply(PV("ACH"), function(p) { r <- wrank(s[[p]][k], w[k]); c(wmean(r[s$ses3[k] == 1], w[k][s$ses3[k] == 1]), wmean(r[s$ses3[k] == 3], w[k][s$ses3[k] == 3])) })
  list(n = nrow(s), schools = uniqueN(s$CNTSCHID), oecd = s$OECD[1], share_two_grades = wmean(as.numeric(s$grade == s$g_lo | s$grade == s$g_hi), w), share_repeated = wmean(s$repeated, w),
       escs = mean(k), sd_ach = mean(sapply(PV("ACH"), function(p) wsd(s[[p]], w))), rank_low = if (any(k)) mean(rk[1, ]) else NA_real_, rank_high = if (any(k)) mean(rk[2, ]) else NA_real_) }
sy <- a[, one(.SD), by = CNT]; fwrite(sy, paste0(OUT, "scale_sys.csv"))
sm <- sy[, .(systems = .N, students = sum(n), schools = sum(schools), oecd_systems = sum(oecd == 1), share_two_grades = sum(share_two_grades * n) / sum(n), sd_ach = mean(sd_ach),
             systems_with_ses = sum(escs > 0), rank_low = mean(rank_low, na.rm = TRUE), rank_high = mean(rank_high, na.rm = TRUE), low_repetition_systems = sum(share_repeated < .05))]
fwrite(sm, paste0(OUT, "scale_summary.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "06b_scale", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE), excluded = EXCLUDE,
  md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
print(sm); log_step("done"); sink()
