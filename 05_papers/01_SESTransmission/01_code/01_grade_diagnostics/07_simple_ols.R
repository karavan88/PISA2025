library(data.table);setDTthreads(1)
BASE<-'05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2'
OUT<-'05_papers/01_SESTransmission/04_output/simple_grade_ols_20261117';dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');RW<-paste0('W_FSTURWT',1:80);SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters')
D<-readRDS('03_outputs/02_grade_diagnostics/dictionary.rds')
paths<-c('05_papers/01_SESTransmission/01_code/01_grade_diagnostics/07_simple_ols.R',list.files(BASE,pattern='^sample_.*rds$',full.names=TRUE));sig<-tools::md5sum(paths);sf<-file.path(OUT,'signature.rds');if(file.exists(sf))stopifnot(identical(sig,readRDS(sf)))else saveRDS(sig,sf)
# Normalized national weights give every country equal total weight in pooled OLS.
# Centering within country is exactly equivalent to country fixed effects.
stats<-function(d,w,vars){w<-w/sum(w);X<-as.matrix(d[,..vars]);Y<-as.matrix(d[,..S]);X<-sweep(X,2,colSums(X*w));Y<-sweep(Y,2,colSums(Y*w));list(A=crossprod(X,w*X),b=crossprod(X,w*Y))}
solvefit<-function(z){if(rcond(z$A)<1e-12)stop('Unidentified grade/age design');solve(z$A,z$b)['grade',]}
rows<-function(pt,se,meta){cbind(meta,data.table(skill=S,estimate=as.numeric(pt),se=as.numeric(se),p=2*pnorm(-abs(pt/se)),lower=as.numeric(pt-1.96*se),upper=as.numeric(pt+1.96*se)))}
res<-list();pool<-list();fails<-list();check<-list()
for(ii in 1:4)for(model in c('Grade only','Grade + age')){
 vars<-c('grade',if(model=='Grade + age')'age_months');ccstats<-list();nn<-list()
 for(cc in D$countries$CNT){
  d<-readRDS(file.path(BASE,paste0('sample_',cc,'_',ii,'.rds')))
  if(nrow(d)<200||uniqueN(d$school)<20||uniqueN(d$grade)<2){fails[[length(fails)+1]]<-data.table(CNT=cc,sample=SUB[ii],model,reason='Fewer than 200 pupils/20 schools, or no grade variation');next}
  ans<-tryCatch({z<-stats(d,d$W_FSTUWT,vars);pt<-solvefit(z);rep<-lapply(RW,function(r)stats(d,d[[r]],vars));betas<-t(vapply(rep,solvefit,numeric(6)));se<-sqrt(colSums(sweep(betas,2,pt)^2)/20)
   # Check against ordinary weighted lm for the first country in each specification.
   if(!length(ccstats)){f<-reformulate(vars,response=S[1]);direct<-coef(lm(f,d,weights=W_FSTUWT))['grade'];stopifnot(abs(direct-pt[1])<1e-9);check[[length(check)+1]]<-data.table(sample=SUB[ii],model,CNT=cc,error=abs(direct-pt[1]))}
   ccstats[[cc]]<-list(main=z,rep=rep);nn[[cc]]<-c(N=nrow(d),schools=uniqueN(d$school));res[[length(res)+1]]<-rows(pt,se,data.table(CNT=cc,economy=D$countries[CNT==cc,economy],sample=SUB[ii],model,N=nrow(d),schools=uniqueN(d$school)));TRUE
  },error=function(e){fails[[length(fails)+1]]<<-data.table(CNT=cc,sample=SUB[ii],model,reason=conditionMessage(e));FALSE})
 }
 total<-list(A=Reduce(`+`,lapply(ccstats,function(z)z$main$A)),b=Reduce(`+`,lapply(ccstats,function(z)z$main$b)));pt<-solvefit(total);variance<-rep(0,6)
 # Perturb one independent national sample at a time, retaining all other countries.
 for(cc in names(ccstats))for(r in 1:80){x<-ccstats[[cc]];rr<-list(A=total$A-x$main$A+x$rep[[r]]$A,b=total$b-x$main$b+x$rep[[r]]$b);variance<-variance+(solvefit(rr)-pt)^2/20}
 pool[[length(pool)+1]]<-rows(pt,sqrt(variance),data.table(sample=SUB[ii],model,countries=length(ccstats),N=sum(vapply(nn,function(x)x['N'],numeric(1))),schools=sum(vapply(nn,function(x)x['schools'],numeric(1)))))
 cat(SUB[ii],model,'complete:',length(ccstats),'systems\n');flush.console()
}
fwrite(rbindlist(res),file.path(OUT,'country_ols.csv'));fwrite(rbindlist(pool),file.path(OUT,'pooled_ols.csv'));fwrite(rbindlist(fails),file.path(OUT,'exclusions.csv'));fwrite(rbindlist(check),file.path(OUT,'validation.csv'))
