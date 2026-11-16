# The price of progress (paper 04) — rules, decisions and how to recover every step

Last updated 2026-11-16. This file is the recovery guide: what the rules are, which decisions were made and why, and the exact order in
which to rebuild the cutoff design from the raw files. The running log of results is `01_code/README.md`; this file says how to get there
again. Run every command from the repository root with `export RENV_PROJECT="$PWD"`.

## 1. Rules

1. Write only inside `05_papers/04_price_of_progress/` unless the user authorises a named change elsewhere (done once on 2026-11-14/16: see §3).
2. Shared variable harmonization lives only in `02_scripts/01_harmonization`; the analysis is exclusive to this paper. No raw-provider read and
   no shared-variable construction in paper code: read `03_outputs/01_harmonized/` products only.
3. Nothing is overwritten. Re-estimation goes into a NEW directory under `05_archive/` (or `PAPER_OUT=<new dir>`); the scripts refuse to write
   into an existing output. Compare with `04_output`, record the reason in `01_code/README.md`, and only then promote with
   `snapshot.py refresh --replace`. Never run two copies of a step at once; never start estimation in the background while testing.
4. Reporting never fits models. Figures and the report read `02_results/snapshot/` only (`run_all.sh report`).
5. Data, CSVs, PDFs and figures are Git-ignored; never force-add them. No commit or push unless the user asks; no git worktree (the data
   exists only in this checkout); do not touch `README.md`, `05_papers/README.md`, `.gitignore` or `00_documentation/` without asking.
6. Manuscript author "Karen Avanesian"; the active manuscripts use "we"; refer to the user as they/them.
7. Every report states plainly whether estimation was rerun, and which directory it went to. Before finishing: `python3 02_scripts/00_tools/check_repo.py`
   and `python3 05_papers/04_price_of_progress/01_code/snapshot.py check`.

## 2. Method decisions (user, with reasons)

- **Design.** Fuzzy regression discontinuity at the school-entry cutoff (Avvisati & Givord 2021): actual upper grade `D` instrumented by
  the assigned grade `Z = 1[r < 0]`; `r` = months from the cutoff, linear; per system; Fay BRR (80 replicates, k = 0.5) + Rubin over 10
  plausible values; DerSimonian–Laird random-effects pooling.
- **Headline estimand (2026-11-15): `gamma = b_D − 12·b_r`**, the grade gain with starting age fixed. `tau = b_D` (grade with birth month
  fixed; also a year younger at entry and youngest in class) is saved beside it and never the headline. The old report worded `tau` but
  reported `gamma`; wording must say gamma.
- **Sample (2026-11-16): defined by the design's eligibility, not by an outcome.** The central eligibility rule (`cutoff_definitions.R`:
  enough students whose grade is moved by the cutoff, shared with paper 02) gives 36 systems; 35 have life satisfaction (not USA). All 35
  are the main sample; the earlier 20 (legacy `skillsgain_analytic.rds`) are a subset. No documented selection rule for the earlier 20 exists.
- **Life satisfaction is a central product** (`wellbeing_provider.rds`, 2026-11-16), not a join from the legacy extract. Join on the INTEGER
  student ID: the central `CNTSTUID` is a zero-padded string, the legacy one an integer; a string join silently loses ALB, AZE, BRA, BRN.
- **Reporting rule (2026-11-16):** the full-window gamma is the headline; the bandwidth sensitivity of the life-satisfaction cost (−0.026 at |r| ≤ 6 to −0.120 at |r| ≤ 3, strict 24 systems) is reported openly, with the covariate-adjusted estimate beside it (adding ESCS, home possessions, language changes nothing).
- **Achievement** = mean of the science, maths and reading plausible values, built per plausible value (`PVkACH`), as in the legacy build.
- Measurement validity is robustness, not a hypothesis; Ukraine (QUA) is excluded in paper 03's all-country work, and the question for this
  paper is still open (QUA is in the 35).

## 3. Guards of other papers (changed 2026-11-16, user's authorisation)

