/*------------------j.kabatek@unimelb.edu.au, 08/2021, (c)----------------------*/
/*          Are sibship characteristics predictive of same-sex marriage?        */
/*                      C.Ablaza, J.Kabatek & P.Perales                         */
/*                                 -(J<)-                                       */
/*                A MODEL ILLUSTRATION USING SYNTHETIC DATA                     */
/*------------------------------------------------------------------------------*/
/* README:                                                                      */
/* This code runs without the need for any adjustments. The data is synthetic   */
/* (artificially-generated) and sourced from 'www.jankabatek.com/datasets/'     */
/*------------------------------------------------------------------------------*/

* Encoding: UTF-8.
PRESERVE. 
SET DECIMAL DOT. 

SPSSINC GETURI DATA 
    URI="https://jankabatek.com/datasets/FBOE_FFE_pseudo_data.dta"
    FILETYPE=STATA
 
/* === preferred model specification ==== */
    
LOGISTIC REGRESSION VARIABLES SSC 
  /METHOD=ENTER NSib NOlderSib NOlderBrother NYoungerBrother BirthYear MaternalAgeBirth 
  /CONTRAST (BirthYear)=Indicator 
  /CONTRAST (MaternalAgeBirth)=Indicator 
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).
/* NSib estimate captures the change of odds associated with adding one younger sister to the sibship, used to test the FFE*/
/* NOlderBrother estimate captures the change of odds associated with having an older brother as opposed to an older sister, used to test the FBOE */
/* NOlderSib estimate captures the SBOE estimate, akin to Blanchard & Lippa 2021 */

/* === preferred model specification, flipped gender variables ==== */
    
LOGISTIC REGRESSION VARIABLES SSC 
  /METHOD=ENTER NSib NOlderSib NOlderSister NYoungerSister BirthYear MaternalAgeBirth 
  /CONTRAST (BirthYear)=Indicator 
  /CONTRAST (MaternalAgeBirth)=Indicator 
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).
/* Because of the flipped gender variables, NOlderSib estimate captures the FBOE estimate, akin to Blanchard & Lippa 2021 */

/* === conventional model specification ==== */
    
LOGISTIC REGRESSION VARIABLES SSC 
  /METHOD=ENTER NOlderBrother NOlderSister NYoungerBrother NYoungerSister BirthYear MaternalAgeBirth 
  /CONTRAST (BirthYear)=Indicator 
  /CONTRAST (MaternalAgeBirth)=Indicator 
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).
/* NOlderBrother estimate captures the conventional FBOE estimate */
/* NOlderBrother estimate captures the conventional SBOE estimate */
/* Note that the exact values of conventional estimates can be recovered from the estimtates corresponding to our preferred model specification. See the manuscript / Stata code for details. */

