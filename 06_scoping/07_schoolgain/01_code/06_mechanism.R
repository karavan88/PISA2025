# School Inputs & the Grade Gain -- mechanism: why does a school year teach more in safe schools? Moderated causal mediation.
# Hypothesis: where schools are unsafe, the extra year raises disengagement (skipping, lateness, victimisation) and lowers belonging and
# effort, and that disengagement consumes the year's learning. For each candidate mediator m (within-system z), per same-school system,
# all quantities computed in the same BRR replicate / PV (Rubin over PVs):
#   a-path   2SLS of m on the grade with safety (TOP) as moderator: a0 (grade effect on m at mean safety), aT (its change per SD of safety)
#            -- causal: the same instrument identifies it
#   total    2SLS of achievement on the grade with TOP as moderator: g0, gT (gT = the safety moderation of the grade gain)
#   direct   the same with m added as a control: d0, dT; b = coefficient on m (needs sequential ignorability: no unobserved confounder of m and y)
#   indirect ind0 = g0 - d0 (part of the average gain running through m); indT = gT - dT (part of the SAFETY MODERATION running through m)
# Mediators: skipping (any, last two weeks), lateness, own victimisation (bullied), belonging, test effort; and the four engagement
# measures jointly (effort excluded from the joint set: not fielded in Cambodia and Mauritius).
# Output: 03_outputs/schoolgain/mechanism.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/schoolgain/00_helpers.R")
TOP <- Sys.getenv("TOP", "s_SAFE")
a <- load_sch()[structure == "Same-school" & !is.na(get(TOP))]
MEDS <- list(SKIPPING = "m_SKIPPING", TARDYSD = "m_TARDYSD", BULLIED = "m_BULLIED", BELONG = "m_BELONG", EFFORT1 = "m_EFFORT1",
             joint = c("m_SKIPPING", "m_TARDYSD", "m_BULLIED", "m_BELONG"))
mech_sys <- function(s, meds) {
  ctrl <- CTRL[vapply(CTRL, function(v) mean(!is.na(s[[v]])) > 0.5 && var(s[[v]], na.rm = TRUE) > 0, logical(1))]
  s <- s[complete.cases(s[, c(meds, TOP), with = FALSE])]
  X0 <- cbind(`(Intercept)` = 1, as.matrix(s[, ..ctrl])); XM <- cbind(X0, as.matrix(s[, ..meds])); colnames(XM)[(ncol(X0) + 1):ncol(XM)] <- paste0("MED", seq_along(meds))
  M <- as.matrix(s[, TOP, with = FALSE]); colnames(M) <- "T"
  f <- function(dt, y, w) {
    tot <- tsls_m(y, dt$D, dt$Z, dt$r, M, X0, w)
    dir <- tsls_m(y, dt$D, dt$Z, dt$r, M, XM, w, extra = list(b = function(b2) unname(b2["MED1"])))
    out <- c(g0 = unname(tot["gamma"]), gT = unname(tot["gamma:T"]), d0 = unname(dir["gamma"]), dT = unname(dir["gamma:T"]),
             ind0 = unname(tot["gamma"] - dir["gamma"]), indT = unname(tot["gamma:T"] - dir["gamma:T"]))
    if (length(meds) == 1) { am <- tsls_m(dt[[meds]], dt$D, dt$Z, dt$r, M, X0, w); out <- c(out, a0 = unname(am["gamma"]), aT = unname(am["gamma:T"]), b = unname(dir["b"])) }
    out
  }
  e <- pisa_est(s, f, PV("ACH")); e[, n := nrow(s)]; e
}
one <- function(cn) {
  s0 <- a[CNT == cn]; out <- list()
  for (nm in names(MEDS)) { m <- MEDS[[nm]]; if (any(vapply(m, function(v) mean(!is.na(s0[[v]])) < 0.5, logical(1)))) next
    out[[length(out) + 1]] <- data.table(CNT = cn, mediator = nm, mech_sys(s0, m)) }
  log_step(cn, "done"); rbindlist(out)
}
res <- rbindlist(parallel::mclapply(sort(unique(a$CNT)), one, mc.cores = as.integer(Sys.getenv("NCORES", "3")), mc.preschedule = FALSE))
res[, `:=`(name = SYS_NAMES[CNT], top = TOP)]
fwrite(res, og("mechanism.csv"))
p <- res[, pool(est, se), by = .(mediator, term)]
print(dcast(p, mediator ~ term, value.var = "re_mean")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
print(dcast(p, mediator ~ term, value.var = "re_se")[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
