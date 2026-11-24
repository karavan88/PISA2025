# Standalone editorial previews. Reads saved estimates; never fits models.
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(patchwork)})
setDTthreads(1)
root<-normalizePath('.')
while(!file.exists(file.path(root,'02_scripts/00_tools/check_repo.py'))) {
 parent<-dirname(root);stopifnot(parent!=root);root<-parent
}
paper<-file.path(root,'05_papers/01_SESTransmission')
saved<-file.path(paper,'04_output/rev2')
out<-file.path(paper,'04_output/01_chart_alternatives/20261124_v1')
if(dir.exists(out))stop('Preview snapshot exists; choose a new version before rebuilding.')
dir.create(out,recursive=TRUE)
E<-fread(file.path(saved,'tables/manuscript_estimates.csv'))[exposure=='SES']
CE<-fread(file.path(saved,'tables/manuscript_equalization_estimates.csv'))[exposure=='SES']
WB<-fread(file.path(saved,'tables/within_between_decomposition.csv'))
stopifnot(uniqueN(E$CNT)==67L,uniqueN(CE$CNT)==67L)
source(file.path(paper,'01_code/26_system_means_rev2.R'))
skill_names<-c(PERSEV='Perseverance',CURIO='Curiosity',ENPROBS='Enjoyment of problem solving',COGABIL='Cognitive adaptability',GOALSET='Goal setting',SELFREG='Help seeking')
cols<-c(Ecuador='#70558C',Japan='#17677E',Korea='#BB5839','Mean (67 systems)'='#172F3B')
theme_set(theme_minimal(base_size=11,base_family='Helvetica')+
 theme(panel.grid.minor=element_blank(),panel.grid.major.y=element_blank(),
 legend.position='bottom',legend.title=element_blank(),strip.text=element_text(face='bold'),
 axis.title=element_text(size=10),plot.margin=margin(12,14,12,12)))
save<-function(p,name,w=8,h=5) {
 ggsave(file.path(out,paste0(name,'.pdf')),p,width=w,height=h,device=cairo_pdf)
 ggsave(file.path(out,paste0(name,'.png')),p,width=w,height=h,dpi=180,device=ragg::agg_png,bg='white')
}
baseline<-c(f2='ses_gap_link_w',f3='ses_pathways',f4='ses_skills',f5='ses_within_between_composition',f6='ses_sorting_increment',f7='ses_recipient_gap_korea',f8='ses_equalization')
for(n in names(baseline))stopifnot(file.copy(file.path(saved,'figures',paste0(baseline[n],'.pdf')),file.path(out,paste0(n,'_current.pdf'))))

# F2: retain all countries, explain the two links and label product contours.
d<-fread(file.path(saved,'tables/ses_gap_link_w_data.csv'))
d[,skill:=factor(unname(skill_names[skill_code]),levels=unname(skill_names))]
mn<-d[,.(a=mean(a),b=mean(b)),by=skill];mn[,example:='Mean (67 systems)']
paths<-c(.25,.5,1);xend<-max(d$a)*.90
curves<-rbindlist(lapply(paths,function(k) {
 x<-seq(max(k/(max(d$b)*.95),.0001),xend,length.out=100)
 data.table(a=x,b=k/x,path=k)
}))
labels<-curves[,.SD[.N],by=path]
p<-ggplot(d,aes(a,b))+geom_hline(yintercept=0,colour='grey65')+geom_vline(xintercept=0,colour='grey65')+
 geom_line(data=curves,aes(group=path),linetype='dashed',colour='#CCD3D6')+
 geom_text(data=labels,aes(label=paste0(path,' pt')),size=2.8,hjust=1,vjust=-.4,colour='#71818A')+
 geom_point(colour='#B9C3C7',size=1.7)+
 geom_point(data=d[example!='Other systems'],aes(colour=example,shape=example),size=2.5)+
 ggrepel::geom_text_repel(data=d[example!='Other systems'],aes(label=CNT,colour=example),size=2.7,seed=4,show.legend=FALSE,max.overlaps=Inf)+
 geom_point(data=mn,aes(colour=example,shape=example),size=3.2)+
 scale_colour_manual(values=cols,breaks=names(cols))+scale_shape_manual(values=c(15,16,17,18),breaks=names(cols))+
 facet_wrap(~skill,ncol=3,labeller=label_wrap_gen(22))+
 coord_cartesian(xlim=range(c(0,d$a)),ylim=range(c(0,d$b)))+
 labs(x='Skill difference per 10 SES rank points (skill SD)',y='Reading difference per skill SD (points)')
save(p,'f2_plain_links',9,6.1)

