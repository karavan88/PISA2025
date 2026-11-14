# Skills & the Grade Gain -- cross-system summaries and counterfactuals
# (1) Pools every per-system estimate (baseline, balance, heterogeneity, levels, mediation) over systems: equal-weight mean with its SE,
#     DerSimonian-Laird random-effects mean, between-system SD, I2, counts of significant systems. Sets: all 20; same-school (14: both grades
#     in the same schools -- the sample on which school SES is a valid moderator) vs transition (6); the two regional groups; leave-outs
#     (Costa Rica: SES = books; Cambodia: no scales, edge; Mauritius: two scales; Kenya: SES and SE jump at the cutoff; B-S-J-Z & Taipei:
#     the grade lowers self-reports).
# (2) Coefficient stability of the SE moderation (Altonji, Elder & Taber 2005): gamma_SE without SES moderators vs with them;
#     ratio = with / (without - with) -- how much stronger selection on unobserved moderators would have to be to remove gamma_SE.
# (3) Counterfactuals from the forest's doubly robust scores (Rubin over PVs, school-clustered SEs): the SES gap in the grade gain
#     (top minus bottom SES quartile), and what it would become (a) if every student's SE index rose by 1 SD, (b) if the bottom SES quartile
#     had the SE level of the top quartile. Parametric counterpart from the pooled interacted 2SLS ("inter").
# Output: 03_outputs/skillsgain/pool_*.csv, counterfactual.csv
suppressPackageStartupMessages({ library(data.table); library(sandwich) })
source("02_scripts/skillsgain/00_helpers.R")
STRONG <- fread(os("baseline.csv"))[sample == "all" & outcome == "ACH" & term == "fs" & est >= 0.4, CNT]   # weak first stages (UAE, Ecuador 0.2; Brazil, Kenya 0.3) leave out
st <- fread(os("structure.csv")); SAME <- st[structure == "Same-school", CNT]; TRANS <- st[structure == "Transition", CNT]
SETS <- list(`All 20` = SYS20, `Same-school (14)` = SAME, `Transition (6)` = TRANS, `Non-European (14)` = SYS_A, `European OECD (6)` = SYS_B,
             `Same-school, non-European` = intersect(SAME, SYS_A), `Same-school, European` = intersect(SAME, SYS_B),
             `Same-school without Costa Rica` = setdiff(SAME, "CRI"), `Same-school without Cambodia` = setdiff(SAME, "KHM"),
             `Same-school without Mauritius` = setdiff(SAME, "MUS"), `Same-school, first stage >= 0.4` = intersect(SAME, STRONG), `All without Kenya` = setdiff(SYS20, "KEN"), `All without B-S-J-Z & Taipei` = setdiff(SYS20, c("QCI", "TAP")))
pool_sets <- function(d, by) rbindlist(lapply(names(SETS), function(nm) d[CNT %in% SETS[[nm]], pool(est, se), by = by][, set := nm]))
het <- fread(os("het.csv")); lev <- fread(os("levels.csv")); base <- fread(os("baseline.csv")); bal <- fread(os("balance.csv")); med <- fread(os("mediation.csv"))
fwrite(pool_sets(het, c("spec", "sample", "outcome", "term")), os("pool_het.csv"))
fwrite(pool_sets(lev, c("outcome", "term")), os("pool_levels.csv"))
fwrite(pool_sets(base, c("sample", "outcome", "term")), os("pool_baseline.csv"))
fwrite(pool_sets(bal, c("var", "term")), os("pool_balance.csv"))
fwrite(pool_sets(med, c("mediator", "outcome", "term")), os("pool_mediation.csv"))

# (2) coefficient stability, per outcome
ph <- fread(os("pool_het.csv"))[set == "Same-school (14)"]
aet <- merge(ph[spec == "se" & term == "gamma:SE", .(outcome, without = re_mean)], ph[spec == "joint" & term == "gamma:SE", .(outcome, with = re_mean)], by = "outcome")
aet[, ratio := with / (without - with)]; aet[, set := "Same-school (14)"]
ses_share <- merge(ph[spec == "ses_sch_s" & term %in% c("gamma:SES", "gamma:schSES"), .(outcome, term, without_SE = re_mean)],
                   ph[spec == "joint" & term %in% c("gamma:SES", "gamma:schSES"), .(outcome, term, with_SE = re_mean)], by = c("outcome", "term"))
