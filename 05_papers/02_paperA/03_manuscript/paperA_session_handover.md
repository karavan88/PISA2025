# Paper A (PISA 2025) — complete session handover

**Purpose of this file.** Context for another assistant (or a collaborator) picking up Paper A. Attach it together with the repo folder `PISA2025`. It records the task, the author's standing rules, every design decision and why it was taken, everything that was tried and abandoned, every technical problem and its fix, and the current results. It is not a verbatim chat transcript — the verbatim log of the early part of the session is no longer held in the workspace — but it is a complete record of the substance. Appendices A–D reproduce the working notes written during the session, unedited, so the earlier stages (proposal, bloc analyses, random slopes) are documented in their original form.

Author: Karen (Garen) Avanesian. Sessions: 25–27 September 2026.

---

## 1. Task

Paper A: socio-emotional skills as mediators of the socio-economic gradient in achievement in PISA 2025, for 19 non-OECD East Asian / post-Soviet / post-communist systems (no Ukraine). Target journals: *International Journal of Educational Development* or *Education Economics*.

Deliverables (all delivered): Quarto manuscript (`04_manuscripts/paperA/paperA.qmd`, PDF 30 pp + DOCX), numbered R scripts (`02_scripts/paperA/`), CSV outputs (`03_outputs/paperA/`), presentation deck (Claude Slides, 18 slides), README, and working notes in the "PISA 2025" Claude project.

## 2. The author's standing rules (apply to all future work)

1. Every paper is written in Quarto (.qmd) — "always as the rule". R code lives separately, numbered, in the scripts folder.
2. **All models are run on each country separately.** No pooled models, no bloc fixed-effects models.
3. **No aggregation by groups/blocs at all.** Report the set of countries and the **median** of coefficients (median preferred over the mean), with the interquartile range. Blocs (East Asia / post-Soviet / post-communist Europe) appear only as labels in figures and tables.
4. One mediation framework: Imai–Keele–Tingley causal mediation via the R **`mediation`** package; single-mediator models are the estimates of record. **Gelbach decomposition is kept only as a sensitivity / composition check.** A correlation matrix of skills and outcomes must be shown; the Gelbach sign reversals for goal setting and problem-solving enjoyment are explained by collinearity among the skills, which supports the Imai approach.
5. No interaction models; separate estimations only. The heterogeneity / returns-to-skills-by-SES research question is **dropped entirely — "not even for appendix"**.
6. **Do not understate the results.** The author's view: "everything that has the magnitude of the effect above 10 % is huge to me." Frame mediated shares above 10 % as a substantial channel.
7. The presentation must make clear which research question uses causal mediation and where the Gelbach decomposition comes in.
8. **Growth mindset** (single item ST420Q01) is included as a **binary** mediator (standardising a single 4-point item would not be meaningful).
9. **No OECD standardisation of skills** ("not meaningful"). Rescale skills to the current analytic sample; within-country scaling kept as an alternative.
10. **ESCS enters as the within-country percentile rank** — "1 unit of ESCS index says NOTHING!" Percentile rank is the headline; ESCS in index units only as a check (appendix).
11. Terminology: "socio-economic gradient", **not** "class gradient".
12. Non-random selection into schools: the author asked whether school random effects should feed into the mediation. Decision after discussion: **keep the Mundlak school-mean specification** and state explicitly that it equals the within-school (fixed-effects) estimator.
13. **Material deprivation as a second exposure**: build an index out of all available items — "degree of deprivation matters. It's fine that some countries have 4 and some 5, we can put a footnote."
14. Country selection: **keep the 19 systems as is** (the author considered "all non-OECD except Ukraine, Azerbaijan, Kosovo, Chinese Taipei" and decided against changing).
15. Workflow: estimation must **never rerun when the .qmd renders**; all estimates are saved to CSV and the manuscript only reads them.
16. Estimation runtime is a sore point ("what are you doing so long", "still running??? it's insane"). Long reruns of appendix specifications were deliberately killed. Any future rerun must be justified and kept short (use the `MED_FAST`, `MED_ONLY` and timestamp mechanisms below).

## 3. Chronology — what was tried, kept and abandoned

