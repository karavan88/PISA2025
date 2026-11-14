suppressPackageStartupMessages(library(data.table))
source('05_papers/02_fuzzy_rd_learning/01_code/00_helpers.R')
e<-fread(op('estimates.csv'));g<-fread(op('eligibility.csv'))
stopifnot(!anyDuplicated(e[,.(CNT,outcome,spec,term)]),setequal(unique(e$CNT),g[eligible==TRUE,CNT]),all(is.finite(e$est)),all(is.finite(e$se)),all(e$se>=0))
w<-dcast(e[spec!='lsdv'],CNT+outcome+spec~term,value.var='est')
stopifnot(max(abs(w$gamma-w$tau-w$beta))<1e-8)
s<-fread(op('summary.csv'));stopifnot(nrow(s)>0)
for(i in seq_len(nrow(s))){z<-e[outcome==s$outcome[i]&spec==s$spec[i]&term==s$term[i]];stopifnot(nrow(z)==s$n_sys[i],abs(median(z$est)-s$median[i])<1e-8)}
if(file.exists('05_papers/02_fuzzy_rd_learning/02_results/estimates.csv')) {
old<-fread('05_papers/02_fuzzy_rd_learning/02_results/estimates.csv')
k<-c('CNT','outcome','spec','term');m<-merge(e,old,by=k,suffixes=c('_new','_old'))
stopifnot(nrow(m)==nrow(e),nrow(m)==nrow(old),all(m$n_new==m$n_old))
delta<-m[,.(max_est_difference=max(abs(est_new-est_old)),max_se_difference=max(abs(se_new-se_old)))]
fwrite(delta,op('reproduction_comparison.csv'))
# The corrected second-stage alignment changes only skill-outcome IV models.
fixed <- m[outcome%in%c('SCIE','MATH','READ') | spec=='lsdv']
stopifnot(max(abs(fixed$est_new-fixed$est_old))<1e-7,max(abs(fixed$se_new-fixed$se_old))<1e-7)
m[,`:=`(estimate_change=est_new-est_old,se_change=se_new-se_old)]
fwrite(m,op('historical_comparison.csv'))
cat('Changed entries after missing-outcome correction:',sum(abs(m$estimate_change)>1e-7),'of',nrow(m),'\n')

} else cat('Historical bundle absent: comparison skipped; design/accounting checks still run.\n')
cat('PASS:',uniqueN(e$CNT),'systems,',nrow(e),'estimates; eligibility, gamma=tau+beta, summaries, and summary checks passed (historical comparison above when available).\n')
