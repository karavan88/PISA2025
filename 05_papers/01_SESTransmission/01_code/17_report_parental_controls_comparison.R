# Summarise the paired-control comparison without touching the manuscript.
library(data.table);library(ggplot2);library(patchwork);library(knitr);library(kableExtra)
setDTthreads(1)
ROOT<-normalizePath(getwd());BASE<-file.path(ROOT,'05_papers/01_SESTransmission/04_output');DEST<-file.path(BASE,'parental_controls_comparison')
EE<-fread(file.path(DEST,'tables/estimates.csv'));DD<-fread(file.path(DEST,'tables/differences.csv'));COV<-fread(file.path(DEST,'tables/coverage.csv'))
stopifnot(uniqueN(EE$CNT)==62,nrow(COV)==62,all(EE$bootstrap_valid==499),all(DD$bootstrap_valid==499))
for(zname in c('EE','DD')) {
 z<-get(zname);bycols<-if(zname=='EE')'specification'else character()
 z[,family:=fcase(estimand=='counterfactual' & term=='gap_reduction','Gap reduction',estimand=='mediation' & term%in%c('skills_sorting','sorting_increment'),'Joint pathway and sorting',grepl('^indS_',term),'Skill contributions',grepl('^a[WB]_',term),'Skill gradients',default=NA_character_)]
 z[!is.na(family),q_value:=p.adjust(p_value,'BH'),by=c(bycols,'family')]
 assign(zname,z)
}
fwrite(EE,file.path(DEST,'tables/estimates_adjusted.csv'));fwrite(DD,file.path(DEST,'tables/paired_differences_adjusted.csv'))
ORIG<-fread(file.path(BASE,'rev2/tables/manuscript_estimates.csv'))[exposure=='DEP' & CNT%in%COV$CNT]
OCF<-fread(file.path(BASE,'rev2/tables/manuscript_equalization_estimates.csv'))[exposure=='DEP' & CNT%in%COV$CNT]
old<-rbind(ORIG[term=='skills_sorting',.(CNT,estimand='mediation',term,original=estimate,original_lower=lower,original_upper=upper)],
 OCF[term=='gap_reduction',.(CNT,estimand='counterfactual',term,original=estimate,original_lower=lower,original_upper=upper)])
KEY<-EE[(estimand=='mediation' & term=='skills_sorting')|(estimand=='counterfactual' & term=='gap_reduction')]
PAIR<-merge(KEY[specification=='ESCS_same_pupils',.(CNT,economy,estimand,term,escs=estimate,escs_lower=lower,escs_upper=upper)],
 KEY[specification=='Parental_background',.(CNT,estimand,term,parental=estimate,parental_lower=lower,parental_upper=upper)],by=c('CNT','estimand','term'))
PAIR<-merge(PAIR,DD[,.(CNT,estimand,term,change=estimate,change_lower=lower,change_upper=upper,change_p=p_value,change_q=q_value)],by=c('CNT','estimand','term'))
PAIR<-merge(PAIR,old,by=c('CNT','estimand','term'));PAIR<-merge(PAIR,COV[,.(CNT,original_N,matched_N,retained_share)],by='CNT')
PAIR[,sample_change:=escs-original]
PAIR[,`:=`(escs_support=ifelse(estimand=='mediation',escs_upper<0,escs_lower>0),parental_support=ifelse(estimand=='mediation',parental_upper<0,parental_lower>0))]
PAIR[,larger_expected:=ifelse(estimand=='mediation',change<0,change>0)]
fwrite(PAIR[order(estimand,economy)],file.path(DEST,'tables/headline_comparison.csv'))
SUMMARY<-KEY[,.(Systems=.N,Expected_support=sum(if(estimand[1]=='mediation') upper<0 else lower>0),
 Opposite_support=sum(if(estimand[1]=='mediation') lower>0 else upper<0),
 BH_expected=sum((if(estimand[1]=='mediation') upper<0 else lower>0)&q_value<.05)),by=.(estimand,specification)]
