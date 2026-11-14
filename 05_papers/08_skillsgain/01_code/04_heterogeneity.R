# Skills & the Grade Gain -- who gains more from a school year? Interacted 2SLS, one system at a time.
# Each specification returns gamma (grade gain at the system mean of the moderators) and gamma:M (change in the grade gain per SD of M).
# Samples: "ses"    = students with student SES (all 20 systems)
#          "skills" = students with SE, SES and school SES (19 systems; Cambodia fielded no scales) -- every SE specification and its
#                     SES-only comparison run on this common sample so coefficients can be compared across columns.
# Specifications (controls: female, immigrant):
#   ses      : SES                          | sch      : schSES             | ses_sch  : SES + schSES                 (sample ses)
#   ses_sch_s: SES + schSES (skills sample) | se       : SE                 | joint    : SE + SES + schSES
#   inter    : joint + SE x SES + SE x schSES   (do skills compensate for disadvantage? -> negative interactions)
#   parts    : SE_task + SE_open + SES + schSES | purged : SE_p + SES + schSES (moderator freed of the grade's own effect on SE)
#   joint_fe : joint with school fixed effects (within-school contrasts; ACH only)
#   scale_X  : one scale X + SES + schSES (ACH only)
# Levels: WLS of the score on the same moderators + D + r (the cross-sectional gradients, to compare a year's gain with the stock gap).
# Usage: Rscript 02_scripts/skillsgain/04_heterogeneity.R [CNT ...]   Output: 03_outputs/skillsgain/het.csv, levels.csv
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/skillsgain/00_helpers.R")
a <- load_sg(); args <- commandArgs(trailingOnly = TRUE); systems <- if (length(args)) args else SYS20
SPECS <- list(ses = "SES", sch = "schSES", ses_sch = c("SES", "schSES"),
              ses_sch_s = c("SES", "schSES"), se = "SE", joint = c("SE", "SES", "schSES"), inter = c("SE", "SES", "schSES", "SExSES", "SExschSES"),
              parts = c("SE_task", "SE_open", "SES", "schSES"), purged = c("SE_p", "SES", "schSES"))
SAMPLE <- c(ses = "ses", sch = "ses", ses_sch = "ses")                      # everything else: skills sample
one_system <- function(cn) {
  res <- list(); lev <- list()
  s_all <- a[CNT == cn & !is.na(SES)]
  s_sk  <- a[CNT == cn & !is.na(SE) & !is.na(SES) & !is.na(schSES)]
  has_sk <- nrow(s_sk) >= 500
  for (sp in names(SPECS)) {
    smp <- if (sp %in% names(SAMPLE)) "ses" else "skills"; if (smp == "skills" && !has_sk) next
    s <- if (smp == "ses") s_all[!is.na(schSES) | sp == "ses"] else s_sk
    for (o in OUT4) res[[length(res) + 1]] <- data.table(CNT = cn, spec = sp, sample = smp, outcome = o, est_sys(s, o, mods = SPECS[[sp]]))
  }
  if (has_sk) {
    res[[length(res) + 1]] <- data.table(CNT = cn, spec = "joint_fe", sample = "skills", outcome = "ACH", est_sys(s_sk, "ACH", mods = SPECS$joint, fe = "school"))
    for (sc in SE6) { if (mean(!is.na(s_sk[[sc]])) < 0.5) next
      ss <- s_sk[!is.na(get(sc))]; res[[length(res) + 1]] <- data.table(CNT = cn, spec = paste0("scale_", sc), sample = "skills", outcome = "ACH", est_sys(ss, "ACH", mods = c(sc, "SES", "schSES"))) }
    # cross-sectional gradients in levels (same sample, same covariates, grade and running variable held fixed)
    for (o in OUT4) {
      X <- cbind(1, D = s_sk$D, r = s_sk$r, SE = s_sk$SE, SES = s_sk$SES, schSES = s_sk$schSES, female = s_sk$female, immigrant = s_sk$immigrant)
      X <- X[, colMeans(!is.na(X)) > 0.5, drop = FALSE]                    # a control missing for most students is dropped (sex in Germany, immigrant in Mauritius)
      f <- function(dt, y, w) { b <- wls(X, y, w); c(lev_SE = unname(b["SE"]), lev_SES = unname(b["SES"]), lev_schSES = unname(b["schSES"])) }
      lev[[length(lev) + 1]] <- data.table(CNT = cn, outcome = o, pisa_est(s_sk, f, PV(o)))
    }
  }
  log_step(cn, "done")
  list(res = rbindlist(res, fill = TRUE), lev = rbindlist(lev))
}
out_l <- parallel::mclapply(systems, one_system, mc.cores = as.integer(Sys.getenv("NCORES", "6")), mc.preschedule = FALSE)
bad <- which(sapply(out_l, inherits, "try-error")); if (length(bad)) { print(out_l[bad]); stop("failed: ", paste(systems[bad], collapse = " ")) }
res <- rbindlist(lapply(out_l, `[[`, "res"), fill = TRUE); lev <- rbindlist(lapply(out_l, `[[`, "lev"), fill = TRUE)
for (x in list(res, lev)) x[, `:=`(name = SYS_NAMES[CNT], group = GROUP[CNT])]
out <- os("het.csv"); if (length(args) && file.exists(out)) res <- rbind(fread(out)[!CNT %in% systems], res, fill = TRUE); fwrite(res, out)
out <- os("levels.csv"); if (length(args) && file.exists(out)) lev <- rbind(fread(out)[!CNT %in% systems], lev, fill = TRUE); fwrite(lev, out)
print(dcast(res[outcome == "ACH" & spec == "joint"], CNT ~ term, value.var = "est", fun.aggregate = function(x) round(x[1], 1)))
log_step("heterogeneity done")
