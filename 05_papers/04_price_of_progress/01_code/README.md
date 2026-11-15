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
