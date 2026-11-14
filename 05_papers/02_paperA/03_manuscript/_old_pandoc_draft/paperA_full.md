---
title: "Conveyor Belt or Compensating Asset? Socio-Emotional Skills and the Socio-Economic Gradient of Learning in East Asian, Post-Soviet and Post-Communist Education Systems"
author:
  - Garen Avanesian^[Southern Federal University, Future Skills Research Lab, Rostov-on-Don, Russia. Corresponding author.]
date: "Draft of 25 September 2026 — for internal circulation"
abstract: |
  Socio-emotional skills are widely described as a channel through which family advantage becomes achievement, and as a lever for closing socio-economic gaps in learning. These are different claims — mediation and compensation — with different empirical signatures, and they are rarely tested on the same data. Using PISA 2025, the first cycle to measure skills on the taxonomy of the OECD Survey on Social and Emotional Skills, we test both in twenty non-OECD education systems with a socialist or Chinese-heritage tradition of character-forming schooling: five in East Asia, seven post-Soviet and eight in post-communist Europe (114,592 students). A Gelbach decomposition shows that six skills — perseverance, self-regulated learning, goal setting, curiosity, enjoyment of problem-solving and stress adaptability — carry 8 per cent of the ESCS gradient in science, three-quarters of it through curiosity; the share lies between 2 and 16 per cent in nineteen systems. Returns to skills are the same for the bottom 40 per cent and the top 10 per cent of the ESCS distribution (curiosity: 12.6 versus 12.4 points per standard deviation) and the same for materially deprived and non-deprived students at a given ESCS; only goal setting shows a compensatory pattern, in the two European blocs. Skills raise the level of achievement rather than its growth across grades. Material deprivation costs 27 points at a given ESCS, of which skills absorb a tenth. Systems differ not in how much skills matter but in which do: strategic self-regulation is rewarded in the examination-driven East Asian systems, reported perseverance in the post-Soviet and Balkan ones. Socio-emotional skills are neither a conveyor belt of class nor a compensating asset, but an additive input with class-neutral returns.
keywords: [socio-emotional skills, non-cognitive skills, socio-economic status, educational inequality, PISA 2025, Gelbach decomposition, transition economies]
geometry: margin=1in
fontsize: 11pt
linestretch: 1.15
numbersections: true
link-citations: true
header-includes:
  - \usepackage{booktabs}
  - \usepackage{longtable}
  - \usepackage{graphicx}
  - \usepackage{float}
  - \floatplacement{figure}{H}
  - \usepackage{caption}
  - \usepackage{pdflscape}
  - \captionsetup{font=small}
---

**JEL codes:** I24, J24, Z13

# Introduction

Two decades of research have established that socio-emotional skills — the dispositions that psychologists organise as the Big Five and that the OECD Survey on Social and Emotional Skills (SSES) re-labels as task performance, open-mindedness, emotional regulation, collaboration and engaging with others — predict schooling outcomes over and above cognitive ability (Heckman, Stixrud & Urzua, 2006; Almlund et al., 2011; Kautz et al., 2014). It is equally well established that these skills are unequally distributed by family background, and that children of educated, well-off parents enter adolescence more persistent, more curious and better able to regulate their learning than children of the poor (Farkas, 2003; Lundberg, 2013). Put together, the two findings license a claim that has become standard in policy discourse: socio-emotional skills are a *channel* through which family advantage is converted into achievement, and therefore a lever through which the class gradient of learning can be flattened.

The claim contains two propositions that are rarely separated and that have opposite implications. The first is a *mediation* proposition: part of the association between socio-economic status (SES) and achievement runs through skills, so that skills transmit advantage. The second is a *moderation* proposition: the return to skills is higher for disadvantaged children, so that skills compensate for advantage. The first is the sociological reading of the correspondence principle and of habitus — schools reward dispositions that are class-conditioned (Bowles & Gintis, 1976; Bourdieu & Passeron, 1977). The second is the economic reading of the technology of skill formation — non-cognitive inputs substitute for scarce family inputs at the bottom of the distribution (Cunha & Heckman, 2007). The empirical signatures are different: a sizeable indirect effect of SES through skills in the first case, a negative skill-by-SES interaction with a small indirect effect in the second. Most studies that use cross-national assessments test neither proposition directly. They show that adding skills to an achievement equation shrinks the SES coefficient, or that skills predict achievement within SES strata, and read the result as support for whichever framing they started from.

This paper tests both propositions on the same data and the same sample, using the 2025 cycle of the Programme for International Student Assessment (PISA). PISA 2025 is the first cycle to carry a set of socio-emotional skill scales built explicitly on the SSES taxonomy — perseverance, curiosity, enjoyment of problem-solving, stress adaptability, goal setting and self-regulated learning — alongside the standard index of economic, social and cultural status (ESCS) and, for the first time, a child-level material deprivation module. We use these instruments in twenty non-OECD education systems that share a socialist institutional legacy or a Chinese-heritage schooling tradition: five East Asian systems (Beijing–Shanghai–Jiangsu–Zhejiang, Hong Kong, Macao, Viet Nam and Mongolia), seven post-Soviet systems (Kazakhstan, Uzbekistan, Kyrgyzstan, Georgia, Azerbaijan, Moldova and Armenia) and eight post-communist systems of the Balkans and Eastern Europe (Serbia, Bulgaria, Romania, Croatia, Albania, North Macedonia, Montenegro and Kosovo). The analytic sample is 114,592 students in 9,113 schools.

Three questions structure the analysis. First, what share of the ESCS gradient in science achievement is transmitted through socio-emotional skills, and which skills carry it? We answer with the Gelbach (2016) decomposition, which attributes the change in the SES coefficient when skills are added to the model to each skill separately and, unlike sequential "add-a-mediator" comparisons, does not depend on the order in which mediators are entered. Second, are returns to skills higher for students from the bottom 40 per cent of the ESCS distribution than for students from the top 10 per cent, and higher for students who report material deprivation at a given ESCS? Third, do skills raise the *level* of achievement or the *rate* at which it is accumulated across grades — the dynamic-complementarity reading in which "skills beget skills"? We exploit the grade dispersion of PISA's age-based sample, as in value-added applications of the education production function (Avvisati & Givord, 2023), to interact each skill with grade.

The choice of systems is deliberate. The socialist school inherited a collectivist, effort-centred moral pedagogy — *vospitanie* in the Soviet tradition, *deyu* in the Chinese — that treated diligence and self-discipline as public virtues to be cultivated by the school rather than private traits brought from home. The post-1990 marketisation of schooling in the post-Soviet and Balkan systems and the high-stakes examination meritocracy of the Chinese-heritage systems have since re-coded these dispositions as individual human capital. If socio-emotional skills transmit class advantage, they should do so most where schooling has become most selective and most privately financed; if they compensate, they should do so most where the school still does the cultivating. Comparing blocs that share a legacy but differ in institutional endpoint therefore asks whether the class distribution and the return of socio-emotional skills depend on the regime of schooling rather than on national culture.

The results are clear on the first two questions and qualified on the third. Socio-emotional skills account for a small share of the ESCS gradient in science: 8 per cent in the pooled sample, between 2 and 16 per cent in nineteen of the twenty systems, and this share is carried almost entirely by curiosity. Returns to skills are, with one exception, the same for the bottom 40 per cent and the top 10 per cent of the ESCS distribution: curiosity is worth about 12 science points per standard deviation in both groups, everywhere. The exception is goal setting, whose return is positive for the disadvantaged and negative for the advantaged in the post-Soviet and post-communist blocs. Skills are neither a conveyor belt of class nor, in the main, a compensating asset: they are an independent input whose distribution is only weakly tied to SES and whose payoff is SES-neutral. We discuss what this means for the equity case for socio-emotional learning.

The paper builds on two earlier studies by the author. Avanesian (2025) estimated an education production function on PISA 2018 data for Brazil, China and Russia, finding that achievement motivation predicted reading achievement across all territories and that peer composition dwarfed most school inputs. Avanesian and Rozhkova (2025) used the OECD SSES to show that task performance and open-mindedness predicted high achievement in eight cities and that the inclusion of skills reduced the SES gap in high achievement by about two percentage points, with parallel slopes across SES groups. The present paper generalises the second finding to nationally representative samples, replaces the informal "shrinkage of the SES coefficient" with a formal decomposition, and adds the value-added and material-deprivation dimensions that neither earlier dataset allowed.

# Literature and framework

## Socio-emotional skills and achievement

The Big Five framework organises personality into openness, conscientiousness, extraversion, agreeableness and neuroticism (John & Srivastava, 1999). The OECD's SSES re-labels the five for the school context as open-mindedness, task performance, engaging with others, collaboration and emotional regulation, and decomposes each into three facets (Chernyshenko, Kankaraš & Drasgow, 2018; OECD, 2021). Across meta-analyses, conscientiousness and its facets — persistence, self-control, achievement striving — are the most consistent correlates of grades and attainment; openness, particularly its intellectual-curiosity facet, is the most consistent correlate of standardised test performance (Poropat, 2009; Richardson, Abraham & Bond, 2012). Emotional stability shows small and non-linear associations; extraversion and agreeableness show little or none. Economists have absorbed these findings into a human-capital framework in which non-cognitive skills are produced by families and schools, are malleable into adolescence, and carry wage returns of the same order as cognitive skills (Heckman, Stixrud & Urzua, 2006; Borghans et al., 2008; Heckman & Kautz, 2012).

