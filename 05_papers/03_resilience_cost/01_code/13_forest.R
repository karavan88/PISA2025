# The Cost of Resilience -- step 13: does the gap vary? A causal forest in place of one interaction model per moderator.
# Step 5 enters each moderator in its own model, as a linear interaction, system by system. Here one forest (Athey, Tibshirani and
# Wager 2019, package grf) estimates how the gap between resilient students (R) and disadvantaged low achievers (PL) varies with all
# fourteen moderators at once, without a functional form. Being resilient is not a treatment: the forest describes a conditional gap.
# Design
#   sample   students in the bottom status quartile who are top or bottom achievers, skill index observed, in the systems of the
#            within-school gap model of step 4 (lad:sei); all systems stacked, final student weights rescaled to sum to one in each system
#   Y, W     standardised life satisfaction; indicator for resilient students
#   X        fourteen moderators (schoolmates' status and achievement, female, expects a degree, growth mindset, science self-efficacy,
#            sense of belonging, enjoyment of science, six skills), age and grade;
#            missing values are left to the forest (a scale not administered in a system)
#   fe       Y and W are centred within school (weighted), so the gap is identified within schools as in steps 4 and 5   [main]
#            The nuisance forests for E[Y|X] and E[W|X] also receive the within-school deviations of X: Y and W vary only within
#            schools, and adjusting them for X in levels alone under-adjusts (the first run of 15 November 2026 gave an average gap
#            of -0.06 where the fixed-effects regression gives about -0.19).
#   nofe     Y and W as they are                                                                                          [check]
#   inference: school-clustered forest and school-clustered standard errors (HC1). The 80 replicate weights cannot be used with a forest.
#            Groups depend on the plausible value, so everything is computed once per plausible value and combined with Rubin's rules.
# Quantities (block: term). ry = Y - E[Y|X], rw = W - E[W|X] (out-of-bag residuals).
#   ate: gap                  coefficient of ry on rw: the average gap after flexible adjustment for X
#   calib: mean, differential omnibus calibration test (Chernozhukov et al. 2025); differential > 0 means the forest found variation in the gap
#   blp: gap, <moderator>     ry on rw and rw x moderator, all fourteen moderators in one model (moderators centred; systems lacking one drop out)
#   blp_common: ...           the same with the moderators measured in every system
#   level: <moderator>:<k>    gap (ry on rw) in fifth k of a continuous moderator, or at 0 and 1 of an indicator; levelx: mean of the moderator there
#   vimp: <variable>          share of forest splits on the variable (depth-weighted)
#   tau: p10 ... p90          distribution of the out-of-bag conditional gap
#   ols0, ols, ols_common     the linear counterpart on the same stacked sample: school fixed effects, all interactions in one model
# Output: forest_pv.csv (per plausible value), forest_est.csv (combined), forest_info.csv
source("05_papers/03_resilience_cost/01_code/00_helpers.R")
suppressPackageStartupMessages({ library(grf); library(sandwich); library(fixest) })
# NT: trees of the causal forest (calibration test, split shares, distribution of the conditional gap). NTN: trees of the two nuisance forests,
# on which the average gap, the projections and the gaps by level rest. Results depend on the seed and the number of threads.
NT <- as.integer(Sys.getenv("FOREST_TREES", "1000")); NTN <- 1000L; THREADS <- 7L; SEED <- 20261115L
PVS <- if (nzchar(Sys.getenv("PAPER_TEST_PVS"))) as.integer(strsplit(Sys.getenv("PAPER_TEST_PVS"), " ")[[1]]) else 1:10                    # testing only
d <- load_rw()
d[, `:=`(g_m1 = as.integer(GRADE < 0), g_p1 = as.integer(GRADE > 0), uni = as.integer(EXPECEDU >= 7), sch = paste(CNT, CNTSCHID))]
SYS0 <- if (nzchar(Sys.getenv("PAPER_TEST_SYSTEMS"))) strsplit(Sys.getenv("PAPER_TEST_SYSTEMS"), " ")[[1]] else fread(orr("gap_sys.csv"))[term == "lad:sei" & !is.na(est), CNT]
MODS <- c(schESCS = "schESCS_loo_z", schACH = "schACH", female = "female", uni = "uni", growth = "growth", EFFSCIE = "EFFSCIE_z", BELONG = "BELONG_z", JOYSCIE = "JOYSCIE_z",
          PERSEV = "PERSEV_z", GOALSET = "GOALSET_z", COGABIL = "COGABIL_z", ENPROBS = "ENPROBS_z", SELFREG = "SELFREG_z", CURIO = "CURIO_z")
