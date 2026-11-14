"""
Paper B -- Does schooling make you persevere? Fuzzy RD at the school-entry cutoff, PISA 2025.
Builds the student file for the systems with a sharp, clean entry cutoff (jump in P(upper grade) >= 0.45 across one birth month,
flat elsewhere; see 03_outputs/paperB/cutoff_audit_all.csv). Run from repo root:  python3 02_scripts/paperB/01_build.py
Output: 01_data/derived/paperB_students.csv.gz  (one row per student, all PVs + 80 BRR replicate weights)
"""
import os, time, numpy as np, pandas as pd, pyreadstat
t0 = time.time()
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived'); os.makedirs(OUT, exist_ok=True)
# Tier 1 (sharp, jump >= 0.45) and tier 2 (fuzzy, jump 0.25-0.45; appendix check). Tiers are set in 00_helpers.R; the build keeps both.
SYS = ['TAP','KOR','FIN','QCI','PER','SRB','BRN','PHL','HKG','EST','PRY','HRV','GEO','SVK',
       'KAZ','ALB','NZL','BRA','AZE','MNE','KSV','CHL','ISR','CRI','USA','KEN','KHM','MUS']
ids   = ['CNT','CNTSCHID','CNTSTUID','STRATUM','REGION','OECD']
demo  = ['ST001D01T','GRADE','ISCEDP','PROGN','ST003D02T','ST003D03T','AGE','REPEAT','ST004D01T','ST022Q01TA','IMMIG','LANGTEST_COG','EXPECEDU']
ses   = ['ESCS','HISEI','PAREDINT','HOMEPOS']
skill = ['PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','ST420Q01DA','ST420Q02DA','ST493Q01DA','BELONG']
pvs   = [f'PV{i}{d}' for d in ['SCIE','MATH','READ'] for i in range(1,11)]
wts   = ['W_FSTUWT','SENWT'] + [f'W_FSTURWT{i}' for i in range(1,81)]
stu, meta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_STU_PUF.sav'), usecols=ids+demo+ses+skill+pvs+wts)
stu = stu[stu.CNT.isin(SYS)].copy()
print('students read', stu.shape, round(time.time()-t0,1), 's')
d = stu
d['economy'] = d.CNT.map(meta.variable_value_labels.get('CNT', {}))
d['byear']   = d.ST003D03T.where(d.ST003D03T < 2100, d.ST003D03T - 543)     # Thai Buddhist calendar guard (not needed here, kept for safety)
d['bmonth']  = d.ST003D02T
d['grade']   = d.ST001D01T
d['female']  = np.where(d.ST004D01T.isna(), np.nan, (d.ST004D01T == 1).astype(float))
d['lang_other'] = np.where(d.ST022Q01TA.isna(), np.nan, (d.ST022Q01TA == 2).astype(float))
d['immigrant']  = np.where(d.IMMIG.isna(), np.nan, (d.IMMIG > 1).astype(float))
d['repeated']   = np.where(d.REPEAT.isna(), np.nan, (d.REPEAT == 1).astype(float))
d['vocational'] = d.ISCEDP.isin([254, 354]).astype(int)
d['growth']  = np.where(d.ST420Q01DA.isna(), np.nan, d.ST420Q01DA.isin([1, 2]).astype(float))   # disagrees that intelligence is fixed
d['growth_sci'] = np.where(d.ST420Q02DA.isna(), np.nan, d.ST420Q02DA.isin([1, 2]).astype(float))
d['fatalism'] = np.where(d.ST493Q01DA.isna(), np.nan, d.ST493Q01DA.isin([3, 4]).astype(float))  # agrees status cannot be changed
keep = ['CNT','economy','OECD','CNTSCHID','CNTSTUID','STRATUM','REGION','grade','GRADE','ISCEDP','PROGN','vocational','byear','bmonth','AGE',
        'female','lang_other','immigrant','repeated','LANGTEST_COG','EXPECEDU','ESCS','HISEI','PAREDINT','HOMEPOS',
        'PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','BELONG','growth','growth_sci','fatalism'] + pvs + wts
d[keep].to_csv(os.path.join(OUT, 'paperB_students.csv.gz'), index=False, compression='gzip')
print('written', d.shape, round(time.time()-t0,1), 's')
print(d.groupby('CNT').agg(n=('CNT','size'), schools=('CNTSCHID','nunique'), grade_na=('grade', lambda x: x.isna().mean()), bm_na=('bmonth', lambda x: x.isna().mean()),
      escs=('ESCS', lambda x: x.notna().mean()), persev=('PERSEV', lambda x: x.notna().mean()), curio=('CURIO', lambda x: x.notna().mean()), belong=('BELONG', lambda x: x.notna().mean())).round(3).to_string())
