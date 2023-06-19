/*************************************************************************
 * STUDY DRUG:        
 * PROTOCOL NO:        
 * PROGRAMMER:        Arun Kumar
 * DATE CREATED:      
 * PROGRAM NAME:      t_caps5_totscr_mfasfl.sas
 * DESCRIPTION:       Primary Efficacy Endpoint, Change in CAPS5 
 * DATA SETS USED:    
 ***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer: Vijay Koduru
Date: 03Jun2020
Details: Change CMD label, decimals for LSM/CI, LMD to 2. Insert blank rows between sections.
*************************************************************************/;


*-----------------------------------------------------------------;
*INCLUDE THE TLF DEFAULTS FOR THE POPULATION AND DATASETS.;
*UPDATE ANY DEFAULTS AS REQUIRED FOR THE TABLE;
*-----------------------------------------------------------------;
/*
%include "_treatment_defaults-mITT.sas" ;
%include "_treatment_defaults-ess-mITT.sas" ; 
*/

PROC DATASETS LIB=WORK MEMTYPE=DATA KILL;QUIT;
options orientation=landscape missing=' ' nodate nonumber MPRINT;

   
   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;

   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl);

*-----------------------------------------------------------------;
*BIGN CALCULATION.;
*-----------------------------------------------------------------;

data adsl;
set adsl;
 SITEIDN=input(SITEID,best.);

 where MFASFL="Y";
 run;

 proc sort data=adsl;
 by siteidn;
 run;

 data adsl;
 set adsl;
 by siteidn;
 retain site_n 0;
 if first.siteidn then site_n=site_n+1;
 else site_n=site_n;
 run;;

  proc freq data=adsl noprint;
  table siteidn*site_n/out=sit nocol nopct;
  
  run;

   data ADSL;                             
      set ADSL(rename=(SITEIDN=SITE));                             
      where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A;                             
          SITEIDN=site_n;
 
   run;

%Macro stats_b(n=,SUBGRP_LAB=);
                             
    



DATA ADSL&n ;
 SET ADSL ;
 IF SITEIDN = &N ;
 RUN ;

DATA ADQS ;
 SET adam.ADQS ;

  where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("CGI0201") and avisitn in (0,12); 
   
 RUN ;

   *** Create TARGET dataset by combing the Working datasets ***;                          
   data ADQS ;                             
      merge ADSL(in= a) 
            ADQS (in= b );                             
      by studyid usubjid;* trtn trt;                             
      if a;
run;

data ADQS&N;
 set ADQS;
 IF SITEIDN = &N ; 
   run; 

data target;
set adam.adsl;


where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A;      
run;


   proc sql;
	  select * from ADQS&N;
	quit;

	%if &sqlobs. gt 0 %then %do;


** Create Treatment formats for reporting **;                             
   %jm_gen_trt_fmt;
*** Calculate the Big N denominator from adqsess by treatment ***;
%JM_BIGN(JM_INDSN=adsl&n,JM_CNTVAR=usubjid,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );
DATA JM_BIGN&N.;SET JM_BIGN1;RUN;

*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_SUM(JM_INDSN=adqs&N, jm_var=aval,  jm_bign=jm_bign1, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline),   JM_BLOCK=101&N,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=adqs&N, jm_var=aval,  jm_bign=jm_bign1, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 12 , JM_AVAL_LABEL=%bquote(End of Week 12),  JM_BLOCK=102&N,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=adqs&N, jm_var=chg,   jm_bign=jm_bign1, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12), JM_BLOCK=103&N,JM_SIGD=0 );



*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA&N);


%if %sysfunc(exist(JM_AVAL_ALLDATA&N)) %then %do;

data JM_AVAL_ALLDATA&N;
set  JM_AVAL_ALLDATA&N;

    if  JM_N=0 then do;
        JM_MEANSTDC="";
        JM_MEDIANC="";
        JM_RANGEC="";
        JM_Q1C_Q3C="";
	end;
run;
%end;

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata&N(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS&n, JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC  , 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC JM_RANGEC JM_Q1C_Q3C, 
   JM_TRANS_ID=JM_TRTVARN);


   
  proc sql noprint;
     select  count(distinct usubjid) into :Subj
     from ADQS&n ;
  quit;

	%if &subj >=20 %then %do;
