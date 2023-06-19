/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        
 * DATE CREATED:      
 * PROGRAM NAME:      t_lab_dsum_003.sas
 * DESCRIPTION:       Template program to create "Summary of Clinical Laboratory Data: [Panel Name] Absolute Values and Change from Baseline" Table
 * DATA SETS USED:    
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            SUBGRPVAR       - Subgroup variable name. ex: sexn (Recommended to use Numeric variable and apply format)
 *            SUBGRPVAR_FMT   - Subgroup variable FORMAT. ex: sex (Sex format must be define in JM_FORMATS.xlsx)
 ************************************************************************
PROGRAM MODIFICATION LOG
*************************************************************************
Programmer:  
Date:        
Description: /*************************************************************************
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
     
       tab_box='Body System|Visit, n (%)';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Treatment Group" trtn1 trtn2 trtn3)  trtn99);

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


*-----------------------------------------------------------------;
*BIGN CALCULATION.;
*-----------------------------------------------------------------;
*** Calculate the Big N denominator from ADLB by treatment ***;
   %jm_gen_trt_fmt(jm_indsn=adsl,jm_intrtvar=trt);

%JM_BIGN(JM_INDSN=ADSL,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );

data ADLB;
 set adam.ADLB ;
 if SAFFL="Y" and  avisitn in (0,1,4,8,12) and parcat1="Urinalysis" and ANL01FL='Y' and anl05fl='Y' and AVAL eq . and LBSTAT ne "NOT DONE";

trtn=trtan;
trt=trta;

  output;
     if trtan in (1,2 ) ;
      trtn=99;
      trt='JZP150 Total';
      output;

run;


**Create Dummy - all subjects from ADSL, with all parameters and all visits in ADLB**;
proc sql;
  create table dummyparm as 
  select a.*,b.*
  from (select distinct paramcd, param,paramn from ADLB where paramcd ne '') as a, 
      (select distinct avisitn,avisit from ADLB where avisit ne '') as b;
  create table dummyadsl as
  select a.*,b.*
  from adsl as a, dummyparm as b
  order by a.usubjid,b.paramn,b.param,b.avisitn;
quit;
proc sort data=dummyparm;
by paramn;
run;


proc freq data=ADLB;
table avisitn*avisit*paramn*param/out=paramn_fr nocol nopct;
where avalc ne "" and aval eq .;

run;


data ADLB_S;
set ADLB;
run;

proc sort data=ADLB out=ADLB_F;
by usubjid trtn paramn param   avisitn avisit avalc adt  ;
run;

data ADLB_F;
set ADLB_F;
by usubjid trtn paramn param   avisitn avisit avalc adt  ;
if last.avalc;

run;


*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline),*/
/* JM_BYVAR=  avisitn avisit PARAMN paramcd param , JM_BLOCK=101,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(End of Week 1),*/
/* JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=102,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 1),*/
/* JM_BYVAR=  avisitn avisit PARAMN paramcd param , JM_BLOCK=103,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(End of Week 4),*/
/*JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=104,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 4),*/
/*JM_BYVAR=  PARAMN paramcd param avisitn avisit, JM_BLOCK=105,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(End of Week 8),*/
/*JM_BYVAR=   PARAMN paramcd param avisitn avisit,  JM_BLOCK=106,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 8),*/
/*JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=107,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =12, JM_AVAL_LABEL=%bquote(End of Week 12),*/
/*JM_BYVAR=   PARAMN paramcd param avisitn avisit,  JM_BLOCK=108,JM_SIGD=1 );*/
/**/
/*%JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12, JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12),*/
/*JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=109,JM_SIGD=1 );*/

%*JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Safety Follow-up),
JM_BYVAR=  PARAMN paramcd param avisitn avisit,  JM_BLOCK=110,JM_SIGD=0 );

%*JM_AVAL_SUM(JM_INDSN=ADLB_S, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Change from Baseline to Safety Follow-up),
JM_BYVAR=  PARAMN paramcd param avisitn avisit, JM_BLOCK=111,JM_SIGD=0 );

%JM_AVAL_COUNT(JM_INDSN=ADLB_F, jm_var= AVALC , JM_SECONDARY_WHERE= avalc ne "" and aval eq . , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=112, jm_cntvar=usubjid, JM_BYVAR= paramn param avisitn avisit, JM_FMT=, JM_AVAL_LABEL=%bquote(SNRARRY) );

/*%JM_AVAL_COUNT(JM_INDSN=ADLB_F, jm_var= AVALC , JM_SECONDARY_WHERE= avalc ne "" and aval eq . , jm_bign=jm_bign1, jm_trtvarn=trtn,*/
/*jm_block=113, jm_cntvar=usubjid, JM_BYVAR= paramn param avisitn avisit AVALN, JM_FMT=, JM_AVAL_LABEL=%bquote(INTP) );*/

*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;


/*data JM_AVAL_ALLDATA2;*/
/*set JM_AVAL_ALLDATA1;*/
/*where JM_TYPE="SUMMARY";*/
/**/
/*if paramn in (106,201) then delete;*/
/**/
/**/
/*run;*/
/**/
/*%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=JM_AVAL_ALLDATA2, */
/*   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=   paramn param avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, */
/*   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC JM_RANGEC , */
/*   JM_TRANS_ID=JM_TRTVARN);*/
/**/
/**/
/*   data jm_aval_trans1 ;*/
/*    set jm_aval_trans1;*/
/*   run ;*/


