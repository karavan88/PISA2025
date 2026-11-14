from pathlib import Path
import json
import numpy as np
import pandas as pd
from scipy.stats import t
from bs4 import BeautifulSoup
R=Path.cwd();O=R/'03_outputs/caucasus_central_asia/armenia_levels';M=R/'04_manuscripts/caucasus_central_asia';checks=[]
def check(n,c):
 assert c,n
 checks.append(n)
a=pd.read_csv(R/'01_data/derived/caucasus_central_asia/analysis_input.csv.gz');a=a[a.CNT.eq('ARM')];d=a.dropna(subset=['AGE','ST001D01T','ST004D01T','ST022Q01TA','HOMEPOS']).copy();d['age']=np.round(d.AGE*12).astype(int);d['grade']=d.ST001D01T.astype(int)
controls=pd.get_dummies(d[['age','grade']].astype(str),drop_first=True,dtype=float).to_numpy();Y=d[[f'PV{k}{dom}' for dom in ['SCIE','MATH','READ'] for k in range(1,11)]].to_numpy();allb=[]
for wname in ['W_FSTUWT']+[f'W_FSTURWT{i}' for i in range(1,81)]:
 w=d[wname].to_numpy();sm=(d.HOMEPOS*d[wname]).groupby(d.CNTSCHID).transform('sum')/d.groupby('CNTSCHID')[wname].transform('sum');X=np.column_stack([np.ones(len(d)),d.HOMEPOS,sm,(d.ST004D01T==1).astype(float),(d.ST022Q01TA!=1).astype(float),controls]);sw=np.sqrt(w);allb.append(np.linalg.lstsq(X*sw[:,None],Y*sw[:,None],rcond=None)[0][:3])
allb=np.array(allb);raw=pd.read_csv(O/'regression_pv.csv');pooled=pd.read_csv(O/'regression.csv')
for j,dom in enumerate(['SCIE','MATH','READ']):
 for term,index in [('HOMEPOS',1),('HOMEPOS_school',2)]:
  rr=raw[(raw['sample']=='possessions')&(raw.domain==dom)&(raw.model=='composition')&(raw.term==term)].sort_values('pv');bb=allb[0,index,j*10:(j+1)*10];ss=np.sqrt(((allb[1:,index,j*10:(j+1)*10]-bb)**2).sum(axis=0)/20)
  check(dom+' '+term+' independent coefficients and 80-replicate SEs',np.allclose(rr.est,bb,atol=1e-8) and np.allclose(rr.se,ss,atol=1e-8))
for keys,z in raw[np.isfinite(raw.est)&np.isfinite(raw.se)].groupby(['sample','domain','model','term']):
 q=pooled
 for k,v in zip(['sample','domain','model','term'],keys):q=q[q[k]==v]
 r=q.iloc[0];check_count=len(z)==10
 assert check_count,keys
 est=z.est.mean();u=np.mean(z.se**2);b=z.est.var(ddof=1);se=np.sqrt(u+1.1*b);df=9*(1+u/(1.1*b))**2 if b>=1e-14 else np.inf;crit=t.ppf(.975,df)
 assert np.allclose([r.est,r.se,r.lo,r.hi],[est,se,est-crit*se,est+crit*se],atol=1e-8),keys
checks.append('All finite regression estimates pool ten PVs and correct BRR/PV intervals')
c=pd.read_csv(O/'coverage.csv');check('main sample restored',int(c[c['sample']=='possessions'].n.iloc[0])==5429)
desc=pd.read_csv(O/'descriptive.csv').pivot(index=['sample','domain'],columns='term',values='est');check('variance partitions',np.allclose(desc.total,desc.between+desc.within))
for model in ['composition','school_FE','loo_composition','peer_score','joint_peer']:
 check(model+' all samples and domains',len(pooled[pooled.model==model][['sample','domain']].drop_duplicates())==21)
text=(M/'armenia_achievement_context.html').read_text();soup=BeautifulSoup(text,'html.parser');check('embedded figures',len(soup.select('img[src^="data:image/png;base64,"]'))==3);check('no numeric missingness in report','NaN' not in soup.get_text());check('active report matches',(M/'report.html').read_text()==text)
(O/'validation.json').write_text(json.dumps({'status':'passed','checks':checks},indent=2));print('Passed',len(checks),'validation checks')
