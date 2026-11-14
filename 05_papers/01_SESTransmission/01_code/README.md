## Publication scope: SES rank in the main paper

The active rev2 main manuscript focuses on socio-economic rank, school sorting and joint skill-profile equalisation. The current scope excludes ISR as well as QUA/UKR and comprises 67 systems, 428,040 pupils and 18,836 schools. Material deprivation is reported exclusively in the supplementary QMD/PDF, including its figures, interpretation, parental-controls specification, sample change and same-pupil ESCS robustness. No regressions were refitted for this restructuring. Before-edit copies are in `05_papers/01_SESTransmission/03_manuscript/archive_before_ses_focus_2026-11-13`.

## Current rev2 publication: 13 November 2026

The latest revision adds a compact country-gradient table to section 4.1, shortens the discussion and distinguishes gradient decomposition, the sorting increment and skill equalisation. Chart means weight retained systems equally. Mean intervals combine independent country variances, conditional on this fixed country set; they are not country-dispersion intervals. `26_system_means_rev2.R` and `27_country_gradients_rev2.R` produce these summaries. BH adjustments are recomputed after exclusions; saved models and draws are not refitted. The immediately preceding publication files are preserved in `archive_before_67_systems_2026-11-13`.

Material deprivation now uses PAREDINT and HISEI at pupil and school levels. ESCS is a robustness specification on identical pupils. The deprivation sample contains 331,622 pupils in 16,929 schools across 62 systems, compared with 392,438 pupils in 17,549 schools before requiring the parental variables. The rank sample now comprises 428,040 pupils, 18,836 schools and 67 systems.

`16_parental_controls_comparison.R` fits and checkpoints both specifications with 499 paired school bootstraps and ten reading plausible values. `17_report_parental_controls_comparison.R` pools results and paired differences; `19_validate_parental_comparison.R` verifies reproduction of earlier estimates. `20_prepare_parental_publication.R` prepares descriptive statistics and ratio screens from these saved inputs without refitting. `reporting_rev2.R` promotes the parental results and preserves explicitly named full-sample ESCS objects for historical sensitivity comparisons. The main paper and supplement use current parental estimates throughout. Earlier deprivation weighting/item-set checks are not represented as robustness of the new parental model.

Run `Rscript 05_papers/01_SESTransmission/01_code/render_rev2.R` from the project root to regenerate figures, validate results and render both PDFs. Raw analytic records are required by the descriptive preparation stage. The `parental_controls_comparison` output directory contains matched ESCS estimates and paired changes; `rev2/tables/manuscript_*` contains the publication tables. The QMD/PDF and modified reporting scripts before this promotion are preserved in their `archive_before_parental_main_2026-11-13` directories.

The record below describes earlier versions; its deprivation specifications and sample sizes are historical.

---

# ijed_ses_seg

New IJED manuscript/reporting routine for **Do socio-emotional skills transmit socioeconomic advantage? Evidence from PISA 2025 data**.

The manuscript uses the completed global joint multilevel mediation analysis. It does not use the later `sestransmit` OLS/Gelbach branch or the original Paper A's seven-disposition single-mediator estimates. Six skills, reading, socioeconomic rank and material deprivation are retained. Primary comparisons require the same six observed scales (69 SES systems, 63 deprivation systems); supplementary results retain all 82/75 estimable systems.

## Render the original two PDFs

From the root of this project or the extracted bundle:

```sh
Rscript 05_papers/01_SESTransmission/01_code/render.R
```

This entry point regenerates ten publication figures, checks saved coefficients and renders both editable QMD files. **It does not fit regressions.** Required software: R, Quarto and XeLaTeX; R packages data.table, ggplot2, patchwork, ggrepel, scales, ragg, svglite, knitr and kableExtra. The manuscript PDFs use PT Serif, matching the sestransmit reference; charts use Helvetica. Change those YAML font fields if unavailable on another computer. Figures are vector PDF/SVG and 300 dpi PNG.

## Inputs and outputs

- `05_papers/01_SESTransmission/04_output/input`: exact copies of the saved aggregate results and audits.
- `05_papers/01_SESTransmission/04_output/audit/source_manifest.json`: original locations and SHA-256 hashes.
- `05_papers/01_SESTransmission/04_output/tables`: complete descriptive statistics, figure data and hypothesis counts.
- `05_papers/01_SESTransmission/04_output/figures`: ten charts in three formats.
- `05_papers/01_SESTransmission/03_manuscript`: editable main/supplement QMD, BibTeX, CSL, rendered PDFs.
- `05_papers/01_SESTransmission/01_code/upstream/global_mediation_code`: unchanged archived estimation scripts. They are preserved for inspection and are not called by the renderer. The counterfactual robustness routine explicitly reuses the archived engine and preparation helpers. They retain the prior workflow's working-directory and prepared-input requirements. The manifest records their provenance; this archive is not represented as a new independent raw-data replication.

