from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json
R=Path.cwd();O=R/'03_outputs/caucasus_central_asia/armenia_levels';S=R/'02_scripts/caucasus_central_asia';M=R/'04_manuscripts/caucasus_central_asia'
assert json.loads((O/'validation.json').read_text())['status']=='passed'
files=[M/'armenia_achievement_context.html',S/'README_armenia_levels.txt',S/'02_extract.py']+[S/n for n in ['17_armenia_levels.R','18_armenia_levels_describe.py','19_armenia_levels_report.py','20_armenia_levels_validate.py','21_armenia_levels_package.py']]+list(O.glob('*.csv'))+list(O.glob('*.json'))+[O/'sessionInfo.txt']+list((O/'figures').glob('*.png'))
p=M/'armenia_achievement_context_bundle.zip'
with ZipFile(p,'w',ZIP_DEFLATED) as z:
 for f in files:z.write(f,f.relative_to(R))
with ZipFile(p) as z:
 assert z.testzip() is None
 assert not any(n.startswith('01_data/') or n.endswith('.rds') for n in z.namelist())
 print('Validated package:',p,'with',len(z.namelist()),'files')
