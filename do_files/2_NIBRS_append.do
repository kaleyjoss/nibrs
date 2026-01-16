****************************************************
* Project: NIBRS Cleaning
* Purpose: Loads in each SRS NIBRS data from 2018-2023, downloaded from https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/KFMHQE 
* Author: Kaley
* Date: 2026-01-07
* Input: Column-cleaned 2018-2023 files
* Output: Combined 2018-2023 table
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
global clean   "$root/clean_data"
global clean_columns "$clean/1_clean_columns"
global combined_data  "$clean/2_combined_raw"


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
        use "$clean_columns/`file'", clear
        local first = 0
    }
    else {
        append using "$clean_columns/`file'", force
    }
}

di as result "Total observations after append: " _N

* Save combined dataset
tempfile combined_data
save "$combined_data/combined_data_2018-2023.dta", replace


