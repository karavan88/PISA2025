# Paper A -- descriptives (Table 1, skill means, correlations, Figure 1)
source("02_scripts/paperA/00_helpers.R"); suppressPackageStartupMessages({library(ggplot2)})
a <- load_analytic()
theme_set(theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom"))

wmean <- function(x, w) sum(w * x, na.rm = TRUE) / sum(w[!is.na(x)])
wsd   <- function(x, w) { m <- wmean(x, w); sqrt(sum(w * (x - m)^2, na.rm = TRUE) / sum(w[!is.na(x)])) }
wz    <- function(x, w) (x - wmean(x, w)) / wsd(x, w)
wcor  <- function(x, y, w) { ok <- !is.na(x) & !is.na(y); x <- x[ok]; y <- y[ok]; w <- w[ok]
  mx <- wmean(x, w); my <- wmean(y, w); sum(w * (x - mx) * (y - my)) / sqrt(sum(w * (x - mx)^2) * sum(w * (y - my)^2)) }
pv <- PV

# ---- Table 1: sample by economy ----
t1 <- a[, .(
  N = .N, Schools = uniqueN(school),
  Female = round(100 * wmean(female, W_FSTUWT)),
  Age = round(wmean(AGE, W_FSTUWT), 2),
  `Modal grade` = as.integer(names(which.max(table(grade)))),
  `Share below modal grade` = round(100 * wmean(grade_rel < 0, W_FSTUWT)),
  `Repeated grade` = round(100 * wmean(repeated, W_FSTUWT)),
  `Immigrant background` = round(100 * wmean(immig2, W_FSTUWT), 1),
  `Other language at home` = round(100 * wmean(lang_other, W_FSTUWT)),
  `ESCS mean` = round(wmean(ESCS, W_FSTUWT), 2), `ESCS SD` = round(wsd(ESCS, W_FSTUWT), 2),
  `Deprived (any of 4 items)` = round(100 * wmean(dep4_any, W_FSTUWT)),
  `Outcome mean` = round(mean(sapply(pv, function(p) wmean(get(p), W_FSTUWT)))),
  `Outcome SD` = round(mean(sapply(pv, function(p) wsd(get(p), W_FSTUWT))))
), by = .(Bloc = bloc, Economy = economy, CNT)][order(Bloc, Economy)]
fwrite(t1, tp("t1_sample.csv")); print(t1)

# ---- Table 2: skill means (sample-standardised; growth mindset = share) and within-economy correlations with the outcome and ESCS ----
t2 <- rbindlist(lapply(skills, function(s) a[, .(skill = skill_lab[s],
   mean = round(wmean(get(s), W_FSTUWT), 2),
   r_escs = round(wcor(get(s), ESCS, W_FSTUWT), 2),
   r_sci  = round(mean(sapply(pv, function(p) wcor(get(s), get(p), W_FSTUWT))), 2)),
   by = .(bloc, economy, CNT)]))
fwrite(t2, tp("t2_skill_means_corr.csv"))
t2w <- dcast(t2, bloc + economy ~ skill, value.var = c("mean", "r_escs", "r_sci"))
fwrite(t2w, tp("t2_skill_means_corr_wide.csv"))

# correlation matrix: skills (within-system z; growth mindset binary), ESCS and achievement (mean over the 10 PVs, within-system z)
zw <- paste0(skills, "_zw")
ap <- a[persev_fielded == TRUE]
ap[, ESCS_zw := wz(ESCS, W_FSTUWT), by = CNT]
for (dom in c("READ", "MATH", "SCIE")) { pvs <- paste0("PV", 1:10, dom); if (all(pvs %in% names(ap))) { ap[, (paste0(dom, "_m")) := rowMeans(.SD), .SDcols = pvs]; ap[, (paste0(dom, "_zw")) := wz(get(paste0(dom, "_m")), W_FSTUWT), by = CNT] } }
extra <- intersect(c("ESCS_zw", "READ_zw", "MATH_zw", "SCIE_zw"), names(ap)); cols <- c(zw, extra)
cc <- ap[complete.cases(ap[, ..cols])]; cm <- cov.wt(as.matrix(cc[, ..cols]), wt = cc$w_senate, cor = TRUE)$cor
lab_map <- c(setNames(skill_lab[skills], zw), ESCS_zw = "ESCS", READ_zw = "Reading", MATH_zw = "Mathematics", SCIE_zw = "Science"); labs <- unname(lab_map[cols])
dimnames(cm) <- list(labs, labs)
fwrite(as.data.table(round(cm, 2), keep.rownames = "skill"), tp("t_skill_intercorr.csv"))
print(round(cm, 2))

# ---- Figure 1: skill-science and skill-ESCS correlations by economy ----
t2[, economy := factor(economy, levels = t1$Economy)]
f1 <- ggplot(t2, aes(x = r_sci, y = economy, colour = bloc)) +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_point(size = 2.4) +
  facet_wrap(~ skill, nrow = 1) +
  scale_colour_manual(values = pal_bloc, name = NULL) +
  labs(x = paste0("Weighted correlation with ", dom_lab, " score (mean over 10 PVs)"), y = NULL,
       title = paste0("Socio-emotional skills and ", dom_lab, " achievement, by economy")) +
  theme(strip.text = element_text(size = 8.5))
ggsave(fp("f1_skill_science_corr.png"), f1, width = 11, height = 5.5, dpi = 200, bg = "white")

f1b <- ggplot(t2, aes(x = r_escs, y = economy, colour = bloc)) +
  geom_vline(xintercept = 0, colour = "grey70") + geom_point(size = 2.4) +
  facet_wrap(~ skill, nrow = 1) + scale_colour_manual(values = pal_bloc, name = NULL) +
  labs(x = "Weighted correlation with ESCS", y = NULL, title = "Socio-emotional skills and family socio-economic status, by economy") +
  theme(strip.text = element_text(size = 8.5))
ggsave(fp("f1b_skill_escs_corr.png"), f1b, width = 11, height = 5.5, dpi = 200, bg = "white")

# ---- SES gradient of skills: mean within-economy z by ESCS group ----
t3 <- rbindlist(lapply(skills, function(s) a[, .(skill = skill_lab[s], z = round(wmean(get(paste0(s, "_zw")), W_FSTUWT), 2)), by = .(bloc, escs_grp)]))
t3w <- dcast(t3, bloc + skill ~ escs_grp, value.var = "z")
fwrite(t3w, tp("t3_skill_by_escs_group.csv")); print(t3w)

# deprivation by ESCS group
t4 <- a[, .(dep_any = round(100 * wmean(dep4_any, W_FSTUWT)), dep_cnt = round(wmean(dep4_cnt, W_FSTUWT), 2)), by = .(bloc, escs_grp)][order(bloc, escs_grp)]
fwrite(t4, tp("t4_deprivation_by_escs.csv")); print(t4)
cat("done descriptives\n")
