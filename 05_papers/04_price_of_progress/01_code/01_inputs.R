# The price of progress -- step 1: input layer of the cutoff design on the central preparation. Fits no model.
# Reads only central products (03_outputs/01_harmonized): cutoff/analytic.rds (36 eligible systems; actual grade D, assigned grade Z,
# running variable r, 10 plausible values, 80 replicate weights) and wellbeing_provider.rds (life satisfaction ST016Q01NA, sex from the
# sampling frame MALE, BULLIED, FEELSAFE, FAMSUP, HOMEPOS). The two are joined on the INTEGER student ID: the central ID is a zero-padded
# string, and a string join against anything that stores it as an integer silently loses ALB, AZE, BRA and BRN.
# Output (new file, never overwritten):  cutoff35_students.rds, cutoff35_coverage.csv  in $PAPER_OUT (default 04_output).
# Checks (stop on failure): every analytic student found in the wellbeing product; no duplicate IDs; the legacy 20-system file, used here
# ONLY as a cross-check and not as an input, agrees on D, Z, r and life satisfaction for every student it shares.
suppressPackageStartupMessages(library(data.table))
OUT <- Sys.getenv("PAPER_OUT", "05_papers/04_price_of_progress/04_output"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
f_rds <- file.path(OUT, "cutoff35_students.rds"); f_cov <- file.path(OUT, "cutoff35_coverage.csv")
if (file.exists(f_rds) || file.exists(f_cov)) stop("Refusing to overwrite ", f_rds, " / ", f_cov, "; set PAPER_OUT to a new directory.")
H <- "03_outputs/01_harmonized"

a <- as.data.table(readRDS(file.path(H, "cutoff/analytic.rds")))
w <- as.data.table(readRDS(file.path(H, "wellbeing_provider.rds")))
w <- as.data.table(lapply(w, function(v) if (is.character(v)) as.character(v) else as.numeric(v)))
a[, id := as.integer(CNTSTUID)]; w[, id := as.integer(CNTSTUID)]
stopifnot(!anyDuplicated(a$id), !anyDuplicated(w$id))
w <- w[, .(id, CNT_w = CNT, LS = ST016Q01NA, MALE, BULLIED, FEELSAFE, FAMSUP, HOMEPOS)]
a <- merge(a, w, by = "id", all.x = TRUE, sort = FALSE)
stopifnot(!anyNA(a$CNT_w), all(a$CNT == a$CNT_w)); a[, CNT_w := NULL]       # every student found, in the same system
a[, `:=`(LS10 = as.integer(LS == 10), LSle4 = as.integer(LS <= 4))]            # LS missing stays missing in both
a[, female_any := fifelse(!is.na(female), female, fifelse(MALE %in% c(0, 1), 1 - MALE, NA_real_))]  # sex also where ST004D01T is withheld
zw <- function(x, w) { k <- is.finite(x) & is.finite(w); m <- sum(x[k] * w[k]) / sum(w[k]); (x - m) / sqrt(sum(w[k] * (x[k] - m)^2) / sum(w[k])) }
a[, LS_z := zw(LS, W_FSTUWT), by = CNT]                                       # within-system weighted z-score, as in the earlier step 8

# cross-check against the legacy 20-system file (not an input)
leg <- "01_data/derived/skillsgain_analytic.rds"
if (file.exists(leg)) {
  l <- as.data.table(readRDS(leg))[, .(id = as.integer(CNTSTUID), D_l = D, Z_l = Z, r_l = r)]
  st <- fread("01_data/derived/resilwb_students.csv.gz", select = c("CNTSTUID", "ST016Q01NA")); setnames(st, c("id", "LS_l"))
  m <- merge(a[, .(id, D, Z, r, LS)], merge(l, st, by = "id", all.x = TRUE), by = "id")
  stopifnot(nrow(m) == nrow(l), all(m$D == m$D_l), all(m$Z == m$Z_l), all(abs(m$r - m$r_l) < 1e-12), identical(is.na(m$LS), is.na(m$LS_l)), all(m$LS == m$LS_l, na.rm = TRUE))
  cat("cross-check: ", nrow(m), " legacy students (", uniqueN(a[id %in% l$id, CNT]), " systems) agree on D, Z, r and life satisfaction\n", sep = "")
} else cat("NOT RUN: cross-check against the legacy file (not found)\n")

cov <- a[, .(N = .N, N_LS = sum(!is.na(LS)), share_LS = round(mean(!is.na(LS)), 3), share_D = round(mean(D), 3)), by = CNT][order(CNT)]
keep <- cov[share_LS >= 0.5, CNT]
cat("systems:", nrow(cov), " with life satisfaction (>= 50%):", length(keep), " students with the item in those:", a[CNT %in% keep, sum(!is.na(LS))], "\n")
cat("without the item:", paste(setdiff(cov$CNT, keep), collapse = " "), "\n")
a <- a[CNT %in% keep]
saveRDS(a, f_rds); fwrite(cov, f_cov)
cat("wrote", f_rds, "(", nrow(a), "students,", ncol(a), "columns )\n")
