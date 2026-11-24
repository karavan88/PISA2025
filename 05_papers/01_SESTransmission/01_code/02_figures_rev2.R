source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
library(ggplot2)
library(patchwork)
# Editorial text belongs in manuscript captions; preserve axis and facet labels.
ggsave <- function(filename, plot, ...) {
 blank <- theme(plot.title=element_blank(),plot.subtitle=element_blank(),plot.caption=element_blank())
 plot <- if(inherits(plot,'patchwork')) plot & blank else plot + blank
 ggplot2::ggsave(filename,plot=plot,...)
}
COL <- c('School setting fixed'='#17677E','With school sorting'='#BB5839')
theme_set(theme_minimal(base_size=10, base_family='Helvetica') +
  theme(panel.grid.minor=element_blank(), panel.grid.major.y=element_blank(),
    plot.title=element_text(face='bold',size=13,colour='#172F3B'),
    plot.subtitle=element_text(size=10,colour='#475961',margin=margin(b=10)),
    legend.position='top', legend.title=element_blank(),
    axis.title=element_text(size=9),axis.text=element_text(colour='#263A45'),
    strip.text=element_text(face='bold'), plot.margin=margin(8,8,8,8)))
save_fig <- function(p, name, w, h) {
  ggsave(file.path(OUT,'figures',paste0(name,'.pdf')),p,width=w,height=h,device=cairo_pdf)
  ggsave(file.path(OUT,'figures',paste0(name,'.png')),p,width=w,height=h,dpi=300,device=ragg::agg_png,bg='white')
  ggsave(file.path(OUT,'figures',paste0(name,'.svg')),p,width=w,height=h,device=svglite::svglite)
}
forest <- function(ex, full=TRUE) {
  z <- E[exposure==ex & term%in%c('skills_same_school','skills_sorting') & (skills==6)==full]
  ids <- unique(z[order(economy),CNT]); n <- length(ids); n1 <- ceiling(n/2)
  z[, idx:=match(CNT,ids)]
  z[, panel:=ifelse(idx<=n1,'A','B')]
  z[, row:=ifelse(idx<=n1,idx,idx-n1)]
  z[,Evidence:=factor(ifelse(p_approx<.05,'p < 0.05',ifelse(p_approx<.1,'p < 0.10','Not significant')),levels=c('p < 0.05','p < 0.10','Not significant'))]
  z[, Profile:=ifelse(term=='skills_same_school','School setting fixed','With school sorting')]
  z[, yy:=n1-row+1+ifelse(term=='skills_same_school',.15,-.15)]
  labels <- merge(unique(z[,.(CNT,economy,skills,panel,row)]),A[exposure==ex,.(CNT,items)],by='CNT')
  labels[, label:=if(ex=='DEP') paste0(economy,' [',items,']') else economy]
  if(!full) labels[,label:=paste0(label,' {',skills,'}')]
  lim <- range(c(z$lower,z$upper)); lim <- c(floor(lim[1]),ceiling(lim[2]))
  axis_label <- if(ex=='SES') 'Reading points per 10 SES percentile points' else 'Reading points per additional unaffordable item'
  mm<-system_mean(z,by='term'); mm[,Profile:=ifelse(term=='skills_same_school','School setting fixed','With school sorting')]
  mm[,yy:=ifelse(term=='skills_same_school',.15,-.15)]
  mm[,Evidence:=factor(ifelse(p_value<.05,'p < 0.05',ifelse(p_value<.1,'p < 0.10','Not significant')),levels=levels(z$Evidence))]
  panels <- lapply(c('A','B'),function(pn) {
    zz<-rbindlist(list(z[panel==pn],if(pn=='A') mm else NULL),fill=TRUE); ll<-labels[panel==pn]
    ggplot(zz,aes(x=estimate,y=yy,colour=Profile,shape=Evidence)) +
      geom_hline(yintercept=seq(1,n1),colour='#EDF0F1',linewidth=.25) +
      geom_vline(xintercept=0,colour='#71838A',linewidth=.4) +
      geom_segment(aes(x=lower,xend=upper,yend=yy),linewidth=.5) + geom_point(size=1.7) +
      scale_colour_manual(values=COL) + scale_shape_manual(values=c(16,17,1),drop=FALSE) +
      scale_y_continuous(breaks=c(n1-ll$row+1,if(pn=='A') 0),labels=c(ll$label,if(pn=='A') paste0('Mean (',n,' systems)')),limits=c(-.6,n1+.6),expand=c(0,0)) +
      scale_x_continuous(limits=lim,breaks=scales::breaks_pretty(5)) +
      labs(x=axis_label,y=NULL) + theme(axis.text.y=element_text(size=8),panel.grid.major.x=element_line(colour='#E4E9EB'))
  })
  p <- (panels[[1]] | panels[[2]]) + plot_layout(guides='collect') & theme(legend.position='top')
  p <- p + plot_annotation(title=if(ex=='SES') 'Socio-emotional skills and the socio-economic reading gradient' else 'Socio-emotional skills and material deprivation',
    subtitle=paste0(n,' systems | ',if(full)'all 6 skills' else 'incomplete skill blocks',' | dots and 95% intervals'),
    caption=paste0(axis_label,'\nSymbols: strongest threshold met; not significant at 10%.\n',mean_note,if(ex=='DEP') '\nBrackets give retained deprivation items; item sets differ between systems.' else '',if(!full)'\nBraces give the number of observed skills.' else ''),
    theme=theme(plot.caption=element_text(size=9,hjust=0,colour='#475961')))
  save_fig(p,paste0(tolower(ex),'_pathways',if(!full)'_partial' else ''),7.4,if(full)8.2 else 3.4)
}
heat <- function(ex) {
  z<-E[exposure==ex & skills==6 & grepl('^indS_',term)]
  ids<-unique(z[order(economy),CNT]); split<-ceiling(length(ids)/2)
  z[,Group:=ifelse(match(CNT,ids)<=split,'A','B')]
  z[,skill:=factor(sub('indS_','',term),levels=names(sklab))]
  mn<-system_mean(z);mn[,skill:=factor(sub('indS_','',term),levels=names(sklab))]
  mn[,Group:='A']
  countries<-unique(z[order(economy),economy]);z<-rbindlist(list(z,mn),fill=TRUE)
  z[,country:=factor(economy,levels=c(unique(mn$economy),rev(countries)))]
  z[,Evidence:=factor(ifelse(p_approx<.05,'p < 0.05',ifelse(p_approx<.1,'p < 0.10','Not significant')),levels=c('p < 0.05','p < 0.10','Not significant'))]
  lim<-ceiling(max(abs(z$estimate))*2)/2
  short<-c(PERSEV='Persev.',CURIO='Curiosity',ENPROBS='Problem\nsolving',COGABIL='Adapt.',GOALSET='Goals',SELFREG='Help\nseeking')
  p<-ggplot(z,aes(skill,country,fill=estimate)) + geom_tile(colour='white',linewidth=.25) +
    geom_point(aes(shape=Evidence),fill='white',colour='#183B4A',stroke=.3,size=1.4,na.rm=TRUE) +
    scale_shape_manual(values=c(21,24,NA),drop=FALSE,name='Two-sided p-value',labels=c('p < 0.05','p < 0.10','No symbol: Not significant')) +
    guides(fill=guide_colourbar(order=1),shape=guide_legend(order=2,nrow=1,override.aes=list(size=2))) +
    scale_fill_gradient2(low='#BC5739',mid='#F7F6F1',high='#17677E',midpoint=0,limits=c(-lim,lim),name='Reading points') +
    scale_x_discrete(labels=short,position='top') +
    facet_wrap(~Group,ncol=2,scales='free_y') + labs(x=NULL,y=NULL,
      title=if(ex=='SES') 'Which skills transmit the SES difference?' else 'Which skills carry the deprivation pathway?',
      subtitle=if(ex=='SES') 'Skill contributions per 10 SES rank points, including observed school composition' else 'Skill contributions per additional unaffordable item, including observed school composition',
      caption='Persev. = perseverance; Adapt. = cognitive adaptability; Goals = goal setting / study management.\nProblem solving = enjoyment of problem solving; Help seeking = self-regulated help seeking.\nSymbols: strongest threshold met; unmarked = not significant at 10%. Mean: equal-weight country contributions.') +
    theme(panel.grid=element_blank(),strip.text=element_blank(),strip.background=element_blank(),
      axis.text.x=element_text(size=7,angle=45,hjust=0,vjust=.5),axis.text.y=element_text(size=7),
      legend.position='bottom',legend.key.width=grid::unit(1,'cm'),plot.caption=element_text(size=7.6,hjust=0),
      panel.spacing=grid::unit(.35,'cm'),plot.margin=margin(45,35,8,8))
  save_fig(p,paste0(tolower(ex),'_skills'),7.4,8.2)
}