CTRL <- c("AGE", "g_m1", "g_p1"); BIN <- c("female", "uni", "growth"); # COMMON: the characteristics observed for more than half of the students of every system (set after the data are loaded)
SYS <- SYS0
COMMON <- { cv <- d[CNT %in% SYS & sesq == 1, lapply(.SD, function(x) mean(!is.na(x))), by = CNT, .SDcols = setdiff(MODS, "schACH")]
  ok <- vapply(setdiff(MODS, "schACH"), function(v) all(cv[[v]] > .5), logical(1)); c(names(MODS)[match(names(ok)[ok], MODS)], "schACH") }
COMMON <- names(MODS)[names(MODS) %in% COMMON]        # in the order of MODS
loo_mean <- function(v, g, w) {                       # weighted leave-one-out group mean, as in step 5
  ok <- !is.na(v) & !is.na(w); sw <- ave(ifelse(ok, w, 0), g, FUN = sum); swx <- ave(ifelse(ok, w * v, 0), g, FUN = sum)
  r <- (swx - ifelse(ok, w * v, 0)) / (sw - ifelse(ok, w, 0)); r[!is.finite(r)] <- NA; r
}
build <- function(p) {                                # analysis sample for plausible value p
  a <- d[CNT %in% SYS, c("CNT", "sch", "w", "LS_z", "SEI", "sesq", setdiff(MODS, "schACH"), CTRL, ACH[p]), with = FALSE]; setnames(a, ACH[p], "ach")
  a[, c("top", "low", "schACH") := { q <- wquant(ach, w, c(.25, .75)); list(as.integer(ach >= q[2]), as.integer(ach <= q[1]), loo_mean((ach - wmean(ach, w)) / wsd(ach, w), sch, w)) }, by = CNT]
  a <- a[sesq == 1 & (top == 1 | low == 1) & !is.na(LS_z) & !is.na(SEI)]
  a[, sw := w / sum(w), by = CNT][, `:=`(Yc = LS_z - sum(w * LS_z) / sum(w), Wc = top - sum(w * top) / sum(w)), by = sch]
  setnames(a, MODS, names(MODS))
  for (v in c(names(MODS), CTRL)) a[, (paste0(v, "_w")) := { x <- get(v); ok <- !is.na(x); r <- x - sum(w[ok] * x[ok]) / sum(w[ok]); r[!is.finite(r)] <- NA; r }, by = sch]   # within-school deviations
  a
}
crse <- function(fm, cl) data.table(term = names(coef(fm)), est = unname(coef(fm)), se = sqrt(diag(sandwich::vcovCL(fm, cluster = cl, type = "HC1"))))
tab <- function(x, block, n) x[, `:=`(block = block, n = n)][]

