"""Freeze clean submission sources from rendered TeX; never estimate models."""
from pathlib import Path
import re, shutil, subprocess, hashlib, json, zipfile
ROOT=Path(__file__).resolve().parents[4]
P=ROOT/'05_papers/01_SESTransmission'
OUT=P/'06_submissions/01_ijed_20261124_v16'
if OUT.exists():
 raise SystemExit('Refusing to overwrite a submission snapshot; choose a new version directory.')
OUT.mkdir(parents=True)
S=OUT/'01_anonymous_sources';S.mkdir(exist_ok=True)
(S/'figures').mkdir(exist_ok=True)
AI=("During the preparation of this work, the author used OpenAI's ChatGPT/Codex to assist with manuscript drafting and editing for language, style, and readability, and with developing R code for the analytical pipeline. The author directed the tool, reviewed and tested the code, and reviewed and edited the text. The author takes full responsibility for the content of the manuscript.")
for stem,target in [('ijed_ses_seg_rev2','manuscript_anonymized'),('ijed_ses_seg_supplement_rev2','supplement_anonymized')]:
 src=P/'03_manuscript'/f'{stem}.tex';text=src.read_text()
 text=text.replace('\\author{Garen Avanesian}','\\author{}').replace('pdfauthor={Garen Avanesian}','pdfauthor={}').replace('\\begin{revision}','').replace('\\end{revision}','')
 text=re.sub(r'\\colorbox\{cyan!8!white\}\{([^{}]*)\}',r'\1',text)
 text=text.replace('ijed_ses_seg_supplement_rev2.pdf','supplement_anonymized.pdf')
 def image(m):
  rel=m.group(2);f=(src.parent/rel).resolve();assert f.is_file(),f
  name=hashlib.sha256(rel.encode()).hexdigest()[:10]+'_'+f.name
  shutil.copy2(f,S/'figures'/name)
  return m.group(1)+'{figures/'+name+'}'
 text=re.sub(r'(\\includegraphics(?:\[[^\]]*\])?)\{([^}]+)\}',image,text)
 if target.startswith('manuscript'):
  idx=text.index('\\section*{References}') if '\\section*{References}' in text else text.index('\\section{References}')
  declarations='\\section*{Declaration of generative AI and AI-assisted technologies in the manuscript preparation process}\n'+AI+'\n\n'
  text=text[:idx]+declarations+text[idx:]
 assert 'Garen Avanesian' not in text and 'kavanesian@' not in text
 (S/f'{target}.tex').write_text(text)
 for _ in range(2):subprocess.run(['xelatex','-interaction=nonstopmode','-halt-on-error',f'{target}.tex'],cwd=S,stdout=subprocess.DEVNULL,check=True)
 # Check rendered text, not only successful LaTeX compilation.
 rendered = subprocess.run(['pdftotext', '-layout', str(S/f'{target}.pdf'), '-'],
                           capture_output=True, text=True, check=True).stdout
 assert r'\figurenote' not in rendered, 'A figure-note command was printed literally.'
 assert '�' not in rendered, 'Replacement glyph in rendered PDF.'
 if target == 'manuscript_anonymized':
  abstract_text = ' '.join(rendered.split('Abstract', 1)[1].split('Keywords:', 1)[0].split())
  assert 'direction between skills and learning.' in abstract_text, 'Abstract is truncated.'
  assert '7.94' in abstract_text and '20.74' in abstract_text, 'Abstract results missing.'
 shutil.copy2(S/f'{target}.pdf',OUT/f'{target}.pdf')
