# IV learning -- tables for the manuscript. Reporting only: reads saved estimates, fits nothing.
# Writes LaTeX (booktabs, threeparttable) to 04_output/tables/table*.tex, which the manuscript reads with \input, and the same numbers
# as CSV. Conventions, the same in every table: an estimate with its standard error in parentheses (on the line below, or beside it
# in table 3); ** p < 0.05, * p < 0.10 (two-sided, normal); counts of systems at both levels; a note under each table. Stars, minus
# signs and the multiplication sign are set as text, so that they take the font of the manuscript and not the math font.
# Rscript 06_scoping/13_iv_learning/01_code/18_tables.R        (TAB_OUT, PAPER_RUN and STEPn_DIR override the defaults)
suppressPackageStartupMessages(library(data.table))
PROJECT <- "06_scoping/13_iv_learning"; source(file.path(PROJECT, "01_code/sample_rules.R")); source(file.path(PROJECT, "01_code/run_of_record.R"))
S1 <- step_dir(1); S4 <- step_dir(4); S5 <- step_dir(5); S6 <- step_dir(6); S10 <- step_dir(10); S11 <- step_dir(11); S12 <- step_dir(12); S13 <- step_dir(13); S14 <- step_dir(14); S15 <- step_dir(15)
OUT <- Sys.getenv("TAB_OUT", file.path(PROJECT, "04_output/tables")); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# ---- LaTeX helpers ----
star <- function(z) fifelse(is.na(z), "", fifelse(abs(z) > qnorm(.975), "**", fifelse(abs(z) > qnorm(.95), "*", "")))
num <- function(x, d = 1) ifelse(is.na(x), "", sub("^-", "\u2212", sub("^-(0\\.?0*)$", "\\1", formatC(x, format = "f", digits = d))))   # a true minus sign; no minus on a rounded zero
est <- function(e, s, d = 1) ifelse(is.na(e), "", paste0(num(e, d), ifelse(star(e / s) == "", "", paste0("\\textsuperscript{", star(e / s), "}"))))
se <- function(s, d = 1) ifelse(is.na(s), "", paste0("(", formatC(s, format = "f", digits = d), ")"))
big <- function(n) ifelse(is.na(n), "", formatC(n, format = "d", big.mark = ","))
row <- function(...) paste0(paste(c(...), collapse = " & "), " \\\\")
pair <- function(label, lead, e, s, d = 1) c(row(label, lead, est(e, s, d)), row("", rep("", length(lead)), se(s, d)))   # estimate line, then SE line
panel <- function(txt, ncol) c("\\addlinespace", sprintf("\\multicolumn{%d}{l}{\\textit{%s}} \\\\", ncol, txt))
STARS <- "\\textsuperscript{**} \\textit{p} < 0.05, \\textsuperscript{*} \\textit{p} < 0.10."; X <- "\u00d7"
write_tex <- function(name, spec, head, body, note, size = "\\small") {
  con <- file(file.path(OUT, paste0(name, ".tex")), open = "wb")
  writeLines(enc2utf8(c("\\begin{threeparttable}", size, "\\setlength{\\tabcolsep}{4.5pt}", sprintf("\\begin{tabular}{@{}%s@{}}", spec), "\\toprule", head, "\\midrule", body, "\\bottomrule", "\\end{tabular}",
               "\\begin{tablenotes}[flushleft]", "\\footnotesize", paste0("\\item \\textit{Notes:} ", note), "\\end{tablenotes}", "\\end{threeparttable}")), con, useBytes = TRUE); close(con)
  message("wrote ", name, ".tex") }
keep_csv <- function(x, name) fwrite(x, file.path(OUT, paste0(name, ".csv")))
shortn <- function(x) { x <- sub(" \\(China\\)$", "", x); x[x == "B-S-J-Z"] <- "B-S-J-Z (China)"; x[x == "Brunei Darussalam"] <- "Brunei"; x[x == "Palestinian Authority"] <- "Palestine"; x }

