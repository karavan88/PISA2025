from pathlib import Path
import hashlib, json, subprocess, sys, datetime, os
ROOT = Path(__file__).resolve().parents[2]
PAPER = ROOT / '05_papers/01_SESTransmission'
def digest(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(8*1024*1024),b''): h.update(b)
    return h.hexdigest()
def run(args):
    env=os.environ.copy()
    profile=ROOT/".Rprofile"
    if profile.exists():
        env["R_PROFILE_USER"]=str(profile)
        env["RENV_PROJECT"]=str(ROOT)
    # --vanilla suppresses the project profile and therefore renv.
    if args and args[0] == "Rscript":
        args=[a for a in args if a != "--vanilla"]
    subprocess.run(args,cwd=ROOT,check=True,env=env)
def log(stage):
    out=PAPER/'04_output/00_logs';out.mkdir(parents=True,exist_ok=True)
    commit=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,capture_output=True,text=True)
    record={'stage':stage,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git_commit':commit.stdout.strip() or None}
    with (out/'runs.jsonl').open('a') as f: f.write(json.dumps(record)+'\n')
