"""
School Inputs & the Grade Gain -- school questionnaire inputs and student-reported school climate for the 20 study systems.
Run from repo root:  python3 02_scripts/schoolgain/01_build.py   (pyreadstat; ~1 min)
Output: 01_data/derived/schoolgain_school.csv (one row per school: questionnaire indices and items); student climate scales and the
        engagement mediators (skipping, lateness, test effort, work for pay) in schoolgain_stu.csv.gz
        01_data/derived/schoolgain_stu.csv.gz (CNTSTUID + student-reported climate scales, aggregated to schools in 02_prepare.R)
"""
import os, pandas as pd, pyreadstat
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived')
SYS = ['KEN','QCI','MUS','TAP','PRY','KHM','PER','ECU','BRA','ARE','HKG','BRN','PHL','CRI','CZE','EST','DEU','SVK','FIN','HRV']
SCH = ['CNT','CNTSCHID','CLSIZE','STRATIO_Q','SCHSIZE_Q','EDUSHORT','STAFFSHORT','DIGPREP','PROATCE','PROPAT7','SCTRAIN','PROPSUPP','PROWBST',
       'EDULEAD','SCHSEL','ABGSCIE','SCHLTYPE','STDTEST','TDTEST','PRIORLRN','NEGSCLIM','ALLACTIV','ENCOURPG','SC001Q01TA','SC013Q01TA']
s, _ = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_SCH_PUF.sav'), usecols=SCH)
s = s[s.CNT.isin(SYS)]
s.drop(columns='CNT').to_csv(os.path.join(OUT, 'schoolgain_school.csv'), index=False)
STU = ['CNT','CNTSTUID','DISCLISCI','TEACHSUP','COGACSC','BULLIED','FEELSAFE','SKIPPING','TARDYSD','EFFORT1','WORKPAY']
d, _ = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_STU_PUF.sav'), usecols=STU)
d = d[d.CNT.isin(SYS)]
d.drop(columns='CNT').to_csv(os.path.join(OUT, 'schoolgain_stu.csv.gz'), index=False, compression='gzip')
print(s.shape, d.shape)
print(d[STU[2:]].notna().groupby(d.CNT).mean().round(2).to_string())
