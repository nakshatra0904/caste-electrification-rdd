version 16.0
use "$PROJECT/stata_generated/model_data.dta", clear
global SOURCE "Source: Burlig-Preonas public RGGVY archive, Census 2001/2011."
graph set window fontface "Arial"

* 01: Discrete population frequencies, not a continuous-density diagnostic.
preserve
keep if sample_preferred==1 & local_200==1
contract tot_p, freq(n)
twoway bar n tot_p, barwidth(1) xline(299.5, lpattern(dash)) ///
    title("Population around the eligibility threshold") ///
    xtitle("2001 population (persons)") ytitle("Number of villages") ///
    note("$SOURCE Population 100-499; integer counts.")
graph export "$FIG/01_population_frequencies.png", width(1800) replace
restore

* 02: Pre-policy caste composition.
preserve
keep if sample_preferred==1 & local_100==1
generate double sc_pct=100*pct_sc_01
generate double st_pct=100*pct_st_01
histogram sc_pct, width(5) start(0) frequency title("Scheduled Caste share") ///
    xtitle("2001 population share (%)") ytitle("Villages") name(sc_hist, replace)
histogram st_pct, width(5) start(0) frequency title("Scheduled Tribe share") ///
    xtitle("2001 population share (%)") ytitle("Villages") name(st_hist, replace)
graph combine sc_hist st_hist, cols(2) note("$SOURCE Population 200-399.")
graph export "$FIG/02_baseline_caste_distributions.png", width(2000) replace
restore

