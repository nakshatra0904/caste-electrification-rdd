s <- as.data.frame(haven::read_dta(file.path(PROJECT,"data/source_extract.dta")))
stopifnot(nrow(s)==55320,!anyDuplicated(s$pca01_id),!anyNA(s$pca01_id),
 all(s$vplan4<11),all(s$corr_state==1),all(s$sample==1),all(s$sample_h==1),
 all(s$sing_h==1),all(s$pop_non_zero==1),all(s$st_code!=32),
 all(s$tot_p>0 & s$tot_p<1000),all(s$tot_p==floor(s$tot_p)))
shares <- c("pct_sc_01","pct_st_01","hpca01_msl_elec","hpca11_msl_elec","work_p_01","work_f_01","work_p_11","work_f_11",
 "work_pooled_ot_p_01","work_pooled_ot_f_01","work_pooled_ot_p_11","work_pooled_ot_f_11")
for (col in shares) stopifnot(all(is.na(s[[col]]) | (s[[col]]>=0 & s[[col]]<=1)))
stopifnot(all(s$pct_sc_01+s$pct_st_01<=1.000001,na.rm=TRUE))
for (col in c("vd_pwr_d_dom_01","vd_pwr_d_dom_11","vd_pwr_d_any_01","vd_pwr_d_any_11","vdp_pwr_d_com_11","vd_pwr_d_all_11"))
 stopifnot(all(is.na(s[[col]]) | s[[col]] %in% c(0,1)))
d <- s
d$running <- d$tot_p-299.5; d$eligible <- as.integer(d$tot_p>=300)
d$sc10 <- as.numeric(d$pct_sc_01)/.1; d$st10 <- as.numeric(d$pct_st_01)/.1
d$sc_majority <- as.integer(d$pct_sc_01>=.5); d$st_majority <- as.integer(d$pct_st_01>=.5)
d$caste_group <- ifelse(d$st_majority==1,"ST majority",ifelse(d$sc_majority==1,"SC majority","Other villages"))
d$caste_group[is.na(d$pct_sc_01)|is.na(d$pct_st_01)] <- "Missing composition"
pairs <- unique(d[,c("stdt","bk_code")]); pairs<-pairs[order(pairs$stdt,pairs$bk_code),]
d$block_id <- match(paste(d$stdt,d$bk_code,sep=":"),paste(pairs$stdt,pairs$bk_code,sep=":"))
d$lights_change_abs <- abs(as.numeric(d$lights_max2011_hat)-as.numeric(d$lights_max2001_hat))
d$sample_no_post_filter <- as.integer(!is.na(d$pop_mismatch20)&d$pop_mismatch20==0)
d$sample_preferred <- as.integer(d$sample_no_post_filter==1 & !is.na(d$lights_change_abs) & d$lights_change_abs<20)
d$local_200<-as.integer(abs(d$running)<200); d$local_100<-as.integer(abs(d$running)<100)
d$lighting_change<-as.numeric(d$hpca11_msl_elec)-as.numeric(d$hpca01_msl_elec)
d$access_adoption_gap<-as.numeric(d$vd_pwr_d_dom_11)-as.numeric(d$hpca11_msl_elec)
local<-d[which(d$sample_preferred==1 & d$local_100==1),]
stopifnot(nrow(local)==12533,length(unique(local$block_id))==1342,length(unique(local$stdt))==129)
saveRDS(d,file.path(OUT,"data/analysis.rds"))
haven::write_dta(d,file.path(OUT,"data/analysis.dta"),version=14)
write.csv(d,file.path(OUT,"data/analysis.csv"),row.names=FALSE,na="")
flow<-read.csv(file.path(PROJECT,"tables/sample_flow.csv"))
flow$records[flow$stage=="preferred_sample"]<-sum(d$sample_preferred)
flow$records[flow$stage=="preferred_local_200"]<-sum(d$sample_preferred*d$local_200)
flow$records[flow$stage=="preferred_local_100"]<-nrow(local)
csv(flow,"sample_flow")
