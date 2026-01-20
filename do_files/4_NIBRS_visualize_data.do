****************************************************
* Project: NIBRS Cleaning
* Purpose: Analyze the data for missingness
* Author: Kaley
* Date: 2026-01-07
****************************************************


*-----------------------------*
* 0. Housekeeping
*-----------------------------*
version 17
clear all
set more off
set linesize 255

*-----------------------------*
* 1. Paths (EDIT)
*-----------------------------*

local filename "combined_data_with_missingness_2018-2023.dta"  

global root    "/Users/klj9278/Library/CloudStorage/Box-Box/_RELIEF_Box/_1b_National_Data/national_datasets/NIBRS"

global raw     "$root/raw_data"
global clean   "$root/clean_data"
global clean_columns "$clean/1_clean_columns"
global combined_data  "$clean/2_combined_raw"
global added_mis  "$clean/3_added_missingness"
use "$added_mis/`filename'"

global vis_mis "$clean/4_visualize_missingness"
cap mkdir `vis_mis'
*-----------------------------*
* 1. Variables (EDIT)
*-----------------------------*
local n_years = 6
local missingness_cutoff = 0.8 // States must report > this percentage of months over the years, unless will be counted as 'missing'

// if you want to specify by year, modify these:
local single_year = 1 // 1 = true, 0 = false
local year_to_keep = 2019

if `single_year' {
	keep if year == `year_to_keep'
	local n_years = 1
}
*-----------------------------*
* 1. Visualize missingness for agencies/counties
*-----------------------------*

// Sum up months of data each year, total
bysort ori9 year : egen months_of_data_each_year = sum(zero_data_indicator_binary)
bysort ori9 : egen months_of_data_total = sum(zero_data_indicator_binary)


// Create binary indicators for marking agencies as 'missing', using either method, from months of data reported each year
gen cutoff = `missingness_cutoff'
gen missing_any = months_of_data_total == 0
gen missing_cutoff = months_of_data_total <= `n_years'*12*`missingness_cutoff'
gen reporting_any = !missing_any
gen reporting_cutoff = !missing_cutoff


// Save list of agencies with 100% missingness 
levelsof ori9 if months_of_data_total==0, local(agencies_with_zero_data)
local num_total_agencies_zero_data : word count `agencies_with_zero_data'

// Tag first instance of each ORI
bysort ori9: gen _tag = _n == 1 

// Count number of agencies per county
bysort fips_state_county_code: egen num_agencies = total(_tag) // number of ORIs

// Number of missing agencies per county
// Strict, only missing if it's never reported data
bysort fips_state_county_code: egen num_missing_any = total(_tag * missing_any)
// Cutoff, only missing if it's reported less than missingness_cutoff of months in last 6 years
bysort fips_state_county_code: egen num_missing_cutoff = total(_tag * missing_cutoff)

// Number of reporting agencies
gen num_reporting_any = num_agencies - num_missing_any
gen num_reporting_cutoff = num_agencies - num_missing_cutoff

// Percentages of reporting vs. missing agencies
gen pct_missing_any = num_missing_any / num_agencies
gen pct_reporting_any = num_reporting_any / num_agencies
gen pct_missing_cutoff = num_missing_cutoff / num_agencies
gen pct_reporting_cutoff = num_reporting_cutoff / num_agencies

//  Sum population of missing agencies (strict)
bysort fips_state_county_code: egen pop_missing_any = total(U_TPOP * missing_any * _tag)
bysort fips_state_county_code: egen pop_reporting_any = total(U_TPOP * reporting_any * _tag)

// Sum population of missing agencies (60% cutoff)
bysort fips_state_county_code: egen pop_missing_cutoff = total(U_TPOP * missing_cutoff * _tag)
bysort fips_state_county_code: egen pop_reporting_cutoff = total(U_TPOP * reporting_cutoff * _tag)

// Percent of county population missing/reporting
bysort fips_state_county_code: egen county_population = total(U_TPOP*  _tag)

gen pct_pop_missing_any = pop_missing_any / county_population
gen pct_pop_reporting_any = pop_reporting_any / county_population

gen pct_pop_missing_cutoff = pop_missing_cutoff / county_population
gen pct_pop_reporting_cutoff = pop_reporting_cutoff / county_population

keep fips_state_county_code num_agencies num_missing_any num_missing_cutoff num_reporting_any num_reporting_cutoff pct_missing_any pct_missing_cutoff pct_reporting_any pct_reporting_cutoff pop_missing_any pop_missing_cutoff pop_reporting_any pop_reporting_cutoff county_population pct_pop_missing_any pct_pop_reporting_any pct_pop_missing_cutoff pct_pop_reporting_cutoff

duplicates drop

tempfile missingness_by_county
save `missingness_by_county', replace

if `single_year' {
    save "$vis_mis/missingness_by_county_`year_to_keep'.dta", replace
    export delimited using ///
        "$vis_mis/missingness_by_county_cutoff`missingness_cutoff'_`year_to_keep'.csv", replace
}
else {
    save "$vis_mis/missingness_by_county.dta", replace
    export delimited using ///
        "$vis_mis/missingness_by_county_cutoff`missingness_cutoff'.csv", replace
}
