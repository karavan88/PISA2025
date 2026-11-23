# IV learning -- figures for the manuscript. Reporting only: reads saved estimates, fits nothing.
# Look (second design, 2026-11-23, after the author found the first one weak): PT Sans; large circles with a white halo; intervals as
# soft rounded bars in a tint of the series colour, so the estimate carries the weight; two strong hues, blue and orange (checked for
# colour-blind separation), and ink for the mean of systems; hairline solid guides; shaded regions where a chart has two sides.
# Rules of the author kept throughout: every system is shown; the mean of systems is marked once per figure; markers are circles and
# the fill carries significance (full colour p < 0.05, pale p < 0.10, white not significant); how to read a figure is said in the
# caption. Figures are drawn at the size they have on the page (text width 6.3 in).
#   fig1_gap_years              each system's gap between the high and the low socio-economic third, in school years      (step 6)
#   fig2_equal_gain             yearly gain of the high third against the low third, with the line of equal gains         (step 4)
#   fig3_school_spread          between-school spread of the gain, every system, by whether the two grades share a level  (step 10)
#   fig4_gain_by_percentile     mean yearly gain at five percentiles over a faint line per system; with skills held fixed (steps 9, 15)
#   fig5_percentile_by_system   the same profile for every system, one small panel each                                   (step 9)
#   fig6_skills                 yearly change in each socio-emotional skill and in achievement, every system              (steps 1, 6b, 13)
# Rscript 06_scoping/13_iv_learning/01_code/07_figures.R      (FIG_OUT, PAPER_RUN and STEPn_DIR override the defaults)
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(ggrepel); library(patchwork) })
PROJECT <- "06_scoping/13_iv_learning"
source(file.path(PROJECT, "01_code/sample_rules.R")); source(file.path(PROJECT, "01_code/run_of_record.R"))
FIG <- Sys.getenv("FIG_OUT", file.path(PROJECT, "04_output/figures")); dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(n, f) { d <- fread(file.path(step_dir(n), f)); if ("CNT" %in% names(d)) stopifnot(!any(d$CNT %in% EXCLUDE)); d }

# ---- look ----
FAM <- { f <- if (requireNamespace("systemfonts", quietly = TRUE)) systemfonts::system_fonts()$family else character(0); if ("PT Sans" %in% f) "PT Sans" else "sans" }
BLUE <- "#1E5AA8"; BLUE_P <- "#A9C4E6"; BLUE_T <- "#C9DAEF"; BLUE_W <- "#EEF3FA"          # series, pale fill (p < 0.10), interval bar, region wash
ORAN <- "#D9601A"; ORAN_P <- "#F2BF9C"; ORAN_T <- "#F6D3BA"; ORAN_W <- "#FDF2E9"
GREY <- "#7C8790"; GREY_P <- "#C9CFD5"; GREY_T <- "#DDE1E5"
INK <- "#16191D"; MUTE <- "#5F6B76"; GRID <- "#E3E7EC"; BAND <- "#F4F6F8"
BASE <- 9; TXT <- 2.95                                      # axis text in points; annotations in mm (about 8.4 pt)
theme_set(theme_minimal(base_size = BASE, base_family = FAM) + theme(
  panel.grid = element_blank(), axis.line = element_line(linewidth = .35, colour = INK), axis.ticks = element_line(linewidth = .35, colour = INK), axis.ticks.length = unit(3, "pt"),
  axis.title = element_text(size = BASE, colour = INK), axis.title.x = element_text(margin = margin(t = 5)), axis.title.y = element_text(margin = margin(r = 5)),
  axis.text = element_text(size = BASE - .5, colour = INK), plot.title = element_text(size = BASE + 1, face = "bold", colour = INK, margin = margin(b = 5)), plot.title.position = "plot",
  legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = BASE - .5, colour = INK), legend.key.size = unit(11, "pt"), legend.spacing.x = unit(3, "pt"),
  legend.margin = margin(0, 0, 0, 0), legend.box.margin = margin(0, 0, 0, 0), plot.margin = margin(5, 9, 3, 5)))
