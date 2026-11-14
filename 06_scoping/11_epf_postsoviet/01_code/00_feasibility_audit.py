"""
EPF post-Soviet paper -- feasibility audit on PISA 2025 (7 systems).
Run from repo root:  python3 02_scripts/epf_postsoviet/00_feasibility_audit.py
Needs: pyreadstat, pandas, statsmodels (pip install --user ...).
Outputs: 03_outputs/epf_postsoviet/audit_sample.csv, audit_grade_by_birthmonth.csv, audit_grade_effects.csv
All estimates use PV1 only (audit, not results). Weighted by W_FSTUWT; SEs clustered by school.
"""
import os, warnings, numpy as np, pandas as pd, pyreadstat, statsmodels.api as sm
warnings.filterwarnings('ignore')
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, '03_outputs', 'epf_postsoviet'); os.makedirs(OUT, exist_ok=True)
PS = ['ARM','GEO','AZE','MDA','KAZ','KGZ','UZB']
NAMES = {'ARM':'Armenia','GEO':'Georgia','AZE':'Azerbaijan','MDA':'Moldova','KAZ':'Kazakhstan','KGZ':'Kyrgyzstan','UZB':'Uzbekistan'}
cols = ['CNT','CNTSCHID','CNTSTUID','ST001D01T','ISCEDP','PROGN','ST003D02T','ST003D03T','AGE','REPEAT','ESCS',
        'PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG','ST420Q01DA','LANGTEST_COG','ST022Q01TA',
        'PV1SCIE','PV1MATH','PV1READ','W_FSTUWT']
d, meta = pyreadstat.read_sav(os.path.join(ROOT,'01_data','CY09_MS_STU_PUF.sav'), usecols=cols)
d = d[d.CNT.isin(PS)].copy()

# ---- 1. sample table ----
rows = []
for c in PS:
    x = d[d.CNT==c]; modal = x.ST001D01T.mode()[0]
    g = x.ST001D01T.value_counts(normalize=True).sort_index()
    voc = x.ISCEDP.isin([254,354]).mean()
    rows.append(dict(CNT=c, economy=NAMES[c], students=len(x), schools=x.CNTSCHID.nunique(), modal_grade=int(modal),
        share_below_modal=round((x.ST001D01T<modal).mean(),3), share_modal=round((x.ST001D01T==modal).mean(),3),
        share_above_modal=round((x.ST001D01T>modal).mean(),3), share_vocational=round(voc,3),
        repeat_share=round((x.REPEAT==1).mean(),3), escs_missing=round(x.ESCS.isna().mean(),3),
        skills_missing=round(x[['CURIO','ENPROBS','COGABIL','GOALSET','SELFREG']].isna().any(axis=1).mean(),3),
        persev_missing=round(x.PERSEV.isna().mean(),3),
        math_pv_missing=round(x.PV1MATH.isna().mean(),3), read_pv_missing=round(x.PV1READ.isna().mean(),3),
        lang_test=' '.join(f'{k}:{v:.2f}' for k,v in x.LANGTEST_COG.value_counts(normalize=True).items()),
        birth_years=' '.join(f'{int(k)}:{v:.2f}' for k,v in x.ST003D03T.value_counts(normalize=True).items())))
pd.DataFrame(rows).to_csv(os.path.join(OUT,'audit_sample.csv'), index=False)

# ---- 2. grade and score by birth month (general programmes only) ----
gen = d[d.ISCEDP.isin([244,344])].dropna(subset=['ST003D02T','ST001D01T','PV1SCIE'])
bm = gen.groupby(['CNT','ST003D02T']).apply(lambda s: pd.Series({
        'n':len(s), 'mean_grade':np.average(s.ST001D01T,weights=s.W_FSTUWT),
        'p_above_modal': np.average((s.ST001D01T>s.ST001D01T.mode()[0]).astype(float),weights=s.W_FSTUWT) if False else np.nan,
        'mean_scie':np.average(s.PV1SCIE,weights=s.W_FSTUWT), 'mean_escs':s.ESCS.mean()})).reset_index()
bm.round(3).to_csv(os.path.join(OUT,'audit_grade_by_birthmonth.csv'), index=False)

# ---- 3. grade effects: LSDV (birth-month dummies) vs cutoff IV, general programmes, modal +/- 1 ----
def lsdv(x, y, escs):
    X = pd.DataFrame({'grade':x.ST001D01T.astype(float)}, index=x.index)
    X = pd.concat([X, pd.get_dummies(x.ST003D02T.astype(int), prefix='m', drop_first=True).astype(float)], axis=1)
    if escs: X['ESCS'] = x.ESCS
    b = sm.WLS(x[y], sm.add_constant(X), weights=x.W_FSTUWT).fit(cov_type='cluster', cov_kwds={'groups':x.CNTSCHID})
    return b.params['grade'], b.bse['grade']
CUT = {'GEO':10,'AZE':10,'KAZ':9}   # first birth month with clearly lower grade (see audit_grade_by_birthmonth.csv)
res = []
for c in PS:
    for y in ['PV1SCIE','PV1MATH','PV1READ']:
        x = d[(d.CNT==c)&(d.ISCEDP.isin([244,344]))].dropna(subset=[y,'ST003D02T','ESCS','ST001D01T'])
        if len(x)==0: continue
        modal = x.ST001D01T.mode()[0]; x = x[(x.ST001D01T-modal).abs()<=1]
        b0,s0 = lsdv(x,y,False); b1,s1 = lsdv(x,y,True)
        r = dict(CNT=c, outcome=y[3:], n=len(x), lsdv_noESCS=round(b0,1), se0=round(s0,1), lsdv_ESCS=round(b1,1), se1=round(s1,1))
        if c in CUT:
            Z = (x.ST003D02T>=CUT[c]).astype(float); m = x.ST003D02T.astype(float)
            W = sm.add_constant(pd.DataFrame({'m':m,'ESCS':x.ESCS}, index=x.index))
            fs = sm.WLS(x.ST001D01T.astype(float), W.assign(Z=Z), weights=x.W_FSTUWT).fit(cov_type='cluster', cov_kwds={'groups':x.CNTSCHID})
            rf = sm.WLS(x[y], W.assign(Z=Z), weights=x.W_FSTUWT).fit(cov_type='cluster', cov_kwds={'groups':x.CNTSCHID})
            r.update(first_stage=round(fs.params['Z'],2), fs_t=round(fs.tvalues['Z'],1), reduced_form=round(rf.params['Z'],1),
                     rf_se=round(rf.bse['Z'],1), wald_iv=round(rf.params['Z']/fs.params['Z'],1))
        res.append(r)
pd.DataFrame(res).to_csv(os.path.join(OUT,'audit_grade_effects.csv'), index=False)
print(pd.DataFrame(rows)[['CNT','students','schools','modal_grade','share_below_modal','share_modal','share_above_modal','share_vocational','escs_missing','skills_missing']].to_string(index=False))
print(pd.DataFrame(res).to_string(index=False))
