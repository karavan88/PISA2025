# School Inputs & the Grade Gain — what makes a school year count? (PISA 2025, 14 same-school systems)

In systems where both grades of the PISA cohort share schools, the grade gain identified by the school-entry cutoff (actual grade
instrumented by the theoretical grade, school-starting age linear; Avvisati & Givord 2021, OECD EDU WP 257) is a causal estimate of what a
school adds in one year. School inputs are moderators of that annual flow; their level associations are the usual production-function
coefficients. Report: `04_manuscripts/schoolgain/report.qmd` → `report.html` (reads CSVs only).

Same-school systems (from `03_outputs/skillsgain/structure.csv`): ARE BRA BRN CRI DEU ECU EST FIN HKG HRV KHM MUS PER PHL.
Transition systems (KEN CZE QCI SVK TAP PRY) are excluded: their upper grade sits in a different school.

| Step | Script | Output | Notes |
|---|---|---|---|
| 1 | `01_build.py` | `schoolgain_school.csv`, `schoolgain_stu.csv.gz` | school questionnaire inputs; student climate scales and engagement mediators |
| 2 | `02_prepare.R` | `schoolgain_analytic.rds`, `coverage_inputs.csv`, `input_corr.csv` | 27 inputs (z within system); LOO climate means; peer SES; peer achievement from lower-grade schoolmates; decomposed-ESCS and skill controls |
| 2b | `02b_skills.R` | `skills_levels.csv` | the three skills with the strongest level association (curiosity, perseverance, problem-solving enjoyment) |
| 3 | `03_flow_level.R` | `flow_level.csv` | per input and system: flow (interacted 2SLS), flow net of peers, level (WLS); BRR + Rubin |
| 3b | `03b_top.R` | `top.csv` | stress tests of the top input (default school safety) |
| 4 | `04_forest.R` | `forest_*.csv`, `forest_scores.rds` | instrumental forest: BLP on all inputs, GATES, honest-split RATE, per-input RATE, VI |
| 5 | `05_decompose.R` | `decomp.csv`, `decomp_delta.csv` | Gelbach decomposition of the top input's moderation on DR scores |
| 6 | `06_mechanism.R` | `mechanism.csv` | moderated causal mediation through skipping, lateness, victimisation, belonging, effort |
| 7 | `07_pool.R` | `pool_*.csv`, `loso_top.csv` | random-effects pooling, BH q-values, leave-one-system-out |
