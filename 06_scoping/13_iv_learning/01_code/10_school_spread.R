# IV learning -- step 10, question 2: how much do schools of the same system differ in what a year adds?
# Sample: schools with 5 or more sampled students in each of the two grades (so the school does not depend on the assigned grade) and at
# least 3 students on each side of the cutoff; systems with 30 or more such schools.
# Per system, within schools: first stage pi (grade on born-before-the-cutoff and birth month, school fixed effects), the age slope b and
# the common jump theta (score on the instrument and birth month, school fixed effects), all common to the system's schools.
# Per school j and plausible value: the gain  g_j = [mean(score - b r | born before) - mean(score - b r | born after)] / pi,  with its
# sampling variance from the two within-school variances. Q is the precision-weighted sum of squared deviations of the school gains
# from their mean, averaged over the ten plausible values.
# Reference distribution by permutation, not chi-square: with 3 to 15 students per side the variances are themselves noisy and Q is
# inflated even without any spread. The common jump is removed from the scores, birth side is shuffled among the students of each
# school (the same shuffle for all plausible values), and Q is recomputed, NPERM times. Then
#     between-school variance = (Q observed - mean Q permuted) / C;     p = share of permutations with Q at or above the observed one;
#     the 5th and 95th percentile of permuted Q give a 90% interval for the variance.
# Two earlier attempts are kept beside the output: Rubin's total variance on gains averaged over plausible values understates the
# spread (superseded_20261122_step10_rubin_variance); a chi-square reference per plausible value overstates it
# (superseded_20261122_step10_chisq_reference).
# What a spread means: schools differ in the score difference between their students born before and after the cutoff. That is a
# difference in gains only if a school's two birth groups are alike apart from grade. Where the upper grade is a new intake (a school
# with its own admission to upper secondary), the spread also carries differences between intakes. It is therefore shown separately
# for systems whose two grades lie in the same level of education.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/10_school_spread.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
NPERM <- as.integer(Sys.getenv("NPERM", "200"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, `:=`(n_lo = sum(D == 0), n_hi = sum(D == 1), n_z1 = sum(Z == 1), n_z0 = sum(Z == 0)), by = .(CNT, CNTSCHID)]
info <- a[, .(share_same = wmean(as.numeric(n_lo >= 5 & n_hi >= 5), W_FSTUWT)), by = CNT]
a <- a[n_lo >= 5 & n_hi >= 5 & n_z1 >= 3 & n_z0 >= 3]
SYS <- a[, .(J = uniqueN(CNTSCHID)), by = CNT][J >= 30, sort(CNT)]
log_step("question 2 on", length(SYS), "systems,", a[CNT %in% SYS, uniqueN(paste(CNT, CNTSCHID))], "schools,", a[CNT %in% SYS, .N], "students;", NPERM, "permutations")
one <- function(cn) { set.seed(20261122 + match(cn, SYS)); s <- a[CNT == cn]; w <- s$W_FSTUWT; g <- s$CNTSCHID
  pi <- unname(lm.wfit(demean(cbind(Z = s$Z, r = s$r), g, w), drop(demean(s$D, g, w)), w)$coefficients["Z"])
  o <- school_spread(s, s$Z, pi, PV("ACH"), NPERM)                    # 00_helpers.R
  list(sys = cbind(CNT = cn, first_stage = pi, o$sys), perm = o$perm) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(one(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
names(res) <- SYS
sy <- merge(rbindlist(lapply(res, `[[`, "sys")), info, by = "CNT")
sy <- merge(sy, rules[, .(CNT, name, same_level = !top2_cross_levels)], by = "CNT")
sy[, `:=`(main_set = share_same >= .5, flagged = CNT %in% FLAG)]
fwrite(sy, paste0(OUT, "school_spread_sys.csv"))
perms <- lapply(res, `[[`, "perm"); allsc <- function(d, lab) spread_overall(d, perms, lab, NPERM)
ov <- rbind(allsc(sy, "all systems with 30+ such schools"), allsc(sy[main_set == TRUE], "most students in such schools"), allsc(sy[first_stage >= .5], "first stage within schools 0.5 or more"),
            allsc(sy[same_level == TRUE], "two grades in the same level of education"), allsc(sy[same_level == FALSE], "two grades in different levels"),
            allsc(sy[same_level == TRUE & first_stage >= .5], "same level and first stage 0.5 or more"))
fwrite(ov, paste0(OUT, "school_spread_overall.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "10_school_spread", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, permutations = NPERM, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220)
cat("\nper system: between-school standard deviation of the gain, points (permutation reference)\n")
print(sy[order(-sd), .(CNT, schools, first_stage = round(first_stage, 2), mean_gain = round(mean_gain, 1), Q_df = round(Q / df, 2), perm_Q_df = round(Q_perm_mean / df, 2), sd = round(sd, 1), sd_lo = round(sd_lo, 1), sd_hi = round(sd_hi, 1),
  p_perm = round(p_perm, 3), p_chisq = round(p_chisq, 3), detectable = round(detectable_sd, 1), school_se = round(median_school_se, 1), same_level, main_set)], nrows = 40)
cat("\nsystems with a spread at p < 0.05:", sy[p_perm < .05, .N], "; at p < 0.10 only:", sy[p_perm >= .05 & p_perm < .10, .N], "of", nrow(sy), "; median detectable sd", round(median(sy$detectable_sd), 1), "\n\nall schools together\n")
print(ov[, .(set, systems, schools, Q_df = round(Q / df, 2), perm_Q_df = round(Q_perm_mean / df, 2), p_perm = round(p_perm, 3), sd = round(sd, 1), sd_lo = round(sd_lo, 1), sd_hi = round(sd_hi, 1), detectable = round(detectable_sd, 1))])
log_step("done"); sink()
