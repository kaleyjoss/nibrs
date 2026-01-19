****************************************************
* Project: NIBRS Cleaning
* Purpose: Visualize the combined and added-missingness data 
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
global root    "/Users/klj9278/Library/CloudStorage/Box-Box/_RELIEF_Box/_1b_National_Data/national_datasets/NIBRS"
global raw     "$root/raw_data"
global clean   "$root/clean_data"
global clean_columns "$clean/1_clean_columns"
global combined_data  "$clean/2_combined_raw"
global added_mis  "$clean/3_added_missingness"
local filename "combined_data_with_missingness_2018-2023.dta" 
use "$added_mis/`filename'"

global vis_mis "$clean/4_visualize_missingness"
cap mkdir vis_mis
*-----------------------------*
* 1. Variables (EDIT)
*-----------------------------*
local n_years = 6
local missingness_cutoff = 0.5 // States must report > this percentage of months over the years, unless will be counted as 'missing'

*-----------------------------*
* 1. Visualize missingness for agencies/counties
*-----------------------------*

// Sum up months of data each year, totla
bysort ori year : egen months_of_data_each_year = sum(zero_data_indicator_binary)
bysort ori : egen months_of_data_total = sum(zero_data_indicator_binary)


// Create binary indicators for marking agencies as 'missing', using either method, from months of data reported each year
gen missing_any = months_of_data_total == 0
gen missing_cutoff = months_of_data_total <= `n_years'*12*`missingness_cutoff'
gen reporting_any = !missing_any
gen reporting_cutoff = !missing_cutoff


// Save list of agencies with 100% missingness 
levelsof crosswalk_agency_name if months_of_data_total==0, local(agencies_with_zero_data)
local num_total_agencies_zero_data : word count `agencies_with_zero_data'

// Tag first instance of each ORI
bysort ori: gen _tag = _n == 1 

// Count number of agencies per county
bysort fips_state_county_code_crosswalk: egen num_agencies = total(_tag) // number of ORIs

// Number of missing agencies per county
// Strict, only missing if it's never reported data
bysort fips_state_county_code_crosswalk: egen num_missing_any = total(_tag * missing_any)
// Cutoff, only missing if it's reported less than missingness_cutoff of months in last 6 years
bysort fips_state_county_code_crosswalk: egen num_missing_cutoff = total(_tag * missing_cutoff)

// Number of reporting agencies
gen num_reporting_any = num_agencies - num_missing_any
gen num_reporting_cutoff = num_agencies - num_missing_cutoff

// Percentages of reporting vs. missing agencies
gen pct_missing_any = num_missing_any / num_agencies
gen pct_reporting_any = num_reporting_any / num_agencies
gen pct_missing_cutoff = num_missing_cutoff / num_agencies
gen pct_reporting_cutoff = num_reporting_cutoff / num_agencies

//  Sum population of missing agencies (strict)
bysort fips_state_county_code_crosswalk: egen pop_missing_any = total(crosswalk_population * missing_any)
bysort fips_state_county_code_crosswalk: egen pop_reporting_any = total(crosswalk_population * reporting_any)

// Sum population of missing agencies (60% cutoff)
bysort fips_state_county_code_crosswalk: egen pop_missing_cutoff = total(crosswalk_population * missing_cutoff)
bysort fips_state_county_code_crosswalk: egen pop_reporting_cutoff = total(crosswalk_population * reporting_cutoff)

// Percent of county population missing/reporting
bysort fips_state_county_code_crosswalk: egen county_population = total(crosswalk_population*_tag)

gen pct_pop_missing_any = pop_missing_any / county_population
gen pct_pop_reporting_any = pop_reporting_any / county_population

gen pct_pop_missing_cutoff = pop_missing_cutoff / county_population
gen pct_pop_reporting_cutoff = pop_reporting_cutoff / county_population

keep fips_state_county_code_crosswalk num_agencies num_missing_any num_missing_cutoff num_reporting_any num_reporting_cutoff pct_missing_any pct_missing_cutoff pct_reporting_any pct_reporting_cutoff pop_missing_any pop_missing_cutoff pop_reporting_any pop_reporting_cutoff county_population pct_pop_missing_any pct_pop_reporting_any pct_pop_missing_cutoff pct_pop_reporting_cutoff

duplicates drop

gen fips_5_digit = string(fips_state_county_code_crosswalk, "%05.0f")

tempfile missingness_by_county
save `missingness_by_county', replace
save "$vis_mis/missingness_by_county.dta", replace
export delimited using "$vis_mis/missingness_by_county.csv", replace