LEV <- c("p < 0.05", "p < 0.10", "not significant")
sig <- function(z) factor(fifelse(abs(z) > qnorm(.975), LEV[1], fifelse(abs(z) > qnorm(.95), LEV[2], LEV[3])), LEV)
sigp <- function(p) factor(fifelse(p < .05, LEV[1], fifelse(p < .10, LEV[2], LEV[3])), LEV)
shade <- function(s, full, pale) fifelse(s == LEV[1], full, fifelse(s == LEV[2], pale, "white"))                                     # the fill rule, for one hue
fill_sig <- function(full = BLUE, pale = BLUE_P, size = 3) list(scale_fill_manual(values = setNames(c(full, pale, "white"), LEV), drop = FALSE),
  guides(fill = guide_legend(override.aes = list(shape = 21, size = size, stroke = .7, colour = full, alpha = 1))))
key_sig <- function(size = 3) list(geom_point(data = data.frame(s = factor(LEV, LEV)), aes(x = -Inf, y = -Inf, fill = s), shape = 21, alpha = 0, inherit.aes = FALSE),   # a neutral key when hues vary
  scale_fill_manual(values = setNames(c(MUTE, GREY_P, "white"), LEV), drop = FALSE), guides(fill = guide_legend(order = 1, override.aes = list(shape = 21, size = size, stroke = .7, colour = MUTE, alpha = 1))))
halo <- function(size, ...) geom_point(shape = 16, colour = "white", size = size + 1.1, ...)                                          # white ring under a marker
rows <- function() theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), panel.grid.major.y = element_line(linewidth = .25, colour = GRID))   # ranked dot plots
MINUS <- function(x) sub("-", "\u2212", format(x, trim = TRUE, drop0trailing = TRUE), fixed = TRUE)                                   # a true minus sign on the axes
short <- function(x) { x <- sub(" \\(China\\)$", "", x); x[x == "B-S-J-Z"] <- "B-S-J-Z (China)"; x[x == "Palestinian Authority"] <- "Palestine"; x[x == "United Arab Emirates"] <- "U.A. Emirates"
  x[x == "Brunei Darussalam"] <- "Brunei"; x[x == "Dominican Republic"] <- "Dominican Rep."; x }
save_fig <- function(p, name, w, h) { for (ext in c("pdf", "png")) ggsave(file.path(FIG, paste0(name, ".", ext)), p, width = w, height = h, dpi = 400, device = if (ext == "pdf") cairo_pdf else "png", bg = "white")
  message(sprintf("wrote %s (%.1f x %.1f in)", name, w, h)) }
unlink(file.path(FIG, c("fig5_skills.pdf", "fig5_skills.png")))                                                                       # name used by the first design

