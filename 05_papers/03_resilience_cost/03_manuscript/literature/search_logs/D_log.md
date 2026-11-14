# Search log, agent D (H4 specificity; RQ1 context)

Date of all searches: 2026-11-14. Output: `D.json` (75 objects: 42 under H4, 33 under RQ1; two sources appear under both).
Read scope of the 75 objects: 4 full text (two of them the same OECD overview under H4 and RQ1), 67 abstract only, 4 record only.

## Conventions used in D.json

- `bears` for H4 is read against the hypothesis as worded (a larger life-satisfaction penalty for disadvantaged high achievers).
  `contradicts` = evidence of no cost, a benefit, or a cost falling on advantaged or low-achieving students instead.
- `bears` for RQ1 (a question, not a hypothesis) is read against the conjecture that context, gender or aspirations DO moderate.
  `supports` = the source finds such moderation or a mechanism for it (so it is in tension with the paper's null result);
  `contradicts` = the source finds no such moderation or the reverse pattern (so it agrees with the paper's null).
- "not stated in abstract" means exactly that; nothing was filled in from memory.
- No verbatim quotes were used as locators; locators are section, page or "Abstract".

## Tools and what happened to them

| Tool | Use | Status |
|---|---|---|
| OpenAlex API (`/works?search=`, `/works/https://doi.org/...`) | keyword screening, abstracts | Worked for about 50 queries, then returned "Rate limit exceeded / Insufficient budget" (shared daily budget). Forward chaining with `filter=cites:` was therefore NOT possible. |
| Semantic Scholar Graph API | abstracts by DOI | By-DOI lookups worked (about 20); keyword search returned HTTP 429 throughout. |
| Europe PMC REST API | keyword screening, abstracts by DOI/PMCID | Worked; keyword search is noisy (recency-biased). |
| Crossref API | bibliographic checks, some abstracts | Worked; two queries returned empty bodies. |
| IDEAS/RePEc, EconPapers pages | abstracts for Springer and Elsevier journals | Worked. |
| WebSearch (standard) | 9 queries | Worked; snippets were used only as leads, never as evidence. |
| WebFetch | publisher and repository pages | Springer redirects to an identity-provider URL that the permission system refused; not worked around. OECD pages returned 403. GUPEA returned an Anubis bot block. Taylor & Francis returned 403. Frontiers, AEA, NBER, MPRA, labore.fi, sociologicalscience.com and the IBE mirror of the OECD overview worked. |
| Internet Archive search API | catalogue records for Bourdieu and Sorokin | Worked (record only). |

## Queries (tool, approximate hits looked at, screened in)

OpenAlex, round 1 (4 queries, about 20 hits, 9 in): habitus clivé Friedman; Marsh Hau BFLPE 26 country; achievement subjective well-being meta-analysis; skin-deep resilience allostatic load.

OpenAlex, round 2 (5 queries, about 35 hits, 9 in): skin-deep resilience; Luthar high-achieving schools; PISA life satisfaction achievement cross-national; intergenerational mobility subjective well-being diagonal reference models; dissociative thesis Sorokin.

OpenAlex, round 3 (18 queries, about 70 hits, 14 in): high-achieving schools risk; culture of affluence; academic pressure systematic review; Marsh Hau exact title; happy fish little pond; BFLPE life satisfaction school-average achievement; Crosnoe school socioeconomic composition; relative deprivation Yitzhaki adolescent life satisfaction; gender gap adolescent mental health 73 countries; gender differences life satisfaction meta-analysis; unrealized educational expectations depression; aspirations expectations subjective well-being disadvantaged; school starting age mental health; relative age adolescence life satisfaction; paradox wealthy nations adolescent life satisfaction; smart but unhappy; can schools make children happier; educational stratification tracking school stress.

OpenAlex, round 4 (24 queries, about 72 hits, 19 in): Luthar 2020 and 2013 exact titles; Coley economic risks; Marsh and Hau exact title; Crosnoe exact title; "is resilience only skin deep"; Gaydosh college completion; Miller self-control epigenetic aging; Hadjar and Samuel; Chan mobility well-being; Houle and Martin; Reay strangers in paradise; Jury low-SES students; Ingram; social class mental health university meta-analysis; equality paradox adolescent well-being; compulsory schooling mental health; too young to leave the nest; relative age mental health; academically resilient students well-being PISA; Kaya and Erdem; Amholt; "better policies for better lives" critique; Govorova 35 OECD countries.

OpenAlex, round 5 (20 queries): all failed on the rate limit except the first (PISA 2015 Volume III record).

Europe PMC (18 keyword queries, about 100 hits looked at, 12 in): school-average achievement life satisfaction BFLPE; class-level performance psychosomatic; life satisfaction achievement PISA SES moderation; relative deprivation classmates life satisfaction; low-income affluent neighbours antisocial; school SES composition depressive symptoms cross-level interaction; relative age school entry life satisfaction; school starting age mental health RD parental education heterogeneity; relative age depression cohort; aspirations expectations misalignment mental health; unmet educational expectations depressive symptoms; family affluence relative deprivation life satisfaction multilevel; school pressure trends HBSC; first-generation students mental health; upward mobility mental health young adults; John Henryism adolescents depressive symptoms; achievement depressive symptoms SES moderation; gender life satisfaction PISA school anxiety. Most hits were 2025-2026 items off topic (clinical, COVID, single-country convenience samples).

Crossref (about 25 title queries): bibliographic verification and DOI discovery for Pop-Eleches and Urquiola; Kaya and Erdem; Marquez and Long; Mühlenweg; Bernardi; Zang and de Graaf; Chan; Brody 2013; Bourdieu; Sorokin; Stephens; Rubin; Bradshaw; Sabates; Bütikofer; Song; Kiessling and Norris; Högberg; OECD PISA 2018 Volume II chapter 3.

WebSearch (9 queries): PISA 2015 Vol III performance and life satisfaction; academically resilient students well-being PISA; school-average achievement life satisfaction PISA; elite school RD mental health; aspirations and life satisfaction or depressive symptoms in disadvantaged adolescents; Högberg stratification stress; relative age or school starting age heterogeneity by SES; PISA 2018 Vol II resilience and well-being chapter; PISA SES-by-achievement interaction on life satisfaction.

Screening totals (approximate): about 330 records looked at by title; about 95 abstracts read; 73 distinct sources charted (75 objects; the OECD 2017 overview and Fumarco et al. 2020 each appear under both questions).
Main exclusion reasons: outcome not wellbeing or mental health (for example allostatic load only); adult-only samples outside the mobility and skin-deep strands; single-site convenience samples; theses and dissertations; non-English text; supplements and duplicates (working-paper twins of published articles); abstract not obtainable.

## Chaining

- Backward: only through sources named in the abstracts read (Friedman to Bourdieu; Chan, Houle and Martin to Sorokin; Rathmann to the BFLPE literature; Miller 2020 and Gaydosh to the Brody skin-deep studies; Präg to the null-result mobility literature). Reference lists were read only for Crede et al. 2015 and Dee and Sievertsen (working paper).
- Forward: NOT done. The OpenAlex `cites:` filter was unavailable after the shared budget ran out. This is a real limitation; a second pass with an API key should forward-chain from Crede 2015, Rathmann 2018 (IJERPH), Brody 2013, Friedman 2016, Fumarco 2020 and Siebecke 2025.

## Anchors

| Anchor in the brief | Status |
|---|---|
| Friedman 2016, "habitus clivé", The Sociological Review | VERIFIED. "Habitus Clivé and the Emotional Imprint of Social Mobility", The Sociological Review 64(1), 129-147, doi 10.1111/1467-954x.12280. OpenAlex lists 2015 (online first); Crossref lists print 2016. It is a qualitative study of 39 upwardly mobile UK adults, not of school students, and has no wellbeing scale. |
| Bourdieu's notion itself | Record only. Catalogue records opened for Sketch for a Self-Analysis (Polity, 2007) and The Weight of the World (Stanford UP, 1999). Page-level attribution of "habitus clivé" rests on Friedman's and Reay's abstracts. |
| Sorokin, dissociative thesis | Record only (Social Mobility, Harper 1927; Social and Cultural Mobility, Free Press 1959). The thesis is named in the abstracts of Chan 2018, Houle and Martin 2011 and Daenekindt 2016. |
| Marsh and Hau 2003, American Psychologist, 26-country PISA test | VERIFIED as to journal, year, 26 countries, N = 103,558, negative effect in all 26 (mean beta -.20). The abstract does NOT name PISA; it says nationally representative samples of 15-year-olds. The outcome is academic self-concept, not wellbeing. |
| Diagonal reference model studies finding no cost | Found and charted: Houle and Martin 2011; Dhoore et al. 2019; Schuck and Steiber 2018; Präg et al. 2022. Also Chan 2018 (not DRM). |

## Gaps (looked for, not found)

1. SES-by-achievement interaction on life satisfaction in PISA or any cross-national survey: nothing found (OpenAlex, Europe PMC, WebSearch). Nearest: Crede et al. 2015 (411 German Gymnasium students), Siebecke 2025 (Sweden, PISA 2018), and the unopened OECD PISA 2018 Volume II chapter 3.
2. Level comparison of resilient students with equally disadvantaged low achievers on life satisfaction: not found in any text I could read. The OECD chapter (Figure II.3.8, "Students' well-being, by academic resilience") almost certainly contains it; the page returned 403 and is charted as record only. A search snippet, which is not evidence under the brief, described resilient students as reporting more school belonging and only weakly different life satisfaction. THIS MUST BE CHECKED BY HAND before any novelty claim.
3. Big-fish-little-pond test on life satisfaction using PISA: none found. Only Rathmann et al. 2018 (German NEPS, class-level GPA).
4. Quasi-experimental study with life satisfaction as outcome and a family-background split: none found. Dee and Sievertsen (parent-rated SDQ, Denmark) is the only school-entry design with reported SES heterogeneity; Fumarco et al. 2020 has life satisfaction but no SES split in the abstract.
5. Gender moderation of the achievement-life satisfaction link specifically: no dedicated study found; only OECD descriptive figures on anxiety among top-performing girls.
6. Wellbeing cost of high aspirations among disadvantaged adolescents in high-income countries: not found. PISA 2015 Volume III has a figure on life satisfaction and expectations of completing university (Crossref component 10.1787/888933471215); not read.
7. Tracking age, competitiveness or average achievement as moderators of student life satisfaction: thin. Found Heller-Sahlgren 2018 (competition), Rudolf and Bethmann 2023 (learning intensity), Fumarco et al. 2020 (tracking age moderates the relative-age gap). The Högberg group's work on stratification, grading and school stress was seen in search snippets only; the article page for Högberg et al. (Journal of Education Policy, doi 10.1080/02680939.2019.1686540) returned 403 and no abstract was available from Crossref, so it is not charted.
8. Skin-deep resilience outside the United States, or with life satisfaction as the outcome: none found.

## Seen but not charted (with reason)

- Black, Devereux and Salvanes, "Too Young to Leave the Nest" (NBER w13969 page opened): the abstract reports IQ, teenage pregnancy, education and earnings, no mental-health outcome. My expectation that it covered mental health at 18 was not borne out by the text read.
- Siebecke 2020, thesis on the well-being of academically resilient students in Germany (PISA 2015): repository blocked; thesis, so excluded anyway.
- Mühlenweg et al. 2012 (Economics of Education Review) and Bernardi 2014 (Sociology of Education): records found, no abstract obtained; Bernardi's outcome is not wellbeing.
- Böckerman et al., IZA DP 17501 (relative age and adult mental health, Finland): search snippet only.
- Malamud, Mitrut, Pop-Eleches and Urquiola 2024 (NBER w32892, perceptions under school tracking): title only.
- Sabates, Harris and Staff 2011; Kim et al. 2026; Zhang and Jiang 2024 (aspiration mismatch): title only.
- Wong et al. 2023 (engagement meta-analysis); Steinmayr et al. 2018; O'Connor and Bartolini 2025; Currie and Morgan 2020; Corell et al. 2024: peripheral to the two questions.
- Präg and Richards 2019; McLoughlin et al. 2022; Gugushvili et al. 2021; Iveson et al. 2022: mobility and allostatic load or later-life health, off outcome.
- Daenekindt 2016 (Sociologos): Dutch-language.
- Lam et al. 2026; Chung et al. 2025; Chen et al. 2023; Hill et al. 2016: skin-deep resilience in adult, clinical or commentary form.

## Points the synthesis should not miss

- The meta-analytic achievement-wellbeing correlation is small and positive (r about .16), and OECD's own PISA 2015 figure puts the top-vs-bottom-quarter life-satisfaction gap at 0.12 points with negative gaps in several systems. A within-disadvantaged-group penalty is therefore a claim about a subgroup against a near-zero average.
- Skin-deep resilience predicts BETTER self-reported psychological outcomes for low-status strivers, with costs in biomarkers. Citing it in support of a life-satisfaction penalty would misstate it.
- The quantitative mobility literature mostly rejects the dissociative thesis for self-reported wellbeing; support is qualitative (Friedman, Ingram, Reay) or isolated (Hadjar and Samuel, UK only).
- The high-achieving-schools literature places achievement-pressure costs among affluent youth.
- Relative age raises adolescent life satisfaction directly (Fumarco et al. 2020), which matters for the exclusion restriction of a school-entry-cutoff instrument.

## Suspicious or noteworthy

- No retrieved page contained text addressed to an automated reader; nothing resembling an injected instruction was seen.
- The fetch tool's summary of Crede et al. 2015 reported an apparent mismatch between Table 3 and the coefficients in the text; I did not check the table myself. Flagged in D.json.
- The Europe PMC abstract of Gump et al. 2026 is garbled in the results sentence, and the OpenAlex abstract of Ehrlich et al. 2024 is missing its sample size; findings are limited to what was legible.
- Kiessling and Norris: Crossref gives print year 2022 for Economic Journal 133(649); the cover date may be 2023.
- Author lists for Amholt et al. 2020, Elgar et al. 2013 and Chen et al. 2020 were first written from memory and then verified against Crossref; they are correct as recorded.
- The OECD 2017 entry rests on the Overview booklet (pp. 3-12) read from a national mirror, not on the full Volume III.