**Stage 0 — data audit and proposal (25 Sept, morning).** Full inventory of the PISA 2025 PUF (student, school, teacher, LDW process data). Identified the six WLE socio-emotional scales, the growth-mindset and status-fatalism items, the new material-deprivation module, school SEL-policy items. Proposed a three-bloc sample (East Asia, post-Soviet, post-communist non-OECD) and a programme of papers A–D (mediation; fuzzy RD at school-entry cutoff; school SEL policy; reported vs revealed perseverance). See Appendix A.

**Stage 1 — Gelbach decomposition, pooled and by bloc (25 Sept, afternoon).** First version of Paper A: pooled models with economy fixed effects, Gelbach decomposition of the ESCS gradient into six skills, bloc contrasts, SES contrast defined as top-10 % vs bottom-10 % groups, skill × ESCS interactions, deprivation penalty, skill × grade "value-added" (H3). Result: pooled mediated share ≈ 8 % of the total gradient, ≈ 17 % within school; curiosity dominant. **Abandoned later:** pooled/bloc estimation (rule 2–3), B10/T10 group contrast (replaced by percentile rank), interactions (rule 5), H3. See Appendix B.

**Stage 2 — Imai causal mediation and random slopes (25 Sept, evening).** Implemented the LSEM closed form of Imai–Keele–Tingley by hand because the `mediation` package could not be installed from CRAN at that point (later installed from GitHub source, version 4.5.1, and the closed form was confirmed to reproduce `mediate()` for linear models). Added `medsens`-style sensitivity ρ*. Fitted lme4 random-slope models (school random intercept + random slopes of skills across economies and across ESCS groups) to test whether returns to skills vary by SES. See Appendix C.

**Stage 3 — per-economy random slopes by ESCS decile (26 Sept).** Re-fitted random slopes separately per economy across weighted ESCS deciles. Finding: returns to skills do **not** vary with SES within any system (0 of 112 decile-1 vs decile-10 differences significant); heterogeneity is between systems. **Consequence: the returns-by-SES research question was dropped entirely** at the author's instruction. See Appendix D.

**Stage 4 — framework decision (26 Sept).** Author's question: in Imai's model mediators enter separately (not controlling for the other mediators), while in Gelbach they enter jointly — so Gelbach should be the sensitivity check. Agreed. The Gelbach sign reversals (goal setting −1.2 %, problem-solving −0.9 %) are suppression effects from collinearity (curiosity–problem-solving r = 0.53; perseverance–curiosity 0.49), which is why single-mediator Imai ACMEs are the estimates of record and a correlation matrix was added (script 03).

**Stage 5 — presentation and "median of countries" rule (26 Sept).** Deck built. Author's reaction: aggregating by blocs "makes 0 sense" → all bloc means removed from tables, figures and text; medians + IQR across the 19 systems everywhere; blocs only as labels. Second reaction: results were understated and the deck did not say which RQ used which estimator → headlines reframed (≥ 10 % = large), RQ ↔ estimator labels added to every slide.

**Stage 6 — growth mindset, rescaling, correlation matrix (26 Sept).** GROWTH = 1 if ST420Q01 = 1 or 2 (disagree with "intelligence is something you can't change much"). Skills re-standardised to the analytic sample (senate-weighted mean 0 / SD 1); `_oecd` and `_zw` (within-system) versions kept. Correlation matrix of 7 dispositions + ESCS + three domains produced. **Probit vs LPM for the binary mediator:** with a probit mediator model, `mediate()` simulates Bernoulli draws of the mediator, inflating the Monte Carlo SD about 4× at the same point estimate (SD 0.338 vs 0.085) — only 1–7 systems significant. Switched to a linear-probability mediator model; significant in 10/19. A partial-rerun mechanism (`MED_ONLY=GROWTH`) was added so only the growth-mindset rows were re-estimated and merged into the existing output files.

**Stage 7 — percentile rank, Mundlak, deprivation, country frame (26–27 Sept).** Author's long message: ESCS units are meaningless → percentile rank; "socio-economic" not "class"; worry about selection into schools; test deprivation as an exposure; reconsider the country frame; stop reruns on render. Decisions (via a four-question prompt): keep Mundlak school-mean controls (= within-school estimator, stated explicitly, cites Mundlak 1978); keep 19 systems; percentile rank headline with units as check; deprivation index = count of "cannot afford" items among those fielded in each system, with a footnote on the 4- vs 5-item difference. The whole pipeline was generalised with a `PISA_TREAT` switch (ESCS_PCT / ESCS / DEP) and rerun; the manuscript, figures, tables, deck, README and project notes were rewritten accordingly. ESCS-in-units reruns for maths and science were killed at the author's request (reading units kept for the appendix).

