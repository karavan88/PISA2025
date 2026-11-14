"""Package the report, aggregate outputs and replication scripts, excluding microdata."""
from pathlib import Path
import hashlib,json,zipfile
R=Path(__file__).resolve().parents[2];O=R/'03_outputs/caucasus_central_asia';D=R/'04_manuscripts/caucasus_central_asia';C=R/'02_scripts/caucasus_central_asia'
assert json.loads((O/'validation.json').read_text())['status']=='passed'
raw=R/'01_data/CY09_MS_STU_PUF.sav'
with raw.open('rb') as f:digest=hashlib.file_digest(f,'sha256').hexdigest()
provenance={'input_file':str(raw.relative_to(R)),'bytes':raw.stat().st_size,'sha256':digest,'reference_manuscript':'epf_eap_preview.pdf (user supplied; not redistributed)','output_scope':'Report, scripts and aggregate results; no student microdata.'}
(O/'provenance.json').write_text(json.dumps(provenance,indent=2))
files=[D/'report.html']+sorted(C.glob('*.py'))+sorted(C.glob('*.R'))+[C/'README.txt']+sorted(O.glob('*.csv'))+sorted(p for p in O.glob('*.json') if p.name!='bundle_manifest.json')+sorted(O.glob('sessionInfo_*.txt'))+sorted((O/'figures').glob('*.png'))
manifest={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(O/'bundle_manifest.json').write_text(json.dumps(manifest,indent=2));files.append(O/'bundle_manifest.json')
with zipfile.ZipFile(D/'pisa2025_regional_report_bundle.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in files:z.write(p,str(p.relative_to(R)))
with zipfile.ZipFile(D/'pisa2025_regional_report_bundle.zip') as z:
 assert z.testzip() is None
 assert not any(n.endswith(('.sav','.rds','.csv.gz')) for n in z.namelist())
print('Packaged',len(files),'files;', (D/'pisa2025_regional_report_bundle.zip').stat().st_size,'bytes')
