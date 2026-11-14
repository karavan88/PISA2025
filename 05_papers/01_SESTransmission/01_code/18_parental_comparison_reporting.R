library(data.table);setDTthreads(1)
p<-normalizePath(getwd());while(!dir.exists(file.path(p,'05_papers/01_SESTransmission/04_output'))){q<-dirname(p);if(identical(q,p))stop('Project root not found');p<-q}
ROOT<-p;DEST<-file.path(ROOT,'05_papers/01_SESTransmission/04_output/parental_controls_comparison')
readtab<-function(n)fread(file.path(DEST,'tables',paste0(n,'.csv')))
EE<-readtab('estimates_adjusted');DD<-readtab('paired_differences_adjusted');COV<-readtab('coverage');PAIR<-readtab('headline_comparison');SUMMARY<-readtab('support_summary');CHANGE<-readtab('change_summary')
fmt<-function(x,d=2)formatC(x,format='f',digits=d,big.mark=',')
num<-function(x)format(x,big.mark=',',scientific=FALSE,trim=TRUE)
bound<-function(x)ifelse(is.finite(x)&abs(x)>0&abs(x)<.005,formatC(x,format='f',digits=4),fmt(x))
ci<-function(x,lo,hi)paste0(fmt(x),' [',bound(lo),', ',bound(hi),']')
result<-function(cc,tt,spec='Parental_background'){z<-EE[CNT==cc&term==tt&specification==spec];stopifnot(nrow(z)==1);ci(z$estimate,z$lower,z$upper)}
difference<-function(cc,tt){z<-DD[CNT==cc&term==tt];stopifnot(nrow(z)==1);ci(z$estimate,z$lower,z$upper)}
count<-function(k,s,field='Expected_support')SUMMARY[estimand==k&specification==s,get(field)]
change<-function(k,field)CHANGE[estimand==k,get(field)]
tbl<-function(x,cap,widths=NULL,size=8){z<-knitr::kable(x,format='latex',booktabs=TRUE,longtable=TRUE,row.names=FALSE,caption=cap,linesep='');z<-kableExtra::kable_styling(z,latex_options='repeat_header',font_size=size,repeat_header_text='(continued)');if(!is.null(widths))for(i in seq_along(widths))z<-kableExtra::column_spec(z,i,width=widths[i]);z}
