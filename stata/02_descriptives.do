version 16.0
use "$PROJECT/stata_generated/model_data.dta", clear
tempname descriptive
postfile `descriptive' str20 group str32 variable long n missing_n ///
    double mean sd p25 median p75 using "$TAB/descriptive_statistics.dta", replace
foreach group in "All villages" "Other villages" "SC majority" "ST majority" {
    foreach y in tot_p pct_sc_01 pct_st_01 hpca01_msl_elec hpca11_msl_elec ///
                 vd_pwr_d_dom_01 vd_pwr_d_dom_11 $SECONDARY {
        local cond "sample_preferred==1 & local_100==1"
        if "`group'"!="All villages" local cond `"`cond' & caste_group=="`group'""'
        quietly count if `cond' & missing(`y')
        local missing_n=r(N)
        quietly summarize `y' if `cond', detail
        post `descriptive' ("`group'") ("`y'") (r(N)) (`missing_n') ///
            (r(mean)) (r(sd)) (r(p25)) (r(p50)) (r(p75))
    }
}
postclose `descriptive'
preserve
use "$TAB/descriptive_statistics.dta", clear
export delimited using "$TAB/descriptive_statistics.csv", replace
restore
preserve
keep if sample_preferred==1 & local_100==1
bysort state caste_group eligible block_id: generate byte block_tag=_n==1
bysort state caste_group eligible stdt: generate byte district_tag=_n==1
generate long n=1
collapse (sum) n blocks=block_tag districts=district_tag, by(state caste_group eligible)
export delimited using "$TAB/sample_coverage.csv", replace
restore
preserve
keep if sample_preferred==1 & local_100==1
contract tot_p eligible, freq(n)
export delimited using "$TAB/integer_population_counts.csv", replace
restore
misstable summarize if sample_preferred==1 & local_200==1
tempname missingness
postfile `missingness' str40 variable long missing_n using "$TAB/missingness_local_200.dta", replace
foreach v of varlist _all {
    quietly count if sample_preferred==1 & local_200==1 & missing(`v')
    post `missingness' ("`v'") (r(N))
}
postclose `missingness'
preserve
use "$TAB/missingness_local_200.dta", clear
export delimited using "$TAB/missingness_local_200.csv", replace
restore
