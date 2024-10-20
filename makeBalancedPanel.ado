capture program drop makeBalancedPanel
program define makeBalancedPanel, rclass
    * Arguments:
    * 1. idname: The ID variable (e.g., firm, household, etc.)
    * 2. tname: The time variable
    * 3. return_data_frame: Option to keep the resulting dataset in memory
    syntax varlist(min=2)
    * Assign the id and time variables
    qui {
	tempvar idname tname
	tokenize `varlist'
    gen `idname'=`1'
	gen `tname' = `2'
	}
    * Get the number of unique time periods
    qui {
		unique `tname'
     	local nt = r(unique)
    * Count the number of time periods for each ID and filter for those with complete data
	 	sort `idname' `tname'
	 	bysort `idname': gen _id_count = _N
     	drop if _id_count != `nt'
    * Drop intermediate variables
	   	drop  _id_count `tname' `idname'
	}
end
