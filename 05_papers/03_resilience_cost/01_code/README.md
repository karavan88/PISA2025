# The cost of resilience — code and analysis notes

Resilient students (bottom within-system ESCS quartile × top achievement quartile) as the critical case: do they pay for academic
success with their life satisfaction? Target journal: Child Indicators Research. Companion paper: `05_papers/04_price_of_progress`.

| Step | Script | Output (`04_output/`) | Notes |
|---|---|---|---|
| shared | `02_scripts/02_legacy/wellbeing_shared/01_build.py`, `02_prepare.R` | `01_data/derived/resilwb_students.csv.gz`, `resilwb_analytic.rds`, `resilwb_coverage.csv` | frozen legacy preparation used by both papers; not yet in the central harmonizer |
| 3 | `03_response_style.R` | `rs_sys.csv`, `rs_pool.csv` | cell descriptives; gap with response-style controls; without speeders; along the ladder P(LS≥k); placebo top-box on 1–10 effort thermometers |
| 4 | `04_gap.R` | `gap_sys.csv`, `gap_pool.csv` | ladder demo → +SEI → +6 skills → +relationships; Gelbach decomposition; advantaged high-vs-low achievers; difference in gaps; continuous ach × ESCS |
| 5 | `05_mechanism.R` | `mech_sys.csv`, `mech_pool.csv`, `meta_reg.csv`, `system_traits.csv` | top × moderator (LOO school ESCS, LOO school achievement per PV, female, university expectation, SEI, each skill); top-box versions; accounting with self-efficacy / expectations / career clarity (Gelbach); RE meta-regression of the step-4 gap on system traits |
| 6 | `06_oriv.R` (~2.5 min) | `oriv_sys.csv`, `oriv_pool.csv`, `oriv_resil.csv` | 17 parent-questionnaire systems; student SELFREG vs parent PQSELFREG: OLS each rater, IV each way, stacked ORIV, first stage, latent correlation; ± achievement (halo) control; part B pooled resilience gap × self-regulation (weights normalised per system, BRR) |
| 7 | `07_curiosity.R` | `cur_sys.csv`, `cur_pool.csv` | top × curiosity under: ladder outcomes, response-style controls (+ × top), RS-purged curiosity, item subsets (positive / reversed / comparative), no speeders, all six skills jointly, no SEI, advantaged quartile |
| 8 | `08_threshold.R` (~6 min) | `thr_sys.csv`, `thr_pool.csv`, `thr_model.csv` | ordered-probit threshold model for the ladder (≤3, 4, …, 10): one latent shift per system; pooled model with a separate shift at every threshold, with thresholds that also move with the four scale-use indices, and with a mean-and-spread alternative; external-criterion check on the relationship composite. `thr_pool.csv` and `thr_model.csv` are in the snapshot. |
| 9 | `09_focal.R` (~2 min) | `foc_sys.csv`, `foc_pool.csv`, `foc_model.csv` | focal answers: gap in the share giving each answer 0–10; 5 against its neighbours; share answering 0 or 5; heaping at 0, 5 and 10; achievement gradient of focal answering inside a status quartile; pooled mixture arithmetic for the share of the gap at 10 that coarse scale use can produce. `foc_pool.csv` and `foc_model.csv` are in the snapshot. |
| 10 | `10_figures.R`, `reporting.R` | `../02_results/figs/fig_a*.pdf` | read `02_results/snapshot/` only |
| — | `snapshot.py` | `../02_results/snapshot/`, `snapshot_manifest.json` | promotes results to the report (13 files); 2 files come from paper 04 (`cutoff_pool.csv`, `desc_dist.csv`) |
| — | `run_all.sh report` / `estimate <new_dir>` / `compare <new_dir>` | | reporting fits no models; estimation never writes into `04_output` |

**Working rules for this folder.**
- This paper's session writes only inside `05_papers/03_resilience_cost/`. The companion paper and `02_scripts/02_legacy/wellbeing_shared/` are read-only here.
- Figures and the report read `02_results/snapshot/` only. Estimation writes to `04_output/`; a result reaches the report only through
  `snapshot.py refresh` (with `--replace` when a file changes, which archives the previous snapshot to `05_archive/`).
