"""
Paper A -- build the analytic student-level dataset from PISA 2025 public-use files.
Input : 01_data/CY09_MS_STU_PUF.sav, 01_data/CY09_MS_SCH_PUF.sav
Output: 01_data/derived/paperA_students.csv.gz (+ .parquet), 01_data/derived/paperA_schools.csv
Run   : python3 02_scripts/01_build_dataset.py   (from the repo root; needs pyreadstat, pandas, pyarrow)
Missing codes (95-99 etc.) are SPSS user-missing and are read as NaN by pyreadstat.
"""
import os, time, numpy as np, pandas as pd, pyreadstat
t0 = time.time()
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived'); os.makedirs(OUT, exist_ok=True)

BLOCS = {
 'East Asia': ['QCI','HKG','MAC','VNM','MNG'],
 'Post-Soviet': ['KAZ','UZB','KGZ','GEO','AZE','MDA','ARM'],
 'Post-communist Europe': ['SRB','BGR','ROU','HRV','ALB','MKD','MNE','KSV'],
}
CNTS = [c for v in BLOCS.values() for c in v]
BLOC_OF = {c:b for b,v in BLOCS.items() for c in v}
NAMES = {'QCI':'B-S-J-Z (China)','HKG':'Hong Kong','MAC':'Macao','VNM':'Viet Nam','MNG':'Mongolia',
 'KAZ':'Kazakhstan','UZB':'Uzbekistan','KGZ':'Kyrgyzstan','GEO':'Georgia','AZE':'Azerbaijan','MDA':'Moldova','ARM':'Armenia',
 'SRB':'Serbia','BGR':'Bulgaria','ROU':'Romania','HRV':'Croatia','ALB':'Albania','MKD':'North Macedonia','MNE':'Montenegro','KSV':'Kosovo'}

ids   = ['CNT','CNTRYID','CNTSCHID','CNTSTUID','STRATUM','REGION','OECD']
demo  = ['ST004D01T','AGE','ST001D01T','GRADE','REPEAT','IMMIG','LANGN','ST022Q01TA','ST003D02T','ST003D03T','ST125Q01NA']
ses   = ['ESCS','HISEI','HISCED','PAREDINT','HOMEPOS','ICTRES','ST255Q01JA','ST250Q20DA','ST250Q01JA']
depr  = ['ST488Q01DA','ST488Q02DA','ST488Q08DA','ST488Q09DA','ST401Q03DA','ST401Q04DA','ST401Q05DA','ST401Q06DA','ST401Q07DA']
skill = ['PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG','BELONG','FAMSUP','EFFSCIE','JOYSCIE']
minds = ['ST420Q01DA','ST420Q02DA','ST493Q01DA','ST016Q01NA','EXPECEDU','ST469Q08DA','EFFORT1','EFFORT2']
clim  = ['TEACHSUP','DISCLISCI','BULLIED','FEELSAFE']
pvs   = [f'PV{i}{d}' for d in ['SCIE','MATH','READ','CMPS','CPPK'] for i in range(1,11)]
wts   = ['W_FSTUWT'] + [f'W_FSTURWT{i}' for i in range(1,81)]
cols  = ids+demo+ses+depr+skill+minds+clim+pvs+wts

stu, meta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_STU_PUF.sav'), usecols=cols)
stu = stu[stu.CNT.isin(CNTS)].copy()
print('students read', stu.shape, round(time.time()-t0,1),'s')

sch_cols = ['CNT','CNTSCHID','SC001Q01TA','SCHLTYPE','PRIVATESCH','SCHSEL','STRATIO_Q','CLSIZE','SCHSIZE_Q','EDUSHORT','STAFFSHORT',
            'PROATCE','NEGSCLIM','SC189Q01JA','SC189Q05JA','SC189Q06JA','SC194Q01DA','SESASSESS','SC211Q03JA_Q','ALLACTIV']
sch, smeta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_SCH_PUF.sav'), usecols=sch_cols)
sch = sch[sch.CNT.isin(CNTS)].copy()

# ---- student-level constructions ----
stu['bloc']     = stu.CNT.map(BLOC_OF)
stu['economy']  = stu.CNT.map(NAMES)
stu['female']   = (stu.ST004D01T==1).astype(float).where(stu.ST004D01T.notna())
stu['lang_other']= (stu.ST022Q01TA==2).astype(float).where(stu.ST022Q01TA.notna())
stu['immig2']   = stu.IMMIG.map({1:0,2:1,3:1})          # any immigrant background
stu['immig_first']= (stu.IMMIG==3).astype(float).where(stu.IMMIG.notna())
stu['repeat']   = stu.REPEAT
stu['grade']    = stu.ST001D01T
modal = stu.groupby('CNT').grade.agg(lambda x: x.mode().iloc[0])
stu['grade_rel']= stu.grade - stu.CNT.map(modal)         # 0 = modal grade
stu['books']    = stu.ST255Q01JA
stu['quiet_place']= (stu.ST250Q20DA==1).astype(float).where(stu.ST250Q20DA.notna())
stu['own_room'] = (stu.ST250Q01JA==1).astype(float).where(stu.ST250Q01JA.notna())
# growth mindset: items state intelligence/ability is fixed -> disagreement = growth
stu['growth_int'] = 5 - stu.ST420Q01DA
stu['growth_sci'] = 5 - stu.ST420Q02DA
stu['status_fatal'] = stu.ST493Q01DA
stu['persev_msg'] = stu.ST469Q08DA
stu['life_sat'] = stu.ST016Q01NA

