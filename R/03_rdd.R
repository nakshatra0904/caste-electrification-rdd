results<-list(); main_models<-list(); joint<-list()
for (y in c(PRIMARY,SECONDARY)) for (h in c(50,100,150,200)) {
  m<-fit(y,h)
  for (term in c("D_sc10","D_st10")) results[[length(results)+1]]<-result_row(m,y,term,h)
  if(h==100) {
    main_models[[y]]<-m; csv(full_table(m),paste0("full_model_",y))
    joint[[length(joint)+1]]<-data.frame(outcome=y,joint_sc_st_p_value=joint_p(m))
    writeLines(c(paste("Outcome:",y),paste("Villages:",nrow(m$z)),paste("Blocks:",m$g),
                 capture.output(print(full_table(m),row.names=FALSE))),file.path(V,paste0("model_",y,".txt")))
  }
}
res<-do.call(rbind,results); res$p_holm<-NA_real_
for (family in list(PRIMARY,SECONDARY)) {
  selected<-res$outcome %in% family & res$bandwidth==100
  res$p_holm[selected]<-p.adjust(res$p_value[selected],method="holm")
}
csv(res,"heterogeneity_results"); csv(do.call(rbind,joint),"joint_tests")
robust<-list(); rd_warnings<-list()
for (y in c(PRIMARY,PRODUCTIVE)) {
  z<-d[which(d$sample_preferred==1 & d$local_200==1),]
  z<-z[complete.cases(z[,c(y,"running","block_id","st_code")]),]
  covs<-state_matrix(z)
  for(method in c("mserd","fixed_100")) {
    warnings<-character()
    call<-list(y=as.numeric(z[[y]]),x=z$running,c=0,covs=covs,p=1,q=2,kernel="tri",vce="cr1",
               cluster=z$block_id,masspoints="adjust",stdvars=TRUE)
    if(method=="fixed_100") call<-c(call,list(h=100,b=150))
    rr<-withCallingHandlers(do.call(rdrobust::rdrobust,call),warning=function(w) {
      warnings<<-c(warnings,conditionMessage(w)); invokeRestart("muffleWarning")
    })
    hl<-rr$bws[1,1]; hr<-rr$bws[1,2]; bl<-rr$bws[2,1]; br<-rr$bws[2,2]
    in_h<-(z$running<0 & abs(z$running)<hl)|(z$running>=0 & abs(z$running)<hr)
    in_b<-(z$running<0 & abs(z$running)<bl)|(z$running>=0 & abs(z$running)<br)
    robust[[length(robust)+1]]<-data.frame(outcome=y,method=method,tau_conventional=rr$coef[1,1],tau_bias_corrected=rr$coef[3,1],
      se_robust=rr$se[3,1],p_robust=rr$pv[3,1],ci_low_robust=rr$ci[3,1],ci_high_robust=rr$ci[3,2],
      h_left=hl,h_right=hr,b_left=bl,b_right=br,n_left=rr$N_h[1],n_right=rr$N_h[2],
      clusters=length(unique(z$block_id[in_h])),clusters_input=length(unique(z$block_id)),
      clusters_bias=length(unique(z$block_id[in_b])),
      clusters_package_left=rr$n_clust[1],clusters_package_right=rr$n_clust[2])
    writeLines(c(capture.output(summary(rr)),"",warnings),file.path(V,paste0("rdrobust_",y,"_",method,".txt")))
    rd_warnings[[paste(y,method,sep="/")]]<-warnings
  }
}
rb<-do.call(rbind,robust); csv(rb,"pooled_rdrobust"); json(rd_warnings,"rdrobust_warnings.json")
