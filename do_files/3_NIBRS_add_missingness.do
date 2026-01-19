* Project: NIBRS Cleaning
* Purpose: Creates crosswalk file of all years, months and agencies, for merging.
* Then merge into larger combined dataset to be able to see missingness.
* Author: Kaley
* Date: 2026-01-07
* Input: Combined 2018-2023 table
* Output: 2018-2023 table with missingness
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


*-----------------------------*
* 1. File List (EDIT)
*-----------------------------*

local cws months.csv crosswalk_all_police_agencies.csv crosswalk_all_fips.csv
*-----------------------------*
* 2. Crosswalk combinations
*-----------------------------*

* Import months and save as tempfile
import delimited "$raw/months.csv", clear varnames(1)
tempfile months
save `months', replace

* Import years and save as tempfile
import delimited "$raw/years.csv", clear varnames(1)
tempfile years
save `years', replace
* Cross join months × years → year_months
use `months', clear
cross using `years'
tempfile year_months
save `year_months', replace
save "$raw/year_months.dta", replace

*-----------------------------*
* 3. Crosswalk agencies
*-----------------------------*

import delimited "$raw/crosswalk_all_police_agencies.csv", clear varnames(1)
drop state_abb //this has some "NA" variables, but we can get it from the ORI
drop ori9 //not necessary, and has missingness
tempfile agencies
save `agencies', replace
use `agencies', clear
cross using `year_months'
tempfile full_panel
save `full_panel', replace
save "$raw/agencies_year_months.dta", replace

*-----------------------------*
* 4. Make zero_data_indicator=1 if there are any crimes reported in all crime columns
*-----------------------------*
use "$combined_data/combined_data_2018-2023.dta"
local exclude ori ori9 population agency_name year month date state state_abb pop_group country_division fips_state_code fips_county_code fips_state_county_code fips_place_code agency_type crosswalk_agency_name census_name longitude latitude address_name address_street_line_1 address_street_line_2 address_city address_state address_zip_code date_of_last_update date_of_1st_previous_update date_of_2nd_previous_update covered_by number_of_months_reported monthly_header_designation breakdown_indicator age_race_ethnicity_indicator juvadult_indicators zero_data_indicator juv_disposition_indicator juv_handled_within_department juv_referred_to_juv_court juv_referred_to_welfare juv_referred_to_police juv_referred_to_crim_court zero_data_indicator_binary zero_data_months identifier_code agency_header_designation msa county sequence_number suburban core_city
ds `exclude', not
local crime_vars `r(varlist)'
// egen crimes_total = rowtotal(`crime_vars')
// replace zero_data_indicator_binary = 1 if zero_data_indicator_binary == 0 & crimes_total > 0

*-----------------------------*
* 4. Replace 0 with "missing" for rows with "reported no data"/zero_data_indicator_binary=0, so it shows as missing instead of a reported 0
*-----------------------------*

foreach v of local crime_vars {
    replace `v' = . if `v' == 0 & zero_data_indicator_binary == 0
}

*-----------------------------*
* 5. Drop irrelevant or inaccurate columns, clean for mergiong
*-----------------------------*

// Same thing with the juv_ indicators, luckily we don't need those
drop juvadult_indicators juv_handled_within_department juv_disposition_indicator juv_referred_to_crim_court juv_referred_to_juv_court juv_referred_to_police juv_referred_to_welfare
drop zero_data_indicator 

// Make fips_state_county_code merge-able in combined_data
destring fips_state_county_code, gen(fips_state_county_code_numeric)
tempfile combined_data 
save `combined_data', replace
clear

// Make fips_state_county_code merge-able in crosswalk
use "$raw/agencies_year_months.dta"
replace fips_state_county_code="" if fips_state_county_code=="20na"
//make new var for fips_state_county_code_crosswalk so that if they don't match up it doesn't mess anything up
destring fips_state_county_code, gen(fips_state_county_code_crosswalk) 
drop fips_state_county_code 

*-----------------------------*
* 6. Merge in combined file to agencies_year_months crosswalk 
*      This is so any agency/year/month combo missing in combined_data is now a row with missing data
*-----------------------------*
merge 1:m year month ori using `combined_data'
sort ori year month

*-----------------------------*
* 7. Check that each agency/year only has 12 or less rows-- that the merging in didn't add any rows/duplicate months
*-----------------------------*
bysort ori year : gen num_rows = _N

*-----------------------------*
* 8. Out of 1.7million rows, there are 1294 with num_months>12 (99.43% have correct number). However, if I ignore the below indicator variables, and then drop duplicates, those rows are duplicates, and there's only 12 per agency/year. So these must have been double imports. So i'm ignoring/making missing these.
*-----------------------------*
replace age_race_ethnicity_indicator = "" if num_rows > 12
replace breakdown_indicator = "" if num_rows > 12
drop num_rows
duplicates drop
bysort ori year : gen num_rows = _N
tab num_rows


save "$added_mis/combined_data_with_missingness_2018-2023.dta", replace
