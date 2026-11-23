# IV learning -- step 14, skills proposal 3: among low-SES students, do those with stronger skills gain more from a year?
#   (a) within the low and within the high SES third: change in the yearly / same-age gain per SD of the skill, and low minus high
#   (b) all students: the three-way term, gain x skill x SES (negative = skills raise the gain more where SES is lower)
#   (c) four groups, SES third (low, high) by skill half (below, above the system median): the yearly gain in each, and
#       low SES with strong skills against high SES with weak skills, and against all high-SES students
# Skill = LEARN, the index of the six learning skills (step 13); (b) also for each scale. Skills are measured at 15 and a year moves
# them by at most 0.07 SD (step 13), so they are read as traits the student brings, approximately.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/14_skills_catchup.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
L6 <- paste0(c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL"), "_z"); SK <- c(L6, "BELONG_z")
a[, LEARN := { m <- as.matrix(.SD); ifelse(rowSums(!is.na(m)) >= 4, rowMeans(m, na.rm = TRUE), NA_real_) }, .SDcols = L6]
a[, LEARN := { m <- wmean(LEARN, W_FSTUWT); (LEARN - m) / sqrt(wmean((LEARN - m)^2, W_FSTUWT)) }, by = CNT]
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
wmed <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); x[ok][o][which(cw >= .5)[1]] }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]; a[, strong := as.numeric(LEARN > wmed(LEARN, W_FSTUWT)), by = CNT]
a[, `:=`(lo_weak = as.numeric(ses3 == 1 & strong == 0), lo_strong = as.numeric(ses3 == 1 & strong == 1), hi_weak = as.numeric(ses3 == 3 & strong == 0), hi_strong = as.numeric(ses3 == 3 & strong == 1))]
has <- function(s, v) all(vapply(v, function(x) mean(!is.na(s[[x]])) >= .5, logical(1)))
SYS <- a[, .(ok = mean(!is.na(ESCS)) > 0 & mean(!is.na(LEARN)) >= .5), by = CNT][ok == TRUE, sort(CNT)]
log_step("skills and catching up on", length(SYS), "systems")
one <- function(cn) { s <- a[CNT == cn]; out <- list()
  # (a) within SES thirds
  out[[1]] <- data.table(part = "within thirds", var = "LEARN", pisa_est(s[!is.na(LEARN) & ses3 %in% c(1, 3)], function(dt, y, w) {
    f <- function(k) { i <- dt$ses3 == k; grade_gain(dt[i], y[i], w[i], mods = "LEARN")[c("gamma", "gamma:LEARN", "tau:LEARN", "main:LEARN")] }
    lo <- f(1); hi <- f(3)
    c(low_gain = unname(lo[1]), low_gamma_skill = unname(lo[2]), low_tau_skill = unname(lo[3]), low_level_skill = unname(lo[4]),
      high_gain = unname(hi[1]), high_gamma_skill = unname(hi[2]), high_tau_skill = unname(hi[3]), high_level_skill = unname(hi[4]),
      gamma_skill_low_minus_high = unname(lo[2] - hi[2]), tau_skill_low_minus_high = unname(lo[3] - hi[3])) }, PV("ACH")))
  # (b) three-way term, index and each scale
  for (m in c("LEARN", SK)) if (has(s, m)) { s[, `:=`(M = get(m), MxS = get(m) * ESCS_z)]
    e <- pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = c("M", "ESCS_z", "MxS"))[c("gamma:M", "gamma:ESCS_z", "gamma:MxS", "tau:MxS", "main:MxS")], PV("ACH"))
    out[[length(out) + 1]] <- data.table(part = "three-way", var = m, e) }
  # (c) four groups; the middle SES third is the reference and drops out of the contrasts
  out[[length(out) + 1]] <- data.table(part = "groups", var = "LEARN", pisa_est(s[!is.na(LEARN) & !is.na(ses3)], function(dt, y, w) {
    g <- grade_gain(dt, y, w, mods = c("lo_weak", "lo_strong", "hi_weak", "hi_strong")); G <- function(k) unname(g["gamma"] + g[paste0("gamma:", k)])
    sh <- wmean(dt$hi_strong[dt$ses3 == 3], w[dt$ses3 == 3]); hi_all <- sh * G("hi_strong") + (1 - sh) * G("hi_weak")
    c(gain_lo_weak = G("lo_weak"), gain_lo_strong = G("lo_strong"), gain_hi_weak = G("hi_weak"), gain_hi_strong = G("hi_strong"),
      lo_strong_minus_lo_weak = G("lo_strong") - G("lo_weak"), hi_strong_minus_hi_weak = G("hi_strong") - G("hi_weak"),
      lo_strong_minus_hi_weak = G("lo_strong") - G("hi_weak"), lo_strong_minus_hi_all = G("lo_strong") - hi_all,
      level_lo_strong_minus_hi_weak = unname(g["main:lo_strong"] - g["main:hi_weak"])) }, PV("ACH")))
  cbind(CNT = cn, rbindlist(out)) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(one(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
g <- rbindlist(res); g[, flagged := CNT %in% FLAG]; fwrite(g, paste0(OUT, "skills_catchup_sys.csv"))
k <- g[is.finite(est) & is.finite(se) & se > 0]; by <- c("part", "var", "term")
pl <- rbind(k[, pool(est, se), by = by][, set := "all (Ukraine out)"], k[flagged == FALSE, pool(est, se), by = by][, set := "without Israel"])
fwrite(pl, paste0(OUT, "skills_catchup_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "14_skills_catchup", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220); P <- pl[set == "all (Ukraine out)"]
sh <- function(x) x[, .(part, var, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), z = round(re_mean / re_se, 2), sd_across = round(tau_sd, 2), pos_05, pos_10, neg_05, neg_10)]
cat("\n(a) within SES thirds, per SD of the skill index (points)\n"); print(sh(P[part == "within thirds"]))
cat("\n(b) three-way term: change in the skill effect on the yearly gain per SD of SES\n"); print(sh(P[part == "three-way" & term %in% c("gamma:MxS", "tau:MxS")][order(term, var)]))
cat("\n(c) four groups: yearly gain (points)\n"); print(sh(P[part == "groups"]))
log_step("done"); sink()