- Re-estimation goes into a new directory (`run_all.sh estimate <new_dir>`), is compared with `04_output` (`run_all.sh compare`), and
  the reason for any difference is recorded below before `04_output` is updated. Never run two copies of a step at once.
- Files that come from the companion paper are listed in `snapshot.py` with their source; refresh them deliberately, not automatically.

**Estimation.** Per system, Fay BRR (80 replicates) + Rubin over 10 plausible values (`pisa_est` in the shared helpers). The plausible value
enters through the achievement composite, so anything defined on achievement is re-derived per plausible value and per replicate weight.
School fixed effects by weighted within-school demeaning. Cross-system summaries: DerSimonian–Laird random effects. Sex comes from the
sampling-frame `MALE` where `ST004D01T` is withheld (14 systems). ISL, LUX, MAC, MLT have no school ID in the public file.
Systems need ≥80 students in each contrasted cell (drops BEL, LUX → 72; within-school models 69).

**Why SES is not the identification problem.** Within system, ESCS explains ~1% of life-satisfaction variance (r = 0.07); adding SES
and school FE moves the skill-index slope from 0.212 to 0.201. The live threats are shared-method/temperament (→ ORIV, behavioural
measures) and scale use (→ step 3).

**First results (RE means, life satisfaction in within-system SD, within school).**
- Resilient vs disadvantaged low achievers: −0.09 (demo) → **−0.19** with the skill index → −0.19 with skills + relationships
  (−0.44 ladder points). 61/69 systems negative, 14 significantly; I² = 0. Skills and relationships *mask* the gap (Gelbach: SEI +0.036,
  belonging +0.017, family support +0.010).
- Not response style: controlling content-free extreme/acquiescent/midpoint responding gives −0.21 (same sample without: −0.20);
  dropping speeders −0.20. Resilient students are *more* extreme on the content-free pool (+0.14 SD).
- The gap lives at the top of the ladder: P(LS≥6) −0.4 pp, P(LS≥9) −12.7 pp, P(LS=10) −15.7 pp.
- Placebo: resilient students do **not** avoid 10 on the effort thermometers (test effort −1.5 pp; effort-if-counted +16.6 pp;
  questionnaire effort +0.8 pp); netting these out leaves the LS top-box gap at −15.6 pp.
- General high-achiever penalty: advantaged top vs low achievers −0.10 with SEI; difference in gaps −0.07 to −0.09 (44–51/69 negative).
  Continuous: −0.06 SD per SD of achievement holding skills and ESCS (I² = 80); ach × ESCS interaction small (+0.009).
- Identification caveat: median 66% of resilient students share a school with a disadvantaged low achiever (NLD, LBN ~21%; tracked
  systems low), so within-school estimates lean on comprehensive systems. Achievement is a collider for skills → do not compare
  high- and low-skill students *within* the resilient cell.

**Mechanisms (step 5; within school, demo + SEI; interactions per SD of the moderator; 69 systems).**
- The gap is strikingly uniform. No structural moderator moves it: school SES (status mismatch) −0.01 (SE 0.055); school achievement
  (big fish / little pond) −0.01 (0.057); female +0.04 (0.034); university expectation −0.00 (0.037). Top-box versions also ≈ 0.
  Between systems, I² = 0 and no trait predicts the gap (mean LS, share of 10s, ESCS segregation, mean achievement, share in mixed
  schools: all |t| < 1.8).
- Candidate channels account for nothing: resilient students have more science self-efficacy (+0.31 SD) and more university plans
  (+20 pp), but neither carries life satisfaction once skills are held, so the gap goes −0.205 → −0.214.
- Skill composition is the one signal: **self-regulated learning shrinks the gap (+0.062, SE 0.017, t = 3.6)** and **curiosity widens it
  (−0.061, SE 0.018, t = −3.4)**. Both survive Bonferroni across the 10 moderators. Perseverance (+0.02), goal setting (0.00) and
  adaptability (0.00) do not moderate it, which runs against a "grit/self-control cost" (skin-deep resilience) reading. Note that
  SELFREG uses a frequency format (less shared method with the agree scales and LS); curiosity is agree-format.
