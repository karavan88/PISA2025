# IV learning -- step 13: socio-emotional skills (author's request, 2026-11-22). Cutoff systems.
#   (1) Skills as outcomes: what does a year add to each skill, and does that differ by family SES?
#       gamma / tau per skill (in SD of the skill within the system); the same interacted with ESCS; the SES gradient of the skill.
#   (2) Skills as moderators: does a year add more achievement for students with stronger skills? One skill at a time, with and without
#       the student's SES alongside; an index of the six learning skills; and the skills jointly. Reading a skill as a fixed trait of the
#       student is licensed only if (1) shows that a year of school does not move it (tau near zero).
#   (6, first cut) Skills and the gradient of question 3: the difference in the skill index between students near the 90th and the 10th
#       (75th and 25th) percentile of achievement, times the change in the yearly gain per SD of the index, is the part of the
#       gradient that goes with skills ("if students at the lower level had the skills of those at the higher level").
# Skills: z-scores of the PISA scales within the system (central analytic file). LEARN = mean of perseverance, self-regulated learning,
# goal setting, curiosity, enjoyment of problem-solving and cognitive adaptability (four or more present), standardised again.
# Self-reports on noisy scales: every association with a skill is weakened by that noise.
# Reads central products and step 9's summary. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/13_skills.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
STEP9 <- Sys.getenv("STEP9_DIR", file.path(PROJECT, "04_output/estimate_20261122_step9_quantile_iv"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, achm := rowMeans(.SD), .SDcols = PV("ACH")]
L6 <- paste0(c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL"), "_z"); SK <- c(L6, "BELONG_z")
a[, LEARN := { m <- as.matrix(.SD); ifelse(rowSums(!is.na(m)) >= 4, rowMeans(m, na.rm = TRUE), NA_real_) }, .SDcols = L6]
a[, LEARN := { m <- wmean(LEARN, W_FSTUWT); (LEARN - m) / sqrt(wmean((LEARN - m)^2, W_FSTUWT)) }, by = CNT]
has <- function(s, v) all(vapply(v, function(x) mean(!is.na(s[[x]])) >= .5, logical(1)))
SYS <- sort(unique(a$CNT)); flag <- function(d) { d[, flagged := CNT %in% FLAG]; d }
wq <- function(x, w, q) { o <- order(x); cw <- cumsum(w[o]) / sum(w); x[o][vapply(q, function(k) which(cw >= k)[1], 1L)] }
one <- function(cn) { s <- a[CNT == cn]; hasE <- has(s, "ESCS_z"); out <- list()
  # (1) skills as outcomes
  for (o in c(SK, "LEARN", "growth")) if (has(s, o)) {
    out[[length(out) + 1]] <- data.table(part = "outcome", var = o, spec = "base", pisa_est(s, function(dt, y, w) grade_gain(dt, y, w), o))
    if (hasE) out[[length(out) + 1]] <- data.table(part = "outcome", var = o, spec = "by_ses", pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = "ESCS_z"), o)) }
  # (2) skills as moderators of the achievement gain
  for (m in c(SK, "LEARN")) if (has(s, m)) {
    out[[length(out) + 1]] <- data.table(part = "moderator", var = m, spec = "alone", pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = m), PV("ACH")))
    if (hasE) out[[length(out) + 1]] <- data.table(part = "moderator", var = m, spec = "with_ses", pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = c(m, "ESCS_z")), PV("ACH"))) }
  J <- c("SELFREG_z", "GOALSET_z", "CURIO_z", "ENPROBS_z", "COGABIL_z", "BELONG_z")
  if (has(s, J)) out[[length(out) + 1]] <- data.table(part = "moderator", var = "joint", spec = "joint", pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = J), PV("ACH")))
  # (6) skill index near the achievement percentiles
  if (has(s, "LEARN")) out[[length(out) + 1]] <- data.table(part = "gradient", var = "LEARN", spec = "bands", pisa_est(s[!is.na(LEARN)], function(dt, y, w) {
    q <- wq(dt$achm, w, c(.05, .15, .20, .30, .70, .80, .85, .95)); band <- function(lo, hi) { k <- dt$achm >= lo & dt$achm < hi; wmean(y[k], w[k]) }
    c(d_90_10 = band(q[7], q[8]) - band(q[1], q[2]), d_75_25 = band(q[5], q[6]) - band(q[3], q[4])) }, "LEARN"))
  cbind(CNT = cn, rbindlist(out)) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(one(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
g <- flag(rbindlist(res)); fwrite(g, paste0(OUT, "skills_sys.csv"))
k <- g[term != "n" & is.finite(est) & is.finite(se) & se > 0]; by <- c("part", "var", "spec", "term")
pl <- rbind(k[, pool(est, se), by = by][, set := "all (Ukraine out)"], k[flagged == FALSE, pool(est, se), by = by][, set := "without Israel"])
fwrite(pl, paste0(OUT, "skills_pool.csv"))
# (6) the part of the gradient that goes with the skill index
P <- pl[set == "all (Ukraine out)"]; gL <- P[part == "moderator" & var == "LEARN" & spec == "alone" & term == "gamma:LEARN"]; q3 <- fread(file.path(STEP9, "quantile_iv_pool.csv"))[set == "all (Ukraine out)"]
acc <- rbindlist(lapply(c("90_10", "75_25"), function(b) { d <- P[part == "gradient" & term == paste0("d_", b)]; G <- q3[term == paste0("gamma_", b)]
  data.table(contrast = b, skill_gap_sd = d$re_mean, skill_gap_se = d$re_se, gain_per_sd = gL$re_mean, gain_per_sd_se = gL$re_se, explained = d$re_mean * gL$re_mean,
             explained_se = sqrt(d$re_mean^2 * gL$re_se^2 + gL$re_mean^2 * d$re_se^2), gradient = G$re_mean, gradient_se = G$re_se, share = d$re_mean * gL$re_mean / G$re_mean) }))
fwrite(acc, paste0(OUT, "skills_gradient_accounting.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "13_skills", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, grf_installed = requireNamespace("grf", quietly = TRUE), md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, file.path(STEP9, "quantile_iv_pool.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 220); sh <- function(x) x[, .(var, spec, term, n_sys, median = round(median, 3), re = round(re_mean, 3), se = round(re_se, 3), z = round(re_mean / re_se, 2), sd_across = round(tau_sd, 3), pos_05, pos_10, neg_05, neg_10)]
cat("\n(1) a year of school and each skill (SD of the skill)\n"); print(sh(P[part == "outcome" & spec == "base" & term %in% c("gamma", "tau")][order(term, var)]))
cat("\n(1) by family SES: SES gradient of the skill, and change in the yearly / same-age gain per SD of SES\n"); print(sh(P[part == "outcome" & spec == "by_ses" & term %in% c("main:ESCS_z", "gamma:ESCS_z", "tau:ESCS_z")][order(term, var)]))
cat("\n(2) achievement: change in the yearly / same-age gain per SD of the skill; level association\n")
print(sh(P[part == "moderator" & spec %in% c("alone", "with_ses") & (term == paste0("gamma:", var) | term == paste0("tau:", var) | term == paste0("main:", var))][order(spec, sub(":.*", "", term), var)]), nrows = 80)
cat("\n(2) skills jointly\n"); print(sh(P[part == "moderator" & spec == "joint" & term %like% "^gamma:"]))
cat("\n(6) skills and the gradient of question 3 (points)\n"); print(acc[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 2) else v)])
cat("grf installed:", requireNamespace("grf", quietly = TRUE), "\n"); log_step("done"); sink()
