# IV learning -- step 11: checks on the between-school spread of step 10. Same schools, same routine (school_spread, 00_helpers.R),
# same scaling by the system's first stage, so every figure is in the units of step 10.
#   (A) false cutoff: inside one birth side (born before the cutoff; born after), students are split at the middle birth month of that
#       side. No grade jump separates the two halves, so any spread across schools comes from school-specific age effects or from
#       anything else tied to birth month inside a grade. The age gap between the halves is smaller than between the real groups; the
#       spread is also shown scaled up to the real age gap. A side is used only if each half spans two or more birth months and 30
#       or more schools keep 3 students in each half.
#   (B) balance: the real comparison (born before against born after) with family SES as the outcome. SES is fixed before school, so a
#       spread here means schools differ in who their two birth groups are, as with a new intake in the upper grade. It is
#       converted to score points with the SES gradient of step 6 (per SD of SES).
# Neither check can show that the remaining spread is learning; they size two things that are not.
# Reads central products and the outputs of steps 6 and 10. PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/11_school_spread_placebo.R
source("06_scoping/13_iv_learning/01_code/00_helpers.R")
source("06_scoping/13_iv_learning/01_code/sample_rules.R")
NPERM <- as.integer(Sys.getenv("NPERM", "200"))
STEP6 <- Sys.getenv("STEP6_DIR", file.path(PROJECT, "04_output/estimate_20261122_step6_gap_years"))
STEP10 <- Sys.getenv("STEP10_DIR", file.path(PROJECT, "04_output/estimate_20261122_step10_school_spread"))
OUT <- new_output(); sink(paste0(OUT, "log.txt"), split = TRUE)
real <- fread(file.path(STEP10, "school_spread_sys.csv")); realov <- fread(file.path(STEP10, "school_spread_overall.csv"))
GRAD <- fread(file.path(STEP6, "gap_years_pool.csv"))[term == "gapSD", re_mean]
a <- as.data.table(readRDS(ANALYTIC))[CNT %in% real$CNT]
for (p in 1:10) a[, (paste0("PV", p, "ACH")) := (get(paste0("PV", p, "MATH")) + get(paste0("PV", p, "READ")) + get(paste0("PV", p, "SCIE"))) / 3]
a[, `:=`(n_lo = sum(D == 0), n_hi = sum(D == 1), n_z1 = sum(Z == 1), n_z0 = sum(Z == 0)), by = .(CNT, CNTSCHID)]
a <- a[n_lo >= 5 & n_hi >= 5 & n_z1 >= 3 & n_z0 >= 3]                                   # the schools of step 10
stopifnot(all(a[, uniqueN(CNTSCHID), by = CNT][order(CNT), V1] == real[order(CNT), schools]))
SYS <- sort(real$CNT); gapm <- function(r, z, w) wmean(r[z == 0], w[z == 0]) - wmean(r[z == 1], w[z == 1])      # months between the two groups
keep3 <- function(s, z) { s[, zz := z]; s[, `:=`(k1 = sum(zz == 1), k0 = sum(zz == 0)), by = CNTSCHID]; s[k1 >= 3 & k0 >= 3] }
one <- function(cn) { set.seed(20261123 + match(cn, SYS)); s <- a[CNT == cn]; pi <- real[CNT == cn, first_stage]; real_gap <- gapm(s$r, s$Z, s$W_FSTUWT)
  out <- list(); perms <- list()
  for (side in c("before", "after")) { x <- s[Z == as.numeric(side == "before")]
    cut <- x[, .(w = sum(W_FSTUWT)), by = r][order(r)][, cw := cumsum(w) / sum(w)][cw >= .5, r][1]         # middle birth month of the side
    x <- keep3(x, as.numeric(x$r <= cut)); if (uniqueN(x$CNTSCHID) < 30 || uniqueN(x$zz) < 2) next
    if (x[, uniqueN(r), by = zz][, min(V1)] < 2) next          # a half with a single birth month cannot be told apart from the age slope
    o <- school_spread(x, x$zz, pi, PV("ACH"), NPERM); lab <- paste("false cutoff, born", side)
    out[[lab]] <- cbind(check = lab, o$sys, age_gap = gapm(x$r, x$zz, x$W_FSTUWT), real_age_gap = real_gap); perms[[lab]] <- o$perm }
  x <- keep3(s[!is.na(ESCS_z)], s[!is.na(ESCS_z), Z])
  if (uniqueN(x$CNTSCHID) >= 30) { o <- school_spread(x, x$zz, pi, "ESCS_z", NPERM); out[["balance on SES"]] <- cbind(check = "balance on SES", o$sys, age_gap = real_gap, real_age_gap = real_gap); perms[["balance on SES"]] <- o$perm }
  list(sys = cbind(CNT = cn, first_stage = pi, rbindlist(out)), perms = perms) }