# ---- figure 1: the gap in school years ----
sy <- rd(6, "gap_years_sys.csv")[!is.na(years3)]; sm <- rd(6, "gap_years_summary.csv")[gap == "gap3"]; G <- sm$yearly_gain; R <- sm$years
sy[, `:=`(lab = short(name), s = sig(gap3 / se_gap3), lo = years3 - qnorm(.975) * years3_se_system, hi = years3 + qnorm(.975) * years3_se_system)]
sy[, lab := factor(lab, lab[order(years3)])]
x1 <- c(min(0, floor(min(sy$lo) * 2) / 2), ceiling(max(sy$hi) * 2) / 2)
p1 <- ggplot(sy, aes(years3, lab)) +
  annotate("rect", xmin = seq(1, floor(x1[2]), 2), xmax = pmin(seq(1, floor(x1[2]), 2) + 1, x1[2]), ymin = -Inf, ymax = Inf, fill = BAND) +     # every second school year shaded
  geom_vline(xintercept = 0, colour = INK, linewidth = .35) +
  geom_vline(xintercept = R, colour = INK, linewidth = .6) +
  geom_segment(aes(x = lo, xend = hi, yend = lab), colour = BLUE_T, linewidth = 2.3, lineend = "round") +
  halo(2.9) + geom_point(aes(fill = s), shape = 21, colour = BLUE, size = 2.9, stroke = .7, show.legend = TRUE) + fill_sig() +
  annotate("label", x = R + .12, y = levels(sy$lab)[2], label = sprintf("Mean of systems: %.1f school years", R), hjust = 0, size = TXT, family = FAM, fontface = "bold", colour = INK, fill = "white", border.colour = NA, label.padding = unit(2, "pt")) +
  scale_x_continuous(breaks = 0:8, labels = MINUS, limits = x1, expand = expansion(mult = c(.01, .01)), sec.axis = sec_axis(~ . * G, name = "Gap in PISA points", breaks = seq(0, 140, 20))) +
  labs(x = "Gap between the high and the low third, in school years", y = NULL) + rows() + theme(panel.grid.major.y = element_blank(), axis.line.x.top = element_line(linewidth = .35, colour = INK))
save_fig(p1, "fig1_gap_years", 6.3, 6.6)

# ---- figure 2: equal gains ----
g <- rd(4, "ses_gain_sys.csv")[spec == "thirds" & outcome == "ACH" & term %in% c("gamma", "gamma:high")]
w <- dcast(g, CNT ~ term, value.var = c("est", "se")); setnames(w, c("CNT", "low", "diff", "se_low", "se_diff"))
w <- merge(w, sy[, .(CNT, name)], by = "CNT"); w[, `:=`(high = low + diff, s = sig(diff / se_diff), lab = short(name), up = diff > 0)]
w[, `:=`(col = fifelse(up, BLUE, ORAN), fl = fifelse(up, shade(s, BLUE, BLUE_P), shade(s, ORAN, ORAN_P)))]
pl <- rd(4, "ses_gain_pool.csv")[set == "all with ESCS (Ukraine out)" & spec == "thirds" & outcome == "ACH"]
mx <- pl[term == "gamma", re_mean]; my <- mx + pl[term == "gamma:high", re_mean]
lim <- range(c(w$low, w$high)); lim <- lim + c(-.06, .06) * diff(lim); span <- diff(lim)
lb <- rbind(w[, .(low, high, lab, ps = 3.6)], data.table(low = mx, high = my, lab = "", ps = 8))                               # the empty label keeps names off the ring
p2 <- ggplot(w, aes(low, high)) +
  annotate("polygon", x = c(lim[1], lim[1], lim[2]), y = c(lim[1], lim[2], lim[2]), fill = BLUE_W) + annotate("polygon", x = c(lim[1], lim[2], lim[2]), y = c(lim[1], lim[1], lim[2]), fill = ORAN_W) +
  geom_abline(slope = 1, intercept = 0, colour = INK, linewidth = .45) +
  annotate("text", x = lim[1] + .03 * span, y = lim[2] - .03 * span, hjust = 0, vjust = 1, size = TXT, family = FAM, colour = INK, fontface = "bold", lineheight = .95,
           label = sprintf("A year adds more for the high third\n%d of %d systems", w[up == TRUE, .N], nrow(w))) +
  annotate("text", x = lim[2] - .03 * span, y = lim[1] + .03 * span, hjust = 1, vjust = 0, size = TXT, family = FAM, colour = INK, fontface = "bold", lineheight = .95,
           label = sprintf("A year adds more for the low third\n%d of %d systems", w[up == FALSE, .N], nrow(w))) +
  annotate("text", x = lim[2] - .035 * span, y = lim[2] - .085 * span, label = "equal gains", angle = 45, hjust = 1, size = TXT, family = FAM, colour = INK, fontface = "italic") +
  geom_text_repel(data = lb, aes(label = lab, point.size = I(ps)), size = 2.45, colour = INK, family = FAM, segment.size = .2, segment.colour = MUTE, min.segment.length = .3, box.padding = .22,
                  force = 2.5, force_pull = .6, max.iter = 40000, max.time = 3, max.overlaps = Inf, seed = 4) +
  halo(3) + geom_point(aes(fill = I(fl), colour = I(col)), shape = 21, size = 3, stroke = .7) + key_sig() +
  geom_point(data = data.frame(low = mx, high = my), aes(shape = "Mean of systems"), size = 6.5, stroke = 1.3, colour = INK, fill = NA) +
  scale_shape_manual(values = c("Mean of systems" = 21), guide = guide_legend(order = 2, override.aes = list(size = 4, stroke = 1.1))) +
  scale_x_continuous(labels = MINUS) + scale_y_continuous(labels = MINUS) + coord_equal(xlim = lim, ylim = lim, expand = FALSE) +
  labs(x = "Yearly gain of the low third, PISA points", y = "Yearly gain of the high third, PISA points")
