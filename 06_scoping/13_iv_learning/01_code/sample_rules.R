# IV learning -- project sample rules, sourced by every step that builds an estimation sample.
#   EXCLUDE  systems left out of every estimate:
#            QUA = Ukraine, user's decision of 2026-11-22, as in papers 01, 03 and 04;
#            ISR = Israel, user's decision of 2026-11-23 ("drop Israel from the paper"). Until then Israel was kept and flagged;
#                  the runs of 2026-11-22 and the first runs of 2026-11-23 under 04_output/estimate_* include it.
#   FLAG     systems kept but marked in every output: none.
# PAPER_EXCLUDE / PAPER_FLAG (space-separated) override the defaults; PAPER_EXCLUDE="QUA" PAPER_FLAG="ISR" reproduces the earlier runs.
# Descriptive reference tables keep all systems and mark the rule.
EXCLUDE <- strsplit(Sys.getenv("PAPER_EXCLUDE", "QUA ISR"), " ", fixed = TRUE)[[1]]
FLAG    <- strsplit(Sys.getenv("PAPER_FLAG", ""), " ", fixed = TRUE)[[1]]