# ---- Table 1: systems ----
rules <- fread("03_outputs/04_entry_rules/entry_rules.csv")
f1 <- fread(file.path(S1, "first_stage_sys.csv"))[term == "fs", .(CNT, fs = est, fs_se = se, n, share_repeated)]; stopifnot(!any(f1$CNT %in% EXCLUDE))
g6 <- fread(file.path(S6, "gap_years_sys.csv"))[, .(CNT, years3, years3_se_system, gamma, se_gamma)]
s10 <- fread(file.path(S10, "school_spread_sys.csv"))[, .(CNT, schools)]
t1 <- Reduce(function(a, b) merge(a, b, by = "CNT", all.x = TRUE), list(f1, rules[, .(CNT, name, pisa_cut, entry_age, same_level = !top2_cross_levels)], g6, s10))
t1[, name := shortn(name)]; setorder(t1, name); keep_csv(t1, "table1_systems")
cutlab <- function(x) paste(month.abb[as.integer(substr(x, 6, 7))], substr(x, 1, 4))
write_tex("table1", "l l c r@{\\ }l r r@{\\ }l r c",
  c(row("", "", "Entry", "\\multicolumn{2}{c}{First}", "", "\\multicolumn{2}{c}{SES gap,}", "Schools with", "Same"),
    row("System", "Cutoff", "age", "\\multicolumn{2}{c}{stage}", "Students", "\\multicolumn{2}{c}{school years}", "both grades", "level")),
  t1[, row(name, cutlab(pisa_cut), entry_age, formatC(fs, format = "f", digits = 2), se(fs_se, 2), big(n), num(years3, 1), se(years3_se_system, 1), ifelse(is.na(schools), "", big(schools)), fifelse(same_level, "yes", "no")), by = seq_len(nrow(t1))]$V1,
  "Standard errors in parentheses. Cutoff: first birth month on the younger side of the school-entry cutoff. Entry age: official entrance age to primary education. First stage: coefficient of born-before-the-cutoff in the grade equation. SES gap: difference in achievement between the high and the low third of socio-economic status, divided by the mean yearly gain across systems, with the system's own standard error; blank where the index is missing. Schools with both grades: schools with five or more sampled students in each grade and three or more on each side of the cutoff; blank where a system has fewer than 30. Same level: the two main grades belong to the same level of education.",
  size = "\\footnotesize")

# ---- Table 2: the gain by family background ----
p4 <- fread(file.path(S4, "ses_gain_pool.csv"))[set == "all with ESCS (Ukraine out)"]; p5 <- fread(file.path(S5, "ses_gain_pooled_pool.csv"))[term == "tau_S"]
cnt <- function(x, sgn) if (sgn > 0) sprintf("%d / %d", x$pos_05, x$pos_10) else sprintf("%d / %d", x$neg_05, x$neg_10)
r2 <- function(lab, sp, oc, tt, tg) { a <- p4[spec == sp & outcome == oc & term == tt]; b <- p4[spec == sp & outcome == oc & term == tg]
  list(csv = data.table(row = lab, systems = a$n_sys, same_age = a$re_mean, same_age_se = a$re_se, yearly = b$re_mean, yearly_se = b$re_se, pos_05 = b$pos_05, pos_10 = b$pos_10, neg_05 = b$neg_05, neg_10 = b$neg_10),
       tex = c(row(lab, a$n_sys, est(a$re_mean, a$re_se), est(b$re_mean, b$re_se), cnt(b, 1), cnt(b, -1)), row("", "", se(a$re_se), se(b$re_se), "", ""))) }
r2p <- function(lab, st) { a <- p5[set == st]
  list(csv = data.table(row = lab, systems = a$n_sys, same_age = a$re_mean, same_age_se = a$re_se, yearly = NA_real_, yearly_se = NA_real_, pos_05 = NA, pos_10 = NA, neg_05 = NA, neg_10 = NA),
       tex = c(row(lab, a$n_sys, est(a$re_mean, a$re_se), "", "", ""), row("", "", se(a$re_se), "", "", ""))) }
R2 <- list(A = list(r2("Per SD of SES", "base", "ACH", "tau:ESCS_z", "gamma:ESCS_z"), r2("High third minus low third", "thirds", "ACH", "tau:high", "gamma:high")),
           B = list(r2("Mathematics", "base", "MATH", "tau:ESCS_z", "gamma:ESCS_z"), r2("Reading", "base", "READ", "tau:ESCS_z", "gamma:ESCS_z"), r2("Science", "base", "SCIE", "tau:ESCS_z", "gamma:ESCS_z")),
           C = list(r2("Within schools", "school_fe", "ACH", "tau:ESCS_z", "gamma:ESCS_z"), r2("Without repeaters", "no_repeaters", "ACH", "tau:ESCS_z", "gamma:ESCS_z"), r2("Years in school as the treatment", "years", "ACH", "tau:ESCS_z", "gamma:ESCS_z")),
           D = list(r2p("Systems with a cutoff", "cutoff systems"), r2p("Systems where grade drifts with birth month", "drifting systems"), r2p("Both", "cutoff and drifting")))
