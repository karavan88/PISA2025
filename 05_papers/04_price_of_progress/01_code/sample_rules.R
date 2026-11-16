# The price of progress -- project sample rules (user's decision, 2026-11-16), read by every step that builds an estimation sample.
#   EXCLUDE  systems left out of every estimate: QUA = Ukraine (17 of 27 regions), as in papers 01 and 03.
#   FLAG     systems kept but marked in every output and shown with and without: ISR = Israel (paper 01 leaves it out).
# PAPER_EXCLUDE / PAPER_FLAG (space-separated) override the defaults; PAPER_EXCLUDE="" reproduces the runs that included Ukraine.
EXCLUDE <- strsplit(Sys.getenv("PAPER_EXCLUDE", "QUA"), " ", fixed = TRUE)[[1]]
FLAG    <- strsplit(Sys.getenv("PAPER_FLAG", "ISR"), " ", fixed = TRUE)[[1]]
