# IV learning -- step 8: does a year add less in schools with a disadvantaged intake? Cutoff systems with ESCS.
# School variables, each leaving the student out and standardised across the students of the system:
#   SCH_SES   mean ESCS of schoolmates
#   SCH_LOW   share of schoolmates in the system's low SES third
#   SCH_ACH   mean achievement of schoolmates in the lower grade only (the school's level of learning; the upper grade is left out
#             because its scores already contain the gain that is being estimated)
# The gain is interacted with these (instrumented by the instrument times the same variable), with the student's own SES alongside.
#   tau:SCH_SES / gamma:SCH_SES   change in the same-age / yearly gain per SD of school SES;  main:SCH_SES  the level difference
# Sample: students in schools with 5 or more sampled students in each of the two grades, so that the school a student attends does not
# depend on the grade the cutoff assigns. All schools are shown beside it for the first model only. School intake is not assigned at
# random: these are differences between schools as they are, not effects of changing a school's intake.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/08_school_ses.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a <- a[CNT %in% a[, .(e = mean(!is.na(ESCS))), by = CNT][e > 0, CNT]]
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
a[, low3 := as.numeric(third(ESCS, W_FSTUWT) == 1), by = CNT]; a[, ach := rowMeans(.SD), .SDcols = PV("ACH")]
loo <- function(x, w, use = rep(TRUE, length(x))) { k <- !is.na(x) & use; sw <- sum(w[k]); sx <- sum(w[k] * x[k]); (sx - ifelse(k, w * x, 0)) / (sw - ifelse(k, w, 0)) }
z <- function(x, w) { m <- wmean(x, w); (x - m) / sqrt(wmean((x - m)^2, w)) }
a[, `:=`(s_ses = loo(ESCS_z, W_FSTUWT), s_low = loo(low3, W_FSTUWT), s_ach = loo(ach, W_FSTUWT, D == 0), n_lo = sum(D == 0), n_hi = sum(D == 1)), by = .(CNT, CNTSCHID)]
for (v in c("s_ses", "s_low", "s_ach")) a[!is.finite(get(v)), (v) := NA_real_]
a[, same := n_lo >= 5 & n_hi >= 5]
a[, `:=`(SCH_SES = z(s_ses, W_FSTUWT), SCH_LOW = z(s_low, W_FSTUWT), SCH_ACH = z(s_ach, W_FSTUWT)), by = CNT]
info <- a[, .(students = .N, same_students = sum(same), same_schools = uniqueN(CNTSCHID[same]), share_same = wmean(as.numeric(same), W_FSTUWT), sd_school_low = sqrt(wmean((s_low - wmean(s_low, W_FSTUWT))^2, W_FSTUWT))), by = CNT]
info[, `:=`(flagged = CNT %in% FLAG, main_set = share_same >= .5)]
SYS <- info[same_schools >= 30 & same_students >= 1000, sort(CNT)]
log_step("systems with 30 or more schools holding both grades:", length(SYS), "; of which most students are in such schools:", info[CNT %in% SYS & main_set == TRUE, .N])
SPECS <- list(school = list(mods = "SCH_SES"), school_own = list(mods = c("ESCS_z", "SCH_SES")), school_own_level = list(mods = c("ESCS_z", "SCH_SES", "SCH_ACH")),
              share_low_own = list(mods = c("ESCS_z", "SCH_LOW")), school_all_schools = list(mods = "SCH_SES", all = TRUE))
res <- parallel::mclapply(SYS, function(cn) { s <- a[CNT == cn]
  rbindlist(lapply(names(SPECS), function(sp) { q <- SPECS[[sp]]; dd <- if (isTRUE(q$all)) s else s[same == TRUE]
    tryCatch(data.table(CNT = cn, spec = sp, pisa_est(dd, function(dt, y, w) grade_gain(dt, y, w, mods = q$mods), PV("ACH"))),
             error = function(e) { message("skipped ", cn, " ", sp, ": ", conditionMessage(e)); NULL }) })) }, mc.cores = 6)
g <- merge(rbindlist(res), info[, .(CNT, flagged, main_set, share_same, same_schools)], by = "CNT")
fwrite(g, paste0(OUT, "school_ses_sys.csv")); fwrite(info, paste0(OUT, "school_ses_samples.csv"))
k <- g[term != "n"]; by <- c("spec", "term")
pl <- rbind(k[, pool(est, se), by = by][, set := "all systems with 30+ such schools"], k[main_set == TRUE, pool(est, se), by = by][, set := "most students in such schools"],
            k[main_set == TRUE & flagged == FALSE, pool(est, se), by = by][, set := "most students in such schools, without Israel"])
fwrite(pl, paste0(OUT, "school_ses_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "08_school_ses", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220)
cat("\nsystems:", paste(SYS, collapse = " "), "\nmain set:", paste(info[CNT %in% SYS & main_set == TRUE, sort(CNT)], collapse = " "), "\n")
cat("students in the same-school sample:", info[CNT %in% SYS, sum(same_students)], "in", info[CNT %in% SYS, sum(same_schools)], "schools; SD of the school share of low-SES students, median system:", round(median(info[CNT %in% SYS, sd_school_low]), 2), "\n\n")
show <- c("tau", "gamma", "tau:SCH_SES", "gamma:SCH_SES", "main:SCH_SES", "age:SCH_SES", "tau:ESCS_z", "gamma:ESCS_z", "main:ESCS_z", "tau:SCH_ACH", "gamma:SCH_ACH", "main:SCH_ACH", "tau:SCH_LOW", "gamma:SCH_LOW", "main:SCH_LOW")
print(pl[term %in% show & set != "most students in such schools, without Israel", .(set, spec, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), sd_across = round(tau_sd, 2), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)][order(set, spec, match(term, show))], nrows = 120)
log_step("done"); sink()
