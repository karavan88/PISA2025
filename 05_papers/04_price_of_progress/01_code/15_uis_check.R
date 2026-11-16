# The price of progress -- step 15: rough external check of the inferred school-entry cutoffs against the UNESCO UIS indicator 403
# "Start month of the academic school year (pre-primary to post-secondary non-tertiary)". Descriptive only; fits nothing.
# The UIS month is when the school YEAR starts; the cutoff is the BIRTH month that decides which entry year a child belongs to. They are
# related, not equal (an entry rule can be "age 6 by 31 December" in a country whose school year starts in September), so this table can
# flag clear oddities but cannot confirm a cutoff. Confirming needs the national entry-date rules.
# Input: the unzipped UIS export (data.csv) in the directory given by UIS_DIR (not stored in the repository). Output: uis_check.csv in $PAPER_OUT.
suppressPackageStartupMessages(library(data.table))
UIS <- Sys.getenv("UIS_DIR"); if (!nzchar(UIS)) stop("Set UIS_DIR to the folder holding the UIS export's data.csv")
OUT <- Sys.getenv("PAPER_OUT"); if (!nzchar(OUT)) stop("Set PAPER_OUT to a NEW directory"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
u <- fread(file.path(UIS, "data.csv")); e <- fread("05_papers/02_fuzzy_rd_learning/02_results/eligibility.csv")[eligible == TRUE]
geo <- c(QCI = "CHN", QUA = "UKR"); e[, iso := fifelse(CNT %in% names(geo), geo[CNT], CNT)]    # PISA economy codes that differ from ISO
# TAP (Taiwan) and KSV (Kosovo) are not in UIS: proxies by the user's decision (2026-11-16), TAP -> CHN, KSV -> ALB; marked in uis_proxy
e[, uis_proxy := fifelse(CNT == "TAP", "CHN", fifelse(CNT == "KSV", "ALB", NA_character_))]; e[!is.na(uis_proxy), iso := uis_proxy]
x <- u[year <= 2025 & value > 0, .SD[year == max(year)], by = geoUnit][, .(iso = geoUnit, uis_start_month = value, uis_year = year)]
m <- merge(e[, .(CNT, iso, uis_proxy, inferred_cutoff = cut_label, cutoff_birth_month = bmonth_cut, edge)], x, by = "iso", all.x = TRUE)
m[, gap_months := {d <- (cutoff_birth_month - uis_start_month) %% 12; fifelse(d > 6, d - 12, d)}]   # signed circular gap, -6..6
fwrite(m[order(CNT)], file.path(OUT, "uis_check.csv"))
cat("systems:", nrow(m), " with a UIS month (incl. proxies):", sum(!is.na(m$uis_start_month)), " cutoff month equals the UIS start month:", sum(m$gap_months == 0, na.rm = TRUE),
    " within 1 month:", sum(abs(m$gap_months) <= 1, na.rm = TRUE), " cutoff in Dec or Jan (calendar-year cohorts):", sum(m$cutoff_birth_month %in% c(12, 1)), "\n")
print(m[order(CNT), .(CNT, inferred_cutoff, uis_start_month, gap_months, edge)], nrows = 50)
