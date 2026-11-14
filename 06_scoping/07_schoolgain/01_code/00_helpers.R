# School Inputs & the Grade Gain -- shared helpers
# Which school inputs make a year of schooling at 15 more productive? An education production function estimated on causal annual flows.
# In "same-school" systems both grades of the PISA cohort sit in the same schools, so the grade gain inside a school -- identified by the
# school-entry cutoff (actual grade instrumented by the theoretical grade, school-starting age linear; Avvisati & Givord 2021, OECD EDU WP 257)
# -- is a causal estimate of what that school adds in one year. School inputs are moderators of that gain:
#   endogenous D, D*M ; instruments Z, Z*M ; exogenous 1, r, r*M, M, controls    ->  gamma_M = b_DM - 12 b_rM  (change in the gain per SD of M)
# Levels: the same input's cross-sectional association with achievement (the usual production-function coefficient), for comparison.
# Estimation is per system (Fay BRR + Rubin over PVs); pooling by DerSimonian-Laird random effects. Reuses the Skills & Grade Gain helpers.
suppressPackageStartupMessages({ library(data.table) })
source("02_scripts/skillsgain/00_helpers.R")                               # tsls_m, est_sys, pool, rubin, PV, wls, pisa_est, SYS20, zw ...
OUTG <- "03_outputs/schoolgain/"; dir.create(OUTG, recursive = TRUE, showWarnings = FALSE)
og <- function(f) paste0(OUTG, f)
load_sch <- function() readRDS("01_data/derived/schoolgain_analytic.rds")

# school inputs (all standardised within system at the student level; binaries too, so every coefficient is per SD)
INPUTS <- data.table(var = c("CLSIZE", "STRATIO", "SCHSIZE", "EDUSHORT", "STAFFSHORT", "DIGPREP",
                             "PROATCE", "PROPAT7", "SCTRAIN", "PROPSUPP",
                             "EDULEAD", "SCHSEL", "ABGSCIE", "PRIVATE", "URBAN", "STDTEST", "TDTEST", "ENCOURPG", "ALLACTIV",
                             "NEGSCLIM", "s_DISC", "s_TSUP", "s_COGA", "s_BULL", "s_SAFE",
                             "peer_SES", "peer_ach"),
                     group = c(rep("Resources", 6), rep("Teachers", 4), rep("Organisation & leadership", 9), rep("Climate", 6), rep("Peers", 2)),
                     label = c("Class size", "Student-teacher ratio", "School size", "Shortage of educational material", "Shortage of educational staff", "Preparedness for digital learning",
                               "Share of fully certified teachers", "Share of teachers with a master's (ISCED 7)", "Science teacher training", "Share of pedagogical support staff",
                               "Educational leadership", "Academic selectivity in admission", "Ability grouping (science)", "Private school", "Urban (city of 100,000+)", "Use of standardised tests", "Use of teacher-developed tests", "Encouragement of parental involvement", "Extra-curricular activities",
                               "Negative school climate (principal)", "Disciplinary climate (students)", "Teacher support (students)", "Cognitive activation (students)", "Bullying (students)", "Feeling safe (students)",
                               "Peer SES (school mean ESCS)", "Peer achievement (lower-grade schoolmates)"))
in_lab <- function(x) { l <- setNames(INPUTS$label, INPUTS$var); ifelse(x %in% names(l), l[x], x) }
in_grp <- function(x) { g <- setNames(INPUTS$group, INPUTS$var); ifelse(x %in% names(g), g[x], NA_character_) }
# student controls: decomposed ESCS (highest parental occupation, parental education in years, home possessions), books (Costa Rica, which
# has none of the three), the three skills with the strongest cross-sectional association, sex, immigrant background; missing -> 0 + flag
CTRL <- c("female", "immigrant", "HISEI_z", "PAREDINT_z", "HOMEPOS_z", "books_cri", "ses_mis", "CURIO_c", "PERSEV_c", "ENPROBS_c", "skill_mis")
SKILL3 <- c("CURIO", "PERSEV", "ENPROBS")
