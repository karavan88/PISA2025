from pathlib import Path
import numpy as np,pandas as pd
R=Path(__file__).resolve().parents[2];O=R/'03_outputs/caucasus_central_asia';a=pd.read_csv(R/'01_data/derived/caucasus_central_asia/analysis_input.csv.gz');rows=[]
for cc,f in a.groupby('CNT'):
 ok=f[['ST001D01T','AGE','ESCS','ST004D01T','ST022Q01TA']].notna().all(axis=1).to_numpy()
 W=f[['W_FSTUWT']+[f'W_FSTURWT{j}' for j in range(1,81)]].to_numpy()
 for dom in ['SCIE','MATH','READ']:
  Y=f[[f'PV{k}{dom}' for k in range(1,11)]].to_numpy()
  if np.isnan(Y).all():continue
  inmean=W[ok].T@Y[ok]/W[ok].sum(axis=0)[:,None];outmean=W[~ok].T@Y[~ok]/W[~ok].sum(axis=0)[:,None]
  for term,b in [('retained_mean',inmean),('excluded_mean',outmean),('retained_minus_excluded',inmean-outmean)]:
   q=b[0].mean();v=np.mean(np.sum((b[1:]-b[0])**2,axis=0)/20)+1.1*np.var(b[0],ddof=1);se=np.sqrt(v)
   rows.append(dict(CNT=cc,domain=dom,term=term,est=q,se=se,lo=q-1.96*se,hi=q+1.96*se))
pd.DataFrame(rows).to_csv(O/'selection.csv',index=False)
print(pd.DataFrame(rows).query('domain=="SCIE" and term=="retained_minus_excluded"').round(2).to_string(index=False))
