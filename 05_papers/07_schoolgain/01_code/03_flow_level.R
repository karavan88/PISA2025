# School Inputs & the Grade Gain -- flows vs levels, input by input, same-school systems
# For every school input M, per system (Fay BRR + Rubin over 10 PVs of overall achievement):
#   flow      : interacted 2SLS, moderator M alone            -> gamma:M  (change in the causal grade gain per SD of M)
#   flow_peer : M + peer SES + peer achievement as moderators  -> gamma:M net of peer composition (for the two peer variables: both jointly)
#   level     : WLS of the score on M + D + r + controls       -> the cross-sectional production-function coefficient of M
# Controls everywhere: sex, immigrant, HISEI, PAREDINT, HOMEPOS (books in Costa Rica), curiosity, perseverance, problem-solving enjoyment.
# Also: peers by domain (science, mathematics, reading) and the all-schoolmates peer-achievement variant.
# Usage: Rscript 02_scripts/schoolgain/03_flow_level.R [CNT ...]     Output: 03_outputs/schoolgain/flow_level.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
a <- load_sch()[structure == "Same-school"]
args <- commandArgs(trailingOnly = TRUE); systems <- if (length(args)) args else sort(unique(a$CNT))
PEERS <- c("peer_SES", "peer_ach")
one <- function(cn) {
  s0 <- a[CNT == cn]; out <- list()
  ctrl <- CTRL[vapply(CTRL, function(v) mean(!is.na(s0[[v]])) > 0.5 && var(s0[[v]], na.rm = TRUE) > 0, logical(1))]
  add <- function(x) out[[length(out) + 1]] <<- x
  for (m in INPUTS$var) {
    s <- s0[!is.na(get(m))]; if (nrow(s) < 500 || var(s[[m]]) == 0) next
    add(data.table(CNT = cn, input = m, spec = "flow", est_sys(s, "ACH", mods = m, ctrl = ctrl)))
    sp <- s[!is.na(peer_SES) & !is.na(peer_ach)]
    if (nrow(sp) >= 500) add(data.table(CNT = cn, input = m, spec = "flow_peer", est_sys(sp, "ACH", mods = unique(c(m, PEERS)), ctrl = ctrl)))
    X <- cbind(1, M = s[[m]], D = s$D, r = s$r, as.matrix(s[, ..ctrl]))
    f <- function(dt, y, w) c(level = unname(wls(X, y, w)["M"]))
    add(data.table(CNT = cn, input = m, spec = "level", pisa_est(s, f, PV("ACH"))[, n := nrow(s)]))
  }
  sp <- s0[!is.na(peer_SES) & !is.na(peer_ach)]
  for (o in DOMS) add(data.table(CNT = cn, input = "peers", spec = paste0("flow_peer_", o), est_sys(sp, o, mods = PEERS, ctrl = ctrl)))
  s <- s0[!is.na(peer_ach_all)]; add(data.table(CNT = cn, input = "peer_ach_all", spec = "flow", est_sys(s, "ACH", mods = "peer_ach_all", ctrl = ctrl)))
  log_step(cn, "done"); rbindlist(out, fill = TRUE)
}
res <- parallel::mclapply(systems, one, mc.cores = as.integer(Sys.getenv("NCORES", "6")), mc.preschedule = FALSE)
bad <- which(sapply(res, inherits, "try-error")); if (length(bad)) { print(res[bad]); stop("failed: ", paste(systems[bad], collapse = " ")) }
res <- rbindlist(res, fill = TRUE); res[, name := SYS_NAMES[CNT]]
out <- og("flow_level.csv"); if (length(args) && file.exists(out)) res <- rbind(fread(out)[!CNT %in% systems], res, fill = TRUE)
fwrite(res, out)
q <- res[(spec == "flow" & term == paste0("gamma:", input)) | (spec == "level" & term == "level"), pool(est, se), by = .(input, spec)]
print(dcast(q, input ~ spec, value.var = "re_mean")[order(-abs(flow))])
