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
OPTIONS MPRINT NONUMBER;

*-----------------------------------------------------------------;
*INCLUDE THE TLF DEFAULTS FOR THE POPULATION AND DATASETS.;
*UPDATE ANY DEFAULTS AS REQUIRED FOR THE TABLE;
*-----------------------------------------------------------------;
/*
%include "_treatment_defaults-mITT.sas" ;
%include "_treatment_defaults-ess-mITT.sas" ; 
*/


PROC DATASETS LIB=WORK MEMTYPE=DATA KILL;QUIT;
options orientation=landscape missing=' ' nodate nonumber;
   
   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP; 

   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl);

      data _null_;
     
       tab_box='Category|Statistic';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'Randomized Treatment Group" trtn1 trtn2 trtn3));
   
	   data ADSL;                             
      set ADSL;                             
      where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A;                             
                            
   run;                             
    
   proc sort data=ADSL;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
 
   *** Create a macro variable for storing ADQS dataset name from the list of datasets ***;                             
   data ADQS ;                             
      set adam.ADQS ;                             
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("PTSDTSEV") and .<=avisitn<=12  and anl01fl="Y" and MFASFL="Y" ; 
   run;                             
    
   proc sort data=ADQS ;                             
      by studyid usubjid ;                         
                            
   run;                             
 
   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target;                             
      merge ADSL(in= a) 
            ADQS (in= b);                             
      by studyid usubjid;* trtn trt;                             
      if a;   
   run;                             
    

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                 



*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;


%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline),   JM_BLOCK=101,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 12 , JM_AVAL_LABEL=%bquote(End of Week 12),  JM_BLOCK=102,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12), JM_BLOCK=103,JM_SIGD=0 );


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC  JM_Q1C_Q3C JM_RANGEC, 
   JM_TRANS_ID=JM_TRTVARN);


   data JM_AVAL_TRANS1;
   set JM_AVAL_TRANS1;

         if _NAME_="JM_NC"  then ord=1;
   else  if _NAME_="JM_MEANSTDC"  then ord=2;
   else  if _NAME_="JM_MEDIANC"  then ord=3;
   else  if _NAME_="JM_Q1C_Q3C"  then ord=4;
   else  if _NAME_="JM_RANGEC"  then ord=5;

 run;

*-----------------------------------------------------------------------------------------------------------------------------;
   * LS Means
*-----------------------------------------------------------------------------------------------------------------------------;
  data ADQSM ;                             
      set adam.ADQS ;                             
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("PTSDTSEV") and .<=avisitn<=12  and MFASFL="Y"  and DTYPE="MULTIPLE IMPUTATION" and anl04fl="Y"; 
   run;                             
    
   proc sort data=ADQSM ;                             
      by studyid usubjid ;                         
                            
   run;                             
 
   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target_M;                             
      merge ADSL(in= a) 
            ADQSM (in= b);                             
      by studyid usubjid;* trtn trt;                             
      if a;   
   run;
 data target_1 ;
  SET target_M ;
  IF chg ne . and trtn in (1,2,3); 
id=subjid;

 RUN ;

proc sort data=target_1;
by IMPUTE trtn;
run;

ods trace on;
PROC MIXED DATA=target_1;
CLASS id  trtn AVISITN SSNRISN;
MODEL CHG = BASE trtn AVISITN trtn*AVISITN BASE*AVISITN SSNRISN SSNRISN*AVISITN / DDFM=KR RESIDUAL OUTP=RESIDUAL;
REPEATED AVISITN/TYPE=UN SUB=ID;
LSMEANS trtn*AVISITN / CL DIFF ALPHA=0.05;
ODS OUTPUT DIFFS=LSDIFFS  LSMeans=LSMEANS_;
BY IMPUTE;
RUN;
ods trace off;
data LSDIFFS2;
set LSDIFFS;
if _trtn=3;
if avisitn=_avisitn and avisitn = 12;
run;
data LSMEANS2;
set LSMEANS_;
if avisitn = 12;
run;