*-----------------------------------------------------------------------------------------------------------------------------;
   * LS Means
*-----------------------------------------------------------------------------------------------------------------------------;

data dbrw_data;
      set ADQS&n ;
      if chg ne . and trtn in (1,2,3) and SITEIDN ne . ;
 run;
 proc sql;
	  select * from dbrw_data;
	;
quit;


%if &sqlobs. gt 0 %then %do;
proc glm data=dbrw_data;
class trtn SSNRISN;
model chg=trtn SSNRISN base / SS3;
lsmeans trtn/cl stderr diff;
ods output LSMeans=LSM_temp&n LSMeanCL=LSMEANCL&n;
run;
quit;

data LSM_temp1&n;
merge  LSM_temp&n
   LSMEANCL&n(keep=trtn lowercl uppercl);
   by trtn ;
   if lsmean ne . then LS_Mean=strip(put(round(lsmean,0.1),9.1));
   if stderr ne . then SE=strip(put(round(stderr,0.01),9.2));
    if lowercl ne . and uppercl ne . then   LS_MEANCL= compress('('||put(lowercl,9.2))||', '||compress(put(uppercl,9.2))||')';

	*if lsmean ne .;
run;

  

 proc sql;
	  select * from LSM_temp1&n;
	  where LS_Mean ne .;
	quit;

%if &sqlobs. gt 0 %then %do;

data dummy;
do i=1 to 3;
trtn=strip(put(i,best.));

output;
end;

run;

data lsm_temp1&n;
merge dummy lsm_temp1&n;
by trtn;
run;

proc transpose data=lsm_temp1&n out=LSM_stat&n;
id trtn;
var ls_mean se LS_MEANCL;
run;

data LSM_STAT&n ;
length JM_AVAL_LABEL _name_ _LABEL_ $200. ;
 SET LSM_STAT&n ;
 JM_BLOCK = "1103"||strip("&n")  ; JM_AVAL_LABEL = 'Change from Baseline' ;
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean' ; _LABEL_ = 'LS Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ; ord=6;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE_Mean' ; _name_ = 'SE_Mean';_LABEL_ = 'SE_Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ; ord=7;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=8;
 end;
 drop _1 _2 _3 ;
 RUN;

 proc sort data=LSM_STAT&n;
 by ord;
 run;

%end;
%end;
%else %do;
data LSM_STAT&n ;
  _name_="";
 JM_BLOCK = "103"||strip("&n")  ; JM_AVAL_LABEL = 'Change from Baseline' ;
 ord=0; trtn1="";
 trtn2="";
 output;

 run;
 %end;



************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;
** normality test: if p-value <0.05 at Shapiro-Wilk test, not normal distribution then use shift location/H-L estimate **;
** else use ranked ANCOVA **;

data dbrw_data;
      set ADQS&n ;
      if chg ne . and trtn in (1,2,3) and SITEIDN ne . ;
 run;

 data norm_data;
   set ADQS ;
      if chg ne . and trtn in (1,2,3) and SITEIDN ne . ;
 run;

ods select none;

PROC glm DATA=norm_data(where=(chg ne . and trtn in (1,2,3) ));
class trtn  SSNRISN;
model chg=trtn  SSNRISN base;
  output out=rsd_data p=p r=resid ;  
RUN;
quit;

proc univariate data=rsd_data normal;
  var resid;
  ods output TestsForNormality=d_normtst(where=(Test="Shapiro-Wilk"));
run;
ods select all;