`01_descriptives.R` optionally recomputes weighted descriptives from the original saved analytic RDS inputs. Set `IJED_ANALYTIC_INPUT` to their directory. Those pupil-level files are not distributed. The cached aggregate descriptives allow the manuscript to render without them.

## Interpretation conventions

M1 is one weighted random-intercept skill equation per skill; M2 is a reading equation containing every observed skill jointly. All variables enter as within-school deviations and school means. S is a separate weighted sorting projection. The joint profile contrast is `(1-delta)*sum(aW*bW) + delta*sum(aB*bB)`. All-country inference comes from the existing 499 school bootstraps and ten reading plausible values. The paper states the identification and survey-design limits in its Research limitations section.

The `SES_on_deprivation_sample` sensitivity is stored under exposure `DEP` by the upstream workflow, but its actual exposure is SES rank. Compare it with the main **SES** result. Do not interpret it as a deprivation robustness estimate. The reporting code handles this explicitly.

All references are generated from BibTeX with Elsevier Harvard citation styling. No manual reference list is maintained. Author affiliations, funding and declarations have not been invented for this draft. Journal submission metadata remains for the author to supply.

## Presentation revision after the November review

The main paper now uses three research questions consistently, with evidence-led subsections and indented question statements following the supplied JVB manuscript. The sestransmit manuscript supplies the A4/PT Serif/11-point/1.15-spacing layout and visual ideas only; none of its different models or estimates are imported.

The new two-link plots use the saved SES aW/bW and aB/bB coefficients. Each contains all 69 six-skill systems; the three worked examples are highlighted. Dashed curves are constant coefficient products, not fitted cross-country relationships. The within-school plot enters the paper; the between-school companion enters the supplement.

The new robustness plots compare saved joint pathway point estimates against weight scaling, minimum analytic school size, unweighted lmer, and (for deprivation) the four-item exposure on the same sample. No alternative bootstrap intervals were created. The unweighted comparison retains the main sorting coefficient. Every plotted country and value is exported in the corresponding *_data.csv file. The original estimation snapshot and the completed review remain unchanged.


## Current manuscript and counterfactual extension (8 November 2026)

- `render_rev1.R` renders the current manuscript with the clarified existing counterfactual. Its estimates are unchanged. The prior main/supplement QMD and PDF are preserved in `05_papers/01_SESTransmission/03_manuscript/archive_before_counterfactual_clarification_2026-11-08`.
- `render_rev2.R` renders the separate extension, `ijed_ses_seg_rev2.qmd` and `ijed_ses_seg_supplement_rev2.qmd`, using cached results in `05_papers/01_SESTransmission/04_output/rev2`. It regenerates the figures and runs the reporting and counterfactual checks. It does not refit regressions.
- `06_equalization_rev2.R` recomputes the new joint-profile replacement from saved analytic inputs, compressed model metadata and all 499 original bootstrap coefficient draws. Set `IJED_MEDIATION_WORK` to the original global-mediation work directory. Pupil-level inputs are not distributed with the reporting bundle.

The SES replacement assigns the empirical joint upper-national-quartile skill distribution to the lower national quartile. The deprivation replacement assigns the non-deprived distribution to pupils with one or more unaffordable items. All six skills move together; school membership, exposures and controls stay fixed, while school skill means and within-school deviations update consistently. The expected recipient gain minus the expected reference-group gain is the gap reduction. The baseline is the observed weighted group reading gap. This is a distributional endowment benchmark, not a new estimate of the original per-unit mediated share or a programme effect.

The same resampled school multiplicities used for every saved coefficient draw update donor means and group moments. Exact sorting-coefficient reconstruction verifies pairing, although sorting coefficients do not enter the new estimand. Original 499-draw/PV inference is retained; new BH families apply only to the 69 SES and 63 deprivation gap-reduction tests. Outputs include country estimates, skill means, target-group coverage, diagnostics, all-country figures and draw arrays. `08_validate_equalization_rev2.R` checks the identities and uncertainty calculations.

