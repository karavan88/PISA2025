"""
EPF post-Soviet paper -- build the analytic student file from the PISA 2025 public-use files.
Run from repo root:  python3 02_scripts/epf_postsoviet/01_build.py      (needs pyreadstat, pandas)
Output: 01_data/derived/epf_students.csv.gz  (one row per student, 11 systems, all PVs + 80 replicate weights)
        01_data/derived/epf_schools.csv
Missing codes are SPSS user-missing and arrive as NaN. All derived variables are documented inline.
"""
import os, time, numpy as np, pandas as pd, pyreadstat
t0 = time.time()
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived'); os.makedirs(OUT, exist_ok=True)
# Two regions, one file. Post-Soviet (7) and East Asia (4; Macao is excluded because the PUF carries no school identifier for it, so
# school composition, school inputs and the school random intercept cannot be formed). Region is a label only -- every model is per system.
PS_SYS = ['ARM','GEO','AZE','MDA','KAZ','KGZ','UZB']
EA_SYS = ['QCI','HKG','VNM','MNG']
PS = PS_SYS + EA_SYS
NAMES = {'ARM':'Armenia','GEO':'Georgia','AZE':'Azerbaijan','MDA':'Moldova','KAZ':'Kazakhstan','KGZ':'Kyrgyzstan','UZB':'Uzbekistan',
         'QCI':'B-S-J-Z (China)','HKG':'Hong Kong','VNM':'Viet Nam','MNG':'Mongolia'}
REGION = {**{c:'Post-Soviet' for c in PS_SYS}, **{c:'East Asia' for c in EA_SYS}}

ids   = ['CNT','CNTSCHID','CNTSTUID','STRATUM']
demo  = ['ST001D01T','ISCEDP','PROGN','ST003D02T','ST003D03T','AGE','REPEAT','ST004D01T','ST022Q01TA','IMMIG','LANGTEST_COG']
ses   = ['ESCS','HISEI','PAREDINT','HOMEPOS']
depr  = ['ST488Q01DA','ST488Q02DA','ST488Q08DA','ST488Q09DA','ST401Q03DA','ST401Q04DA','ST401Q05DA','ST401Q06DA','ST401Q07DA']
skill = ['PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','ST420Q01DA']
pvs   = [f'PV{i}{d}' for d in ['SCIE','MATH','READ'] for i in range(1,11)]
wts   = ['W_FSTUWT','SENWT'] + [f'W_FSTURWT{i}' for i in range(1,81)]
stu, meta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_STU_PUF.sav'), usecols=ids+demo+ses+depr+skill+pvs+wts)
stu = stu[stu.CNT.isin(PS)].copy()
print('students read', stu.shape, round(time.time()-t0,1), 's')

sch_cols = ['CNT','CNTSCHID','SC001Q01TA','PRIVATESCH','SCHLTYPE','STRATIO_Q','CLSIZE','SCHSIZE_Q','EDUSHORT','STAFFSHORT','PROATCE',
            'SC017Q07NA','SC017Q08NA','SC189Q01JA','SC189Q05JA','SC189Q06JA','SC194Q01DA']
sch, smeta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_SCH_PUF.sav'), usecols=sch_cols)
sch = sch[sch.CNT.isin(PS)].copy()

# ---------------- student-level derivations ----------------
d = stu
d['economy']  = d.CNT.map(NAMES)
d['region']   = d.CNT.map(REGION)
d['school']   = d.CNTSCHID.astype('int64')
d['grade']    = d.ST001D01T
# weighted modal grade per system
modal = d.groupby('CNT').apply(lambda s: s.groupby('grade').W_FSTUWT.sum().idxmax()).rename('modal_grade')
d = d.merge(modal, left_on='CNT', right_index=True)
d['grade_c']  = d.grade - d.modal_grade                       # grade relative to modal grade
d['general']  = d.ISCEDP.isin([244, 344]).astype(int)          # general lower/upper secondary programme
d['vocational'] = d.ISCEDP.isin([254, 354]).astype(int)
d['in_window'] = ((d.general == 1) & (d.grade_c.abs() <= 1)).astype(int)   # estimation window for grade models
d['bmonth']   = d.ST003D02T                                    # birth month 1-12 (all students born 2009)
d['female']   = np.where(d.ST004D01T.isna(), np.nan, (d.ST004D01T == 1).astype(float))
d['lang_other'] = np.where(d.ST022Q01TA.isna(), np.nan, (d.ST022Q01TA == 2).astype(float))   # home language != test language
d['immigrant']  = np.where(d.IMMIG.isna(), np.nan, (d.IMMIG > 1).astype(float))
d['repeat']     = np.where(d.REPEAT.isna(), np.nan, (d.REPEAT == 1).astype(float))
d['rus_medium'] = (d.LANGTEST_COG == 'rus').astype(int)         # tested (= instructed) in Russian
d['lang_test']  = d.LANGTEST_COG
# growth mindset (single item, binary): disagrees that intelligence cannot be changed
d['growth'] = np.where(d.ST420Q01DA.isna(), np.nan, d.ST420Q01DA.isin([1, 2]).astype(float))

# ESCS within-system weighted percentile rank (0-100) on all students with ESCS; quintiles from the same rank
def wrank(s, w):
    o = np.argsort(s.values, kind='mergesort'); r = np.empty(len(s)); cw = np.cumsum(w.values[o]); r[o] = (cw - w.values[o]/2) / cw[-1] * 100
    return pd.Series(r, index=s.index)
d['ESCS_pct'] = np.nan
for c in PS:
    m = (d.CNT == c) & d.ESCS.notna()
    d.loc[m, 'ESCS_pct'] = wrank(d.loc[m, 'ESCS'], d.loc[m, 'W_FSTUWT'])
