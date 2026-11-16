# Country-estimate figures for the paper draft (cost_of_resilience_paper.qmd). Reads the approved snapshot only; estimates nothing.
# Every figure shows every system (a labelled point, a row, a line or a dot per system) and marks the mean of systems once.
# The figures carry no title, subtitle or notes: these are in the figure captions of the manuscript. Significance is shown at two
# levels throughout: filled circle p < 0.05, filled triangle p < 0.10, open circle not significant (two-sided, unadjusted).
# Main text: fig_p1_means, fig_p2_benchmark, fig_p3_skills, fig_p8_regions, fig_p4_answers, fig_p5_forest. Appendix: fig_p6_ranking, fig_p7_interactions.
# From the status x achievement matrix (steps 16, 17; not yet in the manuscript): fig_p10_corner_groups, fig_p11_resilient_by_region (the new Figure 2).
# Output: 05_papers/03_resilience_cost/02_results/figs/fig_p*.pdf     Run from the repository root: Rscript 05_papers/03_resilience_cost/01_code/11_figures_paper.R
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork); library(ggrepel) })
IN <- "05_papers/03_resilience_cost/02_results/snapshot/"; FIG <- "05_papers/03_resilience_cost/02_results/figs/"; dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(f) fread(paste0(IN, f))
gs <- rd("gap_sys.csv"); gp <- rd("gap_pool.csv"); rs <- rd("rs_sys.csv"); rp <- rd("rs_pool.csv")
fs <- rd("foc_sys.csv"); fp <- rd("foc_pool.csv"); ms <- rd("mech_sys.csv"); mp <- rd("mech_pool.csv")
bs <- rd("bench_sys.csv"); bp <- rd("bench_pool.csv"); fo <- rd("forest_est.csv"); rg <- rd("region_pool.csv")

source("05_papers/03_resilience_cost/01_code/system_names.R")                     # NAMES: system names by PISA code
for (x in list(gs, rs, fs, ms, bs)) { stopifnot(!"QUA" %in% x$CNT); miss <- setdiff(unique(x$CNT), names(NAMES)); if (length(miss)) stop("no name for: ", paste(miss, collapse = " ")) }

# ------------------------------------------------------------------ look: the paper's own (serif lettering; purple, orange, green; black square for the mean)
cR <- "#6A3D9A"   # resilient students, and the side of a plot where they are worse off
cP <- "#D9730D"   # the comparison group
cG <- "#1B7837"   # a third group
cK <- "#1A1A1A"; cT <- "#555555"; cL <- "#A3A3A3"; cGrid <- "#ECECEC"; tintR <- "#F2EDF8"; cBand <- "#E4E4E4"
FAM <- { f <- systemfonts::system_fonts()$family; if ("Charter" %in% f) "Charter" else if ("PT Serif" %in% f) "PT Serif" else "serif" }
theme_set(theme_minimal(base_size = 9, base_family = FAM) +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = cGrid, linewidth = .3),
        legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 8, colour = cK), legend.margin = margin(0, 0, 0, 0), legend.key.height = unit(9, "pt"),
        axis.text = element_text(colour = "#333333", size = 7.6), axis.title = element_text(size = 8.4, colour = cK),
        plot.tag = element_text(size = 10, face = "bold", colour = cK), plot.tag.position = c(0, 1), plot.margin = margin(8, 8, 4, 6)))
# Written to a temporary file and moved into place: on 15 November 2026 the PDF device twice left an existing file unchanged without an error.
save <- function(p, name, w = 7.4, h = 8.4) { fn <- paste0(FIG, name, ".pdf"); tmp <- paste0(FIG, ".tmp_", name, ".pdf"); unlink(tmp)
  ggsave(tmp, p, width = w, height = h, device = cairo_pdf); if (!file.exists(tmp) || file.size(tmp) == 0 || !file.rename(tmp, fn)) stop("figure not written: ", name); message("wrote ", name) }
EV <- c("p < 0.05", "p < 0.10", "Not significant")
ev <- function(est, se) { z <- abs(est / se); factor(ifelse(z > 1.96, EV[1], ifelse(z > 1.645, EV[2], EV[3])), levels = EV) }
ev_shape <- scale_shape_manual(values = setNames(c(16, 17, 1), EV), drop = FALSE, name = NULL, guide = guide_legend(order = 1, override.aes = list(size = 2.4, colour = cK, alpha = 1)))
MEAN <- "Mean of systems"
mean_pt <- function(d, mapping, size = 3) geom_point(data = d, mapping = mapping, shape = 22, fill = cK, colour = "white", size = size, stroke = .6)   # black square: the mean of systems
mean_key <- function() list(geom_point(data = data.frame(x = NA_real_, y = NA_real_, k = MEAN), aes(x, y, alpha = k), shape = 22, fill = cK, colour = "white", size = 3, na.rm = TRUE),
                            scale_alpha_manual(values = setNames(1, MEAN), name = NULL, guide = guide_legend(order = 9, override.aes = list(shape = 22, fill = cK, colour = "white", size = 3))))
wide <- function(sys, terms) { z <- dcast(sys[term %in% terms & !is.na(est)], CNT ~ term, value.var = "est"); z <- z[complete.cases(z)]; setnames(z, terms, names(terms)); z }
summ <- function(pool, terms, mult = 1) { p <- pool[match(terms, term)]; data.table(x = p$re_mean[1] * mult, y = p$re_mean[2] * mult) }

# ------------------------------------------------------------------ scatter: one labelled point per system against the line of equality
# d: CNT, x, y. Points under the line (y < x) are drawn in the resilient colour. s: output of summ(). tag: panel letter.
scat <- function(d, s, lim, xlab, ylab, tag, below, breaks = waiver(), count = "%d of %d systems\nbelow the line") {
  d <- copy(d)[, side := ifelse(y < x, "below", "above")]; stopifnot(d$x >= lim[1], d$x <= lim[2], d$y >= lim[1], d$y <= lim[2]); span <- diff(lim)
  ggplot(d, aes(x, y)) +
    annotate("polygon", x = c(lim[1], lim[2], lim[2]), y = c(lim[1], lim[1], lim[2]), fill = tintR) +
    geom_abline(slope = 1, intercept = 0, colour = cK, linewidth = .35) +
    geom_point(aes(colour = side), size = 1.5, alpha = .9, show.legend = FALSE) +
    geom_text_repel(aes(label = CNT, colour = side), size = 1.95, family = FAM, segment.size = .15, segment.colour = cL, min.segment.length = .15, box.padding = .1, point.padding = .08,
                    max.overlaps = Inf, max.time = 3, max.iter = 60000, seed = 7, show.legend = FALSE) +
    mean_pt(s, aes(x, y)) + mean_key() +
    annotate("text", x = lim[2] - .03 * span, y = lim[1] + .04 * span, label = below, hjust = 1, vjust = 0, size = 2.6, family = FAM, colour = cR, lineheight = .95, fontface = "bold") +
    annotate("text", x = lim[1] + .03 * span, y = lim[2] - .04 * span, label = sprintf(count, d[side == "below", .N], nrow(d)), hjust = 0, vjust = 1, size = 2.6, family = FAM, colour = cK, lineheight = .95) +
    scale_colour_manual(values = c(below = cR, above = cP)) + scale_x_continuous(limits = lim, breaks = breaks, expand = c(0, 0)) + scale_y_continuous(limits = lim, breaks = breaks, expand = c(0, 0)) +
    coord_fixed() + labs(x = xlab, y = ylab, tag = tag)
}
pair <- function(a, b, name, h = 4.1, widths = c(1, 1)) save((a | b) + plot_layout(guides = "collect", widths = widths) & theme(legend.position = "bottom"), name, h = h)

