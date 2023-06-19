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

%Macro stats_b(n=,SUBGRP_LAB=);
   data ADSL;                             
      set ADSL;                             
      where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A;                             
                            
   run;                             
    

DATA ADSL&n ;
 SET ADSL ;
 IF SSNRISN = &N ;
 RUN ;

DATA ADQS ;
 SET adam.ADQS ;

  where /*TRT01AN in (1,2,3) and*/  MFASFL='Y' and paramcd in ("CGI0201") and .<avisitn<=12 and ANL01FL="Y"; 
   
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
 IF SSNRISN =  &N ; 
   run; 

data target;
set adam.adsl;

where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A;      
run;



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


data JM_AVAL_ALLDATA&N;
set JM_AVAL_ALLDATA&N;
if JM_NC="0" then do;

   JM_MEANSTDC="";
   JM_MEDIANC=""; 
   JM_Q1C_Q3C=""; 
   JM_RANGEC="";
end;
run;


   

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata&N(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS&n, JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC  , 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC JM_RANGEC JM_Q1C_Q3C, 
   JM_TRANS_ID=JM_TRTVARN);


    %if %sysfunc(exist(JM_AVAL_TRANS&n)) %then %do; 
   data JM_AVAL_TRANS&n;
   set JM_AVAL_TRANS&n;

         if _NAME_="JM_NC"  then ord=1;
   else  if _NAME_="JM_MEANSTDC"  then ord=2;
   else  if _NAME_="JM_MEDIANC"  then ord=3;
   else  if _NAME_="JM_Q1C_Q3C"  then ord=4;
   else  if _NAME_="JM_RANGEC"  then ord=5;
   SSNRISN=&N;
 run;

%end;

%mend ;
%stats_b(N=1,SUBGRP_LAB=%str(Concomitant use Of SSRIs and SNRIs = Presence));


%stats_b(N=2,SUBGRP_LAB=%str(Concomitant use Of SSRIs and SNRIs = Absence));




*-----------------------------------------------------------------------------------------------------------------------------;
   * LS Means
*-----------------------------------------------------------------------------------------------------------------------------;
data dbrw_data;
      set ADQS ;
      if chg ne . and trtn in (1,2,3) and AGEGR1N ne . ;
    	id=subjid;

		if avisitn=12 then wk12=1 ; 
       else wk12=0;

	  if 45 < age  then age1=1;
      else age1=0;
 run;

ods trace on;


proc mixed data=dbrw_data;
class id avisitn  trtn SSNRISN wk12;
model chg=base trtn wk12  SSNRISN base*wk12 SSNRISN*trtn trtn*wk12 SSNRISN*wk12 SSNRISN*trtn*wk12/ddfm=kr residual outp=residual;
repeated avisitn/type=un sub=id;/*unstructured covariance*/
lsmeans trtn*SSNRISN/ cl alpha=0.05 ;

ods output LSMeans=LSM_temp  ;
run;

ods trace off;


proc sort data =LSM_temp;
by SSNRISN trtn;
run;


data LSM_temp1;
set   LSM_temp;
   by SSNRISN trtn ;
   if Estimate ne . then LS_Mean=strip(put(round(Estimate,0.1),9.1));
   if stderr ne . then SE=strip(put(round(stderr,0.01),9.2));
    if lower ne . and upper ne . then   LS_MEANCL= compress('('||put(lower,9.1))||', '||compress(put(upper,9.1))||')';

   *if lsmean ne .;
run;


proc transpose data=lsm_temp1 out=LSM_stat ;
id trtn;
var ls_mean se LS_MEANCL;
by SSNRISN;
run;

data LSM_STAT ;
length JM_AVAL_LABEL  JM_AVAL_NAMEC $200. _name_ _LABEL_ $40.;
 SET LSM_STAT ;
 JM_BLOCK = "103"  ; JM_AVAL_LABEL = 'Change from Baseline' ;
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

 proc sort data=LSM_STAT;
 by SSNRISN ord;
 run;




