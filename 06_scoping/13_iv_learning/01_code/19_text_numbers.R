# IV learning -- every number quoted in the text of the manuscript. Reporting only: reads saved estimates and fits nothing; the two
# pooled summaries it forms (the linear school-SES version by level of education) re-average saved system estimates.
# Writes 04_output/tables/numbers.yml, which the manuscript loads (metadata-files) and quotes as {{< meta n.key >}}, and
# 04_output/tables/text_claims.csv. A "claim" is a statement the text makes in words (which system is the exception, whether a
# difference is significant, "about a sixth"): it is checked here, and the script stops with the list of claims that no longer hold,
# so that the sentence is rewritten and not left behind by a new run.
# Rscript 06_scoping/13_iv_learning/01_code/19_text_numbers.R        (TAB_OUT, PAPER_RUN and STEPn_DIR override the defaults)
source("06_scoping/13_iv_learning/01_code/00_helpers.R"); source(file.path(PROJECT, "01_code/sample_rules.R")); source(file.path(PROJECT, "01_code/run_of_record.R"))
OUT <- Sys.getenv("TAB_OUT", file.path(PROJECT, "04_output/tables")); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
rd <- function(n, f) { d <- fread(file.path(step_dir(n), f)); if ("CNT" %in% names(d)) stopifnot(!any(d$CNT %in% EXCLUDE)); d }
one <- function(d) { stopifnot(nrow(d) == 1); d }

# ---- formats: a true minus sign, no minus on a rounded zero, thousands separated by commas ----
f <- function(x, d = 1) { s <- formatC(x, format = "f", digits = d); s <- sub("^-(0\\.?0*)$", "\\1", s); sub("^-", "\u2212", s) }
big <- function(x) formatC(x, format = "d", big.mark = ",")
pct <- function(x, d = 0) f(100 * x, d)
pv <- function(p) if (p < .1) f(p, 3) else f(p, 2)
WORDS <- c("no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve")
N <- list(); CL <- list()
put <- function(key, val) { stopifnot(length(val) == 1, !is.na(val), is.null(N[[key]])); N[[key]] <<- val }
cnt <- function(key, x) { put(key, big(x)); put(paste0(key, "_w"), if (x <= 12) WORDS[x + 1] else big(x)) }                  # a count, as a numeral and as a word
pe <- function(key, d, digits = 1, scale = 1) { d <- one(d); put(key, f(scale * d$re_mean, digits)); put(paste0(key, "_se"), f(scale * d$re_se, digits)) }   # a pooled estimate and its SE
claim <- function(text, ok) CL[[length(CL) + 1]] <<- data.table(claim = text, holds = isTRUE(ok))
z05 <- qnorm(.975); z10 <- qnorm(.95)
sig5 <- function(d) abs(d$re_mean / d$re_se) > z05; sig10only <- function(d) { z <- abs(d$re_mean / d$re_se); z > z10 & z <= z05 }; ns <- function(d) abs(d$re_mean / d$re_se) <= z10
A <- "all (Ukraine out)"; AE <- "all with ESCS (Ukraine out)"; STRONG <- "first stage 0.5 or more"          # set labels written by the estimation steps

