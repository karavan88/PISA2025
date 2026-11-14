# Paper B -- Does schooling make you persevere? Fuzzy RD at the school-entry cutoff (PISA 2025) -- shared helpers
# One model per system; every estimation output goes to 03_outputs/paperB/ as CSV; the manuscript only reads CSVs.
suppressPackageStartupMessages({ library(data.table) })

# Tier 1 -- sharp, clean school-entry cutoff (jump in P(upper grade) >= 0.45 across one birth month, flat elsewhere; cutoff_audit_all.csv):
# the headline sample of Papers B and C. Tier 2 -- fuzzy cutoff (jump 0.25-0.45, often with a sloping profile): appendix check only.
# Excluded for structural reasons: UK (two cutoffs in one sample), Palestinian Authority (cutoff at the edge of the cohort). Region is a label only.
SYS_SHARP <- c("TAP", "KOR", "QCI", "HKG", "BRN", "PHL", "GEO", "FIN", "EST", "SVK", "HRV", "SRB", "PER", "PRY")
SYS_FUZZY <- c("MUS", "USA", "CRI", "KEN", "KHM", "KAZ", "ALB", "NZL", "BRA", "AZE", "MNE", "KSV", "CHL", "ISR")
SYS <- c(SYS_SHARP, SYS_FUZZY)
TIER <- c(setNames(rep("sharp", length(SYS_SHARP)), SYS_SHARP), setNames(rep("fuzzy", length(SYS_FUZZY)), SYS_FUZZY))
SYS_NAMES <- c(TAP = "Chinese Taipei", KOR = "Korea", QCI = "B-S-J-Z (China)", HKG = "Hong Kong", BRN = "Brunei", PHL = "Philippines",
               GEO = "Georgia", FIN = "Finland", EST = "Estonia", SVK = "Slovakia", HRV = "Croatia", SRB = "Serbia", PER = "Peru", PRY = "Paraguay",
               MUS = "Mauritius", USA = "United States", CRI = "Costa Rica", KEN = "Kenya", KHM = "Cambodia", KAZ = "Kazakhstan", ALB = "Albania",
               NZL = "New Zealand", BRA = "Brazil", AZE = "Azerbaijan", MNE = "Montenegro", KSV = "Kosovo", CHL = "Chile", ISR = "Israel")
REGION <- c(TAP = "East Asia", KOR = "East Asia", QCI = "East Asia", HKG = "East Asia", BRN = "Southeast Asia", PHL = "Southeast Asia",
            GEO = "Post-Soviet", FIN = "Europe", EST = "Europe", SVK = "Europe", HRV = "Europe", SRB = "Europe", PER = "Latin America", PRY = "Latin America",
            MUS = "Africa", USA = "North America", CRI = "Latin America", KEN = "Africa", KHM = "Southeast Asia", KAZ = "Post-Soviet", ALB = "Europe",
            NZL = "Oceania", BRA = "Latin America", AZE = "Post-Soviet", MNE = "Europe", KSV = "Europe", CHL = "Latin America", ISR = "Middle East")

PV_DOMS <- c("SCIE", "MATH", "READ")
PV  <- function(dom) paste0("PV", 1:10, dom)
RW  <- paste0("W_FSTURWT", 1:80)
OUTD <- "03_outputs/paperB/"; dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
op <- function(f) paste0(OUTD, f)

# outcomes: six SSES-type scales + belonging (within-system SD units), three beliefs (binary), achievement (points)
skill_wle <- c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL")
skill_lab <- c(PERSEV = "Perseverance", SELFREG = "Self-regulated learning", GOALSET = "Goal setting", CURIO = "Curiosity",
               ENPROBS = "Enjoyment of problem-solving", COGABIL = "Cognitive adaptability", BELONG = "Sense of belonging",
               growth = "Growth mindset (intelligence)", growth_sci = "Growth mindset (science ability)", fatalism = "Status fatalism",
               SCIE = "Science score", MATH = "Mathematics score", READ = "Reading score")
out_skills  <- c(paste0(skill_wle, "_z"), "BELONG_z")
out_beliefs <- c("growth", "growth_sci", "fatalism")
out_lab <- function(x) { x <- sub("_z$", "", x); ifelse(x %in% names(skill_lab), skill_lab[x], x) }
balance_vars <- c("ESCS", "female", "immigrant", "lang_other", "repeated")

BANDWIDTHS <- c(3, 4, 6)          # months on each side of the cutoff (6 = the whole 12-month cohort where the cutoff is central)

load_analytic <- function() readRDS("01_data/derived/paperB_analytic.rds")

# weighted least squares on a fixed design; returns coefficients
wls <- function(X, y, w) { ok <- !is.na(y) & !is.na(w) & complete.cases(X); f <- lm.wfit(X[ok, , drop = FALSE], y[ok], w[ok]); f$coefficients }

# Fay BRR (k = 0.5) sampling variance + Rubin imputation variance across PVs. statfun(dt, y, w) -> named numeric vector
pisa_est <- function(dt, statfun, ys, brr = TRUE) {
  th_pv <- sapply(ys, function(p) statfun(dt, dt[[p]], dt$W_FSTUWT))
  if (is.null(dim(th_pv))) th_pv <- matrix(th_pv, nrow = 1, dimnames = list(names(th_pv)[1], ys))
  est <- rowMeans(th_pv)
  v_imp <- if (length(ys) > 1) (1 + 1 / length(ys)) * apply(th_pv, 1, var) else 0
  v_samp <- 0
  if (brr) { th_r <- sapply(RW, function(r) statfun(dt, dt[[ys[1]]], dt[[r]])); if (is.null(dim(th_r))) th_r <- matrix(th_r, nrow = 1); v_samp <- rowSums((th_r - th_pv[, 1])^2) / 20 }
  data.table(term = names(est), est = est, se = sqrt(v_samp + v_imp), se_samp = sqrt(v_samp), se_imp = sqrt(v_imp))
}

wmean <- function(x, w) { ok <- !is.na(x) & !is.na(w); sum(x[ok] * w[ok]) / sum(w[ok]) }
wsd   <- function(x, w) { ok <- !is.na(x) & !is.na(w); m <- wmean(x[ok], w[ok]); sqrt(sum(w[ok] * (x[ok] - m)^2) / sum(w[ok])) }
summ_systems <- function(dt, col = "est") dt[, .(median = median(get(col), na.rm = TRUE), q25 = quantile(get(col), .25, na.rm = TRUE), q75 = quantile(get(col), .75, na.rm = TRUE), n_sys = sum(!is.na(get(col))))]
log_step <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
