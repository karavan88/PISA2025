# IV learning -- step 12, supplement to question 2: do schools with a high concentration of disadvantaged students add less per year than
# schools with a high concentration of advantaged students?
# School types, within each system, from the sampled students of the school (low and high = the system's bottom and top SES third):
#   disadvantaged  the school's share of low-third students is in the top quarter of the system's students
#   advantaged     the school's share of high-third students is in the top quarter (and the school is not also "disadvantaged")
#   mixed          every other school (reference)
# Model: the gain interacted with the two type indicators (instrumented by the instrument times the indicator), with and without the
# student's own SES and its interaction. Reported: the yearly gain in each type, disadvantaged minus advantaged, and the level gap.
# Sample: students in schools with 5 or more sampled students in each of the two grades (as in steps 8 and 10). After step 11 the
# comparison is read first in the systems whose two grades are in the same level of education, where a school's two birth groups are
# the same intake. School type is not assigned at random: these are differences between schools as they are.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/12_school_types.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a <- a[CNT %in% a[, .(e = mean(!is.na(ESCS))), by = CNT][e > 0, CNT]]
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
wq <- function(x, w, q) { o <- order(x); cw <- cumsum(w[o]) / sum(w); x[o][which(cw >= q)[1]] }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]
a[, `:=`(n_lo = sum(D == 0), n_hi = sum(D == 1), sh_low = wmean(as.numeric(ses3 == 1), W_FSTUWT), sh_high = wmean(as.numeric(ses3 == 3), W_FSTUWT)), by = .(CNT, CNTSCHID)]
a <- a[n_lo >= 5 & n_hi >= 5 & !is.na(ESCS_z)]
a[, dis := as.numeric(sh_low >= wq(sh_low, W_FSTUWT, .75)), by = CNT]
a[, adv := as.numeric(dis == 0 & sh_high >= wq(sh_high, W_FSTUWT, .75)), by = CNT]
info <- a[, .(students = .N, schools = uniqueN(CNTSCHID), schools_dis = uniqueN(CNTSCHID[dis == 1]), schools_adv = uniqueN(CNTSCHID[adv == 1]),
              low_share_dis = wmean(sh_low[dis == 1], W_FSTUWT[dis == 1]), low_share_adv = wmean(sh_low[adv == 1], W_FSTUWT[adv == 1]),
              high_share_dis = wmean(sh_high[dis == 1], W_FSTUWT[dis == 1]), high_share_adv = wmean(sh_high[adv == 1], W_FSTUWT[adv == 1])), by = CNT]
info <- merge(info, rules[, .(CNT, same_level = !top2_cross_levels)], by = "CNT"); info[, flagged := CNT %in% FLAG]
SYS <- info[schools >= 30 & schools_dis >= 8 & schools_adv >= 8, sort(CNT)]
log_step("school types on", length(SYS), "systems;", info[CNT %in% SYS, sum(schools)], "schools, of which disadvantaged", info[CNT %in% SYS, sum(schools_dis)], "and advantaged", info[CNT %in% SYS, sum(schools_adv)])
stat <- function(mods) function(dt, y, w) { g <- grade_gain(dt, y, w, mods = mods)
  c(gamma_mixed = unname(g["gamma"]), gamma_dis = unname(g["gamma"] + g["gamma:dis"]), gamma_adv = unname(g["gamma"] + g["gamma:adv"]), gamma_dis_minus_adv = unname(g["gamma:dis"] - g["gamma:adv"]),
    tau_dis_minus_adv = unname(g["tau:dis"] - g["tau:adv"]), level_dis_minus_adv = unname(g["main:dis"] - g["main:adv"]), fs = unname(g["fs"])) }
SPECS <- list(types = c("dis", "adv"), types_own_ses = c("dis", "adv", "ESCS_z"))
res <- parallel::mclapply(SYS, function(cn) { s <- a[CNT == cn]
  rbindlist(lapply(names(SPECS), function(sp) tryCatch(data.table(CNT = cn, spec = sp, pisa_est(s, stat(SPECS[[sp]]), PV("ACH"))),
    error = function(e) { message("skipped ", cn, " ", sp, ": ", conditionMessage(e)); NULL }))) }, mc.cores = 6)
g <- merge(rbindlist(res), info[, .(CNT, same_level, flagged)], by = "CNT")
fwrite(g, paste0(OUT, "school_types_sys.csv")); fwrite(info, paste0(OUT, "school_types_samples.csv"))
by <- c("spec", "term")
pl <- rbind(g[, pool(est, se), by = by][, set := "all"], g[same_level == TRUE, pool(est, se), by = by][, set := "two grades in the same level"],
            g[same_level == FALSE, pool(est, se), by = by][, set := "two grades in different levels"], g[same_level == TRUE & flagged == FALSE, pool(est, se), by = by][, set := "same level, without Israel"])
fwrite(pl, paste0(OUT, "school_types_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "12_school_types", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220)
cat("\nwho is in the two types (means across systems): share of low-third students", round(mean(info[CNT %in% SYS, low_share_dis]), 2), "in disadvantaged schools and", round(mean(info[CNT %in% SYS, low_share_adv]), 2),
    "in advantaged ones; share of high-third students", round(mean(info[CNT %in% SYS, high_share_dis]), 2), "and", round(mean(info[CNT %in% SYS, high_share_adv]), 2), "\n")
cat("same-level systems:", paste(info[CNT %in% SYS & same_level == TRUE, sort(CNT)], collapse = " "), "\n\n")
ord <- c("gamma_dis", "gamma_mixed", "gamma_adv", "gamma_dis_minus_adv", "tau_dis_minus_adv", "level_dis_minus_adv", "fs")
print(pl[set != "same level, without Israel"][order(set, spec, match(term, ord)), .(set, spec, term, n_sys, median = round(median, 1), re = round(re_mean, 1), se = round(re_se, 1), sd_across = round(tau_sd, 1), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)], nrows = 60)
log_step("done"); sink()
