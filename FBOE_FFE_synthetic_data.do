*------------------j.kabatek@unimelb.edu.au, 08/2021, (c)----------------------*
*          Are sibship characteristics predictive of same-sex marriage?        *
*                      C.Ablaza, J.Kabatek & P.Perales                         *
*                                 -(J<)-                                       *
*                A MODEL ILLUSTRATION USING SYNTHETIC DATA                     *
*------------------------------------------------------------------------------*
* README:                                                                      *
* This code runs without the need for any adjustments. The data is synthetic   *
* (artificially-generated) and sourced from 'www.jankabatek.com/datasets/'     *
*------------------------------------------------------------------------------*

	webuse set "https://www.jankabatek.com/datasets/"
	webuse FBOE_FFE_pseudo_data.dta, clear
	
	/* preferred model specification */
	logit SSC NSib NOlderSib NOlderBrother NYoungerBrother i.BirthYear i.MaternalAgeBirth
		mat RES = r(table)
		
		** Change of odds associated with adding one younger sister to the sibship (isolating the influence of sibship size)
		scalar coef_FFE_test = _b[NSib] 
		scalar odds_FFE_test = exp(coef_FFE_test)
		scalar pval_FFE_test = RES[4,1]		
		
		** Change of odds associated with having an older brother as opposed to an older sister (isolating the influence of gender in the birth order effect)
		scalar coef_FBOE_test = _b[NOlderBrother] 
		scalar odds_FBOE_test = exp(coef_FBOE_test)
		scalar pval_FBOE_test = RES[4,3]				
		
		** SBOE estimate (akin to Blanchard & Lippa, 2021)
		scalar coef_SBOE_BnL = _b[NOlderSib] 
		scalar odds_SBOE_BnL = exp(coef_SBOE_BnL)
		scalar pval_SBOE_BnL  = RES[4,2]
		 
		** FBOE estimate (akin to Blanchard & Lippa, 2021)
		scalar coef_FBOE_BnL = _b[NOlderSib] + _b[NOlderBrother] - _b[NYoungerBrother]
		scalar odds_FBOE_BnL = exp(coef_SBOE_BnL)
		** Command for testing stat. significance of composite coefficient estimates
		*  (!) must be executed after the logit regression command which supplies 
		*  the building blocks for the composite estimate.  
		test NOlderSib + NOlderBrother - NYoungerBrother = 0
		scalar pval_FBOE_BnL = r(p) 
		/* * Alternatively, the same estimates can be extracted from our preferred specification with flipped sibling gender variables:
		logit SSC NSib NOlderSib NOlderSister NYoungerSister i.BirthYear i.MaternalAgeBirth
		scalar coef_FBOE_BnL = _b[NOlderSib] 
		scalar odds_FBOE_BnL = exp(coef_SBOE_BnL)
		scalar pval_FBOE_BnL  = RES[4,2]
		*/
	
	/* conventional model specification */
	logit SSC  NOlderBrother NOlderSister NYoungerBrother NYoungerSister i.BirthYear i.MaternalAgeBirth
		mat RES = r(table)
		** SBOE estimate (conventional)
		scalar coef_SBOE_conv = _b[NOlderSister] 
		scalar odds_SBOE_conv = exp(coef_SBOE_conv)
		scalar pval_SBOE_conv  = RES[4,2]
		 
		** FBOE estimate (conventional)
		scalar coef_FBOE_conv = _b[NOlderBrother]
		scalar odds_FBOE_conv = exp(coef_FBOE_conv)
		scalar pval_FBOE_conv  = RES[4,1]
	
	/* print out the relevant results */	
	qui {
		n di " " 
		n di " " 
		
		local suffix FFE_test  
		n di "Change of odds associated with adding one younger sister to the sibship, used to test the FFE:" 
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 
		
		n di " " 
		
		local suffix FBOE_test  
		n di "Change of odds associated with having an older brother as opposed to an older sister, used to test the FBOE:"
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 
	 
		n di " " 
		n di " " 
		
		local suffix FBOE_BnL  
		n di "FBOE estimate, akin to Blanchard & Lippa 2021:"
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 

		
		n di " " 
		
		local suffix SBOE_BnL  
		n di "SBOE estimate, akin to Blanchard & Lippa 2021:"
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 

		n di " " 
		n di " " 
		
		local suffix FBOE_conv  
		n di "FBOE estimate, conventional model:"
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 

		n di " " 
		
		local suffix SBOE_conv
		n di "SBOE estimate, conventional model:" 
		n di as text "Coefficient:" as err %4.3f coef_`suffix' as text ", odds ratio:" as err %4.3f odds_`suffix' as text ", p-value: " as err %6.5f pval_`suffix' 


		n di " " 
		n di " " 
		
		*re-estimate the preferred model specification
		qui logit SSC NSib NOlderSib NOlderBrother NYoungerBrother i.BirthYear i.MaternalAgeBirth
		n di "We can recover the exact value of conventional FBOE estimate from the estimtates corresponding to our preferred model specification:"
		n di as err coef_FBOE_conv " = "  _b[NSib]  " + " _b[NOlderSib] " + "  _b[NOlderBrother] " = " (_b[NSib] + _b[NOlderSib] +  _b[NOlderBrother])
		
	}