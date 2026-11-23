# Manuscript outline

Written on 23 November 2026 and approved by the author the same day, with five research questions. Structure of the author's
Industrial Relations paper. Research questions only. Drafted so far in `iv_learning_paper.qmd`: background and research questions, data, empirical approach, results.
Results are those recorded in `../README.md`; background sources are in `literature/`. The title is the author's to set.

## Overview

| Section | Words | Purpose |
|---|---|---|
| 1. Introduction | 900 | The puzzle, the design in one paragraph, the findings, the contribution |
| 2. Background and research questions | 1,300 | Five modules, five questions (`literature/review_structure.md`) |
| 3. Data | 900 | PISA 2025, entry rules, samples, measures |
| 4. Empirical approach | 1,400 | Identification, estimands, estimators, threats |
| 5. Results | 3,200 | One subsection per question, then robustness |
| 6. Discussion | 1,000 | Reading, implications, limitations |
| 7. Conclusion | 300 | What the paper establishes |
| Total | 9,000 | Until a journal is chosen |

## Detailed outline

### 1. Introduction (900)

| Paragraph | Claim | Evidence |
|---|---|---|
| 1 | Children from poorer families are behind at 15 everywhere; whether school narrows, preserves or widens that gap is still argued. | Module 2 |
| 2 | Most evidence is from the first grades of single countries; little is known for adolescents across systems. | Modules 1 and 2 |
| 3 | The design: PISA samples one birth cohort; where an entry cutoff falls inside it, children a month apart sit a grade apart. | Section 4 |
| 4 | Findings, one sentence each, in the order of the questions. | Section 5 |
| 5 | Contribution against the closest studies: the yearly gain was known on average; this paper asks who gains. | `evidence_table.md`, last table |
| 6 | Road map. | |

### 2. Background and research questions (1,300)

As in `literature/review_structure.md`, section 3: five subsections, each closing with its question.

### 3. Data (900)

| Subsection | Content | Exhibit |
|---|---|---|
| 3.1 PISA 2025 | Sample, plausible values, replicate weights | |
| 3.2 Entry rules and cutoffs | Official rules from UIS; cutoff month from grades by birth month; the eligibility rule | Table 1: systems, cutoff, first stage, sample |
| 3.3 Samples | 34 systems; 33 with socio-economic status; schools holding both grades; systems with skills | Table 1 |
| 3.4 Measures | Achievement, socio-economic status, school intake, skill scales and the index | Appendix table |

### 4. Empirical approach (1,400)

| Subsection | Content |
|---|---|
| 4.1 Identification | Born before the cutoff as an instrument for grade; birth month as control |
| 4.2 Estimands | The yearly gain and its split into schooling at a given age and age; what the instrument bundles |
| 4.3 Estimation | Per system, replicate weights and plausible values, random-effects summaries; interactions; quantile version; school spread with a permutation reference |
| 4.4 Methodological threats | Repetition; cutoff read from the same cohort; season of birth; new intakes in the upper grade; self-reported skills |

### 5. Results (3,200)

| Subsection | Question | Claim | Evidence in the project | Exhibit |
|---|---|---|---|---|
| 5.1 The gap in years of learning | 1 | The gap between the high and the low third equals 3.6 school years, from under 1 to 6 across systems. | Step 6 | Figure 1 (built) |
| 5.2 A year adds the same | 2 | The gain does not differ by family background; bound of about a tenth of the gap. | Steps 4, 5 | Figure 2 (built); Table 2 |
| 5.3 Schools | 3 | Schools differ by 12 to 15 points in what a year adds; whether disadvantaged schools add less is open. | Steps 8, 10, 11, 12 | Figure 3 (to build); Table 3 |
| 5.4 Along the distribution | 4 | A year adds about twice as much at the 90th percentile as at the 10th. | Step 9 | Figure 4 (to build) |
| 5.5 Skills | 5 | A year adds far more knowledge than skills; skills account for about a sixth of the gradient and do not offset background. | Steps 13, 14, 15 | Table 4 |
| 5.6 Robustness | all | Repeaters; years in school; strong first stage; pooled design and drifting systems; forest; sex. | Steps 1, 2, 3, 5, 16, 17 | Appendix tables |

### 6. Discussion (1,000)

| Subsection | Content |
|---|---|
| 6.1 Findings and interpretation | A gap of levels carried forward; unequal gains follow prior achievement and the school, not family background |
| 6.2 Implications | What an ordinary school year can and cannot do for the gap; where differences between schools sit |
| 6.3 Limitations | One cohort and one grade boundary; the bundle; moderate evidence for questions 3 and 4; self-reported skills; search not exhaustive |

### 7. Conclusion (300)

## Exhibits

All are built from saved estimates by `01_code/07_figures.R` and `01_code/18_tables.R`, which fit nothing. Figures are in
`04_output/figures/` (PDF and PNG), tables in `04_output/tables/` (LaTeX with booktabs, and CSV); both folders are Git-ignored.
Since 23 November 2026 the paper has 34 systems, every number in the text comes from `04_output/tables/numbers.yml`
(`01_code/19_text_numbers.R`), and captions carry the reading notes. The exhibits of the 35-system draft are kept in
`04_output/superseded_20261123_exhibits_with_israel/`.

| Exhibit | File | State |
|---|---|---|
| Figure 1: the gap in school years, every system | `fig1_gap_years` | Built |
| Figure 2: yearly gain, high against low third, every system | `fig2_equal_gain` | Built |
| Figure 3: between-school spread of the gain, every system; same-level systems in colour, the others in grey | `fig3_school_spread` | Built |
| Figure 4: mean yearly gain by percentile; with skills held fixed | `fig4_gain_by_percentile` | Built |
| Figure 5: yearly gain by percentile in every system, one small panel each | `fig5_percentile_by_system` | Built (new) |
| Figure 6: yearly change in each skill and in achievement, every system | `fig6_skills` | Built (new) |
| Table 1: systems, cutoff, first stage, samples | `table1.tex` | Built, 34 rows |
| Table 2: gain by family background, all specifications | `table2.tex` | Built |
| Table 3: schools: spread, checks, school types | `table3.tex` | Built, four panels |
| Table 4: skills as outcomes and as moderators | `table4.tex` | Built |
| Table 5: skills, family background and the gradient | `table5.tex` | Built |

## Open before drafting

1. Target journal, which sets the length and the citation style.
2. Whether the unsettled school-type comparison and the forest go in the main text or the appendix.
