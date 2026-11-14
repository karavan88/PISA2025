# Paper A -- manuscript figures (reading primary; maths and science in the domain comparison)
# Reads the outputs of 04_h1_gelbach.R (BRR SEs for the joint block) and 09_causal_mediation.R (mediate/medsens).
# Every point is a system-level estimate (one model per education system); the summary shown is the median across systems.
# Blocs are used only to order and colour systems. Run from the repo root (or the analysis folder): Rscript 02_scripts/paperA/11_figures_paper.R
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(patchwork)})
source(if (file.exists("02_scripts/paperA/12_paper_tables.R")) "02_scripts/paperA/12_paper_tables.R" else "scripts/12_paper_tables.R")
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
pal_bloc <- c("East Asia" = "#0072B2", "Post-Soviet" = "#D55E00", "Post-communist Europe" = "#009E73", Median = "black")
pal_dom  <- c(Reading = "#0072B2", Mathematics = "#E69F00", Science = "#009E73")
theme_set(theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom", strip.text = element_text(size = 9)))
spec_lab <- function(sp) factor(ifelse(sp == "within", "Within-school gradient", "Total gradient"), levels = c("Within-school gradient", "Total gradient"))
lab_unit <- function(u, AL) factor(u, levels = rev(c(econ$economy, AL)))

# ---- Figure 1: ESCS gradient of each skill by system (mediator-model coefficient on ESCS), reading sample, total spec; median row ----
g <- gel_raw("READ", "total"); AL <- all_lab("READ")
pi <- g[grepl("^pi_", term), .(unit, skill = factor(skill_lab[sub("pi_", "", term)], levels = skill_lab), est, se)]
pi[, bloc := econ$bloc[match(unit, econ$economy)]]
pi <- rbind(pi, pi[, .(unit = AL, est = median(est), se = NA_real_, bloc = "Median"), by = skill], fill = TRUE)
f1 <- ggplot(pi, aes(x = est, y = lab_unit(unit, AL), colour = bloc)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), size = 0.25, na.rm = TRUE) + facet_wrap(~ skill, nrow = 1) +
  scale_colour_manual(values = pal_bloc, name = NULL) + labs(x = "Disposition per 10 percentile points of ESCS (six scales: sample SD; growth mindset: probability), with student controls (95% CI); black = median of 19 systems", y = NULL)
ggsave(paste0(FIG, "fig1_skill_gradients.png"), f1, width = 12, height = 5.5, dpi = 200, bg = "white")