** setup macro to run LSMean based on p-value from normality test **;

   proc sql noprint;
      select pvalue into :pval
      from d_normtst
      ;
   quit;
   %put &pval.;
   
   %if &pval.<0.05 %then %do;

   ** shift location, H-L Estimate **;
      /*data dbrw_data;
      set ADQSESS ;
         if chg_sd_db = 1 and trtn in (1,2) ;
      run;*/
   
 

      
      * H-L estimate and 95% CI;
      **check for #of levels of class variables and #of obs **;
		proc sql noprint;
			select count(distinct trt01p) into: nclslev
			from dbrw_data;
		quit;
     ods trace on;
	  %if &nclslev. gt 2 %then %do;
	  		%do trtlev=1 %to 2;
			     ods select none;
         proc rank data=dbrw_data out=ranked ties=mean;
             var  base chg;
            ranks rbase rchg;
			where trtn in(&trtlev.,3);
            run;

			PROC GLM DATA=RANKED ;
              CLASS trtn SITEIDN;
              MODEL rchg = trtn SITEIDN rbase / SS3 ;
              lsmeans trtn/cl diff;
              ods output ModelANOVA=zzMANOVA&trtlev. (where=(source="trtn")) ;
               RUN;
            quit;

			   data zzzMANOVA&trtlev.;
				set zzMANOVA&trtlev.;
                  trtn=&trtlev.;
				run;

					proc sql noprint;
			        	create table hl_chk as
			        	select count(distinct trt01p) as clslev, count(*) as nobs
			        	from dbrw_data where trtn in(&trtlev.,3);
		      	quit;

			      data _null_;
			        set hl_chk;
			       if clslev lt nobs then call symput("HODGES_YES",'Y');
			        else call symput("HODGES_YES",'N');
					  call symput("nclslev",strip(put(clslev,best.)));
			      run;
			      %if &hodges_yes=Y %then %do;
						proc sql noprint;
			        	create table hl_chk as
			        	select count(distinct trt01p) as clslev, count(*) as nobs
			        	from dbrw_data where trtn in(&trtlev.,3);
			      	quit;
				        proc npar1way data=dbrw_data hl(refclass="Placebo");
				          class /*trtn*/ trt01p;
							 where trtn in(&trtlev.,3);
				            var chg;
				          ods output HodgesLehmann=zzHLdata&trtlev.;
				        run;
				       ods trace off;
				      data zzzHLestimate&trtlev.;
				      set zzHLdata&trtlev.;

					  ord=&trtlev.;
				      drop variable type;
				      format shift midpoint 9.4 stderr lowerCL upperCL 9.4 ;
				      run;
                      data zzzHLdata&trtlev.;
				      set zzHLdata&trtlev.;

					   trtn=&trtlev.;
				      drop variable type;
				      format shift midpoint 9.4 stderr lowerCL upperCL 9.4 ;
				      run;

					%end;
				%end;
					data hlestimate;
					set zzzhlestimate:;

					trtn=&trtlev.;
					run;
					data hldata;
					set zzzhldata:;
					run;

                data MANOVA;
				set zzzMANOVA:;
               
				run;


				data LSM_data;
				merge HLdata(keep=trtn shift lowerCL upperCL)
				      Manova(keep=trtn probf);
				   by trtn;
				     format shift 9.4;
					 	
                run;


			%end;
			%else %do;

          proc sql noprint;
           create table mtrtn as
	       select distinct trtn as ord
	        from dbrw_data ;
	      quit;

		  
		  data mtrtn;
		  set mtrtn;
		  trtn=ord;

		  drop ord;
		  run;


		    ods select none;
         proc rank data=dbrw_data out=ranked ties=mean;
             var  base chg;
            ranks rbase rchg;
		
            run;

			PROC GLM DATA=RANKED ;
              CLASS trtn SSNRISN;
              MODEL rchg = trtn SSNRISN rbase / SS3 ;
              lsmeans trtn/cl diff;
              ods output ModelANOVA=MANOVA (where=(source="trtn")) ;
               RUN;
            quit;


			    data MANOVA;
				merge MANOVA mtrtn(where =(trtn ne 3));
               
				run;

			    proc sql noprint;
			        create table hl_chk as
			        select count(distinct trt01p) as clslev, count(*) as nobs
			        from dbrw_data ;
			      quit;

			      data _null_;
			        set hl_chk;
			       if clslev lt nobs then call symput("HODGES_YES",'Y');
			        else call symput("HODGES_YES",'N');
					  call symput("nclslev",strip(put(clslev,best.)));
			      run;
					%put &nclslev.;
			      %put &hodges_yes.;
			      %if &hodges_yes=Y %then %do;
						proc npar1way data=dbrw_data hl(refclass="Placebo");
					          class /*trtn*/ trt01p;
					            var chg;
					          ods output HodgesLehmann=HLdata;
					        run;
					       ods trace off;
					      data HLestimate;
					      set HLdata;
					      drop variable type;
					      format shift midpoint 9.4 stderr lowerCL upperCL 9.4 ;
					      run;


				       data HLdata;
				        merge HLdata mtrtn(where =(trtn ne 3));
                       run; 
                      data HLestimate;
				       merge HLestimate  mtrtn(where =(trtn ne 3));
                      run;


					data LSM_data;
				      merge HLdata(keep=trtn shift lowerCL upperCL)
				      Manova(keep=trtn probf);
				   by trtn;
				     format shift 9.4;

					

                run;
             %end;
            %else %if &hodges_yes=N %then %do;

			data LSM_data;
			 do trtn=1 to 2;
                 shift=.;
                 lowercl=.;
                 uppercl=.;
                 probf=.;
		    end;
			run;
           %end;  
		%end;
    

      ods select all;
      /*title3 "shift, 95% CI, p-value";
      proc print; run;*/

      ** LSM dataset **;
      data lsmd1(keep= trtn LSM_lbl1) lsmd2(keep=trtn ci_95p) lsmd3(keep=trtn p_value) lsmd4(keep= trtn lsm_lbl2);
      set LSM_data;
         *aperiod=99;
         LSM_lbl1=compress(put(shift,9.2)); output lsmd1;
         if lowercl ne .  and uppercl ne . then CI_95p=compress('('||put(lowercl,9.2))||', '||compress(put(uppercl,9.2))||')'; output lsmd2;
         p_value=tranwrd(compress(put(probf,pvalue6.4)),'<.','<0.'); output lsmd3;
         lsm_lbl2=' '; output lsmd4;  ** reserve as blank to keep dataset consistent for H-L est and ANCOVA **;
      run;

      data lsmd_out_&n;
      set lsmd1 lsmd4 lsmd2 lsmd3;
         length value  _name_ $20 ;
         *aperiod=99;
         if lsm_lbl1 ne ' ' then do; _name_='Shift'; ord=11; value=lsm_lbl1; end;
         if lsm_lbl2 ne ' ' then do; _name_='SE_Dif'; ord=12; value=lsm_lbl2; end;
         if CI_95p ne ' ' then do; _name_='95% CI'; ord=13; value=CI_95p; end;
         if p_value ne ' ' then do; _name_='p-value'; ord=14; value=p_value; end;
         *keep /*aperiod*/ _name_ JZP258 ord;

		 desc=_name_;
		 if ord ne .;
      run;
      proc sort data=lsmd_out_&n;
	  by ord desc trtn;
      run;

	  proc transpose data=lsmd_out_&n out=lsmd_out&n prefix=trtn;
	  by ord desc;
	  var value;
	  id trtn;
	  run;

   %end;
  
  
   %else %if &pval.>=0.05 %then %do;   ** ANCOVA **;
      ods select none;

   ** LS MEAN DIFF, SE, 95% CI, p-value between trt **;


      PROC GLM DATA = dbrw_data;
      CLASS trtn SSNRISN ;
      MODEL chg = trtn SSNRISN base / SS3 ;
      lsmeans trtn/diff stderr cl ;
      estimate 'JZP 150 A vs Placebo' trtn 1 0 -1;
      estimate 'JZP 150 B vs Placebo' trtn 0 1 -1;
      ods output ModelANOVA=Model_ANOVA  LSMeans=LSMeansdiff&n/*(keep=probtdiff)*/ Diff=LSMdiff&n LSMeanDiffCL=LSMdiff_CL&n/*(keep=difference lowercl uppercl)*/ 
         estimates=LSMse&n;
      RUN;
      quit;


	  %if %sysfunc(exist(LSMse&n)) %then %do;
      data LSMse&n;
      set LSMse&n;
      if parameter="JZP 150 A vs Placebo" then trtn=1;
      else trtn=2;
      run;

     %end;


	    %if %sysfunc(exist(LSMeansdiff&n)) %then %do;
      data LSMeansdiff&n;
      set LSMeansdiff&n(rename=(trtn=trtc));

      trtn=input(trtc,best.);
	  iprobt=probt;
	  keep trtn iprobt;
      run;
      %end;


	   %if %sysfunc(exist(LSMdiff&n)) %then %do;
      data LSMdiff&n;
      set LSMdiff&n;

           trtn=input(rowname,best.);
		 probt=_3;
		 if trtn in (1,2);
	keep trtn probt;
      run;
      %end;
      
      
	  %if %sysfunc(exist(LSMDIFF_CL&n)) %then %do;
      data LSMDIFF_CL&n;
      set LSMDIFF_CL&n;
      if (trtn=1 and _trtn=3) or (trtn=2 and _trtn=3);
      run;
       %end;

 %if  %sysfunc(exist(LSMse&n)) and %sysfunc(exist(LSMeansdiff&n)) and %sysfunc(exist(LSMdiff&n)) and %sysfunc(exist(LSMDIFF_CL&n))  %then %do;
      data LSMdiff_stat&n;
      merge LSMeansdiff&n(in=a keep= trtn  iprobt) 
            LSMdiff&n(in=a keep= trtn  probt)
            LSMDIFF_CL&n(in=b keep=trtn difference lowercl uppercl)
              LSMse&n(in=c keep=trtn StdErr);
      by trtn;

       LS_Mean_Diff=difference;
      SE=StdErr;
       LCL=lowercl;
      UCL=uppercl;
      p_value=probt;
	  ip_value=iprobt;


      if trtn in (1,2);

      format LS_Mean_Diff  9.1  SE 9.2 LCL 9.1 UCL 9.1 p_value ip_value  7.4;
      keep trtn LS_Mean_Diff SE LCL UCL p_value ip_value;
  run;
