"""
Grade Gain Report -- build the student file for every PISA 2025 system that could carry the school-entry-cutoff design.
Candidates = systems whose audit profile (03_outputs/paperB/cutoff_audit_all.csv: P(upper grade) by birth month, general programmes)
shows a largest adjacent-month drop of at least 0.15 and more than one grade. The formal eligibility rule is applied in 02_prepare.R
on the analysis sample (all programmes). Run from repo root:  python3 02_scripts/gradegain/01_build.py   (pyreadstat, pandas; ~1 min)
Output: 01_data/derived/gradegain_students.csv.gz, 01_data/derived/gradegain_systems.csv (CNT, name, OECD, audit jump)
"""
import os, time, numpy as np, pandas as pd, pyreadstat
t0 = time.time()
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived'); os.makedirs(OUT, exist_ok=True)
audit = pd.read_csv(os.path.join(ROOT, '03_outputs', 'paperB', 'cutoff_audit_all.csv'))
cand = audit[(audit.jump >= 0.15) & (audit.profile != 'single grade')]
SYS = sorted(cand.CNT.tolist())
print(len(SYS), 'candidate systems:', ' '.join(SYS))
ids   = ['CNT','CNTSCHID','CNTSTUID','STRATUM','OECD']
demo  = ['ST001D01T','ISCEDP','ST003D02T','ST003D03T','AGE','REPEAT','ST004D01T','ST022Q01TA','IMMIG','LANGTEST_COG']
ses   = ['ESCS']
skill = ['PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','ST420Q01DA','BELONG']
pvs   = [f'PV{i}{d}' for d in ['SCIE','MATH','READ'] for i in range(1,11)]
wts   = ['W_FSTUWT','SENWT'] + [f'W_FSTURWT{i}' for i in range(1,81)]
stu, meta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_STU_PUF.sav'), usecols=ids+demo+ses+skill+pvs+wts)
stu = stu[stu.CNT.isin(SYS)].copy()
print('students read', stu.shape, round(time.time()-t0,1), 's')
d = stu
names = meta.variable_value_labels.get('CNT', {})
d['byear']   = d.ST003D03T.where(d.ST003D03T < 2100, d.ST003D03T - 543)     # Thai Buddhist calendar
d['bmonth']  = d.ST003D02T
d['grade']   = d.ST001D01T
d['female']  = np.where(d.ST004D01T.isna(), np.nan, (d.ST004D01T == 1).astype(float))
d['lang_other'] = np.where(d.ST022Q01TA.isna(), np.nan, (d.ST022Q01TA == 2).astype(float))
d['immigrant']  = np.where(d.IMMIG.isna(), np.nan, (d.IMMIG > 1).astype(float))
d['repeated']   = np.where(d.REPEAT.isna(), np.nan, (d.REPEAT == 1).astype(float))
d['vocational'] = d.ISCEDP.isin([254, 354]).astype(int)
d['growth']  = np.where(d.ST420Q01DA.isna(), np.nan, d.ST420Q01DA.isin([1, 2]).astype(float))
keep = ['CNT','OECD','CNTSCHID','CNTSTUID','STRATUM','grade','ISCEDP','vocational','byear','bmonth','AGE','female','lang_other','immigrant','repeated','ESCS',
        'PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','BELONG','growth'] + pvs + wts
d[keep].to_csv(os.path.join(OUT, 'gradegain_students.csv.gz'), index=False, compression='gzip')
sysinfo = cand[['CNT','jump','cut','profile']].copy(); sysinfo['name'] = sysinfo.CNT.map(names); sysinfo['OECD'] = sysinfo.CNT.map(d.groupby('CNT').OECD.first())
sysinfo.rename(columns={'jump':'audit_jump','cut':'audit_cut'}).to_csv(os.path.join(OUT, 'gradegain_systems.csv'), index=False)
print('written', d.shape, round(time.time()-t0,1), 's')
print(d.groupby('CNT').size().to_string())