(S/'README.md').write_text('Compile manuscript_anonymized.tex and supplement_anonymized.tex with XeLaTeX twice. PT Serif must be installed. References are embedded in the generated editable TeX; no data or R execution is needed to typeset this frozen submission. Keep both PDFs together for the appendix hyperlink.\n')
# Title page and highlights are editable LaTeX files as well as PDFs.
common=r'''\documentclass[11pt]{article}
\usepackage[margin=2.5cm]{geometry}
\usepackage{fontspec}\setmainfont{PT Serif}
\usepackage{hyperref}
\begin{document}
'''
title=r'''\begin{center}\Large Do socio-emotional skills transmit socio-economic (dis)advantage? Evidence from PISA 2025 data\end{center}
\bigskip
\noindent\textbf{Garen Avanesian}

\noindent United Nations Children's Fund (UNICEF), Office of Strategy and Evidence -- Innocenti, Education Data and Analytics Unit, Via degli Alfani 58, 50121 Florence, Italy.

\noindent Corresponding author: Garen Avanesian, \href{mailto:kavanesian@unicef.org}{kavanesian@unicef.org}.
\section*{Disclaimer}
The findings, interpretations, and conclusions expressed in this study are those of the author and do not necessarily reflect the views of any organization with which the author is affiliated.
\section*{Disclosure statement}
The author declares no competing interests.
'''
title += r"""
\section*{Funding}
This research did not receive any specific grant from funding agencies in the public, commercial, or not-for-profit sectors.
\section*{Data and code availability}
This study uses OECD PISA public-use data. Provider data are not redistributed. Analysis code, software dependency records, and instructions for obtaining and preparing the data are maintained at \url{https://github.com/karavan88/PISA2025/tree/main/05_papers/01_SESTransmission}.
"""
highlights=['Socio-emotional skills show socio-economic gradients across education systems.','The joint model-based skills pathway is positive in 52 of 67 systems.','School sorting enlarges the skills pathway in 27 systems.','Skill equalization projects gains that can exceed reductions in inequality.']
assert all(len(x)<=85 for x in highlights)
for name,body in [('title_page',title),('highlights', '\\section*{Highlights}\n\\begin{itemize}\n'+''.join('\\item '+x+'\n' for x in highlights)+'\\end{itemize}')]:
 (OUT/f'{name}.tex').write_text(common+body+'\n\\end{document}\n')
 subprocess.run(['xelatex','-interaction=nonstopmode','-halt-on-error',f'{name}.tex'],cwd=OUT,stdout=subprocess.DEVNULL,check=True)
(OUT/'02_editor_only_data_statement.md').write_text('Data and code availability — editor-only submission field\n\nThe study uses OECD PISA public-use data. Data files are not redistributed. The anonymized code archive supplied for review contains analysis scripts, dependency records, and data-placement instructions. The paper code and documentation are publicly available at https://github.com/karavan88/PISA2025/tree/main/05_papers/01_SESTransmission. An anonymized archive is also supplied for peer review. A public persistent archive has not yet been deposited.\n\nVerify the exact provider release/access URL against the dataset citation before final submission.\n')
# Anonymous code-only archive, no Git history, provider data, results, or author files.
with zipfile.ZipFile(OUT/'anonymous_replication_code.zip','w',zipfile.ZIP_DEFLATED) as z:
 roots=[P/'01_code',ROOT/'02_scripts/00_tools',ROOT/'02_scripts/01_harmonization']
 for r in roots:
  for f in sorted(r.rglob('*')):
   if not f.is_file() or f.suffix not in ('.R','.py','.md','.sh'):continue
   if f==Path(__file__).resolve():continue
   txt=f.read_text()
   txt=txt.replace('Garen Avanesian','Author').replace('karavan88','anonymous')
   z.writestr(str(f.relative_to(ROOT)),txt)
 for name in ['renv.lock','DESCRIPTION','.Rprofile','renv/activate.R','01_data/README.md','00_documentation/REPRODUCE.md','05_papers/01_SESTransmission/README.md','05_papers/01_SESTransmission/02_results/analysis_contract.json','05_papers/01_SESTransmission/02_results/snapshot_manifest.json']:
  f=ROOT/name
  if f.exists():z.writestr(name,re.sub(r'Authors@R:.*', 'Authors@R: person("Anonymous", role = c("aut", "cre"))', f.read_text().replace('Garen Avanesian','Author').replace('karavan88','anonymous')))
with zipfile.ZipFile(OUT/'anonymous_replication_code.zip','a',zipfile.ZIP_DEFLATED) as z:
 z.writestr('README.md', 'Anonymous analysis-code archive. Original provider data and numerical result snapshots are not included. Follow 01_data/README.md for source files and 00_documentation/REPRODUCE.md for the workflow. A fresh full 499-resample replication has not been rerun for this submission. The accompanying anonymous_latex_sources.zip reproduces the frozen PDFs without R or data. Historical manifests describe the original snapshot and are not hashes of anonymized source files.\n')
with zipfile.ZipFile(OUT/'anonymous_latex_sources.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in sorted(S.rglob('*')):
  if f.is_file() and f.suffix in ('.tex','.pdf','.png','.md'):z.write(f,f.relative_to(S))
manifest={str(f.relative_to(OUT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in OUT.rglob('*') if f.is_file() and f.suffix in ('.pdf','.tex','.zip')}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(OUT)
