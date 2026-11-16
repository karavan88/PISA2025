# The Cost of Resilience -- step 18: descriptive statistics and variable availability by system (Table 1 and Appendix Table A1).
# Fits no model. One row per system and variable for the systems in the models of step 17 (read from this run's mxmod_sys.csv):
#   mean, sd     weighted with the final student weight, over students with the variable observed; reading and science are averaged
#                over the ten plausible values; scales are the PISA indices as published (not standardised within system)
#   obs          share of the system's students with the variable observed (0 = not fielded)
#   n_obs        students with the variable observed
# Variables: life satisfaction (0-10) and the share answering 10; reading and science scores; the status index; female; age; below
# the modal grade; the six socio-emotional skills; growth mindset; science self-efficacy and enjoyment of science; belonging,
# bullying, family support, feeling safe; school identifier (obs only). Rows var = "n_model" and "n:S#A#" carry the model sample
# of step 17 (mean over plausible values).
# Runs after step 17. Output: desc_sys.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
SYS <- unique(fread(orr("mxmod_sys.csv"))$CNT)
d <- readRDS(DERIV)[CNT %in% SYS]
ex <- fread(STUDENTS, select = c("CNTSTUID", PV("READ"), PV("SCIE"), "EFFSCIE"))
i <- match(d$CNTSTUID, ex$CNTSTUID); stopifnot(!anyNA(i))
d[, `:=`(READ = rowMeans(as.matrix(ex[i, PV("READ"), with = FALSE])), SCIE = rowMeans(as.matrix(ex[i, PV("SCIE"), with = FALSE])),
         EFFSCIE = ex$EFFSCIE[i], below_grade = as.integer(GRADE < 0), LS10 = as.numeric(LS10))]
VARS <- c("LS", "LS10", "READ", "SCIE", "ESCS", "female", "AGE", "below_grade", SE6, "growth", "EFFSCIE", "JOYSCIE", CTX)
wsd0 <- function(x, w) { k <- !is.na(x); if (sum(k) < 2) NA_real_ else wsd(x[k], w[k]) }
res <- rbindlist(lapply(VARS, function(v) d[, .(var = v, mean = if (any(!is.na(get(v)))) wmean(get(v), w) else NA_real_, sd = wsd0(get(v), w),
                                                obs = mean(!is.na(get(v))), n_obs = sum(!is.na(get(v)))), by = CNT]))
res <- rbind(res, d[, .(var = "school_id", mean = NA_real_, sd = NA_real_, obs = mean(!is.na(CNTSCHID)), n_obs = sum(!is.na(CNTSCHID))), by = CNT],
             d[, .(var = "n_students", mean = .N, sd = NA_real_, obs = 1, n_obs = .N), by = CNT])
mm <- fread(orr("mxmod_sys.csv"))[grepl("^n:", term), .(CNT, var = term, mean = est, sd = NA_real_, obs = NA_real_, n_obs = NA_real_)]
res <- rbind(res, mm, mm[, .(var = "n_model", mean = sum(mean), sd = NA_real_, obs = NA_real_, n_obs = NA_real_), by = CNT])
setorder(res, CNT, var)
fwrite(res, orr("desc_sys.csv"))
log_step("descriptives for", uniqueN(res$CNT), "systems,", length(VARS), "variables")
print(res[var %in% VARS, .(mean_of_systems = round(mean(mean, na.rm = TRUE), 3), systems_fielded = sum(obs > .5)), by = var])
