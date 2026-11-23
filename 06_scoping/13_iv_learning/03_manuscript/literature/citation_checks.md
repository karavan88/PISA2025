# Citation checks owed for section 2

Written on 23 November 2026 with the first draft of "Background and research questions" (`../iv_learning_paper.qmd`). The draft cites 47
references. For 25 of them the abstract was read in this session and the sentence follows the abstract. For the 22 below, the reference was
confirmed to exist, but what the sentence says about it is recalled from prior knowledge. Each has to be checked in the full text before
submission. No full text was opened for any reference.

| Key | What the draft says | Check |
|---|---|---|
| `feinstein2003` | Differences by family background are visible in the second year of life | The age (22 months) and that the measure is cognitive development |
| `cunha2007` | Skills acquired early raise the return to later learning; early advantage compounds | Wording of dynamic complementarity |
| `bloom2008`, `hill2008` | What students learn in a year is a yardstick for gaps | That both propose annual gains as benchmarks for gaps, not only for intervention effects |
| `avvisati2023` | "See also" for the yearly gain | Which design the article uses and its estimate; whether it should replace the working paper as the main citation |
| `downey2016` | Schools came to be seen as neutral or compensatory with respect to class | The abstract was read only up to the point where it names the framework; the sentence on class is recalled |
| `vonhippel2019` | The direction of change depends on how the tests are scaled | The exact claim about scaling |
| `vanewijk2010` | School SES is strongly associated with achievement | "Strongly": the meta-analysis may report a moderate effect that depends on the measure |
| `raudenbush1995` | A school's contribution has to be separated from its level | That this is their distinction |
| `marks2015` | Others regard composition effects as statistical artefacts | Conclusion taken from the title |
| `deming2014`, `angrist2017` | Test estimates of school value added against admission lotteries | What each concludes about bias; the draft does not state a conclusion |
| `stanovich1986` | Early advantage compounds in reading | Standard reading; confirm |
| `abadie2002`, `chernozhukov2005` | Methods for effects along the distribution of an outcome with a non-random treatment | Standard; confirm the pairing |
| `heckman2006b`, `almlund2011`, `kautz2014` | Skills predict schooling and later outcomes beyond test scores | Standard; confirm that perseverance and curiosity are among the skills each covers |
| `jackson2018`, `jackson2020` | Teachers and schools affect outcomes that tests miss | Standard; confirm |
| `oecd2021` | 15-year-olds report lower skills than 10-year-olds | The report and the skills it holds for |
| `soto2011` | Cited with the same sentence | That it shows lower self-reports in adolescence; it is a cross-section of ages 10 to 65, not a comparison of 10 and 15 |

Numbers taken from abstracts, also to be confirmed in the full text: `passaretta2022` (50 to 80%), `avvisati2021a` (one-fifth of a
standard deviation, 18 systems), `passaretta2025` (about half), `gruijters2024` (74 countries), `pfost2014` (25 years), `downey2008`
(fewer than half of the bottom fifth), `skopek2021` (up to age 16).

Two sentences describe studies by where they were done; confirm the grades: `skopek2024` (grades 5 and 6), `jensen2026` (narrowing in
grade 2; the abstract read is that of the 2023 preprint), `jensen2025` (TIMSS covers grades 4 and 8; the abstract does not name them).

## Checks owed for sections 3 and 4 (drafted 23 November 2026)

Facts about the data come from the files and the project's saved results and are recorded in `../../README.md`. The following rest on
recall or on a source not yet read:

| Item | What the draft says | Check |
|---|---|---|
| PISA target population | Students between 15 years 3 months and 16 years 2 months, in grade 7 or above | The PISA 2025 technical documentation; no reference for it is in the bibliography |
| `oecd2025` | Cited for the student file | Publication year and the OECD's own citation wording |
| ESCS | Combines parental education, parental occupation and home possessions | The 2025 definition |
| Replicate weights | 80 replicate weights; the variance formula is in the code (Fay, factor 0.5) but not stated in the text | Confirm the factor for 2025 and decide whether to state it |
| "the upper grade is the first year of upper secondary school" (15 systems) | From the programme variable in the file | Wording: in some of the 15 the boundary may fall one grade earlier or later than the upper of the two main grades |
| `cahan1989`, `angrist1991`, `cascio2006`, `luyten2006` | Studies that separate schooling from age with birth dates and entry rules | Recalled; confirm each fits the description |
| `imbens1994` | Effect for students whose grade the cutoff decides | Standard; confirm |
| `bedard2006`, `black2011`, `crawford2014` | Entering school younger affects students | Recalled; confirm each studies entry or relative age |
| `avvisati2021a` | Estimates the quantity we call the yearly gain | The abstract says "the joint effect of schooling and age"; confirm in the full text that it is the same quantity |
| `rubin1987`, `dersimonian1986` | Variance between plausible values; random-effects mean | Standard |
| `chernozhukov2005`, `chernozhukov2006` | Instrumental-variable quantile regression; the estimator used is inverse quantile regression solved by bisection | Confirm the description of the estimator against the 2006 article |
| `buckles2013` | Birth month is related to family background in some countries | Recalled; the study is on the United States, so "in some countries" may be too broad |
| `west2016` | Students rate their skills against the peers around them | Abstract read; it says reference bias is suggestive |

