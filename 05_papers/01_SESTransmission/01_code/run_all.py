"""Report from local frozen results, validate cached draws, or explicitly re-estimate."""
from pathlib import Path
import sys, argparse, json, shutil, os
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'02_scripts/00_tools'))
from project import *
ap=argparse.ArgumentParser();ap.add_argument('mode',choices=['preflight','report','check','draw-check','estimate']);ap.add_argument('--no-pdf',action='store_true');ap.add_argument('--fresh',action='store_true',help='Archive analysis caches before estimation');args=ap.parse_args()
code=PAPER/'01_code';out=PAPER/'04_output';snap=PAPER/'02_results'
manifest=json.loads((snap/'snapshot_manifest.json').read_text())
contract=json.loads((snap/'analysis_contract.json').read_text())
if args.mode!='estimate':
    shared_manifest=ROOT/'03_outputs/01_harmonized/build_manifest.json'
    if shared_manifest.exists():
        built=json.loads(shared_manifest.read_text())
        if built['inputs']!=contract.get('shared_build_inputs',built['inputs']):
            sys.exit('Shared data/build definitions differ from the approved result snapshot. Re-estimate or explicitly restore the matching snapshot.')
        stale=[name for name,h in built['inputs'].items() if (ROOT/name).exists() and digest(ROOT/name)!=h]
        if stale:sys.exit('Central inputs changed since harmonization: '+', '.join(stale))
    changed=[name for name,h in contract['sha256'].items() if not (ROOT/name).exists() or digest(ROOT/name)!=h]
    if changed:sys.exit('Analysis definitions changed since the approved snapshot. Re-estimate/review before reporting: '+', '.join(changed))
missing=[x['path'] for x in manifest['files'] if not (snap/x['path']).exists()]
if missing and args.mode!='estimate':sys.exit('Local aggregate snapshot missing. Restore 02_results from your local backup before report/check, or follow the raw-data rebuild instructions. Data files are intentionally excluded from Git. Missing: '+', '.join(missing[:5]))
if args.mode in ['preflight','report','check','draw-check']:
    for x in manifest['files']:
        source=snap/x['path']
        if digest(source)!=x['sha256']:sys.exit('Snapshot changed: '+x['path']+'. Review and refresh the snapshot explicitly.')
        target=out/x['path'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
for d in ['rev2/figures','rev2/audit','parental_controls_comparison/figures']:(out/d).mkdir(parents=True,exist_ok=True)
def R(name):run(['Rscript','--vanilla',str(code/name)])
if args.mode=='preflight':
    run([sys.executable,str(ROOT/'02_scripts/00_tools/check_repo.py')]);print('Snapshot, analysis code, and available shared-build inputs verified.');sys.exit(0)
if args.mode=='estimate':
    if not args.fresh:
        sys.exit('Estimation requires --fresh to avoid silently reusing historical checkpoints. Existing outputs will be archived locally.')
    import datetime
    if out.exists():
        target=PAPER/'05_archive'/('before_estimation_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
        target.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(out),target)
    for d in ['input','tables','audit','figures','rev1/tables','rev1/evidence','rev2/tables','rev2/audit']:(out/d).mkdir(parents=True,exist_ok=True)
    run([sys.executable,str(ROOT/'02_scripts/00_tools/build_shared.py')])
    shared=ROOT/'03_outputs/01_harmonized/metadata'
    for f in shared.glob('*.csv'):shutil.copy2(f,out/'input'/f.name)
    R('upstream/global_mediation_code/RUN_ANALYSIS.R')
    R('01_descriptives.R')
    for f in (out/'tables').glob('*.csv'):
        shutil.copy2(f,out/'rev1/tables'/f.name);shutil.copy2(f,out/'rev2/tables'/f.name)
    R('04_rev1_evidence.R')
    for f in (out/'rev1/tables').glob('*.csv'):shutil.copy2(f,out/'rev2/tables'/f.name)
    for name in ['16_parental_controls_comparison.R','17_report_parental_controls_comparison.R','20_prepare_parental_publication.R','06_equalization_rev2.R','10_run_counterfactual_robustness_rev2.R','23_within_between_decomposition_rev2.R']:
        R(name)
    print('Estimation finished. Review output against the frozen snapshot before replacing it.');log('estimate');sys.exit(0)
# Drawing existing aggregate results never invokes the harmonizer or regressions.
# These scripts share plotting helpers and must execute in one R session.
expr="source('05_papers/01_SESTransmission/01_code/02_figures_rev2.R');"
expr+=';'.join("source('05_papers/01_SESTransmission/01_code/"+n+"')" for n in ['24_within_between_figure_rev2.R','21_sorting_increment_figure_rev2.R','07_equalization_figures_rev2.R','22_recipient_gap_figure_rev2.R','12_counterfactual_robustness_figures_rev2.R'])
run(['Rscript','--vanilla','-e',expr])
R('03_validate_rev2.R')
if args.mode=='draw-check':R('08_validate_equalization_rev2.R')
if args.mode=='report' and not args.no_pdf:
    for name in ['ijed_ses_seg_rev2.qmd','ijed_ses_seg_supplement_rev2.qmd']:
        run(['quarto','render',str(PAPER/'03_manuscript'/name),'--to','pdf'])
log(args.mode);print('Completed:',args.mode)