PISA has measured selected dispositions since 2000 — motivation, self-efficacy, sense of belonging — but only in 2025 did it field scales explicitly aligned with the SSES taxonomy. Six of them are relevant here. Perseverance (persistence in the SSES) and self-regulated learning (planning, monitoring, strategy change and help-seeking) belong to task performance; curiosity and enjoyment of problem-solving belong to open-mindedness; stress adaptability — handling unusual situations, adapting under pressure — is the emotional-regulation facet closest to stress resistance; goal setting straddles task performance and self-direction. The two SSES domains that concern relations with others, engaging with others and collaboration, are not measured in PISA 2025. This narrows the taxonomy but keeps the two domains that carried the effects in earlier work.

## SES, skills and two readings of the same correlation

That socio-emotional skills are socially stratified is not in doubt. Differences in persistence, self-control and curiosity by parental education and income are visible at school entry and persist through adolescence (Farkas, 2003; Lundberg, 2013). What is in doubt is what follows from the stratification.

The reproduction reading treats skills as the medium of class transmission. In Bowles and Gintis's (1976) correspondence principle, schools reward dispositions — punctuality, perseverance, deference to task structure — that mirror the traits demanded by the capitalist labour process, and these dispositions are differentially instilled by class-specific family socialisation. Bourdieu's habitus makes a related argument in a different idiom: dispositions acquired in the family are converted by the school into certified merit, so that class inheritance appears as individual talent (Bourdieu & Passeron, 1977). In both accounts the causal chain runs SES → dispositions → achievement, and the empirical prediction is that a substantial part of the SES–achievement association is *indirect*, running through measurable dispositions.

The compensation reading treats skills as a partially independent input. In the technology of skill formation (Cunha & Heckman, 2007), non-cognitive skills raise the productivity of later investments — self-productivity and dynamic complementarity — and, because families at the bottom of the distribution under-invest in cognitive inputs, non-cognitive skills have their highest marginal return there. The resilience literature makes the same point from the other side: among disadvantaged students, those who report high persistence and self-efficacy are disproportionately represented among high achievers (OECD, 2011; Agasisti et al., 2021). The empirical prediction is a *negative interaction* between skills and SES — steeper skill gradients of achievement among the poor — and, because skills are only weakly tied to SES, a small indirect effect.

A third, dynamic reading concerns the *rate* rather than the level of learning. If skills beget skills, persistent and curious students should gain more from each additional year of schooling, so that the skill gradient of achievement widens across grades. Because PISA samples an age cohort spread across adjacent grades, the grade coefficient in an achievement equation approximates the learning gain of one school year (Avvisati & Givord, 2023; Avanesian, 2025), and its interaction with skills tests whether skills act on the gain or on the level.

## Why transition and East Asian systems

Most of the evidence on socio-emotional skills and inequality comes from the United States and Western Europe. The systems studied here share a legacy that makes them a distinctive test case. Socialist schooling was explicitly in the business of forming character. The Soviet *vospitanie* — upbringing as a curricular aim alongside instruction — and the Chinese *deyu* — moral education — assigned to the school the cultivation of diligence, collective responsibility and self-discipline, and did so for all children in a comprehensive system with weak tracking and negligible private provision. Thirty-five years later the blocs have diverged. The Chinese-heritage systems combine a residual moral pedagogy with an examination meritocracy of extraordinary intensity, in which effort is culturally coded as the route to success (Li, 2012). The post-Soviet systems of Central Asia and the Caucasus have kept a comprehensive structure but lost much of their resource base and acquired a large shadow-education sector. The post-communist systems of the Balkans have moved towards European models with earlier tracking and growing private and selective segments. If the return to, and the class distribution of, socio-emotional skills depend on institutional regime, these three blocs should differ in predictable ways: a stronger association between SES and skills where private inputs matter more, and a higher return to task-performance skills where selection is more intense.

## Hypotheses

- **H1 (mediation).** The share of the ESCS gradient in science achievement transmitted through the six skills is below 15 per cent in most systems, and largest where the SES–skill association is strongest.
- **H2 (compensation).** Returns to task-performance skills (perseverance, self-regulated learning, goal setting) are higher for the bottom 40 per cent than for the top 10 per cent of the ESCS distribution and higher for materially deprived students at a given ESCS; returns to curiosity are not.
- **H3 (level versus rate).** Skills interact positively with grade, so that they raise the learning gain per school year and not only the level of achievement.
- **H5 (institutional moderation).** Returns to task-performance skills are higher in the examination-driven East Asian systems than in the post-Soviet and post-communist systems; returns to curiosity do not differ across blocs.

(H4, the causal effect of schooling on skills, is the subject of a companion paper that uses school-entry cutoffs and is not tested here.)

# Data

## Sample

PISA 2025 assessed 15-year-old students in 91 education systems, with science as the major domain. We select the twenty non-OECD systems with a socialist legacy or Chinese-heritage schooling tradition listed in Table 1, grouped into three blocs. Ukraine participated with a partial sample and is excluded; Dushanbe (Tajikistan) and Cambodia did not field the skill scales. Two data features constrain the sample. Kazakhstan and Albania did not administer the perseverance items, so models for these systems and for pooled samples containing them omit perseverance. Macao's public-use file carries no school identifier, so Macao enters single-level models only and its school-level controls are set to the student's own values.

The analytic sample requires non-missing values on ESCS, the fielded skill scales, the control variables and the science plausible values. Coverage ranges from 98 per cent of the original sample in B-S-J-Z to 55 per cent in Bulgaria, Kosovo and North Macedonia and 20 per cent in Armenia. The skill items sit late in the student questionnaire and non-response is selective: in the Balkan and Caucasus systems students who skipped the curiosity items score 40–65 science points below respondents and are 0.05–0.20 standard deviations lower on ESCS. Armenia is therefore retained in descriptives and system-level tables but its estimates should be read as pertaining to the completing 20 per cent. Section 6 reports a robustness check that re-weights the analytic sample to the full sample on observed achievement.

```{=latex}
\begin{landscape}
```

```{=latex}
\begingroup\footnotesize
```

Table: Analytic sample by education system. EA = East Asia, PS = post-Soviet, PCE = post-communist Europe. Weighted by final student weights. Deprived = cannot afford at least one of four personal items (ST488). Macao: no school identifier in the public-use file.

| Bloc | Economy | N | Schools | % female | Modal grade | % below modal grade | % repeated | % immigrant | % other language | ESCS mean | ESCS SD | % deprived | Science mean | Science SD |
|----|--------------|-----|------|-------|----------|-----------------|---------|----------|---------------|--------|------|---------|-----------|---------|
| EA | B-S-J-Z (China) | 12171 | 374 | 48 | 10 | 43 | 4 | 0.2 | 1 | -0.52 | 1.0 | 5 | 598 | 87 |
| EA | Hong Kong | 5788 | 230 | 50 | 10 | 37 | 13 | 41.6 | 46 | -0.34 | 0.99 | 6 | 502 | 100 |
| EA | Macao | 4564 | — | 49 | 10 | 25 | 17 | 51.6 | 17 | -0.35 | 0.85 | 5 | 543 | 86 |
| EA | Mongolia | 6501 | 190 | 52 | 10 | 6 | 5 | 0.7 | 6 | -0.76 | 1.01 | 9 | 431 | 78 |
| EA | Viet Nam | 6682 | 190 | 52 | 10 | 2 | 4 | 1.1 | 5 | -0.98 | 1.11 | 17 | 463 | 79 |
| PS | Armenia | 1390 | 228 | 64 | 10 | 14 | 2 | 2.1 | 3 | -0.45 | 0.86 | 8 | 399 | 75 |
| PS | Azerbaijan | 4336 | 227 | 53 | 10 | 30 | 3 | 3.0 | 10 | -0.38 | 0.96 | 15 | 436 | 86 |
| PS | Georgia | 3975 | 261 | 55 | 10 | 30 | 4 | 1.5 | 5 | -0.29 | 0.9 | 7 | 445 | 83 |
| PS | Kazakhstan | 17569 | 641 | 52 | 9 | 1 | 3 | 7.1 | 11 | -0.33 | 0.88 | 6 | 431 | 77 |
| PS | Kyrgyzstan | 3829 | 195 | 54 | 9 | 4 | 8 | 3.5 | 32 | -0.66 | 0.93 | 11 | 383 | 68 |
| PS | Moldova | 4827 | 270 | 53 | 9 | 4 | 4 | 3.0 | 9 | -0.55 | 0.96 | 8 | 437 | 85 |
| PS | Uzbekistan | 5945 | 231 | 50 | 9 | 2 | 6 | 1.4 | 13 | -0.61 | 1.03 | 6 | 445 | 70 |
| PCE | Albania | 5013 | 160 | 54 | 10 | 31 | 2 | 0.4 | 1 | -0.61 | 1.1 | 9 | 443 | 77 |
| PCE | Bulgaria | 3765 | 207 | 53 | 9 | 3 | 4 | 2.4 | 11 | -0.1 | 0.91 | 7 | 457 | 100 |
| PCE | Croatia | 5192 | 273 | 53 | 9 | 0 | 1 | 7.8 | 2 | -0.07 | 0.82 | 2 | 491 | 90 |
| PCE | Kosovo | 3665 | 195 | 60 | 10 | 16 | 5 | 2.2 | 2 | -0.41 | 0.96 | 14 | 377 | 67 |
| PCE | Montenegro | 4681 | 68 | 52 | 10 | 10 | 1 | 7.1 | 4 | -0.28 | 0.87 | 3 | 450 | 84 |
| PCE | North Macedonia | 3859 | 120 | 57 | 10 | 2 | 4 | 3.7 | 5 | -0.16 | 0.93 | 8 | 412 | 83 |
| PCE | Romania | 6171 | 311 | 49 | 9 | 18 | 4 | 1.0 | 2 | -0.26 | 1.03 | 2 | 446 | 94 |
| PCE | Serbia | 4669 | 178 | 54 | 10 | 23 | 1 | 12.4 | 3 | -0.16 | 0.86 | 3 | 450 | 86 |