%end;

   %else %do;
   data LSMdiff_stat&n;
      
   	  do trtn=1 to 2;
       LS_Mean_Diff=.;
       SE=.;
       LCL=.;
      UCL=.;
      p_value=.;
	  output;
    end;

      if trtn in (1,2);

      format LS_Mean_Diff  9.1  SE 9.2 LCL 9.1 UCL 9.1 p_value  7.4;
      keep trtn LS_Mean_Diff SE LCL UCL p_value;
  run;
%end;
      
      ods select all;
      /*title3 "LS MEAN DIFF, SE, 95% CI, P-value";
      proc print data=lsmdiff_stat; run;*/

      
      data lsmd0(keep= trtn ip_value) lsmd1(keep= trtn lsm_lbl1) lsmd2(keep= trtn ci_95p) lsmd3(keep= trtn p_value) lsmd4(keep= trtn lsm_lbl2);
      set lsmdiff_stat&n(rename=(ls_mean_diff=lsmdiff_o ip_value=ipval p_value=pval se=o_se));
         *aperiod=99;
	  if ipval ne . then ip_value=tranwrd(compress(put(ipval,pvalue6.4)),'<.','<0.'); output lsmd0;
         if lsmdiff_o ne . then lsm_lbl1=compress(put(lsmdiff_o,9.1)); output lsmd1;
         if lcl ne . and ucl ne . then CI_95p=compress('('||put(lcl,9.1))||', '||compress(put(ucl,9.1))||')'; output lsmd2;
         if pval ne . then p_value=tranwrd(compress(put(pval,pvalue6.4)),'<.','<0.'); output lsmd3;
         if o_se ne . then lsm_lbl2=compress(put(o_se,9.2)); output lsmd4;
      run;

      data lsmd_out&n;
	   length JZP150 $20.  _name_ $50 ;
      set lsmd0 lsmd1 lsmd4 lsmd2 lsmd3;
        
         *aperiod=99;

		if ip_value ne ' ' then do; _name_='Interaction Term p-value Estimated at Week 12'; ord=10.5; JZP150=ip_value; end;

         if lsm_lbl1 ne ' ' then do; _name_='LS Mean Diff'; ord=11; JZP150=lsm_lbl1; end;
         if lsm_lbl2 ne ' ' then do; _name_='SE_Dif'; ord=12; JZP150=lsm_lbl2; end;
         if CI_95p ne ' ' then do; _name_='95% CI'; ord=13; JZP150=CI_95p; end;
         if p_value ne ' ' then do; _name_='p-value'; ord=14; JZP150=p_value; end;

      	 if _name_ ne "";

		     desc=_name_;
         *keep avisit _name_ JZP150 ord;
      run;

	 proc sql;
	  select * from lsmd_out&n;
	quit;