- ISL, LUX, MAC, MLT have no school ID (missing) in the public file, so within-school models drop them; they enter only the no-FE rows.

**Two raters (step 6; 17 systems, 15 with school IDs; achievement-controlled spec; RE means).**
- Skill → life satisfaction survives a change of rater: student-rated self-regulation 0.17 SD per SD, parent-rated 0.10 (14/15 systems
  significant). The parent rating shares no questionnaire with the outcome, so about 60% of the self-report slope is not shared method.
  Parent-rated emotion management (the SSES skill PISA 2025 lacks): 0.11.
- Raters agree weakly (first stage 0.11; F < 10 in DOM, MNG, ARE). ORIV slopes are ~1.1 SD per SD of the observed measure (IV each way
  0.84 / 1.40) -- per-SD-of-measure slopes inflated by 1/loading, not credible as magnitudes. The scale-free quantity, the correlation
  of LS with the latent skill shared by both raters, is **0.39** (SE 0.02; 0.37 without the achievement control), against 0.17 observed.
  Caveat: if parents' ratings carry a general "my child is doing well" halo that also tracks the child's mood, the shared factor is
  broader than self-regulation and 0.39 overstates it. Same results when the three weak-instrument systems are dropped.
- **The self-regulation moderation of the resilience gap does not replicate with the parent rating.** Pooled 17-system data
  (2,660 resilient, 9,770 disadvantaged low achievers): student-rated top × SR +0.064 (SE 0.044), parent-rated −0.006 (SE 0.043), ORIV
  −0.72 (SE 0.57, uninformative). The parent subsample is underpowered (CI on the cross-rater interaction ±0.085), but the point
  estimate is zero: treat the step-5 self-regulation/curiosity moderation as possibly self-report-specific.
- The resilience gap itself is similar in the parent subsample (−0.13 with SR held, either rater).

**Curiosity (step 7; 68 systems with school IDs and curiosity; top × curiosity, per SD).**
- Survives every within-questionnaire check: base −0.062 (t −3.4); with extreme/acquiescent/midpoint responding and their top
  interactions −0.053 (t −2.2); curiosity purged of response style −0.046 (t −2.5); without speeders −0.057; jointly with all six skills
  −0.069 (self-regulation +0.066 in the same model); without the skill index −0.044.
- Not acquiescence: the reversed item alone ("learning new things is boring", reversed) gives the same sign, −0.033 (t −1.8); acquiescence
  would push it the opposite way. Positive items −0.071, comparative item ("more curious than most") −0.057. Caveat: the reversed item
  correlates only 0.10 with the positive items.
- **It works in the lower tail, not at the top**: P(LS ≤ 4) +1.6 pp per SD (t 2.7); P(LS = 10) −0.7 pp and P(LS ≥ 9) −0.8 pp (both ns).
  The main gap is a top-box gap; curious resilient students are instead more often outright dissatisfied.
- Not resilience-specific: among advantaged students the high-achiever × curiosity interaction is −0.037 (t −2.6).
  Resilient students are more curious than disadvantaged low achievers even net of the skill index (+0.20 SD).
- No system is individually significant (I² = 0): a small, uniform pooled effect. There is no second rater for curiosity, so shared-method
  bias in the self-report → self-report link remains possible; the step-6 failure of self-regulation is the cautionary precedent.

**Threshold model (step 8; 69 systems; 13,760 resilient and 41,011 disadvantaged low achievers; added 14 November 2026).**
PISA 2025 has no anchoring vignettes and no second wellbeing measure, so thresholds specific to resilient students cannot be separated
from a difference in latent satisfaction. The step shows what a reporting explanation would have to look like and tests what it can.
Probit models use school means of every regressor (Mundlak) in place of school fixed effects; the pooled model gives each system its
own thresholds and covariate effects and equal weight. Units: SD of the latent residual, not SD of the observed ladder.
- One latent shift (the model behind a "gap in SD"): per system −0.28 (SE 0.021; 65/69 negative, 19 significantly, I² = 0) with the
  skill index, −0.17 without; pooled −0.26 (SE 0.026).
