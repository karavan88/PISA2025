"""Assemble the Paper A manuscript: build markdown tables from outputs/tables and splice them, results and discussion into paperA.md.
Then: pandoc -> PDF and DOCX. Run from the paperA folder: python3 02_scripts/paperA/08_assemble_manuscript.py"""
import pandas as pd, numpy as np, re, subprocess, os
T = '03_outputs/paperA/tables/'; F = '03_outputs/paperA/figures/'
blocs = ['East Asia', 'Post-Soviet', 'Post-communist Europe']; ALL = 'All 20 economies'
econ = pd.read_csv('01_data/derived/paperA_economies.csv'); order = list(econ.economy) + blocs + [ALL]
SK = {'PERSEV': 'Perseverance', 'CURIO': 'Curiosity', 'ENPROBS': 'Problem-solving enjoyment', 'COGABIL': 'Stress adaptability', 'GOALSET': 'Goal setting', 'SELFREG': 'Self-regulated learning'}
skorder = ['Perseverance', 'Self-regulated learning', 'Goal setting', 'Curiosity', 'Problem-solving enjoyment', 'Stress adaptability']

def md(df, caption, align=None, small=True, landscape=False):
    cols = list(df.columns)
    cells = [[('' if (isinstance(v, float) and np.isnan(v)) else str(v)) for v in r] for r in df.values.tolist()]
    # relative widths from content length (pandoc reads them off the dash counts once a line exceeds the column width)
    lens = [max([len(str(c))] + [min(len(x), 60) for x in col]) for c, col in zip(cols, zip(*cells))] if cells else [len(str(c)) for c in cols]
    tot = sum(lens); dashes = [max(3, int(round(140 * l / tot))) for l in lens]
    out = [f'Table: {caption}', '', '| ' + ' | '.join(str(c) for c in cols) + ' |', '|' + '|'.join('-' * d for d in dashes) + '|']
    for r in cells: out.append('| ' + ' | '.join(r) + ' |')
    body = '\n'.join(out) + '\n'
    if small: body = '```{=latex}\n\\begingroup\\footnotesize\n```\n\n' + body + '\n```{=latex}\n\\endgroup\n```\n'
    if landscape: body = '```{=latex}\n\\begin{landscape}\n```\n\n' + body + '\n```{=latex}\n\\end{landscape}\n```\n'
    return body
def es(e, s, d=1): return '' if pd.isna(e) else f'{e:.{d}f} ({s:.{d}f})'
def star(e, s): return '' if pd.isna(e) else ('***' if abs(e) > 2.576 * s else '**' if abs(e) > 1.96 * s else '*' if abs(e) > 1.645 * s else '')
def ess(e, s, d=1): return '' if pd.isna(e) else f'{e:.{d}f}{star(e, s)} ({s:.{d}f})'

# ---- Table 1 ----
t1 = pd.read_csv(T + 't1_sample.csv')
t1['Schools'] = t1['Schools'].astype(str); t1.loc[t1.Economy == 'Macao', 'Schools'] = '—'
t1 = t1.rename(columns={'Share below modal grade': '% below modal grade', 'Repeated grade': '% repeated', 'Immigrant background': '% immigrant', 'Other language at home': '% other language', 'Deprived (any of 4 items)': '% deprived', 'Female': '% female'})
t1['Bloc'] = t1['Bloc'].replace({'East Asia': 'EA', 'Post-Soviet': 'PS', 'Post-communist Europe': 'PCE'})
t1 = t1[['Bloc', 'Economy', 'N', 'Schools', '% female', 'Modal grade', '% below modal grade', '% repeated', '% immigrant', '% other language', 'ESCS mean', 'ESCS SD', '% deprived', 'Science mean', 'Science SD']]
T1 = md(t1, 'Analytic sample by education system. EA = East Asia, PS = post-Soviet, PCE = post-communist Europe. Weighted by final student weights. Deprived = cannot afford at least one of four personal items (ST488). Macao: no school identifier in the public-use file.', landscape=True)

