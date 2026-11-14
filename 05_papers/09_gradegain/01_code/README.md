# Grade Gain Report — what a year of schooling adds at age 15 (PISA 2025, every eligible system)

Method aligned with Avvisati & Givord (2021, OECD EDU WP 257; Labour Economics 2023): actual grade instrumented by the theoretical grade
implied by the school-entry cutoff and birth month; school-starting age as a linear control; covariates sex, immigrant background, ESCS;
whole 12-month PISA cohort; one model per system; medians + random-effects meta-analysis across systems. Fully reproducible in R from the CSVs.

| Step | Script | Output | Notes |
|---|---|---|---|
| 0 | audit (Paper B) | `03_outputs/gradegain/cutoff_audit_all.csv` | P(upper grade) by birth month for all 91 systems, general programmes |
| 1 | `01_build.py` (Mac, pyreadstat, ~75 s) | `01_data/derived/gradegain_students.csv.gz`, `gradegain_systems.csv` | every system with audit jump ≥ 0.15 (44) |
| 2 | `02_prepare.R` | `gradegain_analytic.rds`, `eligibility.csv`, `compliance.csv` | cutoff re-detected on all programmes (one- or two-month drop); eligibility rule; donut for a partial cutoff month; `ssa`, `Z`, within-system z-scores |
| 3 | `03_gradegain.R` | `estimates.csv` | per system: 2SLS with covariates (`ag_cov`, headline) and without (`ag_nocov`): terms `fs`, `tau`, `beta`, `gamma`; LSDV grade coefficient (`lsdv`); 11 outcomes; BRR + Rubin |
| 4 | `04_summary.R` | `summary.csv`, `summary_clean_only.csv`, `summary_region.csv`, `shrunken.csv` | medians/IQR, significance counts, REML meta-analysis (metafor), BLUPs |
| — | `run_all_estimation.sh` | steps 2–4 | make-like; ~10 min; `FORCE=1` |
| — | `04_manuscripts/gradegain/report.qmd` | `report.html` | reads CSVs only |

## Eligibility (applied on the all-programme sample)
Drop in P(upper grade) ≥ 0.20 between adjacent months (or across two months around a partial month, which is then dropped); no other adjacent
change larger than half the drop; at least one month on each side. Where the only month on one side is partial it is kept ("edge" flag).
2025: 36 eligible (27 clean + 9 edge: PRY, PSE, KHM, ISR, KSV, SVN, CHL, NZL, LVA); excluded GBR (two cutoffs), CHE, THA, MNE (not clean), DNK, RWA, CAN, ITA (< 0.20).

## The three bundles (age at test = starting age + years of schooling → only two contrasts identified)
- `tau`   = coef on D: one more year of school at the same age (youngest in the grade) — fixed-age contrast
- `beta`  = −12 × coef on r: one more year of age inside a grade
- `gamma` = tau + beta: one more year of schooling with its year of age, starting age fixed — the grade gain (A&G estimand, headline)
- `lsdv`  = cross-sectional grade coefficient (birth-month dummies + covariates): gamma + selection

## Headline numbers (2025, 36 systems, medians): science 15.2, maths 18.2, reading 15.9 points (RE means 14.9 / 16.8 / 16.1 ± 1.5–1.7);
significant in 19–22, negative in none; LSDV 35–38; skills all within ±0.06 SD (curiosity +0.06, 7 systems significant).
Labels follow the 2025 codebook: ENPROBS = enjoyment of problem-solving, COGABIL = cognitive adaptability.
