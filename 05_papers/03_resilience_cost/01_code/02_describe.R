# The Cost of Resilience -- step 2: descriptives that the report and figures read, on this paper's own sample of systems.
# Fits no models. Until 15 November 2026 the two files were taken from the shared layer and from paper 04; they are written here
# so that the systems excluded in 00_helpers.R (EXCLUDE) are left out of them as well.
#   coverage.csv   one row per system: sample size, available skill scales, item coverage (rows of the shared coverage file)
#   desc_dist.csv  the 0-10 distribution of life satisfaction by SES x achievement cell, first plausible value, every system weighted
#                  equally (same definition as 05_papers/04_price_of_progress/01_code/09_extras.R, part b)
# Output: 05_papers/03_resilience_cost/04_output/coverage.csv, desc_dist.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
cov <- fread(file.path(DERIVED, "resilwb_coverage.csv"))[!CNT %in% EXCLUDE]
fwrite(cov, orr("coverage.csv"))

d <- load_rw()
d[, wn := w / sum(w), by = CNT]
d[, c("q25", "q75") := as.list(wquant(ACH1, w, c(.25, .75))), by = CNT]
d[, cell := fifelse(sesq == 1 & ACH1 >= q75, "R", fifelse(sesq == 1 & ACH1 <= q25, "PL", fifelse(sesq == 4 & ACH1 >= q75, "AT", fifelse(sesq == 4 & ACH1 <= q25, "AL", NA_character_))))]
dist <- d[!is.na(cell), .(wt = sum(wn)), by = .(cell, LS)][, share := wt / sum(wt), by = cell][order(cell, LS)]
fwrite(dist[, .(cell, LS, share)], orr("desc_dist.csv"))
log_step("descriptives on", uniqueN(d$CNT), "systems; excluded:", paste(EXCLUDE, collapse = " "))
