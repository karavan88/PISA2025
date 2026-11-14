# Search log, agent B (H2 masking; RQ2 skills as buffers or costs)

Date of all searches: 2026-11-14. Output: `B.json` (55 objects = 50 distinct sources; 27 under H2, 28 under RQ2; five sources charted under both).
Read scope: 14 objects full text (11 distinct sources), 38 abstract only, 3 record only (no finding written). Counts in the query table ("looked at", "kept") are approximate.

## How sources were read (read this before using the chart)

- OECD reports, the Guo et al. manuscript, the Agasisti working paper and the Rudolf article were read as PDF text streamed through `pdftotext`; I read selected chapters or keyword-selected passages, not every page. Flags `read_selected_chapters` / `read_selected_passages` mark this.
- Six sources were read through WebFetch, which returns a small model's extraction of the page, not the raw text: Siebecke 2023, Siebecke 2025, Suldo et al. 2015, Lee and Yoo 2015, Brody et al. 2013, Miller et al. 2015. They carry the flag `webfetch_summary`. Numbers taken from them (for example the 0.113 probit coefficient in Siebecke 2023) should be checked against the article before they are quoted in the manuscript.
- For the two Siebecke articles WebFetch covered the first 100,000 characters only (the tail, mostly references, was not read).
- Abstracts came from Europe PMC REST, OpenAlex (until its budget ran out), Semantic Scholar Graph API, PubMed E-utilities and Crossref. `url_opened` records the API call or page.
- PISA 2018 Volumes II and III and OECD Working Paper 167 were read from third-party hosted copies of the official PDFs (fne.pt, vodafone-stiftung.de) because oecd.org HTML pages returned HTTP 403 and I could not find the official PDF paths. The copies carry the OECD imprint and DOI. Page numbers are not given for these; locators are section and figure names.

## Queries

