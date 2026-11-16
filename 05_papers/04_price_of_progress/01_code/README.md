# The price of progress — code and analysis notes

Achievement, school progression and adolescent life satisfaction: the achievement slope hidden by skills, and the school-entry cutoff
design for one extra grade. Target journal: Economics of Education Review. Companion paper: `05_papers/03_resilience_cost`.

| Step | Script | Output (`04_output/`) | Notes |
|---|---|---|---|
| shared | `02_scripts/02_legacy/wellbeing_shared/01_build.py`, `02_prepare.R` | `01_data/derived/resilwb_students.csv.gz`, `resilwb_analytic.rds`, `resilwb_coverage.csv` | frozen legacy preparation used by both papers; not yet in the central harmonizer |
| 1 | `01_inputs.R` (~1 min) | `cutoff35_students.rds`, `cutoff35_coverage.csv` | input layer of the rebuilt cutoff design; fits nothing. Joins central `cutoff/analytic.rds` (36 systems) to central `wellbeing_provider.rds` on the integer student ID; adds `LS`, `LS10`, `LSle4`, `LS_z`, `female_any`; keeps the 35 systems with the item (USA lacks it): 293,734 students, 254,643 with life satisfaction. Cross-check against the legacy 20-system file (not an input): D, Z, r and LS agree for all 180,370 shared students. Refuses to overwrite; run into a new `PAPER_OUT` to rebuild. Not yet used by `08_cutoff.R`, which still reads the legacy file |
| 8 | `08_cutoff.R` (~1.5 min) | `cutoff_sys.csv`, `cutoff_pool.csv` | school-entry cutoff IV on the 20 grade-gain systems (`skillsgain_analytic.rds`): effect of an extra grade on LS, P(LS = 10), P(LS ≤ 4) and achievement; moderation by low SES, SES, grade-purged skill index, curiosity; school FE in same-school systems; pooled for all 20 / same-school 14 / transition 6 |
| 9 | `09_extras.R` | `extras_sys.csv`, `extras_pool.csv`, `desc_dist.csv`, `desc_decile.csv` | achievement slope of LS without / with the skill index (all, by ESCS quartile; mean, P(LS = 10), P(LS ≤ 4)); skill index on achievement; PV1 descriptives for figures. New files only |
| 10 | `10_figures.R`, `reporting.R` | `../02_results/figs/fig_b*.pdf` | read `02_results/snapshot/` only |
| — | `snapshot.py` | `../02_results/snapshot/`, `snapshot_manifest.json` | promotes results to the report; 2 files come from paper 03 (`oriv_pool.csv`, `oriv_sys.csv`) |
| — | `run_all.sh report` / `estimate <new_dir>` / `compare <new_dir>` | | reporting fits no models; estimation never writes into `04_output` |
| — | `test_tsls.R` (`run_all.sh test`) | | simulated data only: `tsls_m` and `est_sys` against a direct matrix 2SLS (0–2 moderators, missing outcomes, school fixed effects, plausible values) and against the grade-gain project's `tsls` |

Inputs of the cutoff design: `01_data/derived/skillsgain_analytic.rds` (legacy 20-system build: cutoff, actual grade D, assigned grade Z,
running variable r, grade-purged skill index `SE_p`) and `01_code/systems.R` (school structure and names of the 20 systems,
copied from the legacy skillsgain output). `tsls_m`, `est_sys` and `pool_iv` in `00_helpers.R` are verbatim copies of the legacy
skillsgain functions. The row-alignment error found in the grade-gain project's 2SLS (missing outcomes) does not apply to `tsls_m`:
it filters outcome, treatment, instruments, covariates and weights together before both stages. `test_tsls.R` confirms this
numerically (56 comparisons within 1e-8, 14 November 2026), including agreement with the grade-gain project's corrected `tsls`.

**Working rules for this folder.**
- This paper's session writes only inside `05_papers/04_price_of_progress/`. The companion paper and `02_scripts/02_legacy/wellbeing_shared/` are read-only here.
- Figures and the report read `02_results/snapshot/` only. Estimation writes to `04_output/`; a result reaches the report only through
  `snapshot.py refresh` (with `--replace` when a file changes, which archives the previous snapshot to `05_archive/`).
- Re-estimation goes into a new directory (`run_all.sh estimate <new_dir>`), is compared with `04_output` (`run_all.sh compare`), and
  the reason for any difference is recorded below before `04_output` is updated. Never run two copies of a step at once.
- Files that come from the companion paper are listed in `snapshot.py` with their source; refresh them deliberately, not automatically.

