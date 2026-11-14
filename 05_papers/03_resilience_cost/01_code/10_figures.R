# Figures for "The cost of resilience". Reads the approved snapshot only (05_papers/03_resilience_cost/02_results/snapshot); estimates nothing.
# Output: 05_papers/03_resilience_cost/02_results/figs/*.pdf      Run from the repository root: Rscript 05_papers/03_resilience_cost/01_code/10_figures.R
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork); library(ggrepel) })
IN <- "05_papers/03_resilience_cost/02_results/snapshot/"; FIG <- "05_papers/03_resilience_cost/02_results/figs/"; dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(f) fread(paste0(IN, f))
rs <- rd("rs_pool.csv"); gp <- rd("gap_pool.csv"); gs <- rd("gap_sys.csv"); mp <- rd("mech_pool.csv"); orr <- rd("oriv_resil.csv"); dist <- rd("desc_dist.csv")

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

# ------------------------------------------------------------------ A1: who reports what
cells <- c(R = "Disadvantaged, top achievers (resilient)", PL = "Disadvantaged, low achievers", AT = "Advantaged, top achievers", AL = "Advantaged, low achievers")
dA <- dist[cell %in% c("R", "PL")][, grp := factor(cells[cell], levels = cells[c("PL", "R")])]
a1a <- ggplot(dA, aes(factor(LS), 100 * share, fill = grp)) + geom_col(position = position_dodge(0.8), width = 0.75) +
  scale_fill_manual(values = c(cB, cR)) + labs(x = "Life satisfaction (0-10)", y = "% of students", title = "Fewer tens, more sevens and eights") +
  theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1), legend.direction = "vertical", panel.grid.major.x = element_blank())
m <- rbindlist(lapply(names(cells), function(cc) data.table(cell = cc, LS = rs[term == paste0("mean:", cc, ":LS"), re_mean], se = rs[term == paste0("mean:", cc, ":LS"), re_se], SEI = rs[term == paste0("mean:", cc, ":SEI"), re_mean])))
m[, `:=`(ses = ifelse(cell %in% c("R", "PL"), "Bottom SES quartile", "Top SES quartile"), ach = factor(ifelse(cell %in% c("R", "AT"), "Top quartile", "Bottom quartile"), levels = c("Bottom quartile", "Top quartile")))]
a1b <- ggplot(m, aes(ach, LS, colour = ses, group = ses)) + geom_line(linewidth = 0.7) + geom_linerange(aes(ymin = LS - 1.96 * se, ymax = LS + 1.96 * se), linewidth = 0.5) + geom_point(size = 2.4) +
  geom_text(aes(label = sprintf("skill index\n%+.2f SD", SEI), hjust = ifelse(ach == "Top quartile", -0.18, 1.18)), size = 2.5, lineheight = 0.9, family = FAM, show.legend = FALSE) +
  scale_colour_manual(values = c(cR, cG)) + scale_y_continuous(limits = c(6.85, 7.95)) + scale_x_discrete(expand = expansion(mult = 0.75)) +
  labs(x = "Achievement within system", y = "Mean life satisfaction (0-10)", title = "Achievement pays off in skills, not in satisfaction") +
  theme(legend.position = "bottom")
save(a1a + a1b + plot_layout(widths = c(1.15, 1)), "fig_a1_cells", h = 3.3)

# ------------------------------------------------------------------ A2: specification ladder
lad <- rbind(pick(gp, c("lad:demo", "lad:sei", "lad:se6", "lad:full"), c("Demographics only", "+ skill index", "+ six skills separately", "+ skill index and relationships")),
             pick(rs, c("gap:sei_rs", "gap:sei_nospeed", "gap:sei_netplac"), c("+ response-style indices", "Excluding questionnaire speeders", "Net of top-box use on effort scales")),
             pick(gp, c("alt:sei", "lad:nofe_demo"), c("Versus all other disadvantaged students", "No school fixed effects, demographics only")))
lad[, block := factor(c(rep("Adding what resilient students have more of", 4), rep("Reporting behaviour (skill index held)", 3), rep("Other comparisons", 2)),
                      levels = c("Adding what resilient students have more of", "Reporting behaviour (skill index held)", "Other comparisons"))]
a2 <- coefplot(lad, xlab = "Life-satisfaction gap, resilient minus disadvantaged low achievers (within-system SD)") +
  geom_text(aes(x = hi, label = sprintf("%.2f", re_mean)), hjust = -0.35, size = 2.7, family = FAM) +
  facet_grid(block ~ ., scales = "free_y", space = "free_y", switch = "y") + scale_x_continuous(limits = c(-0.28, 0.03)) +
  theme(strip.placement = "outside", strip.text.y.left = element_blank(), panel.spacing = unit(9, "pt")) +
  labs(title = "The gap doubles once skills are held fixed, and reporting behaviour does not explain it")
save(a2, "fig_a2_ladder", h = 3.3)