# ---- data: entry rules and samples ----
rules <- fread(RULES); an <- rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE]; sc <- rd("6b", "scale_sys.csv"); sm <- one(rd("6b", "scale_summary.csv"))
stopifnot(setequal(an$CNT, sc$CNT)); NS <- nrow(an)
nm <- function(cnt) rules[match(cnt, CNT), sub(" \\(China\\)$", "", name)]
cnt("sys_file", nrow(rules)); cnt("sys_screened", rules[!is.na(pisa_eligible), .N]); cnt("sys_rule", rules[pisa_eligible == TRUE, .N]); cnt("sys", NS)
cnt("entry5", an[entry_age == 5, .N]); cnt("entry6", an[entry_age == 6, .N]); cnt("entry7", an[entry_age == 7, .N]); claim("entry age is 5, 6 or 7 in every system", an[, all(entry_age %in% 5:7)])
cnt("partial_month", an[pisa_partial_month == TRUE, .N]); cnt("cut_months", an[, uniqueN(substr(pisa_cut, 6, 7))])
put("students", big(sm$students)); put("schools", big(sm$schools)); cnt("oecd", sm$oecd_systems); put("two_grades_pct", pct(sm$share_two_grades)); put("sd_ach", f(sm$sd_ach, 0))
cnt("sys_ses", sm$systems_with_ses); claim("the only system without the socio-economic index is Costa Rica", identical(sc[escs == 0, CNT], "CRI"))
put("usa_ses_pct", pct(sc[CNT == "USA", escs])); claim("the index covers under 75% of students only in the United States, apart from Costa Rica", identical(sc[escs > 0 & escs < .75, CNT], "USA"))
put("rank_low", f(sm$rank_low, 0)); put("rank_high", f(sm$rank_high, 0)); put("rank_diff", f(sm$rank_high - sm$rank_low, 0))
cnt("low_rep_sys", sm$low_repetition_systems)

# ---- first stage, repetition, the yearly gain and its checks (step 1) ----
f1 <- rd(1, "first_stage_sys.csv"); p1 <- rd(1, "first_stage_pool.csv"); gg <- rd(1, "grade_gain_pool.csv")
fs <- f1[term == "fs"]; stopifnot(nrow(fs) == NS)
pe("fs", p1[set == A & term == "fs"], 2); put("fs_min", f(min(fs$est), 2)); put("fs_max", f(max(fs$est), 2)); cnt("fs_strong", fs[est >= .5, .N])
pe("rep_jump", p1[set == A & term == "rep_jump"], 1, scale = 100)
pe("fs_low", p1[set == A & term == "fs_low"], 2); pe("fs_high", p1[set == A & term == "fs_high"], 2)
d <- one(p1[set == A & term == "fs_high_minus_low"]); cnt("fs_diff_05", d$pos_05 + d$neg_05); cnt("fs_diff_05_high", d$pos_05)
G <- function(sp, oc, tm, st = A) one(gg[spec == sp & outcome == oc & term == tm & set == st])
pe("gain_all", G("base", "ACH", "gamma")); pe("gain_controls", G("controls", "ACH", "gamma")); pe("gain_norep", G("no_repeaters", "ACH", "gamma")); pe("gain_years", G("years", "ACH", "gamma"))
pe("gain_strong", G("base", "ACH", "gamma", STRONG)); claim("the strong-first-stage set has as many systems as have a first stage of 0.5 or more", G("base", "ACH", "gamma", STRONG)$n_sys == fs[est >= .5, .N])
pe("gain_lowrep", G("base", "ACH", "gamma", "repetition under 5%")); claim("the low-repetition set is the systems with under 5% repeaters", G("base", "ACH", "gamma", "repetition under 5%")$n_sys == sm$low_repetition_systems)
for (o in c("MATH", "READ", "SCIE")) pe(paste0("gain_", tolower(o)), G("base", o, "gamma"))
pe("tau_all", G("base", "ACH", "tau")); pe("tau_norep", G("no_repeaters", "ACH", "tau")); pe("tau_years", G("years", "ACH", "tau")); pe("tau_strong", G("base", "ACH", "tau", STRONG))

