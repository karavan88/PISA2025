# Grade Gain Report -- shared helpers
# What a year of schooling adds at age 15, PISA 2025, every eligible system. Method aligned with Avvisati & Givord (2021, OECD EDU WP 257):
# actual grade instrumented by the theoretical grade implied by the school-entry cutoff and the birth month; school-starting age as a linear
# control; covariates sex, immigrant background, ESCS; whole 12-month PISA cohort. One model per system; medians and a random-effects
# meta-analysis across systems as the summaries. All outputs are CSV in 03_outputs/gradegain/; the report only reads them.
suppressPackageStartupMessages({ library(data.table) })

OUTD <- "03_outputs/01_harmonized/cutoff/"; dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
op <- function(f) paste0(OUTD, f)
SYSINFO <- fread(Sys.getenv("PISA_RD_SYSTEMS", "03_outputs/01_harmonized/cutoff/systems.csv"))
SYSINFO[, name := sub(" \\(China\\)", "", name)]; SYSINFO[CNT == "QCI", name := "B-S-J-Z (China)"]; SYSINFO[CNT == "QUA", name := "Ukraine (17 regions)"]; SYSINFO[CNT == "BRN", name := "Brunei"]
SYS_NAMES <- setNames(SYSINFO$name, SYSINFO$CNT)
REGION <- c(TAP = "East Asia", KOR = "East Asia", QCI = "East Asia", HKG = "East Asia", BRN = "Southeast Asia", PHL = "Southeast Asia", KHM = "Southeast Asia", THA = "Southeast Asia",
            GEO = "Post-Soviet", KAZ = "Post-Soviet", AZE = "Post-Soviet", QUA = "Post-Soviet", LVA = "Europe", EST = "Europe", FIN = "Europe", DNK = "Europe", SVK = "Europe", CZE = "Europe",
            DEU = "Europe", CHE = "Europe", ITA = "Europe", HRV = "Europe", SVN = "Europe", SRB = "Europe", MNE = "Europe", KSV = "Europe", ALB = "Europe", ROU = "Europe", GBR = "Europe",
            PER = "Latin America", PRY = "Latin America", BRA = "Latin America", CHL = "Latin America", CRI = "Latin America", ECU = "Latin America",
            USA = "North America", CAN = "North America", NZL = "Oceania", ISR = "Middle East", ARE = "Middle East", PSE = "Middle East", MUS = "Africa", KEN = "Africa", RWA = "Africa")
PV_DOMS <- c("SCIE", "MATH", "READ")
PV  <- function(dom) paste0("PV", 1:10, dom)
RW  <- paste0("W_FSTURWT", 1:80)
skill_wle <- c("PERSEV", "SELFREG", "GOALSET", "CURIO", "ENPROBS", "COGABIL", "BELONG")
out_skills <- paste0(skill_wle, "_z")
OUTCOMES <- c(PV_DOMS, out_skills, "growth")
out_lab <- function(x) { x <- sub("_z$", "", x); lab <- c(SCIE = "Science", MATH = "Mathematics", READ = "Reading", PERSEV = "Perseverance", SELFREG = "Self-regulated learning",
  GOALSET = "Goal setting", CURIO = "Curiosity", ENPROBS = "Enjoyment of problem-solving", COGABIL = "Cognitive adaptability", BELONG = "Sense of belonging", growth = "Growth mindset"); ifelse(x %in% names(lab), lab[x], x) }
is_score <- function(x) x %in% PV_DOMS

# eligibility rule (applied to the analysis sample, all programmes): a single, clean school-entry discontinuity
ELIG <- list(min_jump = 0.20,        # drop in P(upper grade) between adjacent birth months
             clean_ratio = 0.5,      # no other adjacent change larger than clean_ratio x the jump (one cutoff, monotone elsewhere)
             min_side = 1)           # at least one non-partial birth month on each side of the cutoff within the cohort


wmean <- function(x,w){ok<-!is.na(x)&!is.na(w);sum(x[ok]*w[ok])/sum(w[ok])}
wsd <- function(x,w){ok<-!is.na(x)&!is.na(w);m<-wmean(x,w);sqrt(sum(w[ok]*(x[ok]-m)^2)/sum(w[ok]))}
