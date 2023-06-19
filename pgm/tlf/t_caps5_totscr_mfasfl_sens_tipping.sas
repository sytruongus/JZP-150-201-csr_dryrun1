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

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'JZP150 4 mg" trtn1 trtn2 trtn3 trtn4 trtn5 trtn6 trtn7 trtn8 trtn9 trtn10 trtn11 trtn12 trtn13 trtn14 trtn15 trtn16 trtn17 trtn18 trtn19 trtn20 trtn21));
   
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

	if avisitn=12 then wk12=aval; 
       
 	if avisitn=4 then wk4=aval ; 
     
   run;                             
    proc sort data=target ;
	by usubjid trtn SSNRISN  base ;
	run;

	proc transpose data=target out=tr_target prefix=WK;
	by usubjid trtn SSNRISN  base ;

	var aval;
	id avisitn;
	run;

   proc sort data=tr_target ;
	by  trtn  ;
	run;


PROC MI DATA=tr_target NIMPUTE=20 SEED=439384924 OUT=ANAL_MONO;
MCMC IMPUTE=MONOTONE NBITER=200 NITER=200;
VAR SSNRISN BASE WK4 WK12;
BY TRTN;
RUN;

proc sort data=ANAL_MONO;
by _imputation_;
run;

PROC MI DATA=ANAL_MONO SEED=439384924 NIMPUTE=1 OUT=ANAL_COMPL; 
class TRTN ;
VAR  TRTN SSNRISN BASE WK4 WK12; 
MONOTONE REGRESSION (BASE SSNRISN WK4 WK12);
BY  _Imputation_;
RUN;



proc sort data=ANAL_COMPL;
by _IMPUTATION_ usubjid SSNRISN trtn  base ;
run;

proc transpose data=ANAL_COMPL out=tr_ANAL_COMPL;
by _IMPUTATION_ usubjid SSNRISN trtn base;
 var WK4 WK12;

 run;


 data tr_ANAL_COMPL;
 set tr_ANAL_COMPL;
chg= aval-base;

avisitn=input(compress(_name_,"WK"),best.);
patient=usubjid;
run;

proc sort data=tr_ANAL_COMPL;
BY _IMPUTATION_  trtn;
run;
 
ods select none;

PROC MIXED DATA=tr_ANAL_COMPL;
CLASS PATIENT trtn avisitn SSNRISN;
MODEL CHG = BASE trtn avisitn trtn*avisitn BASE*avisitn SSNRISN SSNRISN*avisitn / DDFM=KR RESIDUAL OUTP=RESIDUAL;
REPEATED avisitn/TYPE=UN SUB=PATIENT;
LSMEANS trtn*avisitn / CL DIFF ALPHA=0.05;
ODS OUTPUT DIFFS=LSDIFFS_compl;
BY  _IMPUTATION_ ;
RUN;
ods select all;


data LSDIFFS_compl2;
set LSDIFFS_compl;
if avisitn=_avisitn and avisitn = 12  and trtn=2 and _trtn=3;
run;

proc sort data=LSDIFFS_compl2;
by AVISITN TRTN;
run;
ods trace on;
PROC MIANALYZE DATA=LSDIFFS_compl2;
BY AVISITN TRTN;
MODELEFFECTS ESTIMATE;
STDERR STDERR;
ods output VarianceInfo=variance_compl ParameterEstimates=lsmdiffs_compl_estm;
RUN;
ods trace off;

data tr_mean;
set lsmdiffs_compl_estm(keep=estimate);


val=(round(estimate));
x=-(val);
x3=3*(val);
incr=0.2*(abs(val));

min=min(x,x3);
max=max(x,x3);
call symput('min', min);
call symput('max', max);
call symput('incr', incr);
run;

%put &min &max &incr;

data tr_target_1;
set tr_target;
if trtn in (2,3);
/*if trtn=2 then TRTN1=1;
else if trtn=3 then trtn1=0;*/
*drop trtn;

run;


%MACRO TPA2 (DATA=, SMIN=, SMAX=, SINC=, OUT=); 
DATA &OUT; 
SET _NULL_; 
RUN; 
/*------------ # OF SHIFT VALUES ------------*/ 

%LET NCASE= %SYSEVALF( (&SMAX-&SMIN)/&SINC, CEIL );

 /*------- IMPUTED DATA FOR EACH SHIFT -------*/ 