# ---- question 1: the gap in years of learning (step 6) ----
gp <- rd(6, "gap_years_pool.csv"); gs <- rd(6, "gap_years_summary.csv"); gy <- rd(6, "gap_years_sys.csv")[!is.na(gap3)]
stopifnot(nrow(gy) == sm$systems_with_ses)
pe("gap3", gp[term == "gap3"]); pe("gapsd", gp[term == "gapSD"]); cnt("gap_sig05", gp[term == "gap3", pos_05])
claim("the gap is significant at 5% in every system but Kenya, and not at 10% there", identical(gy[abs(gap3 / se_gap3) <= z05, CNT], "KEN") && gy[CNT == "KEN", abs(gap3 / se_gap3) <= z10])
pe("gain", gp[term == "gamma"]); put("gain0", f(gp[term == "gamma", re_mean], 0)); cnt("gain_pos05", gp[term == "gamma", pos_05]); cnt("gain_pos10", gp[term == "gamma", pos_10])
put("gain_sd", f(gp[term == "gamma", re_mean] / sm$sd_ach, 2)); claim("the yearly gain is one-fifth of a standard deviation (0.18 to 0.22)", abs(gp[term == "gamma", re_mean] / sm$sd_ach - .2) < .02)
pe("tau", gp[term == "tau"]); pe("age", gp[term == "age"]); put("tau_share_pct", pct(gp[term == "tau", re_mean] / gp[term == "gamma", re_mean]))
g3 <- one(gs[gap == "gap3"]); gS <- one(gs[gap == "gapSD"])
put("years", f(g3$years)); put("years_se", f(g3$se_jackknife)); put("years_jk_min", f(g3$jackknife_min)); put("years_jk_max", f(g3$jackknife_max)); put("yearssd", f(gS$years)); put("yearssd_se", f(gS$se_jackknife))
o <- gy[order(-years3)]
claim("the largest gaps are Romania and Germany, about six years (5.5 to 6.5)", setequal(o$CNT[1:2], c("ROU", "DEU")) && all(abs(o$years3[1:2] - 6) < .5))
claim("the smallest gaps are Cambodia and Kenya, under one year, and no other system is under one year", setequal(o[years3 < 1, CNT], c("KHM", "KEN")))

# ---- question 2: the gain by family background (steps 4, 1, 5) ----
p4 <- rd(4, "ses_gain_pool.csv")[set == AE]; s4 <- rd(4, "ses_gain_sys.csv")
P4 <- function(sp, oc, tm) one(p4[spec == sp & outcome == oc & term == tm])
pe("ses_tau", P4("base", "ACH", "tau:ESCS_z")); pe("ses_gain", P4("base", "ACH", "gamma:ESCS_z")); pe("ses_level", P4("base", "ACH", "main:ESCS_z"))
d <- P4("base", "ACH", "gamma:ESCS_z"); lev <- P4("base", "ACH", "main:ESCS_z")$re_mean
cnt("ses_pos05", d$pos_05); cnt("ses_pos10", d$pos_10); cnt("ses_neg05", d$neg_05); cnt("ses_neg10", d$neg_10)
claim("the SES interaction is significantly positive in no system at 5% and one at 10%, negative in none at 5% and one at 10%", d$pos_05 == 0 && d$pos_10 == 1 && d$neg_05 == 0 && d$neg_10 == 1)
claim("the SES interaction varies across systems no more than sampling error predicts (I2 = 0)", d$I2 == 0)
ci <- function(key, d) { lo <- d$re_mean - z05 * d$re_se; hi <- d$re_mean + z05 * d$re_se; put(paste0(key, "_lo"), f(lo)); put(paste0(key, "_hi"), f(hi)); put(paste0(key, "_lo_pct"), pct(lo / lev)); put(paste0(key, "_hi_pct"), pct(hi / lev)); invisible(c(lo, hi) / lev) }
b1 <- ci("ses_gain", d); b2 <- ci("ses_tau", P4("base", "ACH", "tau:ESCS_z"))
claim("one more year changes the gap by at most about a tenth of its size (largest bound between 7% and 14%)", max(abs(c(b1, b2))) > .07 && max(abs(c(b1, b2))) < .14)
pe("thirds_gain", P4("thirds", "ACH", "gamma:high")); th <- s4[spec == "thirds" & outcome == "ACH" & term == "gamma:high"]
cnt("thirds_sig05", th[abs(est / se) > z05, .N]); cnt("thirds_sig10only", th[abs(est / se) > z10 & abs(est / se) <= z05, .N])
claim("in the thirds comparison no system differs at 5% and four differ at 10%", th[abs(est / se) > z05, .N] == 0 && th[abs(est / se) > z10, .N] == 4)
pe("ses_gain_fe", P4("school_fe", "ACH", "gamma:ESCS_z")); for (o in c("MATH", "READ", "SCIE")) pe(paste0("ses_gain_", tolower(o)), P4("base", o, "gamma:ESCS_z"))
pe("ses_age", P4("base", "ACH", "age:ESCS_z")); pe("ses_gain_norep", P4("no_repeaters", "ACH", "gamma:ESCS_z")); pe("ses_gain_years", P4("years", "ACH", "gamma:ESCS_z"))
claim("the SES interaction is not significant at 10% within schools, in any domain, without repeaters or with years in school",
      all(sapply(list(P4("school_fe", "ACH", "gamma:ESCS_z"), P4("base", "MATH", "gamma:ESCS_z"), P4("base", "READ", "gamma:ESCS_z"), P4("base", "SCIE", "gamma:ESCS_z"), P4("no_repeaters", "ACH", "gamma:ESCS_z"), P4("years", "ACH", "gamma:ESCS_z"), P4("base", "ACH", "age:ESCS_z")), ns)))

