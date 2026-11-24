# Use the shared publication theme/save_fig from 02_figures_rev2.R.
WB <- fread(file.path(OUT,'tables/within_between_decomposition.csv'))
order_ids <- c(WB[term=='total_between_minus_within'][order(-estimate,economy), CNT], 'MEAN')
WB<-rbindlist(list(WB,system_mean(WB[!grepl('share',term)])),fill=TRUE)
part_terms <- c('skills_within','remaining_within','skills_between','remaining_between')
parts <- copy(WB[term %in% part_terms])
parts[, level := ifelse(grepl('within',term),'Within','Between')]
parts[, kind := ifelse(grepl('^skills',term),'Skills','Remaining')]
parts[, idx := match(CNT,order_ids)]
parts[, panel := ifelse(idx<=34,'A','B')]
parts[, row := 35-ifelse(idx<=34,idx,idx-34)]
parts[, yy := row+ifelse(level=='Within',.17,-.17)]
setorder(parts,idx,level,-kind) # Skills first at zero on each signed side.
parts[, sign := ifelse(estimate>=0,'positive','negative')]
parts[, end := cumsum(estimate),by=.(CNT,level,sign)]
parts[, start := end-estimate]
parts[, Fill := factor(term,levels=part_terms)]
intervals <- copy(WB[term %in% c('total_within','total_between')])
intervals[,idx:=match(CNT,order_ids)]
intervals[,panel:=ifelse(idx<=34,'A','B')]
intervals[,row:=35-ifelse(idx<=34,idx,idx-34)]
intervals[,yy:=row+ifelse(term=='total_within',.17,-.17)]
colors <- c(skills_within='#17677E',remaining_within='#B8D7DF',
            skills_between='#BB5839',remaining_between='#EDCABB')
limits <- range(c(0,parts$start,parts$end,intervals$lower,intervals$upper))
limits <- c(floor(limits[1])-.15,ceiling(limits[2])+.15)
ps <- lapply(c('A','B'),function(pn) {
  d <- parts[panel==pn]; ints <- intervals[panel==pn]
  labels <- unique(d[,.(row,economy)])
  ggplot(d) +
    geom_rect(data=data.table(row=seq(2,34,2)),
      aes(xmin=-Inf,xmax=Inf,ymin=row-.45,ymax=row+.45),
      fill='#F3F5F5',inherit.aes=FALSE) +
    geom_vline(xintercept=0,colour='#687D87',linewidth=.35) +
    geom_rect(aes(xmin=pmin(start,end),xmax=pmax(start,end),
                  ymin=yy-.135,ymax=yy+.135,fill=Fill)) +
    geom_segment(data=ints,aes(x=lower,xend=upper,y=yy,yend=yy),
                 colour='#263A45',linewidth=.22) +
    geom_segment(data=ints,aes(x=lower,xend=lower,y=yy-.055,yend=yy+.055),
                 colour='#263A45',linewidth=.3) +
    geom_segment(data=ints,aes(x=upper,xend=upper,y=yy-.055,yend=yy+.055),
                 colour='#263A45',linewidth=.3) +
    scale_fill_manual(values=colors,drop=FALSE,
      labels=c('Within: skills','Within: remaining','Between: skills','Between: remaining')) +
    scale_y_continuous(breaks=labels$row,labels=labels$economy,
                      limits=c(.45,34.55),expand=c(0,0)) +
    scale_x_continuous(limits=limits,breaks=c(0,4,8,12),expand=c(0,0)) +
    labs(x='Reading points per 10 national rank points',y=NULL) +
    guides(fill=guide_legend(nrow=2,byrow=TRUE)) +
    theme(axis.text.y=element_text(size=7.7),axis.text.x=element_text(size=8),
          axis.title.x=element_text(size=8),
          panel.grid.major.x=element_line(colour='#E4E9EB',linewidth=.25))
})
p <- (ps[[1]]|ps[[2]])+plot_layout(guides='collect') &
  theme(legend.position='top',legend.text=element_text(size=8.5),
        legend.key.height=grid::unit(.26,'cm'),legend.key.width=grid::unit(.55,'cm'))
p <- p+plot_annotation(title='Where the socio-economic reading gradient is distributed',
  subtitle='Each country: within schools above; between schools below\nDark segments: skills-mediated contribution. Pale segments: remaining contribution.',
  caption=paste0(mean_note,'\nBlack capped lines: 95% intervals for each level’s net contribution, including skills and the remainder.\nNegative segments extend left of zero; positive segments stack to the right. Both panels share the same scale.\nOrdered by between minus within total contribution, continuing down the left panel then the right; the all-system mean is shown last.'),
  theme=theme(plot.title=element_text(size=13,face='bold',colour='#172F3B'),
              plot.subtitle=element_text(size=9.5,colour='#475961'),
              plot.caption=element_text(size=7.7,hjust=0,colour='#475961')))
save_fig(p,'ses_within_between_composition',8.6,10.3)
fwrite(parts,file.path(OUT,'tables/within_between_figure_segments.csv'))
