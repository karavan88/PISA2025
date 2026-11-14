> Unedited lab notebook of the combined wellbeing project as it stood on 14 November 2026, before it was split into
> `05_papers/03_resilience_cost` and `05_papers/04_price_of_progress`. Paths in it refer to the old single-folder layout.

# The Cost of Resilience — skills, academic resilience and life satisfaction at 15 (PISA 2025)

**Question.** Disadvantaged students who reach the top of their system's achievement distribution ("academically resilient":
bottom within-system ESCS quartile × top within-system quartile of the math/reading/science mean) report *lower* life satisfaction
than disadvantaged low achievers in the same school, although they have more socio-emotional skills and better relationships.
Is this a real wellbeing cost, a response-style artefact, or a general high-achiever penalty?

**Why SES is not the identification problem.** Within system, ESCS explains ~1% of life-satisfaction variance (r = 0.07); adding SES
and school FE moves the skill-index slope from 0.212 to 0.201. The live threats are shared-method/temperament (→ ORIV, behavioural
measures) and scale use (→ step 3).

| Step | Script | Output | Notes |
|---|---|---|---|
| 1 | `01_build.py` (python, ~2 min) | `01_data/derived/resilwb_students.csv.gz` | all systems; LS, 6 skill WLEs, context scales, SES, 30 PVs, 80 BRR weights, parent ratings, response-style items, effort thermometers, questionnaire screen timings (STU_TT file, latin1) |
| 2 | `02_prepare.R` | `resilwb_analytic.rds`, `coverage.csv` | 74 systems (≥4 skill scales); within-system z; ESCS quartiles; skill index SEI; LOO school ESCS; ERS/ARS (18 content-free 4-pt items), ERS5/MRS5/ACQ5 (balanced skill items); speeder flags |
| 3 | `03_response_style.R` | `rs_sys.csv`, `rs_pool.csv` | cell descriptives; gap with response-style controls; without speeders; along the ladder P(LS≥k); placebo top-box on 1–10 effort thermometers |
| 4 | `04_gap.R` | `gap_sys.csv`, `gap_pool.csv` | ladder demo → +SEI → +6 skills → +relationships; Gelbach decomposition; advantaged high-vs-low achievers; difference in gaps; continuous ach × ESCS |
| 5 | `05_mechanism.R` | `mech_sys.csv`, `mech_pool.csv`, `meta_reg.csv`, `system_traits.csv` | top × moderator (LOO school ESCS, LOO school achievement per PV, female, university expectation, SEI, each skill); top-box versions; accounting with self-efficacy / expectations / career clarity (Gelbach); RE meta-regression of the step-4 gap on system traits |
| 6 | `06_oriv.R` (~2.5 min) | `oriv_sys.csv`, `oriv_pool.csv`, `oriv_resil.csv` | 17 parent-questionnaire systems; student SELFREG vs parent PQSELFREG: OLS each rater, IV each way, stacked ORIV, first stage, latent correlation; ± achievement (halo) control; part B pooled resilience gap × self-regulation (weights normalised per system, BRR) |
| 7 | `07_curiosity.R` | `cur_sys.csv`, `cur_pool.csv` | top × curiosity under: ladder outcomes, response-style controls (+ × top), RS-purged curiosity, item subsets (positive / reversed / comparative), no speeders, all six skills jointly, no SEI, advantaged quartile |
| 8 | `08_cutoff.R` (~1.5 min) | `cutoff_sys.csv`, `cutoff_pool.csv` | school-entry cutoff IV on the 20 grade-gain systems (`skillsgain_analytic.rds`): effect of an extra grade on LS, P(LS = 10), P(LS ≤ 4) and achievement; moderation by low SES, SES, grade-purged skill index, curiosity; school FE in same-school systems; pooled for all 20 / same-school 14 / transition 6 |
| 9 | `09_extras.R` | `extras_sys.csv`, `extras_pool.csv`, `desc_dist.csv`, `desc_decile.csv` | achievement slope of LS without / with the skill index (all, by ESCS quartile; mean, P(LS = 10), P(LS ≤ 4)); skill index on achievement; PV1 descriptives for figures. New files only |
| 10 | `10_figures.R`, `reporting.R` | `../02_results/figs/fig_a*.pdf`, `fig_b*.pdf` | figures and inline-number helpers; read CSVs, estimate nothing |
| — | `../03_manuscript/reportA_resilience.qmd`, `reportB_progress.qmd` | PDFs | two companion reports (problem, hypotheses, tests, results). A: resilient students as the critical case. B: achievement, school progression and life satisfaction |
| — | `run_all.sh` | steps 1–10 + reports | make-like; `FORCE=1` reruns |

**Estimation.** Per system, Fay BRR (80 replicates) + Rubin over 10 PVs via `gradegain/00_helpers.R::pisa_est`. The PV enters through
the achievement composite, so resilience status is re-derived per PV and per replicate weight. School FE by weighted within-school
demeaning. Systems need ≥80 students in each contrasted cell (drops BEL, LUX → 72; within-school models 69). Cross-system summaries:
DerSimonian–Laird RE. Germany and 13 others withhold `ST004D01T`; sex is taken from the sampling-frame `MALE` there.

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

**Correction (2026-11-14).** `cutoff_pool.csv` / `cutoff_sys.csv` were briefly overwritten by a stray background run of the pre-edit
`08_cutoff.R` (raw skill index `SE` as moderator instead of the grade-purged `SE_p`). Step 8 was rerun; the files now match the
script and the numbers above. Base, SES and curiosity rows were identical in both versions.

**Next steps (not built).**
8b. Ordered-probit / heterogeneous-threshold check (HOPIT-style) for LS-specific scale use; sensitivity bounds (sensemakr, not installed).