keep_csv(rbindlist(lapply(unlist(R2, recursive = FALSE), `[[`, "csv")), "table2_gain_by_ses")
tx2 <- function(k) unlist(lapply(R2[[k]], `[[`, "tex"))
write_tex("table2", "l c c c c c",
  c(row("", "", "Same-age", "Yearly", "\\multicolumn{2}{c}{Systems significant}"), row("", "", "gain", "gain", "\\multicolumn{2}{c}{at 5\\% / 10\\%}"), "\\cmidrule(l){5-6}", row("", "Systems", paste(X, "SES"), paste(X, "SES"), "Positive", "Negative")),
  c(panel("A. Combined achievement", 6)[-1], tx2("A"), panel("B. By domain, per SD of SES", 6), tx2("B"), panel("C. Other samples and treatments, per SD of SES", 6), tx2("C"), panel("D. Second estimator, per SD of SES", 6), tx2("D")),
  paste("Random-effects means across systems, PISA points; standard errors in parentheses.", STARS, "Columns 2 and 3: change in the gain per standard deviation of socio-economic status (SES) or, in the second row, between the high and the low third. The last two columns count the systems in which the interaction of the yearly gain with SES is significantly positive or negative, at 5\\% and at 10\\%. Panel D takes the age profile from systems in which grade does not vary with birth month and estimates the same-age gain only."))

# ---- Table 3: schools ----
o10 <- fread(file.path(S10, "school_spread_overall.csv")); o11 <- fread(file.path(S11, "placebo_overall.csv")); p12 <- fread(file.path(S12, "school_types_pool.csv"))[spec == "types"]
keep_csv(o10, "table3a_spread"); keep_csv(o11, "table3b_checks"); keep_csv(p12, "table3c_types")
A <- function(lab, st) { x <- o10[set == st]; row(lab, x$systems, big(x$schools), num(x$sd), sprintf("%s to %s", num(x$sd_lo), num(x$sd_hi)), formatC(x$p_perm, format = "f", digits = 3)) }
B <- function(lab, ck, st) { x <- o11[check == ck & set == st]; ses <- ck == "balance on SES"
  row(lab, x$systems, big(x$schools), if (ses) sprintf("%s SD", num(x$sd, 2)) else num(x$sd), if (ses) sprintf("up to %s SD", num(x$sd_hi, 2)) else sprintf("up to %s", num(x$sd_hi)), formatC(x$p_perm, format = "f", digits = 3)) }
C3 <- function(lab, tm, st) { x <- p12[term == tm & set == st]; row(lab, x$n_sys, "", est(x$re_mean, x$re_se), se(x$re_se), "") }
SL <- "two grades in the same level"
write_tex("table3", "l c c c c c", c(row("", "", "", "", "Interval, bound", ""), row("", "Systems", "Schools", "Estimate", "or (SE)", "\\textit{p}")),
  c(panel("A. Between-school standard deviation of the gain, points", 6)[-1], A("All systems", "all systems with 30+ such schools"), A("Both grades in the same level", "two grades in the same level of education"),
    A("Grades in different levels", "two grades in different levels"), A("Same level, first stage 0.5 or more", "same level and first stage 0.5 or more"),
    panel("B. Checks", 6), B("SES difference between birth groups, same level", "balance on SES", "two grades in the same level of education"),
    B("SES difference between birth groups, different levels", "balance on SES", "two grades in different levels"),
    B("False cutoff, all systems", "false cutoff, born before", "all"), B("False cutoff, same level", "false cutoff, born before", "two grades in the same level of education"),
    panel("C. Yearly gain by school type, both grades in the same level, points", 6), C3("Disadvantaged schools", "gamma_dis", SL), C3("Mixed schools", "gamma_mixed", SL), C3("Advantaged schools", "gamma_adv", SL),
    C3("Disadvantaged minus advantaged", "gamma_dis_minus_adv", SL), C3("Level, disadvantaged minus advantaged", "level_dis_minus_adv", SL),
    panel("D. Yearly gain, disadvantaged minus advantaged, other systems, points", 6), C3("All systems", "gamma_dis_minus_adv", "all"), C3("Grades in different levels", "gamma_dis_minus_adv", "two grades in different levels")),
  paste("Panel A: standard deviation across schools of the gain from one more grade, with a 90\\% interval; \\textit{p} from 200 shuffles of birth side inside schools, so its smallest value is 0.005. Panel B: the same procedure applied to the spread across schools of the difference in socio-economic status (SES) between the two birth groups (in standard deviations of the index) and to a false cutoff inside the older birth side; 95\\% upper bounds. Panels C and D: random-effects means across systems with standard errors in parentheses;", STARS, "Disadvantaged (advantaged) schools: the quarter of students whose schools have the largest share of students from the low (high) third of socio-economic status."))