# ------------------------------------------------------------------ A3: every system
sy <- gs[term == "lad:sei" & !is.na(est) & !is.na(se)][order(est)][, `:=`(rank = .I, sig = est + 1.96 * se < 0)]
pooled <- gp[term == "lad:sei", re_mean]
a3 <- ggplot(sy, aes(rank, est)) + geom_hline(yintercept = 0, linewidth = 0.35, colour = cK) + geom_hline(yintercept = pooled, linewidth = 0.4, colour = cR, linetype = "22") +
  geom_linerange(aes(ymin = est - 1.96 * se, ymax = est + 1.96 * se, colour = sig), linewidth = 0.35) + geom_point(aes(colour = sig), size = 1.1) +
  geom_text(aes(y = pmin(est + 1.96 * se, 0.78), label = CNT), angle = 90, hjust = -0.15, size = 1.9, colour = "#555555", family = FAM) +
  annotate("text", x = nrow(sy), y = -0.95, label = sprintf("dashed line: pooled gap %.2f", pooled), hjust = 1, vjust = 0, size = 2.7, colour = cR, family = FAM) +
  scale_colour_manual(values = c(`TRUE` = cR, `FALSE` = cG), labels = c(`TRUE` = "95% interval excludes zero", `FALSE` = "includes zero")) +
  coord_cartesian(ylim = c(-1.05, 0.95)) + labs(x = sprintf("%d education systems, ordered by the size of the gap", nrow(sy)), y = "Gap (within-system SD)",
       title = sprintf("Negative in %d of %d systems, and statistically the same everywhere", sum(sy$est < 0), nrow(sy))) +
  theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank())
save(a3, "fig_a3_systems", h = 3.3)

# ------------------------------------------------------------------ A4: where on the ladder, and the placebo
th <- pick(rs, c("thr:LSge4", "thr:LSge6", "thr:LSge8", "thr:LSge9", "thr:LS10"), c("4+", "6+", "8+", "9+", "10"))
th[, lab := factor(lab, levels = c("4+", "6+", "8+", "9+", "10"))]
a4a <- ggplot(th, aes(lab, 100 * re_mean)) + geom_hline(yintercept = 0, linewidth = 0.35) + geom_col(fill = cR, width = 0.62) +
  geom_linerange(aes(ymin = 100 * lo, ymax = 100 * hi), linewidth = 0.4) + labs(x = "Share reporting a life satisfaction of at least ...", y = "Gap (percentage points)", title = "The gap opens at the top of the ladder") +
  theme(panel.grid.major.x = element_blank())
pb <- pick(rs, c("thr:LS10", "plac:EFF1_10", "plac:EFFQ_10", "plac:EFF2_10"), c("Life satisfaction", "Effort on the test", "Effort on the questionnaire", "Effort if the test had counted"))
pb[, kind := c("Outcome", "Placebo", "Placebo", "Placebo")]
a4b <- ggplot(pb, aes(100 * re_mean, lab, colour = kind)) + zero + geom_linerange(aes(xmin = 100 * lo, xmax = 100 * hi), linewidth = 0.6) + geom_point(size = 2.2) +
  scale_colour_manual(values = c(Outcome = cR, Placebo = cB)) + labs(x = "Gap in the share answering 10 (percentage points)", y = NULL, title = "Resilient students do not avoid 10 on other scales") +
  theme(legend.position = "none")
save(a4a + a4b + plot_layout(widths = c(1, 1.15)), "fig_a4_topbox", h = 3.0)

# ------------------------------------------------------------------ A5: moderators
mo <- pick(mp, paste0("mod:", c("schESCS", "schACH", "female", "uni", "PERSEV", "GOALSET", "COGABIL", "ENPROBS", "SELFREG", "CURIO"), ":topX"),
           c("School mean SES (others in school)", "School mean achievement (others in school)", "Female", "Expects a university degree",
             "Perseverance", "Goal setting", "Cognitive adaptability", "Enjoyment of problem-solving", "Self-regulated learning", "Curiosity"))
mo[, block := c(rep("Context", 4), rep("Skills, student-rated (69 systems)", 6))]
pr <- orr[sample == "all" & term %in% c("noach:ols_student:topXSR", "noach:ols_parent:topXSR"), .(re_mean = est, re_se = se, lab = c("Self-regulation, student-rated", "Self-regulation, parent-rated"))]
pr[, `:=`(lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se, block = "Two raters (17 systems)")]
mo <- rbind(mo[, .(re_mean, lo, hi, lab = as.character(lab), block)], pr[, .(re_mean, lo, hi, lab, block)])
mo[, `:=`(lab = factor(lab, levels = rev(lab)), block = factor(block, levels = unique(block)), sig = abs(re_mean / ((hi - lo) / 3.92)) > 2.576)]
a5 <- ggplot(mo, aes(re_mean, lab, colour = sig)) + zero + geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6) + geom_point(size = 2) +
  facet_grid(block ~ ., scales = "free_y", space = "free_y") + scale_colour_manual(values = c(`TRUE` = cR, `FALSE` = cG)) +
  labs(x = "Change in the gap per SD of the moderator (per unit for the two indicators); positive = smaller gap", y = NULL,
       title = "Context does not move the gap; two skills do, and one of them fails the second rater") +
  theme(legend.position = "none", strip.text.y = element_text(angle = 0, hjust = 0, face = "plain", size = 7.5, colour = "#444444"), panel.spacing = unit(8, "pt"))
save(a5, "fig_a5_moderators", h = 3.7)

