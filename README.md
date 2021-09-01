# Replication code for Ablaza, Kabatek &amp; Perales, forth.
                                                                             
This replication package contains several sets of codes: 
1. STATA code replicating the full analysis that draws on proprietary data provided by Statistics Netherlands (STATNL) 
2. Simple STATA code that uses a **synthetic dataset** to illustrate the mechanics of our model, demonstrate its relation to the conventional FBOE model, and provide an example of statistical inference for composite coefficient estimates.
3. Simple SPSS code that does the same as 2.

 
The code for principal analysis was written and executed in STATA 16.0, OS Windows 10. You will need Stata 16.0 and higher in order to execute this code. All supplementary packages are provided with the code and they are stored in the subfolder 'auxiliary_scripts'. There is no need to install them.         

The STATNL analysis draws on proprietary administrative data, which means that **the actual dataset used for the analysis is not supplied in the replication package**.                                 

To execute the code with proprietary STATNL data, make sure that you have access to the following datasets: 
                       
      GBAPERSOONTAB                          
      GBAVERBINTENISPARTNERBUS               
      KINDOUDERTAB                           

Inquiries regarding the STATNL data access should be addressed to [microdata@cbs.nl](mailto:microdata@cbs.nl)   

To run the principal analysis, please execute the do-file (FBOE_FFE.do). Before you do so, please change the global MAIN_FOL macro in the code to the folder which contains the do-file FBOE_FFE.do and the subfolder 'auxiliary_scripts' containing the supplementary packages.

The codes are commented and they contain additional information that should facilitate the replication efforts. Estimation results are stored in the designated subfolder 'results'.                                
   