# School Inputs & the Grade Gain -- stress tests for the input with the strongest flow effect (TOP, default s_SAFE: schoolmates' mean
# sense of safety at school). Per same-school system, Fay BRR + Rubin:
#   dom_*    : TOP alone, by domain (science, mathematics, reading)
#   climate  : TOP + disciplinary climate + bullying + negative climate (principal)  -- is it safety or climate in general?
#   context  : TOP + peer SES + peer achievement + urban + school size + private      -- is it safety or who attends / where?
#   all      : climate + context jointly
#   own      : TOP + the student's own sense of safety                                -- school environment or individual perception?
#   quart    : gains by within-system quartile of TOP (indicators q2-q4 as moderators) -- shape
#   bal_own  : jump of the student's own safety at the cutoff (does the grade itself change felt safety?)
# Output: 03_outputs/schoolgain/top.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
TOP <- Sys.getenv("TOP", "s_SAFE")
a <- load_sch()[structure == "Same-school"]
a[, own_SAFE := zw(FEELSAFE, W_FSTUWT), by = CNT]
wq <- function(x, w, k = 4) { ok <- !is.na(x); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); q <- rep(NA_integer_, length(x)); q[which(ok)[o]] <- pmin(k, floor(cw * k - 1e-9) + 1L); q }
a[, tq := wq(get(TOP), W_FSTUWT), by = CNT]; for (k in 2:4) a[, paste0("q", k) := as.numeric(tq == k)]
SPECS <- list(climate = c(TOP, "s_DISC", "s_BULL", "NEGSCLIM"), context = c(TOP, "peer_SES", "peer_ach", "URBAN", "SCHSIZE", "PRIVATE"),
              all = c(TOP, "s_DISC", "s_BULL", "NEGSCLIM", "peer_SES", "peer_ach", "URBAN", "SCHSIZE", "PRIVATE"), own = c(TOP, "own_SAFE"), quart = c("q2", "q3", "q4"))
one <- function(cn) {
  s0 <- a[CNT == cn & !is.na(get(TOP))]; if (nrow(s0) < 500) return(NULL); out <- list()
  ctrl <- CTRL[vapply(CTRL, function(v) mean(!is.na(s0[[v]])) > 0.5 && var(s0[[v]], na.rm = TRUE) > 0, logical(1))]
  for (o in DOMS) out[[length(out) + 1]] <- data.table(spec = paste0("dom_", o), est_sys(s0, o, mods = TOP, ctrl = ctrl))
  for (sp in names(SPECS)) {
    m <- SPECS[[sp]][vapply(SPECS[[sp]], function(v) mean(!is.na(s0[[v]])) > 0.5 && var(s0[[v]], na.rm = TRUE) > 0, logical(1))]
    s <- s0[complete.cases(s0[, ..m])]
    out[[length(out) + 1]] <- data.table(spec = sp, est_sys(s, "ACH", mods = m, ctrl = ctrl))
  }
  s <- s0[!is.na(own_SAFE)]; out[[length(out) + 1]] <- data.table(spec = "bal_own", est_sys(s, "own_SAFE", ctrl = character(0)))
  log_step(cn, "done"); rbindlist(out, fill = TRUE)[, `:=`(CNT = cn, top = TOP)]
}
res <- rbindlist(parallel::mclapply(sort(unique(a$CNT)), one, mc.cores = as.integer(Sys.getenv("NCORES", "4")), mc.preschedule = FALSE), fill = TRUE)
res[, name := SYS_NAMES[CNT]]
fwrite(res, og("top.csv"))
print(res[grepl("gamma", term) | (spec == "bal_own" & term == "tau"), pool(est, se), by = .(spec, term)][, .(spec, term, n_sys, re = round(re_mean, 2), se = round(re_se, 2), tau = round(tau_sd, 2))])