%if &sqlobs. gt 0 %then %do;
      proc transpose data=lsmd_out&n out=tr_lsmd_out prefix=trtn;
      by ord name;
      var JZP150;
      id trtn;
      run;

data LSMD_OUT&n ;
 set tr_lsmd_out(keep=ord name trtn1 trtn2);
 _name_=name;
 run;

%end;
%else %do;


data LSMD_OUT&n ;
 set LSMD_OUT&n;*(keep=ord name trtn1 trtn2);
 _name_="";

 ord=0; trtn1="";
 trtn2="";
 output;

 run;
 %end;

 %let hodges_yes=Y;
%end;

%if &hodges_yes ne N %then %do;
data LSMD_OUT&n ;
 length jm_aval_label SITEID $200 ;
   SITEID="&SUBGRP_LAB.";
 set  LSMD_OUT&n  ;

   _name_=desc;

if _name_ ^= ' ' then do ; 
  JM_BLOCK = "2103"||strip("&n") ;
  JM_AVAL_LABEL = 'Change from Baseline' ;
  JM_AVAL_NAMEC = _name_ ;
  _LABEL_ = _name_ ;
 end;

 if _name_ = 'Shift' then do ;
  JM_AVAL_NAMEC = 'EMD' ; 
 _LABEL_ = 'Estimated Median difference' ;
 _NAME_ = 'EMD' ;
 end;

 keep jm_block JM_AVAL_LABEL JM_AVAL_NAMEC _NAME_ _LABEL_ trtn1 trtn2 SSNRIS ord;
 RUN;
