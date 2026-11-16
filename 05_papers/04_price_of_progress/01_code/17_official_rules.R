# The price of progress -- step 17: official school-entry rules against the cutoff month inferred from the PISA data. Descriptive; fits nothing.
# The inferred cutoff (eligibility.csv, bmonth_cut) is the FIRST birth month of the later-born group, who sit in the LOWER grade. An official
# rule "age 6 by 31 August" therefore gives a first lower-grade birth month of September (9). Where the reference date falls mid-month the
# inferred month is typically the next clean month (the partial month is dropped as a donut), so a gap of +1 or -1 is read as consistent.
# The official months below were coded by hand from the sourced tables in 04_output/external_entry_rules/ (compiled by research subagents,
# 2026-11-16, for the children born in 2009; confidence copied from them). NA = no official rule established.
# Writes official_rules_check.csv to $PAPER_OUT (a NEW directory).
suppressPackageStartupMessages(library(data.table))
OUT <- Sys.getenv("PAPER_OUT"); if (!nzchar(OUT)) stop("Set PAPER_OUT to a NEW directory"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
R <- data.table(
  CNT = c("ALB","ARE","AZE","BRA","BRN","CHL","CRI","CZE","DEU","ECU","EST","FIN","GEO","HKG","HRV","ISR","KAZ","KEN","KHM","KOR","KSV","LVA","MUS","NZL","PER","PHL","PRY","PSE","QCI","QUA","ROU","SRB","SVK","SVN","TAP","USA"),
  official = c( 9, NA, 9, 4, NA, 4, 11, 9, NA, NA, 10, 1, 9, 1, 4, 1, NA, NA, NA, 1, 9, 1, 1, NA, 4, 11, 4, NA, 9, NA, 9, 3, 9, 1, 9, 9),
  rule = c("age 6 by start of school year (about 1 Sep); 2015 date not found", "calendar year of 6th birthday per one report; 2015 rule not established", "6th birthday before 15 Sep", "6 by 31 Mar (contested in courts in 2015)", "not found",
           "6 by 31 Mar", "6y3m by 15 Feb (born by 15 Nov)", "6 by 31 Aug", "Land-specific, 30 Jun to 30 Sep; NRW 30 Sep", "not found", "7 before 1 Oct", "calendar year of turning 7", "age 6; 15 Sep not confirmed for 2015", "5y8m by 1 Sep (born by 31 Dec)",
           "6 by 1 Apr", "calendar (Gregorian) birth year", "none set by law (parental choice)", "not found", "6 or 70 months at start of year; dates not found", "calendar year of turning 6 (enter 1 Mar next year)", "6 by start of school year, inferred from law wording", "calendar year of turning 7",
           "5 by 31 Dec", "no common date: entry on the 5th birthday", "6 by 31 Mar", "6 by October 2015 (born by 31 Oct)", "6 by 31 Mar", "not found", "6 by 31 Aug (Shanghai explicit)", "not found for 2015", "6 by 31 Aug",
           "6.5 years by start of school year", "6 by 31 Aug", "calendar year of turning 6", "6 by 1 Sep", "state-set; 1 Sep most common (range 31 Jul to 1 Jan)"),
  confidence = c("low","low","medium","medium","low","high","high","high","low","low","high","high","low","high","high","medium","medium","low","low","medium-high","medium-low","medium","medium","high","high","medium-low","medium","low","high","low","high","medium","high","medium-high","medium-high","medium"))
e <- fread("05_papers/02_fuzzy_rd_learning/02_results/eligibility.csv")[eligible == TRUE, .(CNT, name, inferred = bmonth_cut, jump = round(jump, 2), edge)]
source("05_papers/04_price_of_progress/01_code/sample_rules.R")
# School-year start month confirmed by the user (2026-11-16): September in Albania, Azerbaijan, Kosovo and Kazakhstan. Kazakhstan has no documented entry date,
# so no official cutoff month is coded for it; its inferred September cutoff fits a 1 September reference but that rule is not established.
x <- merge(e, R, by = "CNT"); x[, school_start_confirmed := fifelse(CNT %in% c("ALB", "AZE", "KSV", "KAZ"), 9L, NA_integer_)]; x[, project_rule := fifelse(CNT %in% EXCLUDE, "excluded", fifelse(CNT %in% FLAG, "flagged", ""))]; x[, gap := {d <- (inferred - official) %% 12; fifelse(d > 6, d - 12, d)}]
x[, verdict := fifelse(is.na(official), "no official rule established", fifelse(gap == 0, "match", fifelse(abs(gap) == 1, "within one month", "differs")))]
x[CNT == "DEU", verdict := "within the range of Land dates (7 to 10); inferred month 10"]
x[CNT == "NZL", verdict := "no official birth-date cutoff: entry on the 5th birthday"]
fwrite(x[order(CNT)], file.path(OUT, "official_rules_check.csv"))
print(x[order(CNT), .(CNT, inferred, official, gap, confidence, verdict, edge)], nrows = 50); print(x[, .N, by = verdict][order(-N)])