%DO JC1=0 %TO &NCASE;
    %DO JC0=0 %TO &NCASE;
     /*NCASE IS THE NUMBER OF TOTAL SHIFTS TO BE EVALUATED*/
      %LET SJ1= %SYSEVALF( &SMIN + &JC1 * &SINC); 
      %LET SJ0= %SYSEVALF( &SMIN + &JC0 * &SINC); 
     /*SJ IS THE SHIFT VALUE*/
	  proc sort data=&DATA;
	  by TRTN;
	  run;
 ods select none;

      PROC MI DATA=&DATA NIMPUTE=20 SEED=439384924 OUT=MONO;
           MCMC IMPUTE=MONOTONE NBITER=200 NITER=200;
           VAR SSNRISN BASE WK4 WK12;
           BY TRTN;
     RUN;
     PROC SORT DATA=MONO;
       BY _IMPUTATION_;
     RUN; 

     PROC MI DATA=MONO SEED=439384924 NIMPUTE=1 OUT=OUTMI;
          VAR TRTN SSNRISN  BASE WK4 WK12; 
          CLASS TRTN; 
          MONOTONE REGRESSION(BASE SSNRISN WK4 WK12);
          MNAR ADJUST(WK12 / SHIFT=&SJ1 ADJUSTOBS=(TRTN='2') ) ADJUST(WK12 / SHIFT=&SJ0 ADJUSTOBS=(TRTN='3') );
         BY _IMPUTATION_; 
    RUN;
 ods select all;

    DATA OUTMI; 
      SET OUTMI; 
      SHIFT1= &SJ1; 
      SHIFT0= &SJ0; 
    RUN;

   DATA &OUT;
    SET &OUT OUTMI; 
   RUN; 
  %END;
 
%END;
%MEND TPA2;

%put &min &max &incr;
%TPA2 (DATA=tr_target_1, SMIN=&min, SMAX=&max, SINC=&incr, OUT= shift_val);

proc sort data=shift_val;
by _IMPUTATION_ usubjid SSNRISN  TRTN base Shift0 shift1;
run;

proc transpose data=shift_val out=tr_shift;
by _IMPUTATION_ usubjid SSNRISN  TRTN base Shift0 shift1;
 var  WK4 WK12;

 run;


 data tr_shift;
 set tr_shift;
chg= aval-base;

avisitn=input(compress(_name_,"WK"),best.);
patient=usubjid;
run;

proc sort data=tr_shift;
BY _IMPUTATION_  Shift0 shift1 ;
run;
 
ods select none;

PROC MIXED DATA=tr_shift;
CLASS PATIENT TRTN avisitn SSNRISN;
MODEL CHG = BASE TRTN avisitn TRTN*avisitn BASE*avisitn SSNRISN SSNRISN*avisitn / DDFM=KR RESIDUAL OUTP=RESIDUAL;
REPEATED avisitn/TYPE=UN SUB=PATIENT;
LSMEANS TRTN*avisitn / CL DIFF ALPHA=0.05;
ODS OUTPUT DIFFS=LSDIFFS;
BY _IMPUTATION_  Shift0 shift1 ;
RUN;
ods select all;


data LSDIFFS2;
set LSDIFFS;
if _trtn=3;
if  avisitn = 12 and _avisitn=12 ;
run;

proc sort data=LSDIFFS2;
by AVISITN  shift1 Shift0;
run;
ods trace on;
PROC MIANALYZE DATA=LSDIFFS2;
BY AVISITN  shift1 Shift0;
MODELEFFECTS ESTIMATE;
STDERR STDERR;
ods output VarianceInfo=variance_ ParameterEstimates=lsmdiffs_estm;
RUN;
ods trace off;

proc freq data=lsmdiffs_estm noprint;
 table shift1/out=frq_1 nocol nopct;
 run;


 data frq_1;
 length trt $20.;
 set frq_1;
 shift1n=_n_;
shift0=-1;
shift1c=strip(put(shift1,best.));
trtn=shift1n;
trt=shift1c;

 run;


proc sort data=lsmdiffs_estm;
by  shift1;
run;
proc sort data=frq_1;
by  shift1;
run;
data lsmdiffs_estm1;
merge lsmdiffs_estm(in=a) frq_1(in=b keep=shift1 shift1n);
by shift1;
P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');
shift1c=strip(put(shift1,best.));

run;

 

proc sort data=lsmdiffs_estm1;
by shift0 shift1;
run;

proc transpose data=lsmdiffs_estm1 out=tr_lsmdiffs_estm prefix=trtn;
by shift0;
var p_value;
id shift1n;
run;


proc transpose data=frq_1 out=tr_frq_1 prefix=trtn;
by shift0;
var shift1c;
id shift1n;
run;

data tr_lsmdiffs_estm;
set tr_lsmdiffs_estm;
shift0c=strip(put(shift0,best.));
run;




 Data final ;
 length jm_aval_label $200 ;
  set tr_lsmdiffs_estm ;
  jm_aval_label = "Placebo";
    jm_aval_namec=strip(shift0c);
 *   trtn1=strip(shift0c);
   var1="Placebo";
    jm_block="103";
	if shift0=-1 then delete;
 
 RUN ;


 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=frq_1,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                 


