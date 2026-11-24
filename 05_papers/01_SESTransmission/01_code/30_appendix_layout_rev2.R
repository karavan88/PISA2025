# Collect tables and group them without changing their original exhibit numbers.
appendix_tables <- list()
original_tbl <- tbl
tbl <- function(x,caption=NULL,...) {
 id<-length(appendix_tables)+1L
 appendix_tables[[id]] <<- as.character(original_tbl(x,caption,...))
 invisible(structure('',class='knitr_kable',format='latex'))
}
model_snippet <- function(id) {
 title<-NULL; lines<-NULL
 if(id==37) {
  title<-'R code: Socio-economic gradients in skills'
  lines<-c('# Formula specification; saved results are used below.',
   '# W = within-school deviation; B = weighted school mean.',
   'controls <- c("AGE", "nonmale")',
   'form <- function(y, x) as.formula(paste(y, "~",',
   '  paste(c(paste0(x, "_W"), paste0(x, "_B"),',
   '          "(1 | school)"), collapse = " + ")))',
   'M1 <- form(skill, c("status", controls))',
   'WeMix::mix(M1, d, weights=c("w1", "w2"), cWeights=TRUE)')
 }
 if(id==11) {
  title<-'R code: Joint reading model and school sorting'
  lines<-c('skills <- c("PERSEV", "CURIO", "ENPROBS",',
   '            "COGABIL", "GOALSET", "SELFREG")',
   'M2 <- form(reading_PV, c("status", controls, skills))',
   'WeMix::mix(M2, d, weights=c("w1", "w2"), cWeights=TRUE)',
   'S <- reformulate(c("status", controls,',
   '                   paste0(controls, "_B")), "status_B")',
   'lm(S, d, weights=W_FSTUWT)',
   '# Apply within each country and reading plausible value.',
   'within_path <- sum(a_within * b_within)',
   'between_path <- sum(a_between * b_between)',
   'joint_path <- (1 - delta) * within_path + delta * between_path',
   'sorting_increment <- joint_path - within_path')
 }
 if(id==15) {
  title<-'R code: Within- and between-school decomposition'
  lines<-c('# Apply to paired model estimates in each saved draw.',
   'skills_within <- (1 - delta) * within_path',
   'skills_between <- delta * between_path',
   'total_within <- (1 - delta) * (direct_within + within_path)',
   'total_between <- delta * (direct_between + between_path)',
   'total_difference <- total_between - total_within',
   'skills_difference <- skills_between - skills_within')
 }
 if(id==25) {
  title<-'R code: Recipient gains and gap reduction'
  lines<-c('# Prediction identity, applied within each saved resample.',
   '# D: expected pupil skill changes (zero for non-recipients).',
   '# school_D: corresponding weighted school means by pupil.',
   'change <- (D - school_D) %*% b_within + school_D %*% b_between',
   'recipient_gain <- weighted.mean(change[recipient], w[recipient])',
   'reference_gain <- weighted.mean(change[reference], w[reference])',
   'gap_reduction <- recipient_gain - reference_gain')
 }
 if(id==34) {
  title<-'R code: Alternative specifications'
  lines<-c('# Unscaled conditional student weights',
   'unscaled <- prepare_model(z, mode="unscaled")',
   '# At least 10 pupils per school; rebuild school quantities',
   'counts <- z$data[, .N, by=school]',
   'restricted <- z',
   'restricted$data <- z$data[school %in% counts[N >= 10, school]]',
   'minimum_10 <- prepare_model(restricted)',
   '# Unweighted mixed model, using the same formula',
   'lme4::lmer(M2, d, REML=FALSE)',
   '# Refit and recalculate gains within each school resample.')
 }
 if(is.null(title))return('')
 paste0('\n\\begin{tcolorbox}[colback=blue!3!white,colframe=blue!25!black,',
  'boxrule=0.4pt,arc=2pt,breakable,title={',title,'},fonttitle=\\bfseries]\n',
  '\\begin{lstlisting}[style=modelR]\n',paste(lines,collapse='\n'),
  '\n\\end{lstlisting}\n\\end{tcolorbox}\n')
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
