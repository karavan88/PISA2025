library(data.table);library(ggplot2);setDTthreads(1)
OUT<-Sys.getenv('GRADE_DIAG_OUT','05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2')
E<-fread(file.path(OUT,'ols_coefficients.csv'));M<-fread(file.path(OUT,'mediation.csv'));C<-fread(file.path(OUT,'coverage.csv'));B<-fread(file.path(OUT,'ses_deciles.csv'))
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');labs<-c(Reading='Reading',PERSEV='Perseverance',CURIO='Curiosity',ENPROBS='Enjoyment of problem solving',COGABIL='Cognitive adaptability',GOALSET='Goal setting',SELFREG='Self-regulated help seeking')
SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters');MOD<-c('Age adjusted','SES adjusted','School FE','School FE + quadratic age')
means<-function(x,bycols){x[,.(estimate=mean(estimate),se=sqrt(sum(se^2))/.N,K=.N),by=bycols][,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se)]}
# Comparisons across models and populations use exactly the same eligible systems.
x<-E[basis=='Common six-skill sample' & model%in%MOD]
sets<-x[,.(eligible=uniqueN(paste(sample,model))==16),by=.(CNT,outcome)][eligible==TRUE]
y<-merge(x,sets[,.(CNT,outcome)],by=c('CNT','outcome'))
G<-means(y,c('outcome','sample','model'));fwrite(G,file.path(OUT,'matched_grade_means.csv'))
A<-means(E,c('outcome','sample','model','basis'));fwrite(A,file.path(OUT,'available_means.csv'))
medset<-M[,.(eligible=uniqueN(sample)==4),by=CNT][eligible==TRUE,CNT]
MM<-means(M[CNT%in%medset],c('term','sample'));fwrite(MM,file.path(OUT,'matched_mediation_means.csv'))
SS<-fread(file.path(OUT,'sex_contrasts.csv'));SS<-merge(SS,C[sample==SUB[3],.(CNT,female_N=N,female_schools=schools)],by='CNT');SS<-merge(SS,C[sample==SUB[4],.(CNT,male_N=N,male_schools=schools)],by='CNT');SS[,c('N','schools','mixed_schools'):=NULL];SS[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se,p=2*pnorm(-abs(estimate/se)))];SS[,q:=p.adjust(p,'BH'),by=.(model,outcome)];fwrite(SS,file.path(OUT,'sex_contrasts_intervals.csv'));fwrite(means(SS,c('outcome','model')),file.path(OUT,'sex_contrast_means.csv'))
counts<-E[basis=='Common six-skill sample',.(K=.N,positive=sum(lower>0),negative=sum(upper<0),uncertain=sum(lower<=0&upper>=0),BH_significant=sum(q<.05)),by=.(sample,model,outcome)];fwrite(counts,file.path(OUT,'direction_counts.csv'))
sesx<-E[basis=='Common six-skill sample' & grepl('SES slope',model)];sesset<-sesx[,.(ok=uniqueN(paste(sample,model))==8),by=.(CNT,outcome)][ok==TRUE];sesx<-merge(sesx,sesset[,.(CNT,outcome)],by=c('CNT','outcome'));fwrite(means(sesx,c('outcome','sample','model')),file.path(OUT,'matched_ses_means.csv'))
# Paired within-school reading and skill grade associations, never-repeaters.
z<-dcast(E[basis=='Common six-skill sample' & model=='School FE',.(CNT,economy,sample,outcome,estimate,lower,upper)],CNT+economy+sample~outcome,value.var=c('estimate','lower','upper'))
P<-rbindlist(lapply(S,function(s)z[,.(CNT,economy,sample,skill=s,reading=estimate_Reading,reading_positive=lower_Reading>0,skill_grade=get(paste0('estimate_',s)),skill_low=get(paste0('lower_',s)),skill_high=get(paste0('upper_',s)))]))
fwrite(P,file.path(OUT,'grade_pattern.csv'))
fig<-file.path(OUT,'figures');dir.create(fig,showWarnings=FALSE)
theme_set(theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),legend.position='bottom',plot.title.position='plot',strip.text=element_text(face='bold')))
pal<-c('#224B5E','#CB703A','#629782','#815E9C')
saveplot<-function(p,n,w=11,h=7){ggsave(file.path(fig,paste0(n,'.png')),p,width=w,height=h,dpi=180,bg='white');ggsave(file.path(fig,paste0(n,'.pdf')),p,width=w,height=h,bg='white')}
G[,`:=`(model=factor(model,MOD),sample=factor(sample,SUB),outcome=factor(outcome,names(labs),labels=labs))]
p<-ggplot(G,aes(model,estimate,color=sample,group=sample))+geom_hline(yintercept=0,color='grey65')+geom_line(position=position_dodge(.4))+geom_errorbar(aes(ymin=lower,ymax=upper),width=.15,position=position_dodge(.4))+geom_point(position=position_dodge(.4))+facet_wrap(~outcome,scales='free_y',ncol=2)+scale_color_manual(values=pal)+labs(title='What changes when we compare pupils within the same school?',subtitle=paste('Equal-weight means on matched systems; 95% confidence intervals. Reading: points; skills: original country SDs.'),x=NULL,y='Difference associated with 1 higher grade',color=NULL)+theme(axis.text.x=element_text(angle=20,hjust=1))
saveplot(p,'grade_means',12,11)
p<-ggplot(P[sample=='Never repeated'],aes(reading,skill_grade))+geom_hline(yintercept=0,color='grey65')+geom_vline(xintercept=0,color='grey65')+geom_point(aes(color=skill_low>0|skill_high<0),alpha=.75)+facet_wrap(~factor(skill,S,labels=labs[S]),scales='free_y',ncol=2)+scale_color_manual(values=c('#BAC5CA','#B85436'),labels=c('Skill interval includes 0','Skill interval excludes 0'))+labs(title='Grade differences in reading and skills need not move together',subtitle='Each point is a system: never-repeaters, age and SES controlled, school fixed effects.',x='Reading points per additional grade',y='Skill SDs per additional grade',color=NULL)
saveplot(p,'grade_pattern',11,9)
# Descriptive decile means use the same systems across all four populations and all deciles.
bset<-B[N>=20,.(ok=uniqueN(paste(sample,decile))==40),by=.(CNT,skill)][ok==TRUE]
bb<-merge(B[N>=20],bset[,.(CNT,skill)],by=c('CNT','skill'))[,.(mean=mean(mean),K=.N),by=.(sample,decile,skill)]
fwrite(bb,file.path(OUT,'ses_decile_means.csv'))
p<-ggplot(bb,aes(decile,mean,color=factor(sample,SUB)))+geom_hline(yintercept=0,color='grey70')+geom_line(linewidth=.8)+geom_point(size=1)+facet_wrap(~factor(skill,S,labels=labs[S]),ncol=2)+scale_color_manual(values=pal)+labs(title='Are all skills higher among socio-economically advantaged pupils?',subtitle='Descriptive means, equal weight per eligible system; country skill scales held fixed.',x='National SES decile (1 = least advantaged)',y='Mean skill score (original country SDs)',color=NULL)
saveplot(p,'ses_profiles',11,9)
mm<-MM[term%in%c('joint_W','skills_sorting','sorting_increment')];mm[,sample:=factor(sample,SUB)]
p<-ggplot(mm,aes(estimate,sample,color=sample))+geom_vline(xintercept=0,color='grey70')+geom_segment(aes(x=lower,xend=upper,yend=sample),linewidth=.8)+geom_point(size=3)+facet_wrap(~factor(term,c('joint_W','skills_sorting','sorting_increment'),labels=c('Among classmates','Including observed sorting','Sorting increment')),scales='free_x')+scale_color_manual(values=pal)+labs(title='Does the skills pathway survive the population restrictions?',subtitle='Matched systems; 499 school bootstrap draws and 10 reading plausible values.',x='Reading points per 10 SES percentile points',y=NULL,color=NULL)+theme(legend.position='none')
saveplot(p,'mediation',13,5)
# Three-variable display: bins formed inside each system, then averaged equally.
tri<-list();correls<-list();stratdiag<-list();desc<-list()
for(cc in unique(C$CNT))for(i in 1:4){d<-readRDS(file.path(OUT,paste0('sample_',cc,'_',i,'.rds')));if(!nrow(d))next
 schoolstr<-unique(d[,.(school,STRATUM)]);ns<-schoolstr[,.N,by=STRATUM];stratdiag[[length(stratdiag)+1]]<-data.table(CNT=cc,sample=SUB[i],schools=nrow(schoolstr),singleton_schools=sum(ns$N==1),singleton_share=mean(schoolstr$STRATUM%in%ns[N==1,STRATUM]),unreported_stratum_schools=sum(is.na(schoolstr$STRATUM)));
 for(v in c('grade','age_months','status',S,'Reading')){vs<-if(v=='Reading')paste0('PV',1:10,'READ')else v;mu<-sapply(vs,function(k)weighted.mean(d[[k]],d$W_FSTUWT));vari<-sapply(seq_along(vs),function(j)weighted.mean((d[[vs[j]]]-mu[j])^2,d$W_FSTUWT));desc[[length(desc)+1]]<-data.table(CNT=cc,sample=SUB[i],variable=v,mean=mean(mu),SD=sqrt(mean(vari)))}
 for(s in S){w<-d$W_FSTUWT;mx<-weighted.mean(d$status,w);my<-weighted.mean(d[[s]],w);cov<-weighted.mean((d$status-mx)*(d[[s]]-my),w);corr<-cov/sqrt(weighted.mean((d$status-mx)^2,w)*weighted.mean((d[[s]]-my)^2,w));correls[[length(correls)+1]]<-data.table(CNT=cc,sample=SUB[i],skill=s,correlation=corr)
  b<-d[,.(ses=pmin(5,pmax(1,ceiling(status/2))),skillbin=pmin(5,pmax(1,findInterval(get(s),c(-Inf,-1,-.3,.3,1,Inf)))),reading=Reading,W_FSTUWT)]
  v<-b[,.(reading=weighted.mean(reading,W_FSTUWT),N=.N),by=.(ses,skillbin)][N>=20];v[,`:=`(CNT=cc,sample=SUB[i],skill=s)];tri[[length(tri)+1]]<-v
 }}
fwrite(rbindlist(stratdiag),file.path(OUT,'bootstrap_strata.csv'));fwrite(rbindlist(desc),file.path(OUT,'descriptives_validated.csv'));TT<-rbindlist(tri);fwrite(TT,file.path(OUT,'three_variable_country_bins.csv'));TT<-TT[,.(reading=mean(reading),systems=.N),by=.(sample,skill,ses,skillbin)][systems>=5];fwrite(TT,file.path(OUT,'three_variable_means.csv'));fwrite(rbindlist(correls),file.path(OUT,'ses_skill_correlations.csv'))
fwrite(data.table(check=c('common_primary_N_matches_models','no_excluded_countries','matched_grade_cells','matched_mediation_systems'),value=c(all(x[,uniqueN(N),by=.(CNT,sample)]$V1==1),!any(E$CNT%in%c('ISR','UKR','QUA')),nrow(G),length(medset))),file.path(OUT,'report_validation.csv'))
cat('Report products complete\n')
