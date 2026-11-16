# The Cost of Resilience -- step 15: pooled estimates by world region. Reads the per-system estimates of steps 3, 4 and 12 from this
# run's output directory and pools them within each region (DerSimonian-Laird random effects, as for all systems). Fits no new model.
#   gap:   lad:demo, lad:sei (resilient students vs disadvantaged low achievers, within school)
#   bench: cell:R:demo, cell:PL:demo, cell:AL:demo, cell:R:sei (each group vs advantaged top achievers, within school)
#   rs:    thr:LS10 (share answering 10, skills held fixed)
#   mxmod: mm:z:M3:S1A4, mm:z:M3:R-PL, mm:z:M3:R-AL, mm:z:M5:S1A4, mm:z:M5:R-PL (step 17: resilient students against advantaged top
#          achievers, and minus disadvantaged / advantaged low achievers; school fixed effects with demographics, and with every control)
# Runs after step 17 (run_all.sh). Output: region_pool.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R"); source("05_papers/03_resilience_cost/01_code/regions.R")
TERMS <- list(gap_sys.csv = c("lad:demo", "lad:sei"), bench_sys.csv = c("cell:R:demo", "cell:PL:demo", "cell:AL:demo", "cell:R:sei"), rs_sys.csv = "thr:LS10",
              mxmod_sys.csv = c("mm:z:M3:S1A4", "mm:z:M3:R-PL", "mm:z:M3:R-AL", "mm:z:M5:S1A4", "mm:z:M5:R-PL"))
x <- rbindlist(lapply(names(TERMS), function(f) fread(orr(f))[term %in% TERMS[[f]] & !is.na(est) & !is.na(se) & se > 0, .(file = sub("_sys.csv", "", f), term, CNT, est, se)]))
miss <- setdiff(unique(x$CNT), REGION_OF$CNT); if (length(miss)) stop("systems without a region: ", paste(miss, collapse = " "))
x <- merge(x, REGION_OF, by = "CNT")
pl <- rbind(pool_by(x, c("file", "term", "region")), pool_by(x, c("file", "term"))[, region := "All systems"], fill = TRUE)
fwrite(pl, orr("region_pool.csv"))
log_step("done:", uniqueN(x$CNT), "systems in", uniqueN(x$region), "regions")
print(pl[, .(file, term, region, n_sys, re = round(re_mean, 3), se = round(re_se, 3), z = round(re_mean / re_se, 1), n_neg, sig_neg)], nrows = 100)