gap_link <- function(level='W') {
  terms <- as.vector(outer(c(paste0('a',level,'_'),paste0('b',level,'_')),names(sklab),paste0))
  z <- E[exposure=='SES' & skills==6 & term%in%terms]
  z[,skill_code:=sub('^[ab][WB]_','',term)]
  z[,link:=substr(term,1,1)]
  d <- dcast(z,CNT+economy+skill_code~link,value.var='estimate')
  stopifnot(nrow(d)==nsys()*6,all(is.finite(d$a)),all(is.finite(d$b)))
  d[,skill:=factor(unname(sklab[skill_code]),levels=unname(sklab))]
  d[,example:=ifelse(CNT%in%c('KOR','JPN','ECU'),economy,'Other systems')]
  mean_label <- paste0('Mean (',nsys(),' countries)')
  cols <- c('Other systems'='#9CAAB0','Japan'='#17677E','Korea'='#BB5839','Ecuador'='#70558C')
  maxa <- max(d$a)*1.08; maxb <- max(d$b)*1.08
  paths <- if(level=='W') c(.25,.5,1) else c(1,3,5)
  curves <- rbindlist(lapply(paths,function(k) {
    a <- seq(max(k/maxb,.0001),maxa,length.out=150)
    data.table(a=a,b=k/a,path=k)
  }))
  mn<-d[,.(a=mean(a),b=mean(b)),by=skill]
  mn[,example:=mean_label]
  cols<-c(cols,setNames('black',mean_label))
  p <- ggplot(d,aes(a,b)) +
    geom_hline(yintercept=0,colour='#89969C',linewidth=.35) +
    geom_vline(xintercept=0,colour='#89969C',linewidth=.35) +
    geom_line(data=curves,aes(group=path),colour='#BEC6C8',linetype='dashed',linewidth=.35) +
    geom_point(data=d[example=='Other systems'],colour=cols[1],size=1.7,alpha=.7) +
    geom_point(data=d[example!='Other systems'],aes(colour=example,shape=example),size=2.3) +
    ggrepel::geom_text_repel(data=d[example!='Other systems'],aes(label=CNT,colour=example),
      size=2.6,seed=2026,min.segment.length=0,max.overlaps=Inf,box.padding=.3,show.legend=FALSE) +
    geom_point(data=mn,aes(shape=example,colour=example),size=3.2) +
    facet_wrap(~skill,ncol=3,labeller=label_wrap_gen(23)) +
    scale_colour_manual(values=cols) + scale_shape_manual(values=c('Japan'=16,'Korea'=17,'Ecuador'=15,setNames(18,mean_label))) +
    coord_cartesian(xlim=range(c(0,d$a)),ylim=range(c(0,d$b))) +
    labs(x=if(level=='W') 'Skill difference per 10 SES rank points within a school (aW, skill SD)' else 'Skill difference per 10 school-average SES rank points (aB, skill SD)',
      y=if(level=='W') 'Reading points per skill SD within a school (bW)' else 'Reading points per unit of school-average skill (bB)',
      title=if(level=='W') '2 links are needed for a skill to transmit advantage' else 'The 2 links between school averages',
      subtitle=paste0(nsys(),' systems | 6 skills | all skills enter the reading equation together'),
      caption=paste0('1 dot per system. JPN = Japan; KOR = Korea; ECU = Ecuador. Gray dots: all other systems.\nBlack diamond: equal-weight means of the 2 links; their product is not the mean pathway.\nDashed curves: products of ',paste(paths,collapse=', '),' reading points. Point estimates; intervals in the saved tables.')) +
    theme(panel.grid.major.y=element_line(colour='#E4E9EB'),legend.position='bottom',
      plot.caption=element_text(size=8,hjust=0),strip.text=element_text(size=9))
  save_fig(p,paste0('ses_gap_link_',tolower(level)),7.4,6.3)
  fwrite(d,file.path(OUT,'tables',paste0('ses_gap_link_',tolower(level),'_data.csv')))
}
robustness <- function(ex='SES') {
  base <- E_ESCS_FULL[exposure==ex & skills==6 & term=='skills_sorting',.(CNT,economy,main=estimate)]
  d <- V[exposure==ex & term=='skills_sorting' & variant%in%c('unscaled_weights','minimum_10','core_four_same_sample'),.(CNT,variant,alternative=estimate)]
  d <- rbind(d,L[exposure==ex & term=='skills_sorting',.(CNT,variant='lmer_unweighted',alternative=lmer_unweighted)])
  d <- merge(base,d,by='CNT')
  names_variant <- c(unscaled_weights='Unscaled student weights',minimum_10='Schools with at least 10 pupils',
    lmer_unweighted='Unweighted lmer',core_four_same_sample='Four common deprivation items')
  d[,variant:=factor(variant,levels=names(names_variant))]
  d[,difference:=alternative-main]
  d[,label:=ifelse(rank(-abs(difference),ties.method='first')<=3,CNT,''),by=variant]
  lim <- range(c(0,d$main,d$alternative)); lim<-lim+c(-1,1)*diff(lim)*.07
  pp <- lapply(levels(droplevels(d$variant)),function(vv) {
    zz<-d[variant==vv]
    ggplot(zz,aes(main,alternative)) +
      geom_abline(slope=1,intercept=0,linetype='dashed',colour='#89969C',linewidth=.5) +
      geom_hline(yintercept=0,colour='#E1E6E8',linewidth=.3) +
      geom_vline(xintercept=0,colour='#E1E6E8',linewidth=.3) +
      geom_point(colour='#17677E',size=1.9,alpha=.7) +
      ggrepel::geom_text_repel(data=zz[label!=''],aes(label=label),size=2.7,seed=2026,
        min.segment.length=0,max.overlaps=Inf,box.padding=.35) +
      geom_point(data=data.table(main=mean(zz$main),alternative=mean(zz$alternative)),shape=23,fill='black',colour='white',size=3) +
      coord_equal(xlim=lim,ylim=lim) +
      labs(title=paste0(paste(strwrap(names_variant[vv],width=24),collapse='\n'),'\n(n = ',nrow(zz),')'),x='Main specification',y='Alternative specification') +
      theme(plot.title=element_text(size=10),panel.grid.major.y=element_line(colour='#E4E9EB'))
  })
  p<-wrap_plots(pp,ncol=if(ex=='SES')3 else 2) + plot_annotation(
    title=if(ex=='SES') 'Does the size of the SES skills pathway survive alternative choices?' else 'How sensitive is the deprivation skills pathway?',
    subtitle=if(ex=='SES') 'Reading points per 10 SES rank points | joint pathway including school composition' else 'Reading points per additional unaffordable item | joint pathway including school composition',
    caption=paste0('Black diamond: equal-weight means. Each dot is a system. On the diagonal, the 2 estimates agree; distance shows the change in magnitude.\nLabels identify the 3 largest absolute changes per panel. Saved point estimates; no new intervals.',
      if(ex=='DEP') '\nThe 4-item definition changes the exposure on the same pupils; lmer retains the main sorting coefficient.' else '\nThe lmer comparison retains the main sorting coefficient.'),
    theme=theme(plot.title=element_text(size=12,face='bold'),plot.subtitle=element_text(size=9),
      plot.caption=element_text(size=8,hjust=0)))
  save_fig(p,paste0(tolower(ex),'_robustness'),7.4,if(ex=='SES')4.0 else 7.1)
  fwrite(d,file.path(OUT,'tables',paste0(tolower(ex),'_robustness_data.csv')))
}
for(ex in c('SES','DEP')) {forest(ex);heat(ex);robustness(ex)}
gap_link('W');gap_link('B')
fwrite(E[term%in%c('skills_same_school','skills_sorting') | grepl('^indS_',term)],file.path(OUT,'tables/figure_data.csv'))
message('Main and supplementary figures exported as vector PDF/SVG and 300 dpi PNG; all use saved estimates.')
