"""Reproduce the broad-coverage cutoff design without relying on scoping projects."""
from pathlib import Path
import sys, os, argparse, json, shutil, datetime
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'02_scripts/00_tools'))
from project import run,digest
PAPER=ROOT/'05_papers/02_fuzzy_rd_learning'
ap=argparse.ArgumentParser()
ap.add_argument('mode',choices=['preflight','check','report','estimate'])
ap.add_argument('--results',type=Path,help='Report/check this newly estimated result directory')
ap.add_argument('--historical',action='store_true',help='Explicitly inspect the historical snapshot, including the old skill-outcome alignment bug')
ap.add_argument('--output',type=Path,help='Fresh-estimation output directory; must not already exist')
a=ap.parse_args()
snap=PAPER/'02_results'; shared=ROOT/'03_outputs/01_harmonized/cutoff'
def shared_products():
    # the central products this paper reads: the cutoff design's (not the whole build, not other designs' products)
    built=json.loads((shared.parent/'build_manifest.json').read_text())
    return {k:v for k,v in sorted(built['outputs'].items()) if k.startswith('cutoff/')}
if a.mode=='estimate':
    run([sys.executable,str(ROOT/'02_scripts/00_tools/build_shared.py')])
    out=a.output or PAPER/'04_output'/('fresh_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
    out=out.resolve()
    if out.exists():sys.exit('Fresh output already exists; choose a new --output path.')
    out.mkdir(parents=True)
    for name in ['systems.csv','eligibility.csv','compliance.csv','cutoff_audit_all.csv']:shutil.copy2(shared/name,out/name)
elif a.results:
    out=a.results.resolve()
    if not (out/'run_manifest.json').exists():sys.exit('Result directory lacks a completed estimation manifest.')
    saved=json.loads((out/'run_manifest.json').read_text())
    if saved['renv_lock_sha256']!=digest(ROOT/'renv.lock'):sys.exit('Package lock changed since estimation.')
    for name in ['00_helpers.R','03_gradegain.R','04_summary.R','model_functions.R']:
        if saved['code'].get(name)!=digest(PAPER/'01_code'/name):sys.exit('Estimation definitions changed: '+name)
    if (shared.parent/'build_manifest.json').exists() and saved['shared_products']!=shared_products():sys.exit('Shared cutoff products changed since estimation.')
else:
    if a.mode=='report' and not a.historical:sys.exit('Use report --results PATH after estimate. To inspect the old snapshot explicitly, use --historical; its skill-outcome IV estimates predate the alignment correction.')
    out=PAPER/'04_output/report';out.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((snap/'snapshot_manifest.json').read_text())
    for f in manifest['files']:
        source=snap/f['path']
        if not source.exists() or digest(source)!=f['sha256']:sys.exit('Missing or changed local results snapshot: '+str(source))
        target=out/f['path']
        if not target.exists() or digest(target)!=f['sha256']:
            if target.exists():target.unlink()
            shutil.copy2(source,target)
os.environ['PISA_RD_OUT']=str(out)
os.environ['PISA_RD_SYSTEMS']=str(out/'systems.csv')
code=PAPER/'01_code'
if a.mode=='estimate':
    for name in ['test_tsls.R','03_gradegain.R','04_summary.R']:run(['Rscript',str(code/name)])
if a.mode!='preflight':run(['Rscript',str(code/'05_validate.R')])
if a.mode=='report':run(['quarto','render',str(PAPER/'03_manuscript/report.qmd'),'--to','html'])
(out/('run_manifest.json' if a.mode=='estimate' else 'report_manifest.json')).write_text(json.dumps({'mode':a.mode,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'renv_lock_sha256':digest(ROOT/'renv.lock'),'code':{p.name:digest(p) for p in sorted(code.glob('*.R'))},'shared_products':shared_products() if (shared.parent/'build_manifest.json').exists() else None},indent=2)+'\n')
print('Completed',a.mode,'at',out)
