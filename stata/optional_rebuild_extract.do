version 16.0
clear all
set more off
/* Optional rebuild of data/source_extract.dta from the full original archive.
   This is unnecessary for running 00_master.do: the verified extract is shipped.
   Download file 7887967 from DOI 10.7910/DVN/APWICK, then put it under raw/.
   Full source size: 2,294,890,843 bytes. Check the MD5 in source_manifest.json.
   Do not upload raw/ to GitHub. This script does not install software.
*/
global PROJECT "`c(pwd)'"
local columns "pca01_id vd01_id pca11_id vd11_id state st_code district stdt bk_code block village tot_p tot_p11 tot_f tot_f11 no_hh pct_sc_01 pct_st_01 lit_p_01 pct_06_01 work_p_01 work_f_01 work_p_11 work_f_11 work_pooled_ot_p_01 work_pooled_ot_f_01 work_pooled_ot_p_11 work_pooled_ot_f_11 hpca01_msl_elec hpca11_msl_elec vd_pwr_d_dom_01 vd_pwr_d_dom_11 vd_pwr_d_any_01 vd_pwr_d_any_11 vdp_pwr_h_dom_avg_11 vplan4 corr_state sample sample_h sing_h pop_non_zero pop_mismatch20 lights_max2001_hat lights_max2011_hat"
forvalues year=1998/2013 {
    local columns "`columns' lights_max`year'"
}
local columns "`columns' vdp_pwr_d_com_11 vd_pwr_d_all_11 vdp_pwr_h_com_avg_11"
use `columns' using "$PROJECT/raw/panel_dataset_full.dta", clear
capture mkdir "$PROJECT/stata_generated"
capture mkdir "$PROJECT/stata_generated/tables"
tempname flow
postfile `flow' str32 stage long records using "$PROJECT/stata_generated/tables/sample_flow.dta", replace
quietly count
post `flow' ("source_records") (r(N))
local stages "first_wave valid_geography nightlights_match habitation_match single_habitation positive_population non_kerala population_under_1000"
forvalues step=1/8 {
    local stage : word `step' of `stages'
    if `step'==1 local restriction "vplan4<11 & !missing(vplan4)"
    if `step'==2 local restriction "corr_state==1"
    if `step'==3 local restriction "sample==1"
    if `step'==4 local restriction "sample_h==1"
    if `step'==5 local restriction "sing_h==1"
    if `step'==6 local restriction "pop_non_zero==1"
    if `step'==7 local restriction "st_code!=32"
    if `step'==8 local restriction "tot_p>0 & tot_p<1000 & !missing(tot_p)"
    keep if `restriction'
    quietly count
    post `flow' ("`stage'") (r(N))
}
quietly count if pop_mismatch20==0 & abs(lights_max2011_hat-lights_max2001_hat)<20
post `flow' ("preferred_sample") (r(N))
quietly count if pop_mismatch20==0 & abs(lights_max2011_hat-lights_max2001_hat)<20 & abs(tot_p-299.5)<200
post `flow' ("preferred_local_200") (r(N))
quietly count if pop_mismatch20==0 & abs(lights_max2011_hat-lights_max2001_hat)<20 & abs(tot_p-299.5)<100
post `flow' ("preferred_local_100") (r(N))
postclose `flow'
isid pca01_id
save "$PROJECT/data/source_extract.dta", replace
export delimited using "$PROJECT/data/source_extract.csv", replace
use "$PROJECT/stata_generated/tables/sample_flow.dta", clear
export delimited using "$PROJECT/stata_generated/tables/sample_flow.csv", replace
