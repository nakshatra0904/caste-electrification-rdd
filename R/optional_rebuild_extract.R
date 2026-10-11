# Optional provenance rebuild. The shipped source extract is sufficient for the master.
# Usage: Rscript R/optional_rebuild_extract.R /path/to/panel_dataset_full.dta
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=1) stop("Supply the original 2.3 GB panel_dataset_full.dta path.")
script<-sub("^--file=","",grep("^--file=",commandArgs(),value=TRUE)[1])
PROJECT<-dirname(dirname(normalizePath(script)))
lib<-Sys.getenv("STUDY_R_LIBRARY",file.path(PROJECT,"r_library"))
if(dir.exists(lib)) .libPaths(c(lib,.libPaths()))
manifest<-jsonlite::fromJSON(file.path(PROJECT,"docs/source_manifest.json"))
source<-normalizePath(args[1])
stopifnot(file.info(source)$size==manifest$source_size,unname(tools::md5sum(source))==manifest$source_md5)
columns<-manifest$extract_columns
z<-as.data.frame(haven::read_dta(source,col_select=tidyselect::all_of(columns)))
keep<-!is.na(z$vplan4)&z$vplan4<11 & z$corr_state==1 & z$sample==1 & z$sample_h==1 & z$sing_h==1 &
 z$pop_non_zero==1 & z$st_code!=32 & !is.na(z$tot_p)&z$tot_p>0&z$tot_p<1000
z<-z[which(keep),columns,drop=FALSE]
stopifnot(nrow(z)==manifest$extract_n,!anyDuplicated(z$pca01_id))
reference<-as.data.frame(haven::read_dta(file.path(PROJECT,"data/source_extract.dta")))
stopifnot(isTRUE(all.equal(z,reference,check.attributes=FALSE,tolerance=0)))
out<-file.path(PROJECT,"r_generated/data"); dir.create(out,recursive=TRUE,showWarnings=FALSE)
haven::write_dta(z,file.path(out,"source_extract.dta"),version=14)
write.csv(z,file.path(out,"source_extract.csv"),row.names=FALSE,na="")
cat("Original byte size and MD5 verified; all 55,320 source rows match.\n")
