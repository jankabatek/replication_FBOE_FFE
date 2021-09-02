*------------------j.kabatek@unimelb.edu.au, 08/2021, (c)----------------------*
*          Are sibship characteristics predictive of same-sex marriage?        *
*                      C.Ablaza, J.Kabatek & P.Perales                         *
*                                 -(J<)-                                       *
*            FULL ANALYSIS USING PROPRIETARY ADMINISTRATIVE DATA               *
*------------------------------------------------------------------------------*
* README:                                                                      *
* To operationalize the code, change the global macro MAIN_FOL (line 28) to    *
* your preferred project folder. Make sure that the folder contains a folder   * 
* called auxiliary_scripts that contains auxiliary scripts stored at           *
* https://github.com/jankabatek/replication_FBOE_FFE/auxiliary_scripts/        *
* Note that the paths, names, and versions of raw CBS datasets used in this    *
* code may have changed. Please make sure that all the global dataset macros   *
* (lines 39-41) are up to date. Note that these changes may affect the exact   *
* numbers of observations in your final dataset.                               *
*                                                                              *
* The folder data_sets will be populated by datasets that are used             *
* within the code. No need to copy any raw data into the folder. Results will  *
* be collated into a signle file (results/_Results_${VERSION}.xls)             *
*                                                                              *
* THIS CODE RUNS WITH PROPRIETARY DATA PROVIDED BY STATISTICS NETHERLANDS      *
* Further information @ github.com/jankabatek/replication_FBOE_FFE             *
*                                                                              *
* Please note that the entire code takes several hours to execute.             * 
*------------------------------------------------------------------------------*

/* Folder macros */
global MAIN_FOL "H:/REPLICATION/FBOE_FFE_Replication"
global DOFILES 	"${MAIN_FOL}/auxiliary_scripts" 
global DATA  	"${MAIN_FOL}/data"
global EST 		"${MAIN_FOL}/est" 
global LOG 		"${MAIN_FOL}/log" 
global RES		"${MAIN_FOL}/results" 

cd ${MAIN_FOL} 
for any auxiliary_scripts data est log results: cap mkdir X
  
/* Dataset macros */
global GBAPERS_2019   "G:/Bevolking/GBAPERSOONTAB/2019/geconverteerde data/GBAPERSOON2019TABV1.DTA"
global GBAVERB_2019   "G:/Bevolking/GBAVERBINTENISPARTNERBUS/2019/GBAVERBINTENISPARTNER2019BUSV1.DTA" 
global KINDOUDER_2019 "G:/Bevolking/KINDOUDERTAB/2019/geconverteerde data/KINDOUDER2019TABV1.dta" 

/* Other macros */ 
global VERSION = strofreal(month(date("$S_DATE", "DMY")),"%02.0f") + "_" + strofreal(day(date("$S_DATE", "DMY")),"%02.0f")	

*------------------------------------------------------------------------------*
/* Initialization */
clear
set more off 
set seed 123										// Randomization seed  
qui do ${DOFILES}/PLOTTABS.do						// Visualization scripts
qui do ${DOFILES}/PLOTAREA.do
qui do ${DOFILES}/MISC.do  							// Misc scripts
cap log close	
log using "${LOG}/log_${VERSION}" , replace			// Log file

*-----------------------------------------------------------------------------*
 
/*----------------------------------------------------------------------------*/		
/* FIRST BLOCK - dataset construction                                         */
/*----------------------------------------------------------------------------*/ 	

    /* start with the marriage/RP register */ 
		use using "$GBAVERB_2019", clear
		renvars, upper
		drop XKOPPELNRVERBINTENIS RINPERSOONSVERBINTENISP RINPERSOONS // redundant data
		compress 

	/* generate couple ID */
		gen PID = real(RINPERSOON)					// personal ID
		gen SID = real(RINPERSOONVERBINTENISP)		// spousal ID
		gen long MIN = min(PID, SID)
		gen long MAX = max(PID, SID)
		drop SID PID
		tostring MIN MAX, replace format(%09.0f)
		gen CID = MIN + MAX
	
	/* retrieve birthdates */
		rename RINPERSOON rinpersoon	
		merge m:1 rinpersoon using "$GBAPERS_2019",  keepusing(gbageboortejaar gbageboortemaand gbageslacht gbageneratie gbaherkomst)  gen(VERMERGE)
		gen byte female = gbageslacht =="2"
		for var gbageboortejaar gbageboortemaand: gen int X_f=real(X)
		gen BD = gbageboortejaar_f + (gbageboortemaand_f-1)/12
		drop gbageboortejaar_f gbageboortemaand_f
		gen int BDY = floor(BD)
	  
	/*  spousal sexes */ 
		sort CID AANVANGVERBINTENIS gbageslacht BD
		bys CID AANVANGVERBINTENIS (gbageslacht BD): gegen byte TOTF = sum(gbageslacht=="2") // 0=gays, 1=diff.sex, 2 =lesbians
		gen byte CPL_TYP = 0 + 1*(TOTF==2) + 2*(TOTF==1) if TOTF !=.
		label define CPL_TYP 0 "Male SSC" 1 "Female SSC" 2 "DSC"
		label values CPL_TYP CPL_TYP
	
		gen byte ssc_rp_aux = TYPE =="P" & CPL_TYP<2
		gen byte ssc_ma_aux = TYPE =="H" & CPL_TYP<2
	
	/* immigration background */
		bys CID AANVANGVERBINTENIS (gbageslacht BD): gen byte IMMIG = 0 if gbageneratie[1]!="1" &  gbageneratie[2]!="1" 
		bys CID AANVANGVERBINTENIS (gbageslacht BD): replace IMMIG = 1 if gbageneratie[1]=="1" &  gbageneratie[2]!="1"
		bys CID AANVANGVERBINTENIS (gbageslacht BD): replace IMMIG = 1 if gbageneratie[1]!="1" &  gbageneratie[2]=="1"
		bys CID AANVANGVERBINTENIS (gbageslacht BD): replace IMMIG = 2 if gbageneratie[1]=="1" &  gbageneratie[2]=="1"
		DESTRING gbageneratie
  
	/* further classification of same-sex marriages/RPs */
		sort rinpersoon AANVANGVERBINTENIS
		bys rinpersoon (AANVANGVERBINTENIS):  gen byte n1_aux = 1 if _n ==1
		bys rinpersoon (AANVANGVERBINTENIS):  gen byte N_aux = 1 if _n ==_N
		bys rinpersoon (AANVANGVERBINTENIS):gegen byte own_min_cpl = min(CPL_TYP)
		bys rinpersoon (AANVANGVERBINTENIS):  gen byte own_1st_cpl = CPL_TYP[1]
		bys rinpersoon (AANVANGVERBINTENIS):  gen frst_mar = AANVANGVERBINTENIS[1]
 
		bys rinpersoon (AANVANGVERBINTENIS):gegen byte SSC_REG = max(ssc_rp_aux) 
		bys rinpersoon (AANVANGVERBINTENIS):gegen byte SSC_MAR = max(ssc_ma_aux)
 
		gen byte SSC = own_min_cpl <2 
		gen byte SSC_SHMAR = own_min_cpl <2 if own_min_cpl != .
		gen byte SSC_FIRST = own_1st_cpl <2
		gen byte SSC_FIRST_SM = own_1st_cpl <2 if own_min_cpl != .
		 
	/* date of marriage */	
		gen d_AAN = date(AANVANGVERBINTENIS ,"YMD")
		
	/* union & divorce indicator */
		gen byte MAR = own_min_cpl != .
		gen byte DIV = REDENBEEINDIGINGVERBINTENIS =="S"
		by rinpersoon: gegen byte anydiv = max(DIV) 
		
	/* age at union entry */
		gen AAM = yofd(d_AAN) - BD
		sum AAM if SSC ==1 & d_AAN > date("19980330","YMD")
		sum AAM if SSC ==0 & d_AAN > date("19980330","YMD")
   
	/* drop irrelevant variables */
		rename rinpersoon rinpersoon_kid
		rename CPL_TYP CPL_TYP_first_mar
		
	/* keep one observation per person */
		keep if N_aux==1
		
	 /* housekeeping */		
		keep rinpersoon_kid own* SSC* CPL_TYP_first_mar BD* gbageneratie gbaherkomst female anydiv frst_mar gbageneratie IMMIG d_AAN   
	