- **The gap is not a uniform shift.** Shift at each threshold, skill index held: ≥4 −0.10, ≥5 −0.11, ≥6 +0.02, ≥7 −0.02, ≥8 −0.14,
  ≥9 −0.38, =10 −0.65. Mean of the top two minus mean of ≥4…≥7: −0.46 (SE 0.025). Implied gaps for the average resilient student:
  −13.1 pp at 9 or 10 and −18.2 pp at 10 (step 3, linear with school FE: −12.7 and −15.7). A model with common thresholds and a
  different mean and spread for resilient students (mean −0.27, spread ratio 0.76) recovers only 48% of the improvement in fit.
- **Measured scale use does not account for it.** Letting every threshold move with the four response-style indices: extreme
  responders are more often at both ends, as expected, but the top-two shift is −0.56 against −0.52 in the same sample without them.
- **Bounds.** If everything at the two top thresholds were reporting, the remaining gap is the shift at ≥4…≥7: −0.05 (SE 0.028;
  −0.07 with scale use in the thresholds). If none of it is, the gap is −0.26. The data cannot place the truth between the two.
- **External-criterion check: inconclusive.** At the same answer, resilient students stand higher on the relationship composite
  than low achievers, and more so at the top: R × answer relative to ≤3 is +0.07, +0.08, +0.08, +0.11 at 4–7 and +0.17, +0.22, +0.32
  at 8, 9, 10; R × (answer ≥ 8) +0.14 (SE 0.029). A pure reporting difference predicts 0 at 4–7 and +0.05, +0.11, +0.12 at 8–10; a real
  difference predicts about 0, and −0.07 at 10. But the difference rises along the whole ladder, where thresholds do not differ
  (slope +0.07 per latent SD, SE 0.037), and once that slope is allowed the excess at 8, 9, 10 is +0.01, +0.03, +0.07 (SE 0.05, 0.06,
  0.09): compatible with the reporting prediction (+0.06, +0.13, +0.13) and with zero. The check does not exclude a reporting
  component and does not establish one. Belonging carries most of the composite result (+0.18; other scales +0.05 to +0.07).
- Consequence for H3: supported against general scale use; a ladder-specific difference in the bar for 9 and 10 is not identifiable
  in PISA 2025 and has to be stated as a limitation. "The gap is a shortfall of very high answers" is exactly what the model shows.
- Run record: estimated twice into fresh directories (the second run added the whole-ladder profile and the excess test); all 131
  model terms, 19 pooled terms and 1,518 system terms shared by the two runs are identical. The second run's files were copied into
  `04_output` as new files (`logs/thr.log`, `logs/thr_run.json`); no existing file changed. Likelihood checked against
  `MASS::polr` and `ordinal::clm` on one system. Steps 3–7 were not rerun.
- Promotion (14 November 2026): `thr_pool.csv` and `thr_model.csv` added to the snapshot with `snapshot.py refresh` (no `--replace`:
  the nine existing files were unchanged, verified by hash; the previous manifest is kept in `05_archive/manifest_20261114T161051Z/`).
  In the report, H3 now covers general response style only and the ladder-specific standard is RQ3 (not identifiable, bounded).

**Focal answers (step 9; 69 systems within school; added 14 November 2026 after the literature stage).**
Barrington-Leigh (2024) shows in PISA 2018 that answers 0, 5 and 10 become rarer as mathematics scores rise and reads it as less numerate
respondents simplifying the scale. That reading predicts an excess of 0s and 5s among low achievers, where neither a real difference
nor a stricter standard for the top predicts anything. Resilient minus disadvantaged low achievers, skill index held, percentage points:
- **The prediction holds.** Answer 0: −0.5 (SE 0.20); answer 5: −2.3 (SE 0.52); answer 10: −15.7 (identical to step 3). Answers 1–4 and
  6: between 0.0 and +1.1; answers 7, 8, 9: +3.5, +6.4, +3.7. Answer 5 against the mean of 4 and 6: −3.3 (SE 0.66), negative in 59 of
  69 systems. Share answering 0 or 5: −2.9 (SE 0.56), and −2.6 with the response-style indices, so those indices do not capture it.
- **Heaping.** Among students answering 4–6, resilient students are 11.5 points less likely to answer 5 (SE 1.6); among 0–1, 11.2
  points less likely to answer 0 (SE 4.3); among 9–10, 26.4 points less likely to answer 10 (SE 1.5) (pooled, system fixed effects).