# F3: paired pathway estimates with a connector; retain original 95% intervals.
ids<-unique(E[order(economy),CNT]);half<-ceiling(length(ids)/2)
paired<-dcast(E[term%in%c('skills_same_school','skills_sorting')],CNT+economy~term,value.var='estimate')
z<-E[term%in%c('skills_same_school','skills_sorting')]
z<-rbindlist(list(z,system_mean(z)),fill=TRUE)
paired<-rbind(paired,data.table(CNT='MEAN',economy='Mean (67 systems)',skills_same_school=mean(paired$skills_same_school),skills_sorting=mean(paired$skills_sorting)))
allids<-c(ids,'MEAN');z[,idx:=match(CNT,allids)];paired[,idx:=match(CNT,allids)]
lim<-range(c(z$lower,z$upper))
panels<-lapply(1:2,function(i) {
 zz<-z[if(i==1)idx<=half else idx>half];pp<-paired[CNT%in%zz$CNT]
 zz[,y:=half+1-if(i==1)idx else idx-half];pp[,y:=half+1-if(i==1)idx else idx-half]
 zz[,Profile:=factor(term,levels=c('skills_same_school','skills_sorting'),labels=c('Among classmates','Including school sorting'))]
 ggplot(zz,aes(estimate,y,colour=Profile))+
 geom_vline(xintercept=0,colour='grey60')+
 geom_segment(data=pp,aes(x=skills_same_school,xend=skills_sorting,y=y,yend=y),inherit.aes=FALSE,colour='#AAB4BA',linewidth=1.1)+
 geom_segment(aes(x=lower,xend=upper,yend=y),linewidth=.3,alpha=.55,show.legend=FALSE)+
 geom_point(aes(shape=Profile),size=2)+scale_shape_manual(values=c(1,16))+
 scale_colour_manual(values=c('#17677E','#BB5839'))+
 scale_y_continuous(breaks=pp$y,labels=pp$economy)+
 scale_x_continuous(limits=lim)+labs(x='Reading points per 10 SES rank points',y=NULL)+
 theme(axis.text.y=element_text(size=8))
})
save((panels[[1]]|panels[[2]])+plot_layout(guides='collect',axis_titles='collect'),'f3_connected',8.8,10.2)

# F4: all country estimates, deterministic vertical jitter, and mean uncertainty.
z<-E[grepl('^indS_',term)];z[,skill:=factor(unname(skill_names[sub('indS_','',term)]),levels=rev(unname(skill_names)))]
mn<-system_mean(z);mn[,skill:=factor(unname(skill_names[sub('indS_','',term)]),levels=levels(z$skill))]
setorder(z,skill,CNT);z[,yy:=as.numeric(skill)+rep(seq(-.17,.17,length.out=67),length.out=.N),by=skill]
hi<-z[CNT%in%c('ECU','JPN','KOR')];hi[,example:=economy];mn[,example:='Mean (67 systems)']
p<-ggplot(z,aes(estimate,yy))+geom_vline(xintercept=0,colour='grey60')+
 geom_point(colour='#A9B7BD',size=1.8,alpha=.65)+
 geom_point(data=hi,aes(colour=example,shape=example),size=2.7)+
 geom_segment(data=mn,aes(x=lower,xend=upper,y=as.numeric(skill),yend=as.numeric(skill)),inherit.aes=FALSE,linewidth=1.2,colour='#172F3B')+
 geom_point(data=mn,aes(estimate,as.numeric(skill),colour=example,shape=example),size=3.5)+
 scale_colour_manual(values=cols,breaks=names(cols))+scale_shape_manual(values=c(15,16,17,18),breaks=names(cols))+
 scale_y_continuous(breaks=seq_along(skill_names),labels=levels(z$skill))+
 labs(x='Skill contribution to the pathway (reading points per 10 SES rank points)',y=NULL)
save(p,'f4_country_distribution',9,5.2)

# F5: retain composition, use two fills and explicit W/B row labels.
seg<-fread(file.path(saved,'tables/within_between_figure_segments.csv'))
int<-rbindlist(list(WB[term%in%c('total_within','total_between')],system_mean(WB[term%in%c('total_within','total_between')])),fill=TRUE)
orderids<-c(WB[term=='total_between_minus_within'][order(-estimate,economy),CNT],'MEAN')
lim<-range(c(seg$start,seg$end,int$lower,int$upper))
pp<-lapply(1:2,function(i) {
 cc<-orderids[if(i==1)1:34 else 35:68]
 zz<-copy(seg[CNT%in%cc]);zz[,base:=35-match(CNT,cc)];zz[,y:=base+ifelse(level=='Within',.18,-.18)]
 zz[,Kind:=factor(kind,levels=c('Skills','Remaining'),labels=c('Skills-mediated','Remaining'))]
 ints<-copy(int[CNT%in%cc]);ints[,y:=35-match(CNT,cc)+ifelse(term=='total_within',.18,-.18)]
 labs<-unique(zz[,.(base,economy)])
 ggplot(zz)+geom_vline(xintercept=0,colour='grey60')+
 geom_rect(aes(xmin=pmin(start,end),xmax=pmax(start,end),ymin=y-.135,ymax=y+.135,fill=Kind))+
 geom_segment(data=ints,aes(x=lower,xend=upper,y=y,yend=y),linewidth=.25)+
 geom_text(data=unique(zz[,.(y,level)]),aes(x=lim[1]-.35,y=y,label=ifelse(level=='Within','W','B')),size=2.1,colour='#53646D')+
 scale_fill_manual(values=c('#17677E','#D4DEE1'))+
 scale_y_continuous(breaks=labs$base,labels=labs$economy)+
 scale_x_continuous(limits=c(lim[1]-.7,lim[2]))+
 labs(x='Reading points per 10 SES rank points',y=NULL)+theme(axis.text.y=element_text(size=8))
})
save((pp[[1]]|pp[[2]])+plot_layout(guides='collect',axis_titles='collect'),'f5_two_fills',9,10.5)

