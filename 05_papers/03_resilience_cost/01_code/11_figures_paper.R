# Country-estimate figures for the paper draft (cost_of_resilience_paper.qmd). Reads the approved snapshot only; estimates nothing.
# Layout follows the figures of paper 01 (SES transmission): every system on its own row, two panels, 95% intervals, the pooled
# estimate in the last row, symbols for the strongest significance threshold met.
# Output: 05_papers/03_resilience_cost/02_results/figs/fig_p*.pdf     Run from the repository root: Rscript 05_papers/03_resilience_cost/01_code/11_figures_paper.R
suppressPackageStartupMessages({ library(data.table); library(ggplot2); library(patchwork) })
IN <- "05_papers/03_resilience_cost/02_results/snapshot/"; FIG <- "05_papers/03_resilience_cost/02_results/figs/"; dir.create(FIG, recursive = TRUE, showWarnings = FALSE)
rd <- function(f) fread(paste0(IN, f))
gs <- rd("gap_sys.csv"); gp <- rd("gap_pool.csv"); rs <- rd("rs_sys.csv"); rp <- rd("rs_pool.csv")
fs <- rd("foc_sys.csv"); fp <- rd("foc_pool.csv"); ms <- rd("mech_sys.csv"); mp <- rd("mech_pool.csv")

# system names as in paper 01
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
for (x in list(gs, rs, fs, ms)) { stopifnot(!"QUA" %in% x$CNT); miss <- setdiff(unique(x$CNT), names(NAMES)); if (length(miss)) stop("no name for: ", paste(miss, collapse = " ")) }

cA <- "#17677E"; cB <- "#BB5839"; cK <- "#202B30"; cT <- "#475961"
FAM <- if ("PT Sans" %in% systemfonts::system_fonts()$family) "PT Sans" else "sans"
theme_set(theme_minimal(base_size = 9, base_family = FAM) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = "#E4E9EB"),
        legend.position = "top", legend.title = element_blank(), legend.text = element_text(size = 8), legend.margin = margin(0, 0, 0, 0),
        axis.text = element_text(colour = "#263A45", size = 7.6), axis.title = element_text(size = 8), plot.margin = margin(4, 8, 4, 8)))
ann <- function(title, subtitle, caption) plot_annotation(title = title, subtitle = subtitle, caption = caption,
  theme = theme(plot.title = element_text(size = 12, face = "bold", colour = "#172F3B", family = FAM), plot.subtitle = element_text(size = 8.6, colour = cT, family = FAM, margin = margin(b = 4)),
                plot.caption = element_text(size = 7.4, hjust = 0, colour = cT, family = FAM, lineheight = 1.05)))
save <- function(p, name, w = 7.4, h = 8.4) { ggsave(paste0(FIG, name, ".pdf"), p, width = w, height = h, device = cairo_pdf); message("wrote ", name) }
EV <- c("p < 0.05", "p < 0.10", "Not significant")
ev <- function(est, se) { z <- abs(est / se); factor(ifelse(z > 1.96, EV[1], ifelse(z > 1.645, EV[2], EV[3])), levels = EV) }
# alphabetical position of each system in two panels of equal length
place <- function(cnt) { o <- data.table(CNT = cnt, name = unname(NAMES[cnt]))[order(name)]; n1 <- ceiling(nrow(o) / 2)
  o[, `:=`(idx = .I, panel = ifelse(.I <= n1, 1L, 2L))][, row := ifelse(panel == 1L, idx, idx - n1)][, y := n1 - row + 1][]; attr(o, "n1") <- n1; o }

