# sestransmit -- figures. Reads 03_outputs/sestransmit/tables/estimates_long.csv; writes PDF + PNG to 03_outputs/sestransmit/figures/
source("02_scripts/sestransmit/00_helpers.R")
suppressPackageStartupMessages({library(ggplot2); library(ggrepel); library(patchwork); library(scales)})
R <- apply_tmin(fread(tp("estimates_long.csv"), encoding = "UTF-8"))
cov <- fread(ap("sample_coverage.csv"), encoding = "UTF-8")
R[, grp := ifelse(OECD == 1, "OECD", "Partner")]
R[, mediator_lab := factor(skill_lab[mediator], levels = skill_lab)]
pal_grp <- c(OECD = "#0072B2", Partner = "#D55E00")
th <- theme_minimal(base_size = 10, base_family = "Helvetica") +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom", plot.title.position = "plot",
        strip.text = element_text(face = "bold", hjust = 0), plot.caption = element_text(hjust = 0, colour = "grey30"))
save <- function(p, name, w, h) { ggsave(fp(paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf); ggsave(fp(paste0(name, ".png")), p, width = w, height = h, dpi = 300, bg = "white") }

# ---- Figure 1: joint mediated share, all systems, science ----
w <- dcast(R[run == "main" & domain == "SCIE" & stat %in% c("beta_tot", "joint", "joint_share")], CNT + economy + grp + spec ~ stat, value.var = c("est", "se"))
ord <- w[spec == "student"][order(est_joint_share), economy]; w[, economy := factor(economy, levels = ord)]
w[, spec := factor(spec, levels = c("student", "school"), labels = c("Total gradient (student-adjusted)", "Within-school gradient (school-adjusted)"))]
p1 <- ggplot(w, aes(y = economy, x = 100 * est_joint_share, colour = grp, shape = spec)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = .3) +
  geom_errorbarh(data = w[grepl("Total", spec)], aes(xmin = 100 * (est_joint_share - 1.96 * se_joint_share), xmax = 100 * (est_joint_share + 1.96 * se_joint_share)),
                 height = 0, linewidth = .35, show.legend = FALSE) +
  geom_point(size = 1.8, fill = "white", stroke = .7) +
  scale_shape_manual(values = c(16, 21)) + scale_colour_manual(values = pal_grp) +
  scale_x_continuous(breaks = seq(-10, 50, 10)) +
  labs(x = "Share of the socio-economic gradient in science carried by socio-emotional skills (%)", y = NULL, colour = NULL, shape = NULL,
       caption = paste("Bars: 95% confidence intervals for the total-gradient estimate (Fay BRR, 10 plausible values).", "Share = (gradient without skills - gradient with all fielded skills) / gradient without skills.",
                       "Within-school shares omitted where the within-school gradient is indistinguishable from zero (|t| < 2: Kenya, Rwanda).", sep = "\n")) +
  guides(colour = guide_legend(order = 1), shape = guide_legend(order = 2, override.aes = list(colour = "grey30"))) +
  th + theme(axis.text.y = element_text(size = 6.8), panel.grid.major.y = element_blank(), legend.box = "vertical", legend.spacing.y = unit(0, "pt"), plot.caption = element_text(size = 7, hjust = 0, colour = "grey30"))
save(p1, "fig1_joint_share", 7, 11)

# ---- Figure 2: gap x return, per skill ----
g <- dcast(R[run == "main" & domain == "SCIE" & spec == "student" & quantity %in% c("pi", "b", "acme")], CNT + economy + grp + mediator_lab ~ quantity, value.var = "est")
g[, gap := P10P90 * pi]
iso <- rbindlist(lapply(levels(g$mediator_lab), function(m) { d <- g[mediator_lab == m]; rbindlist(lapply(c(5, 10, 20), function(A) {
  x <- seq(max(0.02, min(d$gap)), max(d$gap), length.out = 100); data.table(mediator_lab = factor(m, levels = skill_lab), A = A, gap = x, b = A / x)[b <= max(d$b) * 1.05 & b >= min(d$b)] })) }))
p2 <- ggplot(g, aes(gap, b)) +
  geom_line(data = iso, aes(group = A), colour = "grey70", linewidth = .35, linetype = "22") +
  geom_text(data = iso[, .SD[which.max(gap)], by = .(mediator_lab, A)], aes(label = paste0(A, " pts")), colour = "grey45", size = 2.3, hjust = 1, vjust = -0.4) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = .3) + geom_vline(xintercept = 0, colour = "grey55", linewidth = .3) +
  geom_point(aes(colour = grp), size = 1.4, alpha = .85) +
  facet_wrap(~mediator_lab, scales = "free", ncol = 4) + scale_colour_manual(values = pal_grp) +
  labs(x = "Socio-economic gap in the skill, P10 to P90 of ESCS (SD of the skill; share for growth mindset)",
       y = "Return to the skill (science points per SD; per unit for growth mindset)",
       colour = NULL, caption = "One point per system. Dashed curves: combinations of gap and return that give the same indirect effect of moving from P10 to P90 of ESCS, in PISA points.") +
  th
