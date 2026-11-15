"""Approved result snapshot for this paper: the only files figures and the report read.
  python3 05_papers/03_resilience_cost/01_code/snapshot.py check              verify every snapshot file against snapshot_manifest.json
  python3 05_papers/03_resilience_cost/01_code/snapshot.py refresh            copy the listed sources into the snapshot (refuses if any file would change)
  python3 05_papers/03_resilience_cost/01_code/snapshot.py refresh --replace  archive the current snapshot to 05_archive/snapshot_<utc>/, then replace it
Promotion is deliberate: estimation writes to 04_output (or a fresh PAPER_OUT directory); nothing reaches a report until it is
promoted here. Files produced by the companion paper are listed with their source and are refreshed only by this command.
Standard library only. Data files stay Git-ignored; the manifest (hashes, sources) is tracked."""
import hashlib, json, shutil, subprocess, sys, datetime
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
PAPER = Path(__file__).resolve().parents[1]
SNAP = PAPER / '02_results' / 'snapshot'; MANIFEST = PAPER / '02_results' / 'snapshot_manifest.json'
# file in the snapshot -> (source path relative to the repository root, producing script)
FILES = {
    'rs_pool.csv': ('05_papers/03_resilience_cost/04_output/rs_pool.csv', '05_papers/03_resilience_cost/01_code/03_response_style.R'),
    'gap_pool.csv': ('05_papers/03_resilience_cost/04_output/gap_pool.csv', '05_papers/03_resilience_cost/01_code/04_gap.R'),
    'gap_sys.csv': ('05_papers/03_resilience_cost/04_output/gap_sys.csv', '05_papers/03_resilience_cost/01_code/04_gap.R'),
    'mech_pool.csv': ('05_papers/03_resilience_cost/04_output/mech_pool.csv', '05_papers/03_resilience_cost/01_code/05_mechanism.R'),
    'oriv_resil.csv': ('05_papers/03_resilience_cost/04_output/oriv_resil.csv', '05_papers/03_resilience_cost/01_code/06_oriv.R'),
    'cur_pool.csv': ('05_papers/03_resilience_cost/04_output/cur_pool.csv', '05_papers/03_resilience_cost/01_code/07_curiosity.R'),
    'thr_pool.csv': ('05_papers/03_resilience_cost/04_output/thr_pool.csv', '05_papers/03_resilience_cost/01_code/08_threshold.R'),
    'thr_model.csv': ('05_papers/03_resilience_cost/04_output/thr_model.csv', '05_papers/03_resilience_cost/01_code/08_threshold.R'),
    'foc_pool.csv': ('05_papers/03_resilience_cost/04_output/foc_pool.csv', '05_papers/03_resilience_cost/01_code/09_focal.R'),
    'foc_model.csv': ('05_papers/03_resilience_cost/04_output/foc_model.csv', '05_papers/03_resilience_cost/01_code/09_focal.R'),
    'cutoff_pool.csv': ('05_papers/04_price_of_progress/04_output/cutoff_pool.csv', '05_papers/04_price_of_progress/01_code/08_cutoff.R'),
    'desc_dist.csv': ('05_papers/03_resilience_cost/04_output/desc_dist.csv', '05_papers/03_resilience_cost/01_code/02_describe.R'),
    'coverage.csv': ('05_papers/03_resilience_cost/04_output/coverage.csv', '05_papers/03_resilience_cost/01_code/02_describe.R'),
    # per-system estimates behind the country figures of the paper (11_figures_paper.R)
    'rs_sys.csv': ('05_papers/03_resilience_cost/04_output/rs_sys.csv', '05_papers/03_resilience_cost/01_code/03_response_style.R'),
    'mech_sys.csv': ('05_papers/03_resilience_cost/04_output/mech_sys.csv', '05_papers/03_resilience_cost/01_code/05_mechanism.R'),
    'foc_sys.csv': ('05_papers/03_resilience_cost/04_output/foc_sys.csv', '05_papers/03_resilience_cost/01_code/09_focal.R'),
}

def sha(p):
    h = hashlib.sha256(); h.update(Path(p).read_bytes()); return h.hexdigest()

def check():
    if not MANIFEST.exists(): sys.exit('No snapshot manifest: run refresh first.')
    m = json.loads(MANIFEST.read_text()); bad = []
    for f in m['files']:
        p = SNAP / f['path']
        if not p.exists(): bad.append('missing: ' + f['path'])
        elif sha(p) != f['sha256']: bad.append('changed: ' + f['path'])
    extra = sorted(set(x.name for x in SNAP.glob('*.csv')) - set(f['path'] for f in m['files']))
    bad += ['not in manifest: ' + x for x in extra]
    if bad: sys.exit('Snapshot does not match its manifest:\n  ' + '\n  '.join(bad))
    print(f"PASS: {len(m['files'])} snapshot files match {MANIFEST.relative_to(ROOT)} (created {m['created_utc']}).")

def refresh(replace):
    missing = [s for s, _ in FILES.values() if not (ROOT / s).exists()]
    if missing: sys.exit('Sources missing:\n  ' + '\n  '.join(missing))
    changed = [n for n, (s, _) in FILES.items() if (SNAP / n).exists() and sha(SNAP / n) != sha(ROOT / s)]
    if changed and not replace:
        sys.exit('These snapshot files would change; rerun with --replace to archive the current snapshot first:\n  ' + '\n  '.join(changed))
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    if changed:
        arch = PAPER / '05_archive' / ('snapshot_' + stamp); arch.mkdir(parents=True)
        for p in SNAP.glob('*.csv'): shutil.copy2(p, arch / p.name)
        if MANIFEST.exists(): shutil.copy2(MANIFEST, arch / MANIFEST.name)
        print('Archived previous snapshot to', arch.relative_to(ROOT))
    SNAP.mkdir(parents=True, exist_ok=True); files = []
    for n, (s, by) in FILES.items():
        shutil.copy2(ROOT / s, SNAP / n)
        files.append({'path': n, 'sha256': sha(SNAP / n), 'bytes': (SNAP / n).stat().st_size, 'source': s, 'produced_by': by})
    commit = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip() or None
    MANIFEST.write_text(json.dumps({'origin': 'Estimates of 14 November 2026 (legacy wellbeing pipeline, before central migration), promoted when the project was split into papers 03 and 04; thr_* (step 8, threshold model) and foc_* (step 9, focal answers) added the same day. Not regenerated by reporting.', 'created_utc': stamp, 'git_commit_at_creation': commit, 'files': files}, indent=2) + '\n')
    print(f'Snapshot written: {len(files)} files.'); check()

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['check']: check()
    elif a[:1] == ['refresh']: refresh('--replace' in a)
    else: sys.exit(__doc__)