%end;



 Data final&n ;
  length jm_aval_label SITEID $200 ;
  set JM_AVAL_TRANS&n LSM_STAT&n %if &hodges_yes ne N %then %do; LSMD_OUT&n %end; ;
    if jm_aval_label = 'Change from Baseline' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
   * jm_block="1039" ;
  end;
  SITEID="&SUBGRP_LAB.";
  
  if ord ne . and TRTn1 ="" and trtn2="" and trtn3="" then delete;

  RUN ;

proc sort data = final&n nodupkey ;
   by _all_ ;
  run ;


  proc sort data=final&n;
  by jm_block ord;
  run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL&n,  JM_INDSN2= , JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT&N);

data jm_aval_allreport&N;
 set jm_aval_allreport&N;
by jm_block;

 if ord ne . and GROUPVARN=. then do;
GROUPVARN=ord;
jm_aval_namen=ord;
end;

 if ord ne . and GROUPVARN=9 then do;
GROUPVARN=ord;
jm_aval_namen=ord;
end;
run;


proc sort data=jm_aval_allreport&N;
by jm_block GROUPVARN;
run;


data jm_aval_allreport&N;
 set jm_aval_allreport&N;
by jm_block GROUPVARN;



if _name_="JM_NC" then do;
 if trtn1="" then trtn1="0";
 if trtn2="" then trtn2="0";
 if trtn3="" then trtn3="0";
 end;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
   if jm_aval_namec="LS_MEAN" then jm_aval_namec="95% CI";

   IF _NAME_ = ' ' THEN DELETE ;

    if last.jm_block then jm_aval_namec=strip(jm_aval_namec)||'^n';
run;


proc sort data=jm_aval_allreport&N;
by pageno jm_block GROUPVARN;
run;
data jm_aval_allreport&N;
 set jm_aval_allreport&N;


  orig_rec_num=_n_;
   jm_aval_namen=orig_rec_num;


  block = substr(Jm_block,1,4) ;
  if block in ("101&n") then pageno=1;
  if block in ("102&n") then pageno=2;
   if block in ("103&n") then pageno=3;
  if block in ("1103") and jm_block  in ("1103&n") then pageno=3;
  if block in ("2103") and jm_block  in ("2103&n") then pageno=4;


  if  jm_aval_label = "Change from Baseline to End of Week 12"  then jm_block="103&n";
run;

proc sort data=jm_aval_allreport&N;
by pageno jm_block jm_aval_namen;
run;

**Vijay added below code to save datasets for reporting **;
data final_subgrp_&n.;
  set Jm_aval_allreport&n.;
drop _name_;
run;

data final_bign_&n.;
  set jm_bign&n.;
run;
%end;
%else %do;

 %if %sysfunc(exist(JM_AVAL_TRANS&n)) %then %do;
 Data final&n ;
  length jm_aval_label SITEID $200 ;
  set JM_AVAL_TRANS&n;
    if jm_aval_label = 'Change from Baseline' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    *jm_block="1039" ;
  end;
  SITEID="&SUBGRP_LAB.";
  
  if ord ne . and TRTn1 ="" and trtn2="" and trtn3="" then delete;
run;


