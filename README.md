# Replication code for Ablaza, Kabatek &amp; Perales, JSR forth.
                                                                             
This replication package contains three sets of codes: 
1. STATA code replicating the full analysis that draws on proprietary data provided by Statistics Netherlands (STATNL) 
2. Simple STATA code that uses a **synthetic dataset** to illustrate the mechanics of our model, demonstrate its relation to the conventional FBOE model, and provide an example of statistical inference for composite coefficient estimates.
3. Even simpler SPSS code that does the fundamentals of 2.


Note: the STATNL analysis (code 1) draws on proprietary administrative data, which means that **the actual dataset used for the analysis is not supplied in the replication package**.                                 
 
The code for the STATNL analysis was written and executed in STATA 16.0, OS Windows 10. **You will need Stata 16.0 and higher in order to execute this code.** All supplementary packages are provided with the code.      

To execute the code with proprietary STATNL data, make sure that you have access to the following datasets: 
                       
      GBAPERSOONTAB                          
      GBAVERBINTENISPARTNERBUS               
      KINDOUDERTAB                           

Inquiries regarding the access to STATNL data should be addressed to [microdata@cbs.nl](mailto:microdata@cbs.nl)   

To run the principal analysis, please execute the do-file (FBOE_FFE_STATNL.do). Before you do so, please change the global MAIN_FOL macro to your project folder which contains the do-file FBOE_FFE_STATNL.do and the subfolder 'auxiliary_scripts' containing the supplementary packages. Detailed instructions can be found in the preamble of FBOE_FFE_STATNL.do.

The codes are commented and they contain additional information that should facilitate the replication efforts. 