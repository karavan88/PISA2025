# Grade Gain Report — reproducible analysis

See the [project README](../README.md) for the design, coverage, and missing-outcome correction.

- `run_all.py`: central build, fresh estimation, validation, and HTML rendering.
- `00_helpers.R`: consumes central definitions and prepared inputs; statistical helpers.
- `model_functions.R`: corrected weighted 2SLS, with a common sample in both stages.
- `test_tsls.R`: independent matrix-estimator test with and without missing outcomes.
- `03_gradegain.R`: country/outcome/specification estimation; 80 BRR replicates and plausible-value pooling.
- `04_summary.R`: country summaries and metafor REML estimates.
- `05_validate.R`: sample, identities, summary arithmetic, and comparisons with the preserved historical estimates.

`01_build.py` forwards to the central builder. `02_prepare.R` deliberately stops with the central-build instruction. Shared variables and eligibility are defined only under `02_scripts/01_harmonization`. `run_all_estimation.sh` forwards to the Python runner and fails on errors.