proc sort data = final&n nodupkey ;
   by _all_ ;
  run ;


  proc sort data=final&n;
  by jm_block ord;
  run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL&n,  JM_INDSN2= , JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT&N);

data jm_aval_allreport&N;
 set jm_aval_allreport&N;
by jm_block;

 if ord ne . and GROUPVARN=. then do;
GROUPVARN=ord;
jm_aval_namen=ord;
end;

 if ord ne . and GROUPVARN=9 then do;
GROUPVARN=ord;
jm_aval_namen=ord;
end;
run;


proc sort data=jm_aval_allreport&N;
by jm_block GROUPVARN;
run;


data jm_aval_allreport&N;
 set jm_aval_allreport&N;
by jm_block GROUPVARN;



if _name_="JM_NC" then do;
 if trtn1="" then trtn1="0";
 if trtn2="" then trtn2="0";
 if trtn3="" then trtn3="0";
 end;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
   if jm_aval_namec="LS_MEAN" then jm_aval_namec="95% CI";

   IF _NAME_ = ' ' THEN DELETE ;

    if last.jm_block then jm_aval_namec=strip(jm_aval_namec)||'^n';
run;


proc sort data=jm_aval_allreport&N;
by pageno jm_block GROUPVARN;
run;
data jm_aval_allreport&N;
 set jm_aval_allreport&N;


  orig_rec_num=_n_;
   jm_aval_namen=orig_rec_num;


  block = substr(Jm_block,1,4) ;
  if block in ("101&n") then pageno=1;
  if block in ("102&n") then pageno=2;
   if block in ("103&n") then pageno=3;
  if block in ("1103") and jm_block  in ("1103&n") then pageno=3;
  if block in ("2103") and jm_block  in ("2103&n") then pageno=4;


  if  jm_aval_label = "Change from Baseline to End of Week 12"  then jm_block="103&n";
run;

proc sort data=jm_aval_allreport&N;
by pageno jm_block jm_aval_namen;
run;

**Vijay added below code to save datasets for reporting **;
data final_subgrp_&n.;
  set Jm_aval_allreport&n.;
drop _name_;
run;

data final_bign_&n.;
  set jm_bign&n.;
run;
%end;
%else %do;
   %jm_gen_trt_fmt;
*** Calculate the Big N denominator from adqsess by treatment ***;
%JM_BIGN(JM_INDSN=adsl,JM_CNTVAR=usubjid,jm_suffix=0, jm_trtvarn=trtn, jm_trtfmt=trt );
DATA JM_BIGN&n.;SET JM_BIGN0;


JM_AVAL_BIGN=0;
JM_AVAL_BIGN_LABEL=TRTVAR||" |"||"(N=0)";

RUN;

	  data _null_;
	    set jm_bign&n. end=eos;
		 length trttxt $100;
		 if _n_=1 then trttxt='trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 else trttxt=strip(trttxt)||'trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 retain trttxt;
		 if eos then call symputx("trtimp",strip(trttxt));
		run;


data final_bign_&n.;
  set jm_bign&n.;
run;
		data final_subgrp_&n.;
			_TYPE_='COUNT';
			jm_aval_namec='No data to report';
			jm_aval_label='No data to report';
			jm_aval_namec="";
			jm_block='10'||strip("&N.");
			jm_aval_countc='';
			pageno=1;
			&trtimp.;
			SITEID="&SUBGRP_LAB.";
			 drop _name_;

		run;
	%end;                       

%end;


%end;
	%else %do;

	   %jm_gen_trt_fmt;
*** Calculate the Big N denominator from adqsess by treatment ***;
%JM_BIGN(JM_INDSN=adsl,JM_CNTVAR=usubjid,jm_suffix=0, jm_trtvarn=trtn, jm_trtfmt=trt );
DATA JM_BIGN&n.;SET JM_BIGN0;


JM_AVAL_BIGN=0;
JM_AVAL_BIGN_LABEL=TRTVAR||" |"||"(N=0)";

RUN;

	  data _null_;
	    set jm_bign&n. end=eos;
		 length trttxt $100;
		 if _n_=1 then trttxt='trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 else trttxt=strip(trttxt)||'trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 retain trttxt;
		 if eos then call symputx("trtimp",strip(trttxt));
		run;


data final_bign_&n.;
  set jm_bign&n.;
