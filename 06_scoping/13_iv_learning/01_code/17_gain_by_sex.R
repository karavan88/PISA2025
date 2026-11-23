# IV learning -- step 17: does a year add the same for girls and boys? Follow-up to the forest of step 16, which used sex among its most
# frequent splits. Main estimator (replicate weights, plausible values): the gain interacted with female, instrumented by the
# instrument times female; alone, with curiosity (the forest's most used variable) and with SES alongside; combined achievement and
# each domain. Systems that withhold sex (Chile, Germany, New Zealand in the central file) are left out.
# Reads central products only. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/17_gain_by_sex.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
a <- as.data.table(readRDS(ANALYTIC))[!CNT %in% EXCLUDE]
rules <- fread(RULES)
stopifnot(setequal(unique(a$CNT), rules[pisa_eligible == TRUE & !CNT %in% EXCLUDE, CNT]))
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
has <- function(s, v) all(vapply(v, function(x) mean(!is.na(s[[x]])) >= .5, logical(1)))
SYS <- a[, .(ok = mean(!is.na(female)) >= .5), by = CNT][ok == TRUE, sort(CNT)]
log_step("gain by sex on", length(SYS), "systems; without sex:", paste(setdiff(sort(unique(a$CNT)), SYS), collapse = " "))
SPECS <- list(sex = "female", sex_curiosity = c("female", "CURIO_z"), sex_ses = c("female", "ESCS_z"))
res <- parallel::mclapply(SYS, function(cn) { s <- a[CNT == cn]
  rbindlist(lapply(names(SPECS), function(sp) if (has(s, SPECS[[sp]])) rbindlist(lapply(c("ACH", "MATH", "READ", "SCIE"), function(o) if (sp == "sex" || o == "ACH")
    data.table(CNT = cn, spec = sp, outcome = o, pisa_est(s, function(dt, y, w) grade_gain(dt, y, w, mods = SPECS[[sp]]), PV(o))))))) }, mc.cores = 6)
g <- rbindlist(res); g[, flagged := CNT %in% FLAG]; fwrite(g, paste0(OUT, "gain_by_sex_sys.csv"))
k <- g[term != "n" & is.finite(est) & is.finite(se) & se > 0]; by <- c("spec", "outcome", "term")
pl <- rbind(k[, pool(est, se), by = by][, set := "all (Ukraine out)"], k[flagged == FALSE, pool(est, se), by = by][, set := "without Israel"])
fwrite(pl, paste0(OUT, "gain_by_sex_pool.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "17_gain_by_sex", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, excluded = EXCLUDE, flagged = FLAG, md5 = as.list(tools::md5sum(c(ANALYTIC, RULES, code)))), paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 200); P <- pl[set == "all (Ukraine out)"]
print(P[term %in% c("gamma", "tau", "gamma:female", "tau:female", "main:female", "age:female", "gamma:CURIO_z", "tau:CURIO_z")][order(spec, outcome, term),
  .(spec, outcome, term, n_sys, median = round(median, 2), re = round(re_mean, 2), se = round(re_se, 2), z = round(re_mean / re_se, 2), sd_across = round(tau_sd, 2), pos_05, pos_10, neg_05, neg_10)], nrows = 60)
log_step("done"); sink()
