# The cost of resilience -- paper helpers. Shared survey functions come from the frozen legacy layer; this file only sets the paper's output paths.
# PAPER_OUT redirects estimation output (use it for any re-estimation: never overwrite 04_output in place; see ../README.md).
source("02_scripts/02_legacy/wellbeing_shared/00_survey_helpers.R")
OUTR <- paste0(Sys.getenv("PAPER_OUT", "05_papers/03_resilience_cost/04_output"), "/"); dir.create(OUTR, recursive = TRUE, showWarnings = FALSE)
orr <- function(f) paste0(OUTR, f)
# Systems left out of every analysis in this paper. QUA = Ukraine (17 of 27 regions); excluded by the author's decision on 15 November 2026
# (see README, "Ukraine excluded"). The shared layer is not changed: the exclusion is applied here, when the prepared data are loaded.
# PAPER_EXCLUDE="" reproduces the estimates that included Ukraine.
EXCLUDE <- strsplit(Sys.getenv("PAPER_EXCLUDE", "QUA"), " ", fixed = TRUE)[[1]]
# Achievement measure (author's decision, 15 November 2026): reading is the main measure; the check is a composite weighted towards
# reading (1/2 reading, 1/4 mathematics, 1/4 science). The prepared file holds only the simple average of the three domains (ACH1-ACH10),
# so the plausible values are taken from the shared student extract and ACH1-ACH10 are replaced when the data are loaded. Every step
# reads achievement through ACH1-ACH10, so this one switch changes the groups, the schoolmates' mean achievement and every model.
#   PAPER_ACH = READ (default) | ACHW (weighted composite) | SCIE (science) | ACH (simple average: the definition used until 15 November 2026)
ACH_DOMAIN <- Sys.getenv("PAPER_ACH", "READ"); stopifnot(ACH_DOMAIN %in% c("READ", "ACHW", "SCIE", "ACH"))
load_rw <- function() {
  d <- readRDS(DERIV)[!CNT %in% EXCLUDE]
  if (ACH_DOMAIN == "ACH") return(d)
  pv <- fread(STUDENTS, select = c("CNTSTUID", PV("READ"), PV("MATH"), PV("SCIE")))
  stopifnot(!anyDuplicated(pv$CNTSTUID)); i <- match(d$CNTSTUID, pv$CNTSTUID); stopifnot(!anyNA(i))
  for (p in 1:10) { r <- pv[[paste0("PV", p, "READ")]][i]; m <- pv[[paste0("PV", p, "MATH")]][i]; sc <- pv[[paste0("PV", p, "SCIE")]][i]
    if (p == 1) stopifnot(isTRUE(all.equal(d$ACH1, (m + r + sc) / 3)))          # the extract matches the prepared file
    set(d, j = paste0("ACH", p), value = switch(ACH_DOMAIN, READ = r, SCIE = sc, ACHW = 0.5 * r + 0.25 * m + 0.25 * sc)) }
  d
}
