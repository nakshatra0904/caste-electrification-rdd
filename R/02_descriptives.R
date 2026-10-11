desc<-list()
for (group in c("All villages",CAT)) {
  q<-if(group=="All villages") local else local[local$caste_group==group,]
  for (y in c("tot_p","pct_sc_01","pct_st_01","hpca01_msl_elec","hpca11_msl_elec","vd_pwr_d_dom_01","vd_pwr_d_dom_11",SECONDARY)) {
    values<-as.numeric(q[[y]]); good<-values[!is.na(values)]
    percentiles<-quantile(good,c(.25,.5,.75),type=2,names=FALSE)
    desc[[length(desc)+1]]<-data.frame(group=group,variable=y,label=label(y),n=length(good),missing_n=sum(is.na(values)),
       mean=mean(good),sd=sd(good),p25=percentiles[1],median=percentiles[2],p75=percentiles[3])
  }
}
desc<-do.call(rbind,desc); csv(desc,"descriptive_statistics")
groups<-split(local,interaction(local$state,local$caste_group,local$eligible,drop=TRUE))
coverage<-do.call(rbind,lapply(groups,function(z) data.frame(state=z$state[1],caste_group=z$caste_group[1],eligible=z$eligible[1],
 n=nrow(z),blocks=length(unique(z$block_id)),districts=length(unique(z$stdt)))))
csv(coverage,"sample_coverage")
wide<-d[which(d$sample_preferred==1 & d$local_200==1),]
csv(data.frame(variable=names(d),missing_n=colSums(is.na(wide))),"missingness_local_200")
integer<-aggregate(rep(1,nrow(local)),local[,c("tot_p","eligible")],sum)
names(integer)[3]<-"n"; csv(integer,"integer_population_counts")
