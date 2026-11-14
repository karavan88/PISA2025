# The cost of resilience -- paper helpers. Shared survey functions come from the frozen legacy layer; this file only sets the paper's output paths.
# PAPER_OUT redirects estimation output (use it for any re-estimation: never overwrite 04_output in place; see ../README.md).
source("02_scripts/02_legacy/wellbeing_shared/00_survey_helpers.R")
OUTR <- paste0(Sys.getenv("PAPER_OUT", "05_papers/03_resilience_cost/04_output"), "/"); dir.create(OUTR, recursive = TRUE, showWarnings = FALSE)
orr <- function(f) paste0(OUTR, f)
