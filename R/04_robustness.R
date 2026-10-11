specifications<-list(main=list(),no_post_lights_filter=list(sample="sample_no_post_filter"),
 district_cluster=list(cluster="stdt"),donut_5=list(donut=5),baseline_adjusted=list(baseline=TRUE),state_specific_rd=list(state_slopes=TRUE))
sens<-list()
for(y in PRIMARY) for(spec in names(specifications)) {
  m<-do.call(fit,c(list(y=y,h=100),specifications[[spec]]))
  for(term in c("D_sc10","D_st10")) sens[[length(sens)+1]]<-result_row(m,y,term,100,spec)
}
sens<-do.call(rbind,sens); csv(sens,"specification_sensitivity")
balance<-list()
for(y in c("pct_sc_01","pct_st_01","hpca01_msl_elec","vd_pwr_d_dom_01","lit_p_01","lights_max2001"))
 balance[[length(balance)+1]]<-result_row(fit(y,heter=FALSE),y,"eligible",100,"pre_policy_balance")
bal<-do.call(rbind,balance); bal$p_holm<-p.adjust(bal$p_value,"holm"); csv(bal,"baseline_balance")
placebo<-list()
for(cutoff in c(149.5,449.5)) for(y in PRIMARY) {
  r<-result_row(fit(y,50,heter=FALSE,cutoff=cutoff),y,"eligible",50,"placebo_cutoff"); r$cutoff<-cutoff
  placebo[[length(placebo)+1]]<-r
}
csv(do.call(rbind,placebo),"placebo_cutoffs")
subgroups<-list()
for(y in PRIMARY) for(category in CAT) {
  zz<-local[local$caste_group==category & complete.cases(local[,c(y,"block_id")]),]
  sides<-lapply(0:1,function(side) zz[zz$eligible==side,])
  if(min(vapply(sides,nrow,integer(1)))<50 || min(vapply(sides,function(z) length(unique(z$block_id)),integer(1)))<20)
    stop("Insufficient subgroup observations/clusters: ",y," / ",category)
  r<-result_row(fit(y,heter=FALSE,subgroup=category),y,"eligible",100,"majority_group")
  r$group<-category; r$status<-"Estimated"; subgroups[[length(subgroups)+1]]<-r
}
sg<-do.call(rbind,subgroups); csv(sg,"majority_group_rdd")
pretrends<-do.call(rbind,lapply(1998:2004,function(year) {
 y<-paste0("lights_max",year); result_row(fit(y,heter=FALSE),y,"eligible",100,"pre_policy_nightlights")
}))
csv(pretrends,"pre_policy_nightlights")
