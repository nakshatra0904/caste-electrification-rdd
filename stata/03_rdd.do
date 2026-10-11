version 16.0
use "$PROJECT/stata_generated/model_data.dta", clear
tempname heterogeneity joint
postfile `heterogeneity' str32 outcome str12 term int bandwidth str24 specification ///
    double estimate se p_value ci_low ci_high long n n_left n_right clusters ///
    using "$TAB/heterogeneity_results.dta", replace
postfile `joint' str32 outcome double joint_sc_st_p_value using "$TAB/joint_tests.dta", replace
foreach y in $PRIMARY $SECONDARY {
    foreach h in 50 100 150 200 {
        generate double kernel_weight=1-abs(running)/`h' if abs(running)<`h'
        quietly regress `y' $HET if sample_preferred==1 & abs(running)<`h' ///
            [aweight=kernel_weight], vce(cluster block_id)
        local n=e(N)
        local clusters=e(N_clust)
        local df=e(df_r)
        quietly count if e(sample) & eligible==0
        local nl=r(N)
        quietly count if e(sample) & eligible==1
        local nr=r(N)
        foreach term in D_sc10 D_st10 {
            local b=_b[`term']
            local s=_se[`term']
            local p=2*ttail(`df',abs(`b'/`s'))
            local lower=`b'-invttail(`df',.025)*`s'
            local upper=`b'+invttail(`df',.025)*`s'
            post `heterogeneity' ("`y'") ("`term'") (`h') ("main") ///
                (`b') (`s') (`p') (`lower') (`upper') (`n') (`nl') (`nr') (`clusters')
        }
        if `h'==100 {
            estimates save "$PROJECT/stata_generated/model_`y'.ster", replace
            test D_sc10 D_st10
            post `joint' ("`y'") (r(p))
            * Full output is retained in the master log.
            estimates replay
            tempname coefficients
            postfile `coefficients' str80 term double estimate se p_value ci_low ci_high ///
                using "$TAB/full_model_`y'.dta", replace
            local names : colnames e(b)
            foreach coefficient of local names {
                local cb=_b[`coefficient']
                local cs=_se[`coefficient']
                if `cs'>0 {
                    post `coefficients' ("`coefficient'") (`cb') (`cs') ///
                        (2*ttail(`df',abs(`cb'/`cs'))) ///
                        (`cb'-invttail(`df',.025)*`cs') (`cb'+invttail(`df',.025)*`cs')
                }
            }
            postclose `coefficients'
            preserve
            use "$TAB/full_model_`y'.dta", clear
            export delimited using "$TAB/full_model_`y'.csv", replace
            restore
        }
        drop kernel_weight
    }
}
postclose `heterogeneity'
postclose `joint'
preserve
use "$TAB/heterogeneity_results.dta", clear
keep if bandwidth==100
generate str12 family="secondary"
replace family="primary" if inlist(outcome,"vd_pwr_d_dom_11","hpca11_msl_elec")
bysort family (p_value): generate double p_holm=min(1,(_N-_n+1)*p_value)
by family: replace p_holm=max(p_holm,p_holm[_n-1]) if _n>1
keep outcome term bandwidth p_holm
tempfile adjusted
save `adjusted'
use "$TAB/heterogeneity_results.dta", clear
merge 1:1 outcome term bandwidth using `adjusted', nogen
save "$TAB/heterogeneity_results.dta", replace
export delimited using "$TAB/heterogeneity_results.csv", replace
restore
preserve
use "$TAB/joint_tests.dta", clear
export delimited using "$TAB/joint_tests.csv", replace
restore

* Pooled benchmark using the official rdrobust package.
* Install once if missing. Core interacted regressions above use built-in Stata.
capture which rdrobust
if _rc {
    capture noisily ssc install rdrobust
}
capture which rdrobust
if _rc {
    display as error "rdrobust unavailable: pooled RBC estimates skipped; install rdrobust and rerun."
}
else {
    which rdrobust
    quietly tabulate st_code, generate(state_fe)
    drop state_fe1
    tempname pooled
    postfile `pooled' str32 outcome str12 method double tau_conventional tau_bias_corrected ///
        se_robust p_robust ci_low_robust ci_high_robust h_left h_right b_left b_right ///
        long n_left n_right clusters clusters_input clusters_bias using "$TAB/pooled_rdrobust.dta", replace
    foreach y in $PRIMARY $PRODUCTIVE {
        foreach method in mserd fixed_100 {
            local bandwidth_options "bwselect(mserd)"
            if "`method'"=="fixed_100" local bandwidth_options "h(100) b(150)"
            rdrobust `y' running if sample_preferred==1 & local_200==1, c(0) ///
                p(1) q(2) kernel(triangular) covs(state_fe*) masspoints(adjust) ///
                vce(cluster block_id) `bandwidth_options' all
            tempvar tag_input tag_h tag_b
            local clean "sample_preferred==1 & local_200==1 & !missing(`y',running,block_id,st_code)"
            egen byte `tag_input'=tag(block_id) if `clean'
            quietly count if `tag_input'==1
            local gi=r(N)
            egen byte `tag_h'=tag(block_id) if `clean' & ///
                ((running<0 & abs(running)<e(h_l)) | (running>=0 & abs(running)<e(h_r)))
            quietly count if `tag_h'==1
            local gh=r(N)
            egen byte `tag_b'=tag(block_id) if `clean' & ///
                ((running<0 & abs(running)<e(b_l)) | (running>=0 & abs(running)<e(b_r)))
            quietly count if `tag_b'==1
            local gb=r(N)
            post `pooled' ("`y'") ("`method'") (e(tau_cl)) (e(tau_bc)) ///
                (e(se_tau_rb)) (e(pv_rb)) (e(ci_l_rb)) (e(ci_r_rb)) ///
                (e(h_l)) (e(h_r)) (e(b_l)) (e(b_r)) (e(N_h_l)) (e(N_h_r)) (`gh') (`gi') (`gb')
            drop `tag_input' `tag_h' `tag_b'
        }
    }
    postclose `pooled'
    drop state_fe*
    preserve
    use "$TAB/pooled_rdrobust.dta", clear
    export delimited using "$TAB/pooled_rdrobust.csv", replace
    restore
}
