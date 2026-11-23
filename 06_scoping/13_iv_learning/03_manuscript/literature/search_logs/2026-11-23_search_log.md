# Search log, 23 November 2026

Form of review: narrative, for the background section of an empirical paper. It does not claim to cover the literature. The author confirmed
the paper's configuration on 22 November 2026 and did not choose a formal review form.

## Sources

| Source | Used for | Access |
|---|---|---|
| Crossref REST API (`api.crossref.org/works`) | Checking that each reference exists; exact metadata; abstracts where the publisher deposited one | Public, no key |
| OpenAlex API (`api.openalex.org/works`) | Discovery by free-text search; abstracts not in Crossref | Public, no key; rate limit reached several times |

No library databases (Web of Science, Scopus, ERIC, EconLit) and no Google Scholar were searched. No full text was opened.

## Step 1: candidate list from prior knowledge, checked against Crossref

70 candidates were written down from prior knowledge of the field and queried in Crossref by author, title and venue. A candidate
was accepted only when the first author's surname, the year (within one) and the title words matched.

- First pass: 54 of 70 matched. Five of those were working-paper versions (NBER, OSF) and were replaced by the journal version.
- Second pass, refined queries for the 16 unmatched and the 5 working-paper versions: all resolved except three items without a DOI
  (Reardon 2011, a book chapter; Bradbury et al. 2015, a book; Coleman et al. 1966, a report). Each of the three was confirmed to exist
  through a related record with a DOI, named in the `note` field of `references.bib`.
- Third pass: 22 further candidates (seasonal comparison follow-ups, effect-size benchmarks, methods references, skills in adolescence):
  all matched.

## Step 2: discovery searches in OpenAlex (top 8 results per query read by title)

| Label | Query | Hits | Added from it |
|---|---|---|---|
| C1 | school entry cutoff grade effect achievement PISA instrumental variable | 199 | Givord 2024 (preprint); Cordero et al. 2018 |
| C2 | effect of one additional year of schooling on test scores regression discontinuity date of birth international assessment | 1,280 | McEwan and Shapiro 2008; Lee and Lemieux 2010 |
| C4 | adjacent-grade discontinuity schooling socioeconomic inequality achievement | 327 | Skopek et al. 2024 (preprint); Borgen et al. 2026 (preprint) |
| B1 | schools as equalizers socioeconomic achievement gap schooling exposure causal | 1,440 | Passaretta and Skopek 2021, 2024; Passaretta et al. 2025 (preprint); Jensen 2023 (preprint); Dumont and Ready 2020 |
| B2 | seasonal comparison summer learning socioeconomic gap school year | 10,669 | none new |
| A1 | socioeconomic achievement gap trajectory from early childhood to adolescence cross-national | 12,589 | none (results off topic) |
| D3 | who benefits from effective schools heterogeneity school effects prior achievement | 58,206 | none new (Jackson et al. 2024 came from the Crossref second pass) |
| E1 | Matthew effect achievement growth prior achievement cumulative advantage schooling | 1,337 | none new |
| E2 | quantile treatment effect schooling achievement distribution instrumental variable | 1,093 | none |
| E3 | achievement growth low achievers high achievers school year gains differ by prior achievement | 181,878 | none (results off topic) |
| F1 | schooling effect socio-emotional skills non-cognitive skills grade age causal | 10,961 | Sorrenti et al. 2025 |
| F2 | reference bias self-reported non-cognitive skills schools | 275,876 | none new |
| F3 | social and emotional skills adolescents age decline survey OECD | 9,928 | OECD 2024 |
| F4 | school starting age relative age non-cognitive skills personality adolescents | 62,037 | none |
| G1 | learning gain per year of schooling effect size benchmark achievement gap years of schooling equivalent | 6,801 | none new |
| G2 | learning-adjusted years of schooling | 187,955 | Filmer et al. 2020 |
| G3 | Bloom Hill Black Lipsey performance trajectories and performance gaps as achievement effect-size benchmarks | 223 | none (found through Crossref) |
| G4 | PISA score points equivalent to one year of schooling | 5,808 | none |

**Rerun later the same day.** Four queries had failed on the rate limit twice: C3 (schooling effect by SES at the school-entry cutoff),
C5 (differential exposure approach), D1 and D2 (school value added and socioeconomic composition).

| Label | Outcome of the rerun (top 10 by title) | Added |
|---|---|---|
| C5 | Ran in OpenAlex, 14,618 hits | Jensen and Passaretta 2025 (preprint, TIMSS, many countries); Jensen 2026 (the journal version of the 2023 preprint) |
| D2 | Ran in OpenAlex, 27,366 hits | Belfi et al. 2016; Sciffer et al. 2022 |
| C3 | Failed again in OpenAlex; two versions run in Crossref (8 results each) | Nothing on target |
| D1 | Failed again in OpenAlex; two versions run in Crossref (8 results each) | Timmermans and Thomas 2015; Lenkeit 2013 (methods) |

Crossref ranks free-text queries poorly, so C3 and D1 count as weakly searched.

## Step 3: abstracts read

Abstracts were read for 30 references: 12 through Crossref for the papers closest to this study, 4 through OpenAlex (2 more had
none: Avvisati and Givord 2023; Givord 2024), 11 from Crossref for the sociological core (2 more had none), and 3 after the rerun
(Jensen 2026 had none; its content is taken from the abstract of the preprint). The
evidence table marks, for every reference, whether its content was read as an abstract in this session or is recalled from prior
knowledge and still has to be checked in the full text.

## What the search changed

The candidate list did not contain the differential-exposure studies of whether schooling equalises (Passaretta and Skopek 2021 and
the four related papers). They are the closest antecedents of this paper's first question and were found only by search B1 and C4. The rerun of C5 then found
a cross-national application to TIMSS (Jensen and Passaretta 2025), which reports that schooling narrows the socio-economic gap.

## Corrections to earlier project notes

- Avvisati and Givord: the school-entry design in 18 systems is the OECD working paper "How much do 15-year-olds learn over one year of
  schooling? An international comparison based on PISA" (doi:10.1787/a28ed097-en, abstract read). The working paper on Austria and
  Scotland (doi:10.1787/d99e8c0a-en, abstract read) uses changes in the testing period. The Labour Economics article of 2023 carries the
  subtitle "An international comparison based on PISA"; its abstract could not be retrieved, so which design it reports is inferred
  from the title and must be confirmed in the full text. The working-paper numbers are not in Crossref and are not verified.
