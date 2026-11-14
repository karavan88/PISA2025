# Central variable definitions and reproduction boundary

## Authoritative build

`02_scripts/00_tools/build_shared.py` runs `extract_base.R` then `prepare.R`.
The first loads the student and school sources once, attaches school weights,
constructs the national weighted midpoint SES rank, defines age/gender coding,
and standardizes released skill indices on the established SES sample. The
second uses that saved extract to construct deprivation and prepare common
country/exposure inputs. It never rereads SPSS files. Parental education and
occupation come from the same central student read.

- SES exposure: weighted national midpoint percentile rank of ESCS / 10,
  computed before complete-case selection.
- Skills: PERSEV, CURIO, ENPROBS, COGABIL, GOALSET, SELFREG; existing weighted
  SES-sample means and SDs; deprivation keeps the SES scale.
- Deprivation: response 2 means cannot afford. Select an item when valid
  responses cover at least 90% of those answering any candidate in that system.
  Require all retained items. The common-4 alternative is also constructed once.
- Parental controls: PAREDINT and HISEI, numeric source values, no paper recoding.
- Prepared eligibility preserves the existing minimum 100 pupils/30 schools.
  The full all_data.rds is retained centrally for other samples and coverage audits.
- Paper 01 selects 6-skill systems and its recorded country exclusions, giving
  67 SES and 62 deprivation systems. These are analysis choices, not altered raw data.

Within/between centering and model-specific conditional weights occur in shared
model functions called by the paper. They depend on the fitted analytic sample;
they are statistical specification steps, not alternative definitions of the
underlying SES, skill, deprivation, or parental variables.

## Frozen results versus fresh estimation

The current 72-file aggregate snapshot predates this repository migration. Its
SHA-256 manifest identifies the imported artifacts. Reporting verifies those
hashes and regenerates figures and PDFs. The package lock describes the available
reproduction environment, not proof that every historical fit used every locked
package version. Original session/package records remain in local input outputs.

The migration tests central raw-data preparation and cached reporting separately.
It does not certify a fresh rerun of all 499-draw regressions. The expensive
estimate entry point is explicit. Never infer current provenance from output
mtime alone. After changing central definitions or estimation code, use a fresh
analysis checkpoint directory and compare results before publishing a new snapshot.

A fresh clone has no data and no aggregate CSVs by author instruction. Restore
local source files and the approved result snapshot. The snapshot includes
historical country metadata/reference eligibility used to check reconstruction.
The manifest alone cannot regenerate absent observations or estimates.

## Verified migration — 14 November 2026

The central build reproduced all 157 archived country/exposure input objects without numerical differences (attributes excluded from comparison). An unchanged second run skipped processing. Cached reporting passed 657 checks; all 62 saved parental-control fits passed the retained-draw checks. A clean staged-file checkout, with only the local aggregate CSV snapshot restored and no raw data or model caches, rebuilt both PDFs with identical extracted text. No full bootstrap re-estimation was run.

When a central build exists locally, reporting checks its source/code fingerprints against the approved snapshot and rejects changed inputs. Without raw data or a central build, reporting is explicitly frozen-snapshot reproduction.

## Activated renv environment — 14 November 2026

The project now includes `.Rprofile`, `renv/activate.R`, explicit dependency settings, and `DESCRIPTION`. The local platform-specific library was hydrated from the installed packages; all 87 package versions match the unchanged lockfile. `renv::status()` reports a consistent state. WeMix 4.0.3 and lme4 load successfully. Python entry points explicitly pass the root R profile for subprocesses.

The optional renv system-library sandbox is disabled to avoid filesystem-lock stalls in the desktop execution sandbox. The project library remains first in the R library search path; the system library is available as a fallback. Package version checks compare every lockfile entry. On another machine, run `renv::restore(prompt=FALSE)` from the repository root. Legacy workflows may need additional declared dependencies before they are certified.

## Projects 01 and 02: reproducibility audit — 14 November 2026

### Environment and inputs

R 4.4.1 and all 91 locked packages were checked against the active project library. `renv::status()` reports a consistent project. The runners no longer bypass `.Rprofile` with `--vanilla`; the old external-library override was removed. `metafor` and its dependencies are now declared and locked. The source data location and exact filenames are documented in `01_data/README.md`.

The central student import now supplies both designs. All 157 mediation input objects reproduce the previous build numerically. The cutoff preparation recovers the 44 candidate systems and 36 eligible systems; all analytic values match the historical file after accounting for identifier types and missing-stratum-label representation. Repeating an unchanged central build skips processing.

### Project 01

All 157 main point models were refit from regenerated inputs and matched their retained point estimates within 1e-7. Five seeded school resamples for each of SES_KOR and DEP_KOR reproduced the retained draws within 1e-7. The 657 reporting checks, retained equalization-draw checks, and all 62 parental-control-fit checks passed. Both manuscript and appendix PDFs rendered under the project environment. The recovered deterministic classification script reproduces the historical classification table exactly.

This audit did **not** repeat every 499-draw mediation and alternative-model fit. The full fresh-estimation driver has been repaired and documented, but a complete new raw-to-final run of that expensive driver is not certified by these component checks. Historical-reference files are optional and cannot substitute for new estimation. Fresh results have a distinct reporting mode and provenance guard; the frozen snapshot is preserved.

### Project 02

Before the estimator correction, a complete central-input rerun reproduced all 3,411 historical estimate/SE entries across 36 systems: maximum absolute differences were 3.1e-13 and 1.1e-13 respectively. All 4 summary/shrinkage tables also matched within 1e-7. This established numerical reproduction of the old code, but did not establish that the old code was correct.

The rerun exposed a second-stage row-alignment error for missing skill outcomes. The corrected weighted 2SLS filters outcome, treatment, instruments, covariates, and weights together before both stages. Independent direct-matrix tests pass with and without missing outcomes. Original aggregate results remain in `02_results`; the correction is run into a separate output directory. Achievement outcomes have complete plausible values in the sample, so their estimates should remain unchanged. Historical skill-outcome IV estimates should not be used as the corrected results.

The generated run manifests record the package lock, analysis-code fingerprints, and shared-build fingerprint. Data and rendered reports remain Git-ignored; only code, documentation, and provenance manifests are committed. See `REPRODUCE.md` for the supported commands and the corrected-run comparison files.

The corrected project 02 full rerun completed for all 36 systems and passed its design/accounting checks. All achievement and LSDV estimates/SEs remain unchanged within 1e-7; 1,626 of 3,411 coefficient entries change, all in skill-outcome IV models. The median adjusted curiosity gain changes from 0.0623 to 0.0760 SD, with 10 rather than 7 significantly positive systems. The corrected HTML report renders successfully. Original and corrected outputs are in separate local folders.

Toolchain recorded for these checks: Quarto 1.5.57, XeTeX 0.999997 (TeX Live 2025), Python 3.11.7, and R 4.4.1.

An isolated source copy, supplied only with the approved project 01 aggregate bundle, corrected project 02 results, and the restored renv library, rebuilt both project 01 PDFs and the project 02 HTML report without raw data, old derived files, or legacy shortcuts. The external `PISA_DATA` directory option was also tested with the same provider files and correctly skipped unchanged processing. This is an isolated reporting test, not a clean download/install of the entire OS toolchain.