one <- function(a, fe) {
  V <- c(names(MODS), CTRL); X <- as.matrix(a[, ..V]); cl <- as.integer(factor(a$sch)); sw <- a$sw; N <- nrow(a); out <- list()
  Y <- if (fe) a$Yc else a$LS_z; W <- if (fe) a$Wc else a$top
  XN <- if (fe) cbind(X, as.matrix(a[, paste0(V, "_w"), with = FALSE])) else X
  nuis <- function(v) predict(regression_forest(XN, v, sample.weights = sw, clusters = cl, num.trees = NTN, seed = SEED, num.threads = THREADS))$predictions   # out-of-bag
  m <- nuis(Y); e <- nuis(W); ry <- Y - m; rw <- W - e
  cf <- causal_forest(X, Y, W, Y.hat = m, W.hat = e, sample.weights = sw, clusters = cl, num.trees = NT, seed = SEED, num.threads = THREADS)
  tau <- predict(cf)$predictions
  fit <- function(Z, ok = rep(TRUE, N)) { colnames(Z) <- make.names(colnames(Z)); df <- data.frame(ry = ry, Z, sw = sw)[ok, , drop = FALSE]
    crse(lm(reformulate(colnames(Z), "ry", intercept = FALSE), df, weights = sw), cl[ok]) }
  out$ate <- tab(fit(cbind(gap = rw)), "ate", N)
  tc <- test_calibration(cf); out$calib <- tab(data.table(term = c("mean", "differential"), est = tc[, 1], se = tc[, 2]), "calib", N)
  for (k in c("blp", "blp_common")) { v <- if (k == "blp") names(MODS) else COMMON; cc <- complete.cases(X[, v])
    A <- sweep(X[, v, drop = FALSE], 2, colSums(X[cc, v, drop = FALSE] * sw[cc]) / sum(sw[cc])); out[[k]] <- tab(fit(cbind(gap = rw, rw * A), cc), k, sum(cc)) }
  out$level <- rbindlist(lapply(names(MODS), function(mm) { x <- X[, mm]; ok <- !is.na(x)
    b <- rep(NA_integer_, N); b[ok] <- if (mm %in% BIN) as.integer(x[ok]) else 1L + findInterval(x[ok], wquant(x[ok], sw[ok], c(.2, .4, .6, .8)), left.open = TRUE)
    lev <- sort(unique(b[ok])); Z <- sapply(lev, function(l) ifelse(ok & b == l, rw, 0)); colnames(Z) <- paste0("b", lev)
    r <- fit(Z, ok)[, term := paste0(mm, ":", lev)]
    mx <- data.table(b = b[ok], x = x[ok], w = sw[ok])[, .(est = sum(x * w) / sum(w)), keyby = b]
    rbind(tab(r, "level", sum(ok)), tab(data.table(term = paste0(mm, ":", mx$b), est = mx$est, se = NA_real_), "levelx", sum(ok))) }))
  out$vimp <- tab(data.table(term = colnames(X), est = as.vector(variable_importance(cf)), se = NA_real_), "vimp", N)
  out$tau <- tab(data.table(term = paste0("p", c(10, 25, 50, 75, 90)), est = wquant(tau, sw, c(.1, .25, .5, .75, .9)), se = NA_real_), "tau", N)
  rbindlist(out, use.names = TRUE)
}
ols <- function(a) {                                  # linear counterpart: school fixed effects, school-clustered standard errors
  f <- function(v, k) { fm <- if (is.null(v)) feols(as.formula(paste("LS_z ~ top +", paste(c(COMMON, CTRL), collapse = " + "), "| sch")), a, weights = ~sw, cluster = ~sch, notes = FALSE)
      else feols(as.formula(paste("LS_z ~ top * (", paste(v, collapse = " + "), ") +", paste(CTRL, collapse = " + "), "| sch")), a, weights = ~sw, cluster = ~sch, notes = FALSE)
    ct <- as.data.table(coeftable(fm), keep.rownames = "term")[grepl("^top", term), .(term = sub("^top:", "", term), est = Estimate, se = `Std. Error`)]; tab(ct[term == "top", term := "gap"], k, nobs(fm)) }
  rbind(f(NULL, "ols0"), f(names(MODS), "ols"), f(COMMON, "ols_common"))
}

log_step("causal forest:", length(SYS), "systems,", length(PVS), "plausible values,", NT, "trees,", THREADS, "threads, grf", as.character(packageVersion("grf")))
res <- list(); info <- list()
for (p in PVS) {
  a <- build(p); info[[length(info) + 1]] <- data.table(pv = p, n = nrow(a), n_R = sum(a$top), n_sys = uniqueN(a$CNT), n_sch = uniqueN(a$sch), n_sch_both = a[, .(b = uniqueN(top) == 2), by = sch][, sum(b)])
  for (fe in c(TRUE, FALSE)) { r <- one(a, fe)[, `:=`(pv = p, model = if (fe) "fe" else "nofe")]; res[[length(res) + 1]] <- r
    log_step("PV", p, if (fe) "fe" else "nofe", "n =", nrow(a), " gap =", round(r[block == "ate" & term == "gap", est], 3), " differential =", round(r[block == "calib" & term == "differential", est], 2)) }
  res[[length(res) + 1]] <- ols(a)[, `:=`(pv = p, model = "fe")]
}
res <- rbindlist(res, use.names = TRUE); info <- rbindlist(info)
fwrite(res[, .(pv, model, block, term, est, se, n)], orr("forest_pv.csv"))
est <- res[, { M <- .N; v <- mean(se^2) + if (M > 1) (1 + 1 / M) * var(est) else 0; .(est = mean(est), se = sqrt(v), n = mean(n), n_pv = M) }, by = .(model, block, term)]
fwrite(est, orr("forest_est.csv"))
fwrite(cbind(info, trees = NT, threads = THREADS, seed = SEED, grf = as.character(packageVersion("grf"))), orr("forest_info.csv"))
log_step("done")
print(est[block %in% c("ate", "calib", "blp", "blp_common", "ols0", "ols", "ols_common", "tau"), .(model, block, term, est = round(est, 3), se = round(se, 3), z = round(est / se, 2), n = round(n))], nrows = 200)
print(dcast(est[block == "level" & model == "fe"][, c("m", "k") := tstrsplit(term, ":")], m ~ k, value.var = "est")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 3) else x)])
print(est[block == "vimp" & model == "fe", .(term, share = round(est, 3))][order(-share)])