Papers 01 and 02 used to pin the whole central build, so any central edit invalidated their completed runs. Now paper 01 pins the raw inputs
and the hashes of the 172 central products it reads (`02_results/analysis_contract.json`, `run_all.py`); paper 02 pins its six `cutoff/`
products (`run_all.py`; `shared_products` in its completed `run_manifest.json`). A new central product or script for another design no longer
breaks either. Paper 01's 73 result files were byte-identical before and after. Commit `1bdd8fe`.

## 4. Recovery: rebuild the cutoff design from raw

| # | Command | Writes | Check |
|---|---|---|---|
| 0 | `python3 02_scripts/00_tools/build_shared.py` | `03_outputs/01_harmonized/` incl. `cutoff/analytic.rds`, `wellbeing_provider.rds`, `build_manifest.json` | 180 products; `build_manifest.json` lists `wellbeing_provider.rds`; ~3 min |
| 1 | `Rscript 05_papers/04_price_of_progress/01_code/01_inputs.R` | `04_output/cutoff35_students.rds`, `cutoff35_coverage.csv` | prints "cross-check: 180370 legacy students (20 systems) agree on D, Z, r and life satisfaction"; 35 systems, 254,643 students with the item (needs the legacy files only for the cross-check; refuses to overwrite) |
| 2 | `PAPER_OUT=<new dir> Rscript .../08b_cutoff35.R` | `cutoff35_sys.csv`, `cutoff35_pool.csv` | all 35 gamma(LS_z) pooled ≈ −0.043 (SE 0.012); the 20 earlier systems −0.057; ~26 s |
| 3 | `PAPER_OUT=<same dir> Rscript .../12_design.R` | `design35.csv` | per-system first stage, cohort months, gamma; descriptive |
| 4 | `PAPER_OUT=<new dir> Rscript .../13_design_tests.R` | `design_*.csv` (by month, reduced form, balance, density, bandwidth) | first stage 0.556; reduced form ACH +3.9, LS −0.025; ~50 s |
| 5 | `PAPER_OUT=<new dir> Rscript .../14_covariates.R` | `covariates_sys.csv`, `covariates_pool.csv` | gamma with ESCS, home possessions, language added: LS all 35 −0.043 (0.012) as in base; ~60 s |
| 6 | `UIS_DIR=<unzipped UIS 403 export> PAPER_OUT=<new dir> Rscript .../15_uis_check.R` | `uis_check.csv` | rough check of inferred cutoffs against UIS school-year start month; 34 of 36 have a UIS value; descriptive only |
| 7 | `PAPER_OUT=<new dir> Rscript .../16_uis_ages.R` | `uis_ages.csv` | official entry age and level durations (UIS API, stored in `04_output/external_uis/` with `SOURCES.txt`) against the PISA grades; 27 systems consistent, 9 flagged; Taiwan and Kosovo use China and Albania as proxies (`uis_proxy`) |
| T | `bash .../run_all.sh test` | nothing | 56 comparisons within 1e-8 (estimators against direct 2SLS on simulated data) |

Steps 2–5 so far ran into `05_archive/estimate_20261115_central35/`, `05_archive/estimate_20261116_design_tests/` and `05_archive/estimate_20261116_covariates/` (each with `run.json` and
`logs/`). `run_all.sh estimate <new_dir>` still runs only the legacy steps `08_cutoff.R` and `09_extras.R` (20 systems, legacy file); the
new steps are run by hand as above until they are integrated.

## 5. Open items

- Heterogeneity by region and school structure; the school-structure rule (same-school vs transition) is defined only for the earlier 20.
- SES composite and quartile, grade-purged skill index `SE_p`: only in the legacy file; decide which are shared (central) and which stay in this paper.
- Relative-age / starting-age bounding; mechanisms; threshold model; literature search; manuscript rewrite; then promote results to the snapshot.
- Paper 02's `reproduction_20261114` run fails its code-hash check (`03_gradegain.R`), independent of the shared-build guard.