save_fig(p2, "fig2_equal_gain", 5.6, 5.9)

# ---- figure 3: how much schools of one system differ in what a year adds ----
sp <- rd(10, "school_spread_sys.csv"); so <- rd(10, "school_spread_overall.csv")
sp[, `:=`(lab = short(name), s = sigp(p_perm))]; sp[, lab := factor(lab, unique(lab[order(sd, sd_hi)]))]
xmax <- max(sp$sd_hi) * 1.02; same_sd <- so[set == "two grades in the same level of education", sd]
one3 <- function(d, ttl, mark = NA, full = BLUE, pale = BLUE_P, tint = BLUE_T) { g <- ggplot(d, aes(sd, lab)) + geom_vline(xintercept = 0, colour = INK, linewidth = .35)
  if (!is.na(mark)) g <- g + geom_vline(xintercept = mark, colour = INK, linewidth = .6)
  g <- g + geom_segment(aes(x = sd_lo, xend = sd_hi, yend = lab), colour = tint, linewidth = 2.3, lineend = "round") +
    halo(2.9) + geom_point(aes(fill = s), shape = 21, colour = full, size = 2.9, stroke = .7, show.legend = TRUE) + fill_sig(full, pale)
  if (!is.na(mark)) g <- g + annotate("label", x = mark + .8, y = levels(droplevels(d$lab))[1], label = sprintf("All schools of these systems: %.0f points", mark), hjust = 0, size = TXT, family = FAM, fontface = "bold", colour = INK, fill = "white", border.colour = NA, label.padding = unit(2, "pt"))
  g + scale_x_continuous(expand = expansion(mult = c(.012, .02))) + coord_cartesian(xlim = c(0, xmax)) + labs(title = ttl, x = NULL, y = NULL) + rows() + theme(panel.grid.major.y = element_blank()) }
p3 <- (one3(sp[same_level == TRUE], "A. Both grades in the same level of education", same_sd) + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.line.x = element_blank())) /
      (one3(sp[same_level == FALSE], "B. Upper grade in the next level of education", full = GREY, pale = GREY_P, tint = GREY_T) + guides(fill = "none") + labs(x = "Between-school standard deviation of the gain, PISA points")) +
  plot_layout(heights = c(sp[same_level == TRUE, .N], sp[same_level == FALSE, .N]), guides = "collect") & theme(legend.position = "bottom")
save_fig(p3, "fig3_school_spread", 6.3, 6.3)