proc sort data=LSDIFFS2;
by AVISITN trtn;
run;
ods trace on;
PROC MIANALYZE DATA=LSDIFFS2;
BY AVISITN trtn;
MODELEFFECTS ESTIMATE;
STDERR STDERR;
ods output VarianceInfo=variance_ ParameterEstimates=lsmdiffs_estm;
RUN;

proc sort data=LSMEANS2;
by AVISITN trtn;
run;
PROC MIANALYZE DATA=LSMEANS2;
BY AVISITN trtn;
MODELEFFECTS ESTIMATE;
STDERR STDERR;
ods output VarianceInfo=LSMEANS_V ParameterEstimates=LSMEANS_estm;
RUN;
ods trace off;


data LSM_temp1;
set LSMEANS_estm;
   by trtn ;

   where avisitn=12;

	LS_Mean=strip(put(round(Estimate,0.1),9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(LCLMean,9.1))||', '||compress(put(UCLMean,9.1))||')';
run;

proc transpose data=lsm_temp1 out=LSM_stat;
id trtn;
var ls_mean se LS_MEANCL;
run;


data LSM_STAT ;
length JM_AVAL_LABEL _name_ _LABEL_  JM_AVAL_NAMEC $200. ;
 SET LSM_STAT ;
 JM_BLOCK = '104' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean' ; _LABEL_ = 'LS Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=7;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE_Mean' ; _name_ = 'SE_Mean';_LABEL_ = 'SE_Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=8;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=9;
 end;
 drop _1 _2 _3 ;
 RUN;


************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;



 data lsmdiffs1;
set lsmdiffs_estm;
   by trtn ;
   where avisitn=12  and trtn in (1,2) ;
	LS_Mean=strip(put(Estimate,9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(LCLMean,9.1))||', '||compress(put(UCLMean,9.1))||')';
	P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');
run;




proc transpose data=lsmdiffs1 out=lsmdiffs_stat;
id trtn;
var ls_mean se LS_MEANCL  p_value;
run;


data lsmdiffs_stat;
length JM_AVAL_LABEL _name_ _LABEL_ JM_AVAL_NAMEC $200. ;
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

 	data lsmd_out;
		set lsmdiffs_stat;
	 run;



data LSMD_OUT ;
length JM_AVAL_LABEL $200. ;
 SET LSMD_OUT ;
 if _name_ ^= ' ' then do ; 
  JM_BLOCK = '105' ;
  JM_AVAL_LABEL = 'Change' ;
  *JM_AVAL_NAMEC = _name_ ;
  *_LABEL_ = _name_ ;
 end;

 if _name_ = 'Shift' then do ;
  JM_AVAL_NAMEC = 'EMD' ; 
 _LABEL_ = 'Estimated Median difference' ;
 _NAME_ = 'EMD' ;
 end;
 

 keep jm_block JM_AVAL_LABEL JM_AVAL_NAMEC _NAME_ _LABEL_ trtn1 trtn2 ord;
 RUN;

 Data final ;
 length jm_aval_label _name_ _label_ $200 ;
  set JM_AVAL_TRANS1 LSM_STAT LSMD_OUT ;
  if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    jm_block="103";
  end;
 RUN ;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 8, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEANCL" then jm_aval_namec="95% CI";
  *if _name_="LS_MEANCL" and ord=9 then jm_aval_namec="95% CI^n";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

 
   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;


	    if jm_block in ("101") then pageno=1;

		    if jm_block in ("102") then pageno=2;
       if jm_block in ("103") and groupvarn<=15 then pageno=3;
	   else if jm_block in ("103") and groupvarn>15 then pageno=4;

run;

%LET _default_box=Timepoint;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=jm_aval_label);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;


*----------------------------------------------------------------------------------------------------------------------------------;
* GENERATE IN-TEXT TABLES
*----------------------------------------------------------------------------------------------------------------------------------;
%*JM_INTEXT_TABLE (JM_OUTREPORT=&rsltpath.\&outputnm._intext.rtf, 
   JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=jm_aval_label,
   JM_CELLWIDTH=1.25in, JM_TRTWIDTH=.55in, JM_BODYTITLEOPT=0, JM_NOHEADFOOT=Y);


