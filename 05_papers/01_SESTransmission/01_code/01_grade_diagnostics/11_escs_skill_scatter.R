# Descriptive fits on saved analytic samples; no harmonization or manuscript changes.
library(data.table)
library(ggplot2)
setDTthreads(1)
base <- '05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2'
out <- '05_papers/01_SESTransmission/04_output/escs_skill_scatter_20261117_v2'
dir.create(out, recursive=TRUE, showWarnings=FALSE)
dict <- readRDS('03_outputs/02_grade_diagnostics/dictionary.rds')
skills <- c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG')
labels <- c('Perseverance','Curiosity','Enjoyment of problem solving','Cognitive adaptability','Goal setting','Self-regulated help seeking')
samples <- c('All analytic pupils','Never repeated a grade','Urban female non-repeaters','Urban male non-repeaters')
paths <- c('03_outputs/02_grade_diagnostics/dictionary.rds','05_papers/01_SESTransmission/01_code/01_grade_diagnostics/11_escs_skill_scatter.R',file.path(base,paste0('sample_',rep(dict$countries$CNT,each=4),'_',1:4,'.rds')))
sig <- tools::md5sum(paths)
sf <- file.path(out,'signature.rds')
if(file.exists(sf)) stopifnot(identical(sig,readRDS(sf))) else saveRDS(sig,sf)
excluded <- list(); allcoef <- list(); allpoints <- list(); alllines <- list()
for(i in 1:4){
 pts <- list(); lines <- list()
 for(cc in dict$countries$CNT){
  d <- as.data.table(readRDS(file.path(base,paste0('sample_',cc,'_',i,'.rds'))))
  d <- d[is.finite(ESCS)&is.finite(W_FSTUWT)&W_FSTUWT>0]
  if(nrow(d)<200 || uniqueN(d$school)<20 || uniqueN(d$ESCS)<2) {
   excluded[[length(excluded)+1]] <- data.table(sample=samples[i],CNT=cc,N=nrow(d),schools=uniqueN(d$school),escs_values=uniqueN(d$ESCS)); next
  }
  # Fixed-width bins display weighted scatter summaries; fits use every continuous observation.
  d[,bin:=floor(ESCS/0.25)]
  z <- d[order(ESCS)]; cum <- cumsum(z$W_FSTUWT)/sum(z$W_FSTUWT)
  lim <- vapply(c(.025,.975),function(p)z$ESCS[which(cum>=p)[1]],numeric(1))
  grid <- seq(lim[1],lim[2],length.out=60)
  for(k in seq_along(skills)){
   sk <- skills[k]; y <- d[[sk]]; stopifnot(all(is.finite(y)))
   fit <- lm(y~ESCS,data=d,weights=W_FSTUWT)
   b <- coef(fit)
   allcoef[[length(allcoef)+1]] <- data.table(sample=samples[i],CNT=cc,economy=d$economy[1],skill=labels[k],N=nrow(d),intercept=b[1],slope=b[2])
   lines[[length(lines)+1]] <- data.table(sample=samples[i],CNT=cc,skill=labels[k],ESCS=grid,value=b[1]+b[2]*grid)
   pp <- d[,.(ESCS=weighted.mean(ESCS,W_FSTUWT),value=weighted.mean(get(sk),W_FSTUWT),n=.N),by=bin][n>=30 & ESCS>=lim[1] & ESCS<=lim[2]]
   pp[,`:=`(sample=samples[i],CNT=cc,skill=labels[k])];pts[[length(pts)+1]] <- pp
  }
 }
 ptd <- rbindlist(pts); ld <- rbindlist(lines)
 ptd[,skill:=factor(skill,levels=labels)];ld[,skill:=factor(skill,levels=labels)]
 p <- ggplot()+geom_hline(yintercept=0,color='grey85',linewidth=.3)+
  geom_point(data=ptd,aes(ESCS,value,color=CNT),alpha=.23,size=.65)+
  geom_line(data=ld,aes(ESCS,value,color=CNT,group=CNT),alpha=.7,linewidth=.45)+
  facet_wrap(~skill,ncol=3)+scale_color_viridis_d(option='D',end=.95,limits=sort(dict$countries$CNT))+
  labs(title='Socio-emotional skills and socio-economic status',subtitle=paste0(samples[i],' | ',uniqueN(ld$CNT),' systems | One fitted line per system'),
       x='Socio-economic status (continuous ESCS index)',y='Skill (within-country SD)',
       caption='Survey-weighted, unadjusted linear fits using individual pupils. Points: weighted means in 0.25-ESCS bins (at least 30 pupils).\nLines and points shown over each national weighted 2.5th-97.5th ESCS percentiles. Colors identify systems, not significance.\nSkill scales retain the original national analytic-sample standardization. Country-specific panels and a color key are in the PDF atlas.')+
  theme_minimal(base_size=12)+theme(legend.position='none',panel.grid.minor=element_blank(),plot.title=element_text(face='bold',size=19),strip.text=element_text(face='bold'),plot.caption=element_text(size=9,hjust=0),plot.background=element_rect(fill='white',color=NA))
 ggsave(file.path(out,paste0('escs_skills_sample_',i,'.png')),p,width=15,height=9,dpi=180)
 ggsave(file.path(out,paste0('escs_skills_sample_',i,'.pdf')),p,width=15,height=9)
 if(i==1){
  pdf(file.path(out,'country_atlas.pdf'),width=15,height=10)
  print(p+theme(legend.position='bottom',legend.text=element_text(size=6))+guides(color=guide_legend(nrow=6,override.aes=list(alpha=1,linewidth=1))))
  for(sk in labels){
   pp <- ggplot(ptd[skill==sk],aes(ESCS,value))+geom_point(size=.55,alpha=.55,color='#21708a')+geom_line(data=ld[skill==sk],color='#bd6248',linewidth=.55)+facet_wrap(~CNT,ncol=9)+labs(title=paste(sk,'and continuous ESCS'),subtitle='All analytic pupils; weighted descriptive fits. Country codes follow the source data.',x='ESCS',y='Skill (national SD)')+theme_minimal(base_size=8)+theme(panel.grid.minor=element_blank())
   print(pp)
  }
  dev.off()
 }
 allpoints[[i]] <- ptd; alllines[[i]] <- ld
 cat(samples[i],':',uniqueN(ld$CNT),'systems\n')
}
co <- rbindlist(allcoef)
stopifnot(!anyDuplicated(co[,.(sample,CNT,skill)]),all(is.finite(co$slope)))
fwrite(co,file.path(out,'descriptive_slopes.csv'))
fwrite(rbindlist(allpoints),file.path(out,'scatter_bin_means.csv'))
fwrite(rbindlist(alllines),file.path(out,'fitted_lines.csv'))
fwrite(dict$countries,file.path(out,'country_key.csv'))
print(co[,.(countries=.N,positive=sum(slope>0),negative=sum(slope<0)),by=.(sample,skill)])

fwrite(rbindlist(excluded),file.path(out,'excluded_system_samples.csv'))
