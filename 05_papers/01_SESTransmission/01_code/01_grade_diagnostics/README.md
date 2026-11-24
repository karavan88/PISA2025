# Grade, composition, and mediation diagnostics

Separate from the manuscript pipeline. Reads only centrally prepared inputs. The
school location definition is a city with at least 100,000 residents; it does not
identify pupil residence. Sampling gender is used for the exclusive subgroups.

From the repository root:

```sh
python3 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/run.py estimate
python3 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/run.py report
python3 02_scripts/00_tools/check_repo.py
```

`estimate` calls the central hash-checked diagnostic build, estimates weighted OLS
with 80 Fay BRR weights and 10 reading PVs, then multilevel mediation with 499
stratified school bootstrap draws. `report` only reads completed estimates,
produces descriptive display summaries, and renders the separate HTML. Neither
command changes the manuscript, appendix, main checkpoints, or equalization results.

The default run folder is `04_output/grade_diagnostics_20261117_v2`. If input/model
code changes, set `GRADE_DIAG_OUT` to a new, empty run folder. Signatures reject
mixed-definition checkpoints. Preserve existing results. The report also reads
`GRADE_DIAG_OUT` if provided (use an absolute path when invoking Quarto).

Primary models use the same complete six-skill pupils across outcomes and model
specifications; outcome-specific availability is separately labeled. Country
means use fixed common country sets for comparisons, plus available-system means
in the CSV outputs. Within-school means are recomputed for every BRR replicate.
Female–male coefficient contrasts pair replicate numbers across the two groups.
Mediation subgroup differences are descriptive, not paired interaction tests.

All pupil RDSs, aggregate CSVs, coefficient draws, figures, and rendered files are
Git-ignored. Source code and the QMD are the reproducible record. OLS validation
compares weighted absorption against explicit school-dummy regression. The
mediation engine is checked against the reference R likelihood. Grade slopes
cannot establish temporal precedence or personality stability.

## Grade adjustment in the mediation equations

```sh
python3 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/run.py grade-estimate
python3 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/run.py grade-report
```

The grade sensitivity uses exactly the saved diagnostic pupils, country scales,
weights, and original bootstrap seeds. Grade enters within and between schools
in both the skill and reading equations, and in the sorting projection. A second
comparison holds original sorting coefficients fixed to isolate the equation
adjustment. Paired bootstrap/PV differences supply uncertainty for changes.

The current corrected output is `04_output/grade_control_20261117_v2`; the initial
partial run remains preserved. The corrected run explicitly rejects unidentified
bootstrap designs instead of accepting approximate singular solutions. At least
475 of 499 paired draws are required. The run uses 2 R workers. The old report
snapshot and unchanged-manuscript hashes are saved in the initial sensitivity
output directory. `GRADE_CONTROL_OUT` can select a new directory; input/code
signatures prevent mixing definitions. `grade-report` never estimates models.

The full `report` command now also requires completed grade-sensitivity estimates.

## Simple OLS tables

`Rscript 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/07_simple_ols.R`
estimates each skill on grade, with grade-plus-age as a separate specification,
for the 4 existing samples. Country and actual pooled pupil-level regressions
retain survey weights; pooled weights sum equally by country and include country
intercepts. Outputs: `04_output/simple_grade_ols_20261117`.
Run `08_validate_simple_ols.R` to verify pooled estimates against explicit country
dummies, then render `03_manuscript/01_diagnostics/simple_grade_ols.qmd` with Quarto.
The QMD only reads results; it does not estimate models.

## Skills, achievement, and grade-gradient co-movement

```sh
python3 02_scripts/00_tools/build_shared.py --learning-diagnostics
Rscript 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/09_learning_gradients.R
Rscript 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/10_learning_report.R
quarto render 05_papers/01_SESTransmission/03_manuscript/01_diagnostics/skills_learning_gradients.qmd --to html
```

Central preparation joins math PVs onto the exact earlier pupil samples and fails
if any original pupil lacks math. Estimation produces country and pooled joint
skills→reading/math OLS, and country grade gradients for all outcomes. Cross-country
gradient associations update both estimated coordinates in each national survey
replicate; intervals reflect fixed-country survey/PV uncertainty. They do not
correct errors-in-variables bias or identify a causal skill effect. This is not DiD.
The report discusses external IV designs and why grade is not an excluded skill
instrument. All results go into ignored `04_output/learning_gradients_20261117`;
reporting never estimates. Input/code signatures guard the estimation checkpoint.

### Continuous ESCS descriptive scatter plots

Run `Rscript 05_papers/01_SESTransmission/01_code/01_grade_diagnostics/11_escs_skill_scatter.R` from the repository root. This uses the saved 4 diagnostic samples, continuous ESCS, the existing national skill standardization, and final student survey weights. It fits unadjusted descriptive lines only; it does not rerun the mediation, counterfactual, or raw-data preparation. Outputs are under `04_output/escs_skill_scatter_20261117_v2/`: 4 six-panel PNG/PDF plots, a country-panel PDF atlas for the full sample, country keys, fitted lines, binned scatter means, and slopes. Data products remain ignored.

The plotting eligibility threshold is 200 pupils and 20 schools per system/sample, with ESCS variation. This yields 65, 64, 50, and 49 systems respectively. Lines use all eligible observations; their displayed extent is the national weighted 2.5th–97.5th ESCS percentile range. Dots are survey-weighted means in fixed 0.25-ESCS bins with at least 30 pupils, not individual scatter points. No confidence intervals or significance claims are produced. Input/script hashes prevent silently replacing a changed-definition checkpoint.
