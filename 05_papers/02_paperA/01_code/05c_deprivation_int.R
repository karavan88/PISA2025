# Paper A -- H2c interactions: skill x material deprivation (dep4_any), at fixed ESCS
source("02_scripts/paperA/00_helpers.R")
a <- load_analytic()
a[, private := ifelse(is.na(private), 0, private)]; a[, urban := ifelse(is.na(urban), 1, urban)]
a[, sch_escs_loo := ifelse(is.na(sch_escs_loo), ESCS, sch_escs_loo)]; a[, urban_f := factor(urban)]
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- levels(a$bloc); ord <- c(econ$economy, blocs, ALL_LAB)
senate <- function(d) { d <- copy(d); d[, W_FSTUWT := w_senate]; for (r in RW) d[, (r) := get(r) / sum(get(r)) * 5000, by = CNT]; d }
fit_spec <- function(dt, rhs, label) { X <- model.matrix(as.formula(paste("~", rhs)), dt); X <- X[, colnames(X) == "(Intercept)" | apply(X, 2, sd) > 0, drop = FALSE]
  res <- pisa_est(dt, function(d, y, w) wls(X, y, w)); res[, unit := label]; res[, N := nrow(dt)]; res }
ctrl <- function(fe) paste(c("ESCS", controls, "sch_escs_loo", "private", "urban_f", fe), collapse = "+")
a3 <- a[!is.na(dep4_any)]
out <- list()
for (c in levels(droplevels(a3$CNT))) { d <- a3[CNT == c]; sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV"); cat(c, " ")
  out[[c]] <- fit_spec(d, paste(ctrl(NULL), "+ dep4_any +", paste(sk, collapse = "+"), "+", paste0("dep4_any:", sk, collapse = "+")), as.character(d$economy[1])) }
for (b in blocs) { d <- senate(a3[bloc == b]); d[, CNT := droplevels(CNT)]; sk <- if (all(d$persev_fielded)) skills else setdiff(skills, "PERSEV"); cat(b, " ")
  out[[b]] <- fit_spec(d, paste(ctrl("CNT"), "+ dep4_any +", paste(sk, collapse = "+"), "+", paste0("dep4_any:", sk, collapse = "+")), b) }
d <- senate(a3); sk <- setdiff(skills, "PERSEV")
out[["all"]] <- fit_spec(d, paste(ctrl("CNT"), "+ dep4_any +", paste(sk, collapse = "+"), "+", paste0("dep4_any:", sk, collapse = "+")), ALL_LAB)
R <- rbindlist(out); fwrite(R, tp("h2c_deprivation_int_long.csv"))
skl <- function(t) { m <- regexpr(paste(skills, collapse = "|"), t); out <- rep(NA_character_, length(t)); out[m > 0] <- skill_lab[regmatches(t, m)]; out }
di <- R[grepl("dep4_any:", term), .(unit, term = paste0("Skill x deprived: ", skl(term)), est = round(est, 2), se = round(se, 2))]
di[, unit := factor(unit, levels = ord)]; setorder(di, unit)
dep <- fread(tp("h2c_deprivation.csv"))[!grepl("Skill x", term)]
dep <- rbind(dep[, .(unit, term, est = round(est, 2), se = round(se, 2))], di); fwrite(dep, tp("h2c_deprivation.csv"))
options(width = 200); print(dep[unit %in% c(blocs, ALL_LAB)])
cat("\ndone dep int\n")