## 4. Data and measures (final)

- PISA 2025 PUF (CY09). Outcomes: PV1–10 READ / MATH / SCIE. Weights: W_FSTUWT, senate weights for pooling descriptives; Fay BRR replicate weights W_FSTURWT1–80 (variance = Σ(θ_r − θ)² / 20). Rubin combination across 10 PVs.
- Skills (WLE scales, SSES mapping): PERSEV (perseverance), CURIO (curiosity), ENPROBS (stress adaptability), COGABIL (problem-solving enjoyment / cognitive ability self-concept), GOALSET (goal setting), SELFREG (self-regulated learning); GROWTH (binary, ST420Q01). PERSEV not fielded in Kazakhstan and Albania.
- Deprivation: ST488Q01/02/08/09 (all systems) + ST401Q03–07 (national options; ST401 not fielded in MNG, MKD, ARM, BGR, KSV). Code 2 = "cannot afford". DEP = count among items fielded in that system; fielded = ≥ 90 % answered among students who reached the module. (An earlier version computed the denominator over all students and gave Armenia 0 fielded items — fixed.)
- ESCS_pct = weighted within-country percentile rank on the full national sample (`wrank()`); ESCS_pct10 = rank/10, so coefficients are per 10 percentile points; the P10→P90 contrast is ≈ 8.9 units (median across systems). School-mean leave-one-out versions: `sch_escs_loo`, `sch_pct_loo`, `sch_dep_loo`.
- Controls: gender, grade, immigrant background, language at home, plus school-level Mundlak means, private, urban (within-school specification). Under DEP the student's own ESCS is an additional covariate (deprivation "at given ESCS").
- Systems: East Asia — B-S-J-Z China (QCI), Hong Kong, Macao, Viet Nam, Mongolia; post-Soviet — Kazakhstan, Uzbekistan (science only), Kyrgyzstan, Georgia, Azerbaijan, Moldova, Armenia; post-communist Europe — Serbia, Bulgaria, Romania, Croatia, Albania, N. Macedonia, Montenegro, Kosovo. 19 systems for reading/maths (Uzbekistan has no READ/MATH PVs), 20 for science. Macao has no school ID (no school controls). Armenia ≈ 60 % item non-response on skills; BGR/KSV/MKD/GEO/SRB 22–32 %, selective → IPW robustness check.
- Analytic N = 113,799 (reading 107,878).

## 5. Methods (final)

- **Causal mediation** (`mediation::mediate`, quasi-Bayesian, identical weights in mediator and outcome models — `mediate()` requires this). One model per system × domain × specification × mediator. Reported: ACME, ADE, total effect, proportion mediated, all Rubin-combined over PVs. `medsens` gives ρ* (residual correlation at which ACME = 0) and R̃² thresholds; evaluated on a 0.05 grid.
- **Joint block** of all seven mediators: total − direct from the full outcome model (algebraically equal to the Gelbach sum), BRR standard error. Closed-form ρ* for the joint block via the index mediator M* = Σ γ_k M_k (script 09b).
- **Gelbach decomposition** (script 04): allocation γ_k π_k of the change in the ESCS coefficient when the seven skills are added; used only as a composition check and to demonstrate suppression.
- **Two specifications.** Within-school: Mundlak leave-one-out school mean of the exposure + private + urban → equivalent to the school fixed-effects (within) estimator. Total: no school controls. Between-school component ≈ 56–59 % of the total gradient.
- **Summary across systems:** median and IQR of coefficients over the 19 systems. Bulgaria is omitted from within-school share figures (within-school gradient ≈ 1.1 points per 10 percentile points → share not identified).
- **Robustness** (script 07): modal-grade sample; inverse-probability weighting for item non-response; each per system, summarised by medians.

## 6. Scripts and workflow (`02_scripts/paperA/`)

