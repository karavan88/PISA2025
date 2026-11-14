# Paper B — Does schooling make you persevere? Fuzzy RD at the school-entry cutoff (PISA 2025)

Question: does one additional year of schooling by age 15 — induced by the school-entry birth-month cutoff — change students'
socio-emotional skills, beliefs and science achievement, and how much of the achievement effect runs through the skills?
Every model is estimated separately for each system; the summary across systems is the median (with IQR). Regions are labels only.

## Pipeline (run from the repo root)

| Step | Script | Output | Notes |
|---|---|---|---|
| 0 | audit (inline python, saved) | `03_outputs/paperB/cutoff_audit_all.csv` | P(upper grade) by birth month for every PISA 2025 system, general programmes; the sample = jump ≥ 0.45 |
| 1 | `01_build.py` (Mac, pyreadstat, ~40 s) | `01_data/derived/paperB_students.csv.gz` | 14 systems, all students, skills, beliefs, belonging, PVs, 80 BRR weights |
| 2 | `02_prepare.R` | `paperB_analytic.rds`, `cutoffs.csv`, `compliance.csv` | cutoff re-detected on all programmes; running variable r (months from the first post-cutoff month), Z = 1[r<0], D = upper grade; within-system z-scores; donut flag for a partial cutoff month |
| 3 | `03_rd.R` | `rd_estimates.csv`, `rd_balance.csv` | fuzzy RD (Wald) per system × outcome × bandwidth (3/4/6) × spec (ll / common / diff); BRR + Rubin |
| 4 | `04_mediation.R` | `med_share.csv` | Σ β_k τ_Mk decomposition of the science effect (product of coefficients, not Imai) |
| 5 | `05_placebo.R` | `rd_placebo.csv` | fake cutoffs ±3 months, one side only |
| — | `run_all_estimation.sh` | all of the above | make-like (timestamps); whole chain ≈ 5 min; `FORCE=1` reruns |
| — | `04_manuscripts/paperB/report.qmd` | `report.html` | reads CSVs only: `quarto render report.qmd` |

## Systems — two tiers (`tier` column in every output)
**Sharp (headline, jump ≥ 0.45):**
Chinese Taipei, Korea, B-S-J-Z, Hong Kong (East Asia); Brunei, Philippines (Southeast Asia); Georgia (post-Soviet);
Finland, Estonia, Slovakia, Croatia, Serbia (Europe); Peru, Paraguay (Latin America). 
**Fuzzy (appendix check, jump 0.25–0.45):** Mauritius (0.73 but incomplete skill set), USA (no skills), Costa Rica (no ESCS), Kenya, Cambodia, Kazakhstan,
Albania, New Zealand, Brazil, Azerbaijan, Kosovo, Chile, Israel; Montenegro is in the outputs but dropped from the reports (jump 0.17 on all programmes).
Excluded for structural reasons: UK (two cutoffs), Palestinian Authority (cutoff at the edge of the cohort). No cutoff at all: Viet Nam, Mongolia, Macao,
Malaysia, Singapore, Indonesia, Uzbekistan, Kyrgyzstan, Moldova, Armenia and most others. A partial cutoff month is dropped (donut) only where another
post-cutoff month remains; at the edge of the cohort (Chile, Israel, New Zealand) it is kept and the fuzzy first stage absorbs it.

## Things to know
- The cutoff moves schooling and relative age within the grade together: every τ is "one more year of school in the position of the youngest in the grade".
- The running variable is discrete (12 birth months): BRR SEs cover sampling error only; bandwidths, functional forms, balance and placebo cutoffs are the specification check; the placebo rejection rate (≈10 %) says SEs are somewhat too small. Honest CIs (Kolesár & Rothe 2018) are the next step before submission.
- PISA samples one birth-year cohort, so Finland, Peru and Paraguay have one usable birth month after the cutoff (common-slope spec); Korea, Hong Kong, the Philippines two.
- Scale labels follow the 2025 codebook: ENPROBS = enjoyment of problem-solving, COGABIL = cognitive adaptability.