/*-(2)-SIBs-------------------------------------------------------------------*/	
	/* merge with the child-parent data 
	   - only keep those who can be matched to their parents */
	   preserve 
		use "$KINDOUDER_2019" , clear
		renvars, lower
		bys rinpersoon: keep if _n==_N //drop few duplicities
		merge 1:1 rinpersoon using "$GBAPERS_2019", keep(match) nogen keepusing(gbageslacht)  
		rename rinpersoon rinpersoon_kid
		rename rinpersoonpa rinpersoon1
		rename rinpersoonma rinpersoon2
		
		keep rinpersoon_kid rinpersoon1 rinpersoon2  
		tempfile KINDOUDER
		save `KINDOUDER'
	   restore
		merge m:1 rinpersoon_kid  using `KINDOUDER', keep(match master) keepusing(rinpersoon1 rinpersoon2) 
	
	/* mother's birthdate */
		rename rinpersoon2 rinpersoon
		merge m:1 rinpersoon  using "$GBAPERS_2019", keep(match master)  keepusing(gbageboortejaar)  gen(MOMMERGE)
		DESTRING gbageboortejaar
		rename gbageboortejaar BD_MOM
		rename rinpersoon rinpersoon2
		
		gen AGE_MOM_BIRTH = BDY - BD_MOM
		drop if AGE_MOM_BIRTH < 12
		
		replace AGE_MOM_BIRTH = 15 if AGE_MOM_BIRTH<15
		replace AGE_MOM_BIRTH = 45 if AGE_MOM_BIRTH>45 & (AGE_MOM_BIRTH!=. | AGE_MOM_BIRTH!=999)
		replace AGE_MOM_BIRTH = 999 if AGE_MOM_BIRTH==.
 
	/* sibling characteristics */ 
	 
		gen byte chdum = 1	
		gen byte boydum = 1 - female
		** birth order 
		sort rinpersoon2 BD
		bys rinpersoon2 (BD): gen ord_mom = _n 
		** all sibs
		bys rinpersoon2 (BD): gen  byte N_SIB = _N
		bys rinpersoon2 (BD): egen byte N_BOY = sum(boydum)
		** older sibs
		bys rinpersoon2 (BD): gen  byte NoOlderSib = sum(chdum)-1
		bys rinpersoon2 (BD): gen  byte NoOlderBoy = sum(boydum)
		replace NoOlderBoy = NoOlderBoy - boydum // correct for own gender
		gen byte NoOlderGirl = NoOlderSib - NoOlderBoy
		** younger sibs
		gen byte NoYoungerSib = N_SIB - NoOlderSib - 1
		gen byte NoYoungerBoy = N_BOY - NoOlderBoy - boydum
		gen byte NoYoungerGirl = NoYoungerSib - NoYoungerBoy	
		** additional variables
		gen byte NBoy =  NoOlderBoy + NoYoungerBoy
		gen byte NSib =  N_SIB - 1
		gen byte ONLY_CH =  NSib ==0
      
	/* additional marriage characteristics */
		gen int d_AAN_FRS = date(frst_mar ,"YMD")
		gen AAN_YR = yofd(d_AAN) + (month(d_AAN) - 1)/12
		gen AGE_WED = AAN_YR - BD
 
	/* house keeping II */
		gen byte REL_STAT = 0 +1*(own_min_cpl<2) + 2*(own_min_cpl ==2)
		label define REL_STAT 0 "Never Married/RP" 1 "SSC" 2 "DSC only"
		label values REL_STAT REL_STAT
		
		label define N_SIB 1 "1 child"  2 "2 children"  3 "3 children" 4 "4 children" 5 "5 children", replace
		label values N_SIB N_SIB
		
		label define ord_mom 1 "1st"  2 "2nd"  3 "3rd" 4 "4th" 5 "5th", replace
		label values ord_mom ord_mom
	 
		label define female 0 "Men"  1 "Women" , replace
		label values female female
		
		label define NoOlderSib 0 "Eldest" 1 "1OldSib"  2 "2OldSib"  3 "3OldSib" 4 "4OldSib" 5 "5OldSib", replace
		label values NoOlderSib NoOlderSib
		
		label define NoYoungerSib 0 "None" 1 "1YngSib"  2 "2YngSib"  3 "3YngSib" 4 "4YngSib" 5 "5YngSib", replace
		label values NoYoungerSib NoYoungerSib
	
	compress
	save "${DATA}/MAIN_DATA", replace	

