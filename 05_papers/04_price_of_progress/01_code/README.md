# The price of progress — code and analysis notes

Achievement, school progression and adolescent life satisfaction: the achievement slope hidden by skills, and the school-entry cutoff
design for one extra grade. Target journal: Economics of Education Review. Companion paper: `05_papers/03_resilience_cost`.

| Step | Script | Output (`04_output/`) | Notes |
|---|---|---|---|
| shared | `02_scripts/02_legacy/wellbeing_shared/01_build.py`, `02_prepare.R` | `01_data/derived/resilwb_students.csv.gz`, `resilwb_analytic.rds`, `resilwb_coverage.csv` | frozen legacy preparation used by both papers; not yet in the central harmonizer |
| 8 | `08_cutoff.R` (~1.5 min) | `cutoff_sys.csv`, `cutoff_pool.csv` | school-entry cutoff IV on the 20 grade-gain systems (`skillsgain_analytic.rds`): effect of an extra grade on LS, P(LS = 10), P(LS ≤ 4) and achievement; moderation by low SES, SES, grade-purged skill index, curiosity; school FE in same-school systems; pooled for all 20 / same-school 14 / transition 6 |
| 9 | `09_extras.R` | `extras_sys.csv`, `extras_pool.csv`, `desc_dist.csv`, `desc_decile.csv` | achievement slope of LS without / with the skill index (all, by ESCS quartile; mean, P(LS = 10), P(LS ≤ 4)); skill index on achievement; PV1 descriptives for figures. New files only |
| 10 | `10_figures.R`, `reporting.R` | `../02_results/figs/fig_b*.pdf` | read `02_results/snapshot/` only |
| — | `snapshot.py` | `../02_results/snapshot/`, `snapshot_manifest.json` | promotes results to the report; 2 files come from paper 03 (`oriv_pool.csv`, `oriv_sys.csv`) |
| — | `run_all.sh report` / `estimate <new_dir>` / `compare <new_dir>` | | reporting fits no models; estimation never writes into `04_output` |

Inputs of the cutoff design: `01_data/derived/skillsgain_analytic.rds` (legacy 20-system build: cutoff, actual grade D, assigned grade Z,
running variable r, grade-purged skill index `SE_p`) and `01_code/systems.R` (school structure and names of the 20 systems,
copied from the legacy skillsgain output). `tsls_m`, `est_sys` and `pool_iv` in `00_helpers.R` are verbatim copies of the legacy
skillsgain functions. The row-alignment error found in the grade-gain project's 2SLS (missing outcomes) does not apply to `tsls_m`:
it filters outcome, treatment, instruments, covariates and weights together before both stages.

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

**Open items for this paper (Economics of Education Review).**
- Move the cutoff design to the central preparation (`03_outputs/01_harmonized/cutoff/analytic.rds`, 36 eligible systems) and to the
  corrected, tested 2SLS of `05_papers/02_fuzzy_rd_learning`. This is a new estimation: run it into a new directory and compare.
- Design evidence: reduced form by birth month, covariate balance at the cutoff, bandwidth and functional-form checks, compliers.
- Relative age and school starting age travel with the grade; the current model nets them out through a linear birth-month term only.
- Mechanisms from outcomes already in PISA (belonging, bullying, the skills themselves); workload items if a cycle carries them.
- Threshold model for the life-satisfaction item (shared with paper 03).
- Literature: schooling and wellbeing (compulsory-schooling reforms, school starting age, relative age), to be searched and verified.

Full pre-split notebook: `02_scripts/02_legacy/wellbeing_shared/HISTORY_resilwb_2026-11-14.md`.