| Script | Role |
|---|---|
| `00_helpers.R` | skills vector (incl. GROWTH), labels, `binary_skills`; treatment switch `PISA_TREAT` → `TREAT_VAR`, `TSUF` (`""`, `_pct`, `_dep`), `SCH_LOO`, `TREAT_COV`; BRR / Rubin helpers |
| `02_prepare.R` | analytic file: GROWTH, sample-standardised skills (`_oecd`, `_zw` kept), ESCS percentile rank, deprivation count, school leave-one-out means |
| `03_descriptives.R` | sample table; correlation matrix → `t_skill_intercorr.csv` |
| `04_h1_gelbach.R` | per-system Gelbach → `h1_gelbach_long{TSUF}.csv` |
| `07_robustness.R` | modal-grade and IPW Gelbach → `rob_gelbach_table{TSUF}.csv` |
| `09_causal_mediation.R` | `mediate` per system/mediator → `h1_mediation_pkg{TSUF}.csv`; env `MED_FAST`, `MED_CORES`, `MED_ONLY`, `MED_POOLED` |
| `09b_joint_rho.R` | closed-form ρ* for joint block → `h1_joint_rho{TSUF}.csv` |
| `11_figures_paper.R` | fig1–fig5: system-level points + median diamond |
| `12_paper_tables.R` | `med()`, `eq()`, `tbl_*` builders (pipe tables) used by the .qmd |
| `run_all_estimation.sh` | make-like driver: timestamp check `needs_run()`, loops TREATS × DOMAINS; reading/pct at full settings, others `MED_FAST=1`; DEP reading only; `FORCE=1` to override |
| `10_random_slopes.R` | **legacy** (dropped RQ); outputs kept under `old_pooled_rs/` |

Scripts detect the repo layout via `REPO <- dir.exists("03_outputs")`. Full estimation chain ≈ 3.5–4 h on 2 cores; reading within-school full run ≈ 70 min; FAST runs 10–15 min each. The .qmd reads CSVs only.

## 7. Technical problems and fixes (so they are not repeated)

- `mediation` not on the available CRAN mirror → installed from GitHub source (4.5.1). Closed-form LSEM equals `mediate()` for linear models (verified).
- Quarto re-parses any LaTeX table carrying a `tbl-` label and drops kableExtra styling → all tables are `kable(format = "pipe")`, wide ones inside `::: {.landscape}` divs, sizing through etoolbox hooks in the preamble (`\AtBeginEnvironment{tabular}{\footnotesize}`, `\AtBeginEnvironment{longtable}{\footnotesize\renewcommand{\arraystretch}{0.9}}`), `tbl-colwidths` where needed.
- Unicode ρ*, R̃² mangled under POSIX locale and missing Greek glyphs in Latin Modern → `Sys.setlocale("LC_CTYPE","C.UTF-8")` in the setup chunk; `mainfont: Linux Libertine O`. LaTeX math inside a double-quoted YAML `tbl-cap` loses its backslashes → use Unicode there.
- Inline helper `mv()` returned the wrong row because data.table resolved `unit` / `mediator` as column names → all inline helpers coerce with `as.data.frame`. Similar shadowing bugs: `base` → `b_mean`, `spec` → `sp_lab`, empty column name in `tbl_corr` → "Variable".
- Probit mediator for the binary GROWTH inflated `mediate()` intervals ~4× → LPM (see Stage 6).
- `fielded_items` computed over all students gave Armenia 0 deprivation items → denominator restricted to students who answered any deprivation item.
- `tar` "file changed as we read it" while estimation was writing → retry after sleep. Killing R workers with `pkill -f` and bracket patterns to avoid killing the calling shell.
- An unverified magnitude claim ("of the order of a year of schooling") was removed from the text.
- Repo transfer: bundles copied through the device bridge and unpacked; the transfer folders `_to_delete_paperA_repo3/` (v1–v4) at the repo root could not be deleted by the assistant and are for the author to delete.

## 8. Headline results (reading, ESCS percentile rank, medians across 19 systems)

