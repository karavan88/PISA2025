from pathlib import Path
import pyreadstat,re
R=Path(__file__).resolve().parents[2]
p=R/'01_data/CY09_MS_STU_PUF.sav'
_,m=pyreadstat.read_sav(p,metadataonly=True)
cols=['CNT','CNTSCHID','CNTSTUID','ST001D01T','ST003D02T','ST003D03T','AGE','ESCS','W_FSTUWT','REPEAT','ST004D01T','ST022Q01TA','IMMIG','HISEI','PAREDINT','HOMEPOS','ST250Q02JA','ST250Q05JA','ST250Q08DA','ST250Q09DA','ST250Q12DA','ST250Q15DA','ST250Q16DA','ST250Q20DA']+[n for n in m.column_names if re.fullmatch(r'PV\d+(SCIE|MATH|READ)|W_FSTURWT\d+',n)]
d,_=pyreadstat.read_sav(p,usecols=cols)
d=d[d.CNT.isin(['ARM','AZE','GEO','KAZ','KGZ','QTJ','UZB'])]
(R/'01_data/derived/caucasus_central_asia').mkdir(exist_ok=True)
d.to_csv(R/'01_data/derived/caucasus_central_asia/analysis_input.csv.gz',index=False)
print(d.shape)