run;
		data final_subgrp_&n.;
			_TYPE_='COUNT';
			jm_aval_namec='No data to report';
			jm_aval_label='No data to report';
			jm_aval_namec="";
			jm_block='100';
			jm_aval_countc='';
			pageno=1;
			&trtimp.;
			SITEID="&SUBGRP_LAB.";
			 drop _name_;

		run;
	%end;                       
%mend ;

%stats_b(N=1,SUBGRP_LAB=%str(SITE : 1063 ));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;


%stats_b(N=2,SUBGRP_LAB=%str(SITE : 1160));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;


%stats_b(N=3,SUBGRP_LAB=%str(SITE : 1303));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=4,SUBGRP_LAB=%str(SITE : 1358));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;
%stats_b(N=5,SUBGRP_LAB=%str(SITE : 1381));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;
%stats_b(N=6,SUBGRP_LAB=%str(SITE : 1399));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=7,SUBGRP_LAB=%str(SITE : 1659));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;
%stats_b(N=8,SUBGRP_LAB=%str(SITE : 1760));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=9,SUBGRP_LAB=%str(SITE : 1766));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=10,SUBGRP_LAB=%str(SITE : 1768));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;


%stats_b(N=11,SUBGRP_LAB=%str(SITE : 1861));
proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=12,SUBGRP_LAB=%str(SITE : 1969));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;
 
%stats_b(N=13,SUBGRP_LAB=%str(SITE : 1973));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=14,SUBGRP_LAB=%str(SITE : 1983));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;


%stats_b(N=15,SUBGRP_LAB=%str(SITE : 1986));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

%stats_b(N=16,SUBGRP_LAB=%str(SITE : 1990));

proc datasets lib=work memtype=data ;
save adqs: adsl:  jm_tf: final_subgrp_: final_bign:;
quit;run;

proc format lib=work;select jmntrtf;run;

%LET _default_box=Timepoint;

%macro subgrp_rep;
*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;
%global trtlab1 trtlab2 trtlab3;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);
  %do myrep = 1 %to 16;

   data jm_aval_allreport&myrep.;
     set final_subgrp_&myrep.;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_RANGEC','SE_MEAN') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);
   run;
   data jm_bign1;
     set final_bign_&myrep.;
   run;
   %let trtlab1=;%let trtlab2=;%let trtlab3=;
   DATA _NULL_;
     SET JM_BIGN1;
     call symput("TRTLAB"||strip(put(_n_,best.)),strip(jm_aval_bign_label));
   run;
   %put &trtlab1. &trtlab2. &trtlab3.;
/*PROC SORT data=jm_aval_allreport&myrep.;
by jm_block jm_aval_namen;
run;
data jm_aval_allreport&myrep.;
set jm_aval_allreport&myrep.;
by jm_block jm_Aval_namen;
output;
if first.jm_block then do;
	jm_aval_namec=strip(jm_aval_label);
	jm_Aval_namen=0;
	array myarr{*} trtn:;
	do i=1 to dim(myarr);
		myarr(i)='';
	end;
	output;
end;
drop i;
run;
PROC SORT data=jm_aval_allreport&myrep.;
by jm_block jm_aval_namen;
run;
*/
options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
title%eval(&lasttitlenum.+1) j=l "#BYVAL(SITEID)";

   %JM_AVAL_REPORT (JM_INDSN=jm_aval_allreport&myrep.,JM_BYVAR= SITEID, JM_BIGNDSN=Jm_bign1, 
	jm_spanheadopt=Y , JM_CELLWIDTH=2.0in,JM_TRTWIDTH=0.8in,
   JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=jm_aval_label);
   %let trtlab1=;%let trtlab2=;%let trtlab3=;
  %end;
%JM_ODSCLOSE;
%mend;
%subgrp_rep;


data final_subgrp_all;

length  TRTN1-TRTN3 $200.;
set final_subgrp_:;
SITEIDN=input(compress(SITEID,"SITE : "),best.);
jm_aval_namec_o=strip(_LABEL_);

keep JM_: TRTN: SITEID SITEIDN jm_aval_namec_o;
run;
proc sort data=final_subgrp_all;
by SITEIDN JM_BLOCK;
run;


%let dsname=T_9_02_02_03_05;
data tlfdata.&dsname;
set final_subgrp_all;
run;