save(p2, "fig2_gap_return", 9, 5.4)

# ---- Figure 3: heatmap of single-mediator shares ----
h <- R[run == "main" & domain == "SCIE" & spec == "student" & quantity == "ashare", .(CNT, economy, mediator_lab, share = 100 * est)]
jt <- w[grepl("Total", spec), .(CNT, economy = as.character(economy), mediator_lab = factor("All skills (joint)", levels = c(skill_lab, "All skills (joint)")), share = 100 * est_joint_share)]
h[, mediator_lab := factor(as.character(mediator_lab), levels = c(skill_lab, "All skills (joint)"))]
h <- rbind(h, jt); h[, economy := factor(economy, levels = ord)]
p3 <- ggplot(h, aes(mediator_lab, economy, fill = share)) + geom_tile(colour = "white", linewidth = .3) +
  geom_text(aes(label = sprintf("%.0f", share)), size = 2.1, colour = ifelse(h$share > 20, "white", "grey15")) +
  scale_fill_gradient2(low = "#B2182B", mid = "#F7F7F7", high = "#2166AC", midpoint = 0, limits = c(-5, 42), oob = squish, name = "Share of gradient (%)") +
  scale_x_discrete(position = "top", labels = label_wrap(12)) +
  labs(x = NULL, y = NULL, caption = "Single-mediator shares (indirect effect / total gradient, one skill at a time) and the joint share (all fielded skills together).\nBlank cells: scale not fielded in that system.") +
  th + theme(axis.text.y = element_text(size = 6.6), axis.text.x = element_text(size = 7.5), panel.grid = element_blank(), legend.key.width = unit(1.6, "cm"))
save(p3, "fig3_heatmap", 7.5, 11.5)

# ---- Figure 4: what the share correlates with ----
s <- merge(w[grepl("Total", spec), .(CNT, economy = as.character(economy), grp, share = 100 * est_joint_share, beta = est_beta_tot, se_share = 100 * se_joint_share)],
           cov[, .(CNT, sci_all, n_med, icc_sci)], by = "CNT")
s[, lab := fifelse(share > 24 | share < 6 | beta > 11 | beta < 3.5, economy, "")]
p4a <- ggplot(s, aes(sci_all, share, colour = grp)) + geom_hline(yintercept = median(s$share), colour = "grey70", linetype = "22") +
  geom_point(aes(size = n_med), alpha = .85) + geom_text_repel(aes(label = lab), size = 2.3, colour = "grey20", max.overlaps = 30, seed = 1) +
  scale_colour_manual(values = pal_grp) + scale_size(range = c(.8, 2.6), guide = "none") +
  labs(x = "Mean science score (all students)", y = "Joint share of the gradient (%)", colour = NULL, title = "A. Share and average achievement") + th
p4b <- ggplot(s, aes(beta, share, colour = grp)) + geom_hline(yintercept = median(s$share), colour = "grey70", linetype = "22") +
  geom_point(aes(size = n_med), alpha = .85) + geom_text_repel(aes(label = lab), size = 2.3, colour = "grey20", max.overlaps = 30, seed = 1) +
  scale_colour_manual(values = pal_grp) + scale_size(range = c(.8, 2.6), guide = "none") +
  labs(x = "Gradient: science points per 10 percentile points of ESCS", y = NULL, colour = NULL, title = "B. Share and the size of the gradient") + th
