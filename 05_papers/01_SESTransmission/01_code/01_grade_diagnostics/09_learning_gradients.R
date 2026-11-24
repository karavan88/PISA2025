library(data.table);setDTthreads(1)
BASE<-'03_outputs/03_learning_diagnostics';OUT<-'05_papers/01_SESTransmission/04_output/learning_gradients_20261117';dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');PV<-c(paste0('PV',1:10,'READ'),paste0('PV',1:10,'MATH'));RW<-paste0('W_FSTURWT',1:80);SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters');DICT<-readRDS('03_outputs/02_grade_diagnostics/dictionary.rds')
sig<-tools::md5sum(c('05_papers/01_SESTransmission/01_code/01_grade_diagnostics/09_learning_gradients.R',file.path(BASE,'manifest.json')));sf<-file.path(OUT,'signature.rds');if(file.exists(sf))stopifnot(identical(sig,readRDS(sf)))else saveRDS(sig,sf)
suff<-function(d,w,vars,ys){w<-w/sum(w);X<-as.matrix(d[,..vars]);Y<-as.matrix(d[,..ys]);X<-sweep(X,2,colSums(X*w));Y<-sweep(Y,2,colSums(Y*w));list(A=crossprod(X,w*X),b=crossprod(X,w*Y))}
fit<-function(z,targets){active<-diag(z$A)>1e-12;stopifnot(all(targets%in%rownames(z$A)[active]));a<-z$A[active,active,drop=FALSE];if(rcond(a)<1e-12)stop('Collinear design');solve(a,z$b[active,,drop=FALSE])[targets,,drop=FALSE]}
pooled_rows<-function(point,variance,targets,ys){rbindlist(lapply(targets,function(t)rbindlist(lapply(c('Reading','Math',intersect(S,ys)),function(y){j<-if(y=='Reading')which(ys%in%paste0('PV',1:10,'READ'))else if(y=='Math')which(ys%in%paste0('PV',1:10,'MATH'))else which(ys==y);if(!length(j))return(NULL);v<-point[t,j];se<-sqrt(mean(variance[t,j])+if(length(j)>1)1.1*var(v)else 0);data.table(term=t,outcome=y,estimate=mean(v),se,p=2*pnorm(-abs(mean(v)/se)),lower=mean(v)-1.96*se,upper=mean(v)+1.96*se)}))))}
country<-list();pooled<-list();fail<-list();validation<-list()
for(ii in 1:4)for(kind in c('Skills to learning','Grade gradients'))for(model in c('Unadjusted','Adjusted')){
 vars<-if(kind=='Skills to learning')S else 'grade';if(model=='Adjusted')vars<-unique(c(vars,'age_months','grade','nonmale','status'));ys<-if(kind=='Skills to learning')PV else c(PV,S);targets<-if(kind=='Skills to learning')S else 'grade';stats<-list();N<-list()
 for(cc in DICT$countries$CNT){
 d<-readRDS(file.path(BASE,paste0('sample_',cc,'_',ii,'.rds')));key<-paste(cc,ii,kind,model,sep='|')
 if(nrow(d)<200||uniqueN(d$school)<20){fail[[key]]<-data.table(CNT=cc,sample=SUB[ii],kind,model,reason='Fewer than 200 pupils or 20 schools');next}
 tryCatch({
  z<-suff(d,d$W_FSTUWT,vars,ys);pt<-fit(z,targets);rs<-lapply(RW,function(r)suff(d,d[[r]],vars,ys));rr<-array(NA_real_,c(length(targets),length(ys),80),dimnames=list(targets,ys,NULL));for(r in 1:80)rr[,,r]<-fit(rs[[r]],targets)
  variance<-apply(sweep(rr,c(1,2),pt)^2,c(1,2),sum)/20
  out<-pooled_rows(pt,variance,targets,ys);out[,`:=`(CNT=cc,economy=DICT$countries[CNT==cc,economy],sample=SUB[ii],kind=kind,model=model,N=nrow(d),schools=uniqueN(d$school))];country[[key]]<-out;stats[[cc]]<-list(z=z,rep=rs,point=pt,draws=rr);N[[cc]]<-c(nrow(d),uniqueN(d$school))
  if(length(stats)==1){v<-vars[vapply(vars,function(v)sd(d[[v]])>1e-6,logical(1))];lmfit<-lm(reformulate(v,response=ys[1]),d,weights=W_FSTUWT);err<-max(abs(coef(lmfit)[targets]-pt[,1]));stopifnot(err<1e-7);validation[[key]]<-data.table(sample=SUB[ii],kind,model,CNT=cc,lm_error=err)}
 },error=function(e){fail[[key]]<<-data.table(CNT=cc,sample=SUB[ii],kind,model,reason=conditionMessage(e))})
 }
 total<-list(A=Reduce(`+`,lapply(stats,function(z)z$z$A)),b=Reduce(`+`,lapply(stats,function(z)z$z$b)));pt<-fit(total,targets);variance<-matrix(0,nrow(pt),ncol(pt),dimnames=dimnames(pt))
 for(cc in names(stats))for(r in 1:80){x<-stats[[cc]];rep<-list(A=total$A-x$z$A+x$rep[[r]]$A,b=total$b-x$z$b+x$rep[[r]]$b);variance<-variance+(fit(rep,targets)-pt)^2/20}
 out<-pooled_rows(pt,variance,targets,ys);out[,`:=`(sample=SUB[ii],kind=kind,model=model,countries=length(stats),N=sum(vapply(N,function(x)x[1],numeric(1))))];pooled[[paste(ii,kind,model)]]<-out
 if(kind=='Grade gradients')saveRDS(lapply(stats,function(x)list(point=x$point,draws=x$draws)),file.path(OUT,paste0('gradients_',ii,'_',model,'.rds')))
 cat(SUB[ii],kind,model,length(stats),'systems complete\n');flush.console()
}
fwrite(rbindlist(country),file.path(OUT,'country_models.csv'));fwrite(rbindlist(pooled),file.path(OUT,'pooled_models.csv'));fwrite(rbindlist(fail),file.path(OUT,'failures.csv'));fwrite(rbindlist(validation),file.path(OUT,'validation.csv'))
# Association between country grade slopes: update BOTH x and y in each survey replicate.
meta<-list();scatter<-list()
meta_fit<-function(x,y){X<-cbind(1,10*x);solve(crossprod(X),crossprod(X,y))[2,]}
for(ii in 1:4)for(model in c('Unadjusted','Adjusted')){
 g<-readRDS(file.path(OUT,paste0('gradients_',ii,'_',model,'.rds')));K<-length(g)
 for(skill in S)for(domain in c('READ','MATH')){
  ycols<-paste0('PV',1:10,domain);x<-vapply(g,function(a)a$point['grade',skill],numeric(1));Y<-t(vapply(g,function(a)a$point['grade',ycols],numeric(10)));pt<-meta_fit(x,Y);vari<-numeric(10)
  for(c in 1:K)for(r in 1:80){xx<-x;yy<-Y;xx[c]<-g[[c]]$draws['grade',skill,r];yy[c,]<-g[[c]]$draws['grade',ycols,r];vari<-vari+(meta_fit(xx,yy)-pt)^2/20}
  se<-sqrt(mean(vari)+1.1*var(pt));meta[[length(meta)+1]]<-data.table(sample=SUB[ii],model,skill,outcome=if(domain=='READ')'Reading'else'Math',countries=K,estimate=mean(pt),se,p=2*pnorm(-abs(mean(pt)/se)),lower=mean(pt)-1.96*se,upper=mean(pt)+1.96*se,correlation=cor(x,rowMeans(Y)))
  scatter[[length(scatter)+1]]<-data.table(CNT=names(g),sample=SUB[ii],model,skill,outcome=if(domain=='READ')'Reading'else'Math',skill_gradient=x,learning_gradient=rowMeans(Y))
 }
}
fwrite(rbindlist(meta),file.path(OUT,'gradient_associations.csv'));fwrite(rbindlist(scatter),file.path(OUT,'gradient_scatter.csv'));cat('All analyses complete\n')