- **Within-school gradient:** 3.0 points per 10 percentile points [IQR 2.2–3.9] ≈ 27 points P10→P90. Joint ACME 0.62 points → **17.3 % mediated [14.0–26.1]**; 5.6 points of the P10→P90 gap; significant in 16/19 systems (not Hong Kong, Armenia, Serbia).
- **Total gradient:** 7.4 points per 10 percentile points; **12.5 % mediated [8.8–16.2]**; ≈ 59 % of the total gradient lies between schools.
- **Single-mediator shares, within school:** curiosity 12.0 [8.1–17.4] (largest in 12/19; ρ* 0.20); perseverance 8.9 [3.6–13.4] (Kosovo 22, Georgia 16, Azerbaijan 14, Moldova 13; ≈ 0 in B-S-J-Z; significant 13/17); stress adaptability 6.4 [3.9–10.0]; problem-solving enjoyment 5.9 [4.4–7.9]; goal setting 5.1 [1.7–7.8]; growth mindset 4.4 [2.6–5.2] (significant 10/19; Albania 10, Kazakhstan 8, Viet Nam 6 where it is the largest pathway); self-regulated learning 1.0 [0.4–3.7] (> 5 % only in B-S-J-Z 10, Azerbaijan, Kazakhstan). Single-mediator shares overlap and do not sum to the joint block.
- **Gelbach allocation (check):** curiosity 9.9, perseverance 4.2, growth mindset 4.2, stress 2.5, self-reg 0.0, problem-solving −0.9, goal setting −1.2; sum 17.1. ρ* for the joint block 0.28.
- **Skill gradients (mediator models):** ≈ 0.03 SD per 10 percentile points for curiosity, stress adaptability, goal setting, problem-solving enjoyment; 0.01 for self-regulated learning; +1 percentage point of growth mindset. About half as steep as the achievement gradient (≈ 0.07 SD).
- **Systems, within school:** Kazakhstan 35.1, Kosovo 31.6, Georgia 30.2, Azerbaijan 29.7, Moldova 22.6, Albania 22.1, then N. Macedonia, Kyrgyzstan, Romania, Montenegro, Macao (15), B-S-J-Z, Hong Kong, Armenia, Serbia, Mongolia (12–18), Croatia 9.6, Viet Nam 7.1; Bulgaria not identified. **Total:** Kosovo 21.1, Kazakhstan 18.7, Georgia 18.6, Azerbaijan 17.5 … Croatia 7, Hong Kong 6.4, Mongolia 5.8. Spearman within↔total 0.91. Ranking does not sort by region; the three Chinese systems do not behave as a group.
- **Domains:** mathematics 15.0 % [10.7–23.9] within / 10.6 [9.0–13.0] total; science (20 systems) 16.0 [12.7–27.9] / 12.2 [9.5–15.8]. Spearman reading↔maths 0.76, reading↔science 0.86. Curiosity largest in 12/12/13 systems (medians 12.0 / 8.5 / 10.3 %). Uzbekistan's flat total gradient (≈ 7 points) inflates its science share.
- **ESCS in index units (appendix):** 19.0 % within school.
- **Deprivation (second exposure):** −8.2 reading points per unaffordable item at given ESCS [5.6–11.8]; **18.4 % mediated [12.0–24.5]**; composition differs from ESCS: perseverance 8.8 > curiosity 5.4 > growth mindset 5.0.
- **Robustness (percentile rank):** 17.1 % (modal grade), 16.1 % (IPW), 16.7 % baseline Gelbach.
- **Correlations (within-system z):** curiosity–problem-solving 0.53; perseverance–curiosity 0.49; growth mindset × scales 0.01–0.13; curiosity–reading 0.23, perseverance 0.16, growth 0.15; ESCS × dispositions 0.04–0.13; ESCS–reading 0.30.
- **Sensitivity:** ρ* curiosity from 0.05 (B-S-J-Z) and 0.10 (Mongolia) to 0.30 (Bulgaria), most 0.15–0.25; joint block 0.28. Prior achievement could plausibly reach 0.2, so mediated shares are read as upper bounds; composition and ranking of systems are not affected by a common confounder.

## 9. Manuscript structure (paperA.qmd)