# ---- question 3: schools (steps 10, 11, 12, 8) ----
so <- rd(10, "school_spread_overall.csv"); sp <- rd(10, "school_spread_sys.csv"); pc <- rd(11, "placebo_overall.csv")
SAME <- "two grades in the same level of education"; DIFF <- "two grades in different levels"
lg <- readLines(file.path(step_dir(10), "log.txt"), n = 1); m <- regmatches(lg, regexec("on ([0-9]+) systems, ([0-9]+) schools, ([0-9]+) students", lg))[[1]]; stopifnot(length(m) == 4)
al <- one(so[set == "all systems with 30+ such schools"]); stopifnot(as.integer(m[2]) == al$systems, as.integer(m[3]) == al$schools, nrow(sp) == al$systems)
cnt("sch_sys", al$systems); put("sch_n", big(al$schools)); put("sch_students", big(as.integer(m[4]))); cnt("sch_same", sp[same_level == TRUE, .N]); cnt("sch_diff", sp[same_level == FALSE, .N])
spread <- function(key, st) { d <- one(so[set == st]); put(key, f(d$sd)); put(paste0(key, "_lo"), f(d$sd_lo)); put(paste0(key, "_hi"), f(d$sd_hi)); put(paste0(key, "_p"), pv(d$p_perm)); cnt(paste0(key, "_sys"), d$systems); invisible(d) }
d <- spread("spread_all", "all systems with 30+ such schools"); claim("no shuffle of birth side gives as much dispersion as observed (all systems)", abs(d$p_perm - 1 / 201) < 1e-9)
dS <- spread("spread_same", SAME); spread("spread_same_strong", "same level and first stage 0.5 or more")
claim("the spread is significant at 5% in the same-level systems and in those with a strong first stage", dS$p_perm < .05 && so[set == "same level and first stage 0.5 or more", p_perm] < .05)
claim("among same-level systems only Serbia and Brunei show a spread significant at 10% on their own", setequal(sp[same_level == TRUE & p_perm < .10, CNT], c("SRB", "BRN")) && all(sp[CNT %in% c("SRB", "BRN"), p_perm] < .05))
put("spread_detect", f(median(sp$detectable_sd), 0))
bal <- function(key, st) { d <- one(pc[check == "balance on SES" & set == st]); put(key, f(d$sd, 2)); put(paste0(key, "_p"), pv(d$p_perm)); invisible(d) }
dd <- bal("balance_diff", DIFF); ds <- bal("balance_same", SAME); claim("intake differs across schools where the grades are in different levels (5%) and not where they share a level (10%)", dd$p_perm < .05 && ds$p_perm >= .10)
fa <- one(pc[check == "false cutoff, born before" & set == "all"]); fsm <- one(pc[check == "false cutoff, born before" & set == SAME])
cnt("false_sys", fa$systems); put("false_hi", f(fa$sd_hi)); claim("the false cutoff shows no spread across all systems", fa$sd == 0 && fa$p_perm > .10)
cnt("false_same_sys", fsm$systems); put("false_same", f(fsm$sd)); put("false_same_hi", f(fsm$sd_hi)); put("false_same_real", f(fsm$sd_at_real_gap)); claim("the false cutoff in same-level systems is not significant", fsm$p_perm > .10)
left <- sqrt(dS$sd^2 - fsm$sd_at_real_gap^2); put("spread_left", f(left, 0)); put("spread_top", f(dS$sd, 0))
claim("a spread of 12 to 15 points is close to the mean yearly gain (within 6 points of it)", abs(left - gp[term == "gamma", re_mean]) < 6 && abs(dS$sd - gp[term == "gamma", re_mean]) < 6)
ty <- rd(12, "school_types_pool.csv")[spec == "types"]; tsys <- rd(12, "school_types_sys.csv"); tinfo <- rd(12, "school_types_samples.csv")[CNT %in% unique(tsys$CNT)]
TS <- "two grades in the same level"; TY <- function(tm, st = TS) one(ty[term == tm & set == st])
for (v in c("low_share_dis", "high_share_dis", "low_share_adv", "high_share_adv")) put(paste0(v, "_pct"), pct(mean(tinfo[[v]])))
cnt("types_sys", TY("gamma_dis", "all")$n_sys); cnt("types_same", TY("gamma_dis")$n_sys); cnt("types_diff", TY("gamma_dis", DIFF)$n_sys)
put("types_level", f(abs(TY("level_dis_minus_adv")$re_mean), 0)); claim("the level difference between school types is more than five school years (5 to 6)", abs(TY("level_dis_minus_adv")$re_mean) / gp[term == "gamma", re_mean] > 5 && abs(TY("level_dis_minus_adv")$re_mean) / gp[term == "gamma", re_mean] < 6)
pe("types_dis", TY("gamma_dis")); pe("types_mixed", TY("gamma_mixed")); pe("types_adv", TY("gamma_adv")); pe("types_diff_same", TY("gamma_dis_minus_adv"))
d <- TY("gamma_dis_minus_adv"); put("types_diff_same_lo", f(d$re_mean - z05 * d$re_se)); put("types_diff_same_hi", f(d$re_mean + z05 * d$re_se)); claim("the difference between school types in same-level systems is negative and not significant at 10%", d$re_mean < 0 && ns(d))
pe("types_diff_all", TY("gamma_dis_minus_adv", "all")); pe("types_diff_other", TY("gamma_dis_minus_adv", DIFF)); claim("the difference between school types has the opposite sign where the grades are in different levels", TY("gamma_dis_minus_adv", DIFF)$re_mean > 0)
s8 <- merge(rd(8, "school_ses_sys.csv")[spec == "school_own" & term == "gamma:SCH_SES" & CNT %in% unique(tsys$CNT)], rules[, .(CNT, same_level = !top2_cross_levels)], by = "CNT")
lin <- s8[same_level == TRUE, pool(est, se)]; pe("types_linear", lin); claim("the linear version covers the same same-level systems and is positive, not significant at 10%", lin$n_sys == TY("gamma_dis")$n_sys && lin$re_mean > 0 && ns(lin))