# ---- figures 4 and 5: the yearly gain along the achievement distribution ----
num_q <- function(d) d[, q := as.numeric(sub(".*_", "", term))]
qs <- num_q(rd(9, "quantile_iv_sys.csv")[term %like% "^gamma_[0-9]+$" & usable == TRUE])
qp <- num_q(rd(9, "quantile_iv_pool.csv")[set == "all (Ukraine out)" & term %like% "^gamma_[0-9]+$"])
qp[, `:=`(lo = re_mean - qnorm(.975) * re_se, hi = re_mean + qnorm(.975) * re_se, s = sig(re_mean / re_se))]
hp <- num_q(rd(15, "quantile_iv_skills_pool.csv")[set == "all (Ukraine out)" & term %like% "^(base|held)_[0-9]+$"])
MOD <- c("As estimated", "Index of learning skills held fixed")
hp[, model := factor(fifelse(term %like% "^base", MOD[1], MOD[2]), MOD)]
hp[, `:=`(lo = re_mean - qnorm(.975) * re_se, hi = re_mean + qnorm(.975) * re_se, xq = q + fifelse(model == MOD[1], -1.6, 1.6), s = sig(re_mean / re_se))]
hp[, `:=`(col = fifelse(model == MOD[1], BLUE, ORAN), fl = fifelse(model == MOD[1], shade(s, BLUE, BLUE_P), shade(s, ORAN, ORAN_P)), tint = fifelse(model == MOD[1], BLUE_T, ORAN_T))]
YM <- c(0, ceiling(max(qp$hi, hp$hi) / 5) * 5); XQ <- scale_x_continuous(breaks = c(10, 25, 50, 75, 90), limits = c(4, 96), expand = c(0, 0))
YG <- list(geom_hline(yintercept = seq(10, YM[2], 10), colour = GRID, linewidth = .25), scale_y_continuous(breaks = seq(0, YM[2], 10), limits = YM, expand = c(0, 0)))
YA <- c(floor(min(qs$est) / 5) * 5, ceiling(max(qs$est) / 5) * 5)                                                               # panel A holds every system's line, so its scale is wider than panel B's
pa <- ggplot(qp, aes(q, re_mean)) + geom_hline(yintercept = seq(20, YA[2], 20), colour = GRID, linewidth = .25) + geom_hline(yintercept = 0, colour = MUTE, linewidth = .3) +
  geom_line(data = qs, aes(y = est, group = CNT), colour = "#7F95B2", alpha = .42, linewidth = .35, lineend = "round") +                  # one faint line per system, behind the mean
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = BLUE_T, alpha = .6) + geom_line(colour = BLUE, linewidth = 1.2, lineend = "round") +
  halo(3.4) + geom_point(aes(fill = s), shape = 21, colour = BLUE, size = 3.4, stroke = .75, show.legend = TRUE) + fill_sig(size = 3) +
  geom_label(aes(y = hi + 3.6, label = sprintf("%.1f", re_mean)), size = TXT, family = FAM, colour = INK, fontface = "bold", fill = "white", alpha = .92, border.colour = NA, label.padding = unit(1.4, "pt")) +
  scale_y_continuous(breaks = seq(-20, 60, 20), labels = MINUS, limits = YA, expand = c(0, 0)) +
  XQ + labs(title = "A. Mean of systems and every system", x = "Percentile of achievement", y = "Yearly gain, PISA points")
pb <- ggplot(hp, aes(xq, re_mean)) + YG +
  geom_segment(aes(xend = xq, y = lo, yend = hi, colour = I(tint)), linewidth = 2.3, lineend = "round", show.legend = FALSE) + geom_line(aes(colour = model), linewidth = .9, lineend = "round", key_glyph = "path") +
  halo(3, show.legend = FALSE) + geom_point(aes(fill = I(fl), colour = I(col)), shape = 21, size = 3, stroke = .7, show.legend = FALSE) +
  scale_colour_manual(values = setNames(c(BLUE, ORAN), MOD)) + XQ + labs(title = "B. With skills held fixed", x = "Percentile of achievement", y = NULL) +
  theme(legend.position = c(.03, .99), legend.justification = c(0, 1), legend.direction = "vertical", legend.key.width = unit(20, "pt"), legend.background = element_blank())
