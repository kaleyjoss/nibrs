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

*-----------------------------*
* 1. Visualize missingness for agencies/counties
*-----------------------------*

// Count agencies with 100% missingness
bysort ori year : egen months_of_data_each_year = sum(zero_data_indicator_binary)
bysort ori : egen months_of_data_total = sum(zero_data_indicator_binary)

// Save list of agencies with 100% missingness 
levelsof crosswalk_agency_name if months_of_data_total==0, local(agencies_with_zero_data)
local num_total_agencies_zero_data : word count `agencies_with_zero_data'

// Count number of agencies, zero-data-agencies for each county
bysort ori: gen _tag = _n == 1 // tag first instance of each ori 
bysort fips_state_county_code_crosswalk: egen num_agencies = total(_tag) // number oris
drop _tag

bysort fips_state_county_code_crosswalk ori: gen _tag = _n == 1 & months_of_data_total == 0 // tag first instance of each ori with 0 data
bysort fips_state_county_code_crosswalk (months_of_data_total): egen num_agencies_zero_data = total(_tag) // number oris with 0 data
drop _tag


gen has_any_data = (months_of_data_total!=0) //binary indicator
gen population_any_data = has_any_data*crosswalk_population 
gen population_x_num_months = (crosswalk_population*months_of_data_each_year)/12
gen population_x_total_months = (crosswalk_population*months_of_data_total)/(`n_years'*12)

bysort fips_state_county_code_crosswalk: egen county_population = sum(crosswalk_population)

keep ori crosswalk_agency_name fips_state_county_code_crosswalk county_population crosswalk_population year num_agencies num_agencies_zero_data months_of_data_each_year population_any_data population_x_num_months population_x_total_months
duplicates drop
save "$vis_mis/missingness_by_population_agency.dta", replace

bysort fips_state_county_code_crosswalk year : egen c_yr_pop_covered_any = sum(population_any_data) 

gen perc_c_yr_pop_covered_any = c_yr_pop_covered_any/county_population

bysort fips_state_county_code_crosswalk : egen c_pop_covered_any = sum(population_any_data)

replace c_pop_covered_any = c_pop_covered_any/`n_years'

gen perc_c_pop_covered_any = c_pop_covered_any/county_population

keep fips_state_county_code_crosswalk year c_yr_pop_covered_any perc_c_yr_pop_covered_any c_pop_covered_any perc_c_pop_covered_any
duplicates drop 
gen fips_5_digit = string(fips_state_county_code_crosswalk, "%05.0f")
save "$vis_mis/missingness_by_county.dta", replace
export delimited using "missingness_by_county.csv", replace

