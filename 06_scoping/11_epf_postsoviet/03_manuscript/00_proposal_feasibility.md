# EPF in post-Soviet systems (PISA 2025) — feasibility and design

As of 2026-09-30 · Garen Avanesian. Living doc: https://claude.ai/code/artifact/ac9afe71-2988-4ae7-8860-8b4956b842c0
Audit script: `02_scripts/epf_postsoviet/00_feasibility_audit.py` → `03_outputs/epf_postsoviet/audit_*.csv` (PV1 only).

## Bottom line

Feasible for seven systems (ARM, GEO, AZE, MDA, KAZ, KGZ, UZB), but the 2018 identification strategy needs one structural change. Birth-month fixed effects (the "age dummies") remove age; they do not remove selection into early/late school entry, which is what generates most within-age grade variation here. In Georgia and Azerbaijan the school-entry cutoff gives a near-experimental check: the LSDV estimate of a school year is ~20 PISA points too high (RD ≈ 0). In Kazakhstan the LSDV sign is reversed because grade 10 at 15 mixes general and vocational tracks.

Fix: learning gain of record from a fuzzy RD at the entry cutoff where the rule bites (GEO, AZE, KAZ); birth-month LSDV reported for all seven as the descriptive counterpart; the gap between them is a finding about entry-age selection. Then lqmm per system at τ = .25/.50/.75, school random intercepts, birth-month dummies, separate models by SES group, SE skills under the Big Five. Science is the only domain all seven share (Uzbekistan took science only).

Constraints: Armenia 42 % missing ESCS, 73 % missing skills (IPW subsample); Kazakhstan has no PERSEV; vocational programmes (ISCEDP 354) in KAZ/MDA/KGZ must be excluded from grade contrasts.

## Data audit (PISA 2025 PUF; all students born 2009 → age dummies = 12 birth-month indicators)

| System | Students | Schools | Modal grade | Below/modal/above % | Vocational % | ESCS miss % | Skills miss % | Language of test | Domains |
|---|---|---|---|---|---|---|---|---|---|
| Kazakhstan | 22,680 | 643 | 9 | 1/51/48 | 13 | 7 | 16 (PERSEV 100) | kaz 63, rus 36 | S M R |
| Uzbekistan | 8,652 | 233 | 9 | 2/87/11 | 0 | 10 | 18 | uzb 79, rus 15 | S only |
| Azerbaijan | 7,432 | 241 | 10 | 31/69/0 | 0 | 11 | 34 | aze 89, rus 11 | S M R |
| Georgia | 6,855 | 265 | 10 | 32/68/0 | 0 | 14 | 33 | kat 94, aze 4, rus 2 | S M R |
| Armenia | 6,804 | 293 | 10 | 10/90/0 | 0 | 42 | 73 | hye 100 | S M R |
| Kyrgyzstan | 6,645 | 195 | 9 | 4/74/22 | 2 | 13 | 30 | kir 59, rus 36, uzb 5 | S M R |
| Moldova | 6,640 | 272 | 9 | 5/82/14 | 7 | 7 | 19 | ron 81, rus 19 | S M R |

In every system the modal→next grade step is the ISCED 2→3 transition (PROGN changes). KAZ grade-10 vocational students: 391 science vs 444 (grade-10 general) vs 447 (grade 9). Skill non-response is selective (Paper A audit: non-respondents 40–65 points lower). ARM ESCS missingness is spread across schools (student-level non-completion); ARM estimation sample with ESCS ≈ 3,900.

## Identification: age dummies vs school-entry cutoff (science, general programmes, modal ± 1, PV1, weighted, school-clustered SE)

| System | LSDV grade (SE) | LSDV + ESCS (SE) | First stage (t) | Reduced form (SE) | Wald IV |
|---|---|---|---|---|---|
| Georgia | 27.1 (6.5) | 22.4 (6.1) | −0.69 (−45) | 3.7 (3.9) | −5.4 |
| Azerbaijan | 31.5 (3.7) | 21.9 (3.4) | −0.43 (−21) | 1.9 (3.9) | −4.4 |
| Kazakhstan | −13.4 (2.8) | −15.8 (2.7) | −0.26 (−13) | −4.9 (2.4) | 19.0 |
| Moldova | 64.7 (5.4) | 46.4 (4.4) | no usable cutoff | — | — |
| Uzbekistan | 11.5 (4.1) | 8.8 (4.1) | no usable cutoff | — | — |
| Armenia | 10.9 (5.4) | 7.0 (5.1) | thin support | — | — |
| Kyrgyzstan | 1.2 (3.4) | −1.4 (3.3) | no usable cutoff | — | — |