CHANGE<-PAIR[,.(Systems=.N,Larger_expected=sum(larger_expected),Paired_change=sum(change_lower>0|change_upper<0),BH_change=sum(change_q<.05),
 Gained_support=sum(!escs_support&parental_support),Lost_support=sum(escs_support&!parental_support),
 max_abs_change=max(abs(change)),largest_change_country=economy[which.max(abs(change))],
 median_absolute_control_change=median(abs(change)),median_absolute_sample_change=median(abs(sample_change))),by=estimand]
for(k in unique(KEY$estimand))for(sp in unique(KEY$specification)){zz<-KEY[estimand==k&specification==sp];stopifnot(SUMMARY[estimand==k&specification==sp,Expected_support]==sum(if(k=='mediation')zz$upper<0 else zz$lower>0))}
fwrite(SUMMARY,file.path(DEST,'tables/support_summary.csv'));fwrite(CHANGE,file.path(DEST,'tables/change_summary.csv'))
# Validate algebra, identical population, paired point differences, and unchanged source.
for(i in 1:nrow(COV)) {
 x<-readRDS(file.path(DEST,'fits',paste0(COV$CNT[i],'.rds')))
 for(j in 1:2){m<-x$point[[j]]$mediation;c<-x$point[[j]]$counterfactual
 stopifnot(max(abs(m['skills_sorting',]-colSums(m[grepl('^indS_',rownames(m)),])))<1e-8,
 max(abs(m['skills_sorting',]+m['remaining',]-m['total',]))<1e-8,
 max(abs(c['recipient_change',]-c['reference_change',]-c['gap_reduction',]))<1e-8)}
 stopifnot(identical(x$point[[1]]$counterfactual['baseline_gap',],x$point[[2]]$counterfactual['baseline_gap',]),length(x$failures)==0)
 for(k in names(x$point[[1]])){d<-x$differences[estimand==k];delta<-rowMeans(x$point[[2]][[k]]-x$point[[1]][[k]]);stopifnot(max(abs(d$estimate-delta[match(d$term,names(delta))]),na.rm=TRUE)<1e-9)}
}
# Explicit independent check of paired standard errors, not inference from overlapping CIs.
for(cc in c('DNK','KOR','MYS')) {
 x<-readRDS(file.path(DEST,'fits',paste0(cc,'.rds')))
 for(k in names(x$point[[1]])) {
  bd<-x$bootstrap[[2]][[k]]-x$bootstrap[[1]][[k]];pd<-x$point[[2]][[k]]-x$point[[1]][[k]]
  se<-sqrt(rowMeans(apply(bd,c(1,2),var))+1.1*apply(pd,1,var));z<-DD[CNT==cc&estimand==k]
  stopifnot(max(abs(z$se-se[match(z$term,names(se))]),na.rm=TRUE)<1e-9)
 }
}
hashes<-fread(file.path(DEST,'audit/manuscript_hashes_before.csv'));stopifnot(identical(hashes$md5,unname(tools::md5sum(hashes$path))))
fwrite(data.table(check=c('62 countries, two specifications, 499 valid paired resamples','Within/between and skill-sum identities','Identical recipient/reference baseline gap','Paired change calculations and uncertainty','Manuscript unchanged'),passed=TRUE),file.path(DEST,'audit/comparison_checks.csv'))
COL<-c('ESCS, same pupils'='#627A89','Parental background'='#17677E','Paired change excludes zero'='#BB5839','Paired interval includes zero'='#78949E')
theme_set(theme_minimal(base_family='Helvetica',base_size=10)+theme(panel.grid.minor=element_blank(),legend.position='bottom',legend.title=element_blank(),plot.title=element_text(face='bold',colour='#183B4A'),plot.caption=element_text(hjust=0,size=8),axis.text=element_text(colour='#263A45')))
savefig<-function(p,n,w,h){ggsave(file.path(DEST,'figures',paste0(n,'.pdf')),p,width=w,height=h,device=cairo_pdf);ggsave(file.path(DEST,'figures',paste0(n,'.png')),p,width=w,height=h,dpi=250,device=ragg::agg_png)}
compareplot<-function(k){z<-copy(PAIR[estimand==k]);z[,Evidence:=ifelse(change_lower>0|change_upper<0,'Paired change excludes zero','Paired interval includes zero')];lab<-z[order(-abs(change))][1:4]
 ggplot(z,aes(escs,parental,colour=Evidence))+geom_abline(slope=1,intercept=0,colour='#7A8B91')+geom_hline(yintercept=0,colour='#DDDDDD')+geom_vline(xintercept=0,colour='#DDDDDD')+geom_point(size=2)+
 ggrepel::geom_text_repel(data=lab,aes(label=economy),size=3,seed=113,max.overlaps=Inf,show.legend=FALSE)+scale_colour_manual(values=COL)+coord_equal()+
 labs(title=if(k=='mediation')'Deprivation transmitted through skills'else'Skill equalisation: reduction in the gap',
 subtitle=if(k=='mediation')'Reading points per additional unaffordable item'else'Reading points: non-deprived minus deprived group gap',x='ESCS controls, same pupils',y='Parental education and occupation')}