Introduction · Data and measures (exposure = percentile rank + deprivation; skills rescaled to sample; growth mindset) · Empirical strategy (causal mediation as estimates of record; joint block; Gelbach as composition check with the collinearity argument; Mundlak paragraph = within-school estimator; medians/IQR) · Results: the socio-economic gradient of skills; RQ1 how much is mediated; RQ2 which pathways; RQ3 where (system ranking); domains; a second exposure — material deprivation (`tbl-exposures`, `tbl-econ-dep`); sensitivity and robustness · Discussion · Appendix (ESCS-unit table `tbl-main-escs`, per-system tables, correlation matrix). References include Imai–Keele–Tingley, Gelbach 2016, Mundlak 1978, Dweck 2006, Claro et al. 2016.

## 10. Open items and ideas not pursued

- Author to delete `_to_delete_paperA_repo3/` at the repo root.
- Possible extension to all non-OECD systems (needs re-extraction of the PUF on the Mac).
- School fixed effects / lmer as a further check on the Mundlak specification.
- Wording of "collinearity" could be softened to "suppression".
- References should be checked before submission.
- Papers B (fuzzy RD at school-entry cutoff), C (school SEL policy), D (reported vs revealed perseverance from LDW) remain as proposed, untouched.

---

# Appendix A — Data audit and proposal note (25 Sept, morning; verbatim)

# PISA 2025 — data audit and research-proposal summary (2026-09-25)

Full proposal (living doc): https://claude.ai/code/artifact/881e6323-fe6b-45e2-a8e2-b1a544d8ce39

## Repo
`~/Documents/GitHub/PISA2025` — `00_documentation/` (PISA2025_Codebook.xlsx, questionnaires, compendia), `01_data/` (CY09_MS_STU_PUF.sav 755,721 × 885; SCH_PUF; LDW_20260806 721,037 rows of item-level process data; TCH_PUF; STU_TT_PUF), `02_scripts/` (codebook_inventory/ = name+label per file, extracted today), `03_outputs/`, `04_manuscripts/`.

## Key data facts
- 91 economies; **no Russia**; Ukraine (QUA) excluded by choice. Dushanbe (QTJ) and Cambodia (KHM) lack the skill scales.
- SE-skill WLE scales (SSES mapping): PERSEV (task performance; missing in KAZ, IDN, ALB), SELFREG, GOALSET (self-regulation), CURIO, ENPROBS (open-mindedness), COGABIL (stress adaptability). No engaging-with-others / collaboration scales. Mindsets: ST420Q01/02 growth mindset, ST493Q01 status fatalism. Teacher perseverance messaging: ST469Q08DA.
- New child material-deprivation module: ST488Q01/02/08/09, ST401Q03–07 (ST401 not fielded in MNG, MKD, ARM, BGR, KSV).
- School SEL policy items: SC189Q01JA (39–89% of schools say yes within our economies), SC189Q05/06, SC194Q01DA, SC197, SESASSESS; SC266Q05DA priority on managing negative emotions.
- Outcomes: PV1–10 SCIE/MATH/READ, LDW PVxCMPS (problem solving) and PVxCPPK (prior knowledge).
- Macao has no CNTSCHID/STRATUM in the PUF. Armenia ~60% item non-response on skills; BGR/KSV/MKD/GEO/SRB 22–32%, selective (non-respondents 40–65 science points lower).
- Birth-month → grade cutoffs are near-deterministic in QCI, TAP, GEO, SRB (fuzzy RD feasible); softer in HKG, AZE, ALB, PHL, IDN.
- Skill–ESCS correlations weak everywhere (0.05–0.20); CURIO–science 0.13–0.41; PERSEV–science 0 (QCI, TAP) to 0.29 (KSV).

## Proposed sample (three blocs, ~175k students)
East Asia: QCI, HKG, MAC, VNM, MNG (+TAP optional). Post-Soviet: KAZ, UZB, KGZ, GEO, AZE, MDA, ARM. Post-communist non-OECD: SRB, BGR, ROU, HRV, ALB, MKD, MNE, KSV. Optional comparator: post-communist OECD-8.

## Strategies and papers
6.1 Gelbach decomposition of ESCS gradient (mediation) · 6.2 varying slopes by SES/deprivation (compensation) · 6.3 skill × grade value-added · 6.4 fuzzy RD at school-entry cutoff (does schooling produce skills) · 6.5 school SEL policy / leave-one-out teacher messaging as treatment/IV with placebo tests · 6.6 revealed persistence from LDW process data · 6.7 bloc-level institutional moderation.
Papers: A (mediation vs moderation across blocs), B (RD: schooling → skills), C (school SEL policy), D (reported vs revealed perseverance).

