# Paper A -- shared helpers: PISA-style inference (Fay BRR sampling variance + PV imputation variance)
suppressPackageStartupMessages({library(data.table)})
skills    <- c("PERSEV", "CURIO", "ENPROBS", "COGABIL", "GOALSET", "SELFREG", "GROWTH")   # six WLE scales (sample-standardised) + binary growth mindset
skill_lab <- c(PERSEV = "Perseverance", CURIO = "Curiosity", ENPROBS = "Problem-solving enjoyment",
               COGABIL = "Stress adaptability", GOALSET = "Goal setting", SELFREG = "Self-regulated learning", GROWTH = "Growth mindset")
binary_skills <- c("GROWTH")
controls  <- c("female", "AGE", "grade_rel", "repeated", "immig2", "lang_other")
sch_ctrl  <- c("sch_escs_loo", "private", "urban")
pal_bloc  <- c("East Asia" = "#0072B2", "Post-Soviet" = "#D55E00", "Post-communist Europe" = "#009E73")
# Exposure (treatment) for the mediation models: ESCS_PCT = within-system percentile rank of ESCS / 10 (headline; one unit = 10 percentile
# points); ESCS = the ESCS index in its own units (check); DEP = number of deprivation items the family cannot afford (second exposure,
# estimated conditional on ESCS). Set with PISA_TREAT=... ; output files carry the suffix TSUF.
TREAT     <- Sys.getenv("PISA_TREAT", "ESCS_PCT")
TREAT_VAR <- c(ESCS = "ESCS", ESCS_PCT = "ESCS_pct10", DEP = "DEP")[TREAT]
TSUF      <- c(ESCS = "", ESCS_PCT = "_pct", DEP = "_dep")[TREAT]
SCH_LOO   <- if (TREAT == "DEP") c("sch_escs_loo", "sch_dep_loo") else if (TREAT == "ESCS_PCT") "sch_pct_loo" else "sch_escs_loo"   # school-mean (Mundlak) controls
TREAT_COV <- if (TREAT == "DEP") "ESCS" else character(0)   # deprivation effects are estimated at a given ESCS
DOMAIN <- Sys.getenv("PISA_DOMAIN", "READ")          # READ | MATH | SCIE ; set with PISA_DOMAIN=MATH Rscript ...
PV  <- paste0("PV", 1:10, DOMAIN)
OUTD <- paste0("03_outputs/paperA/", DOMAIN, "/"); dir.create(paste0(OUTD, "tables"), recursive = TRUE, showWarnings = FALSE); dir.create(paste0(OUTD, "figures"), recursive = TRUE, showWarnings = FALSE)
tp <- function(f) paste0(OUTD, "tables/", f); fp <- function(f) paste0(OUTD, "figures/", f)
dom_lab <- c(READ = "reading", MATH = "mathematics", SCIE = "science")[DOMAIN]
RW  <- paste0("W_FSTURWT", 1:80)

# statfun(dt, y, w) -> named numeric vector of statistics. Returns estimate, SE, and components.
# Sampling variance: Fay's BRR with k = 0.5 -> var = (1/(80*(1-0.5)^2)) * sum (theta_r - theta)^2 = sum(...)/20, computed on PV1.
# Imputation variance: over 10 PVs with the full weight, Rubin: (1 + 1/M) * var(theta_m).
pisa_est <- function(dt, statfun, pvs = PV, reps = RW, brr = TRUE) {
  th_pv <- sapply(pvs, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT))
  if (is.null(dim(th_pv))) th_pv <- matrix(th_pv, nrow = 1, dimnames = list(names(th_pv)[1], pvs))
  est <- rowMeans(th_pv)
  v_imp <- (1 + 1 / length(pvs)) * apply(th_pv, 1, var)
  if (brr) {
    th_r <- sapply(reps, function(r) statfun(dt, dt[[pvs[1]]], dt[[r]]))
    if (is.null(dim(th_r))) th_r <- matrix(th_r, nrow = 1)
    v_samp <- rowSums((th_r - th_pv[, 1])^2) / 20
  } else v_samp <- 0
  data.table(term = names(est), est = est, se = sqrt(v_samp + v_imp), se_samp = sqrt(v_samp), se_imp = sqrt(v_imp))
}

# weighted least squares coefficients for a fixed design matrix
wls <- function(X, y, w) { ok <- !is.na(y); fit <- lm.wfit(X[ok, , drop = FALSE], y[ok], w[ok]); fit$coefficients }

# drop constant / all-NA columns from a design matrix (e.g. Macao school controls, single-grade economies)
clean_X <- function(X) {
  keep <- apply(X, 2, function(c) !all(is.na(c)) && (colnames(X)[1] == "(Intercept)" && FALSE || sd(c, na.rm = TRUE) > 0))
  keep[1] <- TRUE
  X[, keep, drop = FALSE]
}

# analytic sample restricted to students with PVs in the chosen domain (Uzbekistan has no reading/maths PVs in the PUF)
load_analytic <- function() {
  a <- readRDS("01_data/derived/paperA_analytic.rds"); a <- a[!is.na(get(PV[1]))]
  a[, CNT := droplevels(CNT)]; a[, economy := droplevels(economy)]
  fwrite(data.table(n = uniqueN(a$CNT)), tp("n_economies.txt")); ALL_LAB <<- paste0("All ", uniqueN(a$CNT), " economies"); a
}
ALL_LAB <- if (file.exists(tp("n_economies.txt"))) paste0("All ", fread(tp("n_economies.txt"))$n, " economies") else "All 20 economies"
