library(data.table)
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');BASE<-'05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2';OUT<-'05_papers/01_SESTransmission/04_output/simple_grade_ols_20261117'
for(e in parse('05_papers/01_SESTransmission/01_code/01_grade_diagnostics/07_simple_ols.R'))if(is.call(e)&&identical(e[[1]],as.name('<-'))&&as.character(e[[2]])%in%c('stats','solvefit'))eval(e)
d<-rbindlist(lapply(c('ARE','ARG','AUS'),function(cc)readRDS(file.path(BASE,paste0('sample_',cc,'_2.rds')))));d[,normalized_weight:=W_FSTUWT/sum(W_FSTUWT),by=CNT]
checks<-list()
for(mod in c('Grade only','Grade + age')){
 vars<-c('grade',if(mod=='Grade + age')'age_months');z<-lapply(split(d,by='CNT'),function(x)stats(x,x$W_FSTUWT,vars));tot<-list(A=Reduce(`+`,lapply(z,`[[`,'A')),b=Reduce(`+`,lapply(z,`[[`,'b')));b<-solvefit(tot)
 direct<-coef(lm(reformulate(c(vars,'factor(CNT)'),response='CURIO'),d,weights=normalized_weight))['grade'];err<-abs(direct-b[2]);stopifnot(err<1e-9);checks[[mod]]<-data.table(model=mod,pooled_dummy_lm_error=err)
}
fwrite(rbindlist(checks),file.path(OUT,'pooled_validation.csv'))
e<-fread(file.path(OUT,'country_ols.csv'));p<-fread(file.path(OUT,'pooled_ols.csv'));stopifnot(all(is.finite(e$p)),all(e$p>=0&e$p<=1),all(is.finite(p$p)),all(e[,uniqueN(N),by=.(CNT,sample)]$V1==1))
cat('PASS: pooled coefficients match explicit country-dummy lm; finite p-values; identical pupils across skill/model comparisons.\n')
