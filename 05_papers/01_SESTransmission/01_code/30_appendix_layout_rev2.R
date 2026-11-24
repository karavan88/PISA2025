# Collect tables and group them without changing their original exhibit numbers.
appendix_tables <- list()
original_tbl <- tbl
tbl <- function(x,caption=NULL,...) {
 id<-length(appendix_tables)+1L
 appendix_tables[[id]] <<- as.character(original_tbl(x,caption,...))
 invisible(structure('',class='knitr_kable',format='latex'))
}
model_snippet <- function(id) {
 if(!id %in% c(9,11:20,25:28,32:37))return('')
 dep<-id %in% c(12,14,20,27,28,32,33)
 controls<-if(dep)'c("AGE", "nonmale", "PAREDINT", "HISEI")' else 'c("AGE", "nonmale")'
 lines<-c('# Equivalent model specification; not executed',
 '# W: pupil deviation; B: weighted school mean',
 paste0('controls <- ',controls),
 'skills <- c("PERSEV", "CURIO", "ENPROBS",',
 '            "COGABIL", "GOALSET", "SELFREG")',
 'f <- function(y, x) as.formula(paste(y, "~",',
 '  paste(c(paste0(x, "_W"), paste0(x, "_B"),',
 '          "(1 | school)"), collapse = " + ")))',
 'M1 <- f(skill, c("status", controls))',
 'M2 <- f(reading_PV, c("status", controls, skills))',
 'WeMix::mix(M2, d, weights=c("w1", "w2"), cWeights=TRUE)')
 if(id==37)lines<-c(lines[!grepl('M2',lines,fixed=TRUE)], 'WeMix::mix(M1, d, weights=c("w1", "w2"), cWeights=TRUE)')
 if(id%in%c(11:20,32))lines<-c(lines,
 'S <- reformulate(c("status", controls,',
 '                   paste0(controls, "_B")), "status_B")',
 'lm(S, d, weights=W_FSTUWT)')
 if(id%in%c(25:28,33:36))lines<-c(lines,
 '# Equalization uses M2 and empirical donor profiles.',
 '# Update school skill means; predict both group gains.',
 '# Gap reduction = recipient gain - reference gain.')
 if(id%in%c(32,33))lines<-c(lines,
 '# Comparator: identical pupils, replace parent controls',
 'controls <- c("AGE", "nonmale", "ESCS")',
 '# Rebuild M1/M2, refit within the same bootstrap draws.',
 '# Paired change = parental estimate - ESCS estimate.')
 if(id==34)lines<-c('# Before fitting: retain unscaled conditional weights', 's <- prepare_model(z, mode="unscaled")', 'd <- s$d', lines)
 if(id==35)lines<-c('# Before fitting: restrict and rebuild school quantities', 'counts <- z$data[, .N, by=school]', 'z$data <- z$data[school %in% counts[N >= 10, school]]', 's <- prepare_model(z); d <- s$d', lines)
 if(id==36)lines<-gsub('WeMix::mix(M2, d, weights=c("w1", "w2"), cWeights=TRUE)',
 'lme4::lmer(M2, d, REML=FALSE)',lines,fixed=TRUE)
 paste0('\n{\\footnotesize\n\\begin{verbatim}\n',paste(lines,collapse='\n'),'\n\\end{verbatim}\n}\n')
}
emit_appendix_tables <- function(ids) {
 stopifnot(length(appendix_tables)==37L)
 for(id in ids) {
  landscape<-id%in%c(4,19,20,37)
  if(id!=ids[1])cat('\n\\clearpage\n')
  if(landscape)cat('\\begin{landscape}\n')
  cat(model_snippet(id))
  cat('\\setcounter{table}{',id-1L,'}\n',sep='')
  cat(appendix_tables[[id]],'\n')
  if(landscape)cat('\\end{landscape}\n')
 }
}
