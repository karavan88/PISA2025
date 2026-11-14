# Paper A -- figures 2-5 from model outputs
source("02_scripts/paperA/00_helpers.R"); suppressPackageStartupMessages({library(ggplot2); library(patchwork)})
theme_set(theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom", strip.text = element_text(size = 9)))
econ <- fread("01_data/derived/paperA_economies.csv"); blocs <- c("East Asia", "Post-Soviet", "Post-communist Europe")
ord <- c(econ$economy, blocs, ALL_LAB)
lab_unit <- function(u) factor(u, levels = rev(ord))

# ---- Figure 2: share of the ESCS gradient explained by skills (total gradient), with 95% CI ----
g <- fread(tp("h1_gelbach_long_total.csv"))
sh <- g[term == "share_explained", .(unit, bloc, est = 100 * est, lo = 100 * (est - 1.96 * se), hi = 100 * (est + 1.96 * se))]
sh[, type := ifelse(unit %in% c(blocs, ALL_LAB), "Pooled", "Economy")]
f2 <- ggplot(sh, aes(x = est, y = lab_unit(unit), colour = ifelse(type == "Pooled", "Pooled", bloc))) +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0) + geom_point(aes(shape = type), size = 2.4) +
  scale_colour_manual(values = c(pal_bloc, Pooled = "black"), name = NULL) + scale_shape_manual(values = c(Economy = 16, Pooled = 15), guide = "none") +
  labs(x = paste0("% of the ESCS gradient in ", dom_lab, " explained by the six skills (95% CI)"), y = NULL)
ggsave(fp("f2_gelbach_share.png"), f2, width = 8.5, height = 6.5, dpi = 200, bg = "white")

# ---- Figure 3: decomposition by skill (points of the gradient), pooled and by bloc ----
dl <- g[grepl("^delta_", term) & unit %in% c(blocs, ALL_LAB), .(unit, skill = skill_lab[sub("delta_", "", term)], est, lo = est - 1.96 * se, hi = est + 1.96 * se)]
f3 <- ggplot(dl, aes(x = est, y = skill, colour = unit)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(width = 0.6), size = 0.3) +
  scale_colour_manual(values = c(pal_bloc, `All 20 economies` = "black"), name = NULL) +
  labs(x = paste0("Contribution to the ESCS gradient, ", dom_lab, " points per ESCS unit (gamma_k x pi_k)"), y = NULL)
ggsave(fp("f3_gelbach_by_skill.png"), f3, width = 8.5, height = 4.5, dpi = 200, bg = "white")

# ---- Figure 4: returns to skills for Bottom 40% vs Top 10% ----
sl <- fread(tp("h2_skill_returns_by_group.csv"))
s2 <- sl[group %in% c("Bottom 10%", "Top 10%") & unit %in% c(blocs, ALL_LAB)]
f4 <- ggplot(s2, aes(x = est, y = skill, colour = group)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), position = position_dodge(width = 0.5), size = 0.3) +
  facet_wrap(~ factor(unit, levels = c(blocs, ALL_LAB)), nrow = 2) +
  scale_colour_manual(values = c("Bottom 10%" = "#CC79A7", "Top 10%" = "#56B4E9"), name = "ESCS group") +
  labs(x = paste0(tools::toTitleCase(dom_lab), " points per 1 SD of skill (OECD scale), 95% CI"), y = NULL)
ggsave(fp("f4_returns_by_escs_group.png"), f4, width = 9, height = 6.5, dpi = 200, bg = "white")

# per-economy difference plot
s3 <- sl[group == "Difference (B10 - T10)" & !unit %in% c(blocs, ALL_LAB)]
s3 <- merge(s3, econ[, .(unit = economy, bloc2 = bloc)], by = "unit")
f4b <- ggplot(s3, aes(x = est, y = lab_unit(unit), colour = bloc2)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), size = 0.25) + facet_wrap(~ skill, nrow = 1) +
  scale_colour_manual(values = pal_bloc, name = NULL) + labs(x = paste0("Return to skill, Bottom 10% minus Top 10% (", dom_lab, " points per SD, 95% CI)"), y = NULL)
ggsave(fp("f4b_return_gap_by_economy.png"), f4b, width = 12, height = 6, dpi = 200, bg = "white")

# ---- Figure 5: skill x grade interactions ----
h3 <- fread(tp("h3b_skill_x_grade_restricted.csv"))
h3i <- h3[term != "Grade (learning gain)" & !unit %in% c(blocs, ALL_LAB)]
h3i <- merge(h3i, econ[, .(unit = economy, bloc2 = bloc)], by = "unit"); h3i[, skill := sub("Grade x ", "", term)]
f5 <- ggplot(h3i, aes(x = est, y = lab_unit(unit), colour = bloc2)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), size = 0.25) + facet_wrap(~ skill, nrow = 1) +
  scale_colour_manual(values = pal_bloc, name = NULL) + labs(x = paste0("Skill x grade interaction: extra ", dom_lab, " points per grade per SD of skill (95% CI); restricted sample"), y = NULL)
ggsave(fp("f5_skill_x_grade.png"), f5, width = 12, height = 6, dpi = 200, bg = "white")

# ---- Figure 6: returns to skills by economy (full model gammas) ----
gm <- g[grepl("^gamma_", term) & !unit %in% c(blocs, ALL_LAB), .(unit, bloc, skill = skill_lab[sub("gamma_", "", term)], est, se)]
f6 <- ggplot(gm, aes(x = est, y = lab_unit(unit), colour = bloc)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), size = 0.25) + facet_wrap(~ skill, nrow = 1) +
  scale_colour_manual(values = pal_bloc, name = NULL) + labs(x = "Conditional return to skill, science points per SD (all six skills, ESCS and controls in the model; 95% CI)", y = NULL)
ggsave(fp("f6_returns_by_economy.png"), f6, width = 12, height = 6, dpi = 200, bg = "white")
cat("figures done\n")
