# 13 — IV learning (scoping)

Opened 2026-11-22. Seventeen estimation steps have been run, six figures and five tables built, a first literature search done, the
outline approved, and the background, data, approach and results sections drafted. Working title "IV learning" (the author's); the paper's
title is the author's to set.

## Current state: Israel excluded, 34 systems (2026-11-23)

On 2026-11-23 the author asked to drop Israel from the paper. Until then it was kept and flagged. `01_code/sample_rules.R` now excludes
Ukraine and Israel by default, and every estimation step was run again into one folder,
`04_output/run_20261123_no_israel/` (`sh 01_code/run_all.sh run_20261123_no_israel`; the first attempt stopped at step 13 because the
script ran it before step 9, whose output it reads; the order was corrected, the run was resumed, and the unfinished folder is kept inside the
run as `failed_step13_skills_*`). Estimation code and inputs did not change between the two samples; only the sample rule did.

- **Run of record:** `04_output/run_20261123_no_israel/`, named in `01_code/run_of_record.R`, which the reporting scripts (07, 18, 19) read.
- **Kept, not to be mixed with it:** the 35-system runs `04_output/estimate_20261122_step*` and `estimate_20261123_step*`, and the exhibits,
  numbers and PDF of the 35-system draft in `04_output/superseded_20261123_exhibits_with_israel/`.
- **Everything below "Steps" in this file records the 35-system runs** as they were written on 22 and 23 November. The table here gives the
  current numbers; the manuscript and its tables carry the rest.
- **Set labels inside the saved files are unchanged** ("all (Ukraine out)", "all with ESCS (Ukraine out)"); in the current run they also
  leave Israel out, and the sets called "without Israel" equal them.
- The manuscript does not mention the sample rule, by the author's instruction of 2026-11-23: it says "we analyse 34 systems that
  meet the rule" and nothing about systems left out. The rule is recorded here and in `01_code/sample_rules.R` only.

| Quantity | With Israel (35 systems) | Without Israel (34 systems, current) |
|---|---|---|
| Systems | 35 | 34 |
| Students | 291,468 | 284,743 |
| Schools | 10,358 | 10,143 |
| Systems with socio-economic status | 34 | 33 |
| First stage, mean of systems | 0.55 | 0.55 |
| Systems with a first stage of 0.5 or more | 19 | 19 |
| Yearly gain, all systems | 16.8 (1.7) | 16.9 (1.7) |
| Yearly gain, systems with SES (the yardstick) | 17.0 (1.8) | 17.2 (1.8) |
| Same-age gain | 7.5 (2.2) | 7.9 (2.3) |
| Gap, high minus low third, points | 62.0 (3.7) | 61.7 (3.7) |
| Gap in school years | 3.6 (0.4) | 3.6 (0.4) |
| Yearly gain x SES, per SD | 0.7 (0.8) | 0.6 (0.8) |
| Same-age gain x SES, per SD | 0.8 (1.3) | 0.7 (1.3) |
| High third minus low third, yearly gain | 1.6 (2.1) | 1.3 (2.1) |
| School sample: systems / schools / students | 26 / 3,926 / 137,766 | 25 / 3,883 / 136,252 |
| Between-school SD of the gain, all systems | 17.5 (14.4 to 20.1) | 17.2 (14.7 to 19.5) |
| Between-school SD, same-level systems | 15.0 (9.4 to 19.4), p = 0.010 | 14.9 (8.8 to 19.1), p = 0.010 |
| Disadvantaged minus advantaged schools, same level | −5.0 (3.4) | −5.0 (3.4) |
| Yearly gain at the 10th / 90th percentile | 11.6 / 21.8 | 11.9 / 21.9 |
| 75th minus 25th percentile | 4.2 (1.8) | 4.2 (1.8) |
| 90th minus 10th percentile | 6.3 (3.0) | 6.4 (3.0) |
| Yearly change in curiosity, SD | 0.07 (0.02) | 0.08 (0.02) |
| Yearly change in the skills index, SD | 0.05 (0.02) | 0.05 (0.02) |
| Yearly gain x skills index | 1.5 (0.9) | 1.5 (0.9) |
| 90th minus 10th: as estimated / skills held / change | 7.5 / 6.4 / 1.3 (2.7) | 7.8 / 6.5 / 1.3 (2.7) |
| Forest, rank-weighted average treatment effect | 3.4 (1.0) | 3.3 (1.1) |

Without Israel 115 of the 297 numbers quoted in the text changed, none by more than the rounding of a headline. Two statements changed in
kind and were reworded: growth mindset now rises by 0.01 standard deviations a year, significant at 10% (it was not significant), and the
variables the forest uses most are now curiosity and sex, then socio-economic status and perseverance (enjoyment of problem-solving was
third). A ranking of students by the skill index alone now has a rank-weighted average treatment effect of 2.6 points (SE 1.0, p = 0.008);
with Israel it was 1.9 (SE 1.0, p = 0.056). The forest is fitted to a random half of the schools, so its secondary results move with the
sample more than the main estimates do.

**Exhibits and numbers (reporting only, nothing is estimated).** After a run, from the repository root:

| Step | Command | Writes |
|---|---|---|
| 7 | `Rscript 06_scoping/13_iv_learning/01_code/07_figures.R` | `fig1_gap_years`, `fig2_equal_gain`, `fig3_school_spread`, `fig4_gain_by_percentile`, `fig5_percentile_by_system`, `fig6_skills` (PDF and PNG) in `04_output/figures/` |
| 18 | `Rscript 06_scoping/13_iv_learning/01_code/18_tables.R` | `table1.tex` to `table5.tex` (booktabs, threeparttable, notes under each table) and the same numbers as CSV in `04_output/tables/` |
| 19 | `Rscript 06_scoping/13_iv_learning/01_code/19_text_numbers.R` | `04_output/tables/numbers.yml`: every number quoted in sections 3 to 5 of the manuscript, read by Quarto and quoted as `{{< meta n.key >}}`; `text_claims.csv` |
| Render | `quarto render 06_scoping/13_iv_learning/03_manuscript/iv_learning_paper.qmd` | the PDF |

Step 19 also checks the statements the text makes in words (which system is the exception, whether a difference is significant, "about a
sixth"). If a new run no longer supports one, the script lists it and stops with status 2 after writing the file, so the sentence is
rewritten and not left behind. `PAPER_RUN=<run>` points the three scripts at another run; with the 35-system folders, set `STEPn_DIR` for
each step and `PAPER_EXCLUDE="QUA"`.

Figures (second design, 2026-11-23; the author found the first, a thin pale serif look, "not beautiful"): PT Sans; large circles with a
white halo; intervals as soft rounded bars in a tint of the series colour; two strong hues, blue and orange, checked for colour-blind
separation, with ink for the mean of systems; shaded regions where a chart has two sides. The author's rules hold: every system is shown,
the mean of systems is marked once, circles with the fill carrying significance at 5% and 10%, reading notes in the caption. Figure 2
shades the two sides of the line of equal gains and counts the systems on each. Figure 3 draws the systems whose grades lie in different
levels in grey, because the spread is read in the same-level systems only. Figure 4 is the mean profile along the achievement distribution
over one faint line per system (the author's request), and beside it the mean with and without skills held fixed. Figure 5 is new, at the author's request: the same profile for every system, one small panel each,
ordered from the largest rise between the 25th and the 75th percentile to the largest fall (the gain rises in 21 of the 32 systems where
both are estimated and falls in 11; no single system is significant). Figure 6 is the yearly change in each skill next to achievement,
one circle per system.

Scripting the numbers corrected four statements of the first draft (listed in `03_manuscript/literature/citation_checks.md`): which
systems lack which skill scales; the number of systems behind the skills-held-fixed comparison of the gradient; the number behind the inner
contrast along the distribution; and that the linear school-SES estimate holds the student's own status fixed.

## Idea

PISA samples one birth cohort. Where a school-entry cutoff falls inside that cohort, children born a month apart sit a full grade apart. Being
born before the cutoff is used as an instrument for grade, with birth month as a control because it also sets age at the test. The base estimate
(what one grade adds) is paper 02's and is not the contribution. The contribution is who gains and where.

## Framing (agreed with the author, 2026-11-22)

The socio-economic gap at 15 is a gap in starting points, not in what a year of school adds. Measured against what one year adds, the low
SES third is about three and a half school years behind the high third, and a year moves both by the same step: school at this age neither
widens nor narrows the gap. The claim is limited to the year around grades 9 and 10; it does not say when the gap opened, and it does not
say the gap cannot be closed, only that an ordinary school year does not close it.

The yardstick is the yearly gain (one grade further and a year older), reported with its split into schooling at a given age and age. This
follows from the framing and replaces the earlier choice of the same-age gain as the headline; the same-age gain stays as the schooling part.

## Research questions (five, approved by the author on 2026-11-23 with the manuscript outline)

1. **How large is the socio-economic gap in achievement at 15 when measured in years of learning?** Estimated (step 6).
2. **Does the gain from a year of school differ by family socio-economic status?** Estimated (steps 4 and 5).
3. **How much do schools of the same system differ in what a year adds, and do schools with a disadvantaged intake add less?** The
   spread is estimated and checked (steps 10 and 11) and is read in the systems whose two grades are in the same level of education;
   the comparison of school types is estimated and not settled (steps 8 and 12).
4. **Does a year of school add the same along the achievement distribution?** Estimated (step 9).
5. **What does a year of school add to socio-emotional skills, and do skills change who gains?** Estimated (steps 13 to 15).

Until 2026-11-23 the project had three questions: the present 1 and 2 were one, 3 and 4 were the second and third, and skills were a
set of proposals (table below). Step descriptions further down that say "question 1", "question 2" or "question 3" use that earlier
numbering.

## Socio-emotional skills in the story (author's request, 2026-11-22)

| # | Proposal | State |
|---|---|---|
| 1 | What a year adds to skills, and whether that differs by family SES | Estimated (step 13) |
| 2 | Whether students with stronger skills gain more achievement from a year | Estimated (step 13) |
| 3 | Whether, among low-SES students, those with stronger skills gain more (a route to catching up) | Estimated (step 14): no |
| 4 | Whether schools with a stronger skill climate add more | Dropped: "the least interesting" (author) |
| 5 | How much of the SES gap goes with skill gaps | Not pursued: restates paper 01 |
| 6 | The author's idea: how the gain gradient of question 3 would change if students at the lower level had the skills of those at the higher level | Estimated two ways (steps 13 and 15): skills account for about a sixth of the outer gradient, imprecisely |

Method for proposal 6. First cut: the skill gap between students near the two percentiles times the change in the gain per SD of
skill. Rigorous version: the quantile model of step 9 with the skill index as a covariate and its interaction with grade fixed at the
two-stage least squares value, compared with the same model without skills on the same students; this asks whether a year still adds
more at the top among students with the same skills. Forests (`grf` is installed): an instrumental forest could search for skill-driven
differences in the gain without imposing a straight line, pooled over systems; birth month has to be removed linearly first, because
the instrument is a function of it, and plausible values and replicate weights are not handled by the package. Run as step 16.

## What the paper still needs

The numbers in this table are those of the 35-system runs; the current ones are in "Current state" above and in the manuscript.

| Item | State |
|---|---|
| Gap in school years with its uncertainty | Done (step 6): 3.6 years between the high and the low third (SE 0.4); 1.6 years per SD of SES (SE 0.2) |
| Figure with every system: its SES gap in school years | Done (`fig1_gap_years`) |
| Equal gain by family SES | Done by two estimators (steps 4 and 5); figure `fig2_equal_gain` |
| Gain by school intake (supplement to question 2) | Estimated (steps 8 and 12), not settled: no difference across all systems; in the 12 same-level systems disadvantaged schools add 11 points a year against 17 in advantaged ones, difference -5.0 (SE 3.4). More cohorts would be needed to decide |
| Question 3 (earlier numbering: 2), between-school spread | Done (steps 10 and 11): between-school SD of the gain 15 points (90% interval 9 to 19) where both grades are in the same level; `fig3_school_spread` |
| Question 4 (earlier numbering: 3), quantile instrumental variables | Done (step 9): the yearly gain rises from 11.6 points at the 10th percentile to 21.8 at the 90th; `fig4_gain_by_percentile` |
| Literature | First search done on 2026-11-23: 105 references checked (102 by DOI), 30 read as abstracts, no full text; `03_manuscript/literature/` holds the BibTeX file, search log, evidence table and the structure of the background section. Closest antecedents: the differential-exposure studies, including a cross-national TIMSS preprint that finds schooling narrowing the gap. Not yet done: a library database, full-text checks |
| Manuscript | Outline approved on 2026-11-23 (`03_manuscript/outline.md`). Drafted in `03_manuscript/iv_learning_paper.qmd`, each with one prose pass, rendering to PDF: "Background and research questions" (1,170 words, 47 references), "Data" (about 630 words), "Empirical approach" (about 1,190 words) and "Results" (about 2,170 words, four figures and five tables included from `04_output/`). The PDF has 20 pages. Citations that rest on recall, facts about PISA 2025 still to be confirmed and three numbers not yet in a script are listed in `03_manuscript/literature/citation_checks.md`. Not drafted: introduction, discussion, conclusion, abstract |

## Scope of question 2: how much schools differ in what a year adds

- **Sample.** Schools with 5 or more sampled students in each of the two grades: 4,019 schools and 139,827 students in 26 systems; in 16 systems
  most students attend such schools (ARE AZE BRA BRN DEU ECU EST GEO HKG KAZ KHM MUS PER PHL SRB USA). Kenya, Korea, Romania and Slovenia have
  none.
- **Quantity.** The between-school standard deviation of the yearly gain, per system, with an interval; not a ranking of schools.
- **Method used (step 10).** School-by-school gains from the difference between a school's students born before and after the cutoff, with
  the system's first stage and age slope; their dispersion beyond sampling error, with the reference distribution from shuffling birth side
  inside each school. A mixed model with a random slope was the original plan and has not been fitted.
- **What the data can detect.** A spread of about 10 points across all schools together, and about 24 points in a single system.
- **What step 8 already says.** The gain is unrelated to a school's intake and to its level of learning, so whatever spread exists is not
  explained by them.
- **Risks.** Few students per school and grade; sorting of students into schools; school random effects correlated with the regressors.

## Scope of question 3: the gain across the achievement distribution

- **Quantity.** The yearly gain at the 10th, 25th, 50th, 75th and 90th percentile of achievement, per system and summarised across systems.
- **Method.** Instrumental-variable quantile regression (inverse quantile regression in the sense of Chernozhukov and Hansen, to be verified
  against the source): for each quantile, the grade coefficient that makes the instrument irrelevant in a quantile regression of the
  score net of grade on birth month and the instrument. `quantreg` is installed. Plausible values are the right input for quantiles.
- **Cost.** The root is found by bisection, not on a grid: the run took 8 minutes on six cores (35 systems, 80 replicate weights, 10
  plausible values).
- **Reading.** If a year adds as much at the bottom as at the top, the equal-gain result holds across the distribution. If it adds less at
  the bottom, low achievers fall further behind whatever their family background.
- **Risks.** The estimates rest on rank similarity (a student's rank is the same in either grade, up to noise); birth month is discrete;
  systems with a weak first stage will be noisy, so the summary is also shown for the 19 with a first stage of 0.5 or more.

## Inputs (central products only)

| Product | Used for |
|---|---|
| `03_outputs/04_entry_rules/entry_rules.csv` | cutoff month (`pisa_cut`), eligibility, entry age, school calendar, level structure |
| `03_outputs/04_entry_rules/grade_by_birth_month.csv` | first-stage figures |
| `03_outputs/01_harmonized/cutoff/analytic.rds` | students of the eligible systems with assigned grade and distance to the cutoff |
| `03_outputs/01_harmonized/cutoff_provider.rds` | school identifiers, replicate weights, plausible values |

No rule, cutoff or shared variable is built in this project. Rules: [`02_entry_rules/README.md`](../../02_scripts/01_harmonization/02_entry_rules/README.md).

## Sample (PISA 2025, counted 2026-11-22)

| Step | Systems |
|---|---|
| Eligible cutoff in the central definition (one clean drop of at least 0.20) | 36 |
| Ukraine excluded (sample rule) | 35 (312,055 students with grade and birth month) |
| Size of the drop in the share in the upper grade at the cutoff (central definition): 0.5 or more / 0.3 to 0.5 / below 0.3 | 18 / 14 / 3 |
| First stage estimated with birth month held (step 1): 0.5 or more / 0.3 to 0.5 / below 0.3 | 19 / 10 / 6 |
| Question 1: socio-economic status available | 34 (305,174 students; Costa Rica has no ESCS; the United States has it for 55% of students) |
| Question 2: at least half of students in schools with 5 or more students in each grade | 16 (3,623 schools, 129,104 students) |

Question 2 systems: ARE AZE BRA BRN CRI DEU EST GEO HKG HRV KAZ MUS PER PHL SRB USA. The smaller grade group has a median of 6 to 24
students per school. Ten further systems have 20 to 50% of students in such schools (CHL ECU FIN ISR KHM LVA NZL PRY QCI TAP); Kenya, Korea,
Romania and Slovenia have none, because the two grades are taught in different schools.

**Sample rule (`01_code/sample_rules.R`).** Ukraine (QUA) is excluded from every estimate (author's decision, 2026-11-22). Israel (ISR) was
kept and flagged until 2026-11-23, when the author asked to drop it; it is now excluded too, which leaves 34 systems (33 with socio-economic
status). The counts in the table above are those of the 35-system sample. `PAPER_EXCLUDE="QUA" PAPER_FLAG="ISR"` reproduces the earlier
runs. Descriptive reference tables keep all systems and mark the rule.

## Empirical approach

- **Base model, per system.** Grade (upper of the two) instrumented by born-before-the-cutoff; birth month distance to the cutoff as a linear
  control; no covariates (the instrument needs none, and several systems withhold sex or immigrant background; a version with both is a check); the partial cutoff month left out where the central definition says so; 80 replicate weights and 10 plausible values.
- **Headline estimand (user's decision, 2026-11-22): `tau`, the gain with birth month fixed.** Two students of the same age at the test, one a
  grade higher: one more year in school, started a year younger and as the youngest in class. `gamma` (starting age fixed: `tau` minus twelve
  times the coefficient on birth month) compares two students who started at the same age, one a grade higher and therefore a year older: one
  more year in school plus one year of age. `gamma` is the larger number and is what "learning gain over a school year" usually means; it is
  shown beside `tau` and is not the headline. For question 1 the two agree unless the age trend differs by SES, which is tested.
- **Repeaters stay in the headline sample (user's decision, 2026-11-22).** Repetition responds to the cutoff (children born in the three
  months before it repeat 1.1 points more often than those born in the three after, higher in 22 of 35 systems) and to SES (11.7%, 9.0% and
  6.6% in the low, middle and high third), so dropping the 9.9% who repeated would select the sample on an outcome of the instrument. Three
  checks are reported beside the headline: the sample without repeaters; the 11 systems with under 5% repetition (ALB CZE EST FIN HRV KAZ KOR
  NZL QCI SRB TAP); and years in school (grade plus one for repeaters) as a second treatment. The counts are descriptive tabulations of
  `cutoff/analytic.rds`.
- **Question 1.** Grade and grade × SES instrumented by the instrument and instrument × SES, SES standardised within system and kept as a main
  effect. SES is fixed before school entry, so the interaction is a difference in the gain, not a moderator chosen by the student. Reported per
  system and pooled with a random-effects summary. The first stage is shown by SES third, because compliers may differ by SES.
- **Question 2.** School fixed effects for the mean gain. For the spread, a mixed model with a school random slope on grade and the first-stage
  residual as a control function, restricted to schools holding both grades; uncertainty from replicate weights. The quantity reported is the
  between-school variance of the gain, not a ranking of schools.
- **Systems as a level.** Systems enter through per-system estimates and a random-effects summary, not through a pooled student model.

## Steps

Run from the repository root. Estimation writes to a new directory and refuses an existing one; outputs are Git-ignored. All estimation
steps in the right order, into one run folder: `sh 06_scoping/13_iv_learning/01_code/run_all.sh <run name>` (about 50 minutes; add
`resume` to continue a run that stopped, which keeps the finished steps and sets the unfinished folder aside). Run alone, a step that reads
an earlier step needs `STEPn_DIR`; the defaults written in the scripts still point at the 35-system folders.

| Step | Command | Writes |
|---|---|---|
| Test | `Rscript 06_scoping/13_iv_learning/01_code/test_estimators.R` | nothing; 65 comparisons against `fixest`, hand computations, a simulated population with a known rank-dependent gain (with and without a covariate held fixed) and simulated units with a known spread |
| 1 | `PAPER_OUT=06_scoping/13_iv_learning/04_output/<new dir> Rscript 06_scoping/13_iv_learning/01_code/01_first_stage_base.R` | first stage (overall, by SES third), repetition at the cutoff, base grade gain; about 70 seconds |
| 2 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/02_age_profile.R` | test of the pooled design: age profile in systems without a cutoff against the one inside cutoff systems; about 20 seconds |
| 3 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/03_drifting_systems.R` | exploratory: birth month as the instrument with the borrowed age slope, in cutoff systems (validation) and drifting systems; reads the outputs of steps 1 and 2 (`STEP1_DIR`, `STEP2_DIR`); about 30 seconds |
| 4 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/04_ses_gain.R` | question 1: grade gain by SES (linear in ESCS, by thirds, within schools, without repeaters, years in school); about 2 minutes |
| 5 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/05_ses_gain_pooled.R` | question 1 by the pooled design (age profile and its change with SES borrowed from the flat systems), cutoff and drifting systems; reads the outputs of steps 2 to 4; about 1 minute |
| 6 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/06_gap_years.R` | the SES gap in school years, per system and summarised, with the split of the yearly gain; about 10 seconds |
| 6b | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/06b_scale.R` | descriptive, no model: within-system standard deviation of achievement, mean achievement percentile of the low and the high SES third, sample counts; about 15 seconds |
| 7 | `Rscript 06_scoping/13_iv_learning/01_code/07_figures.R` | reporting only: the five figures (see "Current state" above) |
| 8 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/08_school_ses.R` | the gain by school intake (school mean SES, share of low-SES students, school level of learning); about 20 seconds |
| 9 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/09_quantile_iv.R` | question 3: instrumental-variable quantile regression at five percentiles; reads step 1's first stage; about 8 minutes |
| 10 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/10_school_spread.R` | question 2: between-school spread of the gain with a within-school permutation reference (`NPERM`, default 200); about 40 seconds |
| 11 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/11_school_spread_placebo.R` | checks on step 10: a false cutoff inside one birth side, and balance of the two birth groups on family SES; reads the outputs of steps 6 and 10; about 1 minute |
| 12 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/12_school_types.R` | supplement to question 2: yearly gain in schools with a high concentration of disadvantaged students, mixed schools and schools with a high concentration of advantaged students; about 10 seconds |
| 13 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/13_skills.R` | socio-emotional skills as outcomes of a year, as moderators of the achievement gain, and the first cut of proposal 6; reads step 9's summary; about 4 minutes |
| 14 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/14_skills_catchup.R` | skills proposal 3: the skill effect on the gain within SES thirds, the three-way term, and four SES-by-skill groups; about 4 minutes |
| 15 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/15_quantile_iv_skills.R` | skills proposal 6, rigorous version: quantile instrumental variables with the skill index held fixed, against the same model without it; reads step 1's first stage; about 15 to 20 minutes, run in the background |
| 16 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/16_forest.R` | exploratory: instrumental forest (`grf`) for differences in the same-age gain by skills, SES, sex and immigrant background, judged on schools it was not trained on; about 5 minutes (`FOREST_TREES`, `FOREST_FRAC` for a trial) |
| 17 | `PAPER_OUT=<new dir> Rscript 06_scoping/13_iv_learning/01_code/17_gain_by_sex.R` | follow-up to the forest: the gain by sex with the main estimator; about 30 seconds |
| 18 | `Rscript 06_scoping/13_iv_learning/01_code/18_tables.R` | reporting only: the five LaTeX tables (see "Current state" above) |
| 19 | `Rscript 06_scoping/13_iv_learning/01_code/19_text_numbers.R` | reporting only: the numbers quoted in the text and the check of its worded claims (see "Current state" above) |

Step 1 was run once, on 2026-11-22, into `04_output/estimate_20261122_step1/` (35 systems, 291,468 students after the partial cutoff months are
left out). Random-effects summaries across systems, combined achievement (mean of mathematics, reading and science):

| Quantity | Estimate (SE) | Systems significant at 5% / 10% |
|---|---|---|
| First stage | 0.55 (0.05) | 35 / 35 positive |
| First stage, high minus low SES third (34 systems) | 0.016 (0.013) | 8 / 10 positive, 2 / 5 negative |
| Repetition at the cutoff | +0.012 (0.004) | 7 / 9 positive, 2 / 2 negative |
| `tau` (headline) | 7.5 points (2.2) | 8 / 8 positive, 0 / 2 negative |
| `gamma` | 16.8 points (1.7) | 22 / 24 positive, none negative |
| `tau` without repeaters / years in school / repetition under 5% (11 systems) | 8.5 (2.0) / 7.0 (2.0) / 7.3 (4.2) | |

Per-system standard errors of `tau` have a median of 8.9 points; the largest estimates come from systems with a first stage near 0.3.

Step 2 was run once, on 2026-11-22, into `04_output/estimate_20261122_step2_age_profile/`. It asks whether systems where grade does not move
with birth month can supply the age profile, so that the cutoff systems need not estimate it themselves (a design unlike the one-regression-
per-country approach of Avvisati and Givord).

| Quantity | Result |
|---|---|
| Systems where mean grade barely moves with birth month ("flat") | 9: GRC JOR JPN MEX MLT MYS SAU SGP VNM |
| Systems that are neither flat nor have an eligible cutoff | 38; in 37 mean grade drifts by 0.10 of a grade or more across the cohort without one clean drop |
| Age slope, flat systems | 10.2 points per year older (SE 1.4); spread across systems 1.8; no curvature |
| Age slope inside the cutoff systems | 9.8 (SE 1.7); spread across systems 6.9 |
| Difference | -0.4 (SE 2.2) |
| `tau` with the flat systems' slope imposed | 6.2 (SE 2.0), against 7.5 (2.2) in step 1 |
| Median per-system SE of `tau` | 8.9 in step 1; 6.0 with a common slope; 8.1 if slopes vary across systems as much as the cutoff systems' own estimates suggest |

Reading: the two age profiles agree, so the pooled design is admissible. It does not widen the sample by itself (9 donor systems, not 50) and
its precision gain depends on how common the age slope really is. It is kept as a second estimator beside the per-system one. Not tried: the
37 drifting systems could be brought in with the borrowed slope and birth month as the instrument, at the price of resting entirely on a
common age slope.

Step 3 was run on 2026-11-22 into `04_output/estimate_20261122_step3_drifting/` (a first attempt failed on Uzbekistan, which has no plausible
values in the PISA 2025 file, and is kept as `failed_20261122_step3_uzb_no_scores/`). With the age slope of 10.2 points per year borrowed from
the flat systems, `tau` = (score slope per year older − 10.2) / (grade slope per year older).

| Set | Systems | `tau`, random-effects summary (SE) |
|---|---|---|
| Cutoff systems, this estimator (validation) | 35 | 5.5 (2.4); step 1 gave 7.5 (2.2), the pooled design of step 2 6.2 (2.0) |
| Drifting systems, grade slope of 0.3 or more per year | 26 | 6.7 (3.6) |
| Drifting systems, grade slope of 0.5 or more per year | 17 | 7.6 (3.9) |

- On average the drifting systems give the same answer as the cutoff systems: a same-age gain of 6 to 8 points.
- System by system the estimator is not trustworthy: in the 35 cutoff systems its estimates are uncorrelated with step 1's (r = −0.02; median
  absolute difference 7.3 points, against a median step 1 standard error of 8.9). Estimates for single drifting systems are not to be reported.
- If age slopes vary across systems as much as the cutoff systems' own estimates suggest, the median standard error in the drifting systems is
  13.5 points and two systems are significant; the summary stays near 7.
- Years in school drift with birth month as much as grade does (Colombia 0.96 against 0.94, Morocco 0.77 against 0.72), so the drift is entry
  timing, not repetition. Spain, France, Belgium and Uruguay are the exceptions, and their grade slope is under 0.3 anyway.
- The United Kingdom (53 points) is not usable: its sample joins nations with different cohorts and test dates.

Reading: the drifting systems can extend pooled results to 61 systems; they cannot carry country-level results. For question 1 the borrowed
slope cancels if the age effect does not differ by SES, which the flat systems can test.

Step 4 (question 1) was run on 2026-11-22 into `04_output/estimate_20261122_step4_ses/`: 34 cutoff systems with ESCS, 261,468 students. A first
attempt stopped because school fixed effects cannot be estimated in Kenya and Slovenia, where the two grades are taught in different schools;
it is kept as `failed_20261122_step4_school_fe_collinear/`, and that specification is now skipped and logged where it cannot be estimated.
Random-effects summaries, combined achievement, per standard deviation of SES:

| Quantity | Estimate (SE) | Systems significant at 5% / 10% |
|---|---|---|
| SES gradient in the lower grade | 26.8 points (1.8) | 30 / 31 positive |
| Change in the same-age gain (`tau` x SES) | +0.8 (1.3) | 0 / 1 positive, 1 / 1 negative |
| Change in the yearly gain (`gamma` x SES) | +0.7 (0.8) | 0 / 1 positive, 0 / 1 negative |
| Change in the age slope (age x SES) | +0.9 (1.1) | 1 / 1 positive, 1 / 1 negative |
| `tau` x SES within schools (32 systems) / without repeaters / years in school | -0.4 (1.2) / +0.5 (1.3) / +1.1 (1.2) | |
| Same-age gain, high minus low SES third | +3.2 (3.2) | 1 / 2 positive, 1 / 2 negative |
| `tau` x SES by domain: mathematics / reading / science | +2.0 (1.4) / 0.0 (1.4) / +0.5 (1.5) | |

Reading: no SES difference in the gain from a grade, in any specification, domain or subset of systems, and no variation across systems
beyond sampling error (I2 = 0). The summary is precise enough to bound the effect: one more grade changes the SES gradient by between -7%
and +13% of its size (same-age gain) or -3% and +9% (yearly gain). Single systems are not informative (median standard error 10 points
per SD of SES). The age slope does not differ by SES either, so the same-age and yearly versions agree.

Step 5 was run on 2026-11-22 into `04_output/estimate_20261122_step5_ses_pooled/`: question 1 again, by the second estimator, on 34 cutoff
and 25 drifting systems (531,265 students with the 9 flat systems). In the flat systems the SES gap does not change with age (+1.0 points per
SD per year, SE 1.4).

| Change in the same-age gain per SD of SES | Systems | Estimate (SE) |
|---|---|---|
| Step 4: cutoff as instrument, own age slope | 34 | +0.8 (1.3) |
| Pooled design, cutoff systems | 34 | +0.2 (2.0) |
| Pooled design, drifting systems | 25 | -0.7 (2.9) |
| Pooled design, both | 59 | 0.0 (2.2) |

Reading: the null of step 4 holds under a different estimator and on 25 further systems. The pooled design is less precise here, because
the borrowed age-by-SES slope comes from nine systems and its error is common to all. The same-age gain itself is lower in this model
(4 to 5 points) than in step 1 (7.5): it moves by about 1.3 points for each point of the borrowed age slope, so its level is less secure
than the SES comparison.

**What question 1 says, in years.** The SES gap is 26.8 points per SD, and 60 points between the high and the low third. The yearly gain is
16.8 points. The low third is therefore about three and a half school years behind the high third, and a year moves both by the same step.

Step 6 was run on 2026-11-22 into `04_output/estimate_20261122_step6_gap_years/` (34 systems). Random-effects means: gap between the high
and the low SES third 62.0 points (SE 3.7); per SD of SES 27.2 (1.6); yearly gain 17.0 (1.8), of which schooling at a given age 7.5 and age
10.0 (schooling share 44%). **Gap in school years: 3.64 (jackknife SE 0.43, delta-method 0.44; 3.53 to 3.83 when any one system is left out);
1.60 per SD of SES (SE 0.19).** By system, with the common yardstick, from 6.1 years (Romania) and 6.0 (Germany) to 0.6 (Cambodia) and 0.3
(Kenya, not different from zero); 33 of 34 gaps are significant at 5%. A system's own yearly gain is significant in 21 of 34, so
system-specific yardsticks are saved but not used.

Step 8 was run on 2026-11-22 into `04_output/estimate_20261122_step8_school_ses/`: schools holding both grades, 26 systems, and the 16 where
most students attend such schools. Per standard deviation of the school variable, the student's own SES held alongside, 16 systems:

| Quantity | Estimate (SE) | Systems significant at 5% / 10% |
|---|---|---|
| Level: school mean SES | 33.8 points (3.0) | 16 / 16 positive |
| Level: own SES, within school SES | 11.1 points (1.3) | 13 / 14 positive |
| Change in the yearly gain per SD of school SES | +0.9 (1.2) | 0 / 0 positive, 1 / 1 negative |
| Change in the same-age gain per SD of school SES | -1.5 (2.2) | none |
| Change in the yearly gain per SD of the school share of low-SES students | -0.2 (1.2); level -31.1 (2.9) | 0 / 2 positive, none negative |
| Change in the yearly gain per SD of the school's level of learning | -1.5 (1.5); level 35.8 (2.1) | none |
| Yearly gain per SD of school SES, with the level of learning held | +2.8 (1.5) | 1 / 1 positive |

Reading (revised by step 12 below): schools with a disadvantaged intake stand about 34 points lower per SD of school SES, three times the gap
tied to a student's own SES inside a school; across these 16 systems the yearly gain does not differ by intake. The split into schooling and age is not stable at school level (the age slope is
steeper in higher-SES schools, +3.7, SE 2.2, and the same-age gain correspondingly lower), so only the yearly gain is read. In all schools of
the 26 systems the yearly gain rises with school SES (+3.6, SE 1.4), but there the grade decides which school a student attends, so that
figure is not used. These are differences between schools as they are: intake is not assigned at random, and school SES is measured from
about 35 sampled students per school.

Step 9 (question 3) was run on 2026-11-22 into `04_output/estimate_20261122_step9_quantile_iv/`: 35 cutoff systems, combined achievement.
Random-effects summaries of the yearly gain at each percentile:

| Percentile | Systems with an estimate | Yearly gain (SE) | Systems significant at 5% / 10% |
|---|---|---|---|
| 10th | 29 | 11.6 (2.8) | 5 / 9 positive |
| 25th | 35 | 14.9 (2.1) | 17 / 18 positive |
| 50th | 34 | 17.5 (1.9) | 18 / 20 positive |
| 75th | 33 | 19.4 (1.7) | 18 / 22 positive |
| 90th | 29 | 21.8 (1.8) | 15 / 18 positive |
| 75th minus 25th | 33 | +4.2 (1.8) | 0 / 3 positive |
| 90th minus 10th | 25 | +6.3 (3.0) | 0 / 1 positive |

- The gain rises step by step across the distribution: a year adds about twice as much at the 90th percentile as at the 10th.
- The two contrasts are significant at 5% in the summary of all systems (z = 2.3 and 2.1). They keep their sign and size but not their
  significance in the 19 systems with a first stage of 0.5 or more (+3.4, SE 2.1; +4.7, SE 3.3); in the 11 low-repetition systems they are
  +6.0 (3.0) and +5.8 (4.5). No single system shows a contrast significant at 5%.
- The same-age gain shows the same order (4.4, 6.7, 7.8, 8.9, 10.1) with contrasts that are not significant (+3.3, SE 2.6; +3.5, SE 4.0).
- Tail estimates are missing where the instrument is too weak to pin them down: the 10th percentile in AZE BRA CHL KSV PHL PRY, the 90th in
  ALB ARE BRA ECU KAZ KSV. The systems behind each row therefore differ; the contrasts use systems with both ends.
- This does not contradict question 1. If the gain rises by about 4 points between the 25th and the 75th percentile, the high SES third,
  which sits some 20 to 25 percentile points above the low third on average, should gain about 2 points more. Step 4 found +1.6 (SE 2.1).
- The estimates rest on rank similarity, which cannot be tested here.

Step 10 (question 2) was run on 2026-11-22 into `04_output/estimate_20261122_step10_school_spread/`: 26 systems, 3,926 schools holding both
grades, 137,766 students. Two earlier attempts the same day are kept and must not be used: with Rubin's total variance on gains averaged
over plausible values the spread came out as zero (`superseded_20261122_step10_rubin_variance`), and with a chi-square reference per
plausible value as 28 points (`superseded_20261122_step10_chisq_reference`). The first overstates sampling variance, the second ignores
that with 3 to 15 students per side the dispersion statistic is inflated by a quarter even when schools do not differ. The permutation
reference measures that inflation directly (Q/df of 1.26 under shuffling, 1.43 observed).

| Set | Systems | Schools | Between-school SD of the gain (90% interval) | Permutation p |
|---|---|---|---|---|
| All | 26 | 3,926 | 17.5 points (14.4 to 20.1) | 0.005 |
| Most students in such schools | 17 | 3,416 | 15.3 (11.8 to 18.3) | 0.005 |
| First stage within schools 0.5 or more | 17 | 1,936 | 17.2 (14.3 to 19.6) | 0.005 |
| Two grades in the same level of education | 11 | 2,222 | 15.0 (9.4 to 19.4) | 0.010 |
| Two grades in different levels | 15 | 1,704 | 19.3 (15.3 to 22.1) | 0.005 |
| Same level and first stage 0.5 or more | 7 | 781 | 12.8 (5.1 to 16.9) | 0.040 |

- With 200 permutations the smallest possible p is 0.005.
- System by system the spread is significant at 5% in 7 of 26 (Chinese Taipei 49, Hong Kong 30, B-S-J-Z 30, Mauritius 24, Kazakhstan 24,
  Serbia 19, Brunei 17) and at 10% in no further one; a single system can detect only a spread of about 24 points.
- Size: the spread is as large as the mean yearly gain (17 points). Step 8 found it unrelated to a school's intake or level of learning.
- What it may contain besides differences in learning: differences between a school's two birth groups that are not due to grade (a new
  intake in the upper grade, most plausible where the two grades are in different levels; pupils leaving or repeating), and school-specific
  age slopes, which the common slope does not remove. Plausible values pull school-by-grade differences toward each other, which works the
  other way. Step 11 sizes the first two.

Step 11 was run on 2026-11-22 into `04_output/estimate_20261122_step11_spread_placebo/` (a first attempt failed where one birth side has
only two months, so that a false cutoff cannot be told apart from the age slope; kept as `failed_20261122_step11_one_sided_schools`; such
sides are now skipped). The spread routine was first moved into `00_helpers.R`, and step 10 reproduced its saved results exactly.

| Check | Set | Systems | Schools | Spread (95% upper bound) | Permutation p |
|---|---|---|---|---|---|
| False cutoff among those born before | all | 22 | 2,577 | 0.0 points (7.7); at the real age gap 0.0 (11.3) | 0.55 |
| False cutoff among those born before | same level | 7 | 901 | 6.0 (12.2); at the real age gap 8.7 (17.7) | 0.30 |
| False cutoff among those born after | all | 7 | 1,728 | 15.5 (22.8); detectable only from 17 | 0.095 |
| Balance on family SES, real comparison | all | 25 | 3,628 | 0.16 SD of SES per grade, about 4 score points | 0.035 |
| Balance on family SES, real comparison | same level | 11 | 2,192 | 0.11 SD, about 3 points | 0.24 |
| Balance on family SES, real comparison | different levels | 14 | 1,436 | 0.20 SD, about 5 points | 0.010 |

- Where the two grades are in different levels, a school's two birth groups differ in family SES beyond chance: the upper grade is in
  part a different intake. The spread there (19 points) must not be read as learning. SES captures only part of what an admission
  selects on, so the 5 points are a floor for the intake component.
- Where the two grades are in the same level, the two birth groups are balanced on SES, and the spread of 15.0 points (9.4 to 19.4,
  p = 0.010) stands. This is the estimate to report.
- School-specific age effects are not detected in the larger false-cutoff check, and the bound rules out more than about 11 points at
  the real age gap. In the same-level systems alone the check is weaker (6 points, not significant, bound 18 at the real age gap), so
  up to roughly a third of the variance there could be age and not learning; the spread would then be about 12 points.
- The false cutoff among those born after the cutoff rests on 7 systems and can detect only 17 points; its 15.5 (p = 0.095, Brazil alone
  significant) neither confirms nor clears anything.

Step 12 was run on 2026-11-22 into `04_output/estimate_20261122_step12_school_types/`: 26 systems, 3,971 schools holding both grades, of
which 1,061 disadvantaged (55% of their students from the system's low SES third, 16% from the high third) and 1,002 advantaged (12% and
63%).

| Yearly gain, points (SE) | All 26 systems | 12 systems, two grades in the same level | 14 systems, different levels |
|---|---|---|---|
| Disadvantaged schools | 13.8 (2.0) | 11.1 (2.6) | 17.4 (3.1) |
| Mixed schools | 15.9 (2.1) | 14.9 (3.3) | 16.9 (2.9) |
| Advantaged schools | 14.7 (1.8) | 16.7 (2.3) | 11.9 (2.8) |
| Disadvantaged minus advantaged | -0.8 (2.6) | -5.0 (3.4) | +5.3 (4.0) |
| The same, own SES held | -4.2 (3.4) | -7.9 (4.9) | -0.1 (4.6) |
| Level, disadvantaged minus advantaged | -86 (6) | -95 (10) | -78 (7) |

- Systems significant for the difference in the gain, same-level set: none positive; 1 negative at 5% (Croatia), none more at 10%. Eight of
  the eleven usable same-level systems have a negative difference (Latvia's estimate is degenerate and carries no weight).
- Re-reading step 8 by level of education (saved estimates, nothing re-estimated): in the 12 same-level systems the yearly gain changes by
  +2.2 (SE 1.6) per SD of school SES and by -1.6 (SE 1.5) per SD of the school share of low-SES students; in the 14 others by +0.3 (1.8)
  and +0.4 (1.7).
- Reading: students of disadvantaged schools stand some 90 points, more than five school years, behind those of advantaged schools. Whether
  their schools also add less per year is open. In the systems where the comparison is clean, three measures point the same way
  (disadvantaged schools adding about a third less) and none is significant; the interval for the difference runs from about -12 to +2
  points. In the other systems the sign is reversed, which step 11 attributes to the upper grade being a different intake. The earlier
  statement that a year adds the same whatever the school's intake was too strong: that holds for family SES (question 1), not yet for
  schools.
- More cohorts would be the way to decide, but the author has decided to stay with PISA 2025 (2026-11-22), so this comparison is reported
  as open.

Step 13 was run on 2026-11-22 into `04_output/estimate_20261122_step13_skills/`. Skills are z-scores within the system; LEARN is the index
of the six learning skills. Coverage: 33 systems for most scales (Cambodia has none, the United States lacks curiosity), 29 for perseverance.

Do not take skill results from paper 02's saved `02_results/summary.csv`: the repository README says its skill estimates carry a
missing-outcome alignment bug. I quoted them to the author before this step (same-age effects of about zero); the estimates below, from
this project's tested estimator, replace them.

| A year of school and each skill, SD (SE) | Yearly change | At a given age |
|---|---|---|
| Curiosity | +0.073 (0.016) ** | -0.002 (0.023) |
| Enjoyment of problem-solving | +0.047 (0.015) ** | -0.054 (0.020) ** |
| Learning-skills index | +0.053 (0.017) ** | -0.052 (0.025) ** |
| Goal setting | +0.031 (0.017) * | +0.004 (0.023) |
| Cognitive adaptability | +0.030 (0.017) * | -0.063 (0.025) ** |
| Growth mindset (share) | +0.012 (0.007) | +0.001 (0.008) |
| Self-regulated learning | +0.008 (0.014) | -0.034 (0.024) |
| Perseverance | +0.007 (0.015) | -0.068 (0.021) ** |
| Belonging | -0.007 (0.014) | -0.023 (0.017) |

`**` p < 0.05, `*` p < 0.10, random-effects summary across systems. For comparison, achievement rises by about 0.18 SD a year.

- **A year adds knowledge far more than skills.** Curiosity and enjoyment of problem-solving rise a little; perseverance, self-regulation
  and belonging do not move. At a given age, one more year of school goes with lower perseverance, adaptability and enjoyment
  (0.05 to 0.07 SD). That same-age effect bundles being the youngest in class and comparing oneself with older classmates, so it is
  not read as school eroding skills.
- **The SES gap in skills is carried forward too.** Skills rise with SES by 0.06 to 0.17 SD per SD (index 0.169, SE 0.011). The yearly
  change does not differ by SES for any scale except goal setting (-0.029, SE 0.011: a little less for high SES); the same-age change
  differs for none.
- **Skills go with levels, hardly with gains.** One SD of the index goes with 18.8 points of achievement (SE 1.0), but the yearly gain
  rises by only 1.5 points per SD (SE 0.9, p < 0.10; 1.8, SE 0.9, p < 0.05 with SES held). No single skill reaches 1 point or
  significance, alone or jointly; goal setting shows +3.4 (SE 1.4) for the same-age gain with SES held.
- **Proposal 6, first cut.** Students near the 90th percentile of achievement are 0.69 SD above those near the 10th on the index (0.36 SD
  between the 75th and the 25th). At 1.5 points per SD, giving the lower group the skills of the higher one would raise its yearly gain
  by 1.05 points (SE 0.62) of the 6.3-point gradient, about a sixth (0.55 of 4.2, about an eighth, for the inner contrast). For one
  self-reported index that is a sizeable share, and the noise in the scales pulls it down: with a reliability of 0.8 for the index, which
  is an assumption and not an estimate, it would be about a fifth. It is also imprecise: the interval for the 1.05 points runs from
  about 0 to 2.3, that is, from none to a third of the gradient.
- Because a year moves the skills by at most 0.07 SD, treating them as traits the student brings is a fair approximation, not exact.

Step 14 (skills proposal 3) was run on 2026-11-23 into `04_output/estimate_20261123_step14_skills_catchup/`: 31 systems with ESCS and the
skill index.

| Yearly gain, points (SE) | Weaker skills (below the median) | Stronger skills |
|---|---|---|
| Low SES third | 13.8 (2.4) | 14.5 (3.0) |
| High SES third | 16.7 (3.2) | 16.7 (2.0) |

- Per SD of the skill index the yearly gain rises by 1.0 (SE 1.5) in the low third and 2.2 (SE 1.5) in the high third; low minus high
  -1.5 (SE 2.2). The three-way term is zero for the index (+0.3, SE 0.9) and for every scale; no system is significant at 5% for the
  index in the contrasts, one at 10%.
- Low-SES students with strong skills gain no more than high-SES students: -1.0 (SE 2.8) against all of them, -1.3 (SE 3.4) against
  those with weak skills. In level they stay 29 points (SE 5) below high-SES students with weak skills.
- Reading: skills raise where a disadvantaged student stands (14 points per SD inside the low third) but not how fast the student moves.
  They are not a route to catching up through the school year.

Step 15 (skills proposal 6, rigorous version) was run on 2026-11-23 into `04_output/estimate_20261123_step15_quantile_iv_skills/`: 32
systems with the skill index, 20 minutes in the background.

| Yearly gain, points (SE) | 10th | 25th | 50th | 75th | 90th | 75th minus 25th | 90th minus 10th |
|---|---|---|---|---|---|---|---|
| As in step 9, same students | 12.3 (2.7) | 14.1 (2.1) | 15.5 (1.9) | 18.9 (1.8) | 22.5 (2.0) | 5.5 (2.0) ** | 7.5 (3.3) ** |
| Skills held fixed | 10.8 (2.3) | 12.3 (1.9) | 15.0 (2.0) | 18.0 (2.0) | 20.3 (2.4) | 4.8 (1.9) ** | 6.4 (3.1) ** |
| Change | | | | | | -0.5 (1.6) | -1.3 (2.7) |

`**` p < 0.05. Systems with an estimate: 25 to 32 by percentile, 30 for the inner contrast, 21 to 23 for the outer one. In the 17 systems
with a first stage of 0.5 or more the outer contrast is 5.6 (SE 3.7) and 4.1 (SE 3.5) with skills held, change -1.8 (SE 3.0).

- A year still adds more at the top among students with the same skills: both contrasts stay significant at 5% with skills held.
- Holding skills fixed lowers the outer gradient by 1.3 points, 17% of it, the same share as the first cut of step 13 by a different
  route (1.05 of 6.3). Neither reduction can be told from zero: the standard error of the change is 2.7 points.
- The two rows are not the same percentiles: "the 10th percentile among students with the same skills" is not "the 10th percentile".

Step 16 (instrumental forest) was run on 2026-11-23 into `04_output/estimate_20261123_step16_forest/`: 31 systems, 270,757 students,
9,698 schools, 1,000 trees, `grf` 2.6.1, one run with a fixed seed and no tuning. A first full run stopped at the scoring stage because a
centring value had been clipped to exactly 0 or 1 (`failed_20261123_step16_clipped_centring`); a trial on 15% of schools went to a scratch
folder and is not kept. Standard errors are the package's, clustered by school; they do not include plausible-value or replicate-weight
uncertainty.

| Quantity (both halves of schools together) | Estimate (SE) | p |
|---|---|---|
| Average same-age gain | 6.8 points (1.1) | < 0.001 |
| RATE of the forest's own ranking, scored on the other half (AUTOC / QINI) | 3.4 (1.1) / 1.0 (0.3) | 0.001 / 0.001 |
| RATE of ranking students by the skill index | 1.9 (1.0) / 0.3 (0.3) | 0.056 / 0.29 |
| RATE of ranking students by ESCS | 1.6 (1.1) / 0.5 (0.3) | 0.12 / 0.09 |
| Straight-line projection of the gain on each skill and on ESCS | largest: enjoyment of problem-solving +2.0 (1.5), ESCS +1.1 (1.2) | all above 0.18 |

- The average agrees with the main estimator (7.5, SE 2.2, in step 1; 6.2 in the pooled design).
- **The forest finds real differences in the gain.** A ranking learned on half of the schools picks out, in the other half, students who
  gain more. The predicted gains have an SD of about 4 points around the mean of 6.8.
- **No single trait carries them.** Ranking by the skill index alone works at the 10% level only, ranking by SES not at all at 5%, and
  no straight-line term is significant: the same picture as steps 13 and 14. The forest splits most often on curiosity (17% of
  splits), sex (13%), enjoyment of problem-solving (12%) and SES (12%); immigrant background hardly at all (1%).
- This concerns the same-age gain; the forest cannot estimate the yearly gain.

Step 17 (gain by sex) was run on 2026-11-23 into `04_output/estimate_20261123_step17_gain_by_sex/`: 32 systems (Chile, Germany and New
Zealand withhold sex). Girls minus boys, combined achievement: yearly gain -0.7 (SE 2.5), same-age gain +0.3 (SE 3.4); by domain the
yearly difference is -1.4 (2.4) in mathematics, -0.2 (2.8) in reading, -0.7 (2.5) in science. Unlike the SES and skill terms, the sex
difference varies across systems (SD about 10 points): significant at 5% in favour of girls in 2 systems and of boys in 4, at 10% in 4
and 5. On average a year adds the same for girls and boys; in single systems it may not.

## Threats, taken from the review of the paused paper 04 design

| Threat | Plan |
|---|---|
| The jump bundles one more grade with entering a year younger and being the youngest in class | The headline is stated as that bundle; the starting-age-fixed version is shown beside it; it is not called value added |
| Repetition also jumps at the cutoff | Repeaters kept in the headline; repetition at the cutoff reported by system; the three repeater checks above |
| Cutoff read from the same cohort | Grades only, rule fixed centrally; derive from PISA 2022 if that file is obtained |
| One cohort, so birth month is also season of birth | Cutoffs fall in different months across systems; show the pooled estimate with common birth-month effects |
| Students near the cutoff change school between the two grades | Question 2 only in schools holding both grades; Question 1 shown with and without school fixed effects |
| Few compliers per school | Report the variance and its interval only; state the minimum detectable spread before estimating |

## Open decisions

1. Decided (author, 2026-11-22): PISA 2025 only. The 2018 and 2022 cohorts are not added.
2. Target journal.
3. The base model repeats paper 02's design. A paper has to stand alone, so it is re-estimated inside this project, not cited from paper 02.

## Relation to earlier work in this repository

- `05_papers/02_fuzzy_rd_learning`: the base grade gain in the same eligible systems.
- `06_scoping/07_schoolgain`: which school inputs moderate the gain (14 same-school systems; school safety the only survivor). Question 2 asks how
  large the between-school spread is, before asking what explains it.
- `05_papers/04_price_of_progress`: same design with life satisfaction as outcome, paused; its review is the source of the threats table.
