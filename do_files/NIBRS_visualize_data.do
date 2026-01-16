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

clear
use "$added_mis/`filename'"

// graph bar zero_data_months if year==2018, over(ori)


*-----------------------------*
* 1. Visualize by-variable missingness
*-----------------------------*

* List of variables to check
// levelsof year, local(years_list)
//

bysort ori : egen missing_months_2018to23 = sum(zero_data_indicator_binary)

bysort ori year: gen num_months = _N // num_months is now the number of months for each ORI/Year



// preserve

* Reshape into long format
* Keep only the ORI and missing months
// reshape long missing_months_, i(ori) j(year_missing_data)
// save "$raw/missing_months_by_agency.dta", replace

//
//
// bysort ori (year): gen agency_order = _n if year==2018
// bysort ori (year): replace agency_order = agency_order[_n-1] if missing(agency_order)
// levelsof year, local(years)

//
// foreach y of local years {
//     graph bar zero_data_months if year==`y', over(ori, sort(0)) ///
//         ylabel(0(1)12) ///
//         title("Missing months per agency in `y'") ///
//         bargap(0.5) ///
//         xlabel(, angle(vertical))
// }
