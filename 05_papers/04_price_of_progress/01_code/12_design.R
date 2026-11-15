# The price of progress -- step 12: design strength by system (descriptive; fits no new model). Reads the 35-system input layer and the per-system
# estimates of 08b_cutoff35.R; writes design35.csv to $PAPER_OUT (a new directory). Question: why do the 15 systems added to the earlier 20
# show a weak grade effect -- first stage, how many birth months sit on each side of the cutoff, or something else?
#   fs        first stage of the actual grade D on the assigned grade Z (08b)
#   n_*       students and distinct birth months (running variable r) on each side of the cutoff
#   share_D   share in the upper grade; "jump" = share_D(Z=0) - share_D(Z=1) around the cutoff is fs net of the linear birth-month trend
#   gACH, tau ACH, gLS  the base-specification estimates of 08b
suppressPackageStartupMessages(library(data.table))
source("05_papers/04_price_of_progress/01_code/systems.R")
OUT <- Sys.getenv("PAPER_OUT", "05_papers/04_price_of_progress/04_output"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
EST <- Sys.getenv("PAPER_EST", "05_papers/04_price_of_progress/05_archive/estimate_20261115_central35")
a <- readRDS("05_papers/04_price_of_progress/04_output/cutoff35_students.rds"); setDT(a)
s <- fread(file.path(EST, "cutoff35_sys.csv"))
g <- function(o, tm, col) s[outcome == o & term == tm, .(CNT, v = get(col))]
est <- Reduce(function(x, y) merge(x, y, by = "CNT"), list(
  setnames(g("ACH", "fs", "est"), "v", "fs"), setnames(g("ACH", "gamma", "est"), "v", "gACH"), setnames(g("ACH", "gamma", "se"), "v", "se_gACH"),
  setnames(g("ACH", "tau", "est"), "v", "tauACH"), setnames(g("LS_z", "gamma", "est"), "v", "gLS"), setnames(g("LS_z", "gamma", "se"), "v", "se_gLS")))
d <- a[, .(N = .N, n_below = sum(Z == 1), n_above = sum(Z == 0), months_below = uniqueN(r[Z == 1]), months_above = uniqueN(r[Z == 0]),
           share_D = mean(D), D_below = mean(D[Z == 1]), D_above = mean(D[Z == 0]), age = mean(AGE, na.rm = TRUE), LS = mean(LS, na.rm = TRUE),
           ach = mean((PV1READ + PV1MATH + PV1SCIE) / 3, na.rm = TRUE)), by = CNT]
d[, jump := D_below - D_above]
x <- merge(est, d, by = "CNT"); x[, earlier20 := CNT %in% SYSTEMS_TABLE$CNT]
fwrite(x, file.path(OUT, "design35.csv"))
cat("\nBy group (unweighted means over systems):\n"); print(x[, lapply(.SD, function(v) round(mean(v), 2)), by = earlier20,
  .SDcols = c("fs", "jump", "gACH", "gLS", "tauACH", "N", "months_below", "months_above", "D_below", "D_above", "age", "ach", "LS")])
cat("\nThe 15 added systems (sorted by gACH):\n"); print(x[earlier20 == FALSE][order(gACH), .(CNT, N, fs = round(fs, 2), jump = round(jump, 2), mb = months_below, ma = months_above,
  D_below = round(D_below, 2), D_above = round(D_above, 2), gACH = round(gACH, 1), seACH = round(se_gACH, 1), gLS = round(gLS, 3), age = round(age, 2), ach = round(ach))])
cat("\nCorrelation across all 35 of gACH with:", paste(sapply(c("fs", "jump", "months_below", "months_above", "age", "ach"), function(v) paste0(v, " ", round(cor(x$gACH, x[[v]]), 2))), collapse = "; "), "\n")