```{=latex}
\endgroup
```

```{=latex}
\end{landscape}
```

```{=latex}
\begingroup\footnotesize
```

Table: Socio-emotional skill scales in PISA 2025 and their mapping to the SSES taxonomy. All scales are OECD-standardised weighted-likelihood estimates (mean 0, SD 1 across OECD countries).

| SSES domain | Scale | PISA variable | Items (R = reversed) | Note |
|----------------------------|---------------------|-----------|---------------------------------------------------|-----------------------------|
| Task performance | Perseverance | PERSEV | ST307 (6): keep working on a task until finished; apply additional effort when work becomes challenging; finish tasks even when boring; quit homework if too long (R); finish what I start; give up easily (R) | Not fielded in KAZ, ALB |
| Task performance | Self-regulated learning | SELFREG | ST432–ST434: plan my approach to studying; summarise key points to find gaps; self-question to check understanding; change approach if unsuccessful; ask classmates/teachers/others for help; evaluate what I learned; ask for feedback |  |
| Task performance / self-direction | Goal setting | GOALSET | Goal-setting items of the self-regulated learning block |  |
| Open-mindedness | Curiosity | CURIO | ST301 (5): curious about many different things; like to know how things work; more curious than most people; find learning new things boring (R); like learning new things |  |
| Open-mindedness | Problem-solving enjoyment | ENPROBS | ST435 (4): enjoy finding solutions to problems; like situations where I have to think hard; like complicated more than simple problems; keep working on a problem even if I might not solve it |  |
| Emotional regulation | Stress adaptability | COGABIL | ST216 (4): can handle unusual situations; adapt to different situations even under stress or pressure; adapt easily to a new culture; find a way to resolve difficult situations with other people | PISA label: cognitive adaptability |

```{=latex}
\endgroup
```


## Outcome

The outcome is science achievement, the major domain of the 2025 cycle, measured by ten plausible values on the PISA scale (OECD mean 500, standard deviation 100 in 2015). Within the analytic sample the senate-weighted standard deviation is 99 points, so coefficients in PISA points can be read as hundredths of a pooled standard deviation. Mathematics and reading are used as robustness outcomes.

## Socio-emotional skills

The six scales are weighted-likelihood estimates (WLE) scaled by the OECD to a mean of zero and a standard deviation of one across OECD countries, so that a one-unit change is one OECD standard deviation and the metric is common across systems. Table 2 lists the constituent items. Perseverance (PERSEV, six items: "I keep working on a task until it is finished", "I give up easily", reversed) and self-regulated learning (SELFREG: planning, self-questioning, changing an unsuccessful approach, help-seeking) map onto SSES task performance; curiosity (CURIO: "I am curious about many different things", "I like learning new things") and enjoyment of problem-solving (ENPROBS: "I like situations where I have to think hard about something") map onto open-mindedness; stress adaptability (COGABIL: "I can adapt to different situations even when under stress or pressure") is the closest available facet of emotional regulation; goal setting (GOALSET) captures the self-direction facet of task performance. Inter-correlations range from 0.13 to 0.54 in the pooled sample, so the scales are related but distinct, and all six enter the models jointly.

## Socio-economic status and material deprivation

ESCS is the PISA index of economic, social and cultural status, combining parental education, parental occupation and home possessions. Following the earlier studies we also divide students, within each system and using final student weights, into the bottom 40 per cent, middle 50 per cent and top 10 per cent of the ESCS distribution. PISA 2025 adds a child-level material deprivation module modelled on the EU-SILC child deprivation indicator: whether the student personally has two pairs of properly fitting shoes, some new clothes, outdoor leisure equipment and indoor games, with the response "No, cannot afford it" distinguished from "No, other reason". We code a student as materially deprived if she cannot afford at least one of the four items. Between 2 and 17 per cent of students in the analytic samples are deprived by this definition, and deprivation is concentrated but far from confined in the bottom ESCS group: 14 per cent of bottom-40 students in East Asia are deprived against 2 per cent of top-10 students. Because ESCS is a relative index of cultural and material resources while the deprivation items measure absolute hardship, the two allow a contrast between students at the same ESCS who do and do not experience hardship.

## Controls

Student controls are sex, age in years, grade relative to the modal grade in the system, grade repetition, immigrant background (student or at least one parent born abroad) and speaking a language other than the test language at home. School controls, following Avanesian (2025), are the leave-one-out school mean of ESCS computed on the full national sample before any listwise deletion, a private-school indicator and a three-category community size (rural or small town; town; city or larger). School mean ESCS is the peer-composition variable that dominated the earlier production-function estimates; including it means that the ESCS coefficient in our main models measures the *within-school* family gradient. We report the total gradient, without school controls, alongside it.

# Empirical strategy

## Decomposing the ESCS gradient

Let $Y_{ij}$ be the science score of student $i$ in school $j$, $E_{ij}$ her ESCS, $S_{kij}$ her score on skill $k$ and $X_{ij}$ the vector of controls. The base and full models are

$$Y_{ij} = \alpha_0 + \beta_{\text{base}} E_{ij} + X_{ij}'\delta_0 + \varepsilon_{ij}, \qquad
Y_{ij} = \alpha_1 + \beta_{\text{full}} E_{ij} + \sum_k \gamma_k S_{kij} + X_{ij}'\delta_1 + \nu_{ij}.$$

The Gelbach (2016) decomposition uses the omitted-variable-bias formula to write the change in the ESCS coefficient as an exact sum of skill-specific contributions,

$$\beta_{\text{base}} - \beta_{\text{full}} = \sum_k \gamma_k \pi_k,$$

where $\pi_k$ is the ESCS coefficient from the auxiliary regression of skill $k$ on ESCS and the same controls. The term $\gamma_k \pi_k$ is the part of the gradient that runs through skill $k$ — the product of how strongly SES predicts the skill and how strongly the skill predicts achievement holding the other skills constant — and the identity is exact for least squares on an identical sample, so the contributions do not depend on the order in which skills are considered. We report each contribution in science points per ESCS unit and as a share of $\beta_{\text{base}}$. The decomposition is a description of conditional associations; it identifies mediation only under the assumption that no unmeasured variable drives both skills and achievement conditional on SES and controls, and we interpret it accordingly.

## Moderation by SES and by deprivation

To test H2 we add to the full model interactions between each skill and the ESCS group,

$$Y_{ij} = \alpha + \sum_g \theta_g G_{gij} + \sum_k \gamma_k S_{kij} + \sum_k \sum_g \lambda_{kg} S_{kij} G_{gij} + \beta E_{ij} + X_{ij}'\delta + \nu_{ij},$$

with the top 10 per cent as reference, so that $\gamma_k$ is the return to skill $k$ for the most advantaged students and $\lambda_{k,\text{B40}}$ the difference in return for the bottom 40 per cent. Compensation predicts $\lambda_{k,\text{B40}} > 0$; cumulative advantage predicts $\lambda_{k,\text{B40}} < 0$. The same specification with the deprivation indicator in place of the ESCS group, and ESCS retained as a continuous control, tests whether returns differ for materially deprived students at a given ESCS. A Gelbach decomposition of the deprivation coefficient asks whether the achievement penalty of hardship at given ESCS runs through skills.

## Level versus rate

To test H3 we interact each skill with grade relative to the modal grade,

$$Y_{ij} = \alpha + \rho\, \text{grade}_{ij} + \sum_k \gamma_k S_{kij} + \sum_k \phi_k S_{kij}\,\text{grade}_{ij} + \beta E_{ij} + X_{ij}'\delta + \nu_{ij},$$

where $\rho$ is the learning gain of one school year for a student with average skills and $\phi_k$ the additional gain per standard deviation of skill $k$. Age is held constant, so grade variation comes from school-entry timing and grade repetition rather than from age; repetition is controlled separately. The test is informative only where grades are dispersed, which is the case in the East Asian and Caucasus systems (25–43 per cent of students below the modal grade in B-S-J-Z, Hong Kong, Georgia, Azerbaijan and Mongolia) and much less so in the Central Asian and Balkan systems.

## Bloc comparison

H5 is tested in the pooled sample with system fixed effects, senate weights that give each system equal total weight, and interactions between each skill and bloc.

## Estimation and inference

All models are estimated by weighted least squares with final student weights within systems and senate weights in pooled samples. Standard errors follow the PISA convention: sampling variance from Fay's balanced repeated replication with the 80 replicate weights (computed on the first plausible value), and imputation variance from the ten plausible values combined by Rubin's rules. This accounts for the two-stage sample design and the measurement error in achievement without model-based assumptions about the school-level variance. Per-system models are run for each of the twenty systems; bloc and pooled models add system fixed effects. Skills enter in their OECD-anchored metric so that coefficients are comparable across systems; a robustness check re-standardises them within system.

# Results