# ------------------------------------------------------------------ P1: mean life satisfaction against two benchmarks
m <- wide(rs, c(R = "mean:R:LS", PL = "mean:PL:LS", AT = "mean:AT:LS")); lim1 <- c(5, 9.4)
p1a <- scat(m[, .(CNT, x = PL, y = R)], summ(rp, c("mean:PL:LS", "mean:R:LS")), lim1, breaks = 5:9, tag = "A",
  xlab = "Disadvantaged low achievers (mean, 0-10)", ylab = "Resilient students (mean, 0-10)", below = "Resilient students\nless satisfied")
p1b <- scat(m[, .(CNT, x = AT, y = R)], summ(rp, c("mean:AT:LS", "mean:R:LS")), lim1, breaks = 5:9, tag = "B",
  xlab = "Advantaged top achievers (mean, 0-10)", ylab = "Resilient students (mean, 0-10)", below = "Resilient students\nless satisfied")
pair(p1a, p1b, "fig_p1_means")

# ------------------------------------------------------------------ P2: every group against the most satisfied group, system by system
# Three columns (resilient students, disadvantaged low achievers, advantaged low achievers), each the difference from advantaged top
# achievers in one within-school model with sex, age and grade. Systems are ranked by the estimate for resilient students.
grp <- c(`cell:R:demo` = "Resilient students", `cell:PL:demo` = "Disadvantaged low achievers", `cell:AL:demo` = "Advantaged low achievers"); lim2 <- c(-1.25, 1)
z2 <- bs[term %in% names(grp) & !is.na(est) & !is.na(se) & se > 0]; z2 <- z2[CNT %in% z2[, .N, by = CNT][N == 3, CNT]]
ord <- z2[term == "cell:R:demo"][order(-est), CNT]; n2 <- length(ord)
z2[, `:=`(y = match(CNT, ord), g = factor(grp[term], levels = unname(grp)), lo = pmax(est - 1.96 * se, lim2[1]), hi = pmin(est + 1.96 * se, lim2[2]), Evidence = ev(est, se))]
stopifnot(z2$est > lim2[1], z2$est < lim2[2])
s2 <- bp[match(names(grp), term), .(g = factor(grp[term], levels = unname(grp)), est = re_mean, lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se, y = -.8)]
n2sig <- z2[, .(lab = sprintf("lower at p < 0.05 in %d, at p < 0.10 in %d of %d", sum(est / se < -1.96), sum(est / se < -1.645), .N)), by = g]
p2 <- ggplot(z2, aes(est, y)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) + geom_hline(yintercept = .1, colour = cL, linewidth = .3) +
  geom_segment(aes(x = lo, xend = hi, yend = y, colour = g), linewidth = .4, alpha = .5) + geom_point(aes(colour = g, shape = Evidence), size = 1.6, stroke = .45) + ev_shape +
  geom_segment(data = s2, aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(s2, aes(est, y)) +
  geom_text(data = n2sig, aes(x = lim2[2], y = n2 + 1.6, label = lab), hjust = 1, size = 2.35, family = FAM, colour = cT) +
  scale_colour_manual(values = setNames(c(cR, cP, cG), unname(grp)), guide = "none") +
  scale_y_continuous(breaks = c(seq_len(n2), -.8), labels = c(sprintf("%s (%s)", NAMES[ord], ord), sprintf("Mean of %d systems", n2)), limits = c(-1.6, n2 + 2.4), expand = c(0, 0)) +
  scale_x_continuous(limits = lim2, breaks = seq(-1, 1, .5)) + facet_grid(. ~ g) +
  labs(x = "Difference from advantaged top achievers (SD of life satisfaction)", y = NULL) +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.6), strip.text = element_text(size = 8.4, face = "bold", colour = cK), panel.spacing = unit(10, "pt"))
save(p2, "fig_p2_benchmark", h = 8.9)

# ------------------------------------------------------------------ P3: what the skill index does to the gap; how far systems differ
g <- wide(gs, c(demo = "lad:demo", sei = "lad:sei")); lim3 <- c(floor(min(g$demo, g$sei) * 10 - .5), ceiling(max(g$demo, g$sei) * 10 + .5)) / 10
p3a <- scat(g[, .(CNT, x = demo, y = sei)], summ(gp, c("lad:demo", "lad:sei")), lim3, breaks = seq(-1, 1, .25), tag = "A",
  xlab = "Gap with sex, age and grade held fixed (SD)", ylab = "Gap with the skill index also held fixed (SD)", below = "Larger gap once\nskills are held fixed") +
  geom_hline(yintercept = 0, colour = cL, linewidth = .3, linetype = "22") + geom_vline(xintercept = 0, colour = cL, linewidth = .3, linetype = "22")
f <- gs[term == "lad:sei" & !is.na(est) & se > 0, .(CNT, est, se)]; pm <- gp[term == "lad:sei", re_mean]; f[, out := abs(est - pm) > 1.96 * se]
fun <- data.table(se = exp(seq(log(min(f$se) * .9), log(max(f$se) * 1.08), length.out = 80)))[, `:=`(lo = pm - 1.96 * se, hi = pm + 1.96 * se)]; xl <- c(-1.05, .8); stopifnot(f$est > xl[1], f$est < xl[2])
revlog <- scales::trans_new("revlog", function(x) -log10(x), function(x) 10^(-x), domain = c(1e-6, Inf))
p3b <- ggplot(f, aes(est, se)) +
  geom_ribbon(data = fun, aes(y = se, xmin = pmax(lo, xl[1]), xmax = pmin(hi, xl[2])), inherit.aes = FALSE, fill = "#F1F1F1") +
  geom_path(data = fun[lo > xl[1]], aes(lo, se), colour = cL, linewidth = .4) + geom_path(data = fun[hi < xl[2]], aes(hi, se), colour = cL, linewidth = .4) +
  geom_vline(xintercept = 0, colour = cL, linewidth = .3, linetype = "22") + geom_vline(xintercept = pm, colour = cK, linewidth = .35) +
  geom_point(aes(colour = out), size = 1.5, alpha = .9, show.legend = FALSE) +
  geom_text_repel(aes(label = CNT, colour = out), size = 1.95, family = FAM, segment.size = .15, segment.colour = cL, min.segment.length = .15, box.padding = .1, point.padding = .08, max.overlaps = Inf, max.time = 3, max.iter = 60000, seed = 7, show.legend = FALSE) +
  annotate("text", x = xl[1] + .04, y = min(fun$se) * 1.03, label = sprintf("%d of %d systems\ninside the funnel", f[out == FALSE, .N], nrow(f)), hjust = 0, vjust = 1, size = 2.6, family = FAM, colour = cK, lineheight = .95) +
  scale_colour_manual(values = c(`FALSE` = cP, `TRUE` = cR)) + scale_y_continuous(trans = revlog, breaks = c(.1, .15, .2, .3, .5, .75), limits = rev(range(fun$se)), expand = c(0, 0)) +
  scale_x_continuous(limits = xl, breaks = seq(-1, .5, .5), expand = c(0, 0)) +
  labs(x = "Gap with the skill index held fixed (SD)", y = "Standard error of the system estimate (log scale)", tag = "B") + theme(aspect.ratio = 1)