/*----------------------------------------------------------------------------*/		
/* SECOND BLOCK - descriptive figures and summary statistics                  */
/*----------------------------------------------------------------------------*/ 
	
	
	/* Load the data */
	use "${DATA}/MAIN_DATA", clear 
	
	cap frame create frame_res
	cap frame create frame_pt
	cap frame change frame_pt
		** prepare a blank XLS output file with ordered sheets
		clear
		gen a = ""
		set obs 1
		cd "${RES}/"
		for any DOCUMENTATION TABLE_2 TABLE_3 FIG_1 FIG_2 FIG_3 FIG_3_ADDIT  FIG_S1 FIG_S2 FIG_S3 FIG_S4 TABLE_S1 TABLE_S2 TABLE_S3 TABLE_S4: export excel using "_results_${VERSION}" , sheet("X", replace)
		clear
	cap frame change default
	
	/* SI. FIGURE S1 - GRAPH OF SAME-SEX BIRTH YEARS */
		PLOTTABS BDY SSC if BDY>=1920 & BDY <2000 , row clear opt(`"name(FIG_S3, replace) ytitle(Population share) xsize(8) xtitle(Birth year)"')
		PLOTTABS BDY SSC_FIRST if BDY>=1920 & BDY <2000 , row pattern  opt(`"name(FIG_S3, replace)  ytitle(Population share) xsize(8) xtitle(Birth year) legend(on rows(2) order(1 "Ever entered a same-sex union" 2 "First union ever entered was a same-sex union")) ylabel(0 0.002 "0.2%" 0.004 "0.4%" 0.006 "0.6%" 0.008 "0.8%")   "') 		
		** save the corresponding data (for output genertaion) 		
		frame change frame_pt
			FIRSTVAR, trim
			 
			for var plot_val11 plot_val21 : replace X = round(X*100,0.001)
			tostring plot_val11 plot_val21 , replace force format(%10.3f)
			tostring x_val1, replace
			rename x_val1 name 
			
			insobs 5, before(1)
				 
			replace name = "Data underlying Figure S1. Shares of individuals entering same-sex unions, by birth cohort." if _n ==1
			replace name = "Sample selection criteria: Full population, birth cohorts(1920-2000)" if _n ==2
			replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
			
			replace name = "Birth cohort" if _n ==5
			replace plot_val11 = "Ever entered a same-sex union, %" if _n ==5
			replace plot_val21 = "First entered a same-sex union, %" if _n ==5
			
			export excel using "${RES}/_results_${VERSION}" , sheet("FIG_S1", replace)  
		frame change default	
 
	/* sample selection */
		keep if BDY >= 1940 & BDY<=1990
		drop if gbageneratie ==1						
		drop if _merge ==1
		drop if rinpersoon2 == "---------"
  
	/* SI. FIGURE S2 - GRAPH OF SIBSIP SIZES */  
		gen byte N_SIB_ADJ = N_SIB*(N_SIB<=6) + 6*(N_SIB>6) 
		PLOTAREA BDY N_SIB_ADJ , opt(`"name("FIG_S4, replace") ytitle(Population share) xsize(8) xtitle(Birth year) legend(cols(1) pos(3) colfirst title("Sibship size:") order(1 "1 child" 2 "2 children" 3 "3 children" 4 "4 children" 5 "5 children" 6 "6 children or more" ))"')
		** save the corresponding data (for output genertaion) 	
		frame change frame_pt	
			keep x_val1 cell_val1 cell_val2 cell_val3 cell_val4 cell_val5 
			FIRSTVAR, trim
			for var * : replace X = round(X,0.001) 
			tostring cell_val* , replace force format(%10.3f)
			rename x_val1 name
			tostring name , replace 
			
			insobs 5, before(1)
			
			replace name = "Birth cohort" if _n ==5
			for num 1/5: replace cell_valX = "Less than X siblings" if _n==5 
				 
			replace name = "Data underlying Figure S2. Cummulative share of individuals with at most X siblings, by birth cohort." if _n ==1
			replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
			replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
			export excel using "${RES}/_results_${VERSION}" , sheet("FIG_S2", replace) 
		frame change default	
 
	/* FIGURE 1 - SSU BY BRTH ORDER & SIBSHIP SIZES */  
		*gen byte OUTCOME = SSC_FIRST_SM
		gen byte OUTCOME = SSC 
		cap drop var*
		gen var1 = 0
		forvalues i = 1/5 {
			forvalues j =1/`i' {			
				gen var_`i'`j'= (N_SIB == `i') & (ord_mom== `j') 	
			}
			gen var_x`i'= 0
		}
		
		reg OUTCOME var* if female == 0, nocons 
		estimates store gr1
		reg OUTCOME var* if female == 1, nocons 
		estimates store gr2
		
		coefplot gr1 gr2 , vertical recast(bar) barwidth(0.35) finten(60) citop ciopt(recast(rcap)) ///
			ylabel(0 0.0025 "0.25%" 0.005 "0.5%" 0.0075 "0.75%" 0.01 "1%")  omit base $GROPT xsize(7) ///
			xlabel(2"1st" 4"1st" 5"2nd" 7"1st" 8"2nd" 9"3rd" 11"1st" ///
			12"2nd" 13"3rd" 14"4th" 16"1st" 17"2nd" 18"3rd" 19"4th" 20"5th" ) /// 
			xlabel(2"Only_child" 4.5"1_siblings"  8"2_siblings" 12.5"3_siblings"  18"4_siblings", axis(2) notick labgap(0.05)) ///
			xmlabel(0.8"." 3.2"." 6"."  10"." 10"."  15"." 21".", axis(2) tick labgap(-1) tp(i)) ///
			xtitle("Birth order",  margin(small) axis(1)) xtitle("Number of siblings", axis(2))  ///
			ytitle("Share of people who entered a same-sex union", margin(small)) legend(on order(1 "Men" 3 "Women")) ///
			xaxis(1 2) xline(21.5, lcolor(black) lwidth(thin)) ///
			name(FIG_1, replace)
			
			gr_edit plotregion1.AddLine added_lines editor 0.5 0 21.5 0
			gr_edit plotregion1.added_lines_new = 1
			gr_edit plotregion1.added_lines_rec = 1
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(color(ltbluishgray)) editcopy
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(width(medthick)) editcopy
		
		** save the corresponding data (for output genertaion) 
			preserve
				local name FIG_1			
				keep if _n < 100000
				cap erase "${RES}/`name'.txt"
				estimates restore gr1
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				estimates restore gr2
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				use "${RES}/`name'_dta", clear
					for var *: replace X = "" if _n==1 | _n==5 | _n ==7 | _n ==10 | _n ==14 | _n ==19 | _n ==25
					replace v2 = "Men" if _n ==1
					replace v4 = "Women" if _n ==1
					for var v2 v4: replace X = "Beta" if _n ==2
					for var v3 v5: replace X = "S.E." if _n ==2
					drop if _n ==3 | _n ==4 | _n ==5 | _n ==26 
					
					replace v1 = "Single child" if _n==3
					
					replace v1 = "1st born, 1 sibling"   if _n==5
					replace v1 = "2nd born, 1 sibling"   if _n==6
					
					replace v1 = "1st born, 2 siblings"  if _n==8
					replace v1 = "2nd born, 2 siblings"  if _n==9
					replace v1 = "3rd born, 2 siblings"  if _n==10
					
					replace v1 = "1st born, 3 siblings"  if _n==12
					replace v1 = "2nd born, 3 siblings"  if _n==13
					replace v1 = "3rd born, 3 siblings"  if _n==14
					replace v1 = "4th born, 3 siblings"  if _n==15
					
					replace v1 = "1st born, 4 siblings"  if _n==17
					replace v1 = "2nd born, 4 siblings"  if _n==18
					replace v1 = "3rd born, 4 siblings"  if _n==19
					replace v1 = "4th born, 4 siblings"  if _n==20
					replace v1 = "5th born, 4 siblings"  if _n==21
					
					rename v1 name
					insobs 4, before(1)
					replace name = "Data underlying Figure 1. Cummulative shares of individuals entering same-sex unins, by gender, and sibship composition." if _n ==1
					replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
					replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
				
				export excel using "${RES}/_results_${VERSION}" , sheet("`name'", replace) 
			restore

			
	/* FIGURE 2 - SSU SHARES BY OLDER SIBLING GENDERS */  
		cap drop var*
		gen var1 = 0
		forvalues i = 0/4 {
			forvalues j =0/`i' {
				gen var_`i'`j'= (NoOlderSib == `i') & (NoOlderBoy== `j') 
			}
			gen var_x`i'= 0
		}
		 
		reg OUTCOME var* if female == 0, nocons 
		estimates store gr3
		reg OUTCOME var* if female == 1, nocons 
		estimates store gr4
		
		coefplot gr3 gr4 , vertical recast(bar) barwidth(0.35) finten(60) citop ciopt(recast(rcap)) ///
			ylabel(0 0.0025 "0.25%" 0.005 "0.5%" 0.0075 "0.75%" 0.01 "1%") omit base $GROPT xsize(7) ///
			xlabel(2"0" 4"0" 5"1" 7"0" 8"1" 9"2" 11"0" 12"1" 13"2" 14"3" 16"0" 17"1" 18"2" 19"3" 20"4" ) /// 
			xlabel(2"0" 4.5"1"  8"2" 12.5"3"  18"4", axis(2) notick labgap(0)) ///
			xmlabel(1"." 3"." 6"."  10"." 10"."  15"." 21".", axis(2) tick labgap(-1) tp(i)) ///
			xtitle("Number of older brothers", margin(small) axis(1)) xtitle("Number of older siblings", axis(2))  ///
			ytitle("Share of people who entered a same-sex union", margin(small)) legend(on order(1 "Men" 3 "Women")) ///
			xaxis(1 2)   xline(21.5, lcolor(black) lwidth(thin)) ///
			name(FIG_2, replace)
			
			gr_edit plotregion1.AddLine added_lines editor 0.5 0 21.45 0
			gr_edit plotregion1.added_lines_new = 1
			gr_edit plotregion1.added_lines_rec = 1
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(color(ltbluishgray)) editcopy
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(width(medthick)) editcopy

		** save the corresponding data (for output genertaion) 
			preserve
				local name FIG_2
				cap erase "${RES}/`name'.txt"
				keep if _n <100000
				estimates restore gr3
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				estimates restore gr4
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				use "${RES}/`name'_dta", clear
					for var *: replace X = "" if _n==1 | _n==5 | _n ==7 | _n ==10 | _n ==14 | _n ==19 | _n ==25
					replace v2 = "Men" if _n ==1
					replace v4 = "Women" if _n ==1
					for var v2 v4: replace X = "Beta" if _n ==2
					for var v3 v5: replace X = "S.E." if _n ==2
					drop if _n ==3 | _n ==4 | _n ==5 | _n ==26 
					
					replace v1 = "Eldest child" if _n==3
					
					replace v1 = "1 older sister"  	if _n==5
					replace v1 = "1 older brother"  if _n==6
					
					replace v1 = "2 older sisters"  	if _n==8
					replace v1 = "1 older sister, 1 older brother"  if _n==9
					replace v1 = "2 older brothers"  if _n==10
					
					replace v1 = "3 older sisters"  	if _n==12
					replace v1 = "2 older sisters, 1 older brother"  if _n==13
					replace v1 = "1 older sister, 2 older brothers"  if _n==14
					replace v1 = "3 older brothers"  if _n==15
					
					replace v1 = "4 older sisters"  	if _n==17
					replace v1 = "3 older sisters, 1 older brother"  if _n==18
					replace v1 = "2 older sister, 2 older brothers"  if _n==19
					replace v1 = "1 older sister, 3 older brothers"  if _n==20
					replace v1 = "4 older brothers"  if _n==21
					
					rename v1 name
					insobs 4, before(1)
					replace name = "Data underlying Figure 2. Cummulative shares of individuals entering same-sex unins, by gender, and gender of their older siblings." if _n ==1
					replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
					replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
					
				export excel using "${RES}/_results_${VERSION}" , sheet("`name'", replace) 
			restore			

			
	/* SI FIGURE S1 - SSU SHARES BY YOUNGER SIBLING GENDERS */  
		cap drop var*
		gen var1 = 0
		forvalues i = 0/4 {
			forvalues j =0/`i' {
				gen var_`i'`j'= (NoYoungerSib == `i') & (NoYoungerBoy== `j') 
			}
			gen var_x`i'= 0
		}
		
		reg OUTCOME var* if female == 0, nocons 
		estimates store gr5
		reg OUTCOME var* if female == 1, nocons 
		estimates store gr6
		
		coefplot gr5 gr6 , vertical recast(bar) barwidth(0.35) finten(60) citop ciopt(recast(rcap)) ///
			ylabel(0 0.0025 "0.25%" 0.005 "0.5%" 0.0075 "0.75%" 0.01 "1%") omit base $GROPT xsize(7) ///
			xlabel(2"0" 4"0" 5"1" 7"0" 8"1" 9"2" 11"0" 12"1" 13"2" 14"3" 16"0" 17"1" 18"2" 19"3" 20"4" ) /// 
			xlabel(2"0" 4.5"1"  8"2" 12.5"3"  18"4", axis(2) notick labgap(0)) ///
			xmlabel(1"." 3"." 6"."  10"." 10"."  15"." 21".", axis(2) tick labgap(-1) tp(i)) ///
			xtitle("Number of younger brothers", margin(small) axis(1)) xtitle("Number of younger siblings", axis(2))  ///
			ytitle("Share of people who entered a same-sex union", margin(small)) legend(on order(1 "Men" 3 "Women")) ///
			xaxis(1 2)   xline(21.5, lcolor(black) lwidth(thin)) ///
			name(FIG_3, replace)
			
			gr_edit plotregion1.AddLine added_lines editor 0.5 0 21.45 0
			gr_edit plotregion1.added_lines_new = 1
			gr_edit plotregion1.added_lines_rec = 1
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(color(ltbluishgray)) editcopy
			gr_edit plotregion1.added_lines[1].style.editstyle linestyle(width(medthick)) editcopy

		** save the corresponding data (for output genertaion) 
			preserve
				local name FIG_S3
				cap erase "${RES}/`name'.txt"
				keep if _n <100000
				estimates restore gr5
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				estimates restore gr6
				outreg2 using "${RES}/`name'", side dec(5) noparen dta ctitle("men")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") stats(coef se)
				use "${RES}/`name'_dta", clear
					for var *: replace X = "" if _n==1 | _n==5 | _n ==7 | _n ==10 | _n ==14 | _n ==19 | _n ==25
					replace v2 = "Men" if _n ==1
					replace v4 = "Women" if _n ==1
					for var v2 v4: replace X = "Beta" if _n ==2
					for var v3 v5: replace X = "S.E." if _n ==2
					drop if _n ==3 | _n ==4 | _n ==5 | _n ==26 
					
					replace v1 = "Youngest child" if _n==3
					
					replace v1 = "1 younger sister"  	if _n==5
					replace v1 = "1 younger brother"  if _n==6
					
					replace v1 = "2 younger sisters"  	if _n==8
					replace v1 = "1 younger sister, 1 younger brother"  if _n==9
					replace v1 = "2 younger brothers"  if _n==10
					
					replace v1 = "3 younger sisters"  	if _n==12
					replace v1 = "2 younger sisters, 1 younger brother"  if _n==13
					replace v1 = "1 younger sister, 2 younger brothers"  if _n==14
					replace v1 = "3 younger brothers"  if _n==15
					
					replace v1 = "4 younger sisters"  	if _n==17
					replace v1 = "3 younger sisters, 1 younger brother"  if _n==18
					replace v1 = "2 younger sister, 2 younger brothers"  if _n==19
					replace v1 = "1 younger sister, 3 younger brothers"  if _n==20
					replace v1 = "4 younger brothers"  if _n==21
					
					rename v1 name
					insobs 4, before(1)
					replace name = "Data underlying Figure 2. Cummulative shares of individuals entering same-sex unins, by gender, and gender of their younger siblings." if _n ==1
					replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
					replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
					
				export excel using "${RES}/_results_${VERSION}" , sheet("`name'", replace) 
			restore		
		
			drop var*
	
	
	/* TABLE 2, Summary statistics - by hand bc of sex ratios */
		local ifclauselist SSC==0  SSC==1  SSC==1&female==0  SSC==1&female==1 
		mat RES = J(1,6,.)
		mat SE = J(1,6,.)

		foreach clause in `ifclauselist' {
			** means
			mean N_SIB NoOlderSib NoYoungerSib if `clause'
			mat rtable = r(table)
			mat RESAUX = rtable[1..2,1...] 
			** ratios
			ratio (NoOlderBoy/NoOlderGirl) (NoYoungerBoy/NoYoungerGirl) if `clause', fvwrap(1)
			mat rtable = r(table)
			mat RESAUX = (RESAUX ,  rtable[1..2,1...] , (. \ e(N)))  
			** combined
			mat RES = (RES \ RESAUX[1,1...] \ (RESAUX[2,1..5]*sqrt(e(df_r)),RESAUX[2,6]) )
		}

		** differences (1) - (2) & s.e.'s for t-tests 
			mat DIF = RES[2,1...] - RES[4,1...]
			mat DIF = (DIF \ J(2,6,.))
			forvalues i = 1/5 {
					mat DIF[2,`i'] =  sqrt( ((RES[3,`i'])^2)/RES[3,6] + ((RES[5,`i'])^2)/RES[5,6] )
					mat DIF[3,`i'] = DIF[1,`i'] /  								///
									  sqrt( (((RES[3,`i'])^2)*(RES[3,6] - 1)  + ///
											 ((RES[5,`i'])^2)*(RES[5,6] - 1)) / ///
											 (RES[3,6] + RES[5,6] - 2)  )
			}
			mat RES = (RES \ DIF)
 
		** differences (4) - (5) & s.e.'s for t-tests 
			mat DIF = RES[6,1...] - RES[8,1...]
			mat DIF = (DIF \ J(2,6,.))
			forvalues i = 1/5 {
					mat DIF[2,`i'] =  sqrt( ((RES[7,`i'])^2)/RES[7,6] + ((RES[9,`i'])^2)/RES[9,6] )
					mat DIF[3,`i'] = DIF[1,`i'] /  								///
									  sqrt( (((RES[7,`i'])^2)*(RES[7,6] - 1)  + ///
											 ((RES[9,`i'])^2)*(RES[9,6] - 1)) / ///
											 (RES[7,6] + RES[9,6] - 2)  )
			}
			mat RES = (RES \ DIF)'
		
			matrix colnames RES = "r1" "No_SSC" "se1" "SSC" "se2" "SSC_men" "se3" "SSC_women" "se4" "Difference1" "se5" "Cohens_d1" "Difference2" "se6" "Cohens_d2"


		** save the corresponding data (for output generataion) 
			frame change frame_res
			
				clear
				svmat RES, names(col)
				for var * : replace X = round(X,0.01)
				for var No_SSC SSC SSC_men SSC_women : replace X = X - 1 if _n ==1  // subtracting the person from the total sibship size
				tostring * , replace force format(%10.2f)
				replace r1 = "Number of Siblings"     if _n ==1
				replace r1 = "Number of Older Siblings" if _n ==2
				replace r1 = "Number of Younger Siblings" if _n ==3
				replace r1 = "Sex Ratio, Older Siblings" if _n ==4
				replace r1 = "Sex Ratio, Younger Siblings" if _n ==5
				replace r1 = "Observations" if _n ==6
				for var *: replace X = "" if X =="."
		 				 
				insobs 5, before(1)
				rename r1 name
				replace name = "Data underlying Table 2. Summary statistics of individuals who did and did not enter same-sex unions." if _n ==1
				replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
				replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
				
				gen gap = ""
				order name No_SSC se1 SSC se2 Difference1 se5 Cohens_d1 gap  SSC_men se3 SSC_women se4 Difference2 se6 Cohens_d2
				replace name 		= "Variable" if _n ==5
				replace No_SSC 		= "Individuals who did not enter a same-sex union" if _n ==5
				replace SSC 		= "Individuals who entered a same-sex union" if _n ==5
				replace Difference1 = "Mean Difference" if _n ==5
				replace Cohens_d1 	= "Cohen's d" if _n ==5
				replace SSC_men 	= "Men who entered SSUs" if _n ==5
				replace SSC_women 	= "Women who entered SSUs" if _n ==5
				replace Difference2 = "Mean Difference" if _n ==5
				replace Cohens_d2 	= "Cohen's d" if _n ==5
				for var se1 se2 se3 se4: replace X = "S.D." if _n ==5
				for var se5 se6: replace X = "S.E." if _n ==5
				 
				export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_2", replace) 
			
			frame change default
	 		 
	 
/*-(4)-REGRESS----------------------------------------------------------------*/		
		/* Load the data */
		use "${DATA}/MAIN_DATA" if 	BDY >= 1940 		& ///
									BDY<=1990 			& ///
									gbageneratie !=1 	& ///
									_merge !=1 			& ///
									rinpersoon2 != "---------", clear
		 
		/* Principal Logit Models */
		global VARLIST NSib NoOlderSib NoOlderBoy NoYoungerBoy  i.BDY i.AGE_MOM_BIRTH
		
		*1* COH FE - PRINCIPAL MODEL
		logit SSC ${VARLIST} , robust
			estimates save "${EST}/reg_${VERSION}_main_1", replace
			margins, eydx(NSib NoOlderSib NoOlderBoy NoYoungerBoy)
			mat AME = r(table)
		
		*2* PRICIPAL MODEL FOR MEN
		logit SSC ${VARLIST} if   female ==0, robust
			estimates save "${EST}/reg_${VERSION}_main_2", replace
			*margins, eydx(NSib NoOlderSib NoOlderBoy NoYoungerBoy)
				
			** derive marginal effects for 2
			* 2-person sibships:
			matrix C1 = J(3,4,.)
			matrix rownames C1 = beta ll95 ul95
			matrix colnames C1 = BB BG GB GG
			matrix C2 = C1		
			
				** OLDER brother *younger sister
				margins , at(NSib ==1 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C1[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** OLDER brother *younger brother
				margins , at(NSib ==1 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C1[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** older sister *YOUNGER brother
				margins , at(NSib ==1 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 0)	
				matrix C1[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** older brother *YOUNGER brother
				margins , at(NSib ==1 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C1[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
			* minima and maxima conditional on sibship size:
			matrix C3 = J(3,8,.)	
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C3[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 2 NoYoungerBoy = 0)
				matrix C3[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				margins , at(NSib ==3 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C3[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==3 NoOlderSib = 3 NoOlderBoy = 3 NoYoungerBoy = 0)
				matrix C3[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				margins , at(NSib ==4 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C3[1,5] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==4 NoOlderSib = 4 NoOlderBoy = 4 NoYoungerBoy = 0)
				matrix C3[1,6] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
			
			* 3-person sibships:	
			matrix C5 = J(3,10,.)
			matrix rownames C5 = beta ll95 ul95
			matrix colnames C5 = x2YS xYBYS x2YB  xOSYS xOSYB xOBYS xOBYB   x2OS xOSOB x2OB  
			matrix C6 = C5	
			matrix colnames C6 = x2YS xYBYS x2YB  xOSYS xOSYB xOBYS xOBYB   x2OS xOSOB x2OB  

				** OLDER brother *younger sisters
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C5[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** OLDER brother *younger brother younger sister
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C5[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** OLDER brother *younger brothers
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 2)
				matrix C5[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				** MIDDLE brother *both sisters
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C5[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE brother *younger brother older sister
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C5[1,5] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE brother *older brother younger sister
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C5[1,6] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE brother *both brothers
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 1)
				matrix C5[1,7] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				** YOUNGER brother *older sisters
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C5[1,8] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** YOUNGER brother *older mix
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C5[1,9] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** YOUNGER brother *older brothers
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 2 NoYoungerBoy = 0)
				matrix C5[1,10] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]

		*2* PRICIPAL MODEL FOR WOMEN
		logit SSC ${VARLIST} if   female ==1, robust
			estimates save "${EST}/reg_${VERSION}_main_3", replace
			*margins, eydx(NSib NoOlderSib NoOlderBoy NoYoungerBoy)
			
			** derive marginal effects for 3
			* 2-person sibships:
				** OLDER sister *younger sister
				margins , at(NSib ==1 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C2[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]	
				** OLDER sister *younger brother
				margins , at(NSib ==1 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C2[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** older sister *YOUNGER sister
				margins , at(NSib ==1 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 0)	
				matrix C2[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** older brother *YOUNGER sister
				margins , at(NSib ==1 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C2[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
 	
			* minima and maxima conditional on sibship size:
			matrix C4 = J(3,8,.)	
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C4[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 2 NoYoungerBoy = 0)
				matrix C4[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				margins , at(NSib ==3 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C4[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==3 NoOlderSib = 3 NoOlderBoy = 3 NoYoungerBoy = 0)
				matrix C4[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				margins , at(NSib ==4 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C4[1,5] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				margins , at(NSib ==4 NoOlderSib = 4 NoOlderBoy = 4 NoYoungerBoy = 0)
				matrix C4[1,6] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
			
			* 3-person sibships:
				** OLDER sister *younger sisters
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C6[1,1] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** OLDER sister *younger brother younger sister
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C6[1,2] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** OLDER sister *younger brothers
				margins , at(NSib ==2 NoOlderSib = 0 NoOlderBoy = 0 NoYoungerBoy = 2)
				matrix C6[1,3] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				** MIDDLE sister *both sisters
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 0)
				matrix C6[1,4] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE sister *younger brother older sister
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 0 NoYoungerBoy = 1)
				matrix C6[1,5] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE sister *older brother younger sister
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C6[1,6] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** MIDDLE sister *both brothers
				margins , at(NSib ==2 NoOlderSib = 1 NoOlderBoy = 1 NoYoungerBoy = 1)
				matrix C6[1,7] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				
				** YOUNGER sister *older sisters
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 0 NoYoungerBoy = 0) 
				matrix C6[1,8] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** YOUNGER sister *older mix
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 1 NoYoungerBoy = 0)
				matrix C6[1,9] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]
				** YOUNGER sister *older brothers
				margins , at(NSib ==2 NoOlderSib = 2 NoOlderBoy = 2 NoYoungerBoy = 0)
				matrix C6[1,10] = r(table)[1,1] \ r(table)[5,1] \ r(table)[6,1]

		/* FIGURE 3 - PREDICTIONS, 2-SIB FAMILIES */  
			coefplot matrix(C1) matrix(C2) ,  ci((2 3))  vertical    offset(0)  citop  ciopt(recast(rcap) ) ///
				ylabel(0.005 "0.5%" 0.006 "0.6%" 0.007 "0.7%" 0.008 "0.8%" 0.009 "0.9%") omit base $GROPT  ///
				xlabel(	1`""Older sibling," 1 younger sister"' /// 
						2`""Older sibling," 1 younger brother"' ///
						3`""Younger sibling," 1 older sister"' ///
						4`""Younger sibling," 1 older brother"'  ) ///  
				ytitle("Predicted probability" "of entering a same-sex union", margin(small)) ///
				legend(on order(1 "Men" 3 "Women")) ysc(r(0.005 0.009)) ///
				name(FIG_3_alt, replace)
				
				** graph formatting
				qui forvalues i = 1/1 {
					gr_edit plotregion1.plot1.style.editstyle marker(symbol(smcircle)) editcopy
					gr_edit plotregion1.plot3.style.editstyle marker(symbol(smdiamond)) editcopy
					gr_edit plotregion1.plot2.style.editstyle marker(size(huge)) editcopy
					gr_edit plotregion1.plot4.style.editstyle marker(size(huge)) editcopy
					
					local y = C2[1,1]
					local x = 1.1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x'
					gr_edit plotregion1.added_text_new = 1
					gr_edit plotregion1.added_text_rec = 1
					gr_edit plotregion1.added_text[1].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[1].style.editstyle color(maroon) editcopy
					gr_edit plotregion1.added_text[1].text = {}
					local text = string(round(C2[1,1]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[1].text.Arrpush "`text'"
					// editor text[1] edits

					local y = C2[1,2]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 2
					gr_edit plotregion1.added_text_rec = 2
					gr_edit plotregion1.added_text[2].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[2].style.editstyle color(maroon) editcopy
					gr_edit plotregion1.added_text[2].text = {}
					local text = string(round(C2[1,2]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[2].text.Arrpush "`text'"
					// editor text[2] edits

					local y = C2[1,3]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 3
					gr_edit plotregion1.added_text_rec = 3
					gr_edit plotregion1.added_text[3].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[3].style.editstyle color(maroon) editcopy
					gr_edit plotregion1.added_text[3].style.editstyle size(3.5) editcopy
					gr_edit plotregion1.added_text[3].text = {}
					local text = string(round(C2[1,3]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[3].text.Arrpush "`text'"
					// editor text[3] edits

					local y = C2[1,4]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 4
					gr_edit plotregion1.added_text_rec = 4
					gr_edit plotregion1.added_text[4].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[4].style.editstyle color(maroon) editcopy
					gr_edit plotregion1.added_text[4].text = {}
					local text = string(round(C2[1,4]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[4].text.Arrpush "`text'"
					// editor text[4] edits

					local y = C1[1,1]
					local x = 1.1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 5
					gr_edit plotregion1.added_text_rec = 5
					gr_edit plotregion1.added_text[5].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[5].style.editstyle color(navy) editcopy
					gr_edit plotregion1.added_text[5].text = {}
					local text = string(round(C1[1,1]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[5].text.Arrpush "`text'"
					// editor text[5] edits

					local y = C1[1,2]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 6
					gr_edit plotregion1.added_text_rec = 6
					gr_edit plotregion1.added_text[6].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[6].style.editstyle color(navy) editcopy				
					gr_edit plotregion1.added_text[6].text = {}
					local text = string(round(C1[1,2]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[6].text.Arrpush "`text'"
					// editor text[6] edits

					local y = C1[1,3]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 7
					gr_edit plotregion1.added_text_rec = 7
					gr_edit plotregion1.added_text[7].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[7].style.editstyle color(navy) editcopy
					gr_edit plotregion1.added_text[7].text = {}
					local text = string(round(C1[1,3]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[7].text.Arrpush "`text'"
					// editor text[7] edits

					local y = C1[1,4]
					local x = `x' + 1
					gr_edit plotregion1.AddTextBox added_text editor `y' `x' 
					gr_edit plotregion1.added_text_new = 8
					gr_edit plotregion1.added_text_rec = 8
					gr_edit plotregion1.added_text[8].style.editstyle  angle(default) size( sztype(relative) val(3.4722) allow_pct(1)) color(black) horizontal(left) vertical(middle) margin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) linegap( sztype(relative) val(0) allow_pct(1)) drawbox(no) boxmargin( gleft( sztype(relative) val(0) allow_pct(1)) gright( sztype(relative) val(0) allow_pct(1)) gtop( sztype(relative) val(0) allow_pct(1)) gbottom( sztype(relative) val(0) allow_pct(1))) fillcolor(bluishgray) linestyle( width( sztype(relative) val(.2) allow_pct(1)) color(black) pattern(solid) align(inside)) box_alignment(east) editcopy
					gr_edit plotregion1.added_text[8].style.editstyle color(navy) editcopy
					gr_edit plotregion1.added_text[8].text = {}
					local text = string(round(C1[1,4]*100,0.01)) + "%"
					local text =  "0`text'"
					gr_edit plotregion1.added_text[8].text.Arrpush "`text'"
					// editor text[8] edits
				}
	 			
				** save the corresponding data (for output generataion)
				frame change frame_res  
					** FIGURE 3
					clear 
					mat C_OUT = (C1 \ C2)
					svmat C_OUT, names(col)
						n di as err "YBB vs. OBG: " C1[1,4]/C1[1,1] 
						n di as err "YGB vs. OGG: " C2[1,4]/C2[1,1] 
					 
						for var * : replace X = round(X,0.0001)
						tostring * , replace force format(%10.4f)
						gen name = "" 
						replace name = "lower CI" if _n ==2 | _n==5
						replace name = "Prediction, men" if _n ==1
						replace name = "upper CI" if _n ==3 | _n==6
						replace name = "Prediction, women" if _n ==4
						order name 
							 
						insobs 5, before(1)
						replace name = "Data underlying Figure 3. Predicted probabilities of entering a same-sex union, by gender and sibship composition, Individuals with one sibling." if _n ==1
						replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
						replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
						 
						replace name = "Variable" if _n ==5 
						replace BB = "Older sibling, 1 younger brother" if _n ==5 
						replace BG = "Older sibling, 1 younger sister" if _n ==5 
						replace GB = "Younger sibling, 1 older sister" if _n ==5 
						replace GG = "Younger sibling, 1 older brother" if _n ==5 
				
						export excel using "${RES}/_results_${VERSION}" , sheet("FIG_3", replace) 

					** MINIMA AND MAXIMA CONDITIONAL ON SIBSHIP SIZE
					clear 
					svmat C3, names(col)
						for var * : replace X = round(X,0.0001)
						tostring * , replace force format(%10.4f)
						gen name = "" 
						replace name = "lower CI" if _n ==2  
						replace name = "Prediction, men" if _n ==1
						replace name = "upper CI" if _n ==3   
						order name
						 
						insobs 5, before(1)
						replace name = "Auxiliary results. Predicted probabilities of entering a same-sex union, by gender and sibship composition, Individuals with 1-4 siblings." if _n ==1
						replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
						replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
						 
						replace name = "Variable" if _n ==5 				
						replace c1 ="Eldest, 2 sibs, no brothers " if _n ==5 
						replace c2 ="Youngest, 2 sibs, no sisters"			 if _n ==5 		
						replace c3 ="Eldest, 3 sibs, no brothers " if _n ==5 
						replace c4 ="Youngest, 3 sibs, no sisters"			 if _n ==5 		
						replace c5 ="Eldest, 4 sibs, no brothers " if _n ==5 
						replace c6 ="Youngest, 4 sibs, no sisters"	 if _n ==5 
						
						export excel using "${RES}/_results_${VERSION}" , sheet("FIG_3_ADDIT", replace) 

					** FIGURE S4
					clear 
					mat C_OUT = (C5 \ C6)
					svmat C_OUT, names(col) 
						for var * : replace X = round(X,0.0001)
						tostring * , replace force format(%10.5f)
						
						gen name = "" 
						replace name = "lower CI" if _n ==2 | _n==5
						replace name = "Prediction, men" if _n ==1
						replace name = "upper CI" if _n ==3 | _n==6
						replace name = "Prediction, women" if _n ==4
						order name
						
						insobs 5, before(1)
						replace name = "Data underlying Figure S4, Predicted values of same-sex union entries for individuals with 2 siblings, by gender and sibship composition." if _n ==1
						replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
						replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
						
						replace x2YS  ="Eldest sibling, 2 sisters" if _n ==5 
						replace xYBYS ="Eldest sibling, sister & brother" if _n ==5 
						replace x2YB  ="Eldest sibling, 2 brothers" if _n ==5 
						replace xOSYS ="Middle sibling, 2 sisters" if _n ==5 
						replace xOSYB ="Middle sibling, elder sister & younger brother" if _n ==5 
						replace xOBYS ="Middle sibling, elder brother & younger sister" if _n ==5 
						replace xOBYB ="Middle sibling, 2 brothers" if _n ==5 
						replace x2OS  ="Youngest sibling, 2 sisters" if _n ==5 
						replace xOSOB ="Youngest sibling, sister & brother" if _n ==5 
						replace x2OB  ="Youngest sibling, 2 brothers"  if _n ==5 
						   
						export excel using "${RES}/_results_${VERSION}" , sheet("FIG_S4", replace) 
						
				frame change default
	 				
				n di as err "2 sibs contrast: " %6.0g (C1[1,4]/C1[1,1])*100 - 100 "%"
				n di as err "3 sibs contrast: " %6.0g (C3[1,2]/C3[1,1])*100 - 100 "%"
				n di as err "4 sibs contrast: " %6.0g (C3[1,4]/C3[1,3])*100 - 100 "%"
				n di as err "5 sibs contrast: " %7.0g (C3[1,6]/C3[1,5])*100 - 100 "%"
				
			/* APPENDIX FIGURE S4 - PREDICTIONS, 3-SIB FAMILIES */  
				coefplot matrix(C5) matrix(C6) ,  ci((2 3))  vertical    offset(0)  citop  ciopt(recast(rcap) ) ///
					ylabel(0.005 "0.5%" 0.006 "0.6%" 0.007 "0.7%" 0.008 "0.8%" 0.009 "0.9%" 0.01 "1%") omit base $GROPT  ///
					ytitle("Predicted probability" "of entering a same-sex union", margin(small)) ///
					legend(on order(1 "Men" 3 "Women")) ysc(r(0.005 0.009)) ///
					xlabel(1 "2YS"  2 `""1YS""1YB""' 3 "2YB" 4 `""1OS""1YS""' 5 `""1OS""1YB""' 6 `""1OB""1YS""' 7 `""1OB""1YB""' 8 "2OS" 9 `""1OS""1OB""' 10 "2OB", ) ///
					xlabel(2"eldest_sibling" 5.5 "middle_sibling"  9"youngest_sibling" , axis(2) notick labgap(0.1)) xaxis(1 2) ///
					xtitle("Sibling gender composition", margin(small) axis(1)) xtitle("Position within the sibship", axis(2))  ///
					xline(3.5 7.5, lcolor(gs12)) xline(10.5, lcolor(black) lwidth(thin)) ///
					name(FIG_S4, replace)
					
				gr_edit plotregion1.plot1.style.editstyle marker(symbol(smcircle)) editcopy
				gr_edit plotregion1.plot3.style.editstyle marker(symbol(smdiamond)) editcopy
				gr_edit plotregion1.plot1.style.editstyle marker(size(medium)) editcopy
				gr_edit plotregion1.plot3.style.editstyle marker(size(medium)) editcopy
				gr_edit plotregion1.plot2.style.editstyle marker(size(large)) editcopy
				gr_edit plotregion1.plot4.style.editstyle marker(size(large)) editcopy
				
				gr_edit xaxis2.title.yoffset = 1
				gr_edit xaxis1.title.yoffset = -1
				
				gr_edit xaxis1.major.num_rule_ticks = 0
				gr_edit xaxis1.edit_tick 1 1 `"2YS"', custom tickset(major) editstyle(tickstyle(textgap(2.3)) )			
				gr_edit xaxis1.edit_tick 3 3 `"2YB"', custom tickset(major) editstyle(tickstyle(textgap(2.3)) )
				gr_edit xaxis1.edit_tick 8 8 `"2OS"', custom tickset(major) editstyle(tickstyle(textgap(2.3)) )			
				gr_edit xaxis1.edit_tick 10 10 `"2OB"', custom tickset(major) editstyle(tickstyle(textgap(2.3)) )			
		
		*4* PRICIPAL MODEL, INTERACTED BY FEMALE
		logit SSC ${VARLIST} i1.female i1.female#(c.NSib c.NoOlderSib c.NoOlderBoy c.NoYoungerBoy  i.BDY i.AGE_MOM_BIRTH) , robust
			estimates save "${EST}/reg_${VERSION}_main_4", replace
		
		use "${DATA}/MAIN_DATA", clear		
		keep if BDY >= 1940 & BDY<=1990 & gbageneratie !=1	& _merge !=1 & rinpersoon2 != "---------" 
		 
		/* Robustness */  
 
		** First marriages only
		local i = `i'+1
		local name "First_marriages_only"
		logit SSC_FIRST ${VARLIST} , robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		** Drop singles
		local i = `i'+1
		local name "Drop_singles"
		logit SSC_SHMAR ${VARLIST} , robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		** Past partnership legalization
		local i = `i'+1
		local name "1998plus"
		logit SSC_SHMAR ${VARLIST} if d_AAN >= date("19980101","YMD"), robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		** Past marriage legalization
		local i = `i'+1
		local name "2001plus"
		logit SSC_SHMAR ${VARLIST} if d_AAN > date("20010330","YMD"), robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		** People with less than 5 siblings
		local i = `i'+1
		local name "LT5Sibs"
		logit SSC ${VARLIST} if NSib <=4, robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		/*X* Multinomial logit
		local i = `i'+1
		local name "Mlogit"
		mlogit REL_STAT  ${VARLIST} , robust b(0)
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		*/
		** Matched sample 
		set seed 0
		gen aux = runiform()
		cap drop nr_match1 max_nr_SSC MAX_nr_SSC 
		gen YR_1ST_MRG = floor(AAN_YR)
		bysort BDY YR_1ST_MRG SSC (aux) : gen nr_match1 = _n
		bysort BDY YR_1ST_MRG SSC (aux) : egen max_nr_SSC = max(nr_match1) if SSC ==1
		by BDY YR_1ST_MRG : egen MAX_nr_SSC = max(max_nr_SSC )
		local i = `i'+1
		local name "Matched"
		logit SSC ${VARLIST} if nr_match1 <=MAX_nr_SSC	   & MAX_nr_SSC !=.	
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace	
		** Pick one siblings per sibship
		bys rinpersoon2 (aux): gen rando_pick = _n ==1
		local i = `i'+1
		local name "Only1Sib"
		logit SSC ${VARLIST} if rando_pick==1, robust
			EST_ADD_NAME `name' 
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace		
		
		** Different-sex marriages only
		gen byte DSC = REL_STAT ==2
		local i = `i'+1
		local name "DiffSexUnion"
		logit DSC ${VARLIST}, robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace		
		
		** RegPars only
		local i = `i'+1
		local name "RegParsOnly"
		logit SSC_REG ${VARLIST}, robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
		** Marriages only
		local i = `i'+1
		local name "MarriageOnly"
		logit SSC_MAR ${VARLIST}, robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace	

		** 1st generation included 
		use "${DATA}/MAIN_DATA" if BDY >= 1940 & BDY<=1990 &   _merge !=1 & rinpersoon2 != "---------", clear		
		*keep if _n < 100000
		local i = `i'+1
		local name "InclImmigrants"
		logit SSC ${VARLIST}, robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace 
			
		** 1980YOB_plus 
		use "${DATA}/MAIN_DATA" if BDY >= 1980 & BDY < 2000 & gbageneratie !=1	& _merge !=1 & rinpersoon2 != "---------", clear		
		*keep if _n < 100000
		local i = `i'+1
		local name "1980YOB_plus"
		logit SSC ${VARLIST} if d_AAN > date("19980330","YMD"), robust
			EST_ADD_NAME `name'
			estimates save "${EST}/reg_${VERSION}_robu_`i'", replace 
		
		** DECADE MODELS - back to the original data sample
		use "${DATA}/MAIN_DATA" if BDY >= 1940 & BDY<=1990 & gbageneratie !=1	& _merge !=1 & rinpersoon2 != "---------", clear		
		*keep if _n < 100000
		gen int DEC = floor(BDY/10)*10
		preserve
		forvalues year = 1940(10)1980 {
			keep if DEC == `year'
			local i = `i'+1
			local name "yr_`year'"
			logit SSC ${VARLIST}, robust
				EST_ADD_NAME `name'
				estimates save "${EST}/reg_${VERSION}_robu_`i'", replace
			restore, preserve
		}
		
		di as err "how many robustness models so far:" `i'		
		global I = `i'
	 
		use "${DATA}/MAIN_DATA" if BDY >= 1940 & BDY<=1990 & gbageneratie !=1	& _merge !=1 & rinpersoon2 != "---------", clear	 
		
		/* TABLE S3 - KHOVANOVA'S FBOE-FF MODEL */ 
		gen KHOV_SET = 1 if (female ==0) & (NBoy <2)
		replace KHOV_SET = 2 if NoYoungerBoy ==1 & KHOV_SET==1
		replace KHOV_SET = 3 if NoOlderBoy  == 1 & KHOV_SET==1
		logit SSC i.KHOV_SET i.BDY i.AGE_MOM_BIRTH
		
			** margins:
			matrix CK = J(7,3,.)
			margins i.KHOV_SET, post
			
			forvalues i = 1/3{ 
				mat CK[1+2*(`i'-1),1] = r(table)[1,`i']
				mat CK[2+2*(`i'-1),1] = r(table)[2,`i']
			} 
			mat CK[7,1] = e(N)
			
			** risk ratios 1:
			mat CK[1,2] = 1
			mat CK[2,2] = 0
			nlcom(risk_ratio: _b[2.KHOV_SET] / _b[1.KHOV_SET])
			mat CK[3,2] = r(b)
			mat CK[4,2] = r(V)
			nlcom(risk_ratio: _b[3.KHOV_SET] / _b[1.KHOV_SET])
			mat CK[5,2] = r(b)
			mat CK[6,2] = r(V)
			
			** risk ratios 2:
			nlcom(risk_ratio: _b[1.KHOV_SET] / _b[2.KHOV_SET])
			mat CK[1,3] = r(b)
			mat CK[2,3] = r(V)  
			mat CK[3,3] = 1
			mat CK[4,3] = 0
			nlcom(risk_ratio: _b[3.KHOV_SET] / _b[2.KHOV_SET])
			mat CK[5,3] = r(b)
			mat CK[6,3] = r(V)
			
			** save data into an excel sheet
			frame change frame_res
				clear
				svmat CK 
				replace CK1 = CK1 * 100 if _n!=7
				for var * : replace X = round(X,0.001) 
				tostring * , replace force format(%12.3f)
				
				gen name = "" 
				replace name = "First son in a one-son family" if _n ==1  
				replace name = "First son in a two-son family" if _n ==3
				replace name = "Second son in a two-son family" if _n ==5  
				replace name = "S.E." if _n ==2 | _n ==4 | _n ==6   
				replace name = "Observations" if _n ==7
				order name
				
				insobs 5, before(1)
				
				replace CK1 = "Predicted probability" if _n ==5
				replace CK2 = "Risk ratio PX/P1" if _n ==5
				replace CK3 = "Risk ratiio PX/P2" if _n ==5
				
				for num 2/3: replace CKX = "" if CKX =="." 
				
				replace name = "Data underlying Table S3, Predicted values and risk-ratios of same-sex union entries for men with at most one brother." if _n ==1
				replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
				replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3

				export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_S3", replace) 
			frame change default
			 
  
  		/* CONVENTIONAL FBOE MODEL SPECIFICATION */
		/* conventional model */
		logit SSC  NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.BDY i.AGE_MOM_BIRTH 
			EST_ADD_NAME "altexpo"
			estimates save "${EST}/reg_${VERSION}_alt_1", replace		
		 
		 /* conventional model males */
		logit SSC  NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.BDY i.AGE_MOM_BIRTH if female ==0
			EST_ADD_NAME "altexpo2"
			estimates save "${EST}/reg_${VERSION}_alt_2", replace		
		 
		 /* conventional model females */
		logit SSC  NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.BDY i.AGE_MOM_BIRTH  if female ==1
			EST_ADD_NAME "altexpo3"
			estimates save "${EST}/reg_${VERSION}_alt_3", replace		
		 		 
		 /* conventional model interacted */
		logit SSC  NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.BDY i.AGE_MOM_BIRTH i1.female ///
		i1.female#(c.NoOlderBoy c.NoOlderGirl c.NoYoungerBoy c.NoYoungerGirl i.BDY i.AGE_MOM_BIRTH) 
			EST_ADD_NAME "altexpo4"
			estimates save "${EST}/reg_${VERSION}_alt_4", replace		
		 
/*-(5)-FINAL OUTPUT-----------------------------------------------------------*/		
		cap confirm file "${DATA}/OUTPUT_DATA.dta"
		if _rc != 0 {
			sample 1 
			save "${DATA}/OUTPUT_DATA"
		}
			
		use "${DATA}/OUTPUT_DATA", clear  
		set obs 1000
		  
		global I = 17
		 
		cap erase ${RES}/main.txt
		cap erase ${RES}/robu.txt
		cap erase ${RES}/alt.txt
		
			local outreglist NSib NoOlderSib NoOlderBoy NoYoungerBoy 
		 
			/* MAIN COEFFICIENTS */
			forvalues i=1/4{
				estimates use "${EST}/reg_${VERSION}_main_`i'"
				outreg2 using "${RES}/main",  keep(`outreglist' i.female#c.NSib i.female#c.NoOlderSib i.female#c.NoOlderBoy i.female#c.NoYoungerBoy)  dec(3) ///
					noparen dta ctitle("`main`i''")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)   
			}			
			outreg2 using "${RES}/main", keep(NSib) stats(blank)
			** odds ratios
			forvalues i=1/4{
				estimates use "${EST}/reg_${VERSION}_main_`i'"
				outreg2 using "${RES}/main", eform  keep(`outreglist' i.female#c.NSib i.female#c.NoOlderSib i.female#c.NoOlderBoy i.female#c.NoYoungerBoy)  dec(3) ///
					noparen dta ctitle("`main`i''")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)   
			}	 
 
			/* ROBUSTNESS */
			forvalues i=1/$I {
				n di `i'
				cap estimates use "${EST}/reg_${VERSION}_robu_`i'"
				local name = e(colname)
				outreg2 using "${RES}/robu",  keep(`outreglist' ) dec(3) ///
					noparen dta ctitle("`name'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)   
			}
			outreg2 using "${RES}/robu", keep(NSib) stats(blank)
			** odds ratios
			forvalues i=1/$I {
				n di `i'
				cap estimates use "${EST}/reg_${VERSION}_robu_`i'"
				local name = e(colname)
				outreg2 using "${RES}/robu", eform  keep(`outreglist' ) dec(3) ///
					noparen dta ctitle("`name'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)    
			}
		 
			/* CONVENTIONAL MODEL */
			forvalues i=1/4 {
				estimates use "${EST}/reg_${VERSION}_alt_`i'"
				local name = e(colname)
				outreg2 using "${RES}/alt",  keep(NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.female#c.NoOlderBoy i.female#c.NoOlderGirl i.female#c.NoYoungerBoy i.female#c.NoYoungerGirl) dec(3) ///
					noparen dta ctitle("`name'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)   
			}
			outreg2 using "${RES}/alt", keep(NSib) stats(blank)
			** odds ratios
			forvalues i=1/4 {
				estimates use "${EST}/reg_${VERSION}_alt_`i'"
				local name = e(colname)
				outreg2 using "${RES}/alt", eform keep(NoOlderBoy NoOlderGirl NoYoungerBoy NoYoungerGirl i.female#c.NoOlderBoy i.female#c.NoOlderGirl i.female#c.NoYoungerBoy i.female#c.NoYoungerGirl) dec(3) ///
					noparen dta ctitle("`name'")  addn( "_","Time $S_TIME, $S_DATE", "Data from $S_FN") /// 
					stats(coef se)  alpha(0.001, 0.01, 0.05, 0.1) symbol(***,**,*,†)   
			}			
 
		************************************************************************
		/* COLLATE INTO AN EXCEL FILE */
		use "${RES}/main_dta", clear
			
			forvalues i = 4(2)10{ 
				replace v5 = v5[`i'+8] if _n ==`i'
				replace v10 = strofreal(real(v10[`i'+8])-1) if _n ==`i'
			}
			forvalues i = 5(2)11{ 
				replace v5 = v5[`i'+8] if _n ==`i'
				replace v10 = v10[`i'+8] if _n ==`i'
			}
			
			drop if _n>=12 & _n<=19
		
			replace v6 = ""
			replace v1 = "Number of siblings" if v1 =="NSib"
			replace v1 = "Number of older siblings" if v1 =="NoOlderSib"
			replace v1 = "Number of older brothers" if v1 =="NoOlderBoy"
			replace v1 = "Number of younger brothers" if v1 =="NoYoungerBoy"
			
			replace v1 = "Female * Number of siblings" if v1 =="1.female#c.NSib"
			replace v1 = "Female * Number of older siblings" if v1 =="1.female#c.NoOlderSib"
			replace v1 = "Female * Number of older brothers" if v1 =="1.female#c.NoOlderBoy"
			replace v1 = "Female * Number of younger brothers" if v1 =="1.female#c.NoYoungerBoy"
	   
			replace v2 = "Full sample" if _n ==2
			replace v3 = "Men" if _n ==2
			replace v4 = "Women" if _n ==2
			replace v5 = "Interacted" if _n ==2 
			
			replace v7 = "Full sample - OR" if _n ==2
			replace v8 = "Men - OR" if _n ==2
			replace v9 = "Women - OR" if _n ==2
			replace v10 = "Interacted - OR" if _n ==2 
			forvalues i = 7/10 {
				local j = `i'-6
				replace v`i' = "(`j')" if _n ==1
			}
			
			rename v1 name
			insobs 4, before(1)
			replace name = "Data underlying Table 2. Regression results corresponding to the logit models of same-sex union entry." if _n ==1
			replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
			replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
		 		
			export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_3", replace) 
			
			keep name v2 v7
			rename v2 Coef 
			rename v7 OR
			mat AME_col = . \ . \ . \ . \ . \ . \ . \AME[1,1] \ AME[2,1] \ AME[1,2] \ AME[2,2] \ AME[1,3] \ AME[2,3] \ AME[1,4] \ AME[2,4]
			svmat AME_col
			replace AME_col = round(AME_col,0.001) 
			tostring AME_col , replace force format(%12.3f)
			replace AME_col = "" if AME_col =="."
			
			drop if _n ==5 | _n>15 
			order name AME Coef OR
			replace name = "Data underlying Table S1. Average marginal effects, Beta coefficients and Odds Ratios orresponding to the principal logit model of same-sex union entry." if _n ==1
			replace AME_col = "AME" if _n == 5
			replace Coef = "Coefficient" if _n == 5
			replace OR = "Odds Ratio" if _n == 5
			
			export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_S1", replace) 
		
		use "${RES}/robu_dta", clear 
			replace v19 = ""
			replace v1 = "Number of siblings" if v1 =="NSib"
			replace v1 = "Number of older siblings" if v1 =="NoOlderSib"
			replace v1 = "Number of older brothers" if v1 =="NoOlderBoy"
			replace v1 = "Number of younger brothers" if v1 =="NoYoungerBoy"
		
			for num 20/36: replace vX = vX + " - OR" if _n ==2
			forvalues i = 20/36 { 
				local j = `i'-19
				replace v`i' = "(`j')" if _n ==1
				replace v`i' = v`i' + " - OR" if _n ==2
			}	
			
			rename v1 name
			insobs 4, before(1)
			replace name = "Data underlying Table S4. Regression results corresponding to the logit models of same-sex union entry, robustness checks." if _n ==1
			replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
			replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3

			export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_S4", replace) 
		
		use "${RES}/alt_dta", clear 
			replace v6 = "" 
			replace v1 = "Number of older sisters" if v1 =="NoOlderGirl"
			replace v1 = "Number of older brothers" if v1 =="NoOlderBoy"
			replace v1 = "Number of younger sisters" if v1 =="NoYoungerGirl"
			replace v1 = "Number of younger brothers" if v1 =="NoYoungerBoy"
			
			replace v1 = "Female * Number of older sisters" if v1 =="1.female#c.NoOlderGirl"
			replace v1 = "Female * Number of younger sisters" if v1 =="1.female#c.NoYoungerGirl"
			replace v1 = "Female * Number of older brothers" if v1 =="1.female#c.NoOlderBoy"
			replace v1 = "Female * Number of younger brothers" if v1 =="1.female#c.NoYoungerBoy"
	   
			replace v2 = "Full sample" if _n ==2
			replace v3 = "Men" if _n ==2
			replace v4 = "Women" if _n ==2
			replace v5 = "Interacted" if _n ==2 
			
			replace v7 = "Full sample - OR" if _n ==2
			replace v8 = "Men - OR" if _n ==2
			replace v9 = "Women - OR" if _n ==2
			replace v10 = "Interacted - OR" if _n ==2 
			
			rename v1 name
			insobs 4, before(1)
			replace name = "Data underlying Table S2. Regression results corresponding to the logit models of same-sex union entry." if _n ==1
			replace name = "Sample selection criteria: Population of Dutch residents born in the Netherlands deterministically linked to the records of their mothers, birth cohorts(1920-2000)" if _n ==2
			replace name = "Each cell draws on many more than 10 individuals, so the individual confidentiallity is preserved" if _n ==3
			
			export excel using "${RES}/_results_${VERSION}" , sheet("TABLE_S2", replace) 
		
		! ${RES}/_results_${VERSION}.xls
		
	 