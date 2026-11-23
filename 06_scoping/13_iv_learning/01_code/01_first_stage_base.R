# IV learning -- step 1: is the design usable for the two questions?
#   (a) first stage per system, overall and by third of socio-economic status (ESCS), and high minus low
#   (b) repetition at the cutoff (coefficient of born-before-the-cutoff in a regression of ever-repeated on it and birth month)
#   (c) base grade gain per system. Headline tau (birth month fixed); gamma (starting age fixed) beside it.
#       Specifications: base (no covariates: the instrument needs none and several systems withhold sex or immigrant background);
#       controls (female, immigrant where present); no_repeaters; years (treatment = years in school: grade + 1 for repeaters).
# Reads central products only. Writes to a new directory:
#   PAPER_OUT=06_scoping/13_iv_learning/04_output/<new dir> Rscript 06_scoping/13_iv_learning/01_code/01_first_stage_base.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))   # sample = central eligibility verdict
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, yrs := (grade - g_lo) + repeated]                       # years in school relative to the lower grade; missing where repetition is
third <- function(x, w) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); out <- rep(NA_integer_, length(x)); out[which(ok)[o]] <- 1L + (cw > 1/3) + (cw > 2/3); out }
a[, ses3 := third(ESCS, W_FSTUWT), by = CNT]
info <- a[, .(n = .N, share_repeated = wmean(repeated, W_FSTUWT), escs = mean(!is.na(ESCS))), by = CNT]
info[, `:=`(flagged = CNT %in% FLAG, low_repetition = share_repeated < .05)]
OUTCOMES <- c("ACH", "MATH", "READ", "SCIE")
log_step("step 1 on", uniqueN(a$CNT), "systems,", nrow(a), "students; excluded:", paste(EXCLUDE, collapse = " "), "; flagged:", paste(FLAG, collapse = " "))

zcoef <- function(y, d, w) { ok <- is.finite(y) & is.finite(w); unname(lm.wfit(cbind(1, Z = d$Z[ok], r = d$r[ok]), y[ok], w[ok])$coefficients["Z"]) }
one_system <- function(cn) {
  s <- a[CNT == cn]
  # (a), (b): no plausible values involved, replicate weights only
  fs <- pisa_est(s, function(dt, y, w) {
    o <- c(fs = zcoef(dt$D, dt, w), rep_jump = if (any(!is.na(dt$repeated))) zcoef(dt$repeated, dt, w) else NA_real_)
    if (any(!is.na(dt$ses3))) { t3 <- sapply(1:3, function(k) { i <- which(dt$ses3 == k); zcoef(dt$D[i], dt[i], w[i]) })
      o <- c(o, fs_low = t3[1], fs_mid = t3[2], fs_high = t3[3], fs_high_minus_low = t3[3] - t3[1]) }
    o }, "D")
  # (c)
  ctrl <- c("female", "immigrant"); ctrl <- ctrl[vapply(ctrl, function(v) mean(!is.na(s[[v]])) > .5, logical(1))]
  specs <- list(base = list(d = s), controls = list(d = s, ctrl = ctrl), no_repeaters = list(d = s[repeated == 0]), years = list(d = s[!is.na(yrs)], treat = "yrs"))
  gg <- rbindlist(lapply(names(specs), function(sp) rbindlist(lapply(OUTCOMES, function(o) {
    q <- specs[[sp]]
    e <- pisa_est(q$d, function(dt, y, w) grade_gain(dt, y, w, treat = if (is.null(q$treat)) "D" else q$treat, ctrl = if (is.null(q$ctrl)) character(0) else q$ctrl), PV(o))
    data.table(CNT = cn, spec = sp, outcome = o, e, controls = if (sp == "controls") paste(ctrl, collapse = "+") else "")
  }))))
  list(fs = data.table(CNT = cn, fs), gg = gg)
}
res <- parallel::mclapply(sort(unique(a$CNT)), function(cn) tryCatch(one_system(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- sort(unique(a$CNT))[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
fs <- merge(rbindlist(lapply(res, `[[`, "fs")), info, by = "CNT"); gg <- merge(rbindlist(lapply(res, `[[`, "gg")), info[, .(CNT, flagged, low_repetition)], by = "CNT")
strong <- fs[term == "fs" & est >= .5, CNT]; gg[, strong_first_stage := CNT %in% strong]
fwrite(fs, paste0(OUT, "first_stage_sys.csv")); fwrite(gg, paste0(OUT, "grade_gain_sys.csv"))

sets <- function(d, by) rbind(d[, pool(est, se), by = by][, set := "all (Ukraine out)"], d[flagged == FALSE, pool(est, se), by = by][, set := "without Israel"],
                              d[low_repetition == TRUE, pool(est, se), by = by][, set := "repetition under 5%"])
fsp <- sets(fs[is.finite(est)], "term")
ggp <- rbind(sets(gg[term != "n"], c("spec", "outcome", "term")), gg[term != "n" & strong_first_stage == TRUE, pool(est, se), by = .(spec, outcome, term)][, set := "first stage 0.5 or more"])
fwrite(fsp, paste0(OUT, "first_stage_pool.csv")); fwrite(ggp, paste0(OUT, "grade_gain_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "01_first_stage_base", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = sort(unique(a$CNT)), students = nrow(a), excluded = EXCLUDE, flagged = FLAG,
  md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200)
print(fsp[, .(set, term, n_sys, median = round(median, 3), re = round(re_mean, 3), se = round(re_se, 3), pos_05, pos_10, neg_05, neg_10)][order(set, term)])
print(ggp[term %in% c("tau", "gamma", "fs") & outcome == "ACH", .(set, spec, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), sd = round(tau_sd, 2), I2 = round(I2), pos_05, pos_10, neg_05, neg_10)][order(set, spec, term)], nrows = 100)
log_step("done"); sink()
