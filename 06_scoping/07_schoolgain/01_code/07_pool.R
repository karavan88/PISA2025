# School Inputs & the Grade Gain -- pooling across same-school systems
# Random-effects (DerSimonian-Laird) pooling of every per-system estimate; Benjamini-Hochberg q-values across the inputs (flow and flow net
# of peers); sets: all same-school systems, non-European, European; leave-one-system-out for the top input.
# Output: 03_outputs/schoolgain/pool_flow_level.csv, pool_top.csv, pool_mechanism.csv, loso_top.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
st <- fread("03_outputs/skillsgain/structure.csv"); SAME <- st[structure == "Same-school", CNT]
SETS <- list(`Same-school (14)` = SAME, `Non-European` = intersect(SAME, SYS_A), `European` = intersect(SAME, SYS_B))
pool_sets <- function(d, by) rbindlist(lapply(names(SETS), function(nm) d[CNT %in% SETS[[nm]], pool(est, se), by = by][, set := nm]))
fl <- fread(og("flow_level.csv"))
fl <- fl[(spec %in% c("flow", "flow_peer") & term == paste0("gamma:", input)) | (spec == "level" & term == "level") | (spec %like% "^flow_peer_" & term %like% "gamma")]
pf <- pool_sets(fl, c("input", "spec", "term"))
pf[, p := 2 * pnorm(-abs(re_mean / re_se))]
pf[spec %in% c("flow", "flow_peer") & input %in% INPUTS$var, q_bh := p.adjust(p, "BH"), by = .(spec, set)]
fwrite(pf, og("pool_flow_level.csv"))
tp <- fread(og("top.csv")); fwrite(pool_sets(tp[grepl("gamma", term) | term == "tau"], c("spec", "term")), og("pool_top.csv"))
mc <- fread(og("mechanism.csv")); fwrite(pool_sets(mc, c("mediator", "term")), og("pool_mechanism.csv"))
TOP <- unique(tp$top)[1]
x <- fl[spec == "flow" & input == TOP]
loso <- rbindlist(lapply(unique(x$CNT), function(cn) x[CNT != cn, pool(est, se)][, dropped := cn]))
fwrite(loso, og("loso_top.csv"))
print(pf[set == "Same-school (14)" & spec == "flow"][order(p), .(input, re = round(re_mean, 2), se = round(re_se, 2), q_bh = round(q_bh, 3))][1:8])
print(loso[, .(dropped, re = round(re_mean, 2), se = round(re_se, 2))])
