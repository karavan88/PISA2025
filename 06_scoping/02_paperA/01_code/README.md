# Paper A — Do socio-emotional skills transmit family advantage? (PISA 2025)

Run everything from the repository root (`PISA2025/`). One outcome domain per run: `PISA_DOMAIN=READ|MATH|SCIE`. Exposure per run: `PISA_TREAT=ESCS_PCT` (within-system percentile rank of ESCS / 10, headline; files `*_pct*`), `ESCS` (index units, appendix check; no suffix), `DEP` (deprivation count, conditional on ESCS; `*_dep*`).

**Workflow:** estimation writes CSVs to `03_outputs/paperA/<DOMAIN>/tables/`; the manuscript only reads them (rendering takes about a minute). `run_all_estimation.sh` is make-like: a step re-runs only when its output is missing or older than its inputs (`FORCE=1` reruns all). `MED_ONLY=GROWTH` re-estimates one mediator and replaces its rows.

| Step | Script | Purpose |
| --- | --- | --- |
| 1 | `02_scripts/01_build_dataset.py` | Extract + construct the analytic student file from the PISA 2025 PUF → `01_data/derived/` |
| 2 | `02_prepare.R` | Analytic sample (complete cases incl. the growth-mindset item), six WLE skills re-standardised to the analytic sample (senate-weighted mean 0, SD 1; OECD-anchored values kept as `*_oecd`), binary growth mindset (ST420Q01 disagree/strongly disagree), ESCS groups and deciles → `01_data/derived/paperA_analytic.rds` |
| 3 | `03_descriptives.R` | Sample table, skill means, correlation matrix of the seven dispositions with ESCS and the three achievement domains |
| 4 | `04_h1_gelbach.R` [`--total`] | Joint six-skill mediated share with BRR + PV inference, and its Gelbach allocation across skills (return conditional on the other skills × ESCS gradient) — used in the paper as the sensitivity check on the composition of the single-mediator ACMEs; default = within-school spec, `--total` = total gradient |
| 5 | `07_robustness.R` [`--total`] | Robustness of the joint mediated share, one model per system: modal-grade sample, non-response re-weighting |
| 6 | `09_causal_mediation.R` [`--total`] | **Main analysis**: Imai–Keele–Tingley causal mediation with the `mediation` package (`mediate`, `medsens`), one model per education system (bloc and overall figures are averages of system estimates; `MED_POOLED=1` adds optional pooled units). `MED_FAST=1` for reduced simulations, `MED_CORES` for parallel systems |
| 6b | `09b_joint_rho.R` [`--total`] | Closed-form sensitivity parameter ρ* for the joint six-skill block (index mediator), per system |
| 7 | `11_figures_paper.R`, `12_paper_tables.R` | Figures and table/inline-number helpers for the manuscript |
| 8 | `04_manuscripts/paperA/paperA.qmd` | Quarto manuscript (reads outputs only; no estimation) → `quarto render paperA.qmd` |
| — | `05_h2_h3_h5.R`, `05b`, `05c`, `05d`, `10_random_slopes.R`, `06_figures.R` | Auxiliary analyses (returns by SES group / decile, deprivation, skill × grade, bloc interactions) — not used in the paper except as the no-interaction check |
| — | `run_all_estimation.sh` (04 → 09 → 09b → 07, all treatments and domains, timestamp-aware) | Batch driver (`run_domain.sh`, `run_mediation_all.sh` are older drivers) |

Inference: Fay BRR (80 replicate weights, PV1) + Rubin over PVs for WLS quantities; quasi-Bayesian Monte Carlo (`mediate`) combined over PVs for causal mediation. Weights: final student weights within economy, rescaled to mean 1 for `lm`. Every model is estimated per system; the paper summarises the 19 (20 for science) system estimates by the median with the interquartile range and reports no bloc or pooled statistics (blocs are labels for ordering and colouring only).

Mediators: six WLE scales + growth mindset (binary; linear-probability mediator model — a probit mediator makes `mediate()` draw Bernoulli mediator values and inflates the Monte Carlo interval about fourfold at the same point estimate). School selection: leave-one-out school mean of the exposure (Mundlak device) makes the exposure coefficient the within-school estimator. Data quirks handled in code: `repeat` renamed `repeated` (R reserved word); PERSEV not fielded in KAZ, ALB; Macao has no school ID; Uzbekistan has no reading/maths PVs; ST401 deprivation items not fielded in MNG, MKD, ARM, BGR, KSV.

R packages: data.table, ggplot2, patchwork, lme4, knitr, kableExtra, mediation (+ MASS, Matrix, mvtnorm, sandwich, lpSolve, Hmisc, boot). Python: pandas, pyreadstat, pyarrow. Quarto ≥ 1.4 with xelatex for PDF.