# ---- question 4: along the achievement distribution (step 9) ----
qp <- rd(9, "quantile_iv_pool.csv"); Q <- function(tm, st = A) one(qp[term == tm & set == st])
for (q in c(10, 25, 50, 75, 90)) pe(paste0("q", q), Q(paste0("gamma_", q)))
pe("q7525", Q("gamma_75_25")); pe("q9010", Q("gamma_90_10")); claim("both contrasts along the distribution are significant at 5%", sig5(Q("gamma_75_25")) && sig5(Q("gamma_90_10")))
claim("no single system shows a significant contrast at 5%", Q("gamma_75_25")$pos_05 + Q("gamma_75_25")$neg_05 + Q("gamma_90_10")$pos_05 + Q("gamma_90_10")$neg_05 == 0)
cnt("q7525_sig10", Q("gamma_75_25")$pos_10 + Q("gamma_75_25")$neg_10)
qc <- rd(9, "quantile_iv_sys.csv")[term == "gamma_75_25" & usable == TRUE]; stopifnot(nrow(qc) == Q("gamma_75_25")$n_sys); cnt("q7525_rising", qc[est > 0, .N]); cnt("q7525_falling", qc[est <= 0, .N])
claim("the gain rises between the 25th and the 75th percentile in more than half of the systems, but not in all", qc[est > 0, .N] > nrow(qc) / 2 && qc[est <= 0, .N] >= 5)
pe("q7525_strong", Q("gamma_75_25", STRONG)); pe("q9010_strong", Q("gamma_90_10", STRONG)); claim("in the strong-first-stage systems the contrasts keep their sign and are not significant at 5%", Q("gamma_75_25", STRONG)$re_mean > 0 && Q("gamma_90_10", STRONG)$re_mean > 0 && !sig5(Q("gamma_75_25", STRONG)) && !sig5(Q("gamma_90_10", STRONG)))
cnt("q10_missing", NS - Q("gamma_10")$n_sys); cnt("q90_missing", NS - Q("gamma_90")$n_sys); cnt("q7525_sys", Q("gamma_75_25")$n_sys); cnt("q9010_sys", Q("gamma_90_10")$n_sys); claim("the 10th and the 90th percentile are missing in the same number of systems", Q("gamma_10")$n_sys == Q("gamma_90")$n_sys)
put("tau_q10", f(Q("tau_10")$re_mean)); put("tau_q90", f(Q("tau_90")$re_mean)); claim("the same-age gain rises from the 10th to the 90th percentile, with contrasts not significant at 10%", Q("tau_90")$re_mean > Q("tau_10")$re_mean && ns(Q("tau_75_25")) && ns(Q("tau_90_10")))
put("rank_implied", f((sm$rank_high - sm$rank_low) / 50 * Q("gamma_75_25")$re_mean))

