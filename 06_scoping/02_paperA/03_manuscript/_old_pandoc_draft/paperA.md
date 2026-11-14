---
title: "Conveyor Belt or Compensating Asset? Socio-Emotional Skills and the Socio-Economic Gradient of Learning in East Asian, Post-Soviet and Post-Communist Education Systems"
author:
  - Garen Avanesian^[Southern Federal University, Future Skills Research Lab, Rostov-on-Don, Russia. Corresponding author.]
date: "Draft of 25 September 2026 — for internal circulation"
abstract: |
  ABSTRACT_PLACEHOLDER
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

TABLE1_PLACEHOLDER

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

RESULTS_PLACEHOLDER

# Discussion

DISCUSSION_PLACEHOLDER

# Conclusion

CONCLUSION_PLACEHOLDER

# References

REFERENCES_PLACEHOLDER

# Appendix

APPENDIX_PLACEHOLDER