************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;
** normality test: if p-value <0.05 at Shapiro-Wilk test, not normal distribution then use shift location/H-L estimate **;
** else use ranked ANCOVA **;

data dbrw_data;
      set ADQS ;
      if chg ne . and trtn in (1,2,3) and SSNRISN ne . ;
    	id=subjid;

		if avisitn=12 then wk12=1 ; 
       else wk12=0;

       if trtn=1 then trtn1=1;
	   else if trtn=3 then trtn1=0;
	   
	   if trtn=2 then trtn2=1;
	   else if trtn=3 then trtn2=0;

	   if SSNRISN=1 then SSNRISN1=1;
	   else if SSNRISN=2 then SSNRISN1=0; 
 run;

 data norm_data;
   set ADQS ;
      if chg ne . and trtn in (1,2,3) and SSNRISN ne . ;
 run;

 ods trace on ;
proc mixed data=dbrw_data;
where trtn in (1,3);
class id avisitn ;
model chg=base trtn1 wk12 SSNRISN1  base*wk12 SSNRISN1*trtn1 trtn1*wk12 SSNRISN1*wk12 SSNRISN1*trtn1*wk12/ddfm=kr residual outp=residual;
repeated avisitn/type=un sub=id;/*unstructured covariance*/
estimate "1 ACT-PBO  Week 4" trtn1 1 SSNRISN1*trtn1 1/cl alpha=0.05;
estimate "2 ACT-PBO  Week 4" trtn1 1/cl alpha=0.05;
estimate "1 ACT-PBO  Week 12" trtn1 1 trtn1*wk12 1 SSNRISN1*trtn1 1 SSNRISN1*trtn1*wk12 1/cl alpha=0.05;
estimate "2 ACT-PBO  Week 12" trtn1 1 trtn1*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" SSNRISN1*trtn1 1;
contrast "Treatment*Week 12*Subgroup Interaction" SSNRISN1*trtn1 1 SSNRISN1*trtn1*wk12 1;
ods output estimates=LSM_est1 contrasts=LSM_intr1  ;
run; *this part will generate lsmeans differences;


proc mixed data=dbrw_data;
where trtn in (2,3);
class id avisitn ;
model chg=base trtn2 wk12 SSNRISN1  base*wk12 SSNRISN1*trtn2 trtn2*wk12 SSNRISN1*wk12 SSNRISN1*trtn2*wk12/ddfm=kr residual outp=residual;
repeated avisitn/type=un sub=id;/*unstructured covariance*/
estimate "1 ACT-PBO    Week 4" trtn2 1 SSNRISN1*trtn2 1/cl alpha=0.05;
estimate "2 ACT-PBO  Week 4" trtn2 1/cl alpha=0.05;
estimate "1 ACT-PBO  Week 12" trtn2 1 trtn2*wk12 1 SSNRISN1*trtn2 1 SSNRISN1*trtn2*wk12 1/cl alpha=0.05;
estimate "2 ACT-PBO  Week 12" trtn2 1 trtn2*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" SSNRISN1*trtn2 1;
contrast "Treatment*Week 12*Subgroup Interaction" SSNRISN1*trtn2 1 SSNRISN1*trtn2*wk12 1;
ods output estimates=LSM_est2  contrasts=LSM_intr2  ;
run; *this part will generate lsmeans differences;
ods trace off;


data LSM_est1;
set LSM_est1;
trtn=1;
run;

data LSM_est2;
set LSM_est2;
trtn=2;
run;


data LSM_intr1;
set LSM_intr1;
trtn=1;
run;

data LSM_intr2;
set LSM_intr2;
trtn=2;
run;


data LSM_est;
set LSM_est1 LSM_est2;
if label in ("1 ACT-PBO  Week 12","2 ACT-PBO  Week 12");
     if label="1 ACT-PBO  Week 12" then SSNRISN=1;
else if label="2 ACT-PBO  Week 12" then SSNRISN=2;
run;

proc sort data =LSM_est;
by SSNRISN trtn;
run;


