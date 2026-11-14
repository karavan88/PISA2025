"""Independent numerical checks for the Armenia redesign. Run from repo root."""
from pathlib import Path
import json
import numpy as np
import pandas as pd
from scipy.stats import t
from bs4 import BeautifulSoup
R=Path.cwd(); O=R/'03_outputs/caucasus_central_asia/armenia_redesign'; D=R/'01_data/derived/caucasus_central_asia/armenia_redesign'; M=R/'04_manuscripts/caucasus_central_asia'
checks=[]
def check(name, condition):
    assert condition, name
    checks.append(name)
for name,keys,count in [('forest_average',['spec','domain'],21),('forest_groups',['spec','domain','moderator','group'],159),('forest_contrasts',['spec','domain','moderator'],54),('school_FE_benchmark',['spec','domain'],21)]:
    pooled=pd.read_csv(O/(name+'.csv')); raw=pd.read_csv(O/(name+'_pv.csv'))
    check(name+' dimensions',len(pooled)==count and len(raw)==count*10)
    for key,z in raw.groupby(keys):
        q=pooled
        for k,v in zip(keys,key):q=q[q[k]==v]
        a=q.iloc[0]; u=np.mean(z.se**2); b=z.est.var(ddof=1); se=np.sqrt(u+1.1*b); df=min(z.df_cluster.min(),9*(1+u/(1.1*b))**2 if b>=1e-14 else np.inf); est=z.est.mean()
        expected=[est,se,est-t.ppf(.975,df)*se,est+t.ppf(.975,df)*se,df,2*t.sf(abs(est/se),df)]
        assert np.allclose(a[['est','se','lo','hi','df','p']].astype(float),expected,rtol=1e-9,atol=1e-9),(name,key)
    checks.append(name+' independent PV pooling and intervals')
raw=pd.read_csv(O/'forest_average_pv.csv')
for dom in ['SCIE','MATH','READ']:
    d=pd.read_csv(D/f'validation_residuals_{dom}.csv'); X=np.column_stack([np.ones(len(d)),d.wr]); w=d.w.to_numpy(); y=d.yr.to_numpy(); bread=np.linalg.inv(X.T@(w[:,None]*X)); coef=bread@(X.T@(w*y)); residual=y-X@coef
    scores=pd.DataFrame(X*(w*residual)[:,None]).groupby(d.school).sum().to_numpy(); G=d.school.nunique(); n=len(d); cov=bread@(scores.T@scores)@bread*(G/(G-1))*((n-1)/(n-2)); se=np.sqrt(cov[1,1])
    row=raw[(raw.spec=='possessions_main')&(raw.domain==dom)&(raw.pv==1)].iloc[0]
    check(dom+' independent overlap coefficient and school-cluster SE',np.allclose([coef[1],se],[row.est,row.se],rtol=1e-8))
    check(dom+' main observed support',len(d)==1758 and G==80 and (d.W==0).sum()==348 and (d.W==1).sum()==1410 and d.e.between(.1,.9).all())
c=pd.read_csv(O/'forest_contrasts.csv')
for family,z in c.groupby('family'):
    p=z.p.to_numpy(); ix=np.argsort(p); expected=np.empty(len(p)); expected[ix]=np.minimum(1,np.maximum.accumulate((len(p)-np.arange(len(p)))*p[ix]));check(family+' Holm correction',np.allclose(expected,z.p_holm))
v=pd.read_csv(O/'variance_partition.csv');check('weighted variance partition',np.allclose(v.total,v.between+v.within))
b=pd.read_csv(O/'school_FE_benchmark.csv');check('benchmark outcomes distinct',b[b.spec=='possessions_main'].est.nunique()==3)
soup=BeautifulSoup((M/'armenia_redesign.html').read_text(),'html.parser');check('four embedded figures',len(soup.select('img[src^="data:image/png;base64,"]'))==4)
check('navigation targets',all(soup.find(id=a['href'][1:]) for a in soup.select('a[href^="#"]')))
check('active report updated',(M/'report.html').read_bytes()==(M/'armenia_redesign.html').read_bytes())
check('regional report preserved',(M/'report_regional_before_armenia_redesign.html').exists())
check('no missing numeric values in report','NaN' not in soup.get_text())
result={'status':'passed','checks':checks,'note':'Conditional cluster/PV inference; no complete survey-replicate forest refits.'};(O/'validation.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