# ---- Table 2: scales ----
t2 = pd.DataFrame([
 ['Task performance', 'Perseverance', 'PERSEV', 'ST307 (6): keep working on a task until finished; apply additional effort when work becomes challenging; finish tasks even when boring; quit homework if too long (R); finish what I start; give up easily (R)', 'Not fielded in KAZ, ALB'],
 ['Task performance', 'Self-regulated learning', 'SELFREG', 'ST432–ST434: plan my approach to studying; summarise key points to find gaps; self-question to check understanding; change approach if unsuccessful; ask classmates/teachers/others for help; evaluate what I learned; ask for feedback', ''],
 ['Task performance / self-direction', 'Goal setting', 'GOALSET', 'Goal-setting items of the self-regulated learning block', ''],
 ['Open-mindedness', 'Curiosity', 'CURIO', 'ST301 (5): curious about many different things; like to know how things work; more curious than most people; find learning new things boring (R); like learning new things', ''],
 ['Open-mindedness', 'Problem-solving enjoyment', 'ENPROBS', 'ST435 (4): enjoy finding solutions to problems; like situations where I have to think hard; like complicated more than simple problems; keep working on a problem even if I might not solve it', ''],
 ['Emotional regulation', 'Stress adaptability', 'COGABIL', 'ST216 (4): can handle unusual situations; adapt to different situations even under stress or pressure; adapt easily to a new culture; find a way to resolve difficult situations with other people', 'PISA label: cognitive adaptability'],
], columns=['SSES domain', 'Scale', 'PISA variable', 'Items (R = reversed)', 'Note'])
T2 = md(t2, 'Socio-emotional skill scales in PISA 2025 and their mapping to the SSES taxonomy. All scales are OECD-standardised weighted-likelihood estimates (mean 0, SD 1 across OECD countries).')

# ---- Table 3: skill gradients pi_k and achievement gradient by bloc ----
g = pd.read_csv(T + 'h1_gelbach_long_total.csv')
rows = []
for u in blocs + [ALL]:
    r = {'Unit': u}
    for k, lab in SK.items():
        x = g[(g.unit == u) & (g.term == f'pi_{k}')]
        r[lab] = es(x.est.iloc[0], x.se.iloc[0], 3) if len(x) else '—'
    x = g[(g.unit == u) & (g.term == 'beta_base')]; r['Science (points)'] = es(x.est.iloc[0], x.se.iloc[0], 1)
    rows.append(r)
t3 = pd.DataFrame(rows)[['Unit'] + skorder + ['Science (points)']]
T3 = md(t3, 'Socio-economic gradients of skills and of achievement: coefficient on ESCS (per unit) from weighted regressions with student controls, no school controls; skills in OECD SD units. Standard errors (BRR + PV) in parentheses. Perseverance omitted from pooled units containing Kazakhstan or Albania.')

# ---- Table 4: Gelbach by system (total gradient) ----
gt = pd.read_csv(T + 'h1_gelbach_table_total.csv')
gt['unit'] = pd.Categorical(gt.unit, order); gt = gt.sort_values('unit')
t4 = pd.DataFrame({'System': gt.unit.astype(str), 'N': gt.N,
  'ESCS gradient, base': [es(a, b) for a, b in zip(gt.beta_base, gt.se_base)],
  'ESCS gradient, with skills': [es(a, b) for a, b in zip(gt.beta_full, gt.se_full)],
  'Explained (points)': [es(a, b) for a, b in zip(gt.explained, gt.se_explained)],
  'Explained (%)': [es(a, b) for a, b in zip(gt.share, gt.se_share)],
  'of which curiosity (%)': gt.CURIO.round(1), 'Perseverance (%)': gt.PERSEV.round(1), 'Self-reg. learning (%)': gt.SELFREG.round(1), 'Stress adapt. (%)': gt.COGABIL.round(1)})
T4 = md(t4, 'Gelbach decomposition of the ESCS gradient in science. Base model: ESCS and student controls; full model adds the six skills. "Explained" = beta_base − beta_full = Σ gamma_k pi_k. Skill columns give each skill\'s contribution as a percentage of the base gradient (they sum, with problem-solving enjoyment and goal setting, to the total). Bloc and pooled models include system fixed effects and senate weights.', landscape=True)

# ---- Table 5: returns by ESCS group ----
sl = pd.read_csv(T + 'h2_skill_returns_by_group.csv')
rows = []
for u in blocs + [ALL]:
    for s in skorder:
        x = sl[(sl.unit == u) & (sl.skill == s)]
        if x.empty: continue
        def gv(gname): y = x[x.group == gname]; return (y.est.iloc[0], y.se.iloc[0]) if len(y) else (np.nan, np.nan)
        b, t, d = gv('Bottom 40%'), gv('Top 10%'), gv('Difference (B40 - T10)')
        rows.append({'Unit': u, 'Skill': s, 'Bottom 40%': es(*b), 'Top 10%': es(*t), 'Difference (B40 − T10)': ess(*d)})
T5 = md(pd.DataFrame(rows), 'Returns to skills by ESCS group: science points per OECD SD of skill, from the model with skill × ESCS-group interactions, ESCS, student and school controls. Stars on the difference: * p<0.10, ** p<0.05, *** p<0.01.')