# F7: paired accounting examples. No independent-error propagation is used.
terms<-c('recipient_change','reference_change','gap_reduction')
z<-rbindlist(list(CE[CNT=='KOR'&term%in%terms],system_mean(CE[term%in%terms])),fill=TRUE)
z[,Profile:=factor(ifelse(CNT=='KOR','Korea','Mean (67 systems)'),levels=c('Korea','Mean (67 systems)'))]
bars<-rbindlist(lapply(levels(z$Profile),function(pr) {
 zz<-z[Profile==pr];r<-zz[term=='recipient_change',estimate];g<-zz[term=='gap_reduction',estimate]
 data.table(Profile=pr,step=1:3,start=c(0,g,0),end=c(r,r,g),value=c(r,-zz[term=='reference_change',estimate],g))
}))
errs<-z[term!='reference_change'];errs[,step:=ifelse(term=='recipient_change',1L,3L)]
p<-ggplot(bars)+geom_hline(yintercept=0,colour='grey60')+
 geom_rect(aes(xmin=step-.32,xmax=step+.32,ymin=start,ymax=end,fill=factor(step)))+
 geom_segment(data=bars[step==1],aes(x=1.32,xend=1.68,y=end,yend=end),linetype='dotted',colour='grey50')+
 geom_segment(data=bars[step==3],aes(x=2.32,xend=2.68,y=end,yend=end),linetype='dotted',colour='grey50')+
 geom_errorbar(data=errs,aes(x=step,ymin=lower,ymax=upper),width=.1,linewidth=.45)+
 geom_text(aes(x=step,y=(start+end)/2,label=sprintf('%+.2f',value)),colour='white',fontface='bold',size=3.6)+
 scale_fill_manual(values=c('#17677E','#929FA7','#BB5839'),guide='none')+
 scale_x_continuous(breaks=1:3,labels=c('Recipient\ngain','Subtract advantaged\ngroup gain','Gap\nreduction'))+
 facet_wrap(~Profile,nrow=1)+labs(x=NULL,y='Predicted reading change (points)')
save(p,'f7_waterfall',9,5)

# F8: recipient gain versus net gap reduction, all 67 systems plus mean.
z<-dcast(CE[term%in%c('recipient_change','gap_reduction')],CNT+economy~term,value.var='estimate')
mn<-data.table(CNT='MEAN',economy='Mean (67 systems)',recipient_change=mean(z$recipient_change),gap_reduction=mean(z$gap_reduction))
hi<-z[CNT%in%c('ECU','JPN','KOR')]
lim<-range(c(0,z$recipient_change,z$gap_reduction))*1.08
p<-ggplot(z,aes(recipient_change,gap_reduction))+
 geom_abline(slope=1,intercept=0,linetype='dashed',colour='#7C8D96')+
 geom_hline(yintercept=0,colour='grey75')+geom_vline(xintercept=0,colour='grey75')+
 geom_point(colour='#A9B7BD',size=2.4)+
 geom_point(data=hi,aes(colour=economy,shape=economy),size=3)+
 ggrepel::geom_text_repel(data=hi,aes(label=economy,colour=economy),seed=8,size=3.5,show.legend=FALSE)+
 geom_point(data=mn,aes(colour=economy,shape=economy),size=4)+
 scale_colour_manual(values=cols,breaks=names(cols))+scale_shape_manual(values=c(15,16,17,18),breaks=names(cols))+
 coord_equal(xlim=lim,ylim=lim)+labs(x='Recipient gain (reading points)',y='Reduction in the SES reading gap (points)')
save(p,'f8_gains_vs_gap',7.5,6.6)
stopifnot(z[,max(abs(recipient_change-gap_reduction-CE[term=='reference_change',estimate][match(CNT,CE[term=='reference_change',CNT])]))]<1e-8)
writeLines(c('Saved estimates only. No models fitted.','Mean intervals use independent country variances and equal weights.','Country order and values retained; previews are not manuscript replacements.'),file.path(out,'README.txt'))
message('Created 6 alternative charts and 7 frozen current charts in ',out)