p<-(compareplot('mediation')|compareplot('counterfactual'))+plot_layout(guides='collect')+plot_annotation(title='Does changing the background control change the result?',caption='Each point is a system. Both specifications use identical pupils and 499 paired school resamples.\nBelow the diagonal means a more negative mediation pathway; above it means a larger counterfactual gap reduction.')
savefig(p,'paired_controls_comparison',9.5,5.2)
# Paired skill-contribution changes: differences in the full joint mediator model.
SK<-c(PERSEV='Persev.',CURIO='Curiosity',ENPROBS='Problem\nsolving',COGABIL='Adapt.',GOALSET='Goals',SELFREG='Help\nseeking')
z<-DD[estimand=='mediation'&grepl('^indS_',term)];ids<-unique(z[order(economy),CNT]);z[,Panel:=ifelse(match(CNT,ids)<=ceiling(length(ids)/2),'A','B')]
z[,skill:=factor(sub('indS_','',term),levels=names(SK))];z[,country:=factor(economy,levels=rev(unique(z[order(economy),economy])))];z[,Evidence:=factor(ifelse(p_value<.05,'p < 0.05',ifelse(p_value<.1,'0.05 <= p < 0.10','No symbol: p >= 0.10')),levels=c('p < 0.05','0.05 <= p < 0.10','No symbol: p >= 0.10'))]
lim<-max(abs(z$estimate))
p<-ggplot(z,aes(skill,country,fill=estimate))+geom_tile(colour='white',linewidth=.25)+geom_point(aes(shape=Evidence),fill='white',colour='#183B4A',size=1.4,stroke=.3,na.rm=TRUE)+scale_shape_manual(values=c(21,24,NA),drop=FALSE)+scale_fill_gradient2(low='#BB5839',mid='#F7F6F1',high='#17677E',limits=c(-lim,lim),name='Change in reading points')+scale_x_discrete(labels=SK,position='top')+facet_wrap(~Panel,ncol=2,scales='free_y')+
 labs(title='Which skill pathways change with parental-background controls?',subtitle='Parental-background minus ESCS specification, on identical pupils',x=NULL,y=NULL,caption='Negative changes strengthen a deprivation penalty; positive changes weaken it or shift it towards advantage.\nSymbols test the paired difference (unadjusted); all six skills enter jointly in both specifications.')+
 theme(panel.grid=element_blank(),strip.text=element_blank(),axis.text.y=element_text(size=7),axis.text.x=element_text(size=7),legend.box='vertical',legend.text=element_text(size=8,margin=margin(r=8)),legend.key.width=grid::unit(.6,'cm'))+guides(fill=guide_colourbar(order=1),shape=guide_legend(order=2,nrow=1))
savefig(p,'paired_skill_contributions',8,9)
print(SUMMARY);print(CHANGE)
cat('Validation passed; comparison tables and figures written. No manuscript files modified.\n')