pair(p3a, p3b, "fig_p3_skills")

# ------------------------------------------------------------------ P4: where on the scale the gap lies
a <- fs[grepl("^ans:sei:[0-9]+$", term) & !is.na(est)][, k := as.integer(sub("ans:sei:", "", term))][, est := est * 100]
ap <- fp[grepl("^ans:sei:[0-9]+$", term)][, k := as.integer(sub("ans:sei:", "", term))][order(k)][, v := re_mean * 100]
p4a <- ggplot(a, aes(k, est)) + geom_hline(yintercept = 0, colour = cK, linewidth = .35) +
  geom_line(aes(group = CNT), colour = cR, alpha = .2, linewidth = .3) +
  geom_ribbon(data = ap, aes(k, ymin = (re_mean - 1.96 * re_se) * 100, ymax = (re_mean + 1.96 * re_se) * 100), inherit.aes = FALSE, fill = cK, alpha = .18) +
  geom_line(data = ap, aes(k, v), colour = cK, linewidth = .6) + mean_pt(ap, aes(k, v), size = 2.2) +
  scale_x_continuous(breaks = 0:10) + scale_y_continuous(breaks = seq(-40, 20, 10)) + coord_cartesian(ylim = c(-42, 22)) +
  labs(x = "Answer on the 0-10 item", y = "Difference in the share giving the answer (points)", tag = "A") + theme(panel.grid.major.x = element_blank())
t10 <- wide(rs, c(R = "mean:R:LS10", PL = "mean:PL:LS10"))[, `:=`(R = R * 100, PL = PL * 100)]
p4b <- scat(t10[, .(CNT, x = PL, y = R)], summ(rp, c("mean:PL:LS10", "mean:R:LS10"), 100), c(0, 68), breaks = seq(0, 60, 20), tag = "B",
  xlab = "Disadvantaged low achievers (%)", ylab = "Resilient students (%)", below = "Resilient students answer\n10 less often")
pair(p4a, p4b, "fig_p4_answers", widths = c(1.12, 1))

# ------------------------------------------------------------------ labels of the fourteen characteristics, in three blocks
MODS <- c(schESCS = "Schoolmates' status", schACH = "Schoolmates' achievement", female = "Female", uni = "Expects a degree",
          growth = "Growth mindset", EFFSCIE = "Science self-efficacy", BELONG = "Sense of belonging", JOYSCIE = "Enjoyment of science",
          PERSEV = "Perseverance", GOALSET = "Goal setting", COGABIL = "Cognitive adaptability", ENPROBS = "Enjoys problem-solving", SELFREG = "Self-regulated learning", CURIO = "Curiosity")
BLK <- setNames(c(rep("Context", 4), rep("Beliefs and attitudes", 4), rep("Socio-emotional skills", 6)), names(MODS)); BINM <- c("female", "uni", "growth")

# ------------------------------------------------------------------ P5: the causal forest -- the gap at each level of each characteristic
lv <- merge(fo[model == "fe" & block == "level", .(term, est, se)], fo[model == "fe" & block == "levelx", .(term, x = est)], by = "term")
lv[, c("m", "k") := tstrsplit(term, ":")][, `:=`(k = as.integer(k), lab = factor(MODS[m], levels = unname(MODS)), bin = m %in% BINM)]
stopifnot(!anyNA(lv$lab), setequal(unique(lv$m), names(MODS))); avg <- fo[model == "fe" & block == "ate" & term == "gap", est]
lv[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]; yl5 <- c(min(-.6, floor(min(lv$lo) * 10) / 10), max(.3, ceiling(max(lv$hi) * 10) / 10))
p5 <- ggplot(lv, aes(k, est)) + geom_hline(yintercept = 0, colour = cK, linewidth = .35) + geom_hline(yintercept = avg, colour = cK, linewidth = .5, linetype = "22") +
  geom_line(data = lv[bin == FALSE], colour = cR, linewidth = .45) + geom_linerange(aes(ymin = lo, ymax = hi), colour = cR, linewidth = .5, alpha = .6) +
  geom_point(shape = 21, fill = cR, colour = "white", size = 2, stroke = .4) +
  facet_wrap(~ lab, ncol = 4, scales = "free_x") + coord_cartesian(ylim = yl5) +
  scale_x_continuous(breaks = function(l) if (l[2] < 2) 0:1 else 1:5, labels = function(b) if (max(b) < 2) c("No", "Yes")[b + 1] else c("Lowest\nfifth", "2", "3", "4", "Highest\nfifth")[b], expand = expansion(add = .35)) +
  labs(x = NULL, y = "Gap (SD of life satisfaction)") +
  theme(panel.grid.major.x = element_blank(), strip.text = element_text(size = 8, face = "bold", colour = cK, hjust = 0), panel.spacing = unit(9, "pt"), axis.text.x = element_text(size = 6.6, lineheight = .9))
save(p5, "fig_p5_forest", h = 7.6)

# ------------------------------------------------------------------ P6 (appendix): the gap against disadvantaged low achievers in every system, ranked
rank_plot <- function(sys, pool, term_, name, lim, breaks) {
  z <- sys[term == term_ & !is.na(est) & !is.na(se) & se > 0][order(est)]; n <- nrow(z); n1 <- ceiling(n / 2); pl <- pool[term == term_]
  z[, `:=`(idx = .I, panel = ifelse(.I <= n1, 1L, 2L))][, y := n1 - ifelse(panel == 1L, idx, idx - n1) + 1]
  z[, `:=`(lo = pmax(est - 1.96 * se, lim[1]), hi = pmin(est + 1.96 * se, lim[2]), lab = sprintf("%s (%s)", NAMES[CNT], CNT), Evidence = ev(est, se))]
  stopifnot(z$est >= lim[1], z$est <= lim[2])
  srow <- data.table(est = pl$re_mean, lo = pl$re_mean - 1.96 * pl$re_se, hi = pl$re_mean + 1.96 * pl$re_se, lab = sprintf("Mean of %d systems", n), y = -.6)
  panels <- lapply(1:2, function(k) { d <- z[panel == k]; s <- if (k == 2) srow else srow[0]       # the mean closes the ranking, in the right panel only
    ggplot(d, aes(est, y)) +
      annotate("rect", xmin = pl$re_mean - 1.96 * pl$re_se, xmax = pl$re_mean + 1.96 * pl$re_se, ymin = -Inf, ymax = Inf, fill = cBand) +
      geom_vline(xintercept = 0, colour = cK, linewidth = .4) + geom_hline(yintercept = .2, colour = if (k == 2) cL else NA, linewidth = .3) +
      geom_segment(aes(x = lo, xend = hi, yend = y), colour = cR, linewidth = .45, alpha = .55) + geom_point(aes(shape = Evidence), colour = cR, size = 1.8, stroke = .45) + ev_shape +
      geom_segment(data = s, aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(s, aes(est, y)) +
      scale_y_continuous(breaks = c(d$y, s$y), labels = c(d$lab, s$lab), limits = c(-1.3, n1 + .6), expand = c(0, 0)) + scale_x_continuous(limits = lim, breaks = breaks) +
      labs(x = "Gap in SD of life satisfaction", y = NULL) + theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 7.3)) +
      (if (k == 2) guides(shape = "none")) })   # one legend for both panels
  save((panels[[1]] | panels[[2]]) + plot_layout(guides = "collect") & theme(legend.position = "bottom"), name, h = 7.8)
  invisible(list(n = n, neg = z[est < 0, .N]))
}
r6 <- rank_plot(gs, gp, "lad:sei", "fig_p6_ranking", lim = c(-1.1, 0.9), breaks = seq(-1, .5, .5))

