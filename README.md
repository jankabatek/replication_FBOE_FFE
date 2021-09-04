# Replication code for Ablaza, Kabátek &amp; Perales, JSR forth.

![FBOE_FFE](https://www.jankabatek.com/img/Figure_FBOE_FFE.png)

**This replication package contains three sets of codes:**
1. STATA code replicating the full analysis that draws on **proprietary data** provided by Statistics Netherlands (STATNL).
2. Simple STATA code that uses a **synthetic dataset** to illustrate the mechanics of our model, demonstrate its relation to the conventional FBOE model, and provide an example of statistical inference for composite coefficient estimates.
3. Even simpler SPSS code that does the fundamentals of 2.
 
--- 

## 1. Full analysis in Stata

The first Stata code (FBOE_FFE_STATNL.do) contains the complete data generation and model estimation processes corresponding to our empirical analysis drawing on proprietary administrative data provided by STATNL. The proprietary nature of the the data means that **the administrative dataset is not supplied in this replication package**. The only way to get access to the raw data is to [secure the necessary funding and start a new research project at Statistics Netherlands](https://www.cbs.nl/en-gb/onze-diensten/customised-services-microdata/microdata-conducting-your-own-research). Inquiries regarding data access should be addressed to [microdata@cbs.nl](mailto:microdata@cbs.nl). 
 
The code for the STATNL analysis was written and executed in STATA 16.0, OS Windows 10. **You will need Stata 16.0 and higher in order to execute this code**, otherwise you will have to adjust the code and remove all frame commands (used for the generation of figures and output). All supplementary packages are provided with the code.       

To execute the code with proprietary STATNL data, make sure that you have access to the following datasets: 
                       
      GBAPERSOONTAB                          
      GBAVERBINTENISPARTNERBUS               
      KINDOUDERTAB                           

To run the principal analysis, please execute the do-file (FBOE_FFE_STATNL.do). Before you do so, please change the global MAIN_FOL macro to your project folder which contains the do-file FBOE_FFE_STATNL.do and the subfolder 'auxiliary_scripts' containing the supplementary packages. Detailed instructions can be found in the preamble of FBOE_FFE_STATNL.do.

The codes are commented and they contain additional information that should facilitate the replication efforts. 

---

## 2. Model illustration in Stata

The second Stata code (FBOE_FFE_synthetic_data.do) uses a [synthetic dataset](https://www.jankabatek.com/datasets/FBOE_FFE_pseudo_data.csv) (which roughly mimics the properties of the original proprietary dataset) to estimate **our preferred logistic model**,
<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex=P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\beta&space;}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\beta&space;}})}}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\beta&space;}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\beta&space;}})}}" title="P[{Y_i} = 1\mid {{\bf{x}}_i},{\bf{\beta }}] = \frac{1}{{1 + \exp ( - {{\bf{x}}_i}{\bf{\beta }})}}" /></a>

<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex={{{\bf{x'}}}_i}{\bf{\beta&space;}}&space;=&space;{\beta&space;_0}&space;&plus;&space;{\beta&space;_1}N{(sib.)_i}&space;&plus;&space;{\beta&space;_2}N{(older\,sib.)_i}&space;&plus;&space;{\beta&space;_3}N{(older\,br.)_i}&space;&plus;&space;{\beta&space;_4}N{(younger\,br.)_i}," target="_blank"><img src="https://latex.codecogs.com/gif.latex?{{{\bf{x'}}}_i}{\bf{\beta&space;}}&space;=&space;{\beta&space;_0}&space;&plus;&space;{\beta&space;_1}N{(sib.)_i}&space;&plus;&space;{\beta&space;_2}N{(older\,sib.)_i}&space;&plus;&space;{\beta&space;_3}N{(older\,br.)_i}&space;&plus;&space;{\beta&space;_4}N{(younger\,br.)_i}," title="{{{\bf{x'}}}_i}{\bf{\beta }} = {\beta _0} + {\beta _1}N{(sib.)_i} + {\beta _2}N{(older\,sib.)_i} + {\beta _3}N{(older\,br.)_i} + {\beta _4}N{(younger\,br.)_i}," /></a>
 
and demonstrate its relation to the **conventional FBOE model** and its coefficients, 

 
<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex=P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\gamma&space;}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\gamma&space;}})}}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\gamma&space;}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\gamma&space;}})}}" title="P[{Y_i} = 1\mid {{\bf{x}}_i},{\bf{\gamma }}] = \frac{1}{{1 + \exp ( - {{\bf{x}}_i}{\bf{\gamma }})}}" /></a>

 
<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex={{\bf{x}}_i}{\bf{\gamma&space;}}&space;=&space;{\gamma&space;_0}&space;&plus;&space;{\gamma&space;_1}N{(older\,br.)_i}&space;&plus;&space;{\gamma&space;_2}N{(older\,sis.)_i}&space;&plus;&space;{\gamma&space;_3}N{(younger\,br.)_i}&space;&plus;&space;{\gamma&space;_4}N{(younger\,sis.)_i}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?{{\bf{x}}_i}{\bf{\gamma&space;}}&space;=&space;{\gamma&space;_0}&space;&plus;&space;{\gamma&space;_1}N{(older\,br.)_i}&space;&plus;&space;{\gamma&space;_2}N{(older\,sis.)_i}&space;&plus;&space;{\gamma&space;_3}N{(younger\,br.)_i}&space;&plus;&space;{\gamma&space;_4}N{(younger\,sis.)_i}" title="{{\bf{x}}_i}{\bf{\gamma }} = {\gamma _0} + {\gamma _1}N{(older\,br.)_i} + {\gamma _2}N{(older\,sis.)_i} + {\gamma _3}N{(younger\,br.)_i} + {\gamma _4}N{(younger\,sis.)_i}" /></a> 