p4 <- (pa | pb) + plot_layout(guides = "keep")
save_fig(p4, "fig4_gain_by_percentile", 6.3, 3.6)

# every system: one small panel each, ordered from the steepest rise to the steepest fall
c75 <- rd(9, "quantile_iv_sys.csv")[term == "gamma_75_25" & usable == TRUE, .(CNT, c75 = est)]
ord <- merge(qs[, .(slope = if (.N > 1) coef(lm(est ~ q))[2] * 50 else NA_real_), by = CNT], c75, by = "CNT", all.x = TRUE)[, d := fifelse(is.na(c75), slope, c75)]
nmap <- fread("03_outputs/04_entry_rules/entry_rules.csv")[, .(CNT, name)]
qs <- merge(merge(qs, ord[, .(CNT, d)], by = "CNT"), nmap, by = "CNT")
DIR <- c("Gain rises between the 25th and the 75th percentile", "Gain falls")
qs[, `:=`(lo = est - qnorm(.975) * se, hi = est + qnorm(.975) * se, s = sig(est / se), dir = factor(fifelse(d > 0, DIR[1], DIR[2]), DIR))]
qs[, `:=`(col = fifelse(d > 0, BLUE, ORAN), fl = fifelse(d > 0, shade(s, BLUE, BLUE_P), shade(s, ORAN, ORAN_P)), panel = factor(short(name), unique(short(name)[order(-d)])))]
YS <- c(-25, 60)
p5 <- ggplot(qs, aes(q, est)) +
  geom_hline(yintercept = c(20, 40), colour = "white", linewidth = .5) + geom_hline(yintercept = 0, colour = INK, linewidth = .3) +
  geom_ribbon(aes(ymin = pmax(lo, YS[1]), ymax = pmin(hi, YS[2]), fill = I(fifelse(d > 0, BLUE_T, ORAN_T)), group = CNT), alpha = .6, show.legend = FALSE) +
  geom_line(data = qp[, .(q, re_mean)], aes(y = re_mean, linetype = "Mean of systems"), colour = INK, linewidth = .4, key_glyph = "path") +
  geom_line(aes(colour = dir, group = CNT), linewidth = .8, lineend = "round", key_glyph = "path") +
  geom_point(shape = 16, colour = "white", size = 2.5, show.legend = FALSE) + geom_point(aes(fill = I(fl), colour = I(col)), shape = 21, size = 1.7, stroke = .55, show.legend = FALSE) + key_sig(2.4) +
  facet_wrap(~ panel, ncol = 6) + scale_colour_manual(values = setNames(c(BLUE, ORAN), DIR), drop = FALSE, guide = guide_legend(order = 2, override.aes = list(linewidth = 1))) +
  scale_linetype_manual(values = c("Mean of systems" = "solid"), guide = guide_legend(order = 3, override.aes = list(colour = INK, linewidth = .6))) +
  scale_x_continuous(breaks = c(10, 50, 90), limits = c(3, 97), expand = c(0, 0)) + scale_y_continuous(breaks = c(0, 20, 40), labels = MINUS) + coord_cartesian(ylim = YS, expand = FALSE) +
  labs(x = "Percentile of achievement", y = "Yearly gain, PISA points") +
  theme(panel.background = element_rect(fill = BAND, colour = NA), panel.spacing.x = unit(7, "pt"), panel.spacing.y = unit(5, "pt"), axis.line = element_blank(), axis.ticks = element_line(linewidth = .25, colour = MUTE), axis.ticks.length = unit(2, "pt"),
        axis.text = element_text(size = BASE - 2, colour = MUTE), strip.text = element_text(size = BASE - 1, face = "bold", colour = INK, hjust = 0, margin = margin(2, 0, 2.5, 1)),
        legend.box = "vertical", legend.box.just = "center", legend.spacing.y = unit(0, "pt"), legend.key.width = unit(16, "pt"))
