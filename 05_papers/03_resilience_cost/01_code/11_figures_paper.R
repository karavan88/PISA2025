# Country-estimate figures for the paper draft (cost_of_resilience_paper.qmd). Reads the approved snapshot only; estimates nothing.
# Every figure shows every system (a labelled point, a row, a line or a dot per system) and marks the mean of systems once.
# The figures carry no title, subtitle or notes: these are in the figure captions of the manuscript. Significance is shown at two
# levels throughout: filled circle p < 0.05, filled triangle p < 0.10, open circle not significant (two-sided, unadjusted).
# Main text: fig_p1_means, fig_p2_benchmark, fig_p3_skills, fig_p8_regions, fig_p4_answers, fig_p5_forest. Appendix: fig_p6_ranking, fig_p7_interactions.
# Output: 05_papers/03_resilience_cost/02_results/figs/fig_p*.pdf     Run from the repository root: Rscript 05_papers/03_resilience_cost/01_code/11_figures_paper.R
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork); library(ggrepel) })
IN <- "05_papers/03_resilience_cost/02_results/snapshot/"; FIG <- "05_papers/03_resilience_cost/02_results/figs/"; dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(f) fread(paste0(IN, f))
gs <- rd("gap_sys.csv"); gp <- rd("gap_pool.csv"); rs <- rd("rs_sys.csv"); rp <- rd("rs_pool.csv")
fs <- rd("foc_sys.csv"); fp <- rd("foc_pool.csv"); ms <- rd("mech_sys.csv"); mp <- rd("mech_pool.csv")
bs <- rd("bench_sys.csv"); bp <- rd("bench_pool.csv"); fo <- rd("forest_est.csv"); rg <- rd("region_pool.csv")

NAMES <- c(ALB = "Albania", ARE = "United Arab Emirates", ARG = "Argentina", ARM = "Armenia", AUT = "Austria", AZE = "Azerbaijan", BEL = "Belgium",
  BGR = "Bulgaria", BRA = "Brazil", BRN = "Brunei Darussalam", CHE = "Switzerland", CHL = "Chile", COL = "Colombia", CZE = "Czechia", DEU = "Germany",
  DNK = "Denmark", DOM = "Dominican Republic", ECU = "Ecuador", ESP = "Spain", EST = "Estonia", FIN = "Finland", FRA = "France", GBR = "United Kingdom",
  GEO = "Georgia", GRC = "Greece", GTM = "Guatemala", HKG = "Hong Kong (China)", HRV = "Croatia", HUN = "Hungary", IDN = "Indonesia", IRL = "Ireland",
  ISL = "Iceland", ISR = "Israel", ITA = "Italy", JOR = "Jordan", JPN = "Japan", KAZ = "Kazakhstan", KEN = "Kenya", KGZ = "Kyrgyzstan", KOR = "Korea",
  KSV = "Kosovo", LBN = "Lebanon", LTU = "Lithuania", LUX = "Luxembourg", LVA = "Latvia", MAC = "Macao (China)", MAR = "Morocco", MDA = "Moldova",
  MEX = "Mexico", MKD = "North Macedonia", MLT = "Malta", MNE = "Montenegro", MNG = "Mongolia", MYS = "Malaysia", NLD = "Netherlands", NZL = "New Zealand",
  PER = "Peru", PHL = "Philippines", POL = "Poland", PRT = "Portugal", PRY = "Paraguay", PSE = "Palestinian Authority", QAT = "Qatar",
  QCI = "B-S-J-Z (China)", ROU = "Romania", SAU = "Saudi Arabia", SRB = "Serbia", SVK = "Slovak Republic", SVN = "Slovenia", TAP = "Chinese Taipei",
  THA = "Thailand", URY = "Uruguay", VNM = "Viet Nam")
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

cat(sprintf("systems: means %d, benchmark %d, gap %d (%d negative), answers %d, interactions %d; interaction estimates at the axis limit: %d; answer estimates outside panel A: %d; font %s\n",
            nrow(m), n2, r6$n, r6$neg, uniqueN(a$CNT), uniqueN(z7$CNT), z7[abs(est) > cap7, .N], a[est < -42 | est > 22, .N], FAM))
