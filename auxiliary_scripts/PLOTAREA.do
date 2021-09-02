********************************************************************************
*         PLOTAREA - plots disagregated shares in an area graph       
********************************************************************************
* PLOTAREA 	tabulates one or more variables oneway (twoway), and plots 
* 			the resulting frequencies (rates) against the values of (row) variable
*
* REQUIRES: one variable (two variables, second being a dummy)
*			 
* INPUT: 	varlist = variables that are tabulated, first one is the row variable
*
* OPTIONAL: nogen 	 = suppress graph
*			iflabel  = label lines by used if-conditions
*			row 	 = plot twoway rates. Default is oneway frequencies
*			clear 	 = delete stored graphs. Default combines stored graphs + new
*			plotonly = do not tabulate new values, plot stored graphs only
*			graph 	 = choose graph type. Default is line
*			options  = add any stata graph options 	
*			legend 	 = legend 
*			yzero 	 = include zero on y axis 
*	
* COMMENTS: Graphregion is white by default, and ysize is set to 5
*			
* OUTPUT: 	Generate = couples identifier, by default CID
*
* FORMAT:	PLOTTABS t_TM D_ if t_AAN<`t85' , clear row opt( "xlabel(,format(%ty)) xsize(10) xline( `co1' `co2' )")

*------------------j.kabatek@unimelb.edu.au, 08/2016, (c)----------------------*

capture program drop PLOTAREA


cap mata: mata drop SHARES()
mata
function SHARES()
	{
		MATVAL_ORIG = st_matrix("cell_val")
		MATVAL 		= MATVAL_ORIG
		 
		/* inverse selection : first category comes on the top of the graph */
		for (j=1; j<=cols(MATVAL); j++) {
			jinv = cols(MATVAL) - (j-1)
			MATVAL[,j] = MATVAL_ORIG[,jinv]
		} 
		
		SUMVAL = rowsum(MATVAL)
		
		for (j=1; j<=cols(MATVAL); j++) {
			for (i=1; i<=rows(MATVAL); i++) {
				MATVAL[i,j] = MATVAL[i,j] / SUMVAL[i,1]
			}
		}
		
		for (j=2; j<=cols(MATVAL); j++) {
			for (i=1; i<=rows(MATVAL); i++) {
				
				MATVAL[i,j] = MATVAL[i,j] + MATVAL[i,(j-1)] 
			}
		}
		
		st_matrix("MATVAL",MATVAL)
	}
end


 

program define PLOTAREA
	syntax varlist(max=2) [if], [OPTions(string)] 
								 
	qui { 
		** find out from which frame is the PLOTTABS command called
		frame pwf
		local frame_orig = r(currentframe)
		
		** define the plottab output frame (stores the graph data), override create cmd if already exists		 
		if "`frame'" == ""  {
			local frame_pt frame_pt
		}
		cap frame create `frame_pt'
		
		/*cap drop cell* 
		cap drop sum_val* 
		cap drop x_val* */
		frame `frame_pt': clear
		
		tab `varlist' `if' , matcell(cell_val) matrow(x_val)
		
		local M = colsof(cell_val)
		
		frame change `frame_pt'
			svmat x_val
			
			mata: SHARES()
			
			svmat MATVAL, names(cell_val)
	  
			local graph_syntax = ""
			local graph area
			
			forvalues m = `M'(-1)1{
				local graph_syntax `graph_syntax' (`graph' cell_val`m' x_val1 , `pattern`j'' yaxis(1 2) )
			}
			local graph_syntax twoway `graph_syntax'
			`graph_syntax', graphregion(fcolor(white) lcolor(white)) `options' 
		frame change `frame_orig'
	}
end

*cap gen N_SIB_ADJ = (N_SIB)*(N_SIB<6) + (6)*(N_SIB>=6) if  N_SIB<35
*PLOTAREA BDY N_SIB_ADJ 
 