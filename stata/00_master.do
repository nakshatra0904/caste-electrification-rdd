version 16.0
clear all
set more off
set seed 8102026
capture log close _all

/* Run from the repository root:
       cd "C:/path/to/caste_electrification_study"
       do "stata/00_master.do"
   The shipped outputs were executed in Python, not Stata. This master and
   its component .do files are the corresponding Stata implementation.
   Stata writes to stata_generated/ so shipped outputs are preserved.
*/
global PROJECT "`c(pwd)'"
capture confirm file "$PROJECT/data/source_extract.dta"
if _rc {
    display as error "Change directory to the repository root before running."
    exit 601
}
capture mkdir "$PROJECT/stata_generated"
capture mkdir "$PROJECT/stata_generated/tables"
capture mkdir "$PROJECT/stata_generated/figures"
capture mkdir "$PROJECT/stata_generated/logs"
global TAB "$PROJECT/stata_generated/tables"
global FIG "$PROJECT/stata_generated/figures"
log using "$PROJECT/stata_generated/logs/master.log", text replace
set scheme s2color
do "$PROJECT/stata/01_prepare.do"
do "$PROJECT/stata/02_descriptives.do"
do "$PROJECT/stata/03_rdd.do"
do "$PROJECT/stata/04_robustness.do"
do "$PROJECT/stata/05_graphs.do"
display as result "Analysis completed. Review stata_generated/logs/master.log."
log close
