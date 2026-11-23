# IV learning -- step 4, question 1: does the gain from one more grade differ by socio-economic status? Cutoff systems only.
# Model per system: score on grade, grade x SES, birth month, birth month x SES and SES; grade and grade x SES instrumented by
# born-before-the-cutoff and its product with SES. SES = ESCS standardised within system (central analytic file).
#   tau:ESCS_z    change in the same-age gain per SD of SES (positive: a grade widens the SES gap; negative: it narrows it)
#   gamma:ESCS_z  the same for the yearly gain; age:ESCS_z = their difference, the change in the yearly age slope per SD of SES
#   main:ESCS_z   SES gradient in the lower grade at the cutoff, the yardstick for the size of the interaction
# Specifications: base; school_fe (within schools); no_repeaters; years (treatment = years in school); thirds (low third as reference:
# tau = gain in the low third, tau:high = high minus low).
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/04_ses_gain.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, yrs := (grade - g_lo) + repeated]
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]; a[, `:=`(mid = as.numeric(ses3 == 2), high = as.numeric(ses3 == 3))]
info <- a[, .(n = .N, escs = mean(!is.na(ESCS)), share_repeated = wmean(repeated, W_FSTUWT)), by = CNT]
info[, `:=`(flagged = CNT %in% FLAG, low_repetition = share_repeated < .05)]
SYS <- info[escs > 0, sort(CNT)]
log_step("question 1 on", length(SYS), "systems with ESCS; without:", paste(info[escs == 0, CNT], collapse = " "), "; ESCS under 75%:", paste(info[escs > 0 & escs < .75, CNT], collapse = " "))
OUTCOMES <- c("ACH", "MATH", "READ", "SCIE")
SPECS <- list(base = list(mods = "ESCS_z"), school_fe = list(mods = "ESCS_z", fe = "CNTSCHID"), no_repeaters = list(mods = "ESCS_z", rows = quote(repeated == 0)),
              years = list(mods = "ESCS_z", treat = "yrs", rows = quote(!is.na(yrs))), thirds = list(mods = c("mid", "high")))
one_system <- function(cn) {
  s <- a[CNT == cn]
  rbindlist(lapply(names(SPECS), function(sp) { q <- SPECS[[sp]]; dd <- if (is.null(q$rows)) s else s[eval(q$rows)]
    # A specification that cannot be estimated in a system is skipped and logged, never the whole system: school fixed effects have
    # nothing to work with where the two grades are taught in different schools.
    rbindlist(lapply(OUTCOMES, function(o) tryCatch(data.table(CNT = cn, spec = sp, outcome = o,
      pisa_est(dd, function(dt, y, w) grade_gain(dt, y, w, treat = if (is.null(q$treat)) "D" else q$treat, mods = q$mods, fe = q$fe), PV(o))),
      error = function(e) { message("skipped ", cn, " ", sp, " ", o, ": ", conditionMessage(e)); NULL }))) }))
}
res <- parallel::mclapply(SYS, function(cn) tryCatch(one_system(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
g <- merge(rbindlist(res), info[, .(CNT, escs, flagged, low_repetition)], by = "CNT")
done <- unique(g[, .(CNT, spec)])[, .N, by = spec]; log_step("systems per specification:", paste(done$spec, done$N, collapse = "; "))
miss <- CJ(CNT = SYS, spec = names(SPECS))[!unique(g[, .(CNT, spec)]), on = c("CNT", "spec")]; if (nrow(miss)) log_step("not estimable:", paste(miss$CNT, miss$spec, collapse = "; "))
stopifnot(all(SYS %in% g[spec == "base", CNT]))
fs1 <- g[spec == "base" & outcome == "ACH" & term == "fs", .(CNT, strong = est >= .5)]; g <- merge(g, fs1, by = "CNT")
fwrite(g, paste0(OUT, "ses_gain_sys.csv"))
by <- c("spec", "outcome", "term"); k <- g[term != "n"]
pl <- rbind(k[, pool(est, se), by = by][, set := "all with ESCS (Ukraine out)"], k[flagged == FALSE, pool(est, se), by = by][, set := "without Israel"],
            k[escs >= .75, pool(est, se), by = by][, set := "ESCS for 75% or more (United States out)"], k[strong == TRUE, pool(est, se), by = by][, set := "first stage 0.5 or more"],
            k[low_repetition == TRUE, pool(est, se), by = by][, set := "repetition under 5%"])
fwrite(pl, paste0(OUT, "ses_gain_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "04_ses_gain", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220)
show <- function(x) x[, .(set, spec, outcome, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), sd_across = round(tau_sd, 2), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)]
cat("\ncombined achievement, all systems with ESCS\n")
print(show(pl[set == "all with ESCS (Ukraine out)" & outcome == "ACH" & term %in% c("tau", "gamma", "tau:ESCS_z", "gamma:ESCS_z", "age:ESCS_z", "main:ESCS_z", "tau:high", "gamma:high", "tau:mid", "main:high", "age:high")][order(spec, term)]), nrows = 80)
cat("\nthe SES interaction of the same-age gain (tau:ESCS_z), base specification, by domain and set\n")
print(show(pl[spec == "base" & term == "tau:ESCS_z"][order(outcome, set)]), nrows = 40)
cat("\nthe SES interaction of the yearly gain (gamma:ESCS_z), base specification, by set, combined achievement\n")
print(show(pl[spec == "base" & term == "gamma:ESCS_z" & outcome == "ACH"][order(set)]))
log_step("done"); sink()