# ---- question 5: skills (steps 13, 14, 15) ----
P13 <- rd(13, "skills_pool.csv")[set == A]; ks <- rd(13, "skills_sys.csv"); P14 <- rd(14, "skills_catchup_pool.csv")[set == A]; P15 <- rd(15, "quantile_iv_skills_pool.csv")[set == A]; acc <- rd(13, "skills_gradient_accounting.csv")
SCALES <- c(CURIO_z = "curio", ENPROBS_z = "enprobs", COGABIL_z = "cogabil", GOALSET_z = "goalset", SELFREG_z = "selfreg", PERSEV_z = "persev", BELONG_z = "belong"); VARS <- c(SCALES, LEARN = "learn", growth = "growth")
O <- function(v, tm, sp = "base") one(P13[part == "outcome" & var == v & spec == sp & term == tm]); M <- function(v, tm) one(P13[part == "moderator" & var == v & spec == "alone" & term == tm])
have <- unique(ks[part == "outcome" & spec == "base" & term == "gamma" & var %in% names(SCALES), .(CNT, var)])
lacks <- function(cnt) sort(setdiff(names(SCALES), have[CNT == cnt, var])); nopers <- setdiff(an$CNT, have[var == "PERSEV_z", CNT])
cnt("sk_sys", uniqueN(have$CNT)); cnt("sk_index_sys", O("LEARN", "gamma")$n_sys); cnt("sk_persev_other", length(setdiff(nopers, c("KHM", "USA"))))
claim("Cambodia is the only system with no skill scale", identical(setdiff(an$CNT, have$CNT), "KHM"))
claim("Mauritius lacks exactly enjoyment of problem-solving, cognitive adaptability, goal setting and self-regulation", identical(lacks("MUS"), sort(c("ENPROBS_z", "COGABIL_z", "GOALSET_z", "SELFREG_z"))))
claim("the United States lacks exactly curiosity and perseverance", identical(lacks("USA"), sort(c("CURIO_z", "PERSEV_z"))))
claim("every other system has all scales except, in some, perseverance", all(sapply(setdiff(unique(have$CNT), c("MUS", "USA")), function(x) all(lacks(x) %in% "PERSEV_z"))))
claim("the index is missing only in Cambodia, Mauritius and the United States", O("LEARN", "gamma")$n_sys == NS - 3)
for (v in names(VARS)) { pe(paste0("sk_", VARS[v]), O(v, "gamma"), 2); pe(paste0("sk_", VARS[v], "_tau"), O(v, "tau"), 2) }
claim("curiosity, enjoyment of problem-solving and the index rise significantly at 5%", sig5(O("CURIO_z", "gamma")) && sig5(O("ENPROBS_z", "gamma")) && sig5(O("LEARN", "gamma")))
claim("goal setting and cognitive adaptability rise by the same rounded amount, significant at 10% only", f(O("GOALSET_z", "gamma")$re_mean, 2) == f(O("COGABIL_z", "gamma")$re_mean, 2) && sig10only(O("GOALSET_z", "gamma")) && sig10only(O("COGABIL_z", "gamma")))
claim("growth mindset rises, significant at 10% only", sig10only(O("growth", "gamma")) && O("growth", "gamma")$re_mean > 0)
claim("perseverance, self-regulation and belonging do not change (not significant at 10%)", all(sapply(c("PERSEV_z", "SELFREG_z", "BELONG_z"), function(v) ns(O(v, "gamma")))))
claim("at a given age perseverance, cognitive adaptability and enjoyment are significantly lower at 5%, and no other scale is", setequal(names(SCALES)[sapply(names(SCALES), function(v) sig5(O(v, "tau")) && O(v, "tau")$re_mean < 0)], c("PERSEV_z", "COGABIL_z", "ENPROBS_z")))
pe("sk_learn_ses", O("LEARN", "main:ESCS_z", "by_ses"), 2); pe("sk_goalset_x_ses", O("GOALSET_z", "gamma:ESCS_z", "by_ses"), 2)
claim("the yearly change differs by SES (5%) for goal setting only, where it is smaller for advantaged students", identical(names(SCALES)[sapply(names(SCALES), function(v) sig5(O(v, "gamma:ESCS_z", "by_ses")))], "GOALSET_z") && O("GOALSET_z", "gamma:ESCS_z", "by_ses")$re_mean < 0 && !sig5(O("LEARN", "gamma:ESCS_z", "by_ses")))
pe("learn_level", M("LEARN", "main:LEARN")); pe("learn_gain", M("LEARN", "gamma:LEARN")); claim("the index changes the yearly gain at 10% but not at 5%", sig10only(M("LEARN", "gamma:LEARN")))
claim("no single scale changes the yearly gain by as much as one point", all(sapply(names(SCALES), function(v) abs(M(v, paste0("gamma:", v))$re_mean) < 1)))
GR <- function(tm) one(P14[part == "groups" & term == tm])
pe("grp_lo_weak", GR("gain_lo_weak")); pe("grp_lo_strong", GR("gain_lo_strong")); pe("grp_lo_strong_vs_hi", GR("lo_strong_minus_hi_all")); claim("low-third students with stronger skills gain no more than high-third students", ns(GR("lo_strong_minus_hi_all")))
d <- GR("level_lo_strong_minus_hi_weak"); put("grp_level_gap", f(abs(d$re_mean))); put("grp_level_gap_se", f(d$re_se)); claim("low-third students with stronger skills score below high-third students with weaker skills", d$re_mean < 0 && sig5(d))
pe("learn_x_ses", one(P14[part == "three-way" & var == "LEARN" & term == "gamma:MxS"]))
QS <- function(tm) one(P15[term == tm]); pe("qs_base", QS("base_90_10")); pe("qs_held", QS("held_90_10")); cnt("qs_sys", QS("base_90_10")$n_sys)
d <- QS("change_90_10"); put("qs_change", f(abs(d$re_mean))); put("qs_change_se", f(d$re_se)); put("qs_share_pct", pct(abs(d$re_mean) / QS("base_90_10")$re_mean)); claim("holding skills fixed lowers the contrast, by an amount that is not significant", d$re_mean < 0 && ns(d))
a9 <- one(acc[contrast == "90_10"]); put("acc_gap", f(a9$skill_gap_sd, 2)); put("acc_explained", f(a9$explained, 2)); put("acc_explained_se", f(a9$explained_se, 2)); put("acc_share_pct", pct(a9$share))
claim("skills account for about a sixth of the gradient by both calculations (12% to 22%)", all(c(a9$share, abs(d$re_mean) / QS("base_90_10")$re_mean) > .12 & c(a9$share, abs(d$re_mean) / QS("base_90_10")$re_mean) < .22))

