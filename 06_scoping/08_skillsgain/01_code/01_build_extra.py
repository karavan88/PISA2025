"""
Skills & the Grade Gain -- extra student variables not carried by the grade-gain build: books at home (SES proxy for Costa Rica, where
ESCS and all its components are missing), alternative SES components (HISEI, PAREDINT, HOMEPOS) and family support (FAMSUP).
Run from repo root:  python3 02_scripts/skillsgain/01_build_extra.py   (pyreadstat; ~1 min)
Output: 01_data/derived/skillsgain_extra.csv.gz (CNTSTUID + the variables below, the 20 study systems only)
"""
import os, pandas as pd, pyreadstat
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SYS = ['KEN','QCI','MUS','TAP','PRY','KHM','PER','ECU','BRA','ARE','HKG','BRN','PHL','CRI','CZE','EST','DEU','SVK','FIN','HRV']
cols = ['CNT','CNTSTUID','ST255Q01JA','HISEI','PAREDINT','HOMEPOS','FAMSUP']
d, _ = pyreadstat.read_sav(os.path.join(ROOT, '01_data', 'CY09_MS_STU_PUF.sav'), usecols=cols)
d = d[d.CNT.isin(SYS)].rename(columns={'ST255Q01JA': 'books'})
d.drop(columns='CNT').to_csv(os.path.join(ROOT, '01_data', 'derived', 'skillsgain_extra.csv.gz'), index=False, compression='gzip')
print(d.groupby('CNT').apply(lambda g: g.notna().mean().round(2)).to_string())
