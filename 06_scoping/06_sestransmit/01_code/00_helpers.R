# sestransmit -- shared definitions. Independent pipeline (reads only 01_data/derived/sestransmit_*; writes only 03_outputs/sestransmit/).
suppressPackageStartupMessages({library(data.table)})
OUT  <- "03_outputs/sestransmit/"
tp   <- function(f) paste0(OUT, "tables/", f)
fp   <- function(f) paste0(OUT, "figures/", f)
ap   <- function(f) paste0(OUT, "audit/", f)
wle_skills <- c("PERSEV", "CURIO", "ENPROBS", "COGABIL", "GOALSET", "SELFREG")
skills     <- c(wle_skills, "GROWTH")
skill_lab  <- c(PERSEV = "Perseverance", CURIO = "Curiosity", ENPROBS = "Enjoyment of problem-solving",
                COGABIL = "Cognitive adaptability", GOALSET = "Goal setting", SELFREG = "Self-regulated learning",
                GROWTH = "Growth mindset")
stu_ctrl <- c("female", "AGE", "grade_rel", "immig", "lang_other")
sch_ctrl <- c("sch_pct_loo", "private", "urban1", "urban2")
EXCLUDE  <- c(KHM = "no socio-emotional scales fielded", CRI = "no ESCS or components", SLV = "no ESCS or components")
RW <- paste0("W_FSTURWT", 1:80)
P10P90 <- 8   # moving from the 10th to the 90th within-country percentile = 80 percentile points = 8 units of ESCS_pct10
TMIN <- 2   # a mediated *share* is reported only where the gradient it divides is estimated with |t| > TMIN (otherwise the ratio is uninformative)
# mark unreliable shares as NA in the long estimates file
apply_tmin <- function(R) { g <- R[stat == "beta_tot", .(CNT, run, domain, spec, t_tot = abs(est / se))]; R <- merge(R, g, by = c("CNT", "run", "domain", "spec"), all.x = TRUE)
  R[quantity %in% c("joint_share", "ashare", "dshare") & t_tot <= TMIN, `:=`(est = NA_real_, se = NA_real_)]; R }
