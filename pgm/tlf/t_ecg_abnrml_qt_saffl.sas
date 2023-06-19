
/*************************************************************************
 * STUDY DRUG:        
 * PROTOCOL NO:        
 * PROGRAMMER:        Pavani
 * DATE CREATED:      
 * PROGRAM NAME:      t-ecg-abnrQT-dbrw-SAF.sas 
 * DESCRIPTION:       ECG Parameters Across All Study Periods (Excluding Placebo)
 * DATA SETS USED:    
 ***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer: 

*************************************************************************/;
OPTIONS MPRINT NONUMBER;

*-----------------------------------------------------------------;
*INCLUDE THE TLF DEFAULTS FOR THE POPULATION AND DATASETS.;
*UPDATE ANY DEFAULTS AS REQUIRED FOR THE TABLE;
*-----------------------------------------------------------------;

%LET _BIGN_WHERE=SAFFL='Y';
%LET _DEFAULT_WHERE=SAFFL='Y';
%LET _default_box=Timepoint;
%LET _DEFAULT_SPAN_HEAD= Randomized Treatment Group ^{nbspace 30} ^n ;

*-----------------------------------------------------------------;
*TITLE AND FOOTNOTES
*-----------------------------------------------------------------;
%global mypgmname;

data _null_;
   call symputx('mypgmname',scan("%sysget(SAS_EXECFILENAME)",1,'.'));
run;

   %JM_TF (jm_infile=&tocpath.,JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

**select last non-missing title**;
%global lasttitlenum;
data _null_;
  set tf(keep=title2-title8);
  call symput("lasttitlenum",strip(put(8-cmiss(of title2-title8)+2,best.)));
run;
%put &lasttitlenum.;

*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;
**Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl);
*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%let default_fontsize = 9;
%JM_TEMPLATES;

*-----------------------------------------------------------------;
*BIGN CALCULATION.;
*-----------------------------------------------------------------;
*** Calculate the Big N denominator from ADEG by treatment ***;
 data adsl;*(rename=( trt01an=trtn trt01a=trt));
      set adam.adsl;
	  where saffl="Y" and trt01an in (1,2,3);
	trtn = trt01an;
	trt = trt01a;

      output;
	  if trt01an in (1,2 ) ;
      trtn=99;
      trt='JZP150 Total';
      output;
/*      rename trt01an=trtn trt01a=trt;*/
   run;

data ADEG;
 set adam.ADEG ;
if SAFFL="Y"  and anl01fl='Y' and  trtan in (1,2,3) and avisitn in (1,4,8,12,0) and paramn >=301 ;
 IF CRIT1FL = 'Y' or CRIT2FL = 'Y' or CRIT3FL = 'Y'  then crtfl = 'Y';
output;
if avisitn>=0 and (CHGCAT1 ne "" or CHGCAT2 ne "");
avisitn=500;
avisit="Any post screening abnormality";
output;

run;

data adeg;
set adeg;
if avisitn in (1,4,8,12,0,500) ;
if paramn >=301;

trtn=trtan;
trt=trta;

   output;
	  if trtan in (1,2 ) ;
      trtn=99;
      trt='JZP150 Total';
      output;

run;


**Create Dummy - all subjects from ADSL, with all parameters and all visits in ADEG**;
proc sql;
  create table dummyparm as 
  select a.*,b.*
  from (select distinct paramcd, param,paramn from adeg where paramcd ne '') as a, 
		(select distinct avisitn,avisit from adeg where avisit ne '') as b;
  create table dummyadsl as
  select a.*,b.*
  from adsl as a, dummyparm as b
  order by a.usubjid,b.paramn,b.param,b.avisitn;
quit;
proc sort data=dummyparm;
by paramn;
run;



proc freq data=ADEG noprint;

table paramn* param*  avisitn *avisit*CRIT1FL*CRIT1/out=CRIT1FL(WHERE=(crit1fl="Y")) nocol nopct missing;
table paramn* param*  avisitn *avisit*CRIT2FL*CRIT2/out=CRIT2FL(WHERE=(crit2fl="Y")) nocol nopct missing;
table paramn* param*  avisitn *avisit*CHGCAT1/out=CHGCAT1(WHERE=(CHGCAT1 NE "")) nocol nopct missing;
run;


   %jm_gen_trt_fmt(jm_indsn=adsl,jm_intrtvar=trt);

%JM_BIGN(JM_INDSN=ADSL,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );

