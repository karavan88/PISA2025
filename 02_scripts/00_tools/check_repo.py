"""Check centralization, tracked-file policy, and active source syntax."""
from project import *
import re
errors=[]
for f in (PAPER/'01_code').rglob('*.R'):
    if 'archive' in str(f):continue
    text=f.read_text()
    if re.search(r'\bread_sav\s*\(',text):errors.append('Raw data read outside central build: '+str(f.relative_to(ROOT)))
    if '/Users/' in text:errors.append('Machine-specific path: '+str(f.relative_to(ROOT)))
tracked=subprocess.run(['git','ls-files','-z'],cwd=ROOT,capture_output=True,text=True)
for f in tracked.stdout.split('\0'):
    if not f:continue
    if Path(f).suffix.lower() in {'.csv','.tsv','.sav','.dta','.rds','.rda','.rdata','.parquet','.xlsx','.xls','.feather','.db'}:
        errors.append('Data tracked by Git: '+f)
if errors:sys.exit('\n'.join(errors))
print('PASS: maintained paper code has no raw-data reads or machine-specific paths; no data files tracked.')