ses_share[, share_explained_by_SE := (without_SE - with_SE) / without_SE]; ses_share[, set := "Same-school (14)"]
fwrite(aet, os("stability.csv")); fwrite(ses_share, os("ses_explained_by_se.csv"))
print(aet); print(ses_share)

# (3) counterfactuals from the forest scores, per forest sample (same-school = headline; all 20 = comparison)
cf_all <- list()
for (smp in c("same", "all")) {
  fsf <- os(paste0("forest_scores_", smp, ".rds")); if (!file.exists(fsf)) next
  fs <- readRDS(fsf); d <- as.data.table(fs[c("CNT", "school", "w", "SE", "SES", "schSES", "SE_q", "SES_q")])
  d[, `:=`(SExSES = SE * SES, SExschSES = SE * schSES)]
  ok <- d[, complete.cases(SE, SES, schSES, SES_q)]
  q1 <- d[ok & SES_q == 1]; q4 <- d[ok & SES_q == 4]
  mq <- function(x, v) sum(x$w * x[[v]]) / sum(x$w)
  dSE <- mq(q4, "SE") - mq(q1, "SE"); dSES <- mq(q4, "SES") - mq(q1, "SES"); dsch <- mq(q4, "schSES") - mq(q1, "schSES"); q1SES <- mq(q1, "SES"); q1sch <- mq(q1, "schSES")
  cf <- rbindlist(lapply(seq_len(ncol(fs$scores)), function(k) {
    dd <- d[ok]; dd[, s := fs$scores[ok, k]]
    m <- lm(s ~ SE + SES + schSES + SExSES + SExschSES + factor(CNT), data = dd, weights = w); V <- vcovCL(m, cluster = ~school, type = "HC1"); b <- coef(m)
    L <- function(v) { l <- setNames(rep(0, length(b)), names(b)); l[names(v)] <- v; c(est = sum(l * b), se = sqrt(drop(t(l) %*% V %*% l))) }
    g <- lm(s ~ 0 + factor(SES_q), data = dd, weights = w); Vg <- vcovCL(g, cluster = ~school, type = "HC1"); bg <- coef(g)
    rbind(data.table(pv = k, quantity = "Grade gain, bottom SES quartile", est = unname(bg[1]), se = sqrt(Vg[1, 1])),
          data.table(pv = k, quantity = "Grade gain, top SES quartile", est = unname(bg[4]), se = sqrt(Vg[4, 4])),
          data.table(pv = k, quantity = "SES gap in the grade gain (top - bottom quartile)", est = unname(bg[4] - bg[1]), se = sqrt(Vg[1, 1] + Vg[4, 4] - 2 * Vg[1, 4])),
          data.table(pv = k, quantity = "(a) +1 SD SE for all: change in the average grade gain", t(L(c(SE = 1)))),
          data.table(pv = k, quantity = "(a) +1 SD SE for all: change in the SES gap", t(L(c(SExSES = dSES, SExschSES = dsch)))),
          data.table(pv = k, quantity = "(b) bottom quartile gets top-quartile SE: change in its grade gain", t(L(c(SE = dSE, SExSES = dSE * q1SES, SExschSES = dSE * q1sch)))),
          data.table(pv = k, quantity = "Part of the gap attributable to the SE difference between quartiles", t(L(c(SE = dSE)))))
  }))
  cf <- rubin(cf, "quantity"); cf[, `:=`(order = seq_len(.N), sample = smp)]
  gap <- cf[quantity %like% "^SES gap", est]; cf[, share_of_gap := fifelse(quantity %like% "^\\(b\\)|attributable", est / gap, NA_real_)]
  cf <- rbind(cf, data.table(quantity = c("SE gap between top and bottom SES quartile (SD)", "Student SES gap between quartiles (SD)", "School SES gap between quartiles (SD)"),
                             est = c(dSE, dSES, dsch), order = 97:99, sample = smp), fill = TRUE)
  cf_all[[smp]] <- cf
}
if (length(cf_all)) { cf <- rbindlist(cf_all, fill = TRUE); fwrite(cf, os("counterfactual.csv")); print(cf) }