## Open decisions
Bloc definition (TAP, OECD-8?), science-only vs composite outcome, which paper first, drafting language.

## Tooling note
On the Mac VM, `pyreadstat` reads a 70-column subset of the full student file in ~21 s; pandas/openpyxl installed with pip --user.

*(Note on scale labels: the audit note's mapping of ENPROBS/COGABIL was later corrected — in the final paper ENPROBS = stress adaptability and COGABIL = problem-solving enjoyment.)*

---

# Appendix B — Domain comparison and revised SES contrast (25 Sept, evening; verbatim; pooled/bloc stage, later superseded)

# Paper A — outcome-domain comparison and revised SES contrast (2026-09-25, evening)

Standing rules from the author: manuscripts always in Quarto (.qmd), R code in separately numbered scripts; reading and/or maths as primary outcomes, science in appendix; SES contrast = top 10% vs bottom 10% (4 groups: B10 / 10–40 / 40–90 / T10) plus continuous skill × ESCS interaction.

Pipeline now parameterised by `PISA_DOMAIN` (READ | MATH | SCIE); outputs in `outputs/<DOMAIN>/`. Uzbekistan has no reading/maths PVs in the PUF → 19 economies for READ/MATH (N = 108,647), 20 for SCIE.

## Mediation share (Gelbach, total gradient), pooled / EA / PS / PCE
- Reading: 8.1% / 4.9 / 10.8 / 9.1 (curiosity 6.6 of 8.1)
- Maths: 6.5% / 5.4 / 9.2 / 6.6 (curiosity 4.5)
- Science: 7.9% / 5.7 / 11.8 / 8.0 (curiosity 5.8)
- Reading per economy up to 15–19% (KAZ 15.0, GEO 15.8, KSV 18.7, MAC 13.9, AZE 13.8, BGR 12.9). Between-school sorting accounts for ~60% of the total gradient (24.5 → 9.8 within-school), so skills ≈ 8% vs school composition ≈ 60% is the natural benchmark.

## Returns B10 vs T10 (reading, pooled): curiosity 13.9 vs 14.3; self-reg 3.6 vs 1.9; goal setting −2.6 vs −1.3; stress adaptability 0.3 vs 3.4 (diff −3.1, SE 1.4). Continuous skill × ESCS_zw interactions all within ±1 point. Goal setting compensatory in post-Soviet (B10−T10 = +5.4 reading, +7.7 maths). Slopes parallel otherwise; 2–4 significant differences out of 112 per domain.

## Bloc contrasts sharper in reading: perseverance PS−EA +8.0 (1.1), PCE−EA +5.2 (0.8); self-reg PS−EA −4.1, PCE−EA −6.0; curiosity PCE−EA +6.4 (0.9). Maths: perseverance PS−EA +9.6, self-reg PCE−EA −8.8.

## Deprivation penalty at fixed ESCS: reading −27.0 (skills absorb 10%), maths −22.8 (10%).
## H3 (restricted): reading pooled curiosity × grade 2.2 (1.3), problem-solving enjoyment 3.2 (1.3); East Asia grade = 19 (reading), 25 (maths). Still no strong rate effect.

---

# Appendix C — Causal mediation (Imai) and random slopes (25 Sept, late; verbatim; pooled stage, later superseded)

# Paper A — causal mediation (Imai) and random-slopes results, reading (2026-09-25, late)

Scripts: `09_causal_mediation.R` (LSEM closed form of Imai–Keele–Tingley: ACME = alpha1*beta2, ADE, proportion mediated, sensitivity rho* at which ACME = 0 = observed residual correlation, R² product; single-mediator per skill + joint block), `10_random_slopes.R` (lme4: school random intercept + uncorrelated random slopes of 5 skills at economy level AND economy × ESCS-group level; senate weights scaled to mean 1; 10 PVs; ~50 min). `mediation` package not installable here (CRAN blocked) — closed form implemented by hand and equals what `mediate()` returns for linear models.

## Causal mediation, reading, total gradient (19 economies, pooled)
- Total effect of ESCS: 22.7 points/unit. Joint ACME (six skills): 1.85 (SE 0.14) = 8.1% (identical to Gelbach, as expected). For the B10→T10 ESCS contrast (2.9 units): 5.4 points of a 66-point total effect.
- Single-mediator ACMEs: curiosity 1.54 (6.8%), stress adaptability 0.73 (3.2%), problem-solving enjoyment 0.71 (3.1%), goal setting 0.67 (3.0%), self-reg 0.26 (1.1%). They sum to 17% because skills are correlated — the joint block is the honest total.
- Sensitivity: curiosity ACME vanishes if corr(e_M, e_Y) = 0.19 (R² product 0.022); joint 0.20. Per economy rho* 0.08 (QCI) to 0.28 (Bulgaria, Kosovo). Moderate robustness — an unobserved confounder (prior achievement) explaining 2% of residual variance in both equations would kill it.
- Within-school (school controls): joint 16.9% of 8.6 points; curiosity 13.9%.
- Blocs: joint prop mediated EA 4.9%, PS 10.8%, PCE 9.1%.

## Random slopes, reading, pooled (5 skills; PERSEV excluded because KAZ/ALB)
- Fixed slopes: curiosity 11.7, self-reg 2.4, stress adaptability 2.5, goal setting −0.5, problem-solving enjoyment −0.6.
- LRT random slopes vs school-intercept-only: chi² = 672, df 10, p ≈ 0.
- Variance decomposition of slopes (SD): curiosity 3.8 across economies vs 1.5 across ESCS groups within economy; self-reg 2.4 vs 1.0; ENPROBS 2.2 vs 1.0; COGABIL 1.3 vs 0.7; goal setting 2.8 vs 2.5 (the one skill whose return varies by class as much as by system).
- Shrunken group returns (bloc means B10 / T10): EA curiosity 8.1 / 8.0, self-reg 5.3 / 5.0; PS curiosity 13.7 / 13.5; PCE curiosity 12.4 / 13.0. Goal setting: PS 0.5 / −1.5, PCE 0.3 / −0.3, EA −2.5 / −3.0. No economy shows a significant B10−T10 difference for any skill.
- Reading of the result: heterogeneity in returns is institutional (between systems), not class-based (within systems). Compensation appears only for goal setting and is small.

---

# Appendix D — Per-economy random slopes by ESCS decile (26 Sept; verbatim; RQ subsequently dropped)

# Paper A — per-economy random-slopes models by ESCS decile, reading (2026-09-26)

Script `10_random_slopes.R` now fits, separately for each of the 19 economies: reading ~ ESCS + controls + school controls + all fielded skills + (1|school) + (0 + skills || ESCS decile). Weighted ESCS deciles within economy (`escs_dec` in 02_prepare). 10 PVs, Rubin. Macao without school intercept. Old pooled version kept in `outputs/READ/old_pooled_rs/`.

Results
- Random-slope SD across deciles: mostly 0–2 points per SD of skill; LRT for random slopes significant (p<0.05) in only 4 of 19 economies (Croatia, Kazakhstan, Kyrgyzstan, B-S-J-Z), borderline in Albania and Moldova.
- Decile 1 vs decile 10 shrunken returns: 0 of 112 economy × skill differences significant; linear trends over deciles average ≈ 0 for every skill (sign split roughly half/half).
- Bloc-mean decile profiles are flat: EA curiosity 8.5 → 7.5 across deciles; PS curiosity 11.6 → 11.8; PCE 11.3 → 12.5; PS perseverance 7.6 → 5.9 (mild decline, poorest gain a little more); PS goal setting −1.2 → −3.4.
- Conclusion for the paper: returns to skills do not vary with SES within any system; the heterogeneity in returns is between systems (perseverance PS ≈ 6, PCE ≈ 4, EA ≈ 0; self-regulated learning EA ≈ 5.5, elsewhere ≈ 0–2; curiosity 8 in EA vs 11–12 elsewhere).
- Decision pending: drop returns-by-SES as an RQ; keep one paragraph + appendix table; paper = RQ1 mediation (Gelbach + Imai) and RQ2 institutional heterogeneity.

*(Resolved afterwards: the RQ was dropped entirely, not kept as an appendix.)*
