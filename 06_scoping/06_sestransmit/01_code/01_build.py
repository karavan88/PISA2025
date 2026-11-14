"""
sestransmit -- build the all-system student file from the PISA 2025 public-use files.
Independent of Paper A / EAP / IJED pipelines: reads only the raw PUF, writes only sestransmit_* files.
Input : 01_data/CY09_MS_STU_PUF.sav, 01_data/CY09_MS_SCH_PUF.sav
Output: 01_data/derived/sestransmit_students.csv.gz, 03_outputs/sestransmit/audit/coverage_raw.csv
Run   : python3 02_scripts/sestransmit/01_build.py   (from repo root)
"""
import os, time, numpy as np, pandas as pd, pyreadstat
t0 = time.time()
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, '01_data'); OUT = os.path.join(DATA, 'derived')
AUD = os.path.join(ROOT, '03_outputs', 'sestransmit', 'audit'); os.makedirs(AUD, exist_ok=True)

skills = ['PERSEV', 'CURIO', 'ENPROBS', 'COGABIL', 'GOALSET', 'SELFREG']
cols = (['CNT', 'CNTRYID', 'CNTSCHID', 'CNTSTUID', 'OECD', 'MALE', 'AGE', 'GRADE', 'ST001D01T', 'IMMIG', 'ST022Q01TA', 'REPEAT',
         'ESCS', 'HISEI', 'PAREDINT', 'HOMEPOS', 'ST420Q01DA'] + skills +
        [f'PV{i}{d}' for d in ['SCIE', 'MATH', 'READ'] for i in range(1, 11)] +
        ['W_FSTUWT'] + [f'W_FSTURWT{i}' for i in range(1, 81)])
stu, meta = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_STU_PUF.sav'), usecols=cols)
print('students read', stu.shape, round(time.time() - t0, 1), 's')

# country names from the value labels of CNTRYID
names = meta.variable_value_labels.get('CNTRYID', {})
stu['economy'] = stu.CNTRYID.map(names)

# controls
stu['female'] = 1 - stu.MALE                        # MALE: 1 male, 0 female/other (full coverage; ST004D01T is blank in ~15 systems)
stu['immig'] = stu.IMMIG.map({1: 0, 2: 1, 3: 1})    # any immigrant background
stu['lang_other'] = (stu.ST022Q01TA == 2).astype(float).where(stu.ST022Q01TA.notna())
stu['grade_rel'] = stu.GRADE                        # grade relative to modal grade (PISA-derived)
stu['repeated'] = stu.REPEAT
# growth mindset: single item, "intelligence can't change much"; 1/2 = (strongly) disagree -> growth mindset
stu['GROWTH'] = stu.ST420Q01DA.isin([1, 2]).astype(float).where(stu.ST420Q01DA.notna())

# school characteristics
sch, _ = pyreadstat.read_sav(os.path.join(DATA, 'CY09_MS_SCH_PUF.sav'), usecols=['CNTSCHID', 'PRIVATESCH', 'SC001Q01TA'])
sch['private'] = sch.PRIVATESCH.map({1: 0, 2: 1})
sch['urban'] = sch.SC001Q01TA.map({1: 0, 2: 0, 3: 1, 4: 2, 5: 2, 6: 2})   # 0 village/small town, 1 town, 2 city
df = stu.merge(sch[['CNTSCHID', 'private', 'urban']], on='CNTSCHID', how='left')

keep = (['CNT', 'economy', 'OECD', 'CNTSCHID', 'CNTSTUID', 'female', 'AGE', 'grade_rel', 'repeated', 'immig', 'lang_other',
         'ESCS', 'HISEI', 'PAREDINT', 'HOMEPOS', 'GROWTH'] + skills + ['private', 'urban'] +
        [c for c in cols if c.startswith('PV') or c.startswith('W_FSTU')])
df = df[keep]
df.to_csv(os.path.join(OUT, 'sestransmit_students.csv.gz'), index=False, compression='gzip')

cov = df.groupby(['CNT', 'economy']).apply(lambda x: pd.Series(
    {'N': len(x), 'OECD': x.OECD.iloc[0], **{c: round(x[c].notna().mean(), 3) for c in
     ['ESCS', 'GROWTH'] + skills + ['female', 'AGE', 'grade_rel', 'immig', 'lang_other', 'CNTSCHID', 'private', 'PV1SCIE', 'PV1READ', 'PV1MATH']}}))
cov.reset_index().to_csv(os.path.join(AUD, 'coverage_raw.csv'), index=False)
print('saved', df.shape, round(time.time() - t0, 1), 's')
