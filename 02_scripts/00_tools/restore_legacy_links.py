from project import *
import os
for row in json.loads((ROOT/'00_documentation/legacy_path_map.json').read_text()):
    alias=ROOT/row['alias'];target=ROOT/row['target']
    target.mkdir(parents=True,exist_ok=True)
    if alias.is_symlink():continue
    if alias.exists():raise SystemExit('Refusing to replace existing path: '+str(alias))
    alias.parent.mkdir(parents=True,exist_ok=True)
    alias.symlink_to(os.path.relpath(target,alias.parent),target_is_directory=True)
print('Compatibility paths ready; no data copied or processed.')