`05_link_index.R` fixes the coefficient index for both revisions: exposure-to-skill gradients receive their already-computed full-family `gradient_q`; reading coefficients have no supplied adjusted q-value. No model estimate or original multiple-testing family changes. `render.R` remains the historical original-draft entry point.


## Counterfactual robustness (8 November 2026)

Run `Rscript 05_papers/01_SESTransmission/01_code/10_run_counterfactual_robustness_rev2.R` to fit the alternatives, then `Rscript 05_papers/01_SESTransmission/01_code/render_rev2.R` to summarize, validate and render. Estimation uses two worker processes and 499 school bootstrap draws for all ten reading plausible values. Only M2 is refitted; M1 and the sorting projection do not enter the new counterfactual. The original estimate snapshot, headline counterfactual and rev1 remain unchanged.

The alternatives are unscaled conditional student weights, at least ten analytic pupils per school, and unweighted ML with the original centred regressors. The deprivation extension adds a common-four-item M2 fit with both fixed and redefined deprivation groups. An SES check uses the deprivation-complete sample but retains SES rank, its quartile targets and its controls. Donor means, recipient/reference means and school skill changes are recomputed coherently in each resample. Target-population weights remain final student weights in the unweighted-model check.

Unweighted likelihood calculations use the full design matrix, retaining its nonzero unweighted school means. Direct lmer fits and explicitly duplicated-school bootstrap fits validate this implementation. The optional `counterfactual_ml.cpp` backend uses Rcpp/RcppArmadillo; compiled point fits and first draws are checked against the pure-R reference. The macOS backend uses Accelerate for cross-products. Set `IJED_FAST_ML=0` for the pure-R fallback. Rendering cached results needs no compiler or original pupil files.

Each completed country/specification job is checkpointed under `rev2/counterfactual_robustness`. Rerunning resumes missing jobs. If changing input data, group rules, models or bootstrap count, use a fresh checkpoint directory or remove the affected cached job files before recalculating. The provenance manifest records the current inputs, code hashes and backend per job.

`11_summarize_counterfactual_robustness_rev2.R` creates comparison and summary tables and validates decomposition identities. `12_counterfactual_robustness_figures_rev2.R` exports both chart panels as vector PDF/SVG and 300 dpi PNG; each plots main against alternative gap reductions and identifies changes in separate interval status. `13_counterfactual_robustness_reporting.R` supplies manuscript helpers. All country intervals, sample sizes, valid draw counts and testing-family results remain available in the aggregate CSVs. Interval-status comparisons are not paired tests of the main/alternative difference. BH adjustments are separate by exposure and specification.

The pre-robustness rev2 QMD/PDF files are preserved under `05_papers/01_SESTransmission/03_manuscript/archive_before_counterfactual_robustness_2026-11-08`.


## Earlier 13 November 2026 annotation revision (historical scope)

At this earlier revision, the reporting sample included only systems with all six measured skills, with QUA/UKR excluded by the user: 68 SES systems (432,187 pupils; 19,044 schools) and 62 deprivation systems (392,438 pupils; 17,549 schools). `reporting_rev2.R` applies this scope consistently to main/supplement tables, figures and diagnostics. Original estimation caches are retained as provenance, not published as the manuscript's country universe. Published scoped CSVs use the `manuscript_` prefix and `analysis_sample.csv`; the counterfactual comparison/summary and figure-data tables are also scoped. BH adjustments retain the original family definitions but are recalculated over retained systems. The original estimates, standard errors and bootstrap draws are unchanged.

The title now uses “socio-economic (dis)advantage”, the author is Garen Avanesian, and socio-economic is hyphenated in manuscript prose and figure labels. The data section labels outcome, each exposure and mediators separately, and includes reading descriptives. Computation and limitations are each one paragraph. Counterfactual interpretation appears in estimation; the main evidence inventory and robustness exhibits move to the supplement, leaving two main-text robustness paragraphs. Heatmaps and forest plots have mutually exclusive unadjusted two-sided p-value shape bands (<.05, .05–.10, >=.10). Two-link scatterplots remain descriptive and do not assign one significance test to two different coefficients. Robustness scatterplots distinguish the status of separate intervals; they do not test the difference between specifications.

Before-edit QMD/PDF copies are in `archive_before_annotations_2026-11-13`. Rebuild with `Rscript 05_papers/01_SESTransmission/01_code/render_rev2.R`; no models are refitted. `15_deprivation_covariate_audit.R` separately inspects parental-control availability and weighted deprivation/ESCS correlations; it does not replace the current deprivation specification or estimate new mediation results.