The code also illustrates how to test significance of composite coefficient estimates mentioned in the manuscript. This is shown on an example of the coefficient estimate corresponding to the hypothetical scenario of having one fewer younger brother, and one more older brother (this coefficient is akin to an alternative definition of the FBOE recently used by [Blanchard & Lippa, 2021](https://pubmed.ncbi.nlm.nih.gov/33025292/)).

<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex={\beta&space;_{comp}}&space;=&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}&space;-&space;{\beta&space;_4}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?{\beta&space;_{comp}}&space;=&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}&space;-&space;{\beta&space;_4}" title="{\beta _{comp}} = {\beta _2} + {\beta _3} - {\beta _4}" /></a>

Please note that the code automatically downloads the synthetic dataset from our online repository, there is no need to locate or download the dataset before running the code. 

---

## 3. Model illustration in SPSS

The SPSS script (FBOE_FFE_synthetic_data.sps) uses the same [synthetic dataset] to estimate several specifications of the model. Also in this case, the code automatically downloads the synthetic dataset from our online repository, so there is no need to locate or download the dataset before running the code.

The script is constrained to the bare essentials, because SPSS is more restrictive software than other commonly-used statistical packages. The key limitation is that **SPSS does not allow for testing of composite coefficients**. The most tractable way to test these composites is to re-arrange the model specification so that the tested coefficient appears directly in the regression equation. 

This is again illustrated on the example of the FBOE coefficient akin to [Blanchard & Lippa (2021)](https://pubmed.ncbi.nlm.nih.gov/33025292/). To test its statistical significance, we have to estimate an adjusted version of our preferred model specification with numbers of brothers replaced by numbers of sisters:

<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex=P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\delta}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\delta&space;}})}}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?P[{Y_i}&space;=&space;1\mid&space;{{\bf{x}}_i},{\bf{\delta}}]&space;=&space;\frac{1}{{1&space;&plus;&space;\exp&space;(&space;-&space;{{\bf{x}}_i}{\bf{\delta&space;}})}}" title="P[{Y_i} = 1\mid {{\bf{x}}_i},{\bf{\delta}}] = \frac{1}{{1 + \exp ( - {{\bf{x}}_i}{\bf{\delta }})}}" /></a>

