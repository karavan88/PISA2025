"""Numerical and structural checks independent of the R reporting pipeline."""
from pathlib import Path
import json
import numpy as np
import pandas as pd
from bs4 import BeautifulSoup
R=Path(__file__).resolve().parents[2];O=R/'03_outputs/caucasus_central_asia'
r=pd.read_csv(O/'regression.csv');d=pd.read_csv(O/'descriptive.csv');f=pd.read_csv(O/'forest_deciles.csv');c=pd.read_csv(O/'forest_contrasts.csv');s=pd.read_csv(O/'sensitivity.csv');p=pd.read_csv(O/'peer_check.csv')
assert len(r[['CNT','domain']].drop_duplicates())==19
assert len(f)==380 and len(c)==38
assert r.npv.eq(10).all() and f.npv.eq(10).all()
assert not ((r.CNT=='UZB')&(r.domain!='SCIE')).any()
assert np.isfinite(r.loc[~r.term.str.startswith('agegroup'),['est','se']]).all().all()
# Global factor levels produce non-estimable nuisance contrasts in absent age categories.
assert r.loc[r.est.isna(),'term'].str.startswith('agegroup').all()
v=d.pivot(index=['CNT','domain'],columns='term',values='est')
assert np.allclose(v.total,v.between+v.within,rtol=1e-9)
assert v.between_share.between(0,1).all()
# Contextual contrast equals theta_B - theta_W, pooled over identical PV estimates.
z=r[(r.spec=='within_between')&r.term.isin(['sb','sw'])].pivot(index=['CNT','domain'],columns='term',values='est')
ctx=pd.read_csv(O/'diagnostics.csv');ctx=ctx[(ctx['sample']=='all')&(ctx.term=='contextual')].set_index(['CNT','domain'])
assert np.allclose(z.sb-z.sw,ctx.est.reindex(z.index),rtol=1e-8,atol=1e-8)
# Holm adjustment recomputed independently.
ix=np.argsort(c.p.to_numpy());adjusted=np.maximum.accumulate((len(c)-np.arange(len(c)))*c.p.to_numpy()[ix]).clip(0,1);back=np.empty(len(c));back[ix]=adjusted
assert np.allclose(back,c.p_holm)
# Independent numpy fit for AZE science, all PVs, including replicate variance.
a=pd.read_csv(R/'01_data/derived/caucasus_central_asia/analysis_input.csv.gz');rn=[x for x in a if x.startswith('W_FSTURWT')];assert len(rn)==80
q=a[a.CNT=='AZE'].dropna(subset=['ST001D01T','AGE','ESCS','ST004D01T','ST022Q01TA']).copy();assert len(q)==6596
q['female']=(q.ST004D01T==1).astype(float);q['lang']=(q.ST022Q01TA!=1).astype(float);q['grade']=q.ST001D01T;q['age']=np.round(12*q.AGE).astype(int)
age=pd.get_dummies(q.age,drop_first=True,dtype=float).to_numpy();Y=q[[f'PV{k}SCIE' for k in range(1,11)]].to_numpy()
def estimate(w):
 means=[]
 for v in ['grade','ESCS','female','lang']:
  sums=pd.Series(w*q[v].to_numpy(),index=q.index).groupby(q.CNTSCHID).transform('sum').to_numpy();den=pd.Series(w,index=q.index).groupby(q.CNTSCHID).transform('sum').to_numpy();means.append(sums/den)
 gb,sb,fb,lb=means
 X=np.column_stack([np.ones(len(q)),q.grade-gb,gb,q.ESCS-sb,sb,q.female,q.lang,fb,lb,age])
 b=np.linalg.lstsq(X*np.sqrt(w[:,None]),Y*np.sqrt(w[:,None]),rcond=None)[0]
 return b[1]
b=estimate(q.W_FSTUWT.to_numpy());br=np.array([estimate(q[n].to_numpy()) for n in rn]);se=np.sqrt(np.mean(np.sum((br-b)**2,axis=0)/20)+1.1*np.var(b,ddof=1))
ref=r[(r.CNT=='AZE')&(r.domain=='SCIE')&(r.spec=='within_between')&(r.term=='gw')].iloc[0]
assert np.allclose([b.mean(),se],[ref.est,ref.se],atol=1e-7)
# Every model family has all systems and supported domains.
assert set(s.CNT)==set(a.CNT)
assert len(p[['CNT','domain']].drop_duplicates())==19
report=R/'04_manuscripts/caucasus_central_asia/report.html';soup=BeautifulSoup(report.read_text(),'html.parser')
assert 'LAYOUT PREVIEW' not in soup.get_text()
assert len(json.loads((O/'metadata.json').read_text())['replicate_weights'])==80
assert len(soup.find_all('img'))==6
assert all(im['src'].startswith('data:image/png;base64,') for im in soup.find_all('img'))
assert len(soup.find_all('table'))>=10
assert all(soup.find(id=x['href'][1:]) is not None for x in soup.select('nav a'))
assert 'nan' not in soup.get_text().lower().split()
result={'status':'passed','system_domain_combinations':19,'plausible_values':10,'replicate_weights':80,'forest_decile_estimates':len(f),'forest_contrasts':len(c),'independent_AZE_science_estimate':float(b.mean()),'independent_AZE_science_SE':float(se),'variance_identity':'passed','contextual_contrast_identity':'passed','Holm_adjustment':'passed','embedded_figures':6}
(O/'validation.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
