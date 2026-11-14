# Figures for "The price of progress". Reads the approved snapshot only (05_papers/04_price_of_progress/02_results/snapshot); estimates nothing.
# Output: 05_papers/04_price_of_progress/02_results/figs/*.pdf      Run from the repository root: Rscript 05_papers/04_price_of_progress/01_code/10_figures.R
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork); library(ggrepel) })
IN <- "05_papers/04_price_of_progress/02_results/snapshot/"; FIG <- "05_papers/04_price_of_progress/02_results/figs/"; dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(f) fread(paste0(IN, f))
xp <- rd("extras_pool.csv"); dist <- rd("desc_dist.csv"); dec <- rd("desc_decile.csv"); kp <- rd("cutoff_pool.csv"); ks <- rd("cutoff_sys.csv"); op <- rd("oriv_pool.csv"); os <- rd("oriv_sys.csv")

cR <- "#D55E00"; cB <- "#0072B2"; cG <- "#7A7A7A"; cL <- "#C9C9C9"; cK <- "#222222"
FAM <- if ("PT Sans" %in% systemfonts::system_fonts()$family) "PT Sans" else "sans"
theme_set(theme_minimal(base_size = 9, base_family = FAM) +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(linewidth = 0.25, colour = "#E6E6E6"),
        plot.title = element_text(face = "bold", size = 9.5, margin = margin(b = 3)), plot.subtitle = element_text(size = 8, colour = "#444444", margin = margin(b = 5)),
        plot.title.position = "plot", axis.title = element_text(size = 8), legend.position = "bottom", legend.title = element_blank(),
        legend.key.size = unit(9, "pt"), legend.margin = margin(0, 0, 0, 0), strip.text = element_text(face = "bold", hjust = 0, size = 8.5),
        plot.margin = margin(6, 8, 4, 6)))
save <- function(p, name, w = 6.3, h = 3.4) { ggsave(paste0(FIG, name, ".pdf"), p, width = w, height = h, device = cairo_pdf); message("wrote ", name) }
pick <- function(dt, terms, labels = terms) { x <- dt[match(terms, term)]; x[, lab := factor(labels, levels = rev(labels))]; x[, `:=`(lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se)]; x[] }
zero <- geom_vline(xintercept = 0, linewidth = 0.35, colour = cK)
coefplot <- function(x, col = cR, xlab) ggplot(x, aes(re_mean, lab)) + zero + geom_linerange(aes(xmin = lo, xmax = hi), colour = col, linewidth = 0.6) +
  geom_point(colour = col, size = 2) + labs(x = xlab, y = NULL)

# ------------------------------------------------------------------ B1: the gradient, raw and with skills held
dl <- melt(dec, id.vars = c("sesq", "dec"), measure.vars = c("raw", "adj"))
dl[, `:=`(panel = factor(ifelse(variable == "raw", "As reported", "Holding the skill index fixed"), levels = c("As reported", "Holding the skill index fixed")),
          q = factor(sesq, labels = c("Bottom SES quartile", "Second", "Third", "Top SES quartile")))]
b1 <- ggplot(dl, aes(dec, value, colour = q, group = q)) + geom_hline(yintercept = 0, linewidth = 0.3, colour = "#999999") + geom_line(aes(linewidth = q)) + geom_point(size = 1.1) +
  facet_wrap(~panel) + scale_colour_manual(values = c(cR, "#E8B08A", "#9DB9D3", cB)) + scale_linewidth_manual(values = c(0.8, 0.45, 0.45, 0.8), guide = "none") +
  scale_x_continuous(breaks = 1:10) + labs(x = "Achievement decile within system (1 = lowest)", y = "Life satisfaction (within-system SD)",
       title = "Higher achievers are no more satisfied, and less satisfied once their skills are held fixed")
save(b1, "fig_b1_gradient", h = 3.3)

# ------------------------------------------------------------------ B2: skills mask the slope
ms <- rbind(pick(xp, c("all:ach_noskill", "q1:ach_noskill", "q2:ach_noskill", "q3:ach_noskill", "q4:ach_noskill"), c("All students", "Bottom SES quartile", "Second quartile", "Third quartile", "Top SES quartile"))[, spec := "Without the skill index"],
            pick(xp, c("all:ach_skill", "q1:ach_skill", "q2:ach_skill", "q3:ach_skill", "q4:ach_skill"), c("All students", "Bottom SES quartile", "Second quartile", "Third quartile", "Top SES quartile"))[, spec := "Holding the skill index fixed"])