## Checks owed for section 5, results (drafted 23 November 2026; numbers scripted the same day)

No number in sections 3 to 5 is typed. `01_code/19_text_numbers.R` reads the saved estimates and writes
`04_output/tables/numbers.yml`, and the text quotes it with `{{< meta n.key >}}`; tables and figures are included from
`04_output/`. The three numbers that had been computed by hand (the within-system standard deviation of achievement, the mean
achievement percentile of the low and the high third, and the composition of the two school types) now come from step 6b
(`06b_scale.R`) and the saved output of step 12. Statements made in words (which system is the exception, what is significant,
"about a sixth") are listed as claims in the same script, which stops when a new run no longer supports one; the list with its
verdicts is `04_output/tables/text_claims.csv`.

Scripting the numbers corrected four statements of the first draft: the skill scales are missing in more systems than it said
(Mauritius lacks four, the United States two); the comparison of the gradient with skills held fixed rests on the systems with
estimates at both ends, not on all systems with the index; the inner contrast along the distribution is not estimated in every
system; and the linear school-SES estimate holds the student's own status fixed.

| Item | What the draft says | Check |
|---|---|---|
| PISA target population | Students between 15 years 3 months and 16 years 2 months, in grade 7 or above | The PISA 2025 technical documentation; no reference for it is in the bibliography |
| `oecd2025` | Cited for the student file | Publication year and the OECD's own citation wording |
| ESCS | Combines parental education, parental occupation and home possessions | The 2025 definition |
| Replicate weights | 80 replicate weights; the variance formula is in the code (Fay, factor 0.5) but not stated in the text | Confirm the factor for 2025 and decide whether to state it |
| "the upper grade is the first year of upper secondary school" (15 systems) | From the programme variable in the file | Wording: in some of the 15 the boundary may fall one grade earlier or later than the upper of the two main grades |
| `cahan1989`, `angrist1991`, `cascio2006`, `luyten2006` | Studies that separate schooling from age with birth dates and entry rules | Recalled; confirm each fits the description |
| `imbens1994` | Effect for students whose grade the cutoff decides | Standard; confirm |
| `bedard2006`, `black2011`, `crawford2014` | Entering school younger affects students | Recalled; confirm each studies entry or relative age |
| `avvisati2021a` | Estimates the quantity we call the yearly gain | The abstract says "the joint effect of schooling and age"; confirm in the full text that it is the same quantity |
| `rubin1987`, `dersimonian1986` | Variance between plausible values; random-effects mean | Standard |
| `chernozhukov2005`, `chernozhukov2006` | Instrumental-variable quantile regression; the estimator used is inverse quantile regression solved by bisection | Confirm the description of the estimator against the 2006 article |
| `buckles2013` | Birth month is related to family background in some countries | Recalled; the study is on the United States, so "in some countries" may be too broad |
| `west2016` | Students rate their skills against the peers around them | Abstract read; it says reference bias is suggestive |

## Checks owed for section 5, results (drafted 23 November 2026)

Every number in the section was copied from the saved estimates and compared with the tables built by `01_code/18_tables.R`; the tables
and figures in the manuscript are included from `04_output/`, not typed. Three numbers were computed for the text and are not in a saved
output: the average within-system standard deviation of achievement (86 points, first plausible value), the average achievement
percentile of the low and the high SES third (40 and 61), and the shares of low-third and high-third students in the two school types
(printed in the log of step 12). They should be moved into a script before submission.

| Item | What the draft says | Check |
|---|---|---|
| `avvisati2021a` | The yearly gain "matches" their estimate | Their one-fifth of a standard deviation is from the abstract; confirm the standard deviation they use and the rounds they cover |
| `athey2019`, `yadlowsky2025` | Instrumental forest; rank-weighted average treatment effect | Standard for the method used (`grf` 2.6.1); confirm the citation the package asks for |
| Kenya and Cambodia | "where the index is hardly related to achievement" | This restates their small gaps; no separate check of the index was run |

## Changes made by hand to `references.bib` after it was built from Crossref

- Surnames with a particle are braced so that they print in full: von Hippel, van Ewijk, van Huizen, ter Weel.
- "Mcconney" (as deposited for `perry2010`) is corrected to "McConney", the spelling in `sciffer2022`.
- Paul von Hippel's given name is written "Paul T." in all four entries; Crossref has "Paul" for `vonhippel2019`.
- Authors were added to `avvisati2021a`, `avvisati2021b` and `kautz2014`, which Crossref lists without authors.

The manuscript renders with Quarto's default author–date style. APA 7 needs a style file (`apa.csl`), which is not in the repository.