save_fig(p5, "fig5_percentile_by_system", 6.3, 7.9)

# ---- figure 6: what a year adds to skills, next to achievement ----
NM <- c(ACH = "Achievement", CURIO_z = "Curiosity", ENPROBS_z = "Enjoyment of problem-solving", GOALSET_z = "Goal setting", COGABIL_z = "Cognitive adaptability", SELFREG_z = "Self-regulation",
        PERSEV_z = "Perseverance", BELONG_z = "Sense of belonging", growth = "Growth mindset", LEARN = "Index of learning skills")
sc <- rd("6b", "scale_sys.csv")[, .(CNT, sd_ach)]
ach <- merge(rd(1, "grade_gain_sys.csv")[spec == "base" & outcome == "ACH" & term == "gamma"], sc, by = "CNT")[, .(CNT, var = "ACH", est = est / sd_ach, se = se / sd_ach)]
k <- rbind(ach, rd(13, "skills_sys.csv")[part == "outcome" & spec == "base" & term == "gamma", .(CNT, var, est, se)])
pk <- rbind(rd(13, "skills_pool.csv")[set == "all (Ukraine out)" & part == "outcome" & spec == "base" & term == "gamma", .(var, re_mean, re_se)],
            rd(1, "grade_gain_pool.csv")[set == "all (Ukraine out)" & spec == "base" & outcome == "ACH" & term == "gamma", .(var = "ACH", re_mean = re_mean / mean(sc$sd_ach), re_se = re_se / mean(sc$sd_ach))])
ord6 <- c("ACH", "LEARN", pk[!var %in% c("ACH", "LEARN", "growth")][order(-re_mean), var], "growth"); NR <- length(ord6)
k[, `:=`(row = factor(NM[var], rev(NM[ord6])), s = sig(est / se), a = var == "ACH")]; pk[, `:=`(row = factor(NM[var], rev(NM[ord6])), lo = re_mean - qnorm(.975) * re_se, hi = re_mean + qnorm(.975) * re_se)]
k[, `:=`(col = fifelse(a, ORAN, BLUE), fl = fifelse(a, shade(s, ORAN, ORAN_P), shade(s, BLUE, BLUE_P)))]
set.seed(7); k[, yj := as.numeric(row) + runif(.N, -.27, .27)]
XL <- c(-.3, .75); stopifnot(k[est < XL[1] | est > XL[2], .N] == 0)
p6 <- ggplot(k, aes(est, yj)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = seq(1, NR, 2) - .5, ymax = seq(1, NR, 2) + .5, fill = BAND) +
  geom_vline(xintercept = 0, colour = INK, linewidth = .35) +
  geom_point(shape = 16, colour = "white", size = 2.9) + geom_point(aes(fill = I(fl), colour = I(col)), shape = 21, size = 2.1, stroke = .55) + key_sig() +
  geom_segment(data = pk, aes(x = lo, xend = hi, y = as.numeric(row), yend = as.numeric(row)), colour = INK, linewidth = 1, lineend = "round") +
  geom_point(data = pk, aes(re_mean, as.numeric(row), shape = "Mean of systems, with 95% interval"), size = 5, stroke = 1.3, colour = INK, fill = "white") +
  scale_shape_manual(values = c("Mean of systems, with 95% interval" = 21), guide = guide_legend(order = 2, override.aes = list(size = 3.8, stroke = 1.1))) +
  scale_y_continuous(breaks = seq_len(NR), labels = rev(NM[ord6]), expand = expansion(add = c(0, .12))) + scale_x_continuous(breaks = seq(-.2, .7, .1), labels = MINUS, limits = XL, expand = c(0, 0)) +
  labs(x = "Change over one year, in standard deviations", y = NULL) + theme(axis.line.y = element_blank(), axis.ticks.y = element_blank())
save_fig(p6, "fig6_skills", 6.3, 4.9)