*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=SAFFL,JM_SECONDARY_WHERE=avalc ne '' , JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=100, jm_cntvar=usubjid,JM_BYVAR= paramn param  avisitn avisit, JM_AVAL_LABEL=%bquote(Visit) );

%JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=CRIT1FL,JM_SECONDARY_WHERE= CRIT1FL = 'Y', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=101, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn avisit, JM_AVAL_LABEL=%bquote(> 450 msec) );

%JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=AVAL,JM_SECONDARY_WHERE= CRIT2FL = 'Y', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=201, jm_cntvar=usubjid, JM_BYVAR= paramn param avisitn, JM_AVAL_LABEL=%bquote(> 480 msec) );

 %JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=AVAL,JM_SECONDARY_WHERE= CRIT3FL = 'Y', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=301, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn,  JM_AVAL_LABEL=%bquote(> 500 msec) );

  *%JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=CHGCAT1,JM_SECONDARY_WHERE= CHGCAT1 = 'Change from Baseline > 30 msec', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=401, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn avisit,   JM_AVAL_LABEL=%bquote(Change from Screening <= 30 msec) );


  %JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=CHGCAT1,JM_SECONDARY_WHERE= CHGCAT1 = 'Change from Baseline > 30 msec', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=402, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn avisit,   JM_AVAL_LABEL=%bquote(Change from Baseline > 30 msec) );

  *%JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=CHGCAT2,JM_SECONDARY_WHERE= CHGCAT2 = 'Change from Baseline > 60 msec', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=501, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn avisit,   JM_AVAL_LABEL=%bquote(Change from Screening <= 60 msec) );

 %JM_AVAL_COUNT(JM_INDSN=ADEG, jm_var=CHGCAT2,JM_SECONDARY_WHERE= CHGCAT2 = 'Change from Baseline > 60 msec', JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=502, jm_cntvar=usubjid,JM_BYVAR= paramn param avisitn avisit,   JM_AVAL_LABEL=%bquote(Change from Baseline > 60 msec) );


 data JM_AVAL_COUNT100;
  set  JM_AVAL_COUNT100;
  by paramn param  avisitn avisit ;
   if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.));
  END;
run;
**Calculate the percentages using block 100 COUNT as denominator**;

 PROC SORT DATA=JM_AVAL_COUNT100;
  BY paramn param  avisitn jm_trtvarn;
run;

PROC SORT DATA=JM_AVAL_COUNT101;
  BY paramn param  avisitn jm_trtvarn;
run;

