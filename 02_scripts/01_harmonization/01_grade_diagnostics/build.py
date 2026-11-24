"""Hash-guarded central add-on; does not alter the published model inputs."""
from pathlib import Path
import sys,json,os
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'02_scripts/00_tools'))
from project import digest,run
out=ROOT/'03_outputs/02_grade_diagnostics';out.mkdir(exist_ok=True)
raw=Path(os.environ.get('PISA_DATA',ROOT/'01_data'))
files=[ROOT/'03_outputs/01_harmonized/cutoff_provider.rds',ROOT/'03_outputs/01_harmonized/all_data.rds',raw/'CY09_MS_SCH_PUF.sav',ROOT/'05_papers/01_SESTransmission/02_results/rev2/tables/analysis_sample.csv',Path(__file__).with_name('prepare.R')]
files+=sorted((ROOT/'03_outputs/01_harmonized/input').glob('SES_*.rds'))
missing=[str(p) for p in files if not p.exists()]
if missing:sys.exit('Build the shared inputs first; missing: '+', '.join(missing))
state={str(p):digest(p) for p in files};m=out/'manifest.json'
if m.exists():
 old=json.loads(m.read_text())
 if old['inputs']==state and all((out/k).exists() and digest(out/k)==v for k,v in old['outputs'].items()):print('Diagnostic inputs current; no processing.');sys.exit()
run(['Rscript',str(Path(__file__).with_name('prepare.R'))])
m.write_text(json.dumps({'inputs':state,'outputs':{str(p.relative_to(out)):digest(p) for p in out.glob('*.rds')}},indent=2)+'\n')