data lsmdiffs1;
set   LSM_est;
   by SSNRISN trtn ;
   if Estimate ne . then LS_Mean=strip(put(round(Estimate,0.1),9.1));
   if stderr ne . then SE=strip(put(round(stderr,0.01),9.2));
    if lower ne . and upper ne . then   LS_MEANCL= compress('('||put(lower,9.1))||', '||compress(put(upper,9.1))||')';

	if Probt ne . then P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');

   *if lsmean ne .;
run;

proc transpose data=lsmdiffs1 out=lsmdiffs_stat;
by SSNRISN;
id trtn;
var ls_mean se LS_MEANCL  P_VALUE;
run;


data lsmdiffs_stat;
length JM_AVAL_LABEL  JM_AVAL_NAMEC $200. trtn1 trtn2 _name_ _LABEL_ $40.;
 SET lsmdiffs_stat ;
 JM_BLOCK = '105' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean Diff' ; _LABEL_ = 'LS Mean Diff' ; trtn1 = _1 ; trtn2 = _2 ;ord=10;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE' ; _name_ = 'SE_Mean_diff';_LABEL_ = 'SE' ; trtn1 = _1 ; trtn2 = _2 ;ord=11;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;ord=12;
 end;

  if _name_ = 'P_VALUE' then do ;
 JM_AVAL_NAMEC = 'p-value' ; _name_ = 'P_VALUE';_LABEL_ = 'P-VALUE' ; trtn1 = _1 ; trtn2 = _2 ;ord=13;
 end;
 drop _1 _2 ;
 RUN;



data lsmdiffs_out;
	set lsmdiffs_stat;
run;


/******Interaction Value******/


data LSM_intr;
set LSM_intr1 LSM_intr2;
if label in ("Treatment*Week 12*Subgroup Interaction");
     if label="Treatment*Week 12*Subgroup Interaction" then SSNRISN=1;
else if label="Treatment*Week 12*Subgroup Interaction" then SSNRISN=2;
run;


data LSM_intr_1;
set LSM_intr(in=a) LSM_intr(in=b);
if b then SSNRISN=2;
run;



proc sort data =LSM_intr_1;
by SSNRISN trtn;
run;


data LSM_intr_1;
set   LSM_intr_1;
   by SSNRISN trtn ; 

	if ProbF ne . then P_VALUE=tranwrd(compress(put(ProbF,pvalue6.4)),'<.','<0.');

   *if lsmean ne .;
run;

proc transpose data=LSM_intr_1 out=LSM_intr_stat;
by SSNRISN;
id trtn;
var P_VALUE;
run;

data dummy;
do i=1 to 2;
  SSNRISN=i;
 _NAME_="P_VALUE";
output;
end;
run;

data LSM_intr_stat1;
length JM_AVAL_LABEL JM_AVAL_NAMEC $200. _name_ _LABEL_  trtn1 trtn2 $40. ;
merge dummy LSM_intr_stat ;
by SSNRISN _NAME_;

JM_BLOCK = '105' ; JM_AVAL_LABEL = 'Change' ;

if _name_ = 'P_VALUE' then do ;
 JM_AVAL_NAMEC = 'Interaction Term p-value Estimated at Week 12' ; _name_ = 'P_VALUE';_LABEL_ = 'Interaction Term p-value Estimated at Week 12' ; trtn1 = _1 ; trtn2 = _2 ;ord=9;
 end;
run;

data all_mixed_stat;
length JM_block1 JM_BLOCK $4.  trtn1 trtn2 $40.;
set LSM_STAT LSM_intr_stat1 lsmdiffs_out;

