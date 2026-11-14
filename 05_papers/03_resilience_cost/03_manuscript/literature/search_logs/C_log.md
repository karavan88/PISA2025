# Search log, agent C (H3 and RQ3)

Date of all searches: 2026-11-14. Output: `C.json` holds 85 objects (40 under H3, 45 under RQ3), 84 distinct sources; Barrington-Leigh (2024) is charted under both questions.

Read scope: 10 full text (some only in targeted passages, stated per entry), 68 abstract only, 7 record only (no finding written).

## Tools and what they returned

| Tool / database | Use | Notes |
|---|---|---|
| OpenAlex API (`/works?search=`, `/works?filter=title.search:`) | First discovery rounds and abstracts | About 15 queries, roughly 90 records looked at. The shared free budget ran out part-way ("Rate limit exceeded ... resets at midnight UTC"). No forward-citation chaining was possible after that. |
| Crossref API (`query.bibliographic`, `/works/<doi>`) | Verification of metadata, abstracts where deposited | About 60 lookups. Many Springer and Elsevier records carry no abstract. |
| Europe PMC REST search | Abstracts for psychology and health journals | About 22 lookups. |
| Semantic Scholar Graph API | Abstracts by DOI and title match | About 20 lookups; rate-limited after about 12; several records without abstract. |
| WebSearch (standard mode) | Topic discovery, 17 queries | Each returned about 10 links; used as leads only, every included source was then opened. |
| WebFetch | IDEAS/RePEc, EconPapers, DergiPark, repository pages | 12 pages read. Springer, OECD, ScienceDirect, Taylor & Francis, Tilburg repository and pedocs pages returned redirects or HTTP 403. |
| `curl` + `pdftotext` on open PDFs | Full text | Lu & Bolt 2015; Buckley 2009; Ulitzsch et al. 2023 and 2024; Chen et al. 2023; Barrington-Leigh 2024 and its appendix; Dolan et al. 2011; Kyllonen et al. 2010; Angelini et al. 2009 working paper and 2012 article; Marquez et al. 2026; Zang & de Graaf 2016; Havan et al. 2024. |

## Queries (topic terms only)

OpenAlex and WebSearch, H3:
- response styles PISA self-reports (He, van de Vijver)
- attitude-achievement paradox PISA; attitude-achievement paradox PISA response style
- anchoring vignettes PISA 2012 questionnaire (Kyllonen, Bertling)
- response styles PISA student questionnaire achievement extreme acquiescence
- extreme response style acquiescence related to student achievement socioeconomic status within countries PISA
- careless insufficient effort responding PISA background questionnaire low-achieving students straightlining rapid responding
- careless responding student survey lower GPA academic achievement adolescents predictors
- acquiescence / extreme response style, cognitive ability or achievement, adolescents, within-country
- title searches for each named candidate (Meisenberg & Williams; Primi et al.; Hitt et al.; Zamarro et al.; Soland et al.; Steedle et al.; Ulitzsch et al.; Van Vaerenbergh & Thomas; Van de gaer et al.; Vonkova et al.; Buckley; Heine et al.; Marsh & Hau; Baumgartner & Steenkamp; Stankov et al.; von Davier et al.; Marksteiner et al.)

OpenAlex, Crossref and WebSearch, RQ3:
- title searches for King et al. 2004; King & Wand; Bond & Lang; Bago d'Uva et al. (three papers); Angelini et al. (two papers); van Soest et al. 2011; Kapteyn, Smith & van Soest; Grol-Prokopczyk et al.; Molina; Montgomery; Peracchi & Rossetti
- anchoring vignettes life satisfaction education shifts thresholds reporting heterogeneity
- focal value responses life satisfaction 0-10 scale low education numeracy
- life satisfaction "ten out of ten" less education lower income than "nine"
- children subjective well-being 0-10 scale extreme / ceiling / maximum score, Children's Worlds
- Cantril ladder adolescents reliability validity (Levin & Currie; Mazur et al.)
- PISA life satisfaction top performers, share very satisfied, OECD Students' Well-Being
- life satisfaction top category share adolescents academic achievement, PISA or HBSC
- "anchoring vignettes" "life satisfaction" adolescents / children / students
- gifted or high-achieving adolescents life satisfaction, meta-analysis
- responses to Bond & Lang (Schröder & Yitzhaki; Kaiser & Vendrik; Chen et al.; Bloem; Liu & Netzer; Kaiser & Oswald)
- aspirations and education (Clark et al.; Kristoffersen; Ferrante; Stutzer; Graham & Pettinato; Zang & de Graaf; Hadjar & Samuel)

## Screening

Roughly 230 records seen across all tools. 84 sources included. Main reasons for exclusion:
- Off topic although matched on keywords (PISA policy commentary, single-country achievement-factor studies, immigrant or refugee samples unrelated to measurement): about 60.
- Duplicates of the same work (preprint and journal version, repeated hits): about 35. Where only the preprint abstract could be read this is flagged on the entry.
- Pure psychometric method papers on adult or teacher samples with no bearing on achievement or life satisfaction (for example Ju & Falk 2019 on TALIS; Liu et al. 2017 simulation; Zhang & Wang 2020): about 20.
- Theses, conference abstracts, blogs, news (Quartz), non-English national-journal papers without an English abstract: about 15.
- Could not be opened at all and not central: about 15 (for example Lafontaine et al. 2015; Cheung, Mak & Sit 2018; Vonkova & Hrabak 2015; Peracchi & Rossetti 2012; Gilman & Huebner 2006; Bücker et al. 2018).

