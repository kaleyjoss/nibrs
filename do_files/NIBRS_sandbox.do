****************************************************
* Project: NIBRS Cleaning
* Purpose: Loads in each SRS NIBRS data from 2018-2023, downloaded from https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/KFMHQE 
* Author: Kaley
* Date: 2026-01-07
* Input: Raw data yearly files from dataverse (above link)
* Output: Cleaned 2018-2023 table
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
global output  "$root/outputs"


*-----------------------------*
* 1. File List (EDIT)
*-----------------------------*
local filenames `" "arrests_monthly_all_crimes_race_sex_2023.dta"  "arrests_monthly_all_crimes_race_sex_2022.dta" "arrests_monthly_all_crimes_race_sex_2021.dta" "arrests_monthly_all_crimes_race_sex_2020.dta" "arrests_monthly_all_crimes_race_sex_2019.dta" "arrests_monthly_all_crimes_race_sex_2018.dta" "'


********************************************************************************
* Step 2: Append all files
********************************************************************************

di as text "Appending all files..."

clear
local first = 1
foreach file of local filenames {
    if `first' {
        use "$raw/`file'", clear
        local first = 0
    }
    else {
        append using "$raw/`file'", force
    }
}

di as result "Total observations after append: " _N

* Save combined dataset
tempfile combined_data
save "$clean/`combined_data'", replace



