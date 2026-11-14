"""Only entry point for shared variable construction. No regressions."""
from project import *
import argparse, os
ap=argparse.ArgumentParser();ap.add_argument('--force',action='store_true');args=ap.parse_args()
out=ROOT/'03_outputs/01_harmonized';out.mkdir(parents=True,exist_ok=True)
raw=Path(os.environ.get('PISA_DATA',ROOT/'01_data'))
inputs=[raw/'CY09_MS_STU_PUF.sav',raw/'CY09_MS_SCH_PUF.sav']
inputs+=sorted((ROOT/'02_scripts/01_harmonization').glob('*.R'))
missing=[str(f) for f in inputs if not f.exists()]
if missing:sys.exit('Missing central-build inputs: '+', '.join(missing))
# Identify provider files by role, not machine-specific location, so PISA_DATA is portable.
current={('01_data/'+f.name) if f.parent.resolve()==raw.resolve() else str(f.relative_to(ROOT)):digest(f) for f in inputs}
manifest=out/'build_manifest.json'
if manifest.exists() and not args.force:
    old=json.loads(manifest.read_text())
    if old['inputs']==current and all((out/k).exists() and digest(out/k)==v for k,v in old['outputs'].items()):
        print('Shared data are current; no processing performed.');sys.exit(0)
metadata=out/'metadata';metadata.mkdir(exist_ok=True)
# Historical validation/lookups remain data, not embedded in scripts.
reference=PAPER/'02_results/input'
for name in ['original_eligibility.csv','country_groups.csv']:
    import shutil
    if (reference/name).exists() and not (metadata/name).exists():shutil.copy2(reference/name,metadata/name)
for name in ['extract_base.R','prepare.R','prepare_cutoff.R','prepare_cutoff_analytic.R']:
    run(['Rscript','--vanilla',str(ROOT/'02_scripts/01_harmonization'/name)])
products=[x for x in out.rglob('*') if x.is_file() and x!=manifest]
manifest.write_text(json.dumps({'inputs':current,'outputs':{str(x.relative_to(out)):digest(x) for x in products}},indent=2)+'\n')
log('shared_harmonization');print('Central harmonization complete; source/code/product hashes recorded.')