# ------------------------------------------------------------------ P7 (appendix): the system-by-system interaction models, one panel per characteristic
mt <- setNames(paste0("mod:", names(MODS), ":topX"), names(MODS)); cap7 <- .75
z7 <- ms[term %in% mt & !is.na(est) & !is.na(se) & se > 0][, key := names(mt)[match(term, mt)]]
z7[, `:=`(lab = factor(MODS[key], levels = unname(MODS)), blk = BLK[key], Evidence = ev(est, se), prec = 1 / se, x = pmax(pmin(est, cap7), -cap7))]
set.seed(11); z7[, yj := runif(.N, -.36, .36)]                                   # spread within the panel; the vertical position carries no information
s7 <- mp[term %in% mt][, key := names(mt)[match(term, mt)]][, .(lab = factor(MODS[key], levels = unname(MODS)), blk = BLK[key], v = re_mean, lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se)]
ex7 <- z7[Evidence == EV[1]][order(-abs(est / se)), head(.SD, 3), by = key]
strip7 <- function(b, last) { g <- ggplot(z7[blk == b], aes(x, yj)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) +
    geom_point(aes(size = prec, shape = Evidence, colour = Evidence), stroke = .35, alpha = .8) + ev_shape +
    geom_text_repel(data = ex7[blk == b], aes(label = CNT), size = 1.9, family = FAM, colour = cK, segment.size = .15, segment.colour = cL, min.segment.length = 0, box.padding = .12, max.overlaps = Inf, seed = 3) +
    geom_segment(data = s7[blk == b], aes(x = lo, xend = hi, y = 0, yend = 0), colour = cK, linewidth = .9) + mean_pt(s7[blk == b], aes(v, 0)) + mean_key() +
    scale_colour_manual(values = setNames(c(cR, cR, "#9A9A9A"), EV), drop = FALSE, guide = "none") + scale_size_continuous(range = c(.5, 2.4), limits = range(z7$prec), guide = "none") +
    scale_y_continuous(limits = c(-.5, .5), breaks = NULL, expand = c(0, 0)) + scale_x_continuous(limits = c(-cap7, cap7) * 1.02, breaks = seq(-.75, .75, .25), expand = c(0, 0)) +
    facet_grid(lab ~ ., switch = "y") + labs(x = if (last) "Change in the gap (SD of life satisfaction)" else NULL, y = NULL, title = b) +
    theme(panel.grid.major.y = element_blank(), panel.background = element_rect(fill = "#F6F6F6", colour = NA), panel.spacing = unit(4, "pt"), strip.placement = "outside",
          strip.text.y.left = element_text(angle = 0, hjust = 1, size = 8, colour = cK), plot.title = element_text(size = 8.6, face = "bold", colour = cK, margin = margin(b = 3)))
  if (!last) g <- g + theme(axis.text.x = element_blank()); g }
BL <- unique(unname(BLK)); nb <- vapply(BL, function(b) uniqueN(z7[blk == b, key]), 1L)
save(Reduce(`/`, lapply(seq_along(BL), function(i) strip7(BL[i], i == length(BL)))) + plot_layout(heights = nb, guides = "collect") & theme(legend.position = "bottom"), "fig_p7_interactions", h = 8.4)

# ------------------------------------------------------------------ P8: pooled estimates by world region (step 15)
RT <- c(`gap|lad:sei` = "A. Against disadvantaged low achievers,\nskill index held fixed", `bench|cell:R:demo` = "B. Against advantaged top achievers")
z8 <- rg[paste(file, term, sep = "|") %in% names(RT)][, panel := factor(RT[paste(file, term, sep = "|")], levels = unname(RT))]
ordr <- z8[panel == levels(panel)[1] & region != "All systems"][order(-re_mean), region]; stopifnot(length(ordr) == uniqueN(z8[region != "All systems", region]))
z8[, `:=`(y = ifelse(region == "All systems", 0, match(region, ordr)), lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se, Evidence = ev(re_mean, re_se),
          lab = sprintf("%s (%d)", region, n_sys))]
labs8 <- z8[panel == levels(panel)[1]][order(y)]
p8 <- ggplot(z8[region != "All systems"], aes(re_mean, y)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) + geom_hline(yintercept = .5, colour = cL, linewidth = .3) +
  geom_segment(aes(x = lo, xend = hi, yend = y), colour = cR, linewidth = .55, alpha = .7) + geom_point(aes(shape = Evidence), colour = cR, size = 2.2, stroke = .5) + ev_shape +
  geom_segment(data = z8[region == "All systems"], aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(z8[region == "All systems"], aes(re_mean, y)) + mean_key() +
  scale_y_continuous(breaks = labs8$y, labels = sub("^All systems", "All systems", labs8$lab), expand = expansion(add = .6)) +
  facet_grid(. ~ panel) + labs(x = "Difference in life satisfaction (SD)", y = NULL) +
  theme(panel.grid.major.y = element_blank(), strip.text = element_text(size = 8.2, face = "bold", colour = cK, hjust = 0, lineheight = .95), panel.spacing = unit(14, "pt"), axis.text.y = element_text(size = 8))
save(p8, "fig_p8_regions", h = 3.6)

# ------------------------------------------------------------------ P9 (not in the manuscript): Figure 2 by system, grouped by region
source("05_papers/03_resilience_cost/01_code/regions.R")
P9 <- c(`gap|lad:sei` = "A. Against disadvantaged low achievers,\nskill index held fixed", `bench|cell:R:demo` = "B. Against advantaged top achievers")
z9 <- rbind(gs[term == "lad:sei", .(key = "gap|lad:sei", CNT, est, se)], bs[term == "cell:R:demo", .(key = "bench|cell:R:demo", CNT, est, se)])[!is.na(est) & se > 0]
z9 <- merge(z9, REGION_OF, by = "CNT"); stopifnot(!anyNA(z9$region)); lim9 <- c(-1.25, 1)
ordA <- z9[key == "gap|lad:sei"][order(region, -est)]                                  # within a region, systems ranked by panel A
r9 <- rg[paste(file, term, sep = "|") %in% names(P9) & region != "All systems", .(key = paste(file, term, sep = "|"), region, est = re_mean, se = re_se, n_sys)]
regs <- r9[key == "gap|lad:sei"][order(est), region]                                    # regions in the order of Figure 2
rows <- rbindlist(lapply(regs, function(r) rbind(data.table(region = r, CNT = ordA[region == r, CNT], what = "system"), data.table(region = r, CNT = NA_character_, what = "mean"))))
rows[, `:=`(regf = factor(region, levels = regs, labels = gsub(" and ", " and\n", regs)), y = rev(seq_len(.N)))]          # y unique across regions
d9 <- merge(z9, rows[what == "system", .(CNT, regf, y)], by = "CNT")
m9 <- merge(r9, rows[what == "mean", .(region, regf, y)], by = "region")
for (x in list(d9, m9)) x[, `:=`(panel = factor(P9[key], levels = unname(P9)), lo = pmax(est - 1.96 * se, lim9[1]), hi = pmin(est + 1.96 * se, lim9[2]), Evidence = ev(est, se))]
stopifnot(d9$est > lim9[1], d9$est < lim9[2])
labs9 <- rbind(d9[key == "gap|lad:sei", .(regf, y, lab = sprintf("%s (%s)", NAMES[CNT], CNT))], m9[key == "gap|lad:sei", .(regf, y, lab = sprintf("Region mean (%d)", n_sys))])
p9 <- ggplot(d9, aes(est, y)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) +
  geom_segment(aes(x = lo, xend = hi, yend = y), colour = cR, linewidth = .4, alpha = .5) + geom_point(aes(shape = Evidence), colour = cR, size = 1.5, stroke = .45) + ev_shape +
  geom_segment(data = m9, aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(m9, aes(est, y), size = 2.6) + mean_key() +
  scale_y_continuous(breaks = function(l) labs9[y >= l[1] & y <= l[2], y], labels = function(b) labs9$lab[match(b, labs9$y)], expand = expansion(add = .7)) +
  scale_x_continuous(limits = lim9, breaks = seq(-1, 1, .5)) +
  facet_grid(regf ~ panel, scales = "free_y", space = "free_y", switch = "y") + labs(x = "Difference in life satisfaction (SD)", y = NULL) +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.6), strip.placement = "outside",
        strip.text.x = element_text(size = 8.2, face = "bold", colour = cK, hjust = 0, lineheight = .95),
        strip.text.y.left = element_text(size = 6.8, face = "bold", colour = cK, angle = 0, hjust = 1, lineheight = .95), panel.spacing.y = unit(5, "pt"), panel.spacing.x = unit(12, "pt"))
