# Compare a fresh estimation directory with a reference directory, file by file (numeric columns: maximum absolute difference).
# Usage: Rscript 02_scripts/02_legacy/wellbeing_shared/compare_outputs.R <new_dir> <reference_dir> [tolerance = 1e-9]
# Exit status 1 if any shared CSV differs beyond the tolerance or has different rows; files present on one side only are listed.
suppressPackageStartupMessages(library(data.table))
a <- commandArgs(trailingOnly = TRUE); stopifnot(length(a) >= 2); new <- a[1]; ref <- a[2]; tol <- if (length(a) > 2) as.numeric(a[3]) else 1e-9
fn <- list.files(new, pattern = "[.]csv$"); fr <- list.files(ref, pattern = "[.]csv$"); bad <- FALSE
for (f in intersect(fn, fr)) {
  x <- fread(file.path(new, f)); y <- fread(file.path(ref, f))
  if (!identical(dim(x), dim(y)) || !identical(names(x), names(y))) { cat(sprintf("%-22s DIFFERENT SHAPE %s vs %s\n", f, paste(dim(x), collapse = "x"), paste(dim(y), collapse = "x"))); bad <- TRUE; next }
  num <- names(x)[vapply(x, is.numeric, logical(1))]; chr <- setdiff(names(x), num)
  same_chr <- all(vapply(chr, function(v) identical(as.character(x[[v]]), as.character(y[[v]])), logical(1)))
  d <- if (length(num)) max(vapply(num, function(v) { q <- abs(x[[v]] - y[[v]]); q[is.na(x[[v]]) & is.na(y[[v]])] <- 0; if (anyNA(q)) Inf else max(q, 0) }, numeric(1))) else 0
  ok <- same_chr && d <= tol; bad <- bad || !ok
  cat(sprintf("%-22s %s  rows %d  max |diff| %.3g%s\n", f, if (ok) "same" else "DIFF", nrow(x), d, if (same_chr) "" else "  (labels differ)"))
}
if (length(setdiff(fr, fn))) cat("only in reference:", paste(setdiff(fr, fn), collapse = " "), "\n")
if (length(setdiff(fn, fr))) cat("only in new:", paste(setdiff(fn, fr), collapse = " "), "\n")
quit(status = if (bad) 1 else 0)