Georgia: 95 % of Jan–Aug-born in grade 10, 49 % of Sep-born, <4 % of Oct–Dec-born; mean science by birth month stays within 418–429 with no jump at the cutoff. Audit IV is crude (linear month trend, whole-year window); Georgian Wald SE ≈ 6 points, so compatible with a school year worth ≤ ~10 points, not with 22. In MDA/UZB/KGZ P(higher grade) falls smoothly Jan→Dec (parental choice of entry age, not a rule); within-month ESCS gap between grades: MDA 0.35, UZB 0.58. Consequence: LSDV grade coefficient = conditional grade–achievement association (kept for continuity and because estimable everywhere); learning gain of record and any EYOS denominator come from the cutoff design; elsewhere score points only. Test timing: spring administration, so a "grade" is ~0.6–0.8 of a school year.

## Research questions

- **RQ1** How much does one additional year of schooling add at age 15? Estimand: fuzzy RD at the entry cutoff (GEO, AZE, KAZ) + LSDV association (all). H1: cutoff estimate ≪ LSDV where early entry is selective; converge where rule-driven.
- **RQ2** Is the return to a school year and to other inputs uniform across the achievement distribution? lqmm at τ = .25/.50/.75, school random intercepts. H2a: grade association larger at .75 where between-school sorting is strong. H2b: SES and school composition matter most at .25.
- **RQ3** Do learning gains differ by family SES and school composition? Separate models within SES groups (within-system percentile rank: bottom 40 / middle 50 / top 10; decile check) and within LOO school-mean ESCS terciles. H3: steeper grade slope for advantaged students/schools.
- **RQ4** How are Big Five-organised SE skills related to achievement, across quantiles and SES groups? Sample-standardised scales + binary growth mindset; points and (where RD denominator exists) school-year equivalents. H4a: task-performance domain largest. H4b: skill associations larger at .25 and in the bottom SES group.
- **RQ5** Which school inputs matter and where in the distribution? Language of instruction (Russian-medium vs national), rural, class size, STRATIO, PROATCE, EDUSHORT/STAFFSHORT, private, SEL policy (SC189Q01). H5: shortages bite at .25; language gaps largest in Central Asia and reflect sorting.
- Descriptive: ICC per system with bootstrap CIs.

## Empirical design

- **Sample:** general programmes (ISCEDP 244/344), modal ± 1; vocational to appendix; repeaters kept with indicator in LSDV, dropped in RD; missing ESCS dropped (ARM: reported + IPW check).
- **Outcomes:** science headline (2025 major domain; only domain UZB has); maths/reading appendix for six systems; medians across domains; PISA points; standardisation (senate-weighted sample mean/SD) only for cross-scale skill comparison.
- **Inputs:** grade centred at modal; 12 birth-month dummies; sex; home vs test language; immigrant; repetition; ESCS percentile rank per 10 points (headline) + 3-group version; deprivation count where fielded (ST488; ST401 not in ARM); skills; LOO school-mean ESCS (Mundlak term — a random intercept alone assumes school effects independent of regressors); location; private; CLSIZE; STRATIO_Q; PROATCE (0–1 share); EDUSHORT; STAFFSHORT; LANGTEST_COG; SC189Q01.
- **Model 1** mean LSDV (WLS, school-clustered) + lme4 school random intercept (ICC, continuity with 2018).
- **Model 2** fuzzy RD at entry cutoff with `rdrobust` (GEO, AZE, KAZ), local linear, 2–4-month bandwidth, donut check. Precedent: Avvisati & Givord (OECD WP 2021; Labour Economics 2023).
- **Model 3** `lqmm(score ~ grade + birth-month dummies + student + household + skills + school, random = ~1 | school, tau = q, nK = 7)`; `boot.lqmm` block bootstrap by school (R = 200); Rubin across PVs. Quantile RD (reduced-form quantile regressions on the cutoff indicator ÷ first stage) as extension.
- **Model 4** Models 1 and 3 re-fitted within SES groups and school-composition terciles; no interactions; bootstrap tests of differences.
- **Inference:** 10 PVs; final student weights in Models 1, 2, descriptives; verify whether `lqmm` `weights` accepts student-level weights before the first run. Scripts estimate once → CSV; Quarto manuscript reads CSVs only.

## SE skills — Big Five mapping (only 3 of 5 SSES domains in the PUF; no engaging-with-others or collaboration)

| Domain | Scale | Items | 2018 counterpart | Availability |
|---|---|---|---|---|
| Conscientiousness / task performance | PERSEV | keeps working, extra effort, does not give up | WORKMAST | missing in KAZ |
| Conscientiousness / task performance | SELFREG | self-regulated learning | — | all |
| Conscientiousness / achievement motivation | GOALSET | sets goals, plans study | WORKMAST (partly) | all |
| Openness / open-mindedness | CURIO | curious, likes learning new things | — | all |
| Openness / creativity | ENPROBS | enjoys solving problems | — | all |
| Emotional stability + openness (compound) | COGABIL | adapts under stress, to new cultures | ADAPTIVITY | all |
| Belief (not a trait) | ST420Q01 growth mindset | intelligence fixed (reverse, binary) | ST184Q01 | all |

