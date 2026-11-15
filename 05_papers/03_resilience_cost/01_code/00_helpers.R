# The cost of resilience -- paper helpers. Shared survey functions come from the frozen legacy layer; this file only sets the paper's output paths.
# PAPER_OUT redirects estimation output (use it for any re-estimation: never overwrite 04_output in place; see ../README.md).
source("02_scripts/02_legacy/wellbeing_shared/00_survey_helpers.R")
OUTR <- paste0(Sys.getenv("PAPER_OUT", "05_papers/03_resilience_cost/04_output"), "/"); dir.create(OUTR, recursive = TRUE, showWarnings = FALSE)
orr <- function(f) paste0(OUTR, f)
# Systems left out of every analysis in this paper. QUA = Ukraine (17 of 27 regions); excluded by the author's decision on 15 November 2026
# (see README, "Ukraine excluded"). The shared layer is not changed: the exclusion is applied here, when the prepared data are loaded.
# PAPER_EXCLUDE="" reproduces the estimates that included Ukraine.
EXCLUDE <- strsplit(Sys.getenv("PAPER_EXCLUDE", "QUA"), " ", fixed = TRUE)[[1]]
load_rw <- function() readRDS(DERIV)[!CNT %in% EXCLUDE]
