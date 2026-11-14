# Manuscript reporting only: read filtered saved estimates and format them.
# No model fitting, raw-data loading, or estimation scripts are called here.
countries <- c('Armenia','Azerbaijan','Georgia','Kazakhstan','Kyrgyzstan','Moldova','Uzbekistan')
display_country <- function(x) ifelse(x == 'Uzbekistan', 'Uzbekistan (science)', x)
load_saved <- function(name, reading_only=FALSE) {
  domains <- if (reading_only) 'READ' else c('READ','SCIE')
  out <- lapply(domains, function(d) {
    z <- read.csv(file.path('ijed_data',paste0(d,'_',name,'.csv')), check.names=FALSE,
                  stringsAsFactors=FALSE, na.strings=c('NA',''))
    z$outcome <- if (d == 'READ') 'Reading' else 'Science'
    z
  })
  do.call(rbind,out)
}
samples <- load_saved('t1_sample')
rank_adj <- load_saved('h1_mediation_pkg_pct')
rank_total <- load_saved('h1_mediation_pkg_pct_total')
gel_adj <- load_saved('h1_gelbach_long_pct')
gel_total <- load_saved('h1_gelbach_long_pct_total')
dep_adj <- load_saved('h1_mediation_pkg_dep',TRUE)
dep_total <- load_saved('h1_mediation_pkg_dep_total',TRUE)
gel_dep <- load_saved('h1_gelbach_long_dep',TRUE)
rob <- load_saved('rob_gelbach_long_pct',TRUE)
get_one <- function(z, country, selector, value) {
  r <- z[z$unit == country & selector, value]
  if (length(r) == 0) return(NA_real_)
  stopifnot(length(r) == 1)
  as.numeric(r)
}
M <- function(country, value='prop', mediator='All skills (joint)', spec='adjusted', exposure='rank') {
  z <- if (exposure == 'rank') {if(spec=='adjusted') rank_adj else rank_total} else {
    if(spec=='adjusted') dep_adj else dep_total}
  get_one(z,country,z$mediator == mediator,value)
}
G <- function(country,term,value='est',spec='adjusted') {
  z <- if(spec=='adjusted') gel_adj else gel_total
  get_one(z,country,z$term==term,value)
}
fmt <- function(x,digits=1) ifelse(is.na(x),'n/a',formatC(x,digits=digits,format='f'))
mf <- function(country, value='total', digits=2, ...) fmt(M(country,value,...),digits)
mp <- function(country, mediator='All skills (joint)', ...) fmt(100*M(country,'prop',mediator,...),1)
gf <- function(country,term,mult=1,digits=2,spec='total') fmt(mult*G(country,term,spec=spec),digits)
count <- function(x) format(as.integer(x),big.mark=',',trim=TRUE)
med_keys <- c('Perseverance','Curiosity','Problem-solving enjoyment','Stress adaptability','Goal setting','Self-regulated learning','Growth mindset')
short_keys <- c('Pers.','Cur.','Problem','Adapt.','Goals','Self-reg.','Growth')
print_table <- function(d) {
  rownames(d) <- NULL
  print(knitr::kable(d,format='pipe',align=c('l',rep('r',ncol(d)-1))))
}
table_samples <- function() {
  z<-samples[match(countries,samples$Economy),]
  data.frame(Country=display_country(z$Economy),N=count(z$N),Schools=z$Schools,
             'Mean score'=z[['Outcome mean']], 'Score SD'=z[['Outcome SD']],check.names=FALSE)
}
table_gradients <- function() {
  z<-data.frame(Country=display_country(countries))
  for (s in c('CURIO','PERSEV','GOALSET','SELFREG'))
    z[[s]]<-sapply(countries,function(c) fmt(G(c,paste0('pi_',s),spec='total'),3))
  names(z)<-c('Country','Curiosity','Perseverance','Goal setting','Self-regulation')
  z
}
table_joint <- function() {
  data.frame(Country=display_country(countries),
    'Student adj.'=sapply(countries,mf),
    'School adj.'=sapply(countries,mf),
    'Joint pts'=sapply(countries,function(c) mf(c,'acme')),
    'Share S'=sapply(countries,function(c) mp(c,spec='total')),
    'Share H'=sapply(countries,mp), check.names=FALSE) -> z
  z[['Student adj.']]<-sapply(countries,function(c) mf(c,spec='total'))
  z
}
table_pathways <- function() {
  z<-data.frame(Country=display_country(countries))
  for(i in seq_along(med_keys))z[[short_keys[i]]]<-sapply(countries,function(c) mp(c,med_keys[i]))
  z
}
table_dep <- function() {
  cs<-countries[-7]
  data.frame(Country=cs,N=sapply(cs,function(c)count(M(c,'N',exposure='dep'))),
    Gradient=sapply(cs,function(c)mf(c,exposure='dep')),
    'Joint pts'=sapply(cs,function(c)mf(c,'acme',exposure='dep')),
    'Joint %'=sapply(cs,function(c)mp(c,exposure='dep')),
    'Pers. %'=sapply(cs,function(c)mp(c,'Perseverance',exposure='dep')),
    'Cur. %'=sapply(cs,function(c)mp(c,'Curiosity',exposure='dep')),
    'Growth %'=sapply(cs,function(c)mp(c,'Growth mindset',exposure='dep')),
    check.names=FALSE)
}
table_inference <- function() {
  cell<-function(c,t,mult=1)paste0(fmt(mult*G(c,t),2),' (',fmt(mult*G(c,t,'se'),2),')')
  data.frame(Country=display_country(countries),
    Gradient=sapply(countries,cell,t='beta_base'),
    'Joint pts'=sapply(countries,cell,t='explained'),
    'Joint share (%)'=sapply(countries,cell,t='share_explained',mult=100),check.names=FALSE)
}
table_robust <- function() {
  cs<-countries[-7]
  ratio<-function(c,check) {
    z<-rob[rob$unit==c & rob$check==check,]
    stopifnot(sum(z$term=='explained')==1,sum(z$term=='beta_base')==1)
    fmt(100*z$est[z$term=='explained']/z$est[z$term=='beta_base'],1)
  }
  data.frame(Country=cs,
    Baseline=sapply(cs,function(c)fmt(100*G(c,'explained')/G(c,'beta_base'),1)),
    'Modal grade'=sapply(cs,ratio,check='Modal-grade students only'),
    'Response weights'=sapply(cs,ratio,check='Re-weighted for item non-response'),check.names=FALSE)
}
# Guard against accidental changes in scope or an outcome substitution.
stopifnot(setequal(unique(rank_adj$unit),countries),setequal(unique(gel_total$unit),countries))
stopifnot(all(rank_adj$outcome[rank_adj$unit=='Uzbekistan']=='Science'))
stopifnot(all(rank_adj$outcome[rank_adj$unit!='Uzbekistan']=='Reading'))
stopifnot(all(samples$N[match(countries,samples$Economy)]==sapply(countries,function(c)M(c,'N'))))
