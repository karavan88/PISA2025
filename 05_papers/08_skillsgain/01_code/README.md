# Skills & the Grade Gain — who learns more in a school year at 15? (PISA 2025, 20 systems)

Builds on the Grade Gain Report (`02_scripts/gradegain/`). The causal grade gain γ (actual grade instrumented by the theoretical grade from the
school-entry cutoff, school-starting age linear; Avvisati & Givord 2021) is allowed to vary with socio-emotional (SE) skills, student SES and
school SES. Three estimators: interacted 2SLS per system + random-effects pooling; instrumental causal forest (grf); causal mediation.
Report: `04_manuscripts/skillsgain/report.qmd` → `report.html` (reads CSVs only).

**Systems.** 14 non-European (KEN QCI MUS TAP PRY KHM PER ECU BRA ARE HKG BRN PHL CRI) + 6 European OECD (CZE EST DEU SVK FIN HRV).
The analysis turns on school structure (`structure.csv`): 14 *same-school* systems where both grades of the cohort share schools, and 6
*transition* systems (KEN CZE QCI SVK TAP PRY) where the upper grade is a different school, so school SES is partly an outcome of the grade.

| Step | Script | Output | Notes |
|---|---|---|---|
| 0 | `02_scripts/gradegain/02_prepare.R` | `01_data/derived/gradegain_analytic.rds` | cutoff, D, Z, r, ssa, within-system z of the scales |
| 1 | `01_build_extra.py` (Mac, pyreadstat, ~1 min) | `01_data/derived/skillsgain_extra.csv.gz` | books at home (Costa Rica SES), SES components |
| 2 | `02_prepare.R` | `skillsgain_analytic.rds`, `coverage.csv`, `scale_corr.csv` | SE index and sub-indices, SES, leave-one-out school SES, grade-purged SE, ACH PVs |
| 3 | `03_validity.R` | `structure.csv`, `balance.csv`, `fs_by_group.csv`, `baseline.csv` | jump at the cutoff for covariates and moderators; first stage by quartile; baseline γ |
| 4 | `04_heterogeneity.R` | `het.csv`, `levels.csv` | interacted 2SLS per system (BRR + Rubin): SES, school SES, SE, joint, interactions, parts, purged, school FE, six scales; level gradients |
| 5 | `05_forest.R` (`SAMPLE=same`/`all`) | `forest_{ate,blp,gates,vi}_{same,all}.csv`, `forest_scores_*.rds` | instrumental forest on the age-adjusted outcome; BLP, GATES; Rubin over PVs |
| 6 | `06_mediation.R` | `mediation.csv`, `mediation_pooled.csv`, `mediation_sens.csv` | per-system a/b/indirect (BRR); pooled Imai–Keele–Tingley ITT + medsens |
| 7 | `07_pool.R` | `pool_*.csv`, `stability.csv`, `ses_explained_by_se.csv`, `counterfactual.csv` | RE pooling over sets of systems; coefficient stability; forest counterfactuals |
| — | `run_all.sh` | steps 2–7 | make-like; `FORCE=1` reruns; forests ~1–1.5 h on 6 cores |

**Key definitions.** γ(M) = (b_D − 12 b_r) + (b_DM − 12 b_rM)·M from the 2SLS with D, D·M instrumented by Z, Z·M and r, r·M, M as controls;
moderators are within-system z-scores. Forest outcome y + b_r,s·ssa turns the IV of y on D into γ without r in X.

**Data gaps.** Costa Rica: no ESCS → books at home. Cambodia: no SE scales. Brazil, Kenya: no perseverance. Mauritius: perseverance and
curiosity only. Germany: no sex variable. Costa Rica, Mauritius: no immigrant status.