# ------------------------------------------------------------------ forest: one row per system, one or two series
# series: named character vector, snapshot term -> legend label (first = upper mark). mult rescales the estimates (100 = percentage points).
forest <- function(sys, pool, series, name, title, subtitle, caption, lim, breaks = waiver(), signif = TRUE, mult = 1, zero = TRUE) {
  z <- sys[term %in% names(series) & !is.na(est) & !is.na(se) & se > 0]; z <- z[CNT %in% z[, .N, by = CNT][N == length(series), CNT]]
  pos <- place(unique(z$CNT)); n1 <- attr(pos, "n1"); z <- merge(z, pos, by = "CNT")
  pl <- pool[match(names(series), term), .(term, est = re_mean, se = re_se, n_sys)]
  off <- if (length(series) == 2) c(.16, -.16) else 0; names(off) <- names(series)
  mk <- function(d) d[, `:=`(est = est * mult, se = se * mult)][, `:=`(lo = pmax(est - 1.96 * se, lim[1]), hi = pmin(est + 1.96 * se, lim[2]), Series = factor(series[term], levels = unname(series)), Evidence = ev(est, se))]
  z <- mk(z)[, yy := y + off[term]]; pl <- mk(pl)[, yy := off[term]]
  if (any(z$est < lim[1] | z$est > lim[2])) stop(name, ": a point estimate lies outside the axis limits")
  pooled_lab <- sprintf("Pooled (%d systems)", max(pl$n_sys)); cols <- c(cA, cB)[seq_along(series)]; if (length(series) == 1) cols <- cA
  panels <- lapply(1:2, function(k) {
    d <- rbindlist(list(z[panel == k], pl), fill = TRUE); ll <- pos[panel == k]
    g <- ggplot(d, aes(est, yy, colour = Series)) + geom_hline(yintercept = seq_len(n1), colour = "#EDF0F1", linewidth = .25)
    if (zero) g <- g + geom_vline(xintercept = 0, colour = "#596D77", linewidth = .45)
    g <- g + geom_segment(aes(x = lo, xend = hi, yend = yy), linewidth = .5)
    g <- if (signif) g + geom_point(aes(shape = Evidence), size = 1.7, fill = "white") + scale_shape_manual(values = c(16, 17, 1), drop = FALSE, guide = guide_legend(order = 2)) else g + geom_point(size = 1.7)
    g + scale_colour_manual(values = cols, drop = FALSE, guide = if (length(series) == 1) "none" else guide_legend(order = 1)) +
      scale_y_continuous(breaks = c(ll$y, 0), labels = c(ll$name, pooled_lab), limits = c(-.6, n1 + .6), expand = c(0, 0)) +
      scale_x_continuous(limits = lim, breaks = breaks) + labs(x = NULL, y = NULL)
  })
  save((panels[[1]] | panels[[2]]) + plot_layout(guides = "collect") + ann(title, subtitle, caption) & theme(legend.position = "top"), name)
  invisible(list(n = nrow(pos), z = z, pool = pl))
}

# ------------------------------------------------------------------ heat map: systems in rows, terms in columns
# cols: named character vector, snapshot term -> column label; block (optional): named vector term -> block label.
heat <- function(sys, pool, cols, name, title, subtitle, caption, cap, fill_name, mult = 1, block = NULL, xangle = 0) {
  z <- sys[term %in% names(cols) & !is.na(est) & !is.na(se) & se > 0]; pos <- place(unique(z$CNT)); z <- merge(z, pos[, .(CNT, name, panel)], by = "CNT")
  pl <- pool[term %in% names(cols), .(term, est = re_mean, se = re_se, n_sys)]; pooled_lab <- sprintf("Pooled (%d systems)", max(pl$n_sys))
  z <- rbindlist(list(z, copy(pl)[, `:=`(name = pooled_lab, panel = 1L)], copy(pl)[, `:=`(name = pooled_lab, panel = 2L)]), fill = TRUE)
  z[, `:=`(est = est * mult, se = se * mult)][, `:=`(Evidence = ev(est, se), col = factor(cols[term], levels = unname(cols)), blk = if (is.null(block)) "" else factor(block[term], levels = unique(unname(block))))]
  panels <- lapply(1:2, function(k) { d <- z[panel == k]; d[, country := factor(name, levels = c(pooled_lab, rev(sort(setdiff(unique(name), pooled_lab)))))]
    g <- ggplot(d, aes(col, country, fill = pmax(pmin(est, cap), -cap))) + geom_tile(colour = "white", linewidth = .25) +
      geom_point(aes(shape = Evidence), fill = "white", colour = "#183B4A", stroke = .3, size = 1.15, na.rm = TRUE) +
      scale_shape_manual(values = c(21, 24, NA), drop = FALSE, name = NULL, labels = c("p < 0.05", "p < 0.10", "No symbol: not significant")) +
      scale_fill_gradient2(low = cB, mid = "#F7F6F1", high = cA, midpoint = 0, limits = c(-cap, cap), name = fill_name) +
      scale_x_discrete(position = "top") + labs(x = NULL, y = NULL) +
      guides(fill = guide_colourbar(order = 1, barwidth = unit(4.2, "cm"), barheight = unit(.28, "cm"), title.position = "top"), shape = guide_legend(order = 2, nrow = 1, override.aes = list(size = 2))) +
      theme(panel.grid = element_blank(), panel.background = element_rect(fill = "#D5DADC", colour = NA), axis.text.x = element_text(size = 6.6, angle = xangle, hjust = if (xangle) 0 else .5, vjust = if (xangle) .5 else 0, lineheight = .9), axis.text.y = element_text(size = 7))
    if (!is.null(block)) g <- g + facet_grid(. ~ blk, scales = "free_x", space = "free_x") + theme(strip.text = element_text(size = 7.4, face = "bold", colour = "#263A45"), strip.placement = "outside", panel.spacing = unit(5, "pt"))
    g })
  save((panels[[1]] | panels[[2]]) + plot_layout(guides = "collect") + ann(title, subtitle, caption) & theme(legend.position = "bottom", legend.title = element_text(size = 7.6)), name)
  invisible(list(n = nrow(pos), z = z, over = z[abs(est) > cap, .N]))
}