JM_BLOCK1=strip(JM_BLOCK)||strip(put(SSNRISN,best.));
JM_BLOCK=JM_BLOCK1;
run;



 Data final1 ;
  length jm_aval_label SSNRIS $200.  _name_ _label_ $40. trtn1 trtn2 $40 ;
  set JM_AVAL_TRANS1(in=a) all_mixed_stat(in=b where=(SSNRISN=1));


  JM_BLOCK=substr(JM_BLOCK,1,3);
    if jm_aval_label = 'Change from Baseline' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    *jm_block="1039" ;
  end;

  if a then SSNRISN=1;
  SSNRIS="Concomitant use Of SSRIs and SNRIs = Presence";
    if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    jm_block="103";
  end;

  if JM_block in ("105","106") then JM_BLOCK="103";

  
  *if ord ne . and TRTn1 ="" and trtn2="" and trtn3="" then delete;
  drop JM_block1;
run;

 proc sort data = final1 nodupkey ;
   by _all_ ;
  run ;


  proc sort data=final1;
  by jm_block   ord;
  run;



*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL1,  JM_INDSN2= , JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

 if GROUPVARN=. then GROUPVARN=ord;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEANCL" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_aval_namec="p-value" then jm_aval_namec="p-value^n";

 
   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;


	  if jm_block in ("101") then pageno=1;
        if jm_block in ( "102") then pageno=2;
       if jm_block in ("103") and groupvarn<=18 then pageno=3;
	   else if jm_block in ("103") and groupvarn>18 then pageno=4;
        

run;

proc sort data=jm_aval_allreport1;
by pageno jm_block jm_aval_namen;
run;

**Vijay added below code to save datasets for reporting **;
data final_subgrp_1;
  set Jm_aval_allreport1;

run;

data final_bign_1;
  set jm_bign1;
run;


 Data final2 ;
 length jm_aval_label SSNRIS _name_ _label_ trtn1 trtn2 $200 ;
  set JM_AVAL_TRANS2(in=a) all_mixed_stat(in=b where=(SSNRISN=2));

  JM_BLOCK=substr(JM_BLOCK,1,3);

    if jm_aval_label = 'Change from Baseline' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    *jm_block="1039" ;
  end;

   if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    jm_block="103";
  end;

  if JM_block in ("105","106") then JM_BLOCK="103";
  if a then SSNRISN=2;
  SSNRIS="Concomitant use Of SSRIs and SNRIs = Absence";
  
  *if ord ne . and TRTn1 ="" and trtn2="" and trtn3="" then delete;
  drop JM_block1;
run;

 proc sort data = final2 nodupkey ;
   by _all_ ;
  run ;


  proc sort data=final2;
  by jm_block   ord;
  run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL2,  JM_INDSN2= , JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT2);

data jm_aval_allreport2;
 set jm_aval_allreport2;

 if GROUPVARN=. then GROUPVARN=ord;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEANCL" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_aval_namec="p-value" then jm_aval_namec="p-value^n";

 
   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;


	    if jm_block in ("101") then pageno=1;
        if jm_block in ( "102") then pageno=2;
       if jm_block in ("103") and groupvarn<=18 then pageno=3;
	   else if jm_block in ("103") and groupvarn>18 then pageno=4;
        

run;

proc sort data=jm_aval_allreport2;
by pageno jm_block jm_aval_namen;
run;

**Vijay added below code to save datasets for reporting **;
data final_subgrp_2;
  set Jm_aval_allreport2;

run;

data final_bign_2;
  set jm_bign1;
run;

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
  %do myrep = 1 %to 2;

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
title%eval(&lasttitlenum.+1) j=l "Randomization stratum:  #BYVAL(SSNRIS)";

   %JM_AVAL_REPORT (JM_INDSN=jm_aval_allreport&myrep.,JM_BYVAR= SSNRIS, JM_BIGNDSN=Jm_bign1, 
   jm_spanheadopt=Y , JM_CELLWIDTH=2.0in,JM_TRTWIDTH=0.8in,
   JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=jm_aval_label);
   %let trtlab1=;%let trtlab2=;%let trtlab3=;
  %end;
%JM_ODSCLOSE;
%mend;
%subgrp_rep;

%let dsname=T_9_02_02_03_01;
data tlfdata.&dsname;
length  TRTN1-TRTN3 $200.;
set final_subgrp_:;

keep JM_: TRTN: SSNRIS:;
run;