ms[, spec := factor(spec, levels = c("Without the skill index", "Holding the skill index fixed"))]
b2 <- ggplot(ms, aes(re_mean, lab, colour = spec, shape = spec)) + zero + geom_linerange(aes(xmin = lo, xmax = hi), position = position_dodge(0.5), linewidth = 0.6) +
  geom_point(position = position_dodge(0.5), size = 2.1, fill = "white") + scale_colour_manual(values = c(cG, cR)) + scale_shape_manual(values = c(21, 16)) +
  labs(x = "Change in life satisfaction per SD of achievement (within-system SD, within school)", y = NULL, title = "Skills hide a negative achievement slope at every level of family background") +
  guides(colour = guide_legend(reverse = TRUE), shape = guide_legend(reverse = TRUE))
save(b2, "fig_b2_masking", h = 2.9)

# ------------------------------------------------------------------ B3: the cutoff design, system by system
source("05_papers/04_price_of_progress/01_code/systems.R"); nm <- SYSTEMS_TABLE[, .(CNT, name)]
iv <- merge(ks[spec == "base" & term == "gamma" & outcome %in% c("LS_z", "ACH")], nm, by = "CNT", all.x = TRUE)
ord <- iv[outcome == "LS_z"][order(-est), name]
pooled_iv <- kp[spec == "base" & term == "gamma" & set == "all 20" & outcome %in% c("LS_z", "ACH"), .(outcome, est = re_mean, se = re_se, name = "All 20 systems (random effects)", structure = "Pooled")]
iv <- rbind(iv[, .(outcome, est, se, name, structure)], pooled_iv)
iv[, `:=`(name = factor(name, levels = c("All 20 systems (random effects)", ord)), panel = factor(ifelse(outcome == "LS_z", "Life satisfaction (SD)", "Achievement (PISA points)"), levels = c("Life satisfaction (SD)", "Achievement (PISA points)")))]
b3 <- ggplot(iv, aes(est, name, colour = structure)) + zero + geom_linerange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), linewidth = 0.5) +
  geom_point(aes(shape = structure, size = structure)) + facet_wrap(~panel, scales = "free_x") +
  scale_colour_manual(values = c(Pooled = cK, `Same-school` = cR, Transition = cB), labels = c(Pooled = "Pooled", `Same-school` = "Both grades in the same school", Transition = "Upper grade is a different school")) +
  scale_shape_manual(values = c(Pooled = 18, `Same-school` = 16, Transition = 16), guide = "none") + scale_size_manual(values = c(Pooled = 3.2, `Same-school` = 1.8, Transition = 1.8), guide = "none") +
  labs(x = "Effect of one extra grade at the same age (school-entry cutoff IV)", y = NULL, title = "An extra grade raises achievement and, on average, lowers life satisfaction")
save(b3, "fig_b3_iv", h = 4.2)

# ------------------------------------------------------------------ B4: top of the ladder, cross-section and IV
dB <- dist[cell %in% c("AT", "AL", "R", "PL")]; dB[, ach := ifelse(cell %in% c("AT", "R"), "Top achievement quartile", "Bottom achievement quartile")]
dB <- dB[, .(share = mean(share)), by = .(ach, LS)]
b4a <- ggplot(dB, aes(factor(LS), 100 * share, fill = ach)) + geom_col(position = position_dodge(0.8), width = 0.75) + scale_fill_manual(values = c(cB, cR)) +
  labs(x = "Life satisfaction (0-10)", y = "% of students", title = "High achievers stop short of 10") +
  theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1), legend.direction = "vertical", panel.grid.major.x = element_blank())
tb <- rbind(data.table(design = "Cross-section: per SD of achievement,\nskills held", out = c("Share at 10", "Share at 4 or below"), est = xp[match(c("LS10:ach_skill", "LSle4:ach_skill"), term), re_mean], se = xp[match(c("LS10:ach_skill", "LSle4:ach_skill"), term), re_se]),
            data.table(design = "Cutoff IV: per extra grade", out = c("Share at 10", "Share at 4 or below"), est = kp[spec == "base" & term == "gamma" & set == "all 20"][match(c("LS10", "LSle4"), outcome), re_mean], se = kp[spec == "base" & term == "gamma" & set == "all 20"][match(c("LS10", "LSle4"), outcome), re_se]))