data JM_AVAL_ALLDATA3;
set JM_AVAL_ALLDATA1;
where JM_TYPE="COUNT";
jm_aval_namec = strip(put(AVALN,ECGAVAL.));

if avisitn=0 then  JM_AVAL_LABEL=avisit;
else JM_AVAL_LABEL="End of "||strip(avisit);;

run;

%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata3, 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=   avisitn avisit paramn param avaln grpvar JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);

   data jm_aval_trans2 ;
    set jm_aval_trans2;


 run ;

data JM_AVAL_TRANS3;
set JM_AVAL_TRANS2(in=a) ;*JM_AVAL_TRANS2(in=b) ;
 
run;

proc sort data=JM_AVAL_TRANS3;
by paramn avisitn avisit JM_BLOCK ;
run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_PGBRK (JM_INDSN1=JM_AVAL_TRANS2, JM_INDSN2=, JM_BREAKCNT=12, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

proc sort data=jm_aval_allreport1;
by paramn avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;
run;


data jm_aval_allreport1;
set jm_aval_allreport1;
by paramn avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;

 block=jm_block;

 if avaln ne . then do;
    JM_AVAL_NAMEN=AVALN;
     GROUPVARN=AVALN;
    _LABEL_=grpvar;
   end;

   if avisitn=0 then  GROUPLABEL=avisit;
else GROUPLABEL="End of "||strip(avisit);

/*if paramn in (106,201) then do;*/
/**/
/*   if avisitn in (-1,0) then  GROUPLABEL=avisit;*/
/*else GROUPLABEL="End of "||strip(avisit);*/
/*GROUPVAR=grpvar;*/
/*end;*/

run;


data dummy ;
set jm_aval_allreport1;
by paramn avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;
if first.JM_BLOCK;
*JM_AVAL_LABEL=GROUPLABEL;


if avisitn=0 then jm_aval_namec=strip(PARAM)||'^n^{nbspace 2}'||strip(JM_AVAL_LABEL);
else jm_aval_namec=strip(JM_AVAL_LABEL);

jm_aval_namen=0;

drop trtn:;
run;




data jm_aval_allreport1;
length  JM_BLOCK $200.;
 set dummy jm_aval_allreport1;
 by paramn avisitn JM_BLOCK;
run;

proc sort data=jm_aval_allreport1;
by paramn JM_BLOCK avisitn  avisit  JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;
run;


data jm_aval_allreport1;
set jm_aval_allreport1;
by paramn JM_BLOCK avisitn  avisit  JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;

/*if paramn in (106,201) and jm_aval_namen ne 0  then  jm_aval_namec=strip(scan(strip(jm_aval_namec),2,':')); */
/*else jm_aval_namec=jm_aval_namec;*/

if last.avisitn then jm_aval_namec=strip(jm_aval_namec)||"^n"; 

if jm_aval_namec ne "" and jm_aval_namen ne 0 then jm_aval_namec='^{nbspace 5}'||strip(jm_aval_namec); 
/*if paramn in (106) and last.avisitn and avisitn=12 then jm_aval_namec=tranwrd(jm_aval_namec,"^n","");*/

run;




data jm_aval_allreport1;
set jm_aval_allreport1;
by paramn avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;

 orig_rec_num=_n_;
 pageno = ceil(_n_/15);

/*   if jm_block in ("101","102","103") then pageno=1;*/
/*   if jm_block in ("104","105","106","107") then pageno=2;*/
/*   *if jm_block in ("106","107") then pageno=3;*/
/*   if jm_block in ("108","109") then pageno=4;*/
/*   if jm_block in ("110","111") then pageno=5;*/
/*   if jm_block in ("112","113") then pageno=6;*/
/**/
/*   if paramn=302 then pageno=1+pageno;*/
/*   if paramn=304 then pageno=2+pageno;*/
/*   if paramn=306 then pageno=3+pageno;*/
/*   if paramn=307 then pageno=4+pageno;*/
/*   if paramn=308 then pageno=5+pageno;*/
/*   if paramn=309 then pageno=6+pageno;*/
/*   if paramn=313 then pageno=7+pageno;*/
/*   if paramn=314 then pageno=8+pageno;*/
/*   if paramn=316 then pageno=9+pageno;*/
/*   if paramn=318 then pageno=9+pageno;*/
/*   if paramn=322 then pageno=9+pageno;*/
/*   if paramn=324 then pageno=900+pageno;*/
/*   if paramn=326 then pageno=900+pageno;*/
/*   if paramn=328 then pageno=900+pageno;*/
   

run;


proc sort data=jm_aval_allreport1;
by pageno paramn avisitn JM_BLOCK jm_aval_label jm_aval_namen;
run;

data jm_aval_allreport1;
set jm_aval_allreport1;
by pageno paramn avisitn JM_BLOCK jm_aval_label jm_aval_namen;
/*    array myarr{*} $ trtn:;*/
/*           do i=1 to dim(myarr);*/
/*          if paramn  in (106,201) and jm_aval_namen ne 0 and   myarr(i)=''  then myarr(i)='0(0)' ;*/
/*           end;*/

     groupvarn=orig_rec_num;
     jm_aval_namen=orig_rec_num;

run;

 proc freq data=jm_aval_allreport1 noprint;
    table PARAMN*param/out=freq nocol nopct;
 run;




%LET _default_box=%str(Parameter (SI Unit) | Timepoint);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=N, jm_breakvar=jm_aval_label);

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




%let dsname=T_9_03_02_01_04;
data tlfdata.&dsname;
set jm_aval_allreport1;

keep JM_: TRTN: PARAM:;
run;