p4c <- ggplot(s[!is.na(icc_sci)], aes(100 * icc_sci, share, colour = grp)) + geom_hline(yintercept = median(s$share), colour = "grey70", linetype = "22") +
  geom_smooth(aes(group = 1), method = "lm", se = FALSE, colour = "grey40", linewidth = .5) +
  geom_point(aes(size = n_med), alpha = .85) + geom_text_repel(aes(label = lab), size = 2.3, colour = "grey20", max.overlaps = 30, seed = 1) +
  scale_colour_manual(values = pal_grp) + scale_size(range = c(.8, 2.6), guide = "none") +
  labs(x = "Between-school share of science variance (%)", y = NULL, colour = NULL, title = "C. Share and between-school sorting") + th
p4 <- (p4a | p4b | p4c) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
save(p4, "fig4_correlates", 12, 4.6)

# ---- Figure 5: robustness, system by system ----
base <- R[run == "main" & domain == "SCIE" & spec == "student" & stat == "joint_share", .(CNT, economy, grp, main = 100 * est)]
alt <- R[run != "main" & domain == "SCIE" & spec == "student" & stat == "joint_share", .(CNT, run, alt = 100 * est)]
alt[, run := factor(run, levels = c("ipw", "escs_index", "core5"),
                    labels = c("A. Inverse-probability weights for item non-response", "B. ESCS in index units instead of percentile rank", "C. Five scales fielded everywhere (no perseverance, no growth mindset)"))]
rb <- merge(base, alt, by = "CNT")
rb <- rb[!is.na(main) & !is.na(alt)]; rng <- range(c(rb$main, rb$alt))
p5 <- ggplot(rb, aes(main, alt, colour = grp)) + geom_abline(colour = "grey60", linetype = "22") + geom_point(size = 1.4, alpha = .85) +
  facet_wrap(~run, labeller = label_wrap_gen(38)) + coord_equal(xlim = rng, ylim = rng) + scale_colour_manual(values = pal_grp) +
  labs(x = "Joint share, main specification (%)", y = "Joint share, alternative (%)", colour = NULL) + th
save(p5, "fig5_robustness", 9, 3.8)

# ---- Figure 6: sensitivity rho* ----
rh <- R[run == "main" & domain == "SCIE" & spec == "student" & quantity == "rho", .(economy, mediator_lab, grp, rho = est)]
rh[, mediator_lab := factor(mediator_lab, levels = rev(rh[, median(rho), by = mediator_lab][order(V1), as.character(mediator_lab)]))]
p6 <- ggplot(rh, aes(rho, mediator_lab)) + geom_vline(xintercept = 0, colour = "grey55", linewidth = .3) +
  geom_boxplot(outlier.shape = NA, width = .55, colour = "grey35", fill = "grey92") +
  geom_jitter(aes(colour = grp), height = .18, size = .9, alpha = .7) + scale_colour_manual(values = pal_grp) +
  labs(x = expression(paste(rho, "*: error correlation between the skill and outcome equations at which the indirect effect is zero")), y = NULL, colour = NULL,
       caption = "One point per system (science, total gradient). Larger values mean an unobserved confounder would have to be more strongly related\nto both the skill and achievement to eliminate the channel.") + th
save(p6, "fig6_rho_star", 8, 4.2)

# ---- Figure 7: three domains ----
dd <- dcast(R[run == "main" & spec == "student" & stat == "joint_share"], CNT + economy + grp ~ domain, value.var = "est")
dd <- melt(dd, id.vars = c("CNT", "economy", "grp", "SCIE"), measure.vars = c("READ", "MATH"), variable.name = "domain", value.name = "other")
dd[, domain := factor(domain, levels = c("READ", "MATH"), labels = c("Reading", "Mathematics"))]
p7 <- ggplot(dd, aes(100 * SCIE, 100 * other, colour = grp)) + geom_abline(colour = "grey60", linetype = "22") + geom_point(size = 1.4, alpha = .85) +
  facet_wrap(~domain) + coord_equal() + scale_colour_manual(values = pal_grp) +
  labs(x = "Joint share, science (%)", y = "Joint share, other domain (%)", colour = NULL) + th
save(p7, "fig7_domains", 7.5, 3.8)
cat("figures written\n")