![Weighted correlations of the six skills with science achievement, by system.](outputs/figures/f1_skill_science_corr.png){#fig:corr width=100%}

## Skills are stratified by SES, but weakly

```{=latex}
\begingroup\footnotesize
```

Table: Socio-economic gradients of skills and of achievement: coefficient on ESCS (per unit) from weighted regressions with student controls, no school controls; skills in OECD SD units. Standard errors (BRR + PV) in parentheses. Perseverance omitted from pooled units containing Kazakhstan or Albania.

| Unit | Perseverance | Self-regulated learning | Goal setting | Curiosity | Problem-solving enjoyment | Stress adaptability | Science (points) |
|---------------------|-------------|-----------------------|-------------|-------------|------------------------|-------------------|----------------|
| East Asia | 0.067 (0.006) | 0.064 (0.007) | 0.123 (0.007) | 0.100 (0.008) | 0.088 (0.006) | 0.119 (0.007) | 24.7 (0.9) |
| Post-Soviet | — | 0.051 (0.021) | 0.147 (0.012) | 0.130 (0.012) | 0.132 (0.011) | 0.118 (0.012) | 18.5 (0.6) |
| Post-communist Europe | — | 0.029 (0.011) | 0.116 (0.007) | 0.103 (0.007) | 0.099 (0.007) | 0.125 (0.007) | 28.7 (1.1) |
| All 20 economies | — | 0.047 (0.014) | 0.126 (0.004) | 0.109 (0.004) | 0.103 (0.005) | 0.120 (0.006) | 24.5 (1.0) |

```{=latex}
\endgroup
```

Table 3 reports the gradient of each skill with respect to ESCS — the auxiliary coefficient $\pi_k$ of the decomposition — alongside the achievement gradient. Across the pooled sample a one-unit increase in ESCS is associated with 0.11 OECD standard deviations more curiosity, 0.12 more stress adaptability and 0.05 more self-regulated learning; the corresponding figure for science achievement is 24.5 points, a quarter of a standard deviation. The socio-economic gradient of skills is therefore about half as steep as that of achievement in standardised units, and it is remarkably uniform: for curiosity, enjoyment of problem-solving, goal setting, stress adaptability and perseverance the gradients fall between 0.03 and 0.20 in all twenty systems, with Viet Nam (0.03–0.07) at the flat end and B-S-J-Z, Uzbekistan and Romania (0.14–0.20) at the steep end; self-regulated learning is essentially unstratified (−0.07 to 0.14). Expressed as group differences, students in the top 10 per cent of the ESCS distribution score 0.3–0.5 standard deviations above students in the bottom 40 per cent on curiosity, goal setting, enjoyment of problem-solving and stress adaptability, and 0.1–0.4 above them on perseverance and self-regulated learning (Table 9 in the Appendix). The ordering matches Farkas's (2003) and Lundberg's (2013) findings for the United States: the open-mindedness and self-direction dispositions are more class-stratified than persistence itself.

## H1: skills transmit a small share of the ESCS gradient

![Share of the ESCS gradient in science explained by the six skills, by system and bloc (Gelbach decomposition; 95% CI). Uzbekistan's wide interval reflects its flat gradient.](outputs/figures/f2_gelbach_share.png){#fig:share width=90%}

```{=latex}
\begin{landscape}
```

```{=latex}
\begingroup\footnotesize
```

Table: Gelbach decomposition of the ESCS gradient in science. Base model: ESCS and student controls; full model adds the six skills. "Explained" = beta_base − beta_full = Σ gamma_k pi_k. Skill columns give each skill's contribution as a percentage of the base gradient (they sum, with problem-solving enjoyment and goal setting, to the total). Bloc and pooled models include system fixed effects and senate weights.

| System | N | ESCS gradient, base | ESCS gradient, with skills | Explained (points) | Explained (%) | of which curiosity (%) | Perseverance (%) | Self-reg. learning (%) | Stress adapt. (%) |
|----------------|-----|---------------|--------------------|--------------|----------|-----------------|------------|-----------------|-------------|
| B-S-J-Z (China) | 12171 | 24.8 (1.7) | 21.8 (1.6) | 3.0 (0.4) | 12.1 (1.6) | 4.3 | -4.5 | 6.5 | 2.2 |
| Hong Kong | 5788 | 24.6 (2.1) | 23.0 (2.2) | 1.5 (0.4) | 6.3 (1.8) | 6.8 | -0.3 | 1.1 | 0.8 |
| Macao | 4564 | 18.8 (1.5) | 16.5 (1.5) | 2.3 (0.4) | 12.3 (2.2) | 7.2 | -0.9 | 2.0 | 4.6 |
| Viet Nam | 6682 | 26.3 (1.8) | 25.9 (1.8) | 0.4 (0.2) | 1.6 (0.7) | 2.8 | 0.2 | 0.3 | -1.1 |
| Mongolia | 6501 | 24.9 (1.5) | 24.1 (1.5) | 0.8 (0.2) | 3.1 (0.7) | 1.9 | 0.4 | 1.6 | 0.3 |
| Kazakhstan | 17569 | 17.0 (1.1) | 14.8 (1.1) | 2.3 (0.3) | 13.3 (1.8) | 13.9 |  | 1.4 | 1.3 |
| Uzbekistan | 5945 | 7.2 (1.7) | 4.5 (1.6) | 2.6 (0.4) | 37.2 (9.2) | 13.6 | 9.7 | 5.3 | 1.7 |
| Kyrgyzstan | 3829 | 17.4 (1.6) | 16.3 (1.5) | 1.1 (0.3) | 6.2 (1.7) | 3.7 | 3.8 | -0.1 | 2.7 |
| Georgia | 3975 | 18.5 (2.1) | 16.0 (2.0) | 2.5 (0.5) | 13.4 (2.6) | 7.7 | 3.0 | 0.1 | 0.7 |
| Azerbaijan | 4336 | 22.2 (2.0) | 19.2 (1.8) | 3.0 (0.5) | 13.6 (1.8) | 5.4 | 1.6 | 1.8 | 2.0 |
| Moldova | 4827 | 27.9 (1.5) | 25.2 (1.5) | 2.6 (0.4) | 9.5 (1.6) | 5.2 | 3.1 | -0.3 | 2.1 |
| Armenia | 1390 | 17.4 (2.6) | 15.9 (2.4) | 1.5 (0.8) | 8.4 (4.3) | 6.1 | 2.8 | -2.7 | 0.4 |
| Serbia | 4669 | 31.4 (2.0) | 29.0 (2.0) | 2.5 (0.5) | 7.9 (1.5) | 5.6 | 1.2 | -0.1 | 0.0 |
| Bulgaria | 3765 | 33.7 (2.9) | 30.4 (2.8) | 3.3 (0.7) | 9.7 (2.0) | 9.5 | 0.0 | -0.1 | 1.0 |
| Romania | 6171 | 38.6 (2.1) | 35.5 (2.0) | 3.1 (0.4) | 8.0 (0.9) | 7.9 | -0.7 | -0.9 | 1.8 |
| Croatia | 5192 | 37.9 (2.0) | 35.7 (1.9) | 2.2 (0.4) | 5.8 (1.0) | 2.7 | 0.2 | -0.2 | 1.2 |
| Albania | 5013 | 21.3 (1.6) | 19.3 (1.6) | 2.0 (0.3) | 9.5 (1.6) | 3.3 |  | 1.3 | 3.5 |
| North Macedonia | 3859 | 20.3 (1.5) | 18.4 (1.5) | 1.9 (0.5) | 9.3 (2.4) | 3.1 | 2.9 | -0.5 | 3.3 |
| Montenegro | 4681 | 27.6 (1.6) | 25.4 (1.7) | 2.1 (0.3) | 7.8 (1.3) | 4.5 | 2.8 | -0.1 | 0.5 |
| Kosovo | 3665 | 17.3 (1.4) | 14.6 (1.3) | 2.7 (0.4) | 15.6 (2.5) | 5.1 | 8.1 | 0.0 | 2.7 |
| East Asia | 35706 | 24.7 (0.9) | 23.3 (0.9) | 1.4 (0.1) | 5.7 (0.6) | 4.5 | -0.3 | 1.8 | 0.3 |
| Post-Soviet | 41871 | 18.5 (0.6) | 16.3 (0.6) | 2.2 (0.2) | 11.8 (0.9) | 8.6 |  | 0.5 | 1.9 |
| Post-communist Europe | 37015 | 28.7 (1.1) | 26.4 (1.0) | 2.3 (0.2) | 8.0 (0.6) | 5.4 |  | -0.1 | 1.6 |
| All 20 economies | 114592 | 24.5 (1.0) | 22.6 (1.1) | 1.9 (0.1) | 7.9 (0.7) | 5.8 |  | 0.4 | 1.2 |

```{=latex}
\endgroup
```

```{=latex}
\end{landscape}
```

Figure 2 and Table 4 give the Gelbach decomposition. In the pooled sample the total ESCS gradient in science is 24.5 points (SE 1.0) before and 22.6 points (1.1) after the six skills are added. The 1.9 points that the skills absorb are 7.9 per cent of the gradient (SE 0.7), and 1.4 of those 1.9 points — 5.8 percentage points of the 7.9 — run through curiosity alone. Stress adaptability contributes a further 1.2 percentage points; enjoyment of problem-solving, goal setting and self-regulated learning contribute less than half a point each.

The system-level estimates are tightly clustered. In nineteen of the twenty systems the explained share lies between 1.6 per cent (Viet Nam) and 15.6 per cent (Kosovo), with a median of 9.3 per cent; only Uzbekistan, where the total ESCS gradient is an unusually flat 7.2 points, shows a large share (37 per cent, SE 9) because a small absolute contribution (2.6 points) is divided by a small denominator. By bloc the share is 5.7 per cent in East Asia, 11.8 per cent in the post-Soviet systems and 8.0 per cent in post-communist Europe. The post-Soviet figure is higher because the achievement gradient there is flatter (18.5 points against 24.7 and 28.7) while the skill gradients are not, not because skills are more strongly rewarded.

Two features of the decomposition deserve emphasis. First, the contribution of curiosity is positive in every system, statistically significant in nineteen of the twenty, and the largest of the six in fifteen. Curiosity is both the most class-stratified disposition and the one with the largest conditional return (13.1 points per standard deviation in the pooled model, Table 5), and the product of the two is what the decomposition measures. Second, the contribution of perseverance is *negative* in B-S-J-Z (−4.5 percentage points) and negligible elsewhere in East Asia. The negative sign arises because, conditional on curiosity and self-regulated learning, self-reported perseverance carries a negative coefficient in B-S-J-Z (−11.4 points per standard deviation, SE 1.7): among students of equal curiosity and equal metacognitive skill, those who report working harder score lower. We return to this below.

When the leave-one-out school mean of ESCS, school type and community size are added, the ESCS coefficient becomes a within-school family gradient and shrinks to 9.8 points in the pooled sample. Skills now account for 15.6 per cent of it (SE 0.9; Table 10 in the Appendix), with system-level shares from 2 to 35 per cent. The absolute contribution of skills is almost unchanged (1.5 against 1.9 points); what changes is the denominator. Peer composition — the between-school part of the gradient that the 2018 production-function estimates identified as the dominant channel of inequality — is not mediated by individual skills at all in this specification, because the skill gradients themselves are computed net of school composition.

H1 is therefore supported in its first clause and qualified in its second. The share transmitted through skills is below 15 per cent in all but one system; but it is largest not where the SES–skill association is strongest (B-S-J-Z, Romania) but where the SES–achievement association is weakest (Uzbekistan, Kosovo, Bulgaria, Azerbaijan). Socio-emotional skills are a minor conduit of family advantage, and their importance as a conduit is a function of how little else transmits it.

## H2: returns to skills are the same for the poor and the rich

![Returns to skills for the bottom 40% and top 10% of the ESCS distribution, by bloc (science points per SD; 95% CI).](outputs/figures/f4_returns_by_escs_group.png){#fig:groups width=100%}

![Difference in returns, bottom 40% minus top 10%, by system and skill (95% CI).](outputs/figures/f4b_return_gap_by_economy.png){#fig:gap width=100%}

```{=latex}
\begingroup\footnotesize
```

Table: Returns to skills by ESCS group: science points per OECD SD of skill, from the model with skill × ESCS-group interactions, ESCS, student and school controls. Stars on the difference: * p<0.10, ** p<0.05, *** p<0.01.

| Unit | Skill | Bottom 40% | Top 10% | Difference (B40 − T10) |
|---------------------------------|----------------------------------------|----------------|----------------|-----------------------------------|
| East Asia | Perseverance | -1.2 (1.1) | -3.3 (2.2) | 2.1 (2.6) |
| East Asia | Self-regulated learning | 7.9 (0.9) | 5.7 (1.8) | 2.1 (1.9) |
| East Asia | Goal setting | -2.1 (1.1) | 0.0 (2.2) | -2.2 (2.4) |
| East Asia | Curiosity | 11.2 (0.9) | 9.1 (2.1) | 2.1 (2.2) |
| East Asia | Problem-solving enjoyment | -1.7 (1.3) | 2.8 (2.3) | -4.5* (2.7) |
| East Asia | Stress adaptability | 1.7 (0.9) | -1.9 (1.7) | 3.5* (1.9) |
| Post-Soviet | Self-regulated learning | 1.6 (1.3) | 1.7 (2.2) | -0.1 (3.1) |
| Post-Soviet | Goal setting | 1.5 (1.2) | -4.7 (1.7) | 6.2*** (2.2) |
| Post-Soviet | Curiosity | 12.6 (0.9) | 11.8 (1.7) | 0.8 (1.7) |
| Post-Soviet | Problem-solving enjoyment | 2.6 (1.2) | 2.7 (1.9) | -0.1 (2.1) |
| Post-Soviet | Stress adaptability | 2.9 (0.9) | 1.9 (2.6) | 1.0 (2.3) |
| Post-communist Europe | Self-regulated learning | -0.4 (0.8) | 0.1 (1.3) | -0.5 (1.6) |
| Post-communist Europe | Goal setting | 3.3 (1.0) | -2.5 (1.5) | 5.8*** (1.9) |
| Post-communist Europe | Curiosity | 13.5 (0.8) | 13.9 (1.8) | -0.4 (2.0) |
| Post-communist Europe | Problem-solving enjoyment | 0.1 (1.0) | 1.9 (1.7) | -1.8 (1.9) |
| Post-communist Europe | Stress adaptability | 2.8 (0.8) | 3.0 (1.3) | -0.2 (1.6) |
| All 20 economies | Self-regulated learning | 3.0 (0.9) | 1.4 (1.2) | 1.6* (1.0) |
| All 20 economies | Goal setting | 0.3 (0.7) | -2.1 (1.5) | 2.5 (1.8) |
| All 20 economies | Curiosity | 12.6 (0.8) | 12.4 (1.0) | 0.2 (1.2) |
| All 20 economies | Problem-solving enjoyment | 1.1 (0.8) | 1.1 (1.7) | 0.0 (1.5) |
| All 20 economies | Stress adaptability | 1.8 (0.6) | 1.9 (1.5) | -0.1 (1.3) |

```{=latex}
\endgroup
```

Table 5 reports the return to each skill for students in the top 10 per cent and the bottom 40 per cent of their system's ESCS distribution, from the interaction model, and Figure 3 plots them by bloc. The two sets of returns are almost identical. In the pooled sample a standard deviation of curiosity is worth 12.6 points (SE 0.8) to a bottom-40 student and 12.4 points (1.0) to a top-10 student; the difference is 0.2 points (SE 1.2). Stress adaptability returns 1.8 against 1.9 points; enjoyment of problem-solving 1.1 against 1.1; self-regulated learning 3.0 against 1.4 (difference 1.6, SE 1.0). Across the twenty systems and six skills, the bottom-40 return exceeds the top-10 return significantly in only two cases and falls short of it in only two (Figure 4); the remaining 114 differences are indistinguishable from zero. The slopes are parallel.

The exception is goal setting. In the pooled sample its return is 0.3 points for the bottom 40 per cent and −2.2 points for the top 10 per cent (difference 2.5, SE 1.8); in the post-Soviet bloc the figures are 1.5 and −4.7 (difference 6.2, SE 2.2) and in post-communist Europe 3.3 and −2.5 (difference 5.8, SE 1.9). Among advantaged students, reporting that one sets goals and plans one's learning is unrelated or negatively related to science performance; among disadvantaged students it is mildly positive. This is the single compensatory pattern in the data, and it is confined to a self-direction disposition rather than to persistence or self-regulation, the skills the compensation literature emphasises.

```{=latex}
\begingroup\footnotesize
```

Table: Material deprivation at a given ESCS. Penalty = coefficient on the deprivation indicator (science points) with ESCS, student and school controls, before and after adding skills; "× skill" = difference in the return to the skill for deprived versus non-deprived students. Stars as in Table 5.

| Unit | Penalty at given ESCS | Penalty, skills added | × Perseverance | × Self-regulated learning | × Goal setting | × Curiosity | × Problem-solving enjoyment | × Stress adaptability |
|-----------------|-----------------|-----------------|-----------|--------------------|-----------|---------|----------------------|-----------------|
| East Asia | -25.8 (1.9) | -24.4 (1.9) | 3.9 (2.4) | -1.1 (1.9) | -3.3 (2.3) | 1.4 (2.0) | 3.1 (2.0) | -0.5 (1.9) |
| Post-Soviet | -26.9 (1.9) | -24.1 (1.9) | — | 0.3 (2.8) | 4.3* (2.2) | 3.8* (2.1) | -2.1 (2.7) | 0.1 (2.3) |
| Post-communist Europe | -27.9 (2.8) | -24.5 (2.5) | — | 7.1*** (2.3) | -1.5 (2.7) | 1.0 (2.5) | 0.2 (2.2) | 0.5 (2.1) |
| All 20 economies | -26.8 (1.4) | -24.2 (1.1) | — | 2.7** (1.2) | -0.8 (1.8) | 2.2* (1.3) | 0.9 (2.0) | 0.1 (1.3) |

```{=latex}
\endgroup
```

The material-deprivation contrast (Table 6) sharpens the point. At a given ESCS, a student who cannot afford at least one of four basic personal items scores 26.8 points lower (SE 1.4) in the pooled sample — a quarter of a standard deviation, and as large as the effect of a full unit of ESCS. The penalty is remarkably stable across blocs (25.8, 26.9 and 27.9 points) and lies between 16 and 49 points in every system. Adding the six skills reduces it to 24.2 points: skills absorb 10 per cent of the hardship penalty, about the same share as of the ESCS gradient. Returns to skills for deprived students are not higher than for the non-deprived in the pooled sample (differences of 0.1 to 2.7 points, none significant at conventional levels), with one bloc-specific exception: in post-communist Europe self-regulated learning returns 7.1 points more (SE 2.3) to deprived than to non-deprived students, where it otherwise returns nothing.

H2 is rejected for perseverance, self-regulated learning and curiosity, and supported only for goal setting in the two European blocs. Skills are neither a substitute for family resources nor a complement to them; they are an additive input whose payoff does not depend on class position.

## H3: skills raise the level of achievement, not its rate of accumulation

![Skill × grade interactions by system, restricted sample (95% CI).](outputs/figures/f5_skill_x_grade.png){#fig:grade width=100%}

```{=latex}
\begingroup\footnotesize
```

Table: Level versus rate: grade coefficient and skill × grade interactions, restricted sample (systems with ≥10% of students below the modal grade; students in the modal grade or one below). Controls as in the full model, including age. Bloc units contain only the restricted systems (East Asia: B-S-J-Z, Hong Kong, Macao; post-Soviet: Georgia, Azerbaijan, Armenia; post-communist Europe: Serbia, Romania, Albania, Kosovo, Montenegro).

| Unit | Grade (points per year) | Grade × Perseverance | Grade × Self-regulated learning | Grade × Goal setting | Grade × Curiosity | Grade × Problem-solving enjoyment | Grade × Stress adaptability |
|---------------|-----------------|---------------|-----------------------|---------------|------------|------------------------|--------------------|
| East Asia | 19.9 (2.3) | -0.6 (2.5) | 1.8 (1.7) | -0.9 (2.3) | 1.8 (2.0) | 2.9 (2.8) | -1.6 (1.8) |
| Post-Soviet | 6.4 (6.5) | -2.8 (2.4) | -1.1 (3.2) | -2.2 (2.9) | -1.7 (3.1) | 7.2*** (2.2) | -2.5 (2.1) |
| Post-communist Europe | 2.6 (2.6) | — | 0.6 (1.8) | 1.4 (1.7) | 3.0* (1.7) | -0.0 (1.9) | -0.2 (1.5) |
| All 20 economies | 9.9 (4.6) | — | 0.4 (1.3) | -1.5 (1.2) | 1.5 (2.0) | 3.8* (1.9) | -1.5 (1.2) |

```{=latex}
\endgroup
```

Table 7 reports the grade coefficient — the learning gain of one school year for a student with average skills — and its interactions with the skills, first in the full sample and then in the restricted sample of eleven systems in which at least 10 per cent of students are one grade below the modal grade and grade dispersion is driven by school-entry timing rather than by programme selection. In the East Asian systems a grade is worth 19–24 points, in line with the 2018 estimates for the same territories; in the post-Soviet and Balkan systems, where almost all 15-year-olds are in the modal grade, the coefficient is poorly identified.

The skill × grade interactions are small and inconsistent. In the pooled restricted sample the additional gain per grade per standard deviation of skill is 1.5 points for curiosity (SE 2.0), −1.5 for perseverance (1.2), 0.4 for self-regulated learning (1.3) and −1.5 for stress adaptability (1.3); only enjoyment of problem-solving is positive at conventional significance (3.8, SE 1.9; 2.5 with SE 0.8 in the unrestricted pooled model), and it is driven by the post-Soviet systems (7.2, SE 2.2). In the East Asian bloc, where the grade coefficient is best identified, no interaction exceeds three points or twice its standard error. Persistent, curious and self-regulated students score higher at every grade, but they do not pull further ahead between grades 9 and 10. H3 is not supported except, weakly, for the intellectual-engagement disposition, and we read the result as evidence that the association between skills and achievement at age 15 is mostly formed before lower-secondary school.

## H5: institutional regime changes which skills pay, not how much skills pay

![Conditional returns to skills by system (science points per SD; all six skills, ESCS and student controls; 95% CI).](outputs/figures/f6_returns_by_economy.png){#fig:returns width=100%}

```{=latex}
\begingroup\footnotesize
```

Table: Returns to skills by bloc (science points per OECD SD; bloc models with system fixed effects and senate weights) and tests of bloc differences from the pooled model with bloc × skill interactions. Perseverance contrasts from the pooled model excluding Kazakhstan and Albania; the post-Soviet and European bloc means for perseverance therefore come from systems that fielded it. Stars as in Table 5.

| Skill | East Asia | Post-Soviet | Post-communist Europe | Post-Soviet − East Asia | Post-communist Europe − East Asia |
|----------------------------|-----------|-------------|------------------------|--------------------------|--------------------------------------|
| Perseverance | -1.3 (0.8) |  |  | 6.6*** (1.0) | 4.6*** (0.8) |
| Self-regulated learning | 7.0 (0.5) | 1.7 (1.1) | -1.0 (0.6) | -5.0*** (1.1) | -7.7*** (0.7) |
| Goal setting | -0.8 (0.7) | -1.6 (0.8) | 3.0 (0.8) | 0.2 (0.9) | 5.0*** (0.9) |
| Curiosity | 11.2 (0.7) | 12.2 (0.7) | 15.1 (0.7) | 1.5 (1.0) | 4.0*** (0.9) |
| Problem-solving enjoyment | -0.7 (0.7) | 3.0 (1.4) | -0.7 (0.6) | 2.8** (1.2) | 0.4 (0.8) |
| Stress adaptability | 0.7 (0.6) | 2.9 (0.5) | 3.7 (0.5) | 1.9** (0.9) | 3.4*** (0.8) |

```{=latex}
\endgroup
```

Figure 6 plots the conditional return to each skill by system and Table 8 tests bloc differences in the pooled model. The aggregate return to skills — the sum of the six coefficients for a student one standard deviation above the mean on every skill — is similar across blocs, at 16–20 points. Its composition is not.

Curiosity pays everywhere, but more in Europe: 11.2 points per standard deviation in East Asia, 12.2 in the post-Soviet systems and 15.1 in post-communist Europe (difference from East Asia 4.0, SE 0.9). Self-regulated learning — planning, monitoring, changing strategy, seeking help — is the second most valuable skill in East Asia (7.0 points; 11.4 in B-S-J-Z, 9.7 in Hong Kong, 7.1 in Macao) and worthless or negative elsewhere (1.7 in the post-Soviet bloc, −1.0 in post-communist Europe; differences −5.0 and −7.7, SE 1.1 and 0.7). Perseverance shows the mirror image: 5.6 points in the post-Soviet systems and 3.7 in post-communist Europe, where it is positive in eleven of the thirteen systems that fielded it (nil in Bulgaria, negative in Romania), against −1.3 in East Asia, where it is negative in B-S-J-Z, Hong Kong and Macao and indistinguishable from zero in Viet Nam and Mongolia. Goal setting pays in post-communist Europe (3.1) and not in the other blocs; stress adaptability pays modestly in Europe and the post-Soviet systems (3.7, 2.9) and not in East Asia (0.7), where Viet Nam shows a negative coefficient.

H5 predicted that task-performance skills would carry higher returns in the examination-driven East Asian systems. The prediction holds for the metacognitive component of task performance and fails for the effort component. Where selection is intense and effort is universal, reported effort no longer distinguishes students — what does is how strategically the effort is deployed. Where selection is weaker and average effort lower, persistence itself is scarce and rewarded. This is a substitution within the task-performance domain, not a difference in the overall importance of socio-emotional skills.

## Robustness

Table 11 in the Appendix repeats the pooled and bloc decompositions with mathematics and reading as outcomes, with skills standardised within system rather than on the OECD scale, and with the analytic sample re-weighted to the full sample on the inverse probability of completing the skill items (estimated within system from science score, sex, grade and age). The explained share of the ESCS gradient is 6.5 per cent for mathematics and 8.1 per cent for reading against 7.9 per cent for science in the pooled sample, 7.8 per cent with within-system standardised skills and 8.6 per cent after re-weighting for non-response; curiosity carries 4.7–6.8 percentage points of it in every specification, and the bloc ordering (post-Soviet highest, East Asia lowest) is preserved throughout. The conditional return to curiosity lies between 11.3 and 14.3 points per standard deviation across outcomes, and the East Asian pattern — a high return to self-regulated learning (6.8–7.3 points) and a zero or negative return to perseverance (−0.8 to −2.0) — is present for all three domains. Nothing in the paper's conclusions depends on the choice of outcome, on the skill metric or on the treatment of item non-response.

# Discussion

## Neither conveyor belt nor compensating asset

The two readings of the skills–SES–achievement triangle that motivated this paper make opposite predictions, and the data reject both in their strong form. The reproduction reading predicts that a substantial part of the class gradient in achievement is carried by class-conditioned dispositions. In twenty systems with a shared tradition of character-forming schooling, six dispositions that between them cover most of the SSES task-performance and open-mindedness domains carry 8 per cent of the ESCS gradient, and one disposition — curiosity — carries three-quarters of that. The compensation reading predicts that the return to dispositions is highest where family inputs are scarcest. The return to curiosity, perseverance, self-regulated learning and stress adaptability is the same to within a point or two for the poorest 40 per cent and the richest 10 per cent of students in every bloc, and the same for students who cannot afford basic personal items as for those who can. The only compensatory pattern involves goal setting, and it arises because the skill has a negative return among the advantaged rather than a large positive one among the disadvantaged.

What the data support is a third, less dramatic reading. Socio-emotional skills are an input to learning whose class distribution is much flatter than that of achievement and whose payoff is class-neutral. Mechanically, this is why the mediated share is small: a class gradient of 0.1 standard deviations per ESCS unit in a skill worth 13 points per standard deviation yields 1.3 points, against a total gradient of 24. Substantively, it means that the skills are not the mechanism of reproduction that the correspondence principle describes. Whatever schools reward in the children of the advantaged, it is not, in the main, that they are more curious or more persistent than the children of the poor — they are only slightly so — but that they arrive with more of what ESCS measures directly: parental education, books, a quiet place to study, and the peer composition of the schools those resources buy. The 2018 production-function estimates for the same East Asian territories placed a standard deviation of school-mean ESCS at between one and three and a half years of schooling; the present estimates place a standard deviation of curiosity at about two-thirds of one.

The finding is consistent with the two earlier studies on which this paper builds and extends them in a specific way. Avanesian and Rozhkova (2025) found in the SSES data that adding skills reduced the effect of bottom-40 status on high achievement from 12.5 to 10.7 percentage points — a 14 per cent reduction — and that the skill slopes were parallel across SES groups, differing only in intercept. The Gelbach decomposition reproduces the parallel slopes on nationally representative samples and puts the reduction at 8 per cent of the continuous gradient, or 16 per cent of the within-school gradient, with a formal attribution to individual skills that the earlier informal comparison could not give. It also shows that the earlier finding on task performance and open-mindedness was, in effect, a finding about open-mindedness: curiosity does the work that the SSES composite "task performance" and "open-mindedness" shared.

## What the equity case for socio-emotional learning can and cannot rest on

The result has a direct bearing on how socio-emotional learning is justified in policy. The strong equity case — that fostering these skills will close class gaps because the skills mediate them — is not supported: closing the entire class gap in the six skills would close about 8 per cent of the class gap in science, or 16 per cent of the gap between classmates. The compensatory case — that skills matter more for the poor — is not supported either, except for goal setting in the European blocs. What remains is a weaker but not trivial case. Because returns are class-neutral, a disadvantaged student who gains a standard deviation of curiosity gains as much as an advantaged one, roughly 13 points; because deprivation costs 27 points at a given ESCS and skills absorb a tenth of it, skills are one of several partial offsets to hardship rather than a substitute for addressing it. Socio-emotional learning, on these estimates, is a general productivity input that benefits all students about equally, and an equity intervention only in the sense that any equal benefit is worth more, in relative terms, to those who have less.

## Effort where effort is universal

The bloc contrasts add a finding that neither reading anticipates and that speaks to the institutional argument of Section 2.3. In the three Chinese-heritage systems the conditional return to self-reported perseverance is zero or negative — strongly negative in B-S-J-Z — while the return to self-regulated learning is the highest in the sample. In the post-Soviet and Balkan systems the pattern is reversed: perseverance pays in every system, self-regulated learning in none. Three mechanisms could produce this. The first is reference bias: in systems where effort norms are high, students who report exceptional persistence relative to those norms may be those for whom learning is difficult, so that self-reported effort proxies for low ability once curiosity is held constant (West et al., 2016). The second is ceiling: where effort is near-universal, its marginal return is low and what differentiates students is how effort is allocated — planning, monitoring, changing strategy — which is what the self-regulation scale measures. The third is a genuine institutional difference in what is rewarded: an examination system that tests reasoning under time pressure may reward metacognition, while systems with weaker external assessment reward time on task. The three are not mutually exclusive, and the data cannot separate them. They agree, however, on the implication that "task performance" is not a single quantity with a single return, and that the effort component and the strategic component of it are substitutes whose relative value depends on the schooling regime. For the socialist-legacy systems this is a specific version of a general point: the character-forming pedagogy they inherited valued diligence; the examination meritocracy the East Asian systems have built on it rewards something else.

## Level, not rate

The absence of skill × grade interactions is, we think, the most policy-relevant null result in the paper. If skills raised the rate of learning, their class gradient — small at 15 — would compound across schooling and the mediated share would grow; the case for early socio-emotional intervention would then rest on dynamic complementarity. What the data show, in the systems where grade dispersion allows the test, is that persistent, curious and self-regulated students are ahead at every grade by a constant amount. The skill–achievement association observed at 15 has already been formed, most plausibly in primary school and at home, and lower-secondary schooling neither widens nor narrows it. This is consistent with evidence that non-cognitive skills are most malleable before adolescence (Cunha & Heckman, 2007; Kautz et al., 2014) and shifts the locus of any intervention downward in age.

## Limitations

Four limitations qualify the findings. First, the decomposition describes conditional associations; it identifies mediation only if no unmeasured factor drives both skills and achievement given SES and controls. Prior achievement is the obvious candidate — successful students become more curious — and in its presence the mediated shares reported here are upper bounds on the causal contribution of skills, which strengthens the negative conclusion on reproduction but not the positive conclusion on class-neutral returns. Second, the skills are self-reported and cross-system comparisons of their levels are subject to reference bias; we have therefore compared slopes rather than levels and standardised skills within systems as a check, but the East Asian perseverance result in particular may partly reflect reporting norms. PISA 2025's process data from the Learning in the Digital World assessment offer a route to behavioural measures of persistence that a companion paper pursues. Third, two SSES domains — engaging with others and collaboration — are not measured, so the conclusions concern task performance, open-mindedness and one facet of emotional regulation. Fourth, item non-response on the skill scales is selective in several Balkan and Caucasus systems; the re-weighted estimates are close to the main ones, but Armenia's estimates pertain to the fifth of students who completed the items.

# Conclusion

Using the first PISA cycle to measure socio-emotional skills on the SSES taxonomy, and twenty non-OECD systems that share a socialist or Chinese-heritage tradition of character-forming schooling, we asked whether these skills transmit family advantage, compensate for its absence, or neither. They do neither in any strong sense. Six skills carry 8 per cent of the socio-economic gradient in science achievement, three-quarters of it through curiosity; their returns are identical for the poorest 40 per cent and the richest 10 per cent of students, and for the materially deprived and the non-deprived at a given SES; and they raise the level of achievement rather than its growth across grades. Material deprivation, by contrast, costs a quarter of a standard deviation at a given SES, and skills absorb a tenth of that. Where the systems differ is not in how much socio-emotional skills matter but in which ones do: strategic self-regulation is rewarded in the examination-driven East Asian systems, reported persistence in the post-Soviet and Balkan ones.

For research, the results argue for retiring the informal "shrinkage of the SES coefficient" as evidence of mediation in favour of decompositions that attribute the shrinkage to specific skills and report it against the right denominator. For policy, they argue for a more modest and more precise equity case for socio-emotional learning: a general input with class-neutral returns, worth about as much to disadvantaged students as to anyone else, and no substitute for the material and compositional advantages that carry the other 92 per cent of the gradient.

# References

*Draft reference list — to be verified against the originals before submission; entries marked † are cited from memory and need a full check.*

Agasisti, T., Avvisati, F., Borgonovi, F., & Longobardi, S. (2021). What school factors are associated with the success of socio-economically disadvantaged students? An empirical investigation using PISA data. *Social Indicators Research*, 157, 749–781.

Almlund, M., Duckworth, A. L., Heckman, J. J., & Kautz, T. (2011). Personality psychology and economics. In E. A. Hanushek, S. Machin & L. Woessmann (Eds.), *Handbook of the Economics of Education* (Vol. 4, pp. 1–181). Elsevier.

Avanesian, G. (2025). Estimating cognitive skill formation in Brazil, China, and Russia: An education production function approach. Working paper.

Avanesian, G., & Rozhkova, K. (2025). The effect of non-cognitive skills on academic performance: Does it vary by socio-economic status? Working paper.

Avvisati, F., & Givord, P. (2023). The learning gain over one school year among 15-year-olds: An international comparison based on PISA. *Labour Economics*, 84, 102365.

Borghans, L., Duckworth, A. L., Heckman, J. J., & ter Weel, B. (2008). The economics and psychology of personality traits. *Journal of Human Resources*, 43(4), 972–1059.

Bourdieu, P., & Passeron, J.-C. (1977). *Reproduction in Education, Society and Culture*. Sage.

Bowles, S., & Gintis, H. (1976). *Schooling in Capitalist America: Educational Reform and the Contradictions of Economic Life*. Basic Books.

Chernyshenko, O., Kankaraš, M., & Drasgow, F. (2018). Social and emotional skills for student success and well-being: Conceptual framework for the OECD study on social and emotional skills. *OECD Education Working Papers*, No. 173. OECD Publishing.

Cunha, F., & Heckman, J. J. (2007). The technology of skill formation. *American Economic Review*, 97(2), 31–47.

Farkas, G. (2003). Cognitive skills and noncognitive traits and behaviors in stratification processes. *Annual Review of Sociology*, 29, 541–562.

Gelbach, J. B. (2016). When do covariates matter? And which ones, and how much? *Journal of Labor Economics*, 34(2), 509–543.

Heckman, J. J., & Kautz, T. (2012). Hard evidence on soft skills. *Labour Economics*, 19(4), 451–464.

Heckman, J. J., Stixrud, J., & Urzua, S. (2006). The effects of cognitive and noncognitive abilities on labor market outcomes and social behavior. *Journal of Labor Economics*, 24(3), 411–482.

John, O. P., & Srivastava, S. (1999). The Big Five trait taxonomy: History, measurement, and theoretical perspectives. In L. A. Pervin & O. P. John (Eds.), *Handbook of Personality: Theory and Research* (2nd ed., pp. 102–138). Guilford.

Kautz, T., Heckman, J. J., Diris, R., ter Weel, B., & Borghans, L. (2014). Fostering and measuring skills: Improving cognitive and non-cognitive skills to promote lifetime success. *OECD Education Working Papers*, No. 110. OECD Publishing.

Li, J. (2012). *Cultural Foundations of Learning: East and West*. Cambridge University Press.

Lundberg, S. (2013). The college type: Personality and educational inequality. *Journal of Labor Economics*, 31(3), 421–441.

OECD (2011). *Against the Odds: Disadvantaged Students Who Succeed in School*. OECD Publishing.

OECD (2021). *Beyond Academic Learning: First Results from the Survey of Social and Emotional Skills*. OECD Publishing.

OECD (2026). *PISA 2025 Results* and *PISA 2025 Technical Report*. OECD Publishing. †

Poropat, A. E. (2009). A meta-analysis of the five-factor model of personality and academic performance. *Psychological Bulletin*, 135(2), 322–338.

Richardson, M., Abraham, C., & Bond, R. (2012). Psychological correlates of university students' academic performance: A systematic review and meta-analysis. *Psychological Bulletin*, 138(2), 353–387.

West, M. R., Kraft, M. A., Finn, A. S., Martin, R. E., Duckworth, A. L., Gabrieli, C. F. O., & Gabrieli, J. D. E. (2016). Promise and paradox: Measuring students' non-cognitive skills and the impact of schooling. *Educational Evaluation and Policy Analysis*, 38(1), 148–170.


# Appendix

```{=latex}
\begingroup\footnotesize
```

Table: Mean skill (within-system standardised) by ESCS group and bloc.

| Bloc | Skill | Bottom 40% | Middle 50% | Top 10% |
|----------------------------------------|------------------------------------------------|-------------------|-------------------|-------------|
| East Asia | Curiosity | -0.12 | 0.04 | 0.24 |
| East Asia | Problem-solving enjoyment | -0.11 | 0.04 | 0.22 |
| East Asia | Goal setting | -0.13 | 0.06 | 0.23 |
| East Asia | Perseverance | -0.08 | 0.03 | 0.14 |
| East Asia | Self-regulated learning | -0.07 | 0.01 | 0.22 |
| East Asia | Stress adaptability | -0.12 | 0.04 | 0.27 |
| Post-Soviet | Curiosity | -0.14 | 0.04 | 0.3 |
| Post-Soviet | Problem-solving enjoyment | -0.13 | 0.04 | 0.3 |
| Post-Soviet | Goal setting | -0.16 | 0.04 | 0.35 |
| Post-Soviet | Perseverance | -0.12 | 0.02 | 0.29 |
| Post-Soviet | Self-regulated learning | -0.06 | 0.01 | 0.15 |
| Post-Soviet | Stress adaptability | -0.1 | 0.02 | 0.25 |
| Post-communist Europe | Curiosity | -0.13 | 0.05 | 0.23 |
| Post-communist Europe | Problem-solving enjoyment | -0.1 | 0.04 | 0.19 |
| Post-communist Europe | Goal setting | -0.12 | 0.05 | 0.2 |
| Post-communist Europe | Perseverance | -0.08 | 0.03 | 0.14 |
| Post-communist Europe | Self-regulated learning | -0.04 | 0.02 | 0.06 |
| Post-communist Europe | Stress adaptability | -0.12 | 0.04 | 0.22 |

```{=latex}
\endgroup
```

```{=latex}
\begingroup\footnotesize
```

Table: Gelbach decomposition with school controls (leave-one-out school mean ESCS, private school, community size): the within-school family gradient.

| System | Within-school ESCS gradient, base | With skills | Explained (%) | of which curiosity (%) |
|-----------------------------|----------------------------------------------|---------------|------------------|-------------------------------|
| B-S-J-Z (China) | 6.8 (1.0) | 5.1 (1.1) | 25.3 (6.4) | 12.3 |
| Hong Kong | 9.2 (1.4) | 8.0 (1.4) | 13.2 (4.9) | 16.0 |
| Macao | 18.8 (1.5) | 16.5 (1.5) | 12.3 (2.2) | 7.2 |
| Viet Nam | 9.7 (1.0) | 9.5 (1.0) | 2.0 (2.2) | 4.2 |
| Mongolia | 12.6 (1.2) | 11.4 (1.2) | 9.9 (2.0) | 6.3 |
| Kazakhstan | 8.1 (0.7) | 6.2 (0.7) | 23.6 (3.6) | 23.4 |
| Uzbekistan | 5.1 (1.3) | 3.3 (1.3) | 35.4 (11.1) | 13.8 |
| Kyrgyzstan | 7.6 (1.2) | 6.8 (1.2) | 10.5 (4.0) | 8.4 |
| Georgia | 11.2 (1.8) | 8.6 (1.7) | 23.5 (5.6) | 12.2 |
| Azerbaijan | 8.9 (1.4) | 6.3 (1.4) | 29.3 (5.0) | 10.2 |
| Moldova | 16.0 (1.3) | 13.6 (1.3) | 14.9 (2.7) | 7.8 |
| Armenia | 11.0 (2.6) | 10.0 (2.4) | 9.8 (7.5) | 8.3 |
| Serbia | 8.9 (1.5) | 8.0 (1.5) | 10.2 (4.5) | 8.8 |
| Bulgaria | 6.1 (2.1) | 4.1 (2.0) | 32.7 (13.7) | 32.9 |
| Romania | 15.8 (1.3) | 14.2 (1.3) | 9.8 (2.1) | 10.8 |
| Croatia | 15.7 (1.6) | 14.5 (1.6) | 7.3 (2.1) | 4.9 |
| Albania | 10.3 (1.3) | 8.7 (1.3) | 15.3 (3.0) | 4.6 |
| North Macedonia | 10.3 (1.6) | 9.1 (1.6) | 11.9 (4.7) | 2.8 |
| Montenegro | 12.1 (1.6) | 10.5 (1.6) | 13.5 (3.2) | 7.0 |
| Kosovo | 7.9 (1.4) | 5.8 (1.4) | 26.3 (7.2) | 7.6 |
| East Asia | 8.6 (0.6) | 7.4 (0.6) | 14.9 (1.9) | 11.7 |
| Post-Soviet | 9.4 (0.6) | 7.6 (0.6) | 19.8 (2.2) | 14.2 |
| Post-communist Europe | 11.2 (1.0) | 9.7 (1.0) | 13.1 (1.5) | 8.4 |
| All 20 economies | 9.8 (0.4) | 8.3 (0.4) | 15.6 (0.9) | 11.1 |

```{=latex}
\endgroup
```

```{=latex}
\begin{landscape}
```

```{=latex}
\begingroup\footnotesize
```

Table: Robustness of the decomposition: other outcomes, within-system standardised skills, and re-weighting for item non-response. Point estimates.

| Specification | Unit | ESCS gradient, base | With skills | Return: curiosity | Return: perseverance | Return: self-reg. | of which curiosity (%) | Explained (%) |
|---------------------------|-----------------|---------------|---------|--------------|----------------|--------------|------------------|----------|
| Main: science, total gradient | All 20 economies | 24.49 | 22.55 | 13.1 |  | 2.14 | 5.8 | 7.9 |
| Main: science, total gradient | East Asia | 24.73 | 23.32 | 11.17 | -1.3 | 7.04 | 4.5 | 5.7 |
| Main: science, total gradient | Post-Soviet | 18.53 | 16.34 | 12.19 |  | 1.69 | 8.6 | 11.8 |
| Main: science, total gradient | Post-communist Europe | 28.73 | 26.44 | 15.12 |  | -0.98 | 5.4 | 8.0 |
| Outcome: MATH | All 20 economies | 26.53 | 24.81 | 11.33 |  | 1.76 | 4.7 | 6.5 |
| Outcome: MATH | East Asia | 26.72 | 25.28 | 9.6 | -1.96 | 7.26 | 3.6 | 5.4 |
| Outcome: MATH | Post-Soviet | 21.6 | 19.61 | 11.32 |  | 1.35 | 6.8 | 9.2 |
| Outcome: MATH | Post-communist Europe | 29.19 | 27.26 | 12.76 |  | -1.93 | 4.5 | 6.6 |
| Outcome: READ | All 20 economies | 22.74 | 20.89 | 14.26 |  | 2.71 | 6.8 | 8.1 |
| Outcome: READ | East Asia | 21.53 | 20.47 | 10.17 | -0.76 | 6.84 | 4.7 | 4.9 |
| Outcome: READ | Post-Soviet | 19.54 | 17.44 | 14.71 |  | 1.95 | 9.8 | 10.8 |
| Outcome: READ | Post-communist Europe | 25.93 | 23.57 | 16.5 |  | 0.37 | 6.6 | 9.1 |
| Re-weighted for item non-response | All 20 economies | 23.73 | 21.68 | 13.87 |  | 2.29 | 6.3 | 8.6 |
| Re-weighted for item non-response | East Asia | 24.88 | 23.43 | 11.5 | -0.85 | 7.06 | 4.7 | 5.8 |
| Re-weighted for item non-response | Post-Soviet | 17.57 | 15.36 | 12.61 |  | 2.84 | 8.8 | 12.6 |
| Re-weighted for item non-response | Post-communist Europe | 28.29 | 25.96 | 15.97 |  | -0.64 | 5.7 | 8.2 |
| Skills standardised within economy | All 20 economies | 24.49 | 22.57 | 13.27 |  | 2.2 | 5.9 | 7.8 |
| Skills standardised within economy | East Asia | 24.73 | 23.32 | 10.56 | -1.23 | 6.83 | 4.6 | 5.7 |
| Skills standardised within economy | Post-Soviet | 18.53 | 16.35 | 13.02 |  | 1.62 | 8.6 | 11.7 |
| Skills standardised within economy | Post-communist Europe | 28.73 | 26.44 | 15.56 |  | -1.1 | 5.5 | 8.0 |

```{=latex}
\endgroup
```

```{=latex}
\end{landscape}
```