# ------------------------------------------------------------------ P1: mean life satisfaction of the two disadvantaged groups
r1 <- forest(rs, rp, c(`mean:PL:LS` = "Disadvantaged low achievers", `mean:R:LS` = "Resilient students"), "fig_p1_means", signif = FALSE, zero = FALSE, lim = c(4.5, 9.5), breaks = 5:9,
  title = "Life satisfaction of resilient students and disadvantaged low achievers",
  subtitle = "Mean answer on the 0-10 item in each system, with 95% intervals",
  caption = "Both groups are in the bottom quartile of socio-economic status in their system; resilient students are in the top quartile of achievement and\nlow achievers in the bottom quartile. Means are not adjusted for any characteristic. Systems appear alphabetically; both panels use the same scale.\nPooled: random-effects mean across systems.")

# ------------------------------------------------------------------ P2: the gap, without and with the skill index
r2 <- forest(gs, gp, c(`lad:demo` = "Sex, age and grade held fixed", `lad:sei` = "Skill index also held fixed"), "fig_p2_gap", lim = c(-1.1, 0.9), breaks = seq(-1, .75, .5),
  title = "The life-satisfaction gap of resilient students, system by system",
  subtitle = "Resilient students minus disadvantaged low achievers in the same school, in within-system SD, with 95% intervals",
  caption = "Negative values: resilient students report lower life satisfaction. Estimates use school fixed effects, 80 replicate weights and 10 plausible values.\nSymbols: strongest threshold met (two-sided, unadjusted); not significant refers to the 10% level. Intervals are cut at the axis limits.\nSystems appear alphabetically; both panels use the same scale. Pooled: random-effects mean across systems.")

# ------------------------------------------------------------------ P3: where on the scale, answer by answer
r3 <- heat(fs, fp, setNames(as.character(0:10), paste0("ans:sei:", 0:10)), "fig_p3_answers", mult = 100, cap = 20, fill_name = "Difference in the share giving the answer (percentage points)",
  title = "Which answers resilient students give less often, and which more often",
  subtitle = "Difference in the share choosing each answer from 0 to 10, resilient students minus disadvantaged low achievers, skill index held fixed",
  caption = "Each cell is a within-school regression of an indicator for the answer on an indicator for resilient students, with sex, age, grade and the skill index.\nSymbols: strongest threshold met (two-sided, unadjusted); unmarked cells are not significant at the 10% level. Colours are capped at 20 points.\nPooled: random-effects mean across systems.")

# ------------------------------------------------------------------ P4: context and skills as moderators of the gap
mods <- c(schESCS = "Schoolmates'\nstatus", schACH = "Schoolmates'\nachievement", female = "Female", uni = "Expects a\ndegree",
          PERSEV = "Perseverance", GOALSET = "Goal setting", COGABIL = "Cognitive\nadaptability", ENPROBS = "Enjoys problem-\nsolving", SELFREG = "Self-regulated\nlearning", CURIO = "Curiosity")
names(mods) <- paste0("mod:", names(mods), ":topX")
r4 <- heat(ms, mp, mods, "fig_p4_moderators", cap = 0.5, fill_name = "Change in the gap (SD of life satisfaction)", xangle = 90,
  block = setNames(c(rep("Context", 4), rep("Socio-emotional skills", 6)), names(mods)),
  title = "Does the gap depend on context or on skills?",
  subtitle = "Interaction of the resilient-student indicator with each moderator, system by system, skill index held fixed",
  caption = "Positive values (blue): the gap is smaller where the moderator is higher. Schoolmates' status and achievement are leave-one-out school means; they\nand the six skills are per SD. Female and expecting a university degree are indicators. Symbols: strongest threshold met (two-sided, unadjusted);\nunmarked cells are not significant at the 10% level. Colours are capped at 0.5 SD. Grey: skill not measured in the system. Pooled: random-effects mean.")

cat(sprintf("systems: means %d, gap %d, answers %d, moderators %d; capped cells: answers %d, moderators %d\n", r1$n, r2$n, r3$n, r4$n, r3$over, r4$over))