save(p9, "fig_p9_regions_by_system", h = 10.6)

# ------------------------------------------------------------------ P10: the four corner groups of the status x achievement matrix (step 16), system by system
# Descriptive, no controls, 0-10 points. Panel A: mean life satisfaction of the four groups in each system (the grey line spans the
# lowest and the highest of the four). Panels B-D: resilient students minus each of the other three groups, with 95% intervals.
# Systems are ranked by the difference from advantaged top achievers. The last row is the random-effects mean of systems.
xs <- rd("matrix_sys.csv"); xp <- rd("matrix_pool.csv"); stopifnot(!"QUA" %in% xs$CNT, all(unique(xs$CNT) %in% names(NAMES)))
G4 <- c(S1A4 = "Resilient students", S1A1 = "Disadvantaged low achievers", S4A1 = "Advantaged low achievers", S4A4 = "Advantaged top achievers")
col4 <- setNames(c(cR, cP, cG, "#2B6CB0"), unname(G4))
D3 <- c(`diff:R-AT` = "S4A4", `diff:R-PL` = "S1A1", `diff:R-AL` = "S4A1")
lab3 <- setNames(paste("Against", tolower(substr(G4[D3], 1, 1)), substring(G4[D3], 2)), names(D3)); lab3 <- sub("Against a", "Against a", sub("Against d", "Against d", lab3))
lab3 <- setNames(paste0("Against ", c("advantaged top achievers", "disadvantaged low achievers", "advantaged low achievers")), names(D3))
z10 <- xs[term %in% names(D3) & !is.na(est) & se > 0]; ord10 <- z10[term == "diff:R-AT"][order(-est), CNT]; n10 <- length(ord10)
m10 <- xs[term %in% paste0("mean:", names(G4)) & CNT %in% ord10][, .(CNT, g = factor(G4[sub("mean:", "", term)], levels = unname(G4)), est, y = match(CNT, ord10))]
r10 <- m10[, .(lo = min(est), hi = max(est)), by = y]
pm10 <- xp[match(paste0("mean:", names(G4)), term), .(g = factor(unname(G4), levels = unname(G4)), est = re_mean, y = -.8)]
lim10a <- c(5, 9); stopifnot(m10$est > lim10a[1], m10$est < lim10a[2])
ylab10 <- scale_y_continuous(breaks = c(seq_len(n10), -.8), labels = c(sprintf("%s (%s)", NAMES[ord10], ord10), sprintf("Mean of %d systems", n10)), limits = c(-1.6, n10 + 2.4), expand = c(0, 0))
p10a <- ggplot(m10, aes(est, y)) + geom_hline(yintercept = .1, colour = cL, linewidth = .3) +
  geom_segment(data = r10, aes(x = lo, xend = hi, y = y, yend = y), colour = cBand, linewidth = 1.1, inherit.aes = FALSE) +
  geom_point(aes(colour = g), size = 1.25, alpha = .95) +
  geom_segment(data = pm10[, .(lo = min(est), hi = max(est), y = y[1])], aes(x = lo, xend = hi, y = y, yend = y), colour = cBand, linewidth = 1.6, inherit.aes = FALSE) +
  geom_point(data = pm10, aes(fill = g), shape = 22, colour = "white", size = 2.6, stroke = .5, show.legend = FALSE) +
  scale_colour_manual(values = col4, name = NULL, guide = guide_legend(order = 2, nrow = 2, override.aes = list(size = 2.4))) + scale_fill_manual(values = col4, guide = "none") +
  ylab10 + scale_x_continuous(limits = lim10a, breaks = 5:9, expand = c(0, 0)) +
  labs(x = "Mean life satisfaction (0-10)", y = NULL, tag = "A") +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.6))
lim10b <- c(-2, 1.25)
z10[, `:=`(y = match(CNT, ord10), k = factor(lab3[term], levels = unname(lab3)), c3 = G4[D3[term]], lo = pmax(est - 1.96 * se, lim10b[1]), hi = pmin(est + 1.96 * se, lim10b[2]), Evidence = ev(est, se))]
stopifnot(z10$est > lim10b[1], z10$est < lim10b[2])
s10 <- xp[match(names(D3), term), .(k = factor(lab3[term], levels = unname(lab3)), est = re_mean, lo = re_mean - 1.96 * re_se, hi = re_mean + 1.96 * re_se, y = -.8)]
c10 <- z10[, .(lab = sprintf("lower at p < 0.05 in %d,\nat p < 0.10 in %d of %d", sum(est / se < -1.96), sum(est / se < -1.645), .N)), by = k]
p10b <- ggplot(z10, aes(est, y)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) + geom_hline(yintercept = .1, colour = cL, linewidth = .3) +
  geom_segment(aes(x = lo, xend = hi, yend = y, colour = c3), linewidth = .4, alpha = .5) + geom_point(aes(colour = c3, shape = Evidence), size = 1.5, stroke = .45) + ev_shape +
  geom_segment(data = s10, aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(s10, aes(est, y)) + mean_key() +
  geom_text(data = c10, aes(x = lim10b[1] + .08, y = n10 + 1.4, label = lab), hjust = 0, vjust = .5, size = 2.2, family = FAM, colour = cT, lineheight = .9) +
  scale_colour_manual(values = col4, guide = "none") + ylab10 + scale_x_continuous(limits = lim10b, breaks = seq(-2, 1, .5), expand = c(0, 0)) + facet_grid(. ~ k) +
  labs(x = "Resilient students minus the group (points on the 0-10 scale)", y = NULL, tag = "B") +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_blank(), strip.text = element_text(size = 7.6, face = "bold", colour = cK), panel.spacing = unit(9, "pt"))