# ---- Table 4: skills ----
P13 <- fread(file.path(S13, "skills_pool.csv"))[set == "all (Ukraine out)"]; P14 <- fread(file.path(S14, "skills_catchup_pool.csv"))[set == "all (Ukraine out)"]; P15 <- fread(file.path(S15, "quantile_iv_skills_pool.csv"))[set == "all (Ukraine out)"]
keep_csv(P13, "table4_skills"); keep_csv(P14, "table5_skills_groups"); keep_csv(P15, "table5_quantile_skills")
nm <- c(CURIO_z = "Curiosity", ENPROBS_z = "Enjoyment of problem-solving", COGABIL_z = "Cognitive adaptability", GOALSET_z = "Goal setting", SELFREG_z = "Self-regulation", PERSEV_z = "Perseverance", BELONG_z = "Sense of belonging", LEARN = "Index of learning skills", growth = "Growth mindset")
g2 <- function(d, tt) { x <- d[term == tt]; if (nrow(x)) c(x$re_mean, x$re_se) else c(NA_real_, NA_real_) }
body4 <- unlist(lapply(names(nm), function(v) { o <- P13[part == "outcome" & var == v]; m <- P13[part == "moderator" & var == v]
  cols <- list(g2(o[spec == "base"], "gamma"), g2(o[spec == "base"], "tau"), g2(o[spec == "by_ses"], "main:ESCS_z"), g2(o[spec == "by_ses"], "gamma:ESCS_z"), g2(m[spec == "alone"], paste0("main:", v)), g2(m[spec == "alone"], paste0("gamma:", v)))
  d <- c(3, 3, 3, 3, 1, 1)
  c(if (v == "LEARN") "\\addlinespace", row(nm[v], o[spec == "base" & term == "gamma", n_sys], mapply(function(x, k) est(x[1], x[2], k), cols, d)), row("", "", mapply(function(x, k) se(x[2], k), cols, d))) }))
write_tex("table4", "l c c c c c c c",
  c(row("", "", "\\multicolumn{4}{c}{Skill as the outcome (SD of the skill)}", "\\multicolumn{2}{c}{Achievement (points)}"), "\\cmidrule(lr){3-6}\\cmidrule(lr){7-8}",
    row("", "", "Yearly", "At a", "Per SD", "Yearly change", "Per SD", "Yearly gain"), row("", "Systems", "change", "given age", "of SES", paste(X, "SES"), "of skill", paste(X, "skill"))),
  body4, paste("Random-effects means across systems; standard errors in parentheses.", STARS, "Skills are standardised within the system. Yearly change: the gain from one more grade and one more year of age. At a given age: the gain from one more grade with birth month held fixed. The last two columns give the points of achievement associated with one standard deviation of the skill and the change in the yearly gain in achievement per standard deviation of the skill. Growth mindset is a single item and is not used as a moderator."),
  size = "\\footnotesize")
G <- function(lab, tm) { x <- P14[part == "groups" & term == tm]; pair(lab, x$n_sys, x$re_mean, x$re_se) }
Q <- function(lab, tm) { x <- P15[term == tm]; pair(lab, x$n_sys, x$re_mean, x$re_se) }
tw <- P14[part == "three-way" & var == "LEARN" & term == "gamma:MxS"]
write_tex("table5", "l c c", row("", "Systems", "Estimate"),
  c(panel("A. Yearly gain by socio-economic status and skills", 3)[-1], G("Low third, weaker skills", "gain_lo_weak"), G("Low third, stronger skills", "gain_lo_strong"), G("High third, weaker skills", "gain_hi_weak"), G("High third, stronger skills", "gain_hi_strong"),
    G("Low third with stronger skills minus all of the high third", "lo_strong_minus_hi_all"), pair("Change in the gain per SD of skill, per SD of SES", tw$n_sys, tw$re_mean, tw$re_se),
    G("Level of achievement: low third, stronger skills minus high third, weaker skills", "level_lo_strong_minus_hi_weak"),
    panel("B. Yearly gain along the achievement distribution", 3), Q("90th minus 10th percentile", "base_90_10"), Q("The same with skills held fixed", "held_90_10"), Q("Change", "change_90_10"),
    Q("75th minus 25th percentile", "base_75_25"), Q("The same with skills held fixed", "held_75_25"), Q("Change", "change_75_25")),
  paste("Random-effects means across systems, PISA points; standard errors in parentheses.", STARS, "Stronger skills: above the system's median of the index of learning skills. Panel B uses the systems that have the index."))