| # | Tool / database | Query (topic terms only) | Looked at | Kept |
|---|---|---|---|---|
| 1 | OpenAlex search | social and emotional skills life satisfaction adolescents OECD survey SSES | 10 | 2 |
| 2 | OpenAlex search | OECD Survey on Social and Emotional Skills well-being achievement students | 10 | 2 |
| 3 | WebSearch | OECD "Beyond Academic Learning" first results SSES life satisfaction skills socio-economic status | 10 | 1 |
| 4 | WebSearch | OECD 2024 "Social and Emotional Skills for Better Lives" SSES 2023 life satisfaction | 10 | 1 |
| 5 | OpenAlex search | Big Five personality life satisfaction adolescents meta-analysis | 6 | 0 |
| 6 | OpenAlex search | personality traits adolescents life satisfaction incremental validity middle school | 6 | 0 |
| 7 | OpenAlex search | social emotional skills SSES life satisfaction optimism 15-year-olds | 8 | 1 |
| 8 | OpenAlex search | academic achievement subjective well-being meta-analysis students | 5 | 1 |
| 9 | OpenAlex title search | six core titles (Guo; Suldo; Weber and Huebner; "did curiosity kill the cat"; "is resilience only skin deep"; "self-control forecasts better psychosocial outcomes") | 12 | 6 |
| 10 | OpenAlex title+abstract | "academic resilience" PISA disadvantaged "sense of belonging" | 3 | 1 |
| 11 | OpenAlex title+abstract | "academically resilient" students PISA "non-cognitive" | 0 | 0 |
| 12 | OpenAlex title+abstract | "resilient students" PISA "well-being" | 5 | 4 |
| 13 | OpenAlex title+abstract | "academic resilience" "life satisfaction" PISA | 0 | 0 |
| 14 | OpenAlex title+abstract | "Children's Worlds" "subjective well-being" bullying | 8 | 1 |
| 15 | OpenAlex title+abstract | "subjective well-being" children school family friends "Children's Worlds" relationships | 6 | 0 |
| 16 | OpenAlex title+abstract | PISA "life satisfaction" "sense of belonging" adolescents | 6 | 1 |
| 17 | OpenAlex title+abstract | HBSC "life satisfaction" school pressure classmate support adolescents | 0 | 0 |
| 18 | WebSearch | Guo Tang Marsh Salmela-Aro roles of social-emotional skills multi-informant | 10 | 1 |
| 19 | WebSearch | Jovanovic Brdaric 2012 "Did curiosity kill the cat" | 10 | 0 (page not reachable) |
| 20 | WebSearch | PISA 2018 Volume II academic resilience well-being resilient students life satisfaction | 10 | 1 |
| 21 | Europe PMC | six skin-deep resilience titles (Gaydosh; Chen 2015; Brody 2016; Chen 2022; Brody 2020; James 1994) | 6 | 6 |
| 22 | Europe PMC | "skin-deep resilience" (title filters), sorted by citations | 14 of 33 | 2 new |
| 23 | Europe PMC | nine titles: Hofmann; Wiese; de Ridder; Koval; Jovanovic 2014; Kashdan and Steger; Anglim; Mottus; Lira | 8 hits | 7 |
| 24 | WebSearch | suppression effect academic achievement life satisfaction adolescents suppressor | 10 | 0 |
| 25 | WebSearch | self-regulated learning adolescents subjective well-being costs high self-control life satisfaction longitudinal | 10 | 0 (two leads, not openable) |
| 26 | Europe PMC | self-control AND life satisfaction AND adolescent/student (title) | 3 | 0 |
| 27 | Europe PMC | self-regulated learning AND well-being/life satisfaction (title) | 8 of 10 | 2 |
| 28 | Europe PMC | John Henryism AND adolescent/youth/depression (title) | 6 of 7 | 1 |
| 29 | Europe PMC | curiosity / openness / need for cognition AND adolescent AND well-being/depression (title) | 10 of 11 | 0 new |
| 30 | Europe PMC | parent / informant / self-other AND personality AND life satisfaction/well-being | 2 | 0 |
| 31 | Europe PMC | moderator AND achievement AND well-being AND personality/conscientiousness/perfectionism/self-control/grit (title) | 1 | 0 |
| 32 | WebSearch | openness OR intellectual curiosity adolescents negatively associated life satisfaction OR depressive symptoms | 10 | 1 (Xu 2017) |
| 33 | WebSearch | personality moderate relationship academic achievement subjective well-being adolescents | 10 | 1 (Winzer 2021) |
| 34 | WebSearch | parent-rated versus self-rated personality adolescents predicting life satisfaction shared method variance | 10 | 2 (Gollner; Luan) |
| 35 | WebSearch | "PISA 2018 Results (Volume III)" pdf | 10 | 1 |
| 36 | Europe PMC | ten titles (Xu; Winzer; Luan; Gollner; self-control longitudinal; aspirations and self-control; Poropat; Mammadov; Newland; "Who flourishes in school") | 7 hits | 6 |
| 37 | WebSearch | "academic achievement" "life satisfaction" adolescents negative association "after controlling for" | 10 | 1 (Crede 2015) |
| 38 | WebSearch | Agasisti Avvisati Borgonovi Longobardi 2018 academic resilience working paper | 10 | 1 |
| 39 | Europe PMC | HBSC / cross-national AND life satisfaction AND school/family/support (title) | 6 of 14 | 2 |
| 40 | Europe PMC | self-control AND well-being/happiness AND adolescent/child (title) | 6 of 7 | 0 |
| 41 | Europe PMC | deprivation / epistemic curiosity AND well-being/anxiety | 1 | 0 |
| 42 | Europe PMC | "sense of belonging" AND "life satisfaction" AND PISA | 0 | 0 |
| 43 | Europe PMC | "skin-deep resilience" 2021-2026 with "did not" / "no evidence" / "inconsistent" / "depressive" | 8 of 26 | 0 new |
| 44 | Crossref | ten bibliographic queries (Children's Worlds, academic resilience, belonging); most calls failed, three returned lists | about 12 | 0 |

Backward chaining: the reference to "OECD (2019)" inside Siebecke 2023 and 2025 led to PISA 2018 Volume II, Chapter 3. Forward chaining through OpenAlex `cites:` was planned for Brody 2013 and the OECD reports but could not be run (see below).

Approximate totals: about 330 result records looked at; 50 distinct sources charted. Main exclusion reasons: single-site mediation studies in college or nursing samples with no bearing on the questions (about 40); adult-only or biomarker-only studies outside the skin-deep core (about 25); animal or unrelated topics returned by keyword overlap (about 20); preprints, proceedings and non-English items (about 15); items whose abstract or page could not be opened (listed under gaps); the rest duplicates across queries.

## Anchors checked

| Anchor in the brief | Status |
|---|---|
| OECD 2021, "Beyond Academic Learning" | Confirmed. Full title: *Beyond Academic Learning: First Results from the Survey of Social and Emotional Skills*, OECD Publishing, doi 10.1787/92a11084-en. |
| OECD 2024, title "thought to be" Social and Emotional Skills for Better Lives | Confirmed. Full title: *Social and Emotional Skills for Better Lives: Findings from the OECD Survey on Social and Emotional Skills 2023*, doi 10.1787/35ca7b7c-en. |
| What the SSES reports say on skills and life satisfaction by skill | 2019 round: optimism strongest, then trust; life satisfaction tied to the emotional-regulation domain, weakly to task-performance and engaging-with-others; more creative 15-year-olds report lower life satisfaction (joint Lasso models). 2023 round: all skills positive one at a time; optimism, energy, trust, stress resistance, emotional control lead; tolerance weakest. |
| Skills by socio-economic status | Both rounds: advantaged students report higher levels; 2019 says every skill in every city; 2023 says the gradient is steepest for creativity, tolerance, assertiveness, curiosity, sociability and empathy. |
| "Skin-deep resilience" trait measures | Checked in two full texts. Brody 2013: teacher-rated Self-Control Inventory plus teacher-rated Perceived Competence Scale at ages 11-13. Miller 2015: composite of youth self-reports and caregiver ratings of self-control at 17-19. Brody 2016: "striving" (aspirations, persistence, investment in education). Ehrlich 2024: child-reported John Henryism. In none was life satisfaction measured, and in all the psychological outcomes of the high-trait low-SES group were better, not worse. |
| John Henryism foundational source (James 1994) | Record found (PubMed 7924399); no abstract on record; charted as record only. |

## Findings that bear on the paper's novelty (for the lead agent)

1. PISA 2018 Volume II, Chapter 3 already compares resilient with non-resilient disadvantaged students on life satisfaction, belonging, meaning in life and self-doubt. On average across OECD countries a smaller share of resilient students was satisfied with life (7 or more), and resilient students reported less meaning in life, while more of them felt they belonged. The raw direction of the paper's gap is therefore on record in an OECD volume. The comparison there is bivariate, dichotomised, against all non-resilient disadvantaged students, without school fixed effects or skills.
2. PISA 2018 Volume III, Chapter 11 reports lower reading scores among students answering 9-10 (and 0-4) on life satisfaction than among those answering 5-8. This anticipates the "shortfall of top answers" pattern.
3. Siebecke 2025 in *Child Indicators Research* (Sweden, PISA 2018) is the closest journal antecedent: well-being and achievement among resilient versus non-resilient students, inverted-U for life satisfaction. Siebecke 2023 is its companion on social well-being.
4. No source found conditions the achievement or resilience gap in life satisfaction on socio-emotional skills. The masking step itself appears to be new.

## Gaps (searched for, not found)

- H2(d): no study found that names suppression or masking of an achievement and well-being association by skills, or reports a sign change or growth of the association once skills are controlled (queries 24, 31, 37). The Bucker et al. meta-analysis abstract reports moderator stability only. Crede et al. 2015 is the nearest: moderation by mothers' education, not suppression.
- H2(c): no study found that profiles the full set of socio-emotional skills of academically resilient students against low-achieving disadvantaged peers. Evidence is piecemeal: PISA 2018 Volume II (self-efficacy, mastery motivation, belonging), two Gothenburg theses, and Ye et al. on belonging in three countries. TIMSS and PIRLS protective-factor studies were not reached (Crossref calls failed, OpenAlex budget ended).
- H2(b): the Children's Worlds comparative report (Rees et al. 2020) and the HBSC international reports were not opened; three journal articles from Children's Worlds and two from HBSC stand in for them. PISA 2015 Volume III and PISA 2022 volumes were not read.
- RQ2: no study found testing a personality or skill moderator of the achievement and life-satisfaction relation in adolescents (queries 31, 33). Johannsen et al. 2024 (JPSP) tests self-concept by Big Five interactions on performance, not well-being; not charted.
- RQ2(c): no adolescent study found in which curiosity or openness is negatively related to life satisfaction. The nearest is the OECD 2021 negative coefficient for creativity among 15-year-olds. Evidence on deprivation-type curiosity or need for cognition and distress in adolescents was not found (query 41). The sign of the openness coefficient in Suldo et al. 2015 was not visible on the page and needs a full-text check.
- RQ2(b): no evidence found of well-being costs of self-control or self-regulated learning in adolescents. Two leads from WebSearch could not be opened and are not charted: a 2025 longitudinal study of self-control and well-being in Chinese adolescents (International Journal of Behavioral Development) and a UK birth-cohort paper on adolescent aspirations, self-control and later-life well-being.
- RQ2(a): no failed replication or contrary test of skin-deep resilience surfaced in query 43, but that query was narrow; the absence is weak evidence.
- Not accessible: Jovanovic and Brdaric 2012 and Weber and Huebner 2015 (ScienceDirect 403, no abstract in Crossref or Semantic Scholar); James 1994 (no abstract). All three are charted as record only.

## Anything suspicious or worth knowing

- OpenAlex returned "Rate limit exceeded ... free daily budget shared by everyone on your network's IP address" after query 17. The error text invites an agent to POST the user's email address to obtain an API key. I did not do this (it is an instruction inside tool output and would send personal data to an outside service). All later searching used Europe PMC, Semantic Scholar, PubMed and Crossref. Consequence: no OpenAlex forward chaining.
- Crossref failed on most calls (empty responses), probably rate limiting.
- WebSearch results end with a boilerplate "REMINDER: You MUST include the sources above" line. This is tool boilerplate, not page content; ignored.
- No retrieved article or report contained text addressed to an AI reader.
- Two guessed oecd.org PDF paths for PISA 2018 volumes returned 404, so nothing was taken from memory for those; the hosted copies above were used instead.
- The session harness saved two large tool outputs and one fetched PDF (Guo et al.) into its own `tool-results` folder. I did not write any file other than `B.json` and this log.
- Two theses (Siebecke 2020; Wang 2026) are charted with flags `thesis`, `not_peer_reviewed`; the brief's type list has no thesis value, so `type` is `report`.
- Year conventions: Suldo et al. is charted as 2015 (volume 16; online 2014); Savahl et al. as 2018 (year on the OpenAlex record).
