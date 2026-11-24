"""Separate diagnostics: estimation is explicit; report never estimates."""
from pathlib import Path
import argparse,os,sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'02_scripts/00_tools'))
from project import run
ap=argparse.ArgumentParser();ap.add_argument('stage',choices=['estimate','report','grade-estimate','grade-report']);a=ap.parse_args()
os.chdir(ROOT)
folder=Path(__file__).parent
if a.stage=='estimate':
    run([sys.executable,str(ROOT/'02_scripts/00_tools/build_shared.py'),'--grade-diagnostics'])
    for name in ['01_estimate.R','02_mediation.R']:run(['Rscript',str(folder/name)])
elif a.stage=='grade-estimate':
    run(['Rscript',str(folder/'05_grade_control.R')])
else:
    if a.stage=='report': run(['Rscript',str(folder/'03_report.R')])
    run(['Rscript',str(folder/'06_grade_control_report.R')])
    run(['quarto','render',str(ROOT/'05_papers/01_SESTransmission/03_manuscript/01_diagnostics/grade_composition_diagnostics.qmd'),'--to','html'])
