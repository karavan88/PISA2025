library(data.table);library(ggplot2)
OUT<-Sys.getenv('GRADE_CONTROL_OUT','05_papers/01_SESTransmission/04_output/grade_control_20261117_v2')
E<-fread(file.path(OUT,'comparison.csv'));V<-fread(file.path(OUT,'validation.csv'))
means<-function(x)x[,.(estimate=mean(estimate),se=sqrt(sum(se^2))/.N,K=.N),by=.(sample,term,specification)][,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se)]
A<-means(E);fwrite(A,file.path(OUT,'available_means.csv'))
common<-V[,.(ok=uniqueN(sample)==4),by=CNT][ok==TRUE,CNT];G<-means(E[CNT%in%common]);fwrite(G,file.path(OUT,'matched_means.csv'))
counts<-E[,.(K=.N,positive=sum(lower>0),negative=sum(upper<0),uncertain=sum(lower<=0&upper>=0),BH_significant=sum(q<.05)),by=.(sample,term,specification)];fwrite(counts,file.path(OUT,'direction_counts.csv'))
SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters')
terms<-c('curiosity_within','joint_within','curiosity_sorting','joint_sorting');names<-c('Curiosity: within school','Joint: within school','Curiosity: including sorting','Joint: including sorting')
x<-G[term%in%terms & specification%in%c('baseline','grade_adjusted')];x[,`:=`(sample=factor(sample,SUB),term=factor(term,terms,labels=names),specification=factor(specification,c('baseline','grade_adjusted'),labels=c('Original controls','Plus grade in both equations')))]
theme_set(theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),legend.position='bottom',strip.text=element_text(face='bold'),plot.title.position='plot'))
p<-ggplot(x,aes(estimate,sample,color=specification))+geom_vline(xintercept=0,color='grey75')+geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.15,position=position_dodge(.45))+geom_point(size=2.5,position=position_dodge(.45))+facet_wrap(~term,scales='free_x',ncol=2)+scale_color_manual(values=c('#254E60','#C46B3B'))+labs(title='Do the skills pathways survive adjustment for grade?',subtitle=paste('Exactly the same pupils in each model pair;',length(common),'systems common to all 4 populations.'),x='Reading points per 10 SES percentile points (95% confidence intervals)',y=NULL,color=NULL)
ggsave(file.path(OUT,'grade_pathways.png'),p,width=12,height=7,dpi=200,bg='white');ggsave(file.path(OUT,'grade_pathways.pdf'),p,width=12,height=7,bg='white')
stopifnot(all(V$baseline_error<1e-6),all(V$pair_error<1e-6),all(V$engine_error<1e-5),all(V$valid_draws>=475),!any(E$CNT%in%c('ISR','UKR','QUA')))
w<-dcast(E,CNT+sample+term~specification,value.var='estimate');stopifnot(max(abs(w$grade_adjusted-w$baseline-w$change))<1e-10,max(abs(w$grade_fixed_sorting-w$baseline-w$change_fixed_sorting))<1e-10)
cat('PASS: paired change identities, original fits/draw reproduction, reference engine, exclusions, bootstrap validity.\n')
F<-fread(file.path(OUT,'failures.csv'));BASE<-Sys.getenv('GRADE_DIAG_OUT','05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2')
if(nrow(F)){
 F<-rbindlist(lapply(seq_len(nrow(F)),function(i){d<-readRDS(file.path(BASE,paste0('sample_',F$CNT[i],'_',match(F$sample[i],SUB),'.rds')));cbind(F[i],data.table(N=nrow(d),grade_levels=uniqueN(d$grade),mixed_grade_schools=d[,uniqueN(grade)>1,by=school][,sum(V1)]))}))
 F[,explanation:=fifelse(grade_levels==1,'Grade is constant; a separate grade coefficient cannot be estimated.',fifelse(mixed_grade_schools==0,'No within-school grade variation; the full within-between grade control is unidentified.','Too few mixed-grade schools to retain 475 valid paired bootstrap draws.'))]
}
fwrite(F,file.path(OUT,'failure_details.csv'))
