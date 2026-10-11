version 16.0
/* source_extract.dta contains REAL records extracted from the authors' full
   public archive file, not simulated observations. Extraction and source
   checksum verification are documented in docs/source_manifest.json.
   First-wave, valid-geography, matched single-habitation villages with
   population 1-999 were selected before this compact source extract was saved.
*/
use "$PROJECT/data/source_extract.dta", clear
isid pca01_id
assert vplan4<11 & !missing(vplan4)
assert corr_state==1 & sample==1 & sample_h==1 & sing_h==1
assert pop_non_zero==1 & st_code!=32
assert tot_p>0 & tot_p<1000 & !missing(tot_p)
assert tot_p==floor(tot_p)
foreach v in pct_sc_01 pct_st_01 hpca01_msl_elec hpca11_msl_elec ///
             work_p_01 work_f_01 work_p_11 work_f_11 ///
             work_pooled_ot_p_01 work_pooled_ot_f_01 ///
             work_pooled_ot_p_11 work_pooled_ot_f_11 {
    assert inrange(`v',0,1) if !missing(`v')
}
assert pct_sc_01+pct_st_01<=1.000001 if !missing(pct_sc_01,pct_st_01)
foreach v in vd_pwr_d_dom_01 vd_pwr_d_dom_11 vd_pwr_d_any_01 vd_pwr_d_any_11 vdp_pwr_d_com_11 vd_pwr_d_all_11 {
    assert inlist(`v',0,1) if !missing(`v')
}
generate double running=tot_p-299.5
generate byte eligible=tot_p>=300
generate double sc10=pct_sc_01/.1
generate double st10=pct_st_01/.1
generate byte sc_majority=pct_sc_01>=.5 if !missing(pct_sc_01)
generate byte st_majority=pct_st_01>=.5 if !missing(pct_st_01)
generate str20 caste_group="Other villages"
replace caste_group="SC majority" if sc_majority==1
replace caste_group="ST majority" if st_majority==1
replace caste_group="Missing composition" if missing(pct_sc_01,pct_st_01)
egen long block_id=group(stdt bk_code)
generate double lights_change_abs=abs(lights_max2011_hat-lights_max2001_hat)
generate byte sample_no_post_filter=pop_mismatch20==0
generate byte sample_preferred=pop_mismatch20==0 & lights_change_abs<20
generate byte local_200=abs(running)<200
generate byte local_100=abs(running)<100
generate double lighting_change=hpca11_msl_elec-hpca01_msl_elec
generate double access_adoption_gap=vd_pwr_d_dom_11-hpca11_msl_elec
label variable running "2001 population minus 299.5 (persons)"
label variable sc10 "2001 SC share in units of 10 percentage points"
label variable st10 "2001 ST share in units of 10 percentage points"
label variable eligible "RGGVY eligibility: Census population >=300"
label variable access_adoption_gap "Village domestic availability minus HH lighting share, 2011"
save "$PROJECT/stata_generated/analysis.dta", replace
export delimited using "$PROJECT/stata_generated/analysis.csv", replace

* Both slope and treatment-effect heterogeneity must be included.
generate double D_x=eligible*running
foreach caste in sc10 st10 {
    generate double D_`caste'=eligible*`caste'
    generate double x_`caste'=running*`caste'
    generate double D_x_`caste'=eligible*running*`caste'
}
global HET "eligible running D_x sc10 D_sc10 x_sc10 D_x_sc10 st10 D_st10 x_st10 D_x_st10 i.st_code"
global SIMPLE "eligible running D_x i.st_code"
global PRIMARY "vd_pwr_d_dom_11 hpca11_msl_elec"
global SECONDARY "work_p_11 work_f_11 work_pooled_ot_p_11 work_pooled_ot_f_11 vdp_pwr_d_com_11 vd_pwr_d_all_11"
global PRODUCTIVE "vdp_pwr_d_com_11 vd_pwr_d_all_11"
save "$PROJECT/stata_generated/model_data.dta", replace