# ---- Table 6: deprivation ----
dep = pd.read_csv(T + 'h2c_deprivation.csv')
rows = []
for u in blocs + [ALL]:
    x = dep[dep.unit == u]; r = {'Unit': u}
    for tname, lab in [('Deprivation penalty (base)', 'Penalty at given ESCS'), ('Deprivation penalty (with skills)', 'Penalty, skills added')]:
        y = x[x.term == tname]; r[lab] = es(y.est.iloc[0], y.se.iloc[0])
    for s in skorder:
        y = x[x.term == f'Skill x deprived: {s}']; r[f'× {s}'] = ess(y.est.iloc[0], y.se.iloc[0]) if len(y) else '—'
    rows.append(r)
T6 = md(pd.DataFrame(rows), 'Material deprivation at a given ESCS. Penalty = coefficient on the deprivation indicator (science points) with ESCS, student and school controls, before and after adding skills; "× skill" = difference in the return to the skill for deprived versus non-deprived students. Stars as in Table 5.')

# ---- Table 7: H3 restricted ----
h3 = pd.read_csv(T + 'h3b_skill_x_grade_restricted.csv')
rows = []
for u in ['East Asia', 'Post-Soviet', 'Post-communist Europe', ALL]:
    x = h3[h3.unit == u]
    if x.empty: continue
    r = {'Unit': u}
    y = x[x.term == 'Grade (learning gain)']; r['Grade (points per year)'] = es(y.est.iloc[0], y.se.iloc[0])
    for s in skorder:
        y = x[x.term == f'Grade x {s}']; r[f'Grade × {s}'] = ess(y.est.iloc[0], y.se.iloc[0]) if len(y) else '—'
    rows.append(r)
T7 = md(pd.DataFrame(rows), 'Level versus rate: grade coefficient and skill × grade interactions, restricted sample (systems with ≥10% of students below the modal grade; students in the modal grade or one below). Controls as in the full model, including age. Bloc units contain only the restricted systems (East Asia: B-S-J-Z, Hong Kong, Macao; post-Soviet: Georgia, Azerbaijan, Armenia; post-communist Europe: Serbia, Romania, Albania, Kosovo, Montenegro).')

# ---- Table 8: H5 bloc returns ----
h5 = pd.read_csv(T + 'h5_bloc_x_skill_long.csv'); h5p = pd.read_csv(T + 'h5_bloc_x_skill_withPERSEV_long.csv')
rows = []
for k, lab in SK.items():
    src = h5p if k == 'PERSEV' else h5
    def gv(term): y = src[src.term == term]; return (y.est.iloc[0], y.se.iloc[0]) if len(y) else (np.nan, np.nan)
    ea = gv(k); ps = gv(f'blocPost-Soviet:{k}'); pce = gv(f'blocPost-communist Europe:{k}')
    def bl(u): y = g[(g.unit == u) & (g.term == f'gamma_{k}')]; return (y.est.iloc[0], y.se.iloc[0]) if len(y) else (np.nan, np.nan)
    rows.append({'Skill': lab, 'East Asia': es(*bl('East Asia')), 'Post-Soviet': es(*bl('Post-Soviet')), 'Post-communist Europe': es(*bl('Post-communist Europe')),
                 'Post-Soviet − East Asia': ess(*ps), 'Post-communist Europe − East Asia': ess(*pce)})
t8 = pd.DataFrame(rows).set_index('Skill').loc[skorder].reset_index()
T8 = md(t8, 'Returns to skills by bloc (science points per OECD SD; bloc models with system fixed effects and senate weights) and tests of bloc differences from the pooled model with bloc × skill interactions. Perseverance contrasts from the pooled model excluding Kazakhstan and Albania; the post-Soviet and European bloc means for perseverance therefore come from systems that fielded it. Stars as in Table 5.')

# ---- Appendix tables ----
a2 = pd.read_csv(T + 't3_skill_by_escs_group.csv'); a2['skill'] = a2['skill'].replace({'Enjoyment of problem-solving': 'Problem-solving enjoyment'})
A2 = md(a2.rename(columns={'bloc': 'Bloc', 'skill': 'Skill'}), 'Mean skill (within-system standardised) by ESCS group and bloc.')
gw = pd.read_csv(T + 'h1_gelbach_table.csv'); gw['unit'] = pd.Categorical(gw.unit, order); gw = gw.sort_values('unit')
a3 = pd.DataFrame({'System': gw.unit.astype(str), 'Within-school ESCS gradient, base': [es(a, b) for a, b in zip(gw.beta_base, gw.se_base)], 'With skills': [es(a, b) for a, b in zip(gw.beta_full, gw.se_full)], 'Explained (%)': [es(a, b) for a, b in zip(gw.share, gw.se_share)], 'of which curiosity (%)': gw.CURIO.round(1)})
A3 = md(a3, 'Gelbach decomposition with school controls (leave-one-out school mean ESCS, private school, community size): the within-school family gradient.')
A4 = ''
if os.path.exists(T + 'rob_gelbach_table.csv'):
    rb = pd.read_csv(T + 'rob_gelbach_table.csv'); rb['unit'] = rb.unit.replace({'All': ALL})
    rb = rb.rename(columns={'check': 'Specification', 'unit': 'Unit', 'beta_base': 'ESCS gradient, base', 'beta_full': 'With skills', 'share_explained': 'Explained (%)', 'share_CURIO': 'of which curiosity (%)', 'gamma_CURIO': 'Return: curiosity', 'gamma_SELFREG': 'Return: self-reg.', 'gamma_PERSEV': 'Return: perseverance'})
    A4 = md(rb, 'Robustness of the decomposition: other outcomes, within-system standardised skills, and re-weighting for item non-response. Point estimates.', landscape=True)

