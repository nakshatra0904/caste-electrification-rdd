version 16.0
use "$PROJECT/stata_generated/model_data.dta", clear
generate double kernel_weight=1-abs(running)/100 if abs(running)<100
tempname sensitivity
postfile `sensitivity' str32 outcome str12 term str24 specification double estimate se p_value ///
    ci_low ci_high long n clusters using "$TAB/specification_sensitivity.dta", replace
foreach y in $PRIMARY {
    foreach spec in main no_post_lights_filter district_cluster donut_5 baseline_adjusted state_specific_rd {
        local cond "sample_preferred==1 & abs(running)<100"
        local cluster "block_id"
        local extra ""
        if "`spec'"=="no_post_lights_filter" local cond "sample_no_post_filter==1 & abs(running)<100"
        if "`spec'"=="district_cluster" local cluster "stdt"
        if "`spec'"=="donut_5" local cond "`cond' & abs(running)>5"
        if "`spec'"=="baseline_adjusted" {
            if "`y'"=="vd_pwr_d_dom_11" local extra "vd_pwr_d_dom_01"
            if "`y'"=="hpca11_msl_elec" local extra "hpca01_msl_elec"
        }
        if "`spec'"=="state_specific_rd" local extra "i.st_code#c.eligible i.st_code#c.running i.st_code#c.D_x"
        quietly regress `y' $HET `extra' if `cond' [aw=kernel_weight], vce(cluster `cluster')
        foreach term in D_sc10 D_st10 {
            local b=_b[`term']
            local s=_se[`term']
            local p=2*ttail(e(df_r),abs(`b'/`s'))
            local l=`b'-invttail(e(df_r),.025)*`s'
            local u=`b'+invttail(e(df_r),.025)*`s'
            post `sensitivity' ("`y'") ("`term'") ("`spec'") ///
                (`b') (`s') (`p') (`l') (`u') (e(N)) (e(N_clust))
        }
    }
}
postclose `sensitivity'
tempname balance
postfile `balance' str32 outcome double estimate se p_value ci_low ci_high long n ///
    using "$TAB/baseline_balance.dta", replace
foreach y in pct_sc_01 pct_st_01 hpca01_msl_elec vd_pwr_d_dom_01 lit_p_01 lights_max2001 {
    quietly regress `y' $SIMPLE if sample_preferred==1 & abs(running)<100 ///
        [aw=kernel_weight], vce(cluster block_id)
    local b=_b[eligible]
    local s=_se[eligible]
    post `balance' ("`y'") (`b') (`s') (2*ttail(e(df_r),abs(`b'/`s'))) ///
        (`b'-invttail(e(df_r),.025)*`s') (`b'+invttail(e(df_r),.025)*`s') (e(N))
}
postclose `balance'
tempname subgroup
postfile `subgroup' str32 outcome str20 group str48 status double estimate se p_value ///
    ci_low ci_high long n using "$TAB/majority_group_rdd.dta", replace
foreach y in $PRIMARY {
    foreach group in "Other villages" "SC majority" "ST majority" {
        local cond `"sample_preferred==1 & abs(running)<100 & caste_group=="`group'" & !missing(`y')"'
        local adequate=1
        quietly count if `cond'
        local n=r(N)
        foreach side in 0 1 {
            quietly count if `cond' & eligible==`side'
            if r(N)<50 local adequate=0
            preserve
            keep if `cond' & eligible==`side'
            quietly bysort block_id: keep if _n==1
            quietly count
            if r(N)<20 local adequate=0
            restore
        }
        if `adequate'==0 {
            post `subgroup' ("`y'") ("`group'") ("Insufficient observations/clusters") ///
                (.) (.) (.) (.) (.) (`n')
        }
        else {
            quietly regress `y' $SIMPLE if `cond' [aw=kernel_weight], vce(cluster block_id)
            local b=_b[eligible]
            local s=_se[eligible]
            post `subgroup' ("`y'") ("`group'") ("Estimated") (`b') (`s') ///
                (2*ttail(e(df_r),abs(`b'/`s'))) (`b'-invttail(e(df_r),.025)*`s') ///
                (`b'+invttail(e(df_r),.025)*`s') (e(N))
        }
    }
}
postclose `subgroup'
tempname prelights
postfile `prelights' int year double estimate se p_value ci_low ci_high using "$TAB/pre_policy_nightlights.dta", replace
forvalues year=1998/2004 {
    quietly regress lights_max`year' $SIMPLE if sample_preferred==1 & abs(running)<100 ///
        [aw=kernel_weight], vce(cluster block_id)
    local b=_b[eligible]
    local s=_se[eligible]
    post `prelights' (`year') (`b') (`s') (2*ttail(e(df_r),abs(`b'/`s'))) ///
        (`b'-invttail(e(df_r),.025)*`s') (`b'+invttail(e(df_r),.025)*`s')
}
postclose `prelights'
tempname placebo
postfile `placebo' str32 outcome double cutoff estimate se p_value ci_low ci_high ///
    using "$TAB/placebo_cutoffs.dta", replace
foreach cutoff in 149.5 449.5 {
    generate double placebo_x=tot_p-`cutoff'
    generate byte placebo_D=tot_p>=`cutoff'
    generate double placebo_Dx=placebo_D*placebo_x
    generate double placebo_weight=1-abs(placebo_x)/50 if abs(placebo_x)<50
    foreach y in $PRIMARY {
        quietly regress `y' placebo_D placebo_x placebo_Dx i.st_code ///
            if sample_preferred==1 & abs(placebo_x)<50 [aw=placebo_weight], vce(cluster block_id)
        local b=_b[placebo_D]
        local s=_se[placebo_D]
        post `placebo' ("`y'") (`cutoff') (`b') (`s') (2*ttail(e(df_r),abs(`b'/`s'))) ///
            (`b'-invttail(e(df_r),.025)*`s') (`b'+invttail(e(df_r),.025)*`s')
    }
    drop placebo_x placebo_D placebo_Dx placebo_weight
}
postclose `placebo'
foreach file in specification_sensitivity baseline_balance majority_group_rdd pre_policy_nightlights placebo_cutoffs {
    preserve
    use "$TAB/`file'.dta", clear
    if "`file'"=="baseline_balance" {
        sort p_value
        generate double p_holm=min(1,(_N-_n+1)*p_value)
        replace p_holm=max(p_holm,p_holm[_n-1]) if _n>1
        save "$TAB/`file'.dta", replace
    }
    export delimited using "$TAB/`file'.csv", replace
    restore
}
