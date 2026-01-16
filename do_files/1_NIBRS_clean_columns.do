* Project: NIBRS Cleaning
* Purpose: Creates all missing columns, so 2018-2023 can be appended
* Author: Kaley
* Date: 2026-01-07
* Input: Raw data yearly files from dataverse (above link)
* Output: 2018-2023 yearly files with clean+full columns
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

*-----------------------------*
* 1. File List (EDIT)
*-----------------------------*
local filenames `" "arrests_monthly_all_crimes_race_sex_2023.dta"  "arrests_monthly_all_crimes_race_sex_2022.dta" "arrests_monthly_all_crimes_race_sex_2021.dta" "arrests_monthly_all_crimes_race_sex_2020.dta" "arrests_monthly_all_crimes_race_sex_2019.dta" "arrests_monthly_all_crimes_race_sex_2018.dta" "'

******************************************************************

local first : word 1 of `filenames'
use "$raw/`first'"
quietly ds
local og_varlist `r(varlist)'
local first_var : word 1 of `og_varlist'
di "`first_var'"
clear



foreach file of local filenames { // loop over all the files
	di "======================================"
	di "Processing: `file'"
	use "$raw/`file'", clear
	quietly ds
	local vars `r(varlist)'
	local missing_vars : list og_varlist - vars // print any missing file vars
	di "Vars missing from file:"
	if "`missing_vars'" == "" {
        di "  (none)"
    }
	else {
		foreach v of local missing_vars {
			di "`v'"
			gen `v' = . // make an empty numeric column if missing
		}
	}
	
	local added_vars : list vars - og_varlist // print any added file vars
	di "Vars added since og file:"
	if "`added_vars'" == "" {
        di "  (none)"
    }
	else {
		foreach v of local added_vars {
			di "`v'"
			gen `v' = . // make an empty numeric column if missing
		}
	}
	
	* Reorder columns to match reference
    order `og_varlist'
	duplicates drop

	save "$clean_columns/`file'", replace
}




