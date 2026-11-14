"""
Positive-control extract: systems with a mid-year school-entry cutoff where a school year is known to produce large PISA gains.
Same estimator as 05_rd.R is then applied in 09_benchmark_rd.R. Run from repo root: python3 02_scripts/epf_postsoviet/08_benchmark_extract.py
Output: 01_data/derived/epf_benchmark.csv.gz
"""
import os, numpy as np, pandas as pd, pyreadstat
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))); DATA = os.path.join(ROOT, '01_data')
BENCH = ['CZE','AUT','DEU','NLD','GBR','EST','TAP','HRV','SRB','LVA','LTU','POL','SVK','HUN','TUR','ITA','ESP','FRA']
cols = ['CNT','CNTSCHID','CNTSTUID','ST001D01T','ISCEDP','ST003D02T','ST003D03T','AGE','REPEAT','ST004D01T','ESCS','W_FSTUWT'] + \
       [f'PV{i}{d}' for d in ['SCIE','MATH','READ'] for i in range(1,11)] + [f'W_FSTURWT{i}' for i in range(1,81)]
d, meta = pyreadstat.read_sav(os.path.join(DATA,'CY09_MS_STU_PUF.sav'), usecols=cols)
d = d[d.CNT.isin(BENCH)].copy()
print(d.groupby('CNT').size())
print(d.groupby('CNT').ST003D03T.value_counts(normalize=True).round(2).unstack())
d.to_csv(os.path.join(DATA,'derived','epf_benchmark.csv.gz'), index=False, compression='gzip')
print('written', d.shape)
