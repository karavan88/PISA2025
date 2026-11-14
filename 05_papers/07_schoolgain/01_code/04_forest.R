# School Inputs & the Grade Gain -- instrumental causal forest, same-school systems
# Target gamma(x): the grade gain with school-starting age fixed (age-adjusted outcome y + b_r,s * ssa, see 02_scripts/skillsgain/05_forest.R).
# X = all school inputs and peer variables + student controls (decomposed ESCS, books, sex, immigrant, curiosity, perseverance, problem-solving
#     enjoyment) + system indicators; missing X handled by grf. Clusters = schools; equal total weight per system.
# Per plausible value of overall achievement:
#   * doubly robust scores; average gain; best linear projection of gamma(x) on ALL school inputs jointly with system fixed effects
#     (missing inputs set to the system mean, with flags) -> which inputs carry the heterogeneity, holding the others fixed
#   * GATES: average gain by within-system quartile of every input
#   * RATE (AUTOC): (a) does the forest's own CATE ranking find real heterogeneity? honest 50/50 split by school: a forest trained on half
#     the schools ranks the other half, whose own forest evaluates the ranking; (b) does ranking schools by each single input target larger gains?
#   * variable importance
# Rubin over PVs. Env: NTREES (2000), NPV (5), NCORES (6).
# Output: forest_{ate,blp,gates,rate,vi}.csv, forest_scores.rds (03_outputs/schoolgain/)
suppressPackageStartupMessages({ library(data.table); library(grf); library(sandwich) })
source("02_scripts/schoolgain/00_helpers.R")
NTREES <- as.integer(Sys.getenv("NTREES", "2000")); NPV <- as.integer(Sys.getenv("NPV", "5")); NC <- as.integer(Sys.getenv("NCORES", "6"))
a <- load_sch()[structure == "Same-school"]
base <- fread("03_outputs/skillsgain/baseline.csv")[sample == "all" & outcome == "ACH"]
br <- dcast(base[term %in% c("gamma", "tau")], CNT ~ term, value.var = "est")[, .(CNT, b_r = (tau - gamma) / 12)]
a <- merge(a, br, by = "CNT")
a[, wn := W_FSTUWT / sum(W_FSTUWT) * 1e4, by = CNT]; a[, cl := as.integer(factor(school))]
sysd <- model.matrix(~ 0 + CNT, a); colnames(sysd) <- sub("^CNT", "sys_", colnames(sysd))
for (v in c("HISEI", "PAREDINT", "HOMEPOS")) a[, paste0(v, "_f") := zw(as.numeric(get(v)), W_FSTUWT), by = CNT]   # un-imputed: grf handles NA
XS <- c("HISEI_f", "PAREDINT_f", "HOMEPOS_f", "books_z", "female", "immigrant", SKILL3)
Xr <- as.matrix(a[, c(INPUTS$var, XS), with = FALSE])
X <- cbind(Xr, sysd)
A <- as.matrix(a[, INPUTS$var, with = FALSE]); mis <- is.na(A); A[mis] <- 0
flags <- mis[, colMeans(mis) > 0.02, drop = FALSE]; colnames(flags) <- paste0("mis_", colnames(flags))
A <- cbind(A, flags, sysd[, -1])

dr_means <- function(score, g, w, cl) {
  ok <- !is.na(g) & !grepl("NA", g); d <- data.table(s = score[ok], g = factor(g[ok]), w = w[ok], cl = cl[ok])
  m <- if (nlevels(d$g) > 1) lm(s ~ 0 + g, data = d, weights = w) else lm(s ~ 1, data = d, weights = w); v <- vcovCL(m, cluster = ~cl, type = "HC1")
  data.table(group = if (nlevels(d$g) > 1) sub("^g", "", names(coef(m))) else levels(d$g), est = unname(coef(m)), se = sqrt(diag(v)))
}
wq <- function(x, w, k = 4) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); q <- rep(NA_integer_, length(x)); q[which(ok)[o]] <- pmin(k, floor(cw * k - 1e-9) + 1L); q }
Q <- a[, lapply(.SD, function(x) wq(x, W_FSTUWT)), by = CNT, .SDcols = INPUTS$var]
comp_score <- function(f) predict(causal_forest(f$X.orig, Y = f$W.orig, W = f$Z.orig, Y.hat = f$W.hat, W.hat = f$Z.hat, num.trees = 500, clusters = f$clusters,
                                                sample.weights = f$sample.weights, num.threads = NC))$predictions