**Estimation.** Per system, Fay BRR (80 replicates) + Rubin over 10 plausible values (`pisa_est` in the shared helpers). The plausible value
enters through the achievement composite, so anything defined on achievement is re-derived per plausible value and per replicate weight.
School fixed effects by weighted within-school demeaning. Cross-system summaries: DerSimonian–Laird random effects. Sex comes from the
sampling-frame `MALE` where `ST004D01T` is withheld (14 systems). ISL, LUX, MAC, MLT have no school ID in the public file.

**Exogenous academic progression (step 8; school-entry cutoff IV, 20 systems, 158k students; RE means).**
- An extra grade at the same age raises achievement by 20 points (all 20 significant) and **lowers life satisfaction by −0.056 SD**
  (SE 0.018, t −3.2), P(LS = 10) −2.5 pp (t −3.6), P(LS ≤ 4) +0.6 pp (ns). Same pattern as the cross-section: a top-box loss.
- Same-school systems: −0.034 (t −2.3); with school FE −0.039 (t −2.6, I² = 0). Transition systems (grade = new school): −0.109.
- **No SES gradient in the causal effect**: grade × bottom-SES quartile −0.014 (SE 0.034); × continuous SES +0.004 (0.016). The achievement
  gain is also SES-neutral (+0.7 pts). Grade × grade-purged skill index −0.009 (0.015); × curiosity −0.003 (0.017).
- Scaling: −0.28 SD of LS per 100 achievement points of a grade (−0.20 same-school), several times the cross-sectional slope
  (−0.06 per SD of achievement, step 4) → the grade lowers LS through more than achievement (workload, curriculum, older-grade demands);
  this is the effect of school progression, not of achievement.
- Reading: exogenous academic progression costs life satisfaction for everyone, at the top of the ladder, with no extra cost for poor
  students. The cross-sectional excess penalty for resilient students (difference in gaps −0.07 to −0.09, step 4) is not reproduced,
  though the IV interaction's CI (±0.07) cannot rule out an effect of that size.

**Report extras (step 9; 70 systems).** Within school, per SD of achievement: LS −0.012 (SE 0.006) without the skill index, −0.056 (0.005)
with it; by ESCS quartile with skills −0.065, −0.063, −0.053, −0.044. Skill index rises 0.215 SD per SD of achievement. P(LS = 10)
−6.9 pp per SD of achievement (−5.4 without skills), negative in all 70 systems; P(LS ≤ 4) +0.5 pp.

