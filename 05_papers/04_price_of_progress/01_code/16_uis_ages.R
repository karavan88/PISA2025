# The price of progress -- step 16: official starting age and level lengths (UNESCO UIS) against the grades and cutoff the PISA data show.
# Descriptive; fits nothing. Reads 04_output/external_uis/ (UIS public API extract and the user's indicator-403 export; Git-ignored, see SOURCES.txt).
# Writes uis_ages.csv to $PAPER_OUT (a NEW directory).
#   entry_age   official entrance age to primary education (years); dur_primary, dur_lowsec  theoretical durations
#   age_lo      age at the start of the school year of a pupil in the LOWER grade g_lo of the PISA cohort: entry_age + g_lo - 1 (grades counted from
#               primary grade 1). PISA tests 15-year-olds about three to eight months into the school year, so age_lo is expected near 14 (one year
#               below the age of the upper grade's pupils). Values far from 14 mean the grade labels, the entry age or the cohort differ from the
#               simple reading, e.g. pre-primary counted as a grade, or grade repetition. This is a flag, not a test.
#   start_month the UIS school-year start month (indicator 403), latest year up to 2025
suppressPackageStartupMessages({ library(data.table); library(jsonlite) })
OUT <- Sys.getenv("PAPER_OUT"); if (!nzchar(OUT)) stop("Set PAPER_OUT to a NEW directory"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
X <- "05_papers/04_price_of_progress/04_output/external_uis"
r <- as.data.table(fromJSON(file.path(X, "uis_api_entry_age_durations_2022_2026.json"))$records)
r <- r[year <= 2025 & !is.na(value), .SD[year == max(year)], by = .(indicatorId, geoUnit)]
w <- dcast(r, geoUnit ~ indicatorId, value.var = "value"); setnames(w, c("299905", "299932", "999976"), c("entry_age", "dur_primary", "dur_lowsec"))
m <- fread(file.path(X, "uis_403_start_month.csv"))[year <= 2025 & value > 0, .SD[year == max(year)], by = geoUnit][, .(geoUnit, start_month = value)]
e <- fread("05_papers/02_fuzzy_rd_learning/02_results/eligibility.csv")[eligible == TRUE, .(CNT, name, g_lo, g_hi, cut_label, cutoff_birth_month = bmonth_cut, edge)]
e[, geoUnit := fifelse(CNT == "QCI", "CHN", fifelse(CNT == "QUA", "UKR", CNT))]
# TAP (Taiwan) and KSV (Kosovo) are not in UIS: proxies by the user's decision (2026-11-16), TAP -> CHN, KSV -> ALB; marked in uis_proxy
e[, uis_proxy := fifelse(CNT == "TAP", "CHN", fifelse(CNT == "KSV", "ALB", NA_character_))]; e[!is.na(uis_proxy), geoUnit := uis_proxy]
x <- Reduce(function(a, b) merge(a, b, by = "geoUnit", all.x = TRUE), list(e, w, m))
x[, `:=`(age_lo = entry_age + g_lo - 1, age_hi = entry_age + g_hi - 1)]
x[, flag := fifelse(is.na(age_lo), "no UIS value", fifelse(abs(age_lo - 14) <= 0.5, "", "check"))]
fwrite(x[order(CNT)][, geoUnit := NULL], file.path(OUT, "uis_ages.csv"))
cat("systems:", nrow(x), " with entry age:", sum(!is.na(x$entry_age)), " age_lo within 14 +/- 0.5:", sum(abs(x$age_lo - 14) <= .5, na.rm = TRUE), "\n")
print(x[order(CNT), .(CNT, entry_age, dur_primary, dur_lowsec, g_lo, g_hi, age_lo, start_month, cutoff_birth_month, flag)], nrows = 50)