data JM_AVAL_COUNT101;
  merge JM_AVAL_COUNT101(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT100(in=b keep=paramn param  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by paramn param  avisitn avisit jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT101;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;

PROC SORT DATA=JM_AVAL_COUNT201;
  BY paramn param  avisitn  jm_trtvarn;
run;

data JM_AVAL_COUNT201;
  merge JM_AVAL_COUNT201(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT100(in=b keep=paramn param  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by paramn param  avisitn  jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT201;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


PROC SORT DATA=JM_AVAL_COUNT301;
  BY paramn param  avisitn  jm_trtvarn;
run;

data JM_AVAL_COUNT301;
  merge JM_AVAL_COUNT301(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT100(in=b keep=paramn param  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by paramn param  avisitn  jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT301;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


PROC SORT DATA=JM_AVAL_COUNT402;
  BY paramn param  avisitn  jm_trtvarn;
run;

data JM_AVAL_COUNT402;
  merge JM_AVAL_COUNT402(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT100(in=b keep=paramn param  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by paramn param  avisitn  jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT402;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


PROC SORT DATA=JM_AVAL_COUNT502;
  BY paramn param  avisitn jm_trtvarn;
run;

data JM_AVAL_COUNT502;
  merge JM_AVAL_COUNT502(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT100(in=b keep=paramn param  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by paramn param  avisitn jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT502;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1, 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY= paramn param AVISITN AVISIT JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_AVAL_COUNTC , JM_TRANS_ID=JM_TRTVARN);


   data JM_AVAL_TRANS1;
   set JM_AVAL_TRANS1;
   if JM_AVAL_LABEL="" then delete;
 

        if JM_AVAL_LABEL="Visit" then ord=0;
   else if JM_AVAL_LABEL="> 450 msec" then ord=1;
   else if JM_AVAL_LABEL="> 480 msec" then ord=2;
   else if JM_AVAL_LABEL="> 500 msec" then ord=3;
   else if JM_AVAL_LABEL="Change from Baseline > 30 msec" then ord=4;
   else if JM_AVAL_LABEL="Change from Baseline > 60 msec" then ord=5;
  run;




   PROC SORT DATA = ADEG NODUPKEY OUT = VISIT (KEEP = PARAMN PARAM AVISITN AVISIT);
  BY PARAMn PARAM AVISITN AVISIT ;RUN ;

  data VISIT;
  set visit;
  ord=0;
  run;


PROC SORT DATA = JM_AVAL_TRANS1 NODUPKEY OUT = FILL (KEEP = PARAMN PARAM );
  BY PARAMN PARAM  ;RUN ;

  DATA FILL ;
   SET FILL ;
   DO AVISITN = 0,1,4,8,12,500 ;
    DO ord=0 TO 5;
	OUTPUT;
	END;

  
   END;
  RUN ; 

PROC  SORT DATA = JM_AVAL_TRANS1 ; BY PARAMN PARAM AVISITN  ord  ;RUN ;

data JM_AVAL_TRANS1;
 MERGE JM_AVAL_TRANS1(IN=A drop =AVISIT) FILL (IN = B) VISIT ;
 BY PARAMN PARAM  AVISITN  ord;
 IF A OR B ;

      if avisitn=0 then AVISIT="Baseline";
 else if avisitn=1 then AVISIT="End of Week 1";
 else if avisitn=4 then AVISIT="End of Week 4";
 else if avisitn=8 then AVISIT="End Week 8";
  else if avisitn=12 then AVISIT="End Week 12";

 else if avisitn=500 then AVISIT="Any post screening abnormality";

 if JM_BLOCK="" then do;
        if ord=0 then JM_AVAL_LABEL="Visit" ;
   else if ord=1 then JM_AVAL_LABEL="> 450 msec";
   else if ord=2 then JM_AVAL_LABEL="> 480 msec";
   else if ord=3 then JM_AVAL_LABEL="> 500 msec";
   else if ord=4 then JM_AVAL_LABEL="Change from Baseline > 30 msec";
   else if ord=5 then JM_AVAL_LABEL="Change from Baseline > 60 msec";


     if ord=0 then JM_block="100";
 else if 1<=ord<=3 then JM_block="101";
 else if ord=4 then JM_block="401";
 else if ord=5 then JM_block="402";
/* else if ord=6 then JM_block="501";*/
/* else if ord=7 then JM_block="502";*/
 end;


 IF JM_AVAL_LABEL IN ( ' ' , 'Visit') THEN jm_aval_namec = avisit ;
 else  jm_aval_namec = "   " || jm_aval_label ;
/*if avisitn=99 then avisitn=100;*/
 JM_BLOCK=cat(":",paramn,avisitn,input(strip(JM_BLOCK),best.));
  
 IF strip(JM_AVAL_NAMEC) in ("> 500 msec","Change from Baseline > 60 msec") then JM_AVAL_NAMEC="   " ||strip(JM_AVAL_NAMEC)||"^n";

 if paramn=7 and strip(JM_AVAL_NAMEC) in ("Change from Baseline > 60 msec^n") then JM_AVAL_NAMEC="   " ||strip("Change from Baseline > 60 msec");

  *IF JM_BLOCK = '99' THEN JM_BLOCK = '0' || JM_BLOCK;


*if JM_AVAL_LABEL="" then delete;

 if avisitn=0  and ord in (4,5,6,7) then delete; 
 * Arun 06/23/2020 Dropped "post screening abnormality (last section)" as per Stat comment.;
 if avisitn=500 then delete;
run;

PROC  SORT ; BY PARAMN PARAM JM_BLOCK ord;RUN ;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=, JM_INDSN2=JM_AVAL_TRANS1, JM_BREAKCNT=15, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);
*----------------------------------------------------------------------------------------------------------------------------------;

PROC  SORT ; BY PARAMN PARAM JM_BLOCK ord;RUN ;

data jm_aval_allreport1;
length JM_BLOCK $200.;
 set jm_aval_allreport1;
BY PARAMN PARAM JM_BLOCK ord;
 if   avisitn=0 and jm_aval_label="Visit" then JM_AVAL_NAMEC="Baseline";


pageno=paramn;
if avisitn in (0,1,4) then pageno=1;
else if avisitn in ( 8,12,500) then pageno=2;
array trt[*] trtn1 trtn2 trtn3 trtn99;
do i=1 to dim(trt);
if  trt[i]="" and 1<=ord<=7 then trt[i]="0 (0)";

end;
jm_aval_namen=ord;

run;
proc sort data = jm_aval_allreport1; by PARAMN PARAM  avisitn avisit JM_block   ord;run ;

data jm_aval_allreport1;
set jm_aval_allreport1 ;
by PARAMN PARAM avisitn avisit JM_block ord  ;
retain block_num 0;
 if first.paramn then block_num=block_num+1;
run;


** COunt number of parameters to loop through**;
proc sql;
 create table parmlist as
 select distinct paramn,param
 from JM_AVAL_ALLREPORT1
 where paramn ne . and param ne ''
 order by paramn;
quit;
%global n_param;
%let n_param=&sqlobs.;
%put &n_param.;

proc sql noprint;
  create table jm_aval_allreport2 as
  select a.*,b.param
  from jm_aval_allreport1(drop= param) as a left join parmlist as b
  on a.paramn=b.paramn 
	order by a.PARAMN,a.AVISITN,a.jm_block,jm_aval_namen;
  select count(distinct paramn) into :n_all_blocks
  from jm_aval_allreport2;
quit;
%put &n_all_blocks;



%macro outds;
%macro pageby_rep;
*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);
ods escapechar="^";
options nonumber;
*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
  *select one paramter one visit at a time**;
  %do myrep =1 %to &n_all_blocks;
    data _null_;
	  set dummyparm(firstobs=&myrep. obs=&myrep.);
	  call symput("sel_paramn",strip(put(paramn,best.)));
	  call symput("sel_param",strip(param));
	  
	run;
*-----------------------------------------------------------------;
*TITLES AND FOOTNOTES ARE READ FROM EXCEL SPREADSHEET. ;
*-----------------------------------------------------------------;
%*LET _DEFAULT_BOX=Parameter: %nrbquote(&sel_param.);
%LET _DEFAULT_BOX=Visit| ^   Markedly Abnormal Criterion;
	data jm_aval_allreport;
	  set jm_aval_allreport2;
	  where block_num=&myrep.;
	run;
	options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
title%eval(&lasttitlenum.+1) j=l "Parameter: #BYVAL(param)";

	%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport, JM_BIGNDSN=Jm_bign1 ,/*JM_CELLWIDTH=2.0in,JM_TRTWIDTH=0.85in,*/ jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=N, jm_breakvar=,jm_byvar=  param  );

	%*JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport,JM_BYVAR= , JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , 
	JM_INDENTOPT=N, jm_breakopt=N, jm_breakvar=JM_AVAL_LABEL,JM_TRTWIDTH=0.6in);

  %end;

%JM_ODSCLOSE;
%mend;
%pageby_rep;

proc sql; create table paramfmt as 
select distinct paramn as start,param as label, 'paramfmt' as fmtname
from dummyparm
order by paramn;
create table paramcdfmt as
select distinct paramn as start,paramcd as label, 'paramcdfmt' as fmtname
from dummyparm
order by paramn;

quit;

proc format cntlin=paramfmt;run;
proc format cntlin=paramcdfmt;run;



**Update Output reporting dataset**;
data _null_;
output=tranwrd("&outputnm.",'-','_');
call symput("outputdt",strip(output));
run;
%put &outputdt.;
**update output dataset to add TRTN, PARAMN,AVISITN for easy proc compare**;
data tlfdata.&OUTPUTdt.;
  set jm_aval_allreport2;
run;
/*
  paramn=input(scan(jm_block,1,':'),best.);
  avisitn=input(scan(jm_block,2,':'),best.);
  
  length paramcd $20 param $200;
  if paramn ne . then paramcd=strip(put(paramn,paramcdfmt.));
  if paramn ne . then param=strip(put(paramn,paramfmt.));


        if  JM_AVAL_LABEL="Visit"                            then JM_AVAL_NAMEN=0 ;
   else if  JM_AVAL_LABEL="> 450 msec"                       then JM_AVAL_NAMEN=1 ;
   else if  JM_AVAL_LABEL="> 480 msec"                       then JM_AVAL_NAMEN=2 ;
   else if  JM_AVAL_LABEL="> 500 msec"                       then JM_AVAL_NAMEN=3 ;
   else if  JM_AVAL_LABEL="Change from Screening <= 30 msec" then JM_AVAL_NAMEN=4 ;
   else if  JM_AVAL_LABEL="Change from Screening > 30 msec"  then JM_AVAL_NAMEN=5 ;
   else if  JM_AVAL_LABEL="Change from Screening <= 60 msec" then JM_AVAL_NAMEN=6 ;
   else if  JM_AVAL_LABEL="Change from Screening > 60 msec"  then JM_AVAL_NAMEN=7 ;
 
run;*/
%mend;

%outds;

