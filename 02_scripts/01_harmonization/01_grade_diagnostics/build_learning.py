from pathlib import Path
import sys,json
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'02_scripts/00_tools'))
from project import run,digest
out=ROOT/'03_outputs/03_learning_diagnostics';out.mkdir(exist_ok=True)
files=[Path(__file__).with_name('prepare_learning.R'),ROOT/'03_outputs/01_harmonized/cutoff_provider.rds']+sorted((ROOT/'05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2').glob('sample_*.rds'))
sig={str(f.relative_to(ROOT)):digest(f) for f in files};mf=out/'manifest.json'
if mf.exists():
 old=json.loads(mf.read_text())
 if old['inputs']==sig and all(digest(out/k)==v for k,v in old['outputs'].items()):print('Learning inputs current; no processing.');sys.exit()
 raise SystemExit('Learning inputs changed; preserve this build and use a new output directory.')
run(['Rscript',str(Path(__file__).with_name('prepare_learning.R'))])
mf.write_text(json.dumps({'inputs':sig,'outputs':{f.name:digest(f) for f in out.glob('*.rds')}},indent=2)+'\n')
