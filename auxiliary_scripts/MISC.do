/* Auxiliary programs */

/* store model name among the estimates */
capture program drop EST_ADD_NAME
program define EST_ADD_NAME, eclass
	syntax anything , [SCAlar(string)]
	ereturn local colname =  "`anything'"
end

/* additional result formatting */
capture program drop FIRSTVAR
program define FIRSTVAR
	syntax, [trim] 
	qui forvalues i = 1/1{
		d, varl
		global VAR1 = strtoname(word(r(varlist),1))
		if "`trim'" != ""{
			keep if $VAR1 !=.
		}
	}
end