# ---- robustness: the second estimator, the forest, sex (steps 2, 3, 5, 16, 17) ----
ap <- rd(2, "age_profile_pool.csv"); pdn <- rd(2, "pooled_design_pool.csv"); dr <- rd(3, "drifting_pool.csv"); p5 <- rd(5, "ses_gain_pooled_pool.csv")
cnt("flat_sys", ap[group == "flat", n_sys]); pe("age_flat", ap[group == "flat"]); pe("age_cutoff", ap[group == "cutoff"]); pe("tau_pooled", pdn[design == "pooled: one common slope"])
d <- one(dr[set == "drifting, grade slope 0.3 or more" & slope_uncertainty == "fixed"]); cnt("drift_sys", d$n_sys); pe("tau_drift", d)
d <- one(p5[set == "cutoff and drifting" & term == "tau_S"]); cnt("both_sys", d$n_sys); pe("ses_tau_both", d)
fo <- rd(16, "forest_summary.csv"); im <- rd(16, "forest_importance.csv")
rate <- function(key, w) { d <- one(fo[what == w]); put(key, f(d$est)); put(paste0(key, "_se"), f(d$se)); put(paste0(key, "_p"), pv(2 * pnorm(-abs(d$z)))) }
rate("rate_forest", "RATE, forest ranking AUTOC"); rate("rate_skill", "RATE, ranking by the skill index AUTOC"); rate("rate_ses", "RATE, ranking by ESCS AUTOC")
claim("the forest's most used variables are curiosity and sex, then socio-economic status and perseverance, in that order", identical(sub("importance ", "", im[order(-importance), what][1:4]), c("CURIO_z", "female", "ESCS_z", "PERSEV_z")))
sx <- one(rd(17, "gain_by_sex_pool.csv")[set == A & spec == "sex" & outcome == "ACH" & term == "gamma:female"]); pe("sex_gain", sx)
cnt("sex_girls05", sx$pos_05); cnt("sex_boys05", sx$neg_05); cnt("sex_girls10", sx$pos_10); cnt("sex_boys10", sx$neg_10); claim("the gain does not differ by sex on average", ns(sx))

# ---- write ----
con <- file(file.path(OUT, "numbers.yml"), open = "wb")
writeLines(enc2utf8(c(sprintf("# Written by 01_code/19_text_numbers.R from run '%s'; excluded systems: %s. Do not edit.", RUN, paste(EXCLUDE, collapse = " ")), "n:", paste0("  ", names(N), ": \"", unlist(N), "\""))), con, useBytes = TRUE); close(con)   # paste0, not sprintf: in a C locale sprintf turns the minus sign into "<e2><88><92>"
stopifnot(!any(grepl("<[0-9a-f]{2}>", readLines(file.path(OUT, "numbers.yml"), warn = FALSE))))
CLT <- rbindlist(CL); fwrite(CLT, file.path(OUT, "text_claims.csv"))
cat(sprintf("wrote numbers.yml with %d numbers; %d of %d claims hold\n", length(N), sum(CLT$holds), nrow(CLT)))
if (any(!CLT$holds)) { cat("\nClaims the text makes that these results do not support (rewrite the sentence, then the claim):\n"); cat(paste0("  - ", CLT[holds == FALSE, claim]), sep = "\n"); quit(status = 2) }
