"""
The Cost of Resilience -- student extract (all PISA 2025 systems).
Life satisfaction, socio-emotional skills, SES, achievement PVs, replicate weights, parent-rated skills, the raw items used for the
response-style indices, and questionnaire screen timings (STU_TT file) for the careless-responding check.
Run from repo root:  python3 -I 02_scripts/resilwb/01_build.py   (pyreadstat; ~2 min)
Output: 01_data/derived/resilwb_students.csv.gz
"""
import os, pandas as pd, numpy as np, pyreadstat

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data')

PV = [f'PV{i}{d}' for i in range(1, 11) for d in ['SCIE', 'MATH', 'READ']]
RW = [f'W_FSTURWT{i}' for i in range(1, 81)]
SE6 = ['PERSEV', 'CURIO', 'ENPROBS', 'COGABIL', 'GOALSET', 'SELFREG']
CTX = ['BELONG', 'BULLIED', 'FAMSUP', 'FEELSAFE', 'EFFSCIE']
SES = ['ESCS', 'HISEI', 'PAREDINT', 'HOMEPOS', 'IMMIG']
PAR = ['PQSELFREG', 'PA204Q04DA']
# response-style pool: 4-point agree/disagree items whose content is unrelated to wellbeing and to the skill scales
# (nature of science ST131, environmental agency ST499/ST500, environmental teaching ST501). ST131Q05/Q17 run against the others.
RS4 = ['ST131Q04NA', 'ST131Q10DA', 'ST131Q12DA', 'ST131Q05DA', 'ST131Q13DA', 'ST131Q17DA',
       'ST499Q02DA', 'ST499Q04DA', 'ST499Q05DA', 'ST499Q06DA',
       'ST500Q03DA', 'ST500Q05DA', 'ST500Q06DA', 'ST500Q09DA',
       'ST501Q03DA', 'ST501Q05DA', 'ST501Q06DA', 'ST501Q07DA']
# 5-point agree items of the perseverance and curiosity scales (secondary extreme-response index; shares content with the skills)
RS5 = ['ST307Q01JA', 'ST307Q02JA', 'ST307Q03JA', 'ST307Q07JA', 'ST307Q09JA', 'ST307Q10JA',
       'ST301Q01JA', 'ST301Q04JA', 'ST301Q06JA', 'ST301Q08JA', 'ST301Q10JA']
ID = ['CNT', 'CNTSCHID', 'CNTSTUID', 'ST004D01T', 'MALE', 'AGE', 'GRADE', 'W_FSTUWT']   # MALE (sampling frame) where ST004D01T is withheld
OUTC = ['ST016Q01NA', 'SISCO', 'EXPECEDU']
# placebo numeric scales (1-10 thermometers): effort on the test, effort had it counted, effort on the questionnaire
PLAC = ['EFFORT1', 'EFFORT2', 'ST331Q03JA']

cols = ID + OUTC + PLAC + SE6 + CTX + SES + PAR + RS4 + RS5 + PV + RW
d, _ = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_STU_PUF.sav'), usecols=cols)

# questionnaire timing for the grid screens behind the response-style and skill items -> seconds per item
SCREENS = {'ST131': 6, 'ST499': 4, 'ST500': 4, 'ST501': 4, 'ST307': 6, 'ST301': 5, 'ST435': 4, 'ST216': 4, 'ST432': 4}
tt, _ = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_STU_TT_PUF.sav'), encoding='latin1',
                            usecols=['CNTSTUID'] + [f'{s}_TT' for s in SCREENS] + ['ST016_TT'])
spi = pd.DataFrame({s: tt[f'{s}_TT'] / n for s, n in SCREENS.items()})
tt['sec_per_item'] = spi.median(axis=1, skipna=True)      # median over screens: robust to one screen left open
tt['n_screens_timed'] = spi.notna().sum(axis=1)
d = d.merge(tt[['CNTSTUID', 'sec_per_item', 'n_screens_timed', 'ST016_TT']], on='CNTSTUID', how='left')

out = os.path.join(DATA, 'derived', 'resilwb_students.csv.gz')
d.to_csv(out, index=False, compression='gzip')
print(d.shape, '->', out)
print('sec_per_item quantiles:', d.sec_per_item.quantile([.01, .05, .25, .5, .75, .95]).round(2).to_dict())
cov = d[['ST016Q01NA', 'PERSEV', 'ESCS', 'PV1MATH', 'PQSELFREG', 'ST131Q04NA', 'ST499Q02DA', 'ST501Q03DA', 'ST307Q01JA', 'sec_per_item']].notna().groupby(d.CNT).mean().round(2)
print(cov.to_string())