* Local-linear display helper: unadjusted fitted lines; formal models use FEs.
capture program drop rd_display
program define rd_display
    args y stem heading graphname
    preserve
    keep if sample_preferred==1 & local_200==1 & !missing(`y')
    generate double weight=1-abs(running)/100 if abs(running)<100
    quietly regress `y' running if eligible==0 & abs(running)<100 [aw=weight]
    local left_intercept=100*_b[_cons]
    local left_slope=100*_b[running]
    quietly regress `y' running if eligible==1 & abs(running)<100 [aw=weight]
    local right_intercept=100*_b[_cons]
    local right_slope=100*_b[running]
    generate double display_y=100*`y'
    generate double bin=floor(running/20)*20+10
    collapse (mean) display_y population=tot_p, by(eligible bin)
    twoway (scatter display_y population if eligible==0, mcolor("0 114 178") msymbol(O)) ///
           (scatter display_y population if eligible==1, mcolor("213 94 0") msymbol(S)) ///
           (function y=`left_intercept'+`left_slope'*(x-299.5), range(200 299.5) lcolor("0 114 178") lwidth(medthick)) ///
           (function y=`right_intercept'+`right_slope'*(x-299.5), range(299.5 399) lcolor("213 94 0") lwidth(medthick)), ///
        xline(299.5,lpattern(dash)) title("`heading'") ///
        xtitle("2001 population (persons)") ytitle("Percent") xlabel(100(100)500) ///
        legend(order(1 "Below threshold" 2 "Eligible")) ///
        note("$SOURCE Dots at mean population in each 20-person bin." ///
             "Unadjusted triangular fits, h=100; lines extended to the cutoff.", size(small)) ///
        name(`graphname', replace)
    if "`stem'"!="" graph export "$FIG/`stem'.png", width(1800) replace
    restore
end
rd_display pct_sc_01 "" "SC population share, 2001" sc_balance
rd_display pct_st_01 "" "ST population share, 2001" st_balance
graph combine sc_balance st_balance, cols(2)
graph export "$FIG/03_caste_composition_balance.png", width(2200) replace
rd_display vd_pwr_d_dom_11 "04_rd_vd_pwr_d_dom_11" "Village domestic electricity, 2011" domestic_rd
rd_display hpca11_msl_elec "05_rd_hpca11_msl_elec" "Household electric lighting, 2011" lighting_rd
rd_display hpca01_msl_elec "06_rd_hpca01_msl_elec" "Household electric lighting, 2001" baseline_rd

* 07: Descriptive access/adoption by group and year.
preserve
keep if sample_preferred==1 & local_100==1
foreach y in vd_pwr_d_dom_01 vd_pwr_d_dom_11 hpca01_msl_elec hpca11_msl_elec {
    replace `y'=100*`y'
}
graph bar (mean) vd_pwr_d_dom_01 vd_pwr_d_dom_11, over(caste_group, label(labsize(small))) ///
    title("Village domestic availability") ytitle("Percent") ///
    legend(order(1 "2001" 2 "2011")) name(access_group, replace)
graph bar (mean) hpca01_msl_elec hpca11_msl_elec, over(caste_group, label(labsize(small))) ///
    title("Household electric lighting") ytitle("Percent") ///
    legend(order(1 "2001" 2 "2011")) name(adoption_group, replace)
graph combine access_group adoption_group, cols(2) ///
    note("$SOURCE Population 200-399. Group means are not causal effects.")
graph export "$FIG/07_access_and_adoption_by_group.png", width(2200) replace
restore

capture program drop effect_forest
program define effect_forest
    args family stem heading
    preserve
    use "$TAB/heterogeneity_results.dta", clear
    keep if bandwidth==100
    if "`family'"=="primary" keep if inlist(outcome,"vd_pwr_d_dom_11","hpca11_msl_elec")
    if "`family'"=="employment" keep if inlist(outcome,"work_p_11","work_f_11","work_pooled_ot_p_11","work_pooled_ot_f_11")
    if "`family'"=="productive" keep if inlist(outcome,"vdp_pwr_d_com_11","vd_pwr_d_all_11")
    generate str80 labeltext=outcome+" / "+subinstr(term,"D_","",.)
    replace labeltext="Domestic availability / "+subinstr(term,"D_","",.) if outcome=="vd_pwr_d_dom_11"
    replace labeltext="Household lighting / "+subinstr(term,"D_","",.) if outcome=="hpca11_msl_elec"
    replace labeltext="All work / "+subinstr(term,"D_","",.) if outcome=="work_p_11"
    replace labeltext="Female work / "+subinstr(term,"D_","",.) if outcome=="work_f_11"
    replace labeltext="Other work / "+subinstr(term,"D_","",.) if outcome=="work_pooled_ot_p_11"
    replace labeltext="Female other work / "+subinstr(term,"D_","",.) if outcome=="work_pooled_ot_f_11"
    replace labeltext="Commercial availability / "+subinstr(term,"D_","",.) if outcome=="vdp_pwr_d_com_11"
    replace labeltext="All-sector availability / "+subinstr(term,"D_","",.) if outcome=="vd_pwr_d_all_11"
    encode labeltext, generate(plot_id)
    foreach v in estimate ci_low ci_high {
        replace `v'=100*`v'
    }
    twoway (rcap ci_low ci_high plot_id, horizontal lcolor(gs8)) ///
        (scatter plot_id estimate if term=="D_sc10", mcolor(navy)) ///
        (scatter plot_id estimate if term=="D_st10", mcolor(maroon)), ///
        xline(0,lpattern(dash)) ylabel(,valuelabel labsize(small)) ytitle("") ///
        xtitle("Effect difference: pp per +10 pp baseline caste share") ///
        title("`heading'") legend(order(2 "SC" 3 "ST")) ///
        note("Local-linear RDD, h=100; state FEs; block-clustered 95% t intervals.")
    graph export "$FIG/`stem'.png", width(2200) replace
    restore
end
effect_forest primary "08_primary_caste_heterogeneity" "Caste composition and the eligibility effect"
effect_forest employment "09_employment_heterogeneity" "Employment heterogeneity: exploratory outcomes"

* 10: Bandwidth sensitivity.
preserve
use "$TAB/heterogeneity_results.dta", clear
keep if inlist(outcome,"vd_pwr_d_dom_11","hpca11_msl_elec")
foreach v in estimate ci_low ci_high {
    replace `v'=100*`v'
}
generate str60 panel=outcome+" / "+subinstr(term,"D_","",.)
twoway (rcap ci_low ci_high bandwidth) (connected estimate bandwidth), ///
    by(panel,cols(2) note("State FEs; block-clustered 95% t intervals. Exploratory heterogeneity.")) ///
    yline(0,lpattern(dash)) xlabel(50 100 150 200) ///
    xtitle("Bandwidth each side (persons)") ytitle("Difference (pp per +10 pp share)") legend(off)
graph export "$FIG/10_bandwidth_sensitivity.png", width(2200) replace
restore

* 11: Specification sensitivity.
preserve
use "$TAB/specification_sensitivity.dta", clear
foreach v in estimate ci_low ci_high {
    replace `v'=100*`v'
}
encode specification, generate(spec_id)
generate str60 panel=outcome+" / "+subinstr(term,"D_","",.)
twoway (rcap ci_low ci_high spec_id, horizontal) (scatter spec_id estimate), ///
    by(panel,cols(2) note("h=100; 95% t intervals. District-cluster specification uses district inference.")) ///
    xline(0,lpattern(dash)) ylabel(,valuelabel labsize(small)) ytitle("") ///
    xtitle("Difference (pp per +10 pp share)") legend(off)
graph export "$FIG/11_specification_sensitivity.png", width(2200) replace
restore

* 12: Pre-policy balance.
preserve
use "$TAB/baseline_balance.dta", clear
foreach v in estimate ci_low ci_high {
    replace `v'=100*`v' if outcome!="lights_max2001"
}
encode outcome, generate(balance_id)
twoway (rcap ci_low ci_high balance_id, horizontal) (scatter balance_id estimate), ///
    xline(0,lpattern(dash)) ylabel(,valuelabel labsize(small)) ytitle("") ///
    title("Pre-policy balance at the eligibility boundary") ///
    xtitle("Difference: percentage points; brightness in native units") legend(off) ///
    note("h=100; state FEs; block-clustered 95% t intervals. Check Holm-adjusted p-values.")
graph export "$FIG/12_baseline_balance.png", width(2200) replace
restore

* 13: Majority-group eligibility effects.
preserve
use "$TAB/majority_group_rdd.dta", clear
keep if status=="Estimated"
foreach v in estimate ci_low ci_high {
    replace `v'=100*`v'
}
encode group, generate(group_id)
twoway (rcap ci_low ci_high group_id, horizontal) (scatter group_id estimate), ///
    by(outcome,cols(2) note("h=100; state FEs; block-clustered 95% t intervals. Adequate-sample groups only.")) ///
    xline(0,lpattern(dash)) ylabel(,valuelabel) ytitle("") ///
    xtitle("Eligibility effect (percentage points)") legend(off)
graph export "$FIG/13_majority_group_rdd.png", width(2200) replace
restore

* 14: State coverage.
preserve
keep if sample_preferred==1 & local_100==1
generate byte village_count=1
graph hbar (sum) village_count, over(state,sort(1) label(labsize(small))) ///
    title("State coverage of the local sample") ytitle("Number of villages") ///
    note("$SOURCE Population 200-399. Counts do not establish state-specific power.")
graph export "$FIG/14_state_sample_coverage.png", width(1800) replace
restore

* 15: Pre-policy night-light discontinuities.
preserve
use "$TAB/pre_policy_nightlights.dta", clear
twoway (rcap ci_low ci_high year) (connected estimate year), ///
    yline(0,lpattern(dash)) xlabel(1998(1)2004) title("Night-light differences before RGGVY") ///
    xtitle("Year") ytitle("Maximum brightness difference (0-63 scale)") legend(off) ///
    note("DMSP data; separate local-linear RDDs; h=100; state FEs; block-clustered 95% t intervals.")
graph export "$FIG/15_pre_policy_nightlight_checks.png", width(1800) replace
restore

* 16: Descriptive availability/adoption gap.
preserve
keep if sample_preferred==1 & local_100==1
replace access_adoption_gap=100*access_adoption_gap
graph bar (mean) access_adoption_gap, over(caste_group) ///
    title("Village availability versus household adoption") ///
    ytitle("Mean availability minus lighting share (pp)") ///
    note("$SOURCE Descriptive measure, not a disconnection rate or an individual caste effect.")
graph export "$FIG/16_access_adoption_gap.png", width(1800) replace
restore
rd_display vdp_pwr_d_com_11 "" "Commercial electricity, 2011" commercial_rd
rd_display vd_pwr_d_all_11 "" "All-sector electricity, 2011" allsector_rd
graph combine commercial_rd allsector_rd, cols(2) ///
    note("Exploratory outcomes added after primary results; motivated by the published study.")
graph export "$FIG/17_productive_electricity_rdd.png", width(2200) replace
effect_forest productive "18_productive_electricity_heterogeneity" "Productive electricity: exploratory caste heterogeneity"
graph drop _all