# ---- assemble ----
m = open('04_manuscripts/paperA/paperA.md').read()
res = open('04_manuscripts/paperA/results.md').read(); disc = open('04_manuscripts/paperA/discussion.md').read()
rob_sentence = open('04_manuscripts/paperA/robustness_sentence.txt').read().strip() if os.path.exists('04_manuscripts/paperA/robustness_sentence.txt') else 'ROBUSTNESS_SENTENCE'
res = res.replace('ROBUSTNESS_SENTENCE', rob_sentence)
abstract = open('04_manuscripts/paperA/abstract.txt').read().strip()
m = m.replace('ABSTRACT_PLACEHOLDER', '\n  '.join(abstract.split('\n')))
m = m.replace('TABLE1_PLACEHOLDER', T1 + '\n' + T2)
# insert tables and figures into results at markers
res = res.replace('Table 3 reports', T3 + '\nTable 3 reports', 1)
res = res.replace('Figure 2 and Table 4 give', f'![Share of the ESCS gradient in science explained by the six skills, by system and bloc (Gelbach decomposition; 95% CI). Uzbekistan\'s wide interval reflects its flat gradient.]({F}f2_gelbach_share.png){{#fig:share width=90%}}\n\n' + T4 + '\nFigure 2 and Table 4 give', 1)
res = res.replace('Table 5 reports the return', f'![Returns to skills for the bottom 40% and top 10% of the ESCS distribution, by bloc (science points per SD; 95% CI).]({F}f4_returns_by_escs_group.png){{#fig:groups width=100%}}\n\n![Difference in returns, bottom 40% minus top 10%, by system and skill (95% CI).]({F}f4b_return_gap_by_economy.png){{#fig:gap width=100%}}\n\n' + T5 + '\nTable 5 reports the return', 1)
res = res.replace('The material-deprivation contrast (Table 6)', T6 + '\nThe material-deprivation contrast (Table 6)', 1)
res = res.replace('Table 7 reports the grade coefficient', f'![Skill × grade interactions by system, restricted sample (95% CI).]({F}f5_skill_x_grade.png){{#fig:grade width=100%}}\n\n' + T7 + '\nTable 7 reports the grade coefficient', 1)
res = res.replace('Figure 6 plots the conditional return', f'![Conditional returns to skills by system (science points per SD; all six skills, ESCS and student controls; 95% CI).]({F}f6_returns_by_economy.png){{#fig:returns width=100%}}\n\n' + T8 + '\nFigure 6 plots the conditional return', 1)
res = res.replace('# Results\n', f'# Results\n\n![Weighted correlations of the six skills with science achievement, by system.]({F}f1_skill_science_corr.png){{#fig:corr width=100%}}\n', 1)
m = m.replace('# Results\n\nRESULTS_PLACEHOLDER\n\n# Discussion\n\nDISCUSSION_PLACEHOLDER\n\n# Conclusion\n\nCONCLUSION_PLACEHOLDER\n\n# References\n\nREFERENCES_PLACEHOLDER\n', res + '\n' + disc + '\n')
m = m.replace('# Appendix\n\nAPPENDIX_PLACEHOLDER', '# Appendix\n\n' + A2 + '\n' + A3 + '\n' + A4)
open('04_manuscripts/paperA/paperA_full.md', 'w').write(m)
print('assembled', len(m.split()), 'words')
for fmt, args in [('pdf', ['--pdf-engine=xelatex', '-V', 'mainfont=DejaVu Serif']), ('docx', [])]:
    r = subprocess.run(['pandoc', '04_manuscripts/paperA/paperA_full.md', '-o', f'04_manuscripts/paperA/paperA.{fmt}', '--number-sections', '--resource-path=.', '-f', 'markdown+pipe_tables+implicit_figures+table_captions+raw_attribute'] + args, capture_output=True, text=True)
    print(fmt, 'ok' if r.returncode == 0 else r.stderr[-2000:])