d['ESCS_pct10'] = d.ESCS_pct / 10
d['ses_q'] = np.where(d.ESCS_pct.isna(), np.nan, np.minimum(np.floor(d.ESCS_pct / 20) + 1, 5))   # quintile 1 (bottom) .. 5 (top)

# material deprivation: items answered 'cannot afford' (code 2) among items fielded in the system (>=90% answered among deprivation respondents)
def dep_block(g):
    M = g[depr]; any_ans = M.notna().any(axis=1)
    fielded = [v for v in depr if any_ans.sum() > 0 and M.loc[any_ans, v].notna().mean() >= 0.9]
    if not fielded: return pd.DataFrame({'DEP': np.nan, 'dep_items': 0}, index=g.index)
    Mf = M[fielded]; dep = np.where(Mf.isna().any(axis=1), np.nan, (Mf == 2).sum(axis=1))
    return pd.DataFrame({'DEP': dep, 'dep_items': len(fielded)}, index=g.index)
dd = pd.concat([dep_block(g) for _, g in d.groupby('CNT')]); d = d.join(dd)

# leave-one-out weighted school mean of ESCS (composition measure that excludes the student), on all sampled students with ESCS
def loo_wmean(x, w):
    ok = x.notna(); sx = (x[ok]*w[ok]).sum(); sw = w[ok].sum()
    out = pd.Series(np.nan, index=x.index)
    out[ok] = np.where(sw - w[ok] > 0, (sx - x[ok]*w[ok]) / (sw - w[ok]), np.nan)
    return out
d['sch_escs_loo'] = d.groupby(['CNT','school'], group_keys=False).apply(lambda g: loo_wmean(g.ESCS, g.W_FSTUWT))
d['sch_n_escs']   = d.groupby(['CNT','school']).ESCS.transform(lambda s: s.notna().sum())
d['sch_escs_mean'] = d.groupby(['CNT','school']).ESCS.transform('mean')

# skill availability flag
wle = ['PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL']
d['persev_fielded'] = d.groupby('CNT').PERSEV.transform(lambda s: s.notna().mean() > 0.1).astype(int)
need = d.apply(lambda r: [v for v in wle if not (v == 'PERSEV' and r.persev_fielded == 0)], axis=1) if False else None
d['skills_complete'] = ((d[['SELFREG','GOALSET','CURIO','ENPROBS','COGABIL']].notna().all(axis=1)) &
                        ((d.persev_fielded == 0) | d.PERSEV.notna()) & d.growth.notna()).astype(int)

# ---------------- school-level derivations ----------------
s = sch.copy()
s['school'] = s.CNTSCHID.astype('int64')
s['area'] = pd.cut(s.SC001Q01TA, [0, 2, 3, 6], labels=['village_small_town', 'town', 'city']).astype(str).replace('nan', np.nan)
s['rural']   = np.where(s.SC001Q01TA.isna(), np.nan, (s.SC001Q01TA <= 2).astype(float))
s['private'] = np.where(s.PRIVATESCH.isna(), np.nan, (s.PRIVATESCH == 2).astype(float))
s['stratio_med'] = s.STRATIO_Q.map({1: 5, 2: 9, 3: 13, 4: 20})          # international quartile medians
s['schsize_med'] = s.SCHSIZE_Q.map({1: 102, 2: 295, 3: 568, 4: 1114})
s['clsize']  = s.CLSIZE
s['proatce'] = s.PROATCE                                              # 0-1 share of fully certified teachers
s['infra_poor'] = np.where(s.SC017Q08NA.isna(), np.nan, (s.SC017Q08NA >= 3).astype(float))   # infrastructure hinders instruction to some extent / a lot
s['sel_policy'] = np.where(s.SC189Q01JA.isna(), np.nan, (s.SC189Q01JA == 1).astype(float))
s['sel_assess'] = np.where(s.SC194Q01DA.isna(), np.nan, (s.SC194Q01DA == 1).astype(float))
s['sel_grading'] = np.where(s.SC189Q06JA.isna(), np.nan, (s.SC189Q06JA == 1).astype(float))
skeep = ['CNT','school','area','rural','private','stratio_med','schsize_med','clsize','proatce','EDUSHORT','STAFFSHORT','infra_poor','sel_policy','sel_assess','sel_grading']
s[skeep].to_csv(os.path.join(OUT, 'epf_schools.csv'), index=False)
d = d.merge(s[skeep], on=['CNT','school'], how='left')

keep = ['CNT','economy','region','school','CNTSTUID','STRATUM','modal_grade','grade','grade_c','general','vocational','in_window','ISCEDP','PROGN',
        'bmonth','AGE','female','lang_other','immigrant','repeat','rus_medium','lang_test',
        'ESCS','ESCS_pct','ESCS_pct10','ses_q','HISEI','PAREDINT','DEP','dep_items','sch_escs_loo','sch_escs_mean','sch_n_escs',
        'PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','growth','persev_fielded','skills_complete'] + skeep[2:] + pvs + wts
d[keep].to_csv(os.path.join(OUT, 'epf_students.csv.gz'), index=False, compression='gzip')
print('written', d.shape, round(time.time()-t0,1), 's')
print(d.groupby('CNT').agg(n=('school','size'), schools=('school','nunique'), modal=('modal_grade','first'), in_window=('in_window','mean'),
      escs=('ESCS', lambda x: x.notna().mean()), skills=('skills_complete','mean'), dep_items=('dep_items','first'), rus=('rus_medium','mean')).round(3).to_string())
