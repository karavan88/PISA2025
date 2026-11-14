# Reproducing projects 01 and 02

## Environment

Validated environment: macOS ARM64, R 4.4.1, Python 3, Quarto, XeLaTeX, and PT Serif. Python orchestration uses only the standard library. Project 01's compiled counterfactual routines also need a working C++ toolchain (on macOS, Xcode command-line tools). The R packages are pinned in `renv.lock`; `DESCRIPTION` declares direct dependencies.

From the repository root:

```sh
Rscript -e 'renv::restore(prompt=FALSE)'
Rscript 02_scripts/00_tools/check_environment.R
python3 02_scripts/00_tools/check_repo.py
```

The tracked `.Rprofile` bootstraps renv if necessary. Internet access is needed for first-time restoration. Do not launch R with `--vanilla`: it disables that profile. The Python runners enforce project-profile loading. The environment check requires every locked version to be present in the project library, rather than relying on a global installation. The optional renv system-library sandbox is disabled because it stalls under the desktop filesystem sandbox; the project library remains first.

Quarto rendering needs normal OS access. In the Codex restricted sandbox, Quarto's `sysctl` architecture check may require an escalated run. This is not an analysis dependency.

## Central preparation

Place the 2 SPSS files as specified in [01_data/README.md](../01_data/README.md), or set `PISA_DATA`. Then run:

```sh
python3 02_scripts/00_tools/build_shared.py
```

The student file is read once for both designs. Shared variable construction, cutoff screening, eligibility, and standardization live under `02_scripts/01_harmonization`. Models consume the prepared files. Repeating the build with unchanged sources, code, and outputs skips all processing. Source and product hashes are recorded in `03_outputs/01_harmonized/build_manifest.json`. A changed provider release must be reviewed against the retained sample/results; do not assume a filename identifies the same data release.

## Project 01 — socio-economic transmission

Frozen-report reproduction requires the approved local aggregate bundle described in the data README:

```sh
python3 05_papers/01_SESTransmission/01_code/run_all.py report
python3 05_papers/01_SESTransmission/01_code/run_all.py draw-check
```

`report` checks the snapshot and regenerates figures, the main PDF, and appendix PDF. `draw-check` additionally checks retained draws and parental-control fits. Reporting never fits models.

For a new estimation from raw data:

```sh
python3 05_papers/01_SESTransmission/01_code/run_all.py estimate --fresh
python3 05_papers/01_SESTransmission/01_code/run_all.py report --current-results
```

`--fresh` archives previous outputs locally before rebuilding all country/exposure models, 499 school resamples, parental-control comparisons, and counterfactual alternatives. It is expensive. The frozen `02_results` snapshot is not replaced. `--current-results` requires a completed estimation manifest and matching code, input, and package fingerprints. Historical pilot-reference files are optional validation inputs, not estimation dependencies. The deterministic classification postprocessor is included in the repository.

To refit all main point estimates and verify 5 seeded draws for each Korean exposure against retained draws:

```sh
Rscript 05_papers/01_SESTransmission/01_code/25_reproduction_check.R
```

This check requires the retained historical draws. It is not a substitute for repeating every bootstrap and alternative-model fit.

## Project 02 — fuzzy-RD learning

```sh
python3 05_papers/02_fuzzy_rd_learning/01_code/run_all.py estimate --output /absolute/new/results/directory
python3 05_papers/02_fuzzy_rd_learning/01_code/run_all.py report --results /absolute/new/results/directory
```

`report --results` validates a completed fresh result directory, then renders `03_manuscript/report.html`. `estimate` runs the central build if needed and writes to a new timestamped directory under `04_output`, preserving historical estimates. It recomputes all 36 eligible systems, all available outcomes, the 3 specifications, 80 BRR replicates, plausible-value pooling, and meta-analysis summaries. The final validator checks the sample, coefficient identities, summary arithmetic, and agreement of achievement and LSDV estimates/SEs with the historical bundle. When the historical bundle is present, changes in skill-outcome IV estimates caused by the corrected missing-outcome alignment are recorded in `historical_comparison.csv`. Without that bundle, the historical comparison is explicitly skipped; fresh estimation and design/accounting checks do not require it. Supply `--output /absolute/new/path` to choose a fresh destination. For intentional design revisions, update the validation baseline only after reviewing differences. `report --historical` explicitly renders the old snapshot; it must not be treated as the corrected analysis.

The broad screening audit is now generated centrally from the provider file, with no dependency on project B or scoping outputs. The recovered audit reproduces the 44 candidate systems and final 36-system sample. Minor differences in descriptive single-grade labels for noncandidate systems do not affect selection. The reported sample retains the original cohort-edge flags and country rules.

## Verification and limits

See [REPRODUCIBILITY.md](REPRODUCIBILITY.md) for the completed checks. No portability claim is made for untested R/OS combinations. The package lock does not pin Quarto, TeX, or system fonts; their installed versions are recorded in the verification report. Project 03 and scoping analyses are not yet certified against this workflow.

## Estimation correction found during verification

The historical project 02 2SLS routine appended outcome-complete fitted grade values to an unfiltered covariate matrix before filtering. With missing outcomes, R recycled those fitted values across the wrong pupils. The correction filters all variables once before either stage. An independent direct-matrix test verifies the corrected estimator with and without missing outcomes. Achievement plausible values are complete in this sample, so their estimates are unchanged; skill-outcome IV estimates require the corrected run. The historical bundle is preserved, and the corrected run writes a full comparison.