save((p10a | p10b) + plot_layout(widths = c(1, 2.6), guides = "collect") & theme(legend.position = "bottom"), "fig_p10_corner_groups", w = 9.6, h = 10.4)

# ------------------------------------------------------------------ P11: Figure 2 -- resilient students in every system, grouped by region (step 17, model 3)
# Model 3: 16 status x achievement cells, school fixed effects, sex, age and grade; reference advantaged top achievers. Panel A: the
# coefficient of resilient students. Panel B: resilient students minus advantaged low achievers, from the same model. Regions are
# ranked by their mean in panel A, systems within a region by their estimate in panel A. New Zealand and Kenya are shown at the
# bottom without a region; the last row is the mean of all systems. Region and overall means: random effects (step 15).
source("05_papers/03_resilience_cost/01_code/regions.R")
xm <- rd("mxmod_sys.csv"); stopifnot(!"QUA" %in% xm$CNT, all(unique(xm$CNT) %in% names(NAMES)))
P11 <- c(`mm:z:M3:S1A4` = "A. Resilient students against\nadvantaged top achievers", `mm:z:M3:R-AL` = "B. Resilient students against\nadvantaged low achievers")
OTHER <- "New Zealand and Kenya"; lim11 <- c(-1, .75)
z11 <- merge(xm[term %in% names(P11) & !is.na(est) & se > 0, .(key = term, CNT, est, se)], REGION_OF, by = "CNT"); stopifnot(!anyNA(z11$region))
r11 <- rg[file == "mxmod" & term %in% names(P11), .(key = term, region, est = re_mean, se = re_se, n_sys)]
regs11 <- r11[key == names(P11)[1] & !region %in% c("All systems", OTHER)][order(est), region]
ordA11 <- z11[key == names(P11)[1]][order(est)]
G_OTHER <- " "; G_ALL <- "  "                                                         # unlabelled groups at the bottom
rows11 <- rbind(rbindlist(lapply(regs11, function(r) rbind(data.table(grp = r, CNT = ordA11[region == r, CNT], what = "system", region = r),
                                                          data.table(grp = r, CNT = NA_character_, what = "mean", region = r)))),
                data.table(grp = G_OTHER, CNT = ordA11[region == OTHER, CNT], what = "system", region = OTHER),
                data.table(grp = G_ALL, CNT = NA_character_, what = "mean", region = "All systems"))
rows11[, `:=`(grpf = factor(grp, levels = c(regs11, G_OTHER, G_ALL), labels = c(gsub(" and ", " and\n", regs11), G_OTHER, G_ALL)), y = rev(seq_len(.N)))]
d11 <- merge(z11, rows11[what == "system", .(CNT, grpf, y)], by = "CNT")
m11 <- merge(r11, rows11[what == "mean", .(region, grpf, y)], by = "region")
for (x in list(d11, m11)) x[, `:=`(panel = factor(P11[key], levels = unname(P11)), lo = pmax(est - 1.96 * se, lim11[1]), hi = pmin(est + 1.96 * se, lim11[2]), Evidence = ev(est, se))]
stopifnot(d11$est > lim11[1], d11$est < lim11[2], nrow(d11) == 2 * uniqueN(xm$CNT))
labs11 <- rbind(d11[key == names(P11)[1], .(y, lab = sprintf("%s (%s)", NAMES[CNT], CNT))],
                m11[key == names(P11)[1], .(y, lab = ifelse(region == "All systems", sprintf("Mean of %d systems", n_sys), sprintf("Region mean (%d)", n_sys)))])
p11 <- ggplot(d11, aes(est, y)) + geom_vline(xintercept = 0, colour = cK, linewidth = .4) +
  geom_segment(aes(x = lo, xend = hi, yend = y), colour = cR, linewidth = .4, alpha = .5) + geom_point(aes(shape = Evidence), colour = cR, size = 1.5, stroke = .45) + ev_shape +
  geom_segment(data = m11, aes(x = lo, xend = hi, yend = y), colour = cK, linewidth = .7) + mean_pt(m11, aes(est, y), size = 2.6) + mean_key() +
  scale_y_continuous(breaks = function(l) labs11[y >= l[1] & y <= l[2], y], labels = function(b) labs11$lab[match(b, labs11$y)], expand = expansion(add = .7)) +
  scale_x_continuous(limits = lim11, breaks = seq(-1, .75, .25)) +
  facet_grid(grpf ~ panel, scales = "free_y", space = "free_y", switch = "y") + labs(x = "Difference in life satisfaction (SD)", y = NULL) +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.6), strip.placement = "outside",
        strip.text.x = element_text(size = 8.2, face = "bold", colour = cK, hjust = 0, lineheight = .95),
        strip.text.y.left = element_text(size = 6.6, face = "bold", colour = cK, angle = 90, hjust = .5, lineheight = .95), panel.spacing.y = unit(5, "pt"), panel.spacing.x = unit(12, "pt"))
save(p11, "fig_p11_resilient_by_region", h = 10.6)

# ------------------------------------------------------------------ P12: Figure 1 -- the status x achievement matrix (step 16), the systems of the models
# Mean over the systems of step 17 (each system weighted equally) of three cell statistics: mean life satisfaction (tile colour and
# the large number), share answering 10 and share of the system's students. Descriptive, no controls. The four corner groups are named.
xs12 <- rd("matrix_sys.csv"); sys12 <- unique(rd("mxmod_sys.csv")$CNT); stopifnot(all(sys12 %in% xs12$CNT))
c12 <- xs12[CNT %in% sys12 & grepl("^(mean|ls10|share):S[1-4]A[1-4]$", term), .(v = mean(est)), by = term][, c("stat", "cell") := tstrsplit(term, ":")]
c12 <- dcast(c12, cell ~ stat, value.var = "v")[, `:=`(S = as.integer(substr(cell, 2, 2)), A = as.integer(substr(cell, 4, 4)))]
stopifnot(nrow(c12) == 16, abs(sum(c12$share) - 1) < 1e-6)
corner12 <- c(S1A4 = "Resilient\nstudents", S1A1 = "Disadvantaged\nlow achievers", S4A1 = "Advantaged\nlow achievers", S4A4 = "Advantaged top\nachievers (reference)")
c12[, `:=`(name = ifelse(cell %in% names(corner12), corner12[cell], ""), lab = sprintf("%.2f", mean), sub = sprintf("answer 10: %.0f%%   students: %.1f%%", 100 * ls10, 100 * share))]
mid12 <- mean(range(c12$mean)); c12[, ink := ifelse(mean < mid12, "white", cK)]
p12 <- ggplot(c12, aes(A, S)) + geom_tile(aes(fill = mean), colour = "white", linewidth = 1.2) +
  geom_tile(data = c12[name != ""], fill = NA, colour = cK, linewidth = .5, width = .97, height = .97) +
  geom_text(aes(label = name, colour = ink), y = c12$S + .3, size = 2.3, family = FAM, fontface = "italic", lineheight = .85) +
  geom_text(aes(label = lab, colour = ink), size = 4.2, family = FAM, fontface = "bold") +
  geom_text(aes(label = sub, colour = ink), y = c12$S - .3, size = 2.1, family = FAM) +
  scale_colour_identity() + scale_fill_gradient(low = cR, high = tintR, name = "Mean life satisfaction (0-10)", guide = guide_colourbar(barwidth = unit(110, "pt"), barheight = unit(6, "pt"), title.position = "top")) +
  scale_x_continuous(breaks = 1:4, labels = c("Bottom quarter", "Second quarter", "Third quarter", "Top quarter"), expand = c(0, 0)) +
  scale_y_continuous(breaks = 1:4, labels = c("Bottom quarter\n(disadvantaged)", "Second quarter", "Third quarter", "Top quarter\n(advantaged)"), expand = c(0, 0)) +
  coord_fixed() + labs(x = "Reading achievement (national quarters)", y = "Economic, social and cultural status\n(national quarters)") +
  theme(panel.grid = element_blank(), legend.title = element_text(size = 7.6, colour = cK), axis.text = element_text(size = 7.4))