Decisions: domain-level scores in main text (task performance = mean of available scales; open-mindedness = CURIO, ENPROBS; adaptability; growth mindset), six scales in appendix; sample standardisation, growth mindset binary; core EPF (RQ1–3, 5) on full ESCS sample, skills models (RQ4) on respondent subsample with IPW; correlation matrix of dispositions × ESCS × achievement required.

## Contribution

1. First EPF estimates for the post-Soviet PISA 2025 participants as a set (shared Soviet origin, divergent entry ages, 12-year transitions, Russian-medium tracks — visible in the grade-by-birth-month patterns).
2. Age-dummy value-added design benchmarked against the cutoff design inside the same data: LSDV overstates by ~20 points where entry is selective and can be wrong-signed under tracking.
3. Distributional production function (lqmm) — whether a school year, SES, composition and skills pay off at the same point of the distribution; .25 speaks to SDG 4.1.1.
4. Non-cognitive block moves from one motivation index to a Big Five-organised set with explicit omissions; complements Paper A (mediation) with "are returns larger where achievement is low?".
Framing: learning-crisis question ("how much a school year buys, and for whom"), not productivity ranking. Targets: IJED, Education Economics; EAP fallback.

## Enhancements, ranked

1. Cutoff RD as learning gain of record (GEO, AZE, KAZ).
2. Restrict grade contrast to general programmes, modal ± 1.
3. Language of instruction as a school input (rus-medium: KAZ 36 %, KGZ 36 %, MDA 19 %, UZB 15 %).
4. Quantile versions of the group heterogeneity.
5. School SEL policy (SC189Q01, SC194) as a school input.
6. Distributional RD for the three RD systems (if mean RD precise).
7. School fixed-effects Model 1; ICC on common sample.
8. Optional Baltic comparator (EST, LVA, LTU) in an appendix only.
Not recommended: EYOS as primary unit; bloc aggregation; LDW process data (Paper D); Dushanbe.

## Risks and decisions needed

Risks: Armenia may not support a credible model (10 % grade variation, 42 % ESCS, 73 % skills missing); Kazakh reversal needs an institutional explanation (12-year transition, 2019–21 entry-age changes) before its RD is trusted; lqmm convergence/time with ~30 FE columns and 250 clusters (test on Georgia first); Georgian RD may show a school year ≈ 0 in science — run maths/reading RDs before framing.

- [ ] Science headline (forced by UZB), maths/reading appendix — or maths headline and drop UZB?
- [ ] Armenia: full inclusion with caveats / core models only / excluded from skills block?
- [ ] Learning gain of record: RD where available + LSDV elsewhere (proposed) or LSDV everywhere with RD as robustness?
- [ ] SES groups: 40/50/10 (2018) or top 10 vs bottom 10 (Paper A)?
- [ ] Baltic comparator appendix?
- [ ] Vocational students excluded (proposed) or kept with track indicator?
- [ ] Working title: *How much does a school year buy, and for whom? Distributional education production functions in seven post-Soviet systems (PISA 2025).*

## Work plan and compute

FAST profile (PV1, R = 50, science): ~1–2 h all systems. FULL (10 PVs point estimates, 5 PVs bootstrap, R = 200): overnight per domain (~8–12 h science), run once; spec changes force a rerun and will be flagged first.

| Step | Script | Output | Effort |
|---|---|---|---|
| Build analytic files (general-programme flag, LOO means, IPW) | `02_scripts/epf_postsoviet/01_build.py` | `01_data/derived/epf_students.csv.gz`, `epf_schools.csv` | 1 day |
| Descriptives, ICC, correlations, birth-month figures | `02_descriptives.R` | `03_outputs/epf_postsoviet/desc/` | 1 day |
| Model 1 LSDV + lmer; Model 2 rdrobust | `03_mean_models.R`, `04_rd.R` | `mean/`, `rd/` | 2 days |
| Model 3 lqmm FAST → FULL | `05_lqmm.R`, `run_all_estimation.sh` | `lqmm/{SCIE,MATH,READ}/` | 2 days + overnight |
| Model 4 separate groups | `06_heterogeneity.R` | `het/` | 1 day |
| Figures, tables | `07_figures.R`, `08_tables.R` | `figures_paper/`, `tables/` | 1 day |
| Quarto manuscript (reads CSVs) | `04_manuscripts/epf_postsoviet/paper.qmd` | pdf, docx | 3 days |

First runs after decisions: Georgia lqmm test (one τ, PV1) for convergence time and weights; maths/reading RDs for GEO and AZE.
