# I compare the independent R run against every published numerical table.
reference<-as.data.frame(haven::read_dta(file.path(PROJECT,"data/analysis.dta")))
stopifnot(identical(names(d),names(reference)),nrow(d)==nrow(reference))
for(col in names(d)) {
  if(is.numeric(d[[col]])) stopifnot(isTRUE(all.equal(as.numeric(d[[col]]),as.numeric(reference[[col]]),tolerance=1e-12)))
  else stopifnot(identical(as.character(d[[col]]),as.character(reference[[col]])))
}
comparisons<-list()
compare<-function(stem,keys,tolerance=1e-7,strict=TRUE) {
  expected<-read.csv(file.path(PROJECT,"tables",paste0(stem,".csv")),check.names=FALSE,na.strings="")
  actual<-read.csv(file.path(T,paste0(stem,".csv")),check.names=FALSE,na.strings="")
  key<-function(z) do.call(paste,c(z[keys],sep="|"))
  stopifnot(!anyDuplicated(key(expected)),!anyDuplicated(key(actual)),setequal(key(expected),key(actual)))
  actual<-actual[match(key(expected),key(actual)),,drop=FALSE]
  numeric<-intersect(names(expected)[vapply(expected,is.numeric,logical(1))],names(actual)[vapply(actual,is.numeric,logical(1))])
  differences<-vapply(numeric,function(col) {
    stopifnot(identical(is.na(expected[[col]]),is.na(actual[[col]])))
    if(all(is.na(expected[[col]]))) return(0)
    max(abs(expected[[col]]-actual[[col]]),na.rm=TRUE)
  },numeric(1))
  passed<-all(differences<=tolerance)
  if(strict && !passed) stop("Numerical reproduction mismatch in ",stem,": ",paste(names(differences)[differences>tolerance],collapse=", "))
  comparisons[[stem]]<<-list(rows=nrow(actual),tolerance=tolerance,passed=passed,max_abs_difference=max(differences),by_column=as.list(differences))
}
compare("heterogeneity_results",c("outcome","term","bandwidth"))
compare("specification_sensitivity",c("outcome","term","specification"))
compare("baseline_balance",c("outcome")); compare("placebo_cutoffs",c("outcome","cutoff"))
compare("majority_group_rdd",c("outcome","group")); compare("pre_policy_nightlights",c("outcome"))
compare("joint_tests",c("outcome")); compare("descriptive_statistics",c("group","variable"))
compare("sample_coverage",c("state","caste_group","eligible"),0)
compare("integer_population_counts",c("tot_p","eligible"),0); compare("missingness_local_200",c("variable"),0)
compare("sample_flow",c("stage"),0)
for(y in c(PRIMARY,SECONDARY)) compare(paste0("full_model_",y),"term")
compare("pooled_rdrobust",c("outcome","method"),tolerance=1e-5)
# R returns side-specific package cluster counts. The historical Python table's
# aggregate clusters_package field is excluded; common h/b/input counts are checked.
independent<-lapply(names(main_models),function(y) {
  m<-main_models[[y]]; X<-m$X; w<-m$w; yy<-as.numeric(m$z[[y]])
  A<-solve(crossprod(X,w*X)); beta<-drop(A%*%crossprod(X,w*yy))
  scores<-X*(w*drop(yy-X%*%beta)); groups<-split(seq_len(nrow(X)),m$z$block_id)
  sums<-t(vapply(groups,function(i) colSums(scores[i,,drop=FALSE]),numeric(ncol(X))))
  C<-A%*%crossprod(sums)%*%A*m$g/(m$g-1)*(nrow(X)-1)/(nrow(X)-ncol(X))
  bd<-max(abs(beta-m$beta)); cd<-max(abs(C-m$vcov))
  stopifnot(bd<1e-8,cd<1e-7)
  data.frame(outcome=y,coefficient_max_difference=bd,covariance_max_difference=cd)
})
independent<-do.call(rbind,independent); json(independent,"R_independent_matrix_checks.json")
versions<-data.frame(package=c("R","haven","jsonlite","rdrobust"),version=c(as.character(getRversion()),
 vapply(c("haven","jsonlite","rdrobust"),function(x) as.character(packageVersion(x)),character(1))))
write.csv(versions,file.path(V,"R_package_versions.csv"),row.names=FALSE)
status<-list(r_executed=TRUE,source_rows=nrow(s),local_main_n=nrow(local),local_main_blocks=length(unique(local$block_id)),
 local_main_districts=length(unique(local$stdt)),main_models=8,primary_tests=4,secondary_tests=12,
 data_reconstruction_passed=TRUE,main_regression_comparison_passed=TRUE,
 independent_cr1_check_passed=TRUE,table_comparisons=comparisons,
 png_graphs=length(list.files(F,pattern="\\.png$")),svg_graphs=length(list.files(F,pattern="\\.svg$")),
 report_graph_assets=length(list.files(file.path(OUT,"report/assets"),pattern="\\.pdf$")))
stopifnot(status$png_graphs==18,status$svg_graphs==18,status$report_graph_assets==18)
json(status,"R_validation.json")
print(res[res$outcome %in% PRIMARY & res$bandwidth==100,],row.names=FALSE)
cat("R data reconstruction, all eight regressions and 18 graph designs passed.\n")
