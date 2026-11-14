# Skills & the Grade Gain -- instrumental causal forest (grf): data-driven heterogeneity of the grade gain
# Target: gamma(x), the grade gain with school-starting age fixed. Within a system, y = a + b_D D + b_r r + ... and ssa = -r - 12 D, so the
#   age-adjusted outcome y_adj = y + b_r,s * ssa  satisfies  y_adj = a + gamma D + e : the IV of y_adj on D with instrument Z returns gamma.
#   b_r,s is the system's within-grade age slope from the baseline 2SLS (baseline.csv: b_r = (tau - gamma) / 12). The forest then needs no
#   running variable in X (Z is a function of r, so r in X would leave no instrument variation inside leaves).
# Forest: W = D (upper grade), Z = theoretical grade, Y = y_adj; X = self-management, open-mindedness, student SES, school SES, sex, immigrant,
#   home language, system indicators (so propensities and outcome means are system-specific). Missing X handled by grf (MIA splits).
#   Clusters = schools; sample weights = final student weights rescaled so every system has the same total (equal-weight pooling).
# Sample (env SAMPLE): "same" (default) = the 14 same-school systems, where school SES is not moved by the grade; "all" = 20 systems.
# One forest per plausible value of overall achievement (mean of the three domains); summaries combined over PVs by Rubin's rules.
# The compliance score (local first stage) is fitted once per forest and reused by every doubly robust summary.
# Outputs (suffix _same / _all): forest_ate (average grade gain, by group and structure), forest_blp (best linear projection of gamma(x) on
#   the moderators with system fixed effects), forest_gates (doubly robust means: SE quartile x SES quartile, margins, systems), forest_vi,
#   forest_scores.rds (DR scores per PV, for the counterfactuals in 07_pool.R)
# Env: NTREES (default 2000), NPV (default 5), NCORES (default 6)
suppressPackageStartupMessages({ library(data.table); library(grf); library(sandwich) })
source("02_scripts/skillsgain/00_helpers.R")
NTREES <- as.integer(Sys.getenv("NTREES", "2000")); NPV <- as.integer(Sys.getenv("NPV", "5")); NC <- as.integer(Sys.getenv("NCORES", "6"))
SAMPLE <- Sys.getenv("SAMPLE", "same"); sfx <- function(f) sub("\\.(csv|rds)$", paste0("_", SAMPLE, ".\\1"), f)
a <- load_sg()
st <- fread(os("structure.csv")); a <- merge(a, st[, .(CNT, structure)], by = "CNT")
if (SAMPLE == "same") a <- a[structure == "Same-school"]
base <- fread(os("baseline.csv"))[sample == "all" & outcome == "ACH"]
br <- dcast(base[term %in% c("gamma", "tau")], CNT ~ term, value.var = "est")[, .(CNT, b_r = (tau - gamma) / 12)]
a <- merge(a, br, by = "CNT")
a[, wn := W_FSTUWT / sum(W_FSTUWT) * 1e4, by = CNT]                         # equal total weight per system
a[, cl := as.integer(factor(school))]
sysd <- model.matrix(~ 0 + CNT, a); colnames(sysd) <- sub("^CNT", "sys_", colnames(sysd))
XV <- c("SE_task", "SE_open", "SES", "schSES", "female", "immigrant", "lang_other")
X <- cbind(as.matrix(a[, ..XV]), sysd)
A_cols <- c("SE", "SES", "schSES", "SExSES", "SExschSES")
blp_rows <- which(a[, complete.cases(SE, SES, schSES)])
A <- cbind(as.matrix(a[, ..A_cols]), sysd[, -1])[blp_rows, ]
cell <- a[, fifelse(!is.na(SE_q) & !is.na(SES_q), paste0("SE", SE_q, "_SES", SES_q), NA_character_)]

