# EPF post-Soviet paper -- shared helpers
# One model per system; all estimation outputs go to 03_outputs/epf_postsoviet/<DOMAIN>/ as CSV; the manuscript only reads CSVs.
suppressPackageStartupMessages({ library(data.table) })

PS       <- c("KAZ", "UZB", "AZE", "GEO", "ARM", "KGZ", "MDA")
PS_NAMES <- c(KAZ = "Kazakhstan", UZB = "Uzbekistan", AZE = "Azerbaijan", GEO = "Georgia", ARM = "Armenia", KGZ = "Kyrgyzstan", MDA = "Moldova")
RD_SYS   <- c(GEO = 10, AZE = 10, KAZ = 9)   # systems with a usable school-entry cutoff and the first birth month AFTER the cutoff (see 00_feasibility_audit)

DOMAIN <- Sys.getenv("PISA_DOMAIN", "SCIE")            # SCIE (headline; only domain Uzbekistan took) | MATH | READ
PROFILE <- Sys.getenv("PISA_PROFILE", "FAST")          # FAST = PV1 only, few bootstrap draws (development); FULL = all PVs, R = 200
PV   <- paste0("PV", 1:10, DOMAIN)
RW   <- paste0("W_FSTURWT", 1:80)
NPV  <- if (PROFILE == "FULL") 10 else 1               # PVs used in the heavy (lqmm) models; mean models always use all 10
NBOOT <- if (PROFILE == "FULL") 200 else 30            # school block-bootstrap draws for lqmm
OUTD <- paste0("03_outputs/epf_postsoviet/", DOMAIN, "/")
dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
op <- function(f) paste0(OUTD, f)
dom_lab <- c(SCIE = "science", MATH = "mathematics", READ = "reading")[DOMAIN]

# ---- variable blocks -------------------------------------------------------------------------------------------------
student_ctrl <- c("female", "lang_other", "immigrant", "repeated")
hh_ctrl      <- c("ESCS_pct10")                                     # within-system percentile rank of ESCS / 10
school_ctrl  <- c("sch_escs_loo", "rural", "private", "clsize", "stratio_med", "proatce", "STAFFSHORT", "EDUSHORT", "infra_poor", "rus_medium", "sel_policy")
skill_dom    <- c("task", "open", "adapt", "growth")               # Big Five-organised domain scores (+ binary growth mindset)
skill_wle    <- c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL")
skill_lab    <- c(task = "Task performance (conscientiousness)", open = "Open-mindedness (openness)", adapt = "Adaptability (compound)", growth = "Growth mindset (binary)",
                  PERSEV = "Perseverance", SELFREG = "Self-regulated learning", GOALSET = "Goal setting", CURIO = "Curiosity", ENPROBS = "Problem-solving enjoyment", COGABIL = "Cognitive adaptability")
term_lab <- c(grade_c = "Grade (one year further)", female = "Female", lang_other = "Home language differs from test language", immigrant = "Immigrant background",
              repeated = "Repeated a grade", ESCS_pct10 = "ESCS percentile rank (per 10 points)", sch_escs_loo = "School-mean ESCS (leave-one-out, index units)",
              rural = "Rural or small-town school", private = "Private school", clsize = "Class size (students)", stratio_med = "Student-teacher ratio (quartile median)",
              proatce = "Certified-teacher share (international quintile 1-5)", STAFFSHORT = "Staff shortage (WLE)", EDUSHORT = "Material shortage (WLE)", infra_poor = "Poor infrastructure hinders instruction",
              rus_medium = "Russian-medium school", sel_policy = "School has an SEL policy", skill_lab)

# ---- data -------------------------------------------------------------------------------------------------------------
load_analytic <- function() {
  a <- readRDS("01_data/derived/epf_analytic.rds")
  a <- a[!is.na(get(PV[1]))]                                        # Uzbekistan has science only
  a[, CNT := factor(CNT, levels = PS[PS %in% unique(CNT)])]
  a
}

# ---- PISA inference: Fay BRR (k = 0.5) sampling variance on PV1 + Rubin imputation variance over PVs ----------------
# statfun(dt, y, w) -> named numeric vector
pisa_est <- function(dt, statfun, pvs = PV, reps = RW, brr = TRUE) {
  th_pv <- sapply(pvs, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT))
  if (is.null(dim(th_pv))) th_pv <- matrix(th_pv, nrow = 1, dimnames = list(names(th_pv)[1], pvs))
  est   <- rowMeans(th_pv)
  v_imp <- if (length(pvs) > 1) (1 + 1 / length(pvs)) * apply(th_pv, 1, var) else 0
  if (brr) {
    th_r <- sapply(reps, function(r) statfun(dt, dt[[pvs[1]]], dt[[r]]))
    if (is.null(dim(th_r))) th_r <- matrix(th_r, nrow = 1)
    v_samp <- rowSums((th_r - th_pv[, 1])^2) / 20
  } else v_samp <- 0
  data.table(term = names(est), est = est, se = sqrt(v_samp + v_imp), se_samp = sqrt(v_samp), se_imp = sqrt(v_imp))
}

# weighted least squares on a fixed design matrix; constant columns dropped (e.g. private school where none is private)
wls <- function(X, y, w) { ok <- !is.na(y) & !is.na(w); f <- lm.wfit(X[ok, , drop = FALSE], y[ok], w[ok]); f$coefficients }
clean_X <- function(X) {
  keep <- vapply(seq_len(ncol(X)), function(j) { v <- X[, j]; !all(is.na(v)) && (colnames(X)[j] == "(Intercept)" || sd(v, na.rm = TRUE) > 0) }, logical(1))
  X[, keep, drop = FALSE]
}
build_X <- function(dt, rhs) { X <- model.matrix(as.formula(paste("~", paste(rhs, collapse = " + "))), dt); clean_X(X) }

# Rubin combination of a (est, var) pair across PVs when models are fitted PV by PV (lqmm)
rubin <- function(est, var) { m <- length(est); list(est = mean(est), se = sqrt(mean(var) + (1 + 1 / m) * (if (m > 1) var(est) else 0))) }

# weighted quantile / weighted mean / weighted sd
wmean <- function(x, w) { ok <- !is.na(x) & !is.na(w); sum(x[ok] * w[ok]) / sum(w[ok]) }
wsd   <- function(x, w) { ok <- !is.na(x) & !is.na(w); m <- wmean(x[ok], w[ok]); sqrt(sum(w[ok] * (x[ok] - m)^2) / sum(w[ok])) }
wquant <- function(x, w, p) { ok <- !is.na(x) & !is.na(w); o <- order(x[ok]); cw <- cumsum(w[ok][o]) / sum(w[ok]); x[ok][o][which(cw >= p)[1]] }

# median and IQR across systems (the paper's summary statistic; no bloc averages)
summ_systems <- function(dt, col = "est") dt[, .(median = median(get(col), na.rm = TRUE), q25 = quantile(get(col), .25, na.rm = TRUE), q75 = quantile(get(col), .75, na.rm = TRUE), n_sys = sum(!is.na(get(col))))]

log_step <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
