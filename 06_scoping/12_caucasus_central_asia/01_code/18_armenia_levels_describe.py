from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import t
R=Path.cwd();O=R/'03_outputs/caucasus_central_asia/armenia_levels'
a=pd.read_csv(R/'01_data/derived/caucasus_central_asia/analysis_input.csv.gz');a=a[a.CNT.eq('ARM')].copy()
b=a.dropna(subset=['AGE','ST001D01T','ST004D01T','ST022Q01TA']);d=b.dropna(subset=['HOMEPOS']).copy();weights=['W_FSTUWT']+[f'W_FSTURWT{i}' for i in range(1,81)]
def mean(x,w):return np.average(x,weights=w)
def schoolmean(z,v,w):
 sw=z.groupby('CNTSCHID')[w].transform('sum');sy=(z[v]*z[w]).groupby(z.CNTSCHID).transform('sum');return sy/sw

def pool(x):
 est=x[:,0].mean();u=np.mean(np.sum((x[:,1:]-x[:,:1])**2,axis=1)/20);bb=x[:,0].var(ddof=1);se=np.sqrt(u+1.1*bb);df=9*(1+u/(1.1*bb))**2 if bb>1e-14 else np.inf;c=t.ppf(.975,df);return dict(est=est,se=se,lo=est-c*se,hi=est+c*se)
rows=[];cuts=[]
for v in ['HOMEPOS','PAREDINT']:
 z=b.dropna(subset=[v]).copy();z[v+'_school']=schoolmean(z,v,'W_FSTUWT')
 for mod in [v,v+'_school']:
  ix=np.argsort(z[mod].to_numpy());xx=z[mod].to_numpy()[ix];cw=np.cumsum(z.W_FSTUWT.to_numpy()[ix]);cut=np.interp(np.array([.4,.9])*cw[-1],cw,xx);group=np.searchsorted(cut,z[mod],side='left')+1
  cuts.append(dict(moderator=mod,cut40=cut[0],cut90=cut[1]))
  for g in [1,2,3]:
   zz=z[group==g]
   if len(zz)==0:continue
   for dom in ['SCIE','MATH','READ']:
    stats=np.array([[mean(zz[f'PV{k}{dom}'],zz[w]) for w in weights] for k in range(1,11)])
    rows.append(dict(moderator=mod,group=g,domain=dom,n=len(zz),schools=zz.CNTSCHID.nunique(),**pool(stats)))
pd.DataFrame(rows).to_csv(O/'group_achievement.csv',index=False);pd.DataFrame(cuts).to_csv(O/'group_cutpoints.csv',index=False)
# Domain-specific score and resource variance partition, sample-size support, plus pooled outcome levels.
rows=[]
for name,z in [('full',a),('possessions',d),('joint',b.dropna(subset=['HOMEPOS','PAREDINT']))]:
 for dom in ['SCIE','MATH','READ']:
  pv=[]
  for k in range(1,11):
   rep=[];v=f'PV{k}{dom}'
   for w in weights:
    mu=mean(z[v],z[w]);sm=schoolmean(z,v,w);tot=mean((z[v]-mu)**2,z[w]);bt=mean((sm-mu)**2,z[w]);rep.append([mu,tot,bt,tot-bt,bt/tot])
   pv.append(rep)
  ar=np.array(pv)
  for j,term in enumerate(['mean','total','between','within','between_share']):rows.append(dict(sample=name,domain=dom,term=term,**pool(ar[:,:,j])))
pd.DataFrame(rows).to_csv(O/'descriptive.csv',index=False)
rows=[]
for name,vv in [('possessions',['HOMEPOS']),('education',['PAREDINT']),('joint',['HOMEPOS','PAREDINT']),('escs',['ESCS'])]:
 z=b.dropna(subset=vv);nc=z.groupby('CNTSCHID').size();alln=a.groupby('CNTSCHID').size()
 rows.append(dict(sample=name,n=len(z),n_loo_ses=int(z.CNTSCHID.map(nc).gt(1).sum()),n_loo_score=int(z.CNTSCHID.map(alln).gt(1).sum()),minimum_school_n=int(nc.min()),median_school_n=float(nc.median())))
pd.DataFrame(rows).to_csv(O/'peer_support.csv',index=False)
print('Descriptive results complete')
