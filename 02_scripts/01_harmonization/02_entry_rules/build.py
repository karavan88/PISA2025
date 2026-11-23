"""Hash-guarded central add-on: official school-entry rules (UIS) set against the PISA 2025 cohort. No estimation."""
from pathlib import Path
import sys, json, os
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / '02_scripts/00_tools'))
from project import digest, run
here = Path(__file__).parent
pin_file = here / 'uis_pin.json'
if not pin_file.exists(): sys.exit('No UIS snapshot pinned. Run fetch_uis.py --pin first.')
pin = json.loads(pin_file.read_text())
snapshot = Path(os.environ.get('PISA_DATA', ROOT / '01_data')) / 'external_uis' / pin['file']
provider = ROOT / '03_outputs/01_harmonized/cutoff_provider.rds'
cut = [ROOT / '03_outputs/01_harmonized/cutoff' / f for f in ['eligibility.csv', 'cutoff_audit_all.csv']]
missing = [str(p) for p in [snapshot, provider] + cut if not p.exists()]
if missing: sys.exit('Missing entry-rule inputs (run fetch_uis.py and the shared build): ' + ', '.join(missing))
if digest(snapshot) != pin['sha256']: sys.exit('The UIS snapshot does not match uis_pin.json; it must not be edited.')
out = ROOT / '03_outputs/04_entry_rules'; out.mkdir(exist_ok=True)
state = {'external_uis/' + pin['file']: pin['sha256'], '03_outputs/01_harmonized/cutoff_provider.rds': digest(provider),
         '02_entry_rules/prepare.R': digest(here / 'prepare.R'), **{'03_outputs/01_harmonized/cutoff/' + p.name: digest(p) for p in cut}}
m = out / 'manifest.json'
if m.exists():
    old = json.loads(m.read_text())
    if old['inputs'] == state and all((out / k).exists() and digest(out / k) == v for k, v in old['outputs'].items()):
        print('Entry rules current; no processing.'); sys.exit()
run(['Rscript', str(here / 'prepare.R')])
m.write_text(json.dumps({'inputs': state, 'uis_version': pin['uis_version'],
                         'outputs': {p.name: digest(p) for p in sorted(out.glob('*.csv'))}}, indent=2) + '\n')
print('Entry rules built; input and product hashes recorded.')
