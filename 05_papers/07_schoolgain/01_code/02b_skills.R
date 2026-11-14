# School Inputs & the Grade Gain -- choice of the skill controls: cross-sectional association of each of the six PISA 2025 socio-emotional
# scales with overall achievement (WLS per system on the scale + student SES + grade + birth month + sex; BRR + Rubin), pooled by random
# effects over the 20 study systems. The three strongest enter every model as controls (CURIO, PERSEV, ENPROBS).
# Output: 03_outputs/schoolgain/skills_levels.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
a <- load_sg(); r <- list()
for (cn in SYS20) { s <- a[CNT == cn]
  for (sc in SE6) { if (mean(!is.na(s[[sc]])) < .5) next
    X <- cbind(1, s[[sc]], s$SES, s$D, s$r, s$female); X <- X[, colMeans(!is.na(X)) > .5]
    e <- pisa_est(s, function(dt, y, w) c(b = unname(wls(X, y, w)[2])), PV("ACH")); r[[length(r) + 1]] <- data.table(CNT = cn, scale = sc, est = e$est, se = e$se) } }
r <- rbindlist(r); p <- r[, pool(est, se), by = scale][order(-re_mean)]
fwrite(p, og("skills_levels.csv")); print(p[, .(scale, n_sys, re = round(re_mean, 1), se = round(re_se, 1))])