res <- parallel::mclapply(SYS, function(cn) tryCatch(one(cn), error = function(e) { message(cn, ": ", conditionMessage(e)); NULL }), mc.cores = 6)
bad <- SYS[vapply(res, is.null, logical(1))]; if (length(bad)) stop("failed systems: ", paste(bad, collapse = " "))
names(res) <- SYS
sy <- merge(rbindlist(lapply(res, `[[`, "sys")), real[, .(CNT, same_level, main_set, real_sd = sd, real_p = p_perm)], by = "CNT")
fwrite(sy, paste0(OUT, "placebo_sys.csv"))
ov <- rbindlist(lapply(unique(sy$check), function(ck) { d <- sy[check == ck]; perms <- lapply(res[d$CNT], function(x) x$perms[[ck]]); names(perms) <- d$CNT
  f <- function(dd, lab) { if (!nrow(dd)) return(NULL); o <- spread_overall(dd, perms, lab, NPERM)
    o[, `:=`(check = ck, age_gap = weighted.mean(dd$age_gap, dd$schools), real_age_gap = weighted.mean(dd$real_age_gap, dd$schools))]; o }
  rbind(f(d, "all"), f(d[same_level == TRUE], "two grades in the same level of education"), f(d[same_level == FALSE], "two grades in different levels"), f(d[first_stage >= .5], "first stage within schools 0.5 or more")) }))
ov[check != "balance on SES", `:=`(sd_at_real_gap = sd * real_age_gap / age_gap, sd_hi_at_real_gap = sd_hi * real_age_gap / age_gap)]
ov[check == "balance on SES", `:=`(sd_points = sd * GRAD, sd_hi_points = sd_hi * GRAD, detectable_points = detectable_sd * GRAD)]
fwrite(ov, paste0(OUT, "placebo_overall.csv"))
code <- list.files(file.path(PROJECT, "01_code"), full.names = TRUE)
jsonlite::write_json(list(step = "11_school_spread_placebo", utc = format(Sys.time(), tz = "UTC", usetz = TRUE), git_commit = system("git rev-parse HEAD", intern = TRUE),
  systems = SYS, permutations = NPERM, ses_gradient = GRAD, md5 = as.list(tools::md5sum(c(ANALYTIC, file.path(STEP10, "school_spread_sys.csv"), file.path(STEP6, "gap_years_pool.csv"), code)))),
  paste0(OUT, "run.json"), auto_unbox = TRUE, pretty = TRUE)
options(width = 230)
cat("\nstep 10, for comparison (points)\n"); print(realov[, .(set, systems, schools, sd = round(sd, 1), sd_lo = round(sd_lo, 1), sd_hi = round(sd_hi, 1), p_perm, detectable = round(detectable_sd, 1))])
cat("\n(A) false cutoff inside one birth side (points; scaled = at the age gap of the real comparison)\n")
print(ov[check != "balance on SES", .(check, set, systems, schools, Q_df = round(Q / df, 2), perm_Q_df = round(Q_perm_mean / df, 2), p_perm = round(p_perm, 3), sd = round(sd, 1), sd_hi = round(sd_hi, 1), detectable = round(detectable_sd, 1),
  age_gap = round(age_gap, 1), real_age_gap = round(real_age_gap, 1), sd_scaled = round(sd_at_real_gap, 1), sd_hi_scaled = round(sd_hi_at_real_gap, 1))])
cat("\n(B) balance on family SES, real comparison (SD of SES per grade; points = x", round(GRAD, 1), "per SD of SES)\n")
print(ov[check == "balance on SES", .(set, systems, schools, Q_df = round(Q / df, 2), perm_Q_df = round(Q_perm_mean / df, 2), p_perm = round(p_perm, 3), sd = round(sd, 3), sd_hi = round(sd_hi, 3), sd_points = round(sd_points, 1), sd_hi_points = round(sd_hi_points, 1), detectable_points = round(detectable_points, 1))])
cat("\nsystems with a placebo spread at p < 0.05 / p < 0.10 only:\n"); print(sy[, .(p05 = sum(p_perm < .05), p10_only = sum(p_perm >= .05 & p_perm < .10), systems = .N, which05 = paste(CNT[p_perm < .05], collapse = " ")), by = check])
log_step("done"); sink()