b4b <- ggplot(tb, aes(100 * est, out, colour = out)) + zero + geom_linerange(aes(xmin = 100 * (est - 1.96 * se), xmax = 100 * (est + 1.96 * se)), linewidth = 0.6) + geom_point(size = 2.2) +
  facet_wrap(~design, ncol = 1) + scale_colour_manual(values = c(`Share at 10` = cR, `Share at 4 or below` = cB)) + labs(x = "Percentage points", y = NULL, title = "Both designs: fewer tens, not more misery") +
  theme(legend.position = "none", strip.text = element_text(face = "plain", size = 7.5))
save(b4a + b4b + plot_layout(widths = c(1.15, 1)), "fig_b4_topbox", h = 3.2)

# ------------------------------------------------------------------ B5: is the causal effect the same for everyone?
het <- kp[outcome == "LS_z" & set %in% c("all 20", "same-school 14") & ((spec == "lowses" & term == "gamma:lowSES") | (spec == "ses" & term == "gamma:SES") | (spec == "se" & term == "gamma:SE_p") | (spec == "cur" & term == "gamma:CURIO_z"))]
het[, lab := factor(c(`gamma:lowSES` = "Bottom SES quartile (vs the rest)", `gamma:SES` = "SES, per SD", `gamma:SE_p` = "Skill index, per SD", `gamma:CURIO_z` = "Curiosity, per SD")[term],
                    levels = rev(c("Bottom SES quartile (vs the rest)", "SES, per SD", "Skill index, per SD", "Curiosity, per SD")))]
het[, set := factor(ifelse(set == "all 20", "All 20 systems", "14 same-school systems"), levels = c("All 20 systems", "14 same-school systems"))]
b5 <- ggplot(het, aes(re_mean, lab, colour = set, shape = set)) + zero + geom_vline(xintercept = kp[spec == "base" & term == "gamma" & set == "all 20" & outcome == "LS_z", re_mean], linetype = "22", colour = cR, linewidth = 0.4) +
  geom_linerange(aes(xmin = re_mean - 1.96 * re_se, xmax = re_mean + 1.96 * re_se), position = position_dodge(0.5), linewidth = 0.6) + geom_point(position = position_dodge(0.5), size = 2) +
  scale_colour_manual(values = c(cK, cG)) + scale_shape_manual(values = c(16, 17)) + guides(colour = guide_legend(reverse = TRUE), shape = guide_legend(reverse = TRUE)) +
  labs(x = "Difference in the effect of an extra grade on life satisfaction (SD); dashed line = the average effect", y = NULL, title = "The effect of an extra grade does not depend on family background or skills")
save(b5, "fig_b5_heterogeneity", h = 2.6)

# ------------------------------------------------------------------ B6: two raters
nm2 <- c(BRA = "Brazil", BRN = "Brunei", TAP = "Chinese Taipei", COL = "Colombia", DOM = "Dominican Republic", GEO = "Georgia", DEU = "Germany", HKG = "Hong Kong", IRL = "Ireland",
         ITA = "Italy", KOR = "Korea", MNG = "Mongolia", PRT = "Portugal", ROU = "Romania", ARE = "United Arab Emirates", LUX = "Luxembourg", MAC = "Macao")
rt <- os[term %in% c("ach:ols_student", "ach:ols_parent") & !is.na(est)]
rt <- rbind(rt[, .(CNT, term, est, se)], op[sample == "all" & term %in% c("ach:ols_student", "ach:ols_parent"), .(CNT = "ZZ", term, est = re_mean, se = re_se)])
rt[, name := ifelse(CNT == "ZZ", "Pooled (random effects)", nm2[CNT])]
o2 <- c("Pooled (random effects)", rt[term == "ach:ols_parent" & CNT != "ZZ"][order(est), name])
rt[, `:=`(name = factor(name, levels = o2), rater = factor(ifelse(term == "ach:ols_student", "Rated by the student", "Rated by a parent"), levels = c("Rated by the student", "Rated by a parent")))]
b6 <- ggplot(rt, aes(est, name, colour = rater)) + zero + geom_line(aes(group = name), colour = cL, linewidth = 0.9) + geom_linerange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), linewidth = 0.4, alpha = 0.7) +
  geom_point(aes(size = name == "Pooled (random effects)")) + scale_size_manual(values = c(`FALSE` = 1.7, `TRUE` = 2.8), guide = "none") + scale_colour_manual(values = c(cG, cR)) +
  labs(x = "Change in life satisfaction per SD of self-regulated learning (within-system SD)", y = NULL, title = "Self-regulation predicts life satisfaction even when a parent does the rating")
save(b6, "fig_b6_raters", h = 3.6)
