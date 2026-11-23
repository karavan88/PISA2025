"""Download the UIS school-entry indicators once per UIS data release. Never overwrites a snapshot.

    python3 02_scripts/01_harmonization/02_entry_rules/fetch_uis.py          # download, print the pin
    python3 02_scripts/01_harmonization/02_entry_rules/fetch_uis.py --pin    # also make it the build input

The response body is stored verbatim under 01_data/external_uis/ (Git-ignored). The build reads only the
snapshot named in uis_pin.json, so a new UIS release changes nothing until it is pinned on purpose.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, os, sys, urllib.request
ROOT = Path(__file__).resolve().parents[3]
API = 'https://api.uis.unesco.org/api/public'
# The six indicators of the Data Browser view the rules are defined from.
INDICATORS = ['403', '404', '299905', '299932', '999975', '999977']
START, END = 2005, 2026  # covers school entry of the PISA 2018, 2022 and 2025 cohorts


def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'research-script', 'Accept': 'application/json'})
    with urllib.request.urlopen(req, timeout=180) as r:
        return r.read()


ap = argparse.ArgumentParser(); ap.add_argument('--pin', action='store_true'); args = ap.parse_args()
release = json.loads(get(API + '/versions/default'))
version = release['version']
url = (API + '/data/indicators?' + '&'.join('indicator=' + i for i in INDICATORS)
       + f'&start={START}&end={END}&version={version}')
body = get(url)
sha = hashlib.sha256(body).hexdigest()
n = len(json.loads(body)['records'])
if n == 0: sys.exit('UIS returned no records; nothing stored.')
names = {str(d['indicatorCode']): d['name'] for d in json.loads(get(API + '/definitions/indicators'))
         if str(d['indicatorCode']) in INDICATORS}
folder = Path(os.environ.get('PISA_DATA', ROOT / '01_data')) / 'external_uis'; folder.mkdir(parents=True, exist_ok=True)
target = folder / f'uis_entry_rules_{version}.json'
if target.exists():
    if hashlib.sha256(target.read_bytes()).hexdigest() != sha:
        sys.exit(f'{target.name} exists with different content; kept as is. Investigate before replacing.')
    print('Snapshot already stored and identical:', target.name)
else:
    target.write_bytes(body)
    print('Stored', target.name, f'({n} records)')
pin = {'file': target.name, 'sha256': sha, 'uis_version': version, 'uis_release': release.get('themeDataStatus'),
       'url': url, 'retrieved_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
       'records': n, 'indicators': names}
(folder / (target.stem + '.retrieval.json')).write_text(json.dumps(pin, indent=2) + '\n')
if args.pin:
    Path(__file__).with_name('uis_pin.json').write_text(json.dumps(pin, indent=2) + '\n')
    print('Pinned as the build input: uis_pin.json')
else:
    print(json.dumps(pin, indent=2))