ate <- list(); blp <- list(); gates <- list(); rate <- list(); vi <- list(); scores <- list()
schools <- unique(a$cl)
for (k in seq_len(NPV)) {
  set.seed(20252000 + k)
  y <- a[[paste0("PV", k, "ACH")]] + a$b_r * a$ssa
  f <- instrumental_forest(X, y, a$D, a$Z, num.trees = NTREES, clusters = a$cl, sample.weights = a$wn, num.threads = NC)
  comp <- comp_score(f); sc <- suppressWarnings(get_scores(f, compliance.score = comp))
  ate[[k]] <- rbind(data.table(pv = k, dr_means(sc, rep("All", nrow(a)), a$wn, a$cl)), data.table(pv = k, dr_means(sc, a$group, a$wn, a$cl)))
  b <- suppressWarnings(best_linear_projection(f, A, compliance.score = comp))
  blp[[k]] <- data.table(pv = k, term = rownames(b), est = b[, 1], se = b[, 2])[term %in% c("(Intercept)", INPUTS$var)]
  gates[[k]] <- rbindlist(lapply(INPUTS$var, function(v) data.table(pv = k, input = v, dr_means(sc, ifelse(is.na(Q[[v]]), NA, paste0("q", Q[[v]])), a$wn, a$cl))))
  # RATE (a): honest split by school
  tr <- a$cl %in% sample(schools, length(schools) %/% 2); ev <- !tr
  f_tr <- instrumental_forest(X[tr, ], y[tr], a$D[tr], a$Z[tr], num.trees = NTREES %/% 2, clusters = a$cl[tr], sample.weights = a$wn[tr], num.threads = NC)
  f_ev <- instrumental_forest(X[ev, ], y[ev], a$D[ev], a$Z[ev], num.trees = NTREES %/% 2, clusters = a$cl[ev], sample.weights = a$wn[ev], num.threads = NC)
  pri <- predict(f_tr, X[ev, ])$predictions
  r1 <- suppressWarnings(rank_average_treatment_effect(f_ev, pri, target = "AUTOC", compliance.score = comp_score(f_ev)))
  rr <- list(data.table(pv = k, priority = "Forest CATE (honest split)", est = r1$estimate, se = r1$std.err))
  # RATE (b): single inputs as priorities, on the full forest (priorities are not learned from the outcome)
  for (v in INPUTS$var) { ok <- which(!is.na(a[[v]]))
    r2 <- try(suppressWarnings(rank_average_treatment_effect(f, a[[v]][ok], target = "AUTOC", subset = ok, compliance.score = comp)), silent = TRUE)
    if (!inherits(r2, "try-error")) rr[[length(rr) + 1]] <- data.table(pv = k, priority = v, est = r2$estimate, se = r2$std.err) }
  rate[[k]] <- rbindlist(rr)
  vi[[k]] <- data.table(pv = k, var = colnames(X), vi = as.numeric(variable_importance(f)))
  scores[[k]] <- sc
  log_step("PV", k, "done; RATE(CATE) =", round(r1$estimate, 2), "(", round(r1$std.err, 2), ")")
}
ate <- rubin(rbindlist(ate), "group"); blp <- rubin(rbindlist(blp), "term"); gates <- rubin(rbindlist(gates), c("input", "group"))
rate <- rubin(rbindlist(rate), "priority"); vi <- rbindlist(vi)[, .(vi = mean(vi)), by = var][order(-vi)]
fwrite(ate, og("forest_ate.csv")); fwrite(blp, og("forest_blp.csv")); fwrite(gates, og("forest_gates.csv")); fwrite(rate, og("forest_rate.csv")); fwrite(vi, og("forest_vi.csv"))
saveRDS(list(CNT = a$CNT, school = a$cl, w = a$wn, inputs = as.matrix(a[, INPUTS$var, with = FALSE]), scores = do.call(cbind, scores), settings = list(ntrees = NTREES, npv = NPV)), og("forest_scores.rds"))
print(ate); print(blp[order(-abs(est / se))]); print(rate[order(-abs(est / se))]); print(head(vi, 15))