# material deprivation: 2 = "No, cannot afford it"; 1 = yes; 3 = no, other reason (treated as not deprived)
d4 = ['ST488Q01DA','ST488Q02DA','ST488Q08DA','ST488Q09DA']; d5 = ['ST401Q03DA','ST401Q04DA','ST401Q05DA','ST401Q06DA','ST401Q07DA']
for lst,name in [(d4,'dep4'),(d4+d5,'dep9')]:
    m = stu[lst]
    answered = m.notna().sum(axis=1)
    cnt = (m==2).sum(axis=1).astype(float)
    stu[name+'_n'] = cnt.where(answered==len(lst))            # count, only if all items answered
    stu[name+'_share'] = (cnt/answered).where(answered>0)     # share of answered items, tolerant to missing
    stu[name+'_any'] = (stu[name+'_share']>0).astype(float).where(stu[name+'_share'].notna())
stu['st401_fielded'] = stu.groupby('CNT').ST401Q04DA.transform(lambda x: x.notna().mean()>0.5).astype(int)

# weighted ESCS percentile groups within economy: bottom 40 / middle 50 / top 10
def wgroups(g):
    x = g.ESCS.values; w = g.W_FSTUWT.values; ok = ~np.isnan(x)
    order = np.argsort(x[ok]); cw = np.cumsum(w[ok][order])/w[ok].sum()
    q40 = x[ok][order][np.searchsorted(cw,0.40)]; q90 = x[ok][order][np.searchsorted(cw,0.90)]
    out = pd.Series(np.nan, index=g.index, dtype=float)
    out[g.ESCS<=q40]=1; out[(g.ESCS>q40)&(g.ESCS<=q90)]=2; out[g.ESCS>q90]=3
    return out
stu['escs_grp'] = stu.groupby('CNT', group_keys=False).apply(wgroups)
stu['escs_grp_lab'] = stu.escs_grp.map({1:'Bottom 40%',2:'Middle 50%',3:'Top 10%'})

# school composition from the full student sample (before any listwise deletion), leave-one-out weighted mean ESCS
def loo_mean(g):
    w = g.W_FSTUWT.where(g.ESCS.notna(), 0); x = (g.ESCS.fillna(0)*w)
    S = x.sum(); W = w.sum()
    return ((S - x)/(W - w)).where(W - w > 0)
has_sch = stu.CNTSCHID.notna()
stu['sch_escs_loo'] = np.nan
stu.loc[has_sch,'sch_escs_loo'] = stu[has_sch].groupby('CNTSCHID', group_keys=False).apply(loo_mean)
stu['sch_escs_mean'] = stu.groupby('CNTSCHID').ESCS.transform('mean')
stu['sch_n'] = stu.groupby('CNTSCHID').CNTSTUID.transform('size')

# ---- school file constructions ----
sch['private'] = sch.PRIVATESCH.map({1:0,2:1})
sch['urban']   = sch.SC001Q01TA.map({1:0,2:0,3:1,4:2,5:2,6:2})   # 0 rural/small town, 1 town, 2 city+
sch['sel_policy'] = sch.SC189Q01JA.map({1:1,2:0})
sch['sel_assess'] = sch.SC194Q01DA.map({1:1,2:0})
sch['pct_disadv_q'] = sch.SC211Q03JA_Q
sch_keep = ['CNTSCHID','SC001Q01TA','urban','SCHLTYPE','private','SCHSEL','STRATIO_Q','CLSIZE','SCHSIZE_Q','EDUSHORT','STAFFSHORT','PROATCE','NEGSCLIM',
            'sel_policy','SC189Q05JA','SC189Q06JA','sel_assess','SESASSESS','pct_disadv_q','ALLACTIV']
df = stu.merge(sch[sch_keep], on='CNTSCHID', how='left')

# senate-type weight: each economy sums to 5000 (pooled models); within-economy weight unchanged
df['w_senate'] = df.W_FSTUWT / df.groupby('CNT').W_FSTUWT.transform('sum') * 5000

df.to_csv(os.path.join(OUT,'paperA_students.csv.gz'), index=False, compression='gzip')
try:
    df.to_parquet(os.path.join(OUT,'paperA_students.parquet'), index=False)
except Exception as e: print('parquet skipped:', e)
sch.to_csv(os.path.join(OUT,'paperA_schools.csv'), index=False)
pd.DataFrame({'CNT':CNTS,'economy':[NAMES[c] for c in CNTS],'bloc':[BLOC_OF[c] for c in CNTS],'modal_grade':[modal[c] for c in CNTS]}).to_csv(os.path.join(OUT,'paperA_economies.csv'), index=False)
print('saved', df.shape, 'schools', sch.shape, round(time.time()-t0,1),'s')
print(df.groupby('bloc').size())