//
//
// ********************************************************************************
// * Step 3: Merge with crosswalk file for each year
// ********************************************************************************
//
// di as text _n "{hline 80}"
// di as text "Merging with crosswalk file..."
// di as text "{hline 80}"
//
// * Import crosswalk file
// preserve
// import delimited "$raw/crosswalk_all_police_agencies.csv", clear varnames(1)
// tempfile crosswalk
// save `crosswalk', replace
// restore
//
// * Get list of merge variables that exist in both datasets
// use `combined_data', clear
// quietly ds
// local arrest_vars `r(varlist)'
//
// use `crosswalk', clear
// quietly ds
// local crosswalk_vars `r(varlist)'
//
// * Check which merge variables exist, out of ones we think exist
// local merge_vars "year month crosswalk_agency_name fips_state_county_code ori ori9"
// local actual_merge_vars //empty list
// foreach var of local merge_vars { 
//     local var_lower = lower("`var'") 
//     capture confirm variable `var'  // confirm variable = checks existence
//     if !_rc { //if the last command done succeeded, ie if variable exists
//         local actual_merge_vars `actual_merge_vars' `var' // add var
//     }
//     else { // try lowercase
//         capture confirm variable `var_lower' 
//         if !_rc {
//             local actual_merge_vars `actual_merge_vars' `var_lower' // add var
//         }
//     }
// }
//
// if "`actual_merge_vars'" == "" {
//     di as error "No valid merge variables found."
//     exit 459
// }
//
// use `crosswalk', clear
// keep `actual_merge_vars'
// duplicates drop
// tempfile crosswalk_unique
// save `crosswalk_unique', replace
//
// * Merge for each year
// use `combined_data', clear
//
// * Check if year variable exists
// capture confirm variable year 
// if _rc { // if last command DOESN'T succeed
//     di as error "Variable 'year' not found in dataset"
//     exit
// }
//
// levelsof year, local(years)
//
// clear
// tempfile merged_all
// local first = 1
//
// foreach yr of local years {
//     use `combined_data', clear
//     keep if year == `yr'
//    
//     * Cross join with crosswalk to get all agencies
//     cross using `crosswalk_unique'
//    
//     * Fill in year
//     replace year = `yr' if missing(year)
//    
//     if `first' {
//         save `merged_all', replace
//         local first = 0
//     }
//     else {
//         append using `merged_all'
//         save `merged_all', replace
//     }
//    
//     di as text "Merged year `yr': " as result _N " observations"
// }
//
// use `merged_all', clear
//
// ********************************************************************************
// * Step 4: Expand to include all months for each ORI-year
// ********************************************************************************
//
// di as text _n "{hline 80}"
// di as text "Expanding to include all months..."
// di as text "{hline 80}"
//
// * Check which month variables exist
// local months "jan feb mar apr may jun jul aug sep oct nov dec"
// local month_vars
// foreach mon of local months {
//     capture confirm variable `mon'
//     if !_rc {
//         local month_vars `month_vars' `mon'
//     }
// }
//
// * Identify the data structure - need to expand by months
// * Create month identifier if data isn't already in long format
// capture confirm variable month
// if _rc {
//     * Data might be in wide format - convert to long
//     di as text "Converting to long format with all 12 months..."
//    
//     * Create all month combinations
//     preserve
//     clear
//     set obs 12
//     gen month = _n
//     gen month_name = ""
//     replace month_name = "jan" if month == 1
//     replace month_name = "feb" if month == 2
//     replace month_name = "mar" if month == 3
//     replace month_name = "apr" if month == 4
//     replace month_name = "may" if month == 5
//     replace month_name = "jun" if month == 6
//     replace month_name = "jul" if month == 7
//     replace month_name = "aug" if month == 8
//     replace month_name = "sep" if month == 9
//     replace month_name = "oct" if month == 10
//     replace month_name = "nov" if month == 11
//     replace month_name = "dec" if month == 12
//     tempfile all_months
//     save `all_months', replace
//     restore
//    
//     * Cross join with all months
//     cross using `all_months'
// }
//
// save `merged_all', replace
//
// ********************************************************************************
// * Step 5: Calculate missing month percentages
// ********************************************************************************
//
// di as text _n "{hline 80}"
// di as text "Calculating missing month percentages..."
// di as text "{hline 80}"
//
// use `merged_all', clear
//
// * Identify data variables (non-ID variables) to check for missingness
// ds year ori* crosswalk_agency_name fips_state_county_code state_abb month*, not
// local data_vars `r(varlist)'
//
// * Create indicator for missing data
// egen missing_data = rowmiss(`data_vars')
// gen has_data = (missing_data < `: word count `data_vars'')
//
// * Calculate percentage of missing months by agency and year
// collapse (mean) pct_missing = has_data (count) n_months = month, ///
//     by(year ori crosswalk_agency_name state_abb)
//    
// replace pct_missing = (1 - pct_missing) * 100
//
// * Label
// label variable pct_missing "Percentage of missing months"
//
// save "$raw/arrests_panel_with_missingness.dta", replace
//
// ********************************************************************************
// * Step 6: Create bar charts by state
// ********************************************************************************
//
// di as text _n "{hline 80}"
// di as text "Creating bar charts by state..."
// di as text "{hline 80}"
//
// * Get list of states
// levelsof state_abb, local(states)
//
// foreach state of local states {
//    
//     use "$raw/arrests_panel_with_missingness.dta", clear
//     keep if state_abb == "`state'"
//    
//     * Limit to agencies with some data
//     bysort crosswalk_agency_name: egen any_data = max(n_months > 0)
//     keep if any_data == 1
//    
//     * Create numeric agency ID for graphing
//     encode crosswalk_agency_name, gen(agency_id)
//    
//     * Check if there are agencies to graph
//     qui count
//     if r(N) == 0 {
//         di as text "Skipping `state' - no data"
//         continue
//     }
//    
//     * Create graph
//     graph bar pct_missing, over(year) over(agency_id, label(angle(45) labsize(vsmall))) ///
//         asyvars ///
//         title("Percentage of Missing Months by Agency: `state'") ///
//         subtitle("2018-2023") ///
//         ytitle("Percent Missing Months") ///
//         legend(title("Year") rows(1)) ///
//         name(missing_`state', replace)
//    
//     * Export
//     graph export "$raw/missing_months_`state'.png", replace width(1200)
//    
//     di as text "Created chart for `state'"
// }
//
// di as text _n "{hline 80}"
// di as result "Analysis complete!"
// di as text "{hline 80}"
// di as text "Combined dataset saved to: $raw/arrests_panel_with_missingness.dta"
// di as text "Charts exported to: $raw/missing_months_[STATE].png"