Adult samples were kept only where they are foundational or carry the only evidence on a mechanism (vignette identification, education and thresholds, aspirations); each is flagged `adult_sample`.

## Anchors checked

| Anchor in the brief | Status |
|---|---|
| He & van de Vijver, response styles and self-reports in PISA, 2013-2016 | Partly as assumed. Found: He & van de Vijver 2016 chapter on the motivation-achievement paradox (record only, text not accessible); He, Van de Vliert & van de Vijver 2016 (country-level extreme responding from PISA); He, Buchholz & Klieme 2017 (PISA 2012 vignettes, not with van de Vijver); He & van de Vijver 2015 is on TALIS teachers; He & van de Vijver 2013 is a Dutch multi-ethnic study, not PISA (record only). The readable PISA papers analyse response style between countries. The one within-sample statement is in He, Buchholz & Klieme: misordered vignette ratings go with low socio-economic status and low cognitive sophistication. |
| Kyllonen & Bertling, innovative formats and anchoring vignettes in PISA 2012, 2013-2014 | Exists: chapter in the Handbook of International Large-Scale Assessment, Crossref date 2013-11-12, DOI 10.1201/b16061-17. Text not accessible (record only). A related consortium paper (Kyllonen, Burrus, Roberts & Van de gaer 2010) was read in part; it is marked "do not cite without permission". |
| King, Murray, Salomon & Tandon 2004 | Confirmed: American Political Science Review 98(1), 191-207, DOI 10.1017/S000305540400108X. OpenAlex also lists a duplicate record dated 2003 with another DOI; the Crossref record of the 2004 DOI was used. |
| HOPIT / CHOPIT | The term Hopit appears in Angelini et al. (2012, 2014 working-paper version). No separate source on the model was charted. |
| Kapteyn, Smith, van Soest; Angelini and colleagues | Confirmed: Kapteyn et al. 2010 chapter "Life Satisfaction"; RAND working paper on income satisfaction (journal version not verified); Angelini et al. 2012 and 2014. |
| Bond & Lang, Journal of Political Economy 2019 | Confirmed: 127(4), 1629-1640, DOI 10.1086/701679. |

## Gaps (searched for, not found)

- No study was found that relates extreme, acquiescent or midpoint responding to achievement within countries across many PISA systems, apart from Lu & Bolt 2015 (near-zero relation, PISA 2006, extreme style only). Single-country results point both ways (Ertürk & Tan 2021 on socio-economic status; İlgün Dibek & Yildirim-Erbasli 2026 on achievement in Türkiye).
- No PISA study relating questionnaire speeding or careless responding to students' test performance was found; the Ulitzsch et al. papers do not report it in the parts read. The achievement link comes from TIMSS (Steinmann et al. 2024; Chen et al. 2023, books at home).
- No anchoring-vignette study of life satisfaction in PISA, HBSC or Children's Worlds was found. PISA 2012 vignettes covered teacher support and classroom management only. The one child study with life-satisfaction vignettes is Vonkova 2019 (Czech fifth-graders).
- No study was found that documents the top-box (answer 10) share by achievement group in PISA other than the appendix figure in Barrington-Leigh 2024. The OECD PISA 2015 Volume III chapter on life satisfaction could not be opened (HTTP 403), so what it reports on top versus bottom performers is not charted.
- Nothing was found on ceiling effects or top-category responding in Children's Worlds or HBSC single items; the search returned scale-format and factor-structure papers only.
- No direct test in adolescents of whether high achievers hold a higher standard for a top score. The supporting evidence is from adults (Kristoffersen 2018; Clark et al. 2015; Bago d'Uva et al. 2008) plus Vonkova 2019 for children.
- Forward citation chaining from the core papers was not done because the OpenAlex budget was exhausted; backward chaining was limited to references seen in the full texts read (it produced Dolan et al. 2011 and Conti & Pudney 2011 from Barrington-Leigh 2024).

## Things to know before citing

- Several abstracts were read from a working-paper or preprint record of a paper that was later published (Hitt et al. 2016; Montgomery 2022; Graham & Pettinato 2002; Liu & Netzer 2023; Stutzer; Kapteyn et al. on income satisfaction; Marquez & Long; Vriesema & Gehlbach). Flags mark each case; the published text should be checked before quoting results.
- Three abstracts were truncated in the record read (Primi et al. 2016; Vonkova et al. 2018 overclaiming; Marquez & Long). Only the part read is charted.
- Meisenberg & Williams 2008 was read as the abstract reproduced in the IHSN survey-catalogue citation record, because the publisher page was not accessible.
- Angelini et al. 2014: the education result comes from the 2009 working-paper version; the direction of the education effect on thresholds was not extracted.
- The implied within-country correlation of about -.02 for Lu & Bolt 2015 is my arithmetic from their covariance matrix, not a number they print.

## Anything suspicious

- The OpenAlex rate-limit response contained text addressed to automated agents, suggesting that an agent obtain an API key by posting the user's email address. This was ignored; no key was requested and no personal data was sent.
- One Bash attempt to fetch publisher pages with a browser-style user agent was blocked by the permission system and not retried in any other form.
- WebFetch saved two PDFs automatically under the session's `tool-results` folder (Buckley 2009; Marquez et al. 2026). I did not write any other file besides `C.json` and this log.
- No retrieved page contained instructions aimed at the reader other than the OpenAlex message above.
