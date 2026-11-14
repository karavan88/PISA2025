"""Read-only PISA 2025 feasibility audit; no outcome models are estimated."""
from pathlib import Path
import json, re
import numpy as np
import pandas as pd
import pyreadstat
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'03_outputs/caucasus_central_asia'; OUT.mkdir(exist_ok=True)
path=ROOT/'01_data/CY09_MS_STU_PUF.sav'
_,meta=pyreadstat.read_sav(path,metadataonly=True)
systems=['ARM','AZE','GEO','KAZ','KGZ','QTJ','UZB']
base=['CNT','CNTSCHID','CNTSTUID','ST001D01T','ST003D02T','ST003D03T','AGE','ESCS','W_FSTUWT','REPEAT']
pvs=[n for n in meta.column_names if re.fullmatch(r'PV\d+(SCIE|MATH|READ)',n)]
d,_=pyreadstat.read_sav(path,usecols=base+pvs)
d=d[d.CNT.isin(systems)].copy()
rows=[]
for c,g in d.groupby('CNT'):
 schoolgrades=g.groupby('CNTSCHID').ST001D01T.nunique()
 agegrade=g.groupby('AGE').ST001D01T.nunique()
 row=dict(system=c,students=len(g),schools=g.CNTSCHID.nunique(),age_values=g.AGE.nunique(),age_min=g.AGE.min(),age_max=g.AGE.max(),birth_month_missing=g.ST003D02T.isna().mean(),birth_year_missing=g.ST003D03T.isna().mean(),escs_missing=g.ESCS.isna().mean(),grade_missing=g.ST001D01T.isna().mean(),mixed_grade_schools=int((schoolgrades>1).sum()),student_share_mixed_grade=np.average(g.CNTSCHID.map(schoolgrades).gt(1),weights=g.W_FSTUWT),age_groups_multiple_grades=int((agegrade>1).sum()),grades=','.join(str(int(x)) for x in sorted(g.ST001D01T.dropna().unique())))
 for domain in ['SCIE','MATH','READ']:
  cols=[n for n in pvs if n.endswith(domain)]
  row[domain+'_pv_count']=len(cols)
  row[domain+'_all_pv_available']=int(g[cols].notna().all(axis=1).sum())
 rows.append(row)
pd.DataFrame(rows).to_csv(OUT/'feasibility.csv',index=False)
d.groupby(['CNT','AGE','ST001D01T'],dropna=False).size().reset_index(name='n').to_csv(OUT/'age_grade_support.csv',index=False)
metadata={f:{'label':meta.column_names_to_labels[f]} for f in base+pvs}
metadata['date_fields']={n:l for n,l in zip(meta.column_names,meta.column_labels) if re.search(r'date|birth',str(l),re.I)}
metadata['replicate_weights']=[n for n in meta.column_names if re.fullmatch('W_FSTURWT[0-9]+',n)]
(OUT/'metadata.json').write_text(json.dumps(metadata,indent=2))
print(pd.DataFrame(rows).to_string(index=False))
print('AGE values:',{c:sorted(g.AGE.dropna().unique().tolist()) for c,g in d.groupby('CNT')})
