# Run with Rscript from the repository root (without --vanilla).
stopifnot(file.exists('renv.lock'),requireNamespace('renv',quietly=TRUE),requireNamespace('jsonlite',quietly=TRUE))
root<-normalizePath(getwd());project_lib<-normalizePath(.libPaths()[1])
stopifnot(startsWith(project_lib,paste0(root,'/renv/library/')))
lock<-jsonlite::fromJSON('renv.lock',simplifyVector=FALSE)
for(x in lock$Packages){
 stopifnot(requireNamespace(x$Package,quietly=TRUE),packageVersion(x$Package)==package_version(x$Version))
 stopifnot(dir.exists(file.path(project_lib,x$Package)))
}
stopifnot(getRversion()==package_version(lock$R$Version))
cat('PASS: R',as.character(getRversion()),'and',length(lock$Packages),'locked package versions; project renv library is active.\n')