save(p12, "fig_p12_matrix", w = 6.6, h = 6.4)

# ------------------------------------------------------------------ P13: RQ2 -- what the characteristics do to the gap to advantaged top achievers; how far systems differ (step 17)
# Panel A: each system's gap in model 3 against its gap in model 5 (skills, mindsets and relationships also held fixed); under the line
# the gap is larger before the characteristics are held fixed. Panel B: the model-3 gap against its standard error, with the funnel in
# which 95% of estimates would fall if every system had the pooled gap.
xm13 <- rd("mxmod_sys.csv"); xp13 <- rd("mxmod_pool.csv")
g13 <- wide(xm13, c(m3 = "mm:z:M3:S1A4", m5 = "mm:z:M5:S1A4")); lim13 <- c(floor(min(g13$m3, g13$m5) * 10 - .5), ceiling(max(g13$m3, g13$m5) * 10 + .5)) / 10
p13a <- scat(g13[, .(CNT, x = m5, y = m3)], summ(xp13, c("mm:z:M5:S1A4", "mm:z:M3:S1A4")), lim13, breaks = seq(-1, 1, .25), tag = "A",
  xlab = "Gap with skills, mindsets and relationships\nalso held fixed (model 5, SD)", ylab = "Gap with sex, age and grade held fixed (model 3, SD)", below = "Larger gap before the\ncharacteristics are held fixed") +
  geom_hline(yintercept = 0, colour = cL, linewidth = .3, linetype = "22") + geom_vline(xintercept = 0, colour = cL, linewidth = .3, linetype = "22")
f13 <- xm13[term == "mm:z:M3:S1A4" & !is.na(est) & se > 0, .(CNT, est, se)]; pm13 <- xp13[term == "mm:z:M3:S1A4", re_mean]; f13[, out := abs(est - pm13) > 1.96 * se]
fun13 <- data.table(se = exp(seq(log(min(f13$se) * .9), log(max(f13$se) * 1.08), length.out = 80)))[, `:=`(lo = pm13 - 1.96 * se, hi = pm13 + 1.96 * se)]; xl13 <- c(-1, .5); stopifnot(f13$est > xl13[1], f13$est < xl13[2])
revlog <- scales::trans_new("revlog", function(x) -log10(x), function(x) 10^(-x), domain = c(1e-6, Inf))
p13b <- ggplot(f13, aes(est, se)) +
  geom_ribbon(data = fun13, aes(y = se, xmin = pmax(lo, xl13[1]), xmax = pmin(hi, xl13[2])), inherit.aes = FALSE, fill = "#F1F1F1") +
  geom_path(data = fun13[lo > xl13[1]], aes(lo, se), colour = cL, linewidth = .4) + geom_path(data = fun13[hi < xl13[2]], aes(hi, se), colour = cL, linewidth = .4) +
  geom_vline(xintercept = 0, colour = cL, linewidth = .3, linetype = "22") + geom_vline(xintercept = pm13, colour = cK, linewidth = .35) +
  geom_point(aes(colour = out), size = 1.5, alpha = .9, show.legend = FALSE) +
  geom_text_repel(aes(label = CNT, colour = out), size = 1.95, family = FAM, segment.size = .15, segment.colour = cL, min.segment.length = .15, box.padding = .1, point.padding = .08, max.overlaps = Inf, max.time = 3, max.iter = 60000, seed = 7, show.legend = FALSE) +
  annotate("text", x = xl13[1] + .04, y = min(fun13$se) * 1.03, label = sprintf("%d of %d systems\ninside the funnel", f13[out == FALSE, .N], nrow(f13)), hjust = 0, vjust = 1, size = 2.6, family = FAM, colour = cK, lineheight = .95) +
  scale_colour_manual(values = c(`FALSE` = cP, `TRUE` = cR)) + scale_y_continuous(trans = revlog, breaks = c(.05, .075, .1, .15, .2, .3), limits = rev(range(fun13$se)), expand = c(0, 0)) +
  scale_x_continuous(limits = xl13, breaks = seq(-1, .5, .25), expand = c(0, 0)) +
  labs(x = "Gap with sex, age and grade held fixed (model 3, SD)", y = "Standard error of the system estimate (log scale)", tag = "B") + theme(aspect.ratio = 1)
pair(p13a, p13b, "fig_p13_controls")

# ------------------------------------------------------------------ P14: RQ2 -- what accounts for the gaps, system by system (Gelbach decomposition, step 17)
# Two panels: resilient students against advantaged top achievers, and against advantaged low achievers. Each bar splits a system's
# model-3 gap (marker) into the contributions of the characteristics added in models 4 and 5 (difference between the groups in the
# characteristic x its model-5 coefficient) and the remainder, the gap left in model 5. The parts sum to the gap in every system. A
# characteristic a system did not field contributes nothing there. Significance of the model-3 gap (two-sided): filled circle p < 0.05,
# filled triangle p < 0.10; where it is not significant the bar is drawn in pale colours and the marker is an open circle. Last row: mean
# of systems (each weighted equally; parts sum to the mean gap), marked by the significance of the random-effects mean.
xm14 <- rd("mxmod_sys.csv"); xp14 <- rd("mxmod_pool.csv")
PART14 <- list(`Sense of belonging` = "BELONG_z", `Family support` = "FAMSUP_z", `Safety and bullying` = c("FEELSAFE_z", "BULLIED_z"),
               `Socio-emotional skills` = c("PERSEV_z", "CURIO_z", "ENPROBS_z", "COGABIL_z", "GOALSET_z", "SELFREG_z"), `Mindsets and attitudes` = c("growth", "EFFSCIE_z", "JOYSCIE_z"))
CON14 <- c(`R-AT` = "A. Against advantaged top achievers", `R-AL` = "B. Against advantaged low achievers"); TOT14 <- c(`R-AT` = "S1A4", `R-AL` = "R-AL")
w14 <- dcast(xm14[grepl("^gel:|^mm:z:M[35]:", term)], CNT ~ term, value.var = "est")
all14 <- rbindlist(lapply(names(CON14), function(cn) {
  t3 <- paste0("mm:z:M3:", TOT14[[cn]])
  z <- data.table(CNT = w14$CNT, con = cn, gross = w14[[t3]], Remainder = w14[[paste0("mm:z:M5:", TOT14[[cn]])]])
  for (pn in names(PART14)) { M <- as.matrix(w14[, intersect(paste0("gel:", cn, ":", PART14[[pn]]), names(w14)), with = FALSE]); M[is.na(M)] <- 0; z[, (pn) := rowSums(M)] }
  stopifnot(max(abs(z$gross - z$Remainder - rowSums(z[, names(PART14), with = FALSE]))) < 1e-6)
  z <- merge(z, xm14[term == t3, .(CNT, se)], by = "CNT")[, gross_sig := gross]
  m <- z[, lapply(.SD, mean), .SDcols = c("gross", "Remainder", names(PART14))][, `:=`(CNT = "MEAN", con = cn, se = xp14[term == t3, re_se], gross_sig = xp14[term == t3, re_mean])]
  rbind(z, m, use.names = TRUE) }))
