# Shared cutoff-design extraction and audit; no model estimation.
suppressPackageStartupMessages(library(data.table))
setDTthreads(1)
WORK <- '03_outputs/01_harmonized'
OUT <- file.path(WORK,'cutoff');dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
x <- readRDS(file.path(WORK,'cutoff_provider.rds'))
labs <- attr(x$CNT,'labels'); names_by_code <- setNames(names(labs),as.character(labs))
d <- as.data.table(lapply(x,function(v)if(is.character(v))as.character(v)else as.numeric(v)));rm(x);gc()
d[, `:=`(byear=fifelse(ST003D03T<2100,ST003D03T,ST003D03T-543),bmonth=ST003D02T,grade=ST001D01T,
 female=fifelse(is.na(ST004D01T),NA_real_,as.numeric(ST004D01T==1)),
 lang_other=fifelse(is.na(ST022Q01TA),NA_real_,as.numeric(ST022Q01TA==2)),
 immigrant=fifelse(is.na(IMMIG),NA_real_,as.numeric(IMMIG>1)),
 repeated=fifelse(is.na(REPEAT),NA_real_,as.numeric(REPEAT==1)),
 vocational=as.integer(ISCEDP%in%c(254,354)),
 growth=fifelse(is.na(ST420Q01DA),NA_real_,as.numeric(ST420Q01DA%in%c(1,2))))]
wmean <- function(x,w){ok<-!is.na(x)&!is.na(w);sum(x[ok]*w[ok])/sum(w[ok])}
# Reconstruct the exploratory general-programme audit previously saved without code.
audit <- rbindlist(lapply(sort(unique(d$CNT)),function(cc){
 z<-d[CNT==cc & vocational==0 & !is.na(grade)&!is.na(byear)&!is.na(bmonth)]
 if(nrow(z)<500)return(NULL)
 g<-z[,.(w=sum(W_FSTUWT)),by=grade][order(-w)]
 info<-data.table(CNT=cc,name=names_by_code[cc],OECD=z$OECD[1],N=nrow(z),skills=round(mean(!is.na(z$CURIO)),2),persev=round(mean(!is.na(z$PERSEV)),2))
 if(nrow(g)<2 || g$w[1]/sum(g$w)>.98) return(cbind(info,data.table(grades=paste(g$grade[1],'only'),share_hi=NA_real_,cut=NA_character_,jump=0,other=NA_real_,profile='single grade')))
 hi<-max(g$grade[1:2]);lo<-min(g$grade[1:2]);z[,t:=byear*12+bmonth]
 pr<-z[,.(p=wmean(as.numeric(grade>=hi),W_FSTUWT),n=.N),by=t][order(t)]
 pr<-pr[n>=30]; if(nrow(pr)<2)return(NULL)
 delta<-diff(pr$p);j<-which.min(delta)+1L;tt<-pr$t[j]
 cbind(info,data.table(grades=paste(lo,hi,sep='/'),share_hi=round(wmean(as.numeric(z$grade>=hi),z$W_FSTUWT),2),cut=paste0(month.abb[(tt-1)%%12+1],(tt-1)%/%12),jump=round(-min(delta),2),other=round(mean(abs(delta[-(j-1)])),2),profile=paste(sprintf('%.2f',pr$p),collapse=' ')))
}),fill=TRUE)
fwrite(audit[order(-jump)],file.path(OUT,'cutoff_audit_all.csv'))
cand<-audit[jump>=.15 & profile!='single grade']
keep<-c('CNT','OECD','CNTSCHID','CNTSTUID','STRATUM','grade','ISCEDP','vocational','byear','bmonth','AGE','female','lang_other','immigrant','repeated','ESCS','PERSEV','SELFREG','GOALSET','CURIO','ENPROBS','COGABIL','BELONG','growth',unlist(lapply(c('SCIE','MATH','READ'),function(v)paste0('PV',1:10,v))),'W_FSTUWT','SENWT',paste0('W_FSTURWT',1:80))
saveRDS(d[CNT%in%cand$CNT,..keep],file.path(OUT,'students.rds'))
sys<-cand[,.(CNT,audit_jump=jump,audit_cut=cut,profile,name,OECD)]
fwrite(sys,file.path(OUT,'systems.csv'))
cat(nrow(audit),'systems audited;',nrow(cand),'candidates\n')