dr_means <- function(score, g, w, cl) {                                   # weighted means of DR scores by group, school-clustered SEs
  ok <- !is.na(g) & !grepl("NA", g); d <- data.table(s = score[ok], g = factor(g[ok]), w = w[ok], cl = cl[ok])
  m <- if (nlevels(d$g) > 1) lm(s ~ 0 + g, data = d, weights = w) else lm(s ~ 1, data = d, weights = w); v <- vcovCL(m, cluster = ~cl, type = "HC1")
  data.table(group = if (nlevels(d$g) > 1) sub("^g", "", names(coef(m))) else levels(d$g), est = unname(coef(m)), se = sqrt(diag(v)))
}
ate <- list(); blp <- list(); gates <- list(); vi <- list(); scores <- list()
for (k in seq_len(NPV)) {
  set.seed(20251000 + k)
  y <- a[[paste0("PV", k, "ACH")]] + a$b_r * a$ssa
  f <- instrumental_forest(X, y, a$D, a$Z, num.trees = NTREES, clusters = a$cl, sample.weights = a$wn, num.threads = NC)
  cf <- causal_forest(X, Y = f$W.orig, W = f$Z.orig, Y.hat = f$W.hat, W.hat = f$Z.hat, num.trees = 500, clusters = a$cl, sample.weights = a$wn, num.threads = NC)
  comp <- predict(cf)$predictions                                           # local first stage
  sc <- suppressWarnings(get_scores(f, compliance.score = comp))            # doubly robust scores of gamma(x)
  ate[[k]] <- rbind(data.table(pv = k, dr_means(sc, rep("All", nrow(a)), a$wn, a$cl)), data.table(pv = k, dr_means(sc, a$group, a$wn, a$cl)),
                    data.table(pv = k, dr_means(sc, a$structure, a$wn, a$cl)))
  b <- suppressWarnings(best_linear_projection(f, A, subset = blp_rows, compliance.score = comp))
  blp[[k]] <- data.table(pv = k, term = rownames(b), est = b[, 1], se = b[, 2])[term %in% c("(Intercept)", A_cols)]
  gates[[k]] <- rbind(data.table(pv = k, dim = "SE x SES", dr_means(sc, cell, a$wn, a$cl)),
                      data.table(pv = k, dim = "SE quartile", dr_means(sc, paste0("SE", a$SE_q), a$wn, a$cl)),
                      data.table(pv = k, dim = "SES quartile", dr_means(sc, paste0("SES", a$SES_q), a$wn, a$cl)),
                      data.table(pv = k, dim = "School SES quartile", dr_means(sc, paste0("schSES", a$schSES_q), a$wn, a$cl)),
                      data.table(pv = k, dim = "System", dr_means(sc, a$CNT, a$wn, a$cl)))
  vi[[k]] <- data.table(pv = k, var = colnames(X), vi = as.numeric(variable_importance(f)))
  scores[[k]] <- sc
  log_step("PV", k, "done; min local first stage", round(min(comp), 3), "; share < 0.05:", round(mean(comp < 0.05), 3))
}
ate <- rubin(rbindlist(ate), "group"); blp <- rubin(rbindlist(blp), "term"); gates <- rubin(rbindlist(gates), c("dim", "group"))
vi <- rbindlist(vi)[, .(vi = mean(vi)), by = var][order(-vi)]
fwrite(ate, os(sfx("forest_ate.csv"))); fwrite(blp, os(sfx("forest_blp.csv"))); fwrite(gates, os(sfx("forest_gates.csv"))); fwrite(vi, os(sfx("forest_vi.csv")))
saveRDS(list(id = a$CNTSTUID, CNT = a$CNT, group = a$group, structure = a$structure, school = a$cl, w = a$wn, SE = a$SE, SES = a$SES, schSES = a$schSES,
             SE_q = a$SE_q, SES_q = a$SES_q, scores = do.call(cbind, scores), settings = list(ntrees = NTREES, npv = NPV, sample = SAMPLE)), os(sfx("forest_scores.rds")))
print(ate); print(blp); print(gates[!dim %in% c("System", "SE x SES")]); print(head(vi, 12))