all14[, `:=`(Evidence = ev(gross_sig, se), conf = factor(CON14[con], levels = unname(CON14)))]
sys14 <- unique(all14[CNT != "MEAN", CNT]); sys14 <- sys14[order(NAMES[sys14])]; ord14 <- rev(c(sys14, "GAP", "MEAN"))   # alphabetical from the top, a blank row, the mean at the bottom
lab14 <- c(setNames(NAMES[sys14], sys14), GAP = "", MEAN = sprintf("Mean of %d systems", length(sys14)))
long14 <- melt(all14[, c("CNT", "conf", "Evidence", "Remainder", names(PART14)), with = FALSE], id.vars = c("CNT", "conf", "Evidence"), variable.name = "part", value.name = "v")
long14[, `:=`(y = factor(CNT, levels = ord14), part = factor(part, levels = c(names(PART14), "Remainder")))]
P14L <- c(names(PART14), "Remainder")
long14[, key := factor(ifelse(Evidence == EV[3], paste0(part, " (pale)"), as.character(part)), levels = c(P14L, paste0(P14L, " (pale)")))]   # same stacking order for solid and pale
mk14 <- all14[, .(y = factor(CNT, levels = ord14), conf, gross, Evidence)]
col14 <- c(`Sense of belonging` = "#1F5A99", `Family support` = "#5B9BD5", `Safety and bullying` = "#A9CCE8", `Socio-emotional skills` = "#D9730D", `Mindsets and attitudes` = "#F2B880", Remainder = cR)
pale <- function(x, f = .78) grDevices::rgb(t(grDevices::col2rgb(x) + (255 - grDevices::col2rgb(x)) * f), maxColorValue = 255)   # mixed with white
fill14 <- c(col14, setNames(vapply(col14, pale, ""), paste0(names(col14), " (pale)")))
p14 <- ggplot(long14, aes(v, y)) + geom_vline(xintercept = 0, colour = cL, linewidth = .4) +
  geom_col(aes(fill = key), width = .72, orientation = "y") +
  geom_point(data = mk14, aes(gross, y, shape = Evidence, fill = I(ifelse(Evidence == EV[3], "white", cK)), colour = I(ifelse(Evidence == EV[3], cK, "white"))), size = 2, stroke = .5, show.legend = c(shape = TRUE, fill = FALSE, colour = FALSE)) +
  scale_shape_manual(values = setNames(c(21, 24, 21), EV), drop = FALSE, name = NULL,
                     guide = guide_legend(order = 1, nrow = 1, override.aes = list(fill = c(cK, cK, "white"), colour = c("white", "white", cK), size = 2.4))) +
  scale_fill_manual(values = fill14, breaks = names(col14), name = NULL, guide = guide_legend(order = 2, nrow = 2)) +
  scale_y_discrete(labels = lab14, drop = FALSE, limits = ord14) +
  scale_x_continuous(breaks = round(seq(-.8, .4, .2), 1), labels = function(b) formatC(round(b, 1) + 0, format = "f", digits = 1)) +
  facet_grid(. ~ conf) + labs(x = "Gap in model 3 (SD) and its parts", y = NULL) +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 6.4), legend.box = "vertical", legend.text = element_text(size = 7.6),
        strip.text.x = element_text(size = 8.2, face = "bold", colour = cK, hjust = 0), panel.spacing.x = unit(12, "pt"),
        panel.background = element_rect(fill = "#FAFAF8", colour = "#D9D9D9", linewidth = .4))
save(p14, "fig_p14_decomposition", w = 7.6, h = 10.2)

# ------------------------------------------------------------------ P15: RQ1 -- where on the scale the gap to advantaged top achievers lies (step 19, model 3; step 16)
# Panel A: difference between resilient students and advantaged top achievers in the same school in the share giving each answer 0-10,
# model 3 (16 groups, school fixed effects, sex, age, grade), in percentage points; thin lines are systems, the black line and squares the
# random-effects mean with its 95% interval. Panel B: unadjusted share of each group answering 10 in each system of the models (step 16).
xa15 <- rd("mxans_sys.csv"); xpa15 <- rd("mxans_pool.csv"); xs15 <- rd("matrix_sys.csv"); sys15 <- unique(xa15$CNT)
a15 <- xa15[grepl("^ans:M3:[0-9]+:R-AT$", term) & !is.na(est)][, k := as.integer(sub(":R-AT$", "", sub("^ans:M3:", "", term)))][, est := est * 100]
ap15 <- xpa15[grepl("^ans:M3:[0-9]+:R-AT$", term)][, k := as.integer(sub(":R-AT$", "", sub("^ans:M3:", "", term)))][order(k)][, v := re_mean * 100]
yl15 <- c(-30, 20); cut15 <- a15[est < yl15[1] | est > yl15[2], .N]
p15a <- ggplot(a15, aes(k, est)) + geom_hline(yintercept = 0, colour = cK, linewidth = .35) +
  geom_line(aes(group = CNT), colour = cR, alpha = .2, linewidth = .3) +
  geom_ribbon(data = ap15, aes(k, ymin = (re_mean - 1.96 * re_se) * 100, ymax = (re_mean + 1.96 * re_se) * 100), inherit.aes = FALSE, fill = cK, alpha = .18) +
  geom_line(data = ap15, aes(k, v), colour = cK, linewidth = .6) + mean_pt(ap15, aes(k, v), size = 2.2) + mean_key() +
  scale_x_continuous(breaks = 0:10) + scale_y_continuous(breaks = seq(-30, 20, 10)) + coord_cartesian(ylim = yl15) +
  labs(x = "Answer on the 0-10 item", y = "Difference in the share giving the answer (points)", tag = "A") + theme(panel.grid.major.x = element_blank())
t15 <- dcast(xs15[CNT %in% sys15 & term %in% c("ls10:S1A4", "ls10:S4A4")], CNT ~ term, value.var = "est")[, .(CNT, x = 100 * `ls10:S4A4`, y = 100 * `ls10:S1A4`)]
s15 <- t15[, .(x = mean(x), y = mean(y))]
p15b <- scat(t15, s15, c(0, 60), breaks = seq(0, 60, 20), tag = "B",
  xlab = "Advantaged top achievers (%)", ylab = "Resilient students (%)", below = "Resilient students answer\n10 less often")
pair(p15a, p15b, "fig_p15_answers", widths = c(1.12, 1))

cat(sprintf("systems: means %d, benchmark %d, gap %d (%d negative), answers %d, interactions %d; interaction estimates at the axis limit: %d; answer estimates outside panel A: %d; font %s\n",
            nrow(m), n2, r6$n, r6$neg, uniqueN(a$CNT), uniqueN(z7$CNT), z7[abs(est) > cap7, .N], a[est < -42 | est > 22, .N], FAM))