<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex={{{\bf{x'}}}_i}{\bf{\delta&space;}}&space;=&space;{\delta&space;_0}&space;&plus;&space;{\delta&space;_1}N{(sib.)_i}&space;&plus;&space;{\delta&space;_2}N{(older\,sib.)_i}&space;&plus;&space;{\delta&space;_3}N{(older\,sis.)_i}&space;&plus;&space;{\delta&space;_4}N{(younger\,sis.)_i}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?{{{\bf{x'}}}_i}{\bf{\delta&space;}}&space;=&space;{\delta&space;_0}&space;&plus;&space;{\delta&space;_1}N{(sib.)_i}&space;&plus;&space;{\delta&space;_2}N{(older\,sib.)_i}&space;&plus;&space;{\delta&space;_3}N{(older\,sis.)_i}&space;&plus;&space;{\delta&space;_4}N{(younger\,sis.)_i}" title="{{{\bf{x'}}}_i}{\bf{\delta }} = {\delta _0} + {\delta _1}N{(sib.)_i} + {\delta _2}N{(older\,sib.)_i} + {\delta _3}N{(older\,sis.)_i} + {\delta _4}N{(younger\,sis.)_i}" /></a>

The coefficient <a href="https://www.codecogs.com/eqnedit.php?latex={\delta&space;_2}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?{\delta&space;_2}" title="{\delta _2}" /></a> is what we're looking for. The *ceteris paribus* condition implies that this coefficient approximates the increase in the probability associated with increasing the number of older siblings by one, while keeping the sibship size and the number of older and younger sisters fixed, which is equivalent to having one fewer younger brother and one more older brother.

For reference, here is a list of correspondence equations for the three listed sets of coefficients:

<p align="center">
<a href="https://www.codecogs.com/eqnedit.php?latex=\begin{array}{lll}&space;{{\beta&space;_1}&space;=&space;{\gamma&space;_4}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_4}}&{{\gamma&space;_1}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}\,&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_2}}&space;\,\,\,\&space;&{{\delta&space;_1}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_4}&space;=&space;{\gamma&space;_3}}&space;\\&space;{{\beta&space;_2}&space;=&space;{\gamma&space;_2}&space;-&space;{\gamma&space;_4}&space;=&space;{\delta&space;_2}&space;&plus;&space;{\delta&space;_3}&space;-&space;{\delta&space;_4}}&space;\,\,\,\&space;&{{\gamma&space;_2}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_2}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_2}&space;&plus;&space;{\delta&space;_3}}&{{\delta&space;_2}&space;=&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}&space;-&space;{\beta&space;_4}&space;=&space;{\gamma&space;_1}&space;-&space;{\gamma&space;_3}}&space;\\&space;{{\beta&space;_3}&space;=&space;{\gamma&space;_1}&space;-&space;{\gamma&space;_2}&space;=&space;-&space;{\delta&space;_3}}&{{\gamma&space;_3}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_4}&space;=&space;{\delta&space;_1}}&{{\delta&space;_3}&space;=&space;-&space;{\beta&space;_3}&space;=&space;{\gamma&space;_2}&space;-&space;{\gamma&space;_1}}&space;\\&space;{{\beta&space;_4}&space;=&space;{\gamma&space;_3}&space;-&space;{\gamma&space;_4}&space;=&space;-&space;{\delta&space;_4}}&{{\gamma&space;_4}&space;=&space;{\beta&space;_1}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_4}}&{{\delta&space;_4}&space;=&space;-&space;{\beta&space;_4}&space;=&space;{\gamma&space;_4}&space;-&space;{\gamma&space;_3}}&space;\end{array}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\begin{array}{lll}&space;{{\beta&space;_1}&space;=&space;{\gamma&space;_4}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_4}}&{{\gamma&space;_1}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}\,&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_2}}&space;\,\,\,\&space;&{{\delta&space;_1}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_4}&space;=&space;{\gamma&space;_3}}&space;\\&space;{{\beta&space;_2}&space;=&space;{\gamma&space;_2}&space;-&space;{\gamma&space;_4}&space;=&space;{\delta&space;_2}&space;&plus;&space;{\delta&space;_3}&space;-&space;{\delta&space;_4}}&space;\,\,\,\&space;&{{\gamma&space;_2}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_2}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_2}&space;&plus;&space;{\delta&space;_3}}&{{\delta&space;_2}&space;=&space;{\beta&space;_2}&space;&plus;&space;{\beta&space;_3}&space;-&space;{\beta&space;_4}&space;=&space;{\gamma&space;_1}&space;-&space;{\gamma&space;_3}}&space;\\&space;{{\beta&space;_3}&space;=&space;{\gamma&space;_1}&space;-&space;{\gamma&space;_2}&space;=&space;-&space;{\delta&space;_3}}&{{\gamma&space;_3}&space;=&space;{\beta&space;_1}&space;&plus;&space;{\beta&space;_4}&space;=&space;{\delta&space;_1}}&{{\delta&space;_3}&space;=&space;-&space;{\beta&space;_3}&space;=&space;{\gamma&space;_2}&space;-&space;{\gamma&space;_1}}&space;\\&space;{{\beta&space;_4}&space;=&space;{\gamma&space;_3}&space;-&space;{\gamma&space;_4}&space;=&space;-&space;{\delta&space;_4}}&{{\gamma&space;_4}&space;=&space;{\beta&space;_1}&space;=&space;{\delta&space;_1}&space;&plus;&space;{\delta&space;_4}}&{{\delta&space;_4}&space;=&space;-&space;{\beta&space;_4}&space;=&space;{\gamma&space;_4}&space;-&space;{\gamma&space;_3}}&space;\end{array}" title="\begin{array}{lll} {{\beta _1} = {\gamma _4} = {\delta _1} + {\delta _4}}&{{\gamma _1} = {\beta _1} + {\beta _2} + {\beta _3}\, = {\delta _1} + {\delta _2}} \,\,\,\ &{{\delta _1} = {\beta _1} + {\beta _4} = {\gamma _3}} \\ {{\beta _2} = {\gamma _2} - {\gamma _4} = {\delta _2} + {\delta _3} - {\delta _4}} \,\,\,\ &{{\gamma _2} = {\beta _1} + {\beta _2} = {\delta _1} + {\delta _2} + {\delta _3}}&{{\delta _2} = {\beta _2} + {\beta _3} - {\beta _4} = {\gamma _1} - {\gamma _3}} \\ {{\beta _3} = {\gamma _1} - {\gamma _2} = - {\delta _3}}&{{\gamma _3} = {\beta _1} + {\beta _4} = {\delta _1}}&{{\delta _3} = - {\beta _3} = {\gamma _2} - {\gamma _1}} \\ {{\beta _4} = {\gamma _3} - {\gamma _4} = - {\delta _4}}&{{\gamma _4} = {\beta _1} = {\delta _1} + {\delta _4}}&{{\delta _4} = - {\beta _4} = {\gamma _4} - {\gamma _3}} \end{array}" /></a>