data JM_BIGN1;
 length JM_AVAL_BIGN JM_TRTVARN JM_AVAL_START trtn 8.
  TRTVAR JM_AVAL_BIGN_LABEL JM_AVAL_FMTNAME $200;
  set frq_1;

TRTVAR=strip(shift1c);
JM_AVAL_BIGN = 0;
JM_TRTVARN=shift1n;
JM_AVAL_START=shift1n;
trtn=shift1n;
JM_AVAL_BIGN_LABEL= strip(shift1c);
JM_AVAL_FMTNAME= "BIGNTRTF";
keep JM_AVAL_BIGN JM_TRTVARN JM_AVAL_START trtn  TRTVAR JM_AVAL_BIGN_LABEL JM_AVAL_FMTNAME;

run;



*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 11, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

 
	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;

       if jm_block in ("103") and groupvarn<=11 then pageno=1;
	   else if jm_block in ("103") and groupvarn>11 then pageno=2;

	*   label
 
 trtn1  =  "-9"  
 trtn2  =  "-8.4"
 trtn3  =  "-7.8"
 trtn4  =  "-7.2"
 trtn5  =  "-6.6"
 trtn6  =  "-6"  
 trtn7  =  "-5.4"
 trtn8  =  "-4.8"
 trtn9  =  "-4.2"
 trtn10 =  "-3.6"
 trtn11 =  "-3"  
 trtn12 =  "-2.4"
 trtn13 =  "-1.8"
 trtn14 =  "-1.2"
 trtn15 =  "-0.6"
 trtn16 =  "0"   
 trtn17 =  "0.6" 
 trtn18 =  "1.2" 
 trtn19 =  "1.8" 
 trtn20 =  "2.4" 
 trtn21 =  "3"   

 ;

run;

%LET _default_box=;


/*
proc format;
  value trt (MULTILABEL)
    
       1 =  "-9"  
       2 =  "-8.4"
       3 =  "-7.8"
       4 =  "-7.2"
       5 =  "-6.6"
       6 =  "-6"  
       7 =  "-5.4"
       8 =  "-4.8"
       9 =  "-4.2"
      10 =  "-3.6"
      11 =  "-3"  
      12 =  "-2.4"
      13 =  "-1.8"
      14 =  "-1.2"
      15 =  "-0.6"
      16 =  "0"   
	  17 =  "0.6" 
      18 =  "1.2" 
      19 =  "1.8" 
      20 =  "2.4" 
      21 =  "3"   
      ;
      value $trtc
	     
              "-9"    = 1
			  "-8.4"  = 2
 			  "-7.8"  = 3
			  "-7.2"  = 4
			  "-6.6"  = 5
			  "-6"    = 6
			  "-5.4"  = 7
			  "-4.8"  = 8
			  "-4.2"  = 9
			  "-3.6"  =10
 			  "-3"    =11
			  "-2.4"  =12
			  "-1.8"  =13
			  "-1.2"  =14
			  "-0.6"  =15
			  "0"     =16
			  "0.6"   =17
			  "1.2"   =18
 			  "1.8"   =19
			  "2.4"   =20
			  "3"     =21
					; 
		run;
*/


%include "C:\SASData\JZP-150\150-201\stat\csr_dryrun1\utilities\STDY_JM_AVAL_REPORT.sas";
%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'JZP150 4 mg"  trtn1 trtn2 trtn3 trtn4 trtn5 trtn6 trtn7 trtn8 trtn9 trtn10 trtn11 trtn12 trtn13 trtn14 trtn15 trtn16 trtn17 trtn18 trtn19 trtn20 trtn21));
*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%*JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=N, jm_breakvar=jm_aval_label,JM_CELLWIDTH=0.2, JM_TRTWIDTH=0.2);
%STDY_JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N,
jm_breakopt=Y, jm_breakvar=JM_AVAL_LABEL,jm_grouplabel=, jm_cellwidth=0.5in, jm_trtwidth = 0.5in);

*%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT1
,JM_COL2VAR=  var1 trtn1 trtn2 trtn3 trtn4 trtn5 trtn6 trtn7 trtn8 trtn9 trtn10 trtn11 trtn12 trtn13 trtn14 trtn15 trtn16 trtn17 trtn18 trtn19 trtn20 trtn21 trtn22
,JM_CELLWIDTH= 0.45 0.45   0.45  0.45  0.45  0.45  0.45 0.45   0.45  0.45  0.45   0.45  0.45   0.45   0.45   0.45    0.45  0.45   0.45    0.45  0.45   0.45 0.45
,JM_BYVAR= 
,JM_BREAKVAR=
,JM_REPTYPE=Listing
);
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



%let dsname=T_9_02_01_02_02;
data tlfdata.&dsname;
set final;

*keep JM_: TRTN: SEX;
run;