**Two raters (snapshot of paper 03's `oriv_pool.csv`, 17 systems, achievement held).** Student-rated self-regulated learning → life
satisfaction 0.17 SD per SD; parent-rated 0.10; correlation of life satisfaction with the component the two ratings share 0.39.

**Correction (2026-11-14).** `cutoff_pool.csv` / `cutoff_sys.csv` were briefly overwritten by a stray background run of the pre-edit
`08_cutoff.R` (raw skill index `SE` as moderator instead of the grade-purged `SE_p`). Step 8 was rerun; the files now match the
script and the numbers above. Base, SES and curiosity rows were identical in both versions.

**Orientation for the rebuild (2026-11-14; read-only checks, no estimation).**
- *Estimand.* Each model saves two terms. `tau` is the coefficient on the grade with birth month held fixed: one grade further at
  the same age at test, which also means a year younger at school entry and the youngest instead of the oldest in class.
  `gamma = tau − 12·b_r` adds a year of age, with starting age fixed (the grade gain of Avvisati and Givord), and relies on the
  within-grade birth-month slope being linear. The numbers reported above and in the report are `gamma` (LS −0.056, SE 0.018;
  achievement +20.2), but the report words them as "one extra grade at the same age", which is `tau`: LS −0.073 (SE 0.026),
  P(LS = 10) −2.7 pp, achievement +11.4 points (significant in 8 of 20 systems). Same-school 14: `tau` −0.066 (0.026) against
  `gamma` −0.034 (0.015). The wording and the choice of headline are to be settled before the report is revised.
- *Central preparation.* `03_outputs/01_harmonized/cutoff/analytic.rds` holds 297,954 students in 36 systems. The 20 legacy
  systems are among them with equal row counts; `D`, `Z` and `r` are identical row by row in the 18 compared by student ID
  (BRA and BRN not yet compared). It has no life-satisfaction item, and neither has any other central product. The item is in
  35 of the 36 systems (not USA): 254,643 students, against 147,042 in the current estimates.
- *Student ID.* The central `CNTSTUID` is a zero-padded string, the legacy extract's an integer. Join on the integer; a string
  join silently loses ALB, AZE, BRA and BRN.
- *Decision (user, 2026-11-14).* The life-satisfaction item is to be added to the central harmonizer before the rebuild, not
  joined from the legacy extract. Requested from the harmonizer (outside this session's write area): a new product
  `03_outputs/01_harmonized/wellbeing_provider.rds` from the existing provider read in `extract_base.R`, with `CNT`, `CNTSTUID`,
  `ST016Q01NA`, `MALE`, `BULLIED`, `FEELSAFE`, `FAMSUP`, `HOMEPOS`; all existing products unchanged; values checked against the
  legacy extract. Steps that need the item wait for it.
- *Central change applied, verified and reverted (2026-11-14, with the user's authorisation).* Three lines in `extract_base.R`
  and one run of `build_shared.py`. All 179 existing products kept their hash; the six new columns equalled the legacy extract
  for all 755,721 students; the string ID joined `cutoff/analytic.rds` at 100% in all 36 systems. But papers 01 and 02 pin the
  central build itself (paper 02 the hash of `build_manifest.json`, paper 01 the hash of every harmonization script), so their
  reporting refused the completed runs although every product they read was unchanged. The script and the manifest were
  restored from copies taken before the build and the new product removed; afterwards the products, both pins and
  `git diff` on `02_scripts` matched the earlier state. With those guards, any central change invalidates the completed runs of
  papers 01 and 02. How to obtain the item was therefore put back to the user.
- *Central change re-applied (2026-11-15, user's decision "Re-apply centrally").* The same three lines in `extract_base.R`, one run
  of `build_shared.py` (about 3 minutes). Checked: 180 products, the only new one `wellbeing_provider.rds`, the 179 others with
  unchanged hashes; the only changed input is `extract_base.R`; the six columns equal the legacy extract for all 755,721
  students (NA patterns equal, largest difference 2e-15); string ID joins `cutoff/analytic.rds` at 100% in 36 systems, 35 with
  the item, 254,643 students; `check_repo.py` and `snapshot.py check` pass. **Consequence, not resolved here:** the build manifest
  now has hash `f523d2dc…` (was `29c22aa4…`) and the hash of `extract_base.R` changed, so paper 02's three completed runs
  (pinned `29c22aa4…`) and paper 01's pinned harmonization-script hash no longer match. Their reporting will refuse the
  completed runs until those papers are re-estimated against the new build or their guards are changed to pin product hashes;
  both are outside this session's write area and nothing was done to them. Estimation was not rerun by this session. Another
  `shared_harmonization` line was appended to paper 01's `04_output/00_logs/runs.jsonl`.
- *Guards of papers 01 and 02 changed (2026-11-16, user's authorisation).* The consequence above is resolved. Paper 01's
  `run_all.py` and `02_results/analysis_contract.json` now pin the raw inputs and the hashes of the 172 central products it reads
  (all except the cutoff design's), not the harmonization scripts or the whole manifest; the three harmonization scripts left its
  `sha256` pins. Paper 02's `run_all.py` pins the six `cutoff/` products, and its three completed `run_manifest.json` files gained
  `shared_products` (the old manifest hash was kept; the cutoff products are byte-identical to the approved state). Both papers'
  checks pass and a tampered product hash is refused in each. Paper 01: all 73 files in `02_results` are byte-identical before and
  after, `check` passed (657 checks, no model refitted). No estimation was rerun for either paper. A new central product or script for
  another design no longer invalidates either paper.
- *Estimation rerun (2026-11-16, this paper).* `08b_cutoff35.R` (base specification, central input layer, 35 systems) was run into
  `05_archive/estimate_20261115_central35` (26 s; `04_output` and the report untouched, nothing compared or promoted yet). Pooled
  gamma on life satisfaction: all 35 -0.043 (SE 0.012); the 20 earlier systems -0.057 (reproduces -0.056); the other 15 -0.013
  (SE 0.017). Achievement: 16.5 / 20.6 / 7.0 points. The 15 new systems show a much weaker grade effect; first stage and design
  strength by system are the next check. Headline estimand chosen by the user: gamma (tau saved beside it).
- *Design strength by system (2026-11-16, `12_design.R`, descriptive, written to the same new directory as `design35.csv`).* The weaker
  effect in the 15 added systems is not a first-stage failure: mean first stage 0.51 against 0.59 in the earlier 20, mean jump in the
  upper-grade share 0.58 against 0.68. Thin cohorts matter for precision, not for the mean: 7 of the 15 (4 of the earlier 20) have at most
  one birth month on one side of the cutoff, and their standard errors on achievement are about twice as large (11.7 against 5.8). But the
  8 added systems with at least two months on both sides still show gamma on achievement of 8.5 points against 21.8 in the 16 clean earlier
  systems. Across all 35, system-level gamma is nearly uncorrelated with first stage (0.04) and weakly with months per side (0.23, -0.19)
  and mean achievement (0.28). So the difference is real heterogeneity or a selection of the original 20 systems, not yet explained;
  how the 20 were chosen in the grade-gain project is the first thing to check.
- *How the earlier 20 were chosen (2026-11-16, checked).* No selection rule is documented in the repository (searched the legacy history,
  both READMEs and the central eligibility table). Not skill-scale availability (the 15 added have it at the same rate) and not the
  edge flag (partial month kept on one side): 2 of the earlier 20 and 7 of the 15 added are edge systems, but the 8 clean (non-edge)
  added systems still pool to +6.3 achievement points (SE 1.6) against +20.1 (SE 2.0) in the 18 clean earlier ones; life satisfaction
  -0.009 (SE 0.018) against -0.060 (SE 0.018). The two groups differ by region: the earlier 20 are Europe 6, Latin America 5, Southeast
  Asia 3, East Asia 3, Africa 2, Middle East 1; the 15 added are Europe 6, Post-Soviet 4, Middle East 2, Latin America, East Asia and
  Oceania 1 each. So the headline is not a selected-on-results artefact that I can show, but it does not generalise to the added systems,
  and heterogeneity by region or school system is a finding to examine (and to state), not to average away.
- *Sample rule (user, 2026-11-16).* The sample is defined by the design's own eligibility (enough students whose grade is moved by the
  birth-month cutoff, the central rule shared with paper 02), not by an outcome. All 35 eligible systems with the item are the main
  sample; the earlier 20 are a subset. Check run the same day: restricting to the 24 systems with a "strict" design (not edge-flagged
  and at least two birth months on each side) gives life satisfaction -0.046 (SE 0.015) and achievement +16.3 (SE 2.1), against -0.043
  (0.012) and +16.5 (1.7) for all 35; the 11 others give -0.035 (0.028) and +17.6 (2.5). The pooled result does not depend on
  design strictness; the between-system spread (I-squared 74% for achievement) is the open question.
- *Design tests (2026-11-16, `13_design_tests.R`, base specification, 35 systems, new directory `05_archive/estimate_20261116_design_tests`;
  `04_output` untouched, nothing promoted).* First stage 0.556 (SE 0.045; heterogeneous, I-squared 100%). Reduced form (jump at the cutoff):
  achievement +3.9 points (SE 1.2), life satisfaction -0.025 SD (0.011), P(LS = 10) -0.7 pp (0.4). Balance at the cutoff: sex 0.000 (0.004);
  ESCS +0.020 SD (0.013), home possessions +0.022 (0.012), immigrant background +0.002, other language -0.003; ESCS and home
  possessions are not clean: 6 of 34 and 8 of 34 systems individually significant (about 2 expected by chance) and heterogeneous across
  systems (Q p = 0.001), so covariate controls and the systems that drive it need a look. Density: the month just below the cutoff against
  the month just above has a median ratio 1.01; outside 0.7-1.4 only KEN (0.38), ALB (2.05), KOR (2.29), none edge-flagged (could be
  seasonality of births, not tested). Bandwidth, gamma in the 24 strict systems (full window: achievement 16.3 (2.1), LS -0.046 (0.015)):
  achievement is stable (|r| <= 6: 15.8, <= 4: 17.8, <= 3: 19.1), life satisfaction is not: -0.026 (0.022), -0.064 (0.041), -0.120 (0.049).
  The life-satisfaction cost is therefore consistent with the full-window estimate within noise but its size depends on the window;
  this is the weakest part of the design evidence. Quadratic birth-month term not run (not identified with 1-3 months on a side).
  Recovery guide for all steps: `../RULES.md`.
- *Covariates added (2026-11-16, `14_covariates.R`, new directory `05_archive/estimate_20261116_covariates`; `04_output` untouched).* Adding
  ESCS, home possessions and other-language to sex and immigrant background leaves the headline unchanged: life satisfaction -0.043
  (SE 0.012) in both specifications in all 35 systems; -0.046 (0.015) against -0.045 (0.015) in the strict 24; achievement 16.5 (1.7)
  against 16.3 (1.6). The window pattern is also unchanged by the controls (strict 24, base then plus; LS: |r|<=6 -0.026 / -0.033,
  <=4 -0.064 / -0.075, <=3 -0.120 / -0.149; achievement 15.8 / 15.9, 17.8 / 18.0, 19.1 / 19.8). So the mild ESCS and home-possessions
  imbalance does not drive the estimate, and the window dependence of the life-satisfaction cost is not a covariate effect. Decision
  (user, 2026-11-16): report the window sensitivity openly with the full-window headline and the covariate-adjusted estimate beside it.
- *External check of the inferred cutoffs (2026-11-16, `15_uis_check.R`, `05_archive/estimate_20261116_uis_check/uis_check.csv`).* Source: UNESCO UIS
  indicator 403, start month of the academic school year, export supplied by the user (`~/Downloads/indicator-data-export_403.zip`, not stored
  in the repository; latest year up to 2025). It gives when the school YEAR starts, not the birth-date rule, so it can flag oddities but not
  confirm a cutoff. Of the 36 eligible systems, 34 have a UIS month (Taiwan and Kosovo do not); the inferred cutoff birth month equals the
  UIS start month in 8 and is within one month in 12; 10 cutoffs fall in December or January (calendar-year cohorts, e.g. FIN, KOR, HKG,
  SVN, LVA, which fits known rules but was not checked against national sources). Confirming the cutoffs needs each country's official
  entry-date rule (a table for the appendix); not done.
- *Official starting age and level lengths (2026-11-16, `16_uis_ages.R`, `05_archive/estimate_20261116_uis_ages/uis_ages.csv`).* The user approved
  searching and scraping. The UIS ISCED mapping workbooks (`download.uis.unesco.org/ISCED mapping/`, 32 downloaded to the scratchpad) are free-form
  programme tables and not usable for a country panel; the clean source is the UIS public API (`api.uis.unesco.org/api/public/`,
  `data/indicators?indicator=299905&indicator=299932&indicator=999976&start=2022&end=2026`: entrance age to primary, duration of primary and
  of lower secondary), stored with the indicator-403 export in `04_output/external_uis/` (Git-ignored; `SOURCES.txt`). Result: 34 of 36 systems have
  UIS values (TAP and KSV do not). Using age at school-year start of a pupil in the lower grade g_lo, entry_age + g_lo - 1, 25 systems give 14
  (the plain reading), 7 give 15 (ARE, BRA, BRN, ECU, HRV, PSE, SRB) and 2 give 13 (MUS, ROU). The 9 flagged systems are not necessarily wrong
  (grade numbering, pre-primary counted as a grade, a lower de facto entry age as in Croatia) and need the national rule before the appendix.
  Proxies (user's decision, 2026-11-16): Taiwan (TAP) takes China's UIS values and Kosovo (KSV) Albania's, marked in the column `uis_proxy`; they
  are stand-ins, not Taiwan's or Kosovo's own official figures. With them all 36 systems have values: 27 consistent (both proxies fit,
  age_lo 14, school year starting in September), 9 flagged. Rerun into `estimate_20261116_uis_ages_v2` and `estimate_20261116_uis_check_v2`;
  the first versions (without proxies) were kept. The cutoff birth month equals the UIS school-year start month in 9 systems and is within
  one month in 13.
- *Only in the legacy 20-system file.* The SES composite and its quartile, `school`, the grade-purged skill index `SE_p` and the
  same-school / transition classification have no central counterpart; the 15 additional systems with the item need each of them defined.
- *Room for bandwidth checks.* One 12-month birth cohort per system: of the 35 systems, 11 have at least three clean birth months
  on both sides of the cutoff, 21 at least two, 14 at most one on one side (9 edge-flagged).

**Open items for this paper (Economics of Education Review).**
- Move the cutoff design to the central preparation (`03_outputs/01_harmonized/cutoff/analytic.rds`, 36 eligible systems) and to the
  corrected, tested 2SLS of `05_papers/02_fuzzy_rd_learning`. This is a new estimation: run it into a new directory and compare.
- Design evidence: reduced form by birth month, covariate balance at the cutoff, bandwidth and functional-form checks, compliers.
- Relative age and school starting age travel with the grade; the current model nets them out through a linear birth-month term only.
- Mechanisms from outcomes already in PISA (belonging, bullying, the skills themselves); workload items if a cycle carries them.
- Threshold model for the life-satisfaction item (shared with paper 03).
- Literature: schooling and wellbeing (compulsory-schooling reforms, school starting age, relative age), to be searched and verified.

Full pre-split notebook: `02_scripts/02_legacy/wellbeing_shared/HISTORY_resilwb_2026-11-14.md`.