- **It is a gradient in achievement, in both status groups.** Per SD of achievement within the bottom quartile: share answering 0
  or 5 −1.4 (SE 0.16), share of 5 among 4–6 −5.4 (SE 0.68). Within the top quartile: −0.8 and −3.0.
- **How much of the shortfall of 10s it can produce.** If simplifiers answer only 0, 5 or 10 and full-scale users answer 5 as often
  as the mean of 4 and 6, the excess of 5s puts the simplifier share at 10.3% of low achievers (SE 0.5) and 0.3% of resilient students
  (SE 1.0). Removing their answers takes the raw gap at 10 from −14.1 to −11.4 (19% explained, SE 3) if simplifiers round to the nearest
  focal value, and to −8.1 (43%, SE 7) if they round up from 7. Heaping at 10 beyond the heaping at 0 and 5: −15.1 of 26.4 points.
- **Comparisons that do not depend on rounding within a band.** Share at 8 or more: −6.1 (SE 1.0); at 7 or more: −1.8 (SE 0.9); at
  most 3: +1.5 (SE 0.56); at most 2: +0.3 (SE 0.41).
- Consequence: part (c) of the proposed H3 fails. Coarse use of the scale by low achievers produces a part of the gap, on these
  assumptions between a fifth and two fifths of the shortfall of 10s; the larger part is not accounted for, and resilient students
  remain 6 points less likely to answer 8 or more. The mixture numbers are arithmetic on two answer distributions under stated
  assumptions, not a fitted model; a fitted mixture (Barrington-Leigh's) is the fuller version and has not been built.
- Run record: estimated twice into fresh directories (the second run added the mixture arithmetic); all shared terms identical. The gap
  at 10 and at 8 or more reproduce step 3 to seven decimals. Files copied into `04_output` as new files (`logs/foc.log`,
  `logs/foc_run.json`). No other step was rerun.

**From the companion paper (snapshot of `cutoff_pool.csv`).** An extra grade at the same age lowers life satisfaction by 0.056 SD; the
interaction with the bottom ESCS quartile is −0.014 (SE 0.034), so the causal design does not reproduce the larger penalty for
disadvantaged students that the cross-section suggests (difference in gaps −0.07 to −0.09).

**Structure of the report since 14 November 2026 (author's decision).** Measurement validity is not a hypothesis. The report has
three hypotheses (H1 the cost, H2 masking, H3 specificity, formerly H4) and two research questions (RQ1 context, RQ2 skills). What
was H3 (scale use) and RQ3 (standard for the top) is one short robustness section; it is to stay short. Notes above written before
this decision, and the scoping review in `03_manuscript/literature/`, use the old labels (H3 = scale use, H4 = specificity, RQ3).
`foc_*` was promoted with `snapshot.py refresh` (existing files unchanged; previous manifest in `05_archive/manifest_20261114T185631Z/`).

**Open items for this paper.**
- The top-of-ladder question needs data this cycle does not have (vignettes or a second wellbeing measure): check PISA 2018/2022.
- Literature stage: a hypothesis-based scoping review is in `03_manuscript/literature/` (14 November 2026; 217 sources, DOIs checked
  against Crossref). Its rewording of H1, H2, H3, RQ1 and RQ2 is applied in the report, which now cites `literature/references.bib`
  and prints a reference list (29 sources). Still to do: read the abstract-only sources in full (most of those cited), and give
  `references.bib` one pass for style (names as Crossref stores them; U+2010 hyphens and two mis-encoded titles were fixed by hand).
- Optional, low priority: a fitted mixture model of focal answering in place of the mixture arithmetic of step 9.
- Raised by the review, not run: quantile comparisons, and response time on the life-satisfaction screen (needs the shared preparation).
- Emotional-stability skills (PISA 2022) and a eudaimonic outcome (PISA 2018), both to be confirmed against the codebooks.
- Central migration of the shared preparation (`02_scripts/01_harmonization`) before any fresh processing is treated as maintained.

Full pre-split notebook: `02_scripts/02_legacy/wellbeing_shared/HISTORY_resilwb_2026-11-14.md`.
