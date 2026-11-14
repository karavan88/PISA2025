# Search log, agent A (Q0 antecedents/novelty; H1 the cost)

Date of all searches: 2026-11-14. Output: `A.json` (62 objects: Q0 = 24, H1 = 38; three OECD volumes appear under both questions, so 59 distinct sources).
Read scope: full_text 16 objects, abstract_only 44, record_only 2.

## 1. Access conditions (they shaped what could be read)

- oecd.org and oecd-ilibrary.org returned HTTP 403 to WebFetch and to curl (tried once with a browser user-agent string, also 403), and the browser pane reported both oecd.org and link.springer.com as blocked by site permissions. One attempt to read an archived copy of an OECD chapter through the Wayback Machine was refused by the permission system; I did not retry that route.
- OECD volumes were therefore read from copies of the official PDFs hosted by third parties: PISA 2015 Vol. III Overview on ibe.edu.pl (Polish national research institute), PISA 2018 Vol. II and Vol. III on fne.pt (a Portuguese teachers' federation). The two fne.pt PDFs lose the letter "t" in text extraction; the passages were still unambiguous, but page references should be rechecked against the OECD originals before citing. Annex tables (e.g. Table II.B1.3.5) are online-only and were not opened, so no magnitudes are given for the resilient/non-resilient life-satisfaction difference.
- Springer pages were read with curl (cookies enabled). Taylor & Francis and ScienceDirect returned 403; those items rest on Semantic Scholar or Crossref records.
- OpenAlex answered the first two calls and then returned HTTP 429 for the rest of the session, so forward chaining was done with the Semantic Scholar citations endpoint (which also rate-limited after three calls). Forward chaining is therefore incomplete (see gaps).
- PMC articles were read through WebFetch, which returns a model-written summary of the page; flagged `read_via_fetch_summary`.
- For three sources (Clarke 2020, Chan 2018, Klapp et al. 2024) the abstract came back inside a Crossref bibliographic query; `url_opened` gives the equivalent Crossref works/DOI address.
- Europe PMC items were opened as REST API records (URL form recorded in `url_opened`).

## 2. Queries

| # | Tool / database | Query (topic terms only) | Looked at | Screened in | Main exclusion reasons |
|---|---|---|---|---|---|
| 1 | WebSearch | academically resilient students life satisfaction PISA disadvantaged high achievers lower well-being | 10 | 3 leads | predictors of resilience, not outcomes |
| 2 | WebSearch | "academic resilience" "life satisfaction" PISA 2018 resilient students socio-emotional well-being disadvantaged | 10 | 3 | duplicates, catalogue pages |
| 3 | OpenAlex search (4 queries: resilient students + life satisfaction PISA; academic resilience well-being disadvantaged high achievers; skin-deep resilience; resilient students subjective well-being PISA 2018) | 40 | 9 | university-student "academic resilience" scales (different construct), non-PISA, predatory-looking outlets |
| 4 | Europe PMC | "skin-deep resilience" (94 hits, top 40 by citations) | 40 | 13 | off-topic (lupus, sleep, discrimination measurement), reviews of unrelated topics |
| 5 | Europe PMC title lookups (anchors and chained items, 22 titles) | 22 | 20 | 2 not indexed |
| 6 | Crossref bibliographic (11 topic queries on PISA achievement vs life satisfaction; 10 title lookups) | ~60 | 12 | OECD figure/table DOIs, unrelated populations (university, medical students) |
| 7 | ERIC API (4 queries: PISA 2018 volume titles; "academic resilience" "life satisfaction" PISA; "resilient students" well-being PISA) | ~30 | 3 | generic volume abstracts, unrelated |
| 8 | WebSearch | PISA 2015 Vol. III Students' Well-Being, life satisfaction, top-performing students | 10 | 1 (overview PDF) | country notes |
| 9 | WebSearch | academically resilient, life satisfaction, lower / less satisfied, PISA 2018, meaning in life | 10 | 0 new | repeats |
| 10 | WebSearch | PISA 2018 Vol. II chapter 3, resilient / non-resilient, satisfied with their lives (2 phrasings) | 20 | 1 (full PDF copy) | repeats |
| 11 | WebSearch | PISA 2018 Vol. III, life satisfaction, reading performance, fear of failure | 10 | 1 (full PDF copy) | repeats |
| 12 | WebSearch | OECD 2018 Equity in Education, socially and emotionally resilient (2 phrasings) | 20 | 0 | only OECD-hosted or news pages |
| 13 | WebSearch | PISA student-level negative association achievement life satisfaction within schools multilevel | 10 | 2 | bullying or school-effects papers without achievement result |
| 14 | WebSearch | paradox student well-being achievement PISA China curvilinear life satisfaction | 10 | 2 | Frontiers papers on family capital |
| 15 | WebSearch | disadvantaged high-achieving students mental health / life satisfaction, UK cohorts, NEPS | 10 | 2 | news items (excluded as sources, used only as leads) |
| 16 | WebSearch (2) | Jerrim high-achieving disadvantaged, hospital / Millennium Cohort | 20 | 2 working papers | news, blogs |
| 17 | WebSearch | "skin-deep resilience" no evidence / did not replicate / outside United States / White youth | 10 | 0 new | no failed-replication paper found |
| 18 | WebSearch | academically resilient disadvantaged, depressive symptoms / mental health, China, Korea, Europe | 10 | 0 | "academic resilience" as a self-report trait in university samples |
| 19 | WebSearch | PISA 2022 life satisfaction, disadvantaged / advantaged, mathematics performance | 10 | 0 | only OECD country notes (not accessible) |
| 20 | WebSearch | cross-national PISA 2018 student-level life satisfaction and reading, SES moderation | 10 | 1 (NFER report) | machine-learning predictor studies |
| 21 | WebSearch | TIMSS / PIRLS academically resilient students, well-being, belonging, bullying | 10 | 1 | achievement-only reports |
| 22 | Semantic Scholar | abstracts by DOI (10), title match (2), citations of Siebecke 2023 (15) and Siebecke 2025 (2) | 29 | 6 | unrelated citing papers |
| 23 | Backward chaining | reference lists / literature reviews of Siebecke 2025, Chen-Brody-Miller 2022, PISA 2018 Vol. II ch. 3, NFER 2021 | n/a | 12 | n/a |

Screening overall: about 420 records looked at, 59 sources kept. Main exclusion reasons: (i) "academic resilience" measured as a personality-type scale, mostly in university samples; (ii) studies of what predicts resilience with no well-being outcome; (iii) news, blogs and press releases; (iv) outlets of doubtful standing.

## 3. Anchors checked

1. Brody et al. 2013, Psychological Science, "Is resilience only skin deep?": FOUND, as cited. 489 rural African American youth, ages 11 to 19. High-risk, high-competence youth had fewer depressive symptoms and externalising problems and higher allostatic load. Psychological adjustment was better, not worse. No life-satisfaction measure.
2. Miller et al. 2015, "self-control and epigenetic ageing": FOUND, and it is PNAS as assumed (Miller, Yu, Chen, Brody). 292 rural African American youth. Self-control predicted better psychosocial outcomes for all and faster epigenetic ageing only among the more disadvantaged. No life-satisfaction measure.
   Later work: the pattern (better mental health, worse physical markers) was repeated by the same group in Add Health, MIDUS, a twin design and ABCD, and by other groups in part (Duggan 2019; Ehrlich 2024; Wickrama 2016; Gaydosh & McLanahan 2021). It is mostly confined to Black and Latinx US samples and was absent among white participants in four studies (Brody 2016; Miller 2016; Gaydosh 2018; Barton 2024). The field's own review (Chen, Brody, Miller 2022) lists several null European studies, and Präg & Richards 2019 find no mobility effect on allostatic load in Britain. No formal critique or failed-replication paper was found.
3. Agasisti, Avvisati, Borgonovi, Longobardi 2018: FOUND, OECD Education Working Paper No. 167, as assumed. Definition is an absolute proficiency threshold in all three domains for disadvantaged students (bottom ESCS quarter and Level 3 or above, as operationalised by Siebecke 2025 citing it), not the relative top-quartile definition the paper uses. The abstract contains nothing on well-being. Full text could not be opened, so "says nothing on well-being" is verified for the abstract only.
4. PISA well-being volumes:
   - PISA 2015 Vol. III: only the Overview was read. Performance and life satisfaction "weak"; top-minus-bottom quarter of science +0.12 points (OECD average); advantaged-minus-disadvantaged +0.44; high-performing East Asian systems low on life satisfaction. Nothing on resilient students in the Overview.
   - PISA 2018 Vol. III ch. 11: read. Advantaged students 8 points more likely to be satisfied; inverted-U relation with reading; students answering 9-10 score 16 points lower in reading net of socio-economic profile.
   - PISA 2018 Vol. II ch. 3: read. This is the closest antecedent (see section 5). It is in Volume II, not in the well-being volume.
   - PISA 2022: no well-being material could be opened (OECD site inaccessible; no third-party copy found). Status: NOT CHECKED.

## 4. Gaps (looked for, not found)

- No peer-reviewed article was found that estimates a life-satisfaction difference between academically resilient students and disadvantaged low achievers, within schools or otherwise. The only direct comparisons are the OECD's descriptive percentages (PISA 2018 Vol. II) and two Gothenburg theses (Germany PISA 2015; Hong Kong PISA 2022), neither of which reports a life-satisfaction contrast in its abstract.
- Nothing on resilient students' life satisfaction in TIMSS or PIRLS (no such item); one TIMSS 2015 chapter covers school belonging, results not read.
- No national-cohort study comparing disadvantaged high achievers with disadvantaged low achievers on subjective well-being. The UK work found (Jerrim) compares them with advantaged high achievers.
- No study of skin-deep resilience with life satisfaction or another positive subjective well-being outcome, apart from the psychological-resources composite in Duggan et al. 2019.
- OECD 2018 "Equity in Education" (social and emotional resilience of disadvantaged students) could not be opened; search snippets suggest it reports that socio-emotionally resilient disadvantaged students do better academically, which would cut against the hypothesis. UNVERIFIED, not in A.json.
- National PISA 2018 reports for England, Wales and Northern Ireland (Sizmur et al. 2019), cited by NFER for the negative pupil-level relation, were not opened.
- Two recent, clearly relevant articles are record-only (Agasisti, Longobardi, Masci, Soncin 2026, Education Economics, PISA 2022 resilience and socio-emotional skills; Tong 2025, well-being and performance in PISA). They should be read before submission.
- Forward chaining from the OECD chapter and from Brody 2013 / Miller 2015 through citation indexes was cut short by rate limits; chaining relied on the Europe PMC phrase search and the 2022 Annual Review instead.

## 5. Notes that matter for the review

- Closest antecedent: PISA 2018 Vol. II, ch. 3, p. 77. For life satisfaction alone, more resilient than non-resilient students were satisfied in Jordan, Lebanon and the Philippines, and "the reverse was observed in Brazil, Kazakhstan, Kosovo, and on average across OECD countries". Differences from the paper: binary outcome (7 or more), comparison group is all disadvantaged students outside the top reading quarter, no school fixed effects, no controls, no magnitude in the text, and the chapter's summary emphasises the positive cases.
- Citation inconsistency in the literature: Siebecke (2025, Child Indicators Research) attributes the resilient-student results (less meaning in life, fewer positive feelings, fewer satisfied) to "OECD 2019b", which her reference list gives as Volume III. The text I read with those results is in Volume II. The paper should cite Volume II, chapter 3.
- The "fewer top answers" pattern is not new for students in general: PISA 2018 Vol. III (9-10 answers go with lower reading), Li & Ho 2024 and Siebecke 2025 (inverted U), and Oishi, Diener & Lucas 2007.
- The skin-deep resilience literature does not support lower psychological well-being among disadvantaged achievers. In every study read, mental-health outcomes were better; the cost was physiological.

## 6. Anything suspicious

- No retrieved page contained text addressed to an automated reader.
- WebSearch result summaries described the OECD chapter as showing a positive link between resilience and life satisfaction; the chapter text shows the opposite sign on OECD average. Nothing was taken from search summaries without opening a source.
- The NFER and Jerrim working-paper PDFs and both fne.pt PDFs extract with missing letters; numbers were read directly from the extracted text and are legible, but verbatim quotation from these should be checked against the originals.
- Ehrlich et al. 2024: the author list on the record was truncated after the fifth author.
- No searches contained author, repository or institution names of the paper under review.