# ---- Figure 2: % of the ESCS gradient in reading mediated by the six skills, by system: within-school and total; median row ----
sh <- rbindlist(lapply(c("within", "total"), function(sp) med("READ", sp)[mediator == "All skills (joint)", .(spec = sp, unit = as.character(unit), bloc, est = 100 * prop, se = 100 * prop_se, total, n_sys)]))
sh[, spec := spec_lab(spec)]
# a share is not identified when the gradient itself is near zero (Bulgaria within school, ~3 points): drop such points from the panel
drop_sh <- sh[spec == "Within-school gradient" & n_sys == 1 & abs(total) < 4, unit]; sh <- sh[!(spec == "Within-school gradient" & unit %in% drop_sh)]
cap2 <- paste0("Black = median of 19 systems, bar = interquartile range.", if (length(drop_sh)) paste0("\nNot shown in the within-school panel (gradient below four points, share not identified): ", paste(drop_sh, collapse = ", "), ".") else "")
for (sp in c("within", "total")) { m <- med("READ", sp)[unit == AL & mediator == "All skills (joint)"]; sh[spec == spec_lab(sp) & n_sys > 1, `:=`(lo = 100 * m$prop_lo, hi = 100 * m$prop_hi)] }
sh[n_sys == 1, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
f2 <- ggplot(sh, aes(x = est, y = lab_unit(unit, AL), colour = bloc)) + geom_vline(xintercept = 0, colour = "grey70") +
  geom_pointrange(aes(xmin = lo, xmax = hi), size = 0.3) + facet_wrap(~ spec, scales = "free_x") +
  scale_colour_manual(values = pal_bloc, name = NULL) + labs(x = "% of the ESCS-rank effect on reading mediated by the seven dispositions (systems: 95% CI)", y = NULL, caption = cap2) +
  theme(plot.caption = element_text(hjust = 0, colour = "grey40"))
ggsave(paste0(FIG, "fig2_prop_mediated_by_economy.png"), f2, width = 10, height = 6.5, dpi = 200, bg = "white")

# ---- Figure 3: ACME by skill (mediate), reading: one point per system, median marked ----
mk <- rbindlist(lapply(c("within", "total"), function(sp) med("READ", sp)[mediator != "All skills (joint)", .(spec = sp, unit = as.character(unit), bloc, mediator, acme, n_sys)]))
mk[, spec := spec_lab(spec)]; mk[, mediator := factor(mediator, levels = rev(skill_lab))]
f3 <- ggplot() + geom_vline(xintercept = 0, colour = "grey70") +
  geom_jitter(data = mk[n_sys == 1], aes(x = acme, y = mediator, colour = bloc), height = 0.15, width = 0, size = 1.8, alpha = 0.8) +
  geom_point(data = mk[n_sys > 1], aes(x = acme, y = mediator), shape = 18, size = 4.5, colour = "black") +
  facet_wrap(~ spec, scales = "free_x") + scale_colour_manual(values = pal_bloc, name = NULL) +
  labs(x = "ACME: reading points per 10 percentile points of ESCS via each disposition (one point per system; diamond = median of 19 systems)", y = NULL)
ggsave(paste0(FIG, "fig3_acme_by_skill.png"), f3, width = 10, height = 5, dpi = 200, bg = "white")

# ---- Figure 4: sensitivity, rho* by system for curiosity (medsens) and the joint block (closed form), reading within-school ----
mm <- med("READ", "within")[n_sys == 1]
rs <- rbind(mm[mediator == "Curiosity", .(unit = as.character(unit), bloc, what = "Curiosity (medsens)", rho = rho_star)],
            mm[mediator == "All skills (joint)", .(unit = as.character(unit), bloc, what = "All skills (joint)", rho = rho_star)])
f4 <- ggplot(rs, aes(x = rho, y = lab_unit(unit, AL), colour = bloc, shape = what)) + geom_vline(xintercept = 0, colour = "grey70") + geom_point(size = 2.4, position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = pal_bloc, name = NULL) + scale_shape_manual(values = c(16, 17), name = NULL) +
  labs(x = expression(paste("Sensitivity parameter ", rho^"*", " (residual correlation at which the mediated effect is zero)")), y = NULL)
ggsave(paste0(FIG, "fig4_sensitivity_rho.png"), f4, width = 9, height = 6, dpi = 200, bg = "white")

# ---- Figure 5: domain comparison — % mediated (joint) per system and median, three domains, two specs ----
dd <- rbindlist(lapply(c("READ", "MATH", "SCIE"), function(dom) rbindlist(lapply(c("within", "total"), function(sp) {
  x <- med(dom, sp)[mediator == "All skills (joint)", .(spec = sp, unit = as.character(unit), est = 100 * prop, total, n_sys)]; x[, domain := dom_lab[dom]]; x }))))
dd[, spec := spec_lab(spec)]; dd[, domain := factor(domain, levels = rev(names(pal_dom)))]
dd <- dd[!(spec == "Within-school gradient" & n_sys == 1 & abs(total) < 4)]   # same rule as Figure 2
f5 <- ggplot() + geom_vline(xintercept = 0, colour = "grey70") +
  geom_jitter(data = dd[n_sys == 1], aes(x = est, y = domain, colour = domain), height = 0.15, width = 0, size = 1.8, alpha = 0.7) +
  geom_point(data = dd[n_sys > 1], aes(x = est, y = domain), shape = 18, size = 4.5, colour = "black") +
  facet_wrap(~ spec, scales = "free_x") + scale_colour_manual(values = pal_dom, name = NULL, guide = "none") +
  labs(x = "% of the ESCS-rank effect mediated by the seven dispositions (one point per system; diamond = median)", y = NULL)
ggsave(paste0(FIG, "fig5_domains.png"), f5, width = 10, height = 3.5, dpi = 200, bg = "white")
cat("paper figures written to", FIG, "\n")
