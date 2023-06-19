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
      where  paramcd in ("CGI0202") and  anl01fl="Y" and MFASFL="Y"; 
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

   %JM_AVAL_COUNT(JM_INDSN=target, jm_var= MFASFL, JM_SECONDARY_WHERE= avalc ne "" and avisitn=4, jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=100, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(CGI-C at End of Week 4^nNumber of Participants with at Least One Survey^n) );
data Jm_aval_count100;
set Jm_aval_count100;
    Jm_aval_countc=strip(put(Jm_aval_count,best.));
run;
%JM_AVAL_COUNT(JM_INDSN=target, jm_var= MFASFL, JM_SECONDARY_WHERE= avalc ne "" and avisitn=12, jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=101, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(CGI-C at End of Week 12^nNumber of Participants with at Least One Survey^n) );

data Jm_aval_count101;
set Jm_aval_count101;
    Jm_aval_countc=strip(put(Jm_aval_count,best.));
run;


 *** Create Treatment formats for reporting ***;

%jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
 %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=4,JM_SUFFIX=2);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=4, jm_bign=jm_bign2, 
                jm_trtvarn=trtn, JM_FMT=cgic., jm_block=105, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param,
                JM_AVAL_LABEL=%bquote(Week 4) );




%JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=12,JM_SUFFIX=2);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=12, jm_bign=jm_bign2, 
                jm_trtvarn=trtn, JM_FMT=cgic., jm_block=106, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param,
                JM_AVAL_LABEL=%bquote(Week 12) );


%*JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=12,JM_SUFFIX=3);
%JM_AVAL_COUNT(JM_INDSN=target, jm_var= crit3fl, JM_SECONDARY_WHERE= %str(crit3fl="Y" and avisitn in (4,12)), jm_bign=jm_bign1, jm_trtvarn=trtn, jm_block=109,
               jm_cntvar=usubjid, JM_BYVAR=avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Proportion of Very Much Improved and Much Improved) );




*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;


%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="COUNT")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=  avisitn avisit paramcd param  JM_BLOCK grpvar JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);

proc sort data=JM_AVAL_TRANS2;
by avisitn avisit;
run;


data obs;
set JM_AVAL_TRANS2;
where JM_BLOCK in ("100","101");

if JM_BLOCK in ("101") then do;
*grpvar="CGI-C at End of Week 12";
JM_AVAL_LABEL="CGI-C at End of Week 12";
JM_AVAL_NAMEC="CGI-C at End of Week 12";
end;


if JM_BLOCK in ("100") then do;
*grpvar="CGI-C at End of Week 4";
JM_AVAL_LABEL="CGI-C at End of Week 4";
JM_AVAL_NAMEC="CGI-C at End of Week 4";
end;

trtn1="";
trtn2="";
trtn3="";

run;

data JM_AVAL_TRANS2;
set obs JM_AVAL_TRANS2;
run;

data target;
set target;
if CRIT3FL="" then CRIT3FL="N";
run;

proc sort data=target;
by avisitn avisit paramcd param;
run;

ods trace on ;

ods output CMH=FRQ_cmh_1;
PROC FREQ DATA=target;
by avisitn avisit paramcd param;
TABLES SSNRISN*TRT*crit3fl/CMH ;

*TABLES TRTN*cri4fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (1,3) and avisitn in (4,12);
RUN;
ods trace off;

ods trace on ;
ods output PdiffCLs=frq_PdiffCLs_1;
PROC FREQ DATA=target;
by avisitn avisit paramcd param;
TABLES TRT*crit3fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (1,3) and avisitn in (4,12);
RUN;
ods trace off;


ods trace on ;

ods output CMH=FRQ_cmh_2;
PROC FREQ DATA=target;
by avisitn avisit paramcd param;
TABLES SSNRISN*TRT*crit3fl/CMH ;
*TABLES TRTN*cri4fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (2,3) and avisitn in (4,12);
RUN;
ods trace off;

ods trace on ;
ods output PdiffCLs=frq_PdiffCLs_2;
PROC FREQ DATA=target;
by avisitn avisit paramcd param;
TABLES TRT*crit3fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (2,3) and avisitn in (4,12);
RUN;
ods trace off;

data FRQ_cmh;
set FRQ_cmh_1(in=a where=(statistic=1))
    FRQ_cmh_2(in=b where=(statistic=1));

     if a then trtn=1;
else if b then trtn=2;
p_value=tranwrd(compress(put(prob,pvalue6.4)),'<.','<0.');

diff=strip(put(value,9.2));
run;


data frq_PdiffCLs;
set frq_PdiffCLs_1(in=a )
    frq_PdiffCLs_2(in=b );

     if a then trtn=1;
else if b then trtn=2;
CL_95p= compress('('||put(lowercl,9.2))||', '||compress(put(uppercl,9.2))||')';

run;

proc sort data=frq_cmh;
by avisitn avisit paramcd param;
run;


proc transpose data=FRQ_cmh out=tr_frq_cmh prefix=trtn;
by avisitn avisit paramcd param;
var diff p_value;
id trtn;
run;


proc sort data=frq_PdiffCLs;
by avisitn avisit paramcd param;
run;

proc transpose data=frq_PdiffCLs out=tr_frq_PdiffCLs prefix=trtn;
by avisitn avisit paramcd param;
var CL_95p;
id trtn;
run;

data frq_all;
length jm_aval_namec $200  trtn1 trtn2 $40.;
 set tr_frq_cmh(in=a)
     tr_frq_PdiffCLs(in=b);

if _name_="diff"   then do;
  jm_aval_namec="^{nbspace 5}Difference";
  jm_aval_namen=1;
end;

if _name_="p_value"   then do;
  jm_aval_namec="^{nbspace 5}p-value";
  jm_aval_namen=3;
end;

if _name_="CL_95p"   then do;
  jm_aval_namec="^{nbspace 5}95% CI";
  jm_aval_namen=2;
end;

JM_BLOCK="110";
run;


proc sort data=frq_all;
by avisitn avisit paramcd param;
run;

data frq_all;
set frq_all(in=a) 
    frq_all(in=b where=(JM_BLOCK="110" and jm_aval_namen=1) keep= JM_BLOCK jm_aval_namen jm_aval_namec avisitn avisit paramcd param);

	if b then do ;
      jm_aval_namen=0;
	  jm_aval_namec="Difference in Proportion from Placebo";
	end;


	if _name_="diff"    then ordn=0;
	if _name_="CL_95p"  then ordn=1;
	if _name_="p_value" then ordn=2;


	grpvar=strip(put(ordn,best.))||":"|| strip(jm_aval_namec);


run;



 Data final ;
 length jm_aval_label _name_  $200 ;
  set JM_AVAL_TRANS2;* LSM_STAT LSMD_OUT ;

  if grpvar="Y" then grpvar="00:"||strip(JM_AVAL_LABEL);
  *if grpvar="" and JM_BLOCK="109" then grpvar="00:Proportion with = 1 Unit of Improvement";
    jm_aval_namen=input(scan(grpvar,1,':'),best.); 
     jm_aval_namec=scan(grpvar,2,':'); 
     jm_aval_label=strip(jm_aval_namec);

	 if JM_BLOCK in ("105","106") then jm_aval_namec="^{nbspace 5}"||strip(jm_aval_namec);

 RUN ;



data final;
set final;* dummy;
   ordn=jm_aval_namen;
run;
proc sort data=final;
by avisitn avisit JM_BLOCK  jm_aval_namen ;
run;


data final;
set final;
by avisitn avisit JM_BLOCK  jm_aval_namen ;



 jm_aval_label=strip(jm_aval_namec);
retain block 0;
if first.avisitn then block=block+1;

    *JM_BLOCK=strip(put(block,best.));

retain ord1 0;
if first.avisitn then ord1=1;
else ord1=ord1+1;

ordc=put(ord1,z2.);
 grpvar=ordc||":"||strip(jm_aval_label);

jm_aval_namen=ord1;

run;

proc sort data=frq_all;
by avisitn avisit paramcd param  JM_BLOCK  jm_aval_namen ;
run;

proc sort data=final;
by avisitn avisit paramcd param  JM_BLOCK  jm_aval_namen ;
run;

data final;
set final(drop=block) frq_all;
by avisitn avisit paramcd param  JM_BLOCK jm_aval_namen;
*jm_aval_namen=0.5;

if jm_aval_label="" then do;
    jm_aval_label=strip(jm_aval_namec);
	
	end;

	retain block 0;
if first.JM_BLOCK then block=block+1;

    JM_BLOCK=strip(put(block,best.));
run;



*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 14, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

 if jm_aval_namec="^{nbspace 5}Very Much Worse" then jm_aval_namec=strip(jm_aval_namec)||"^n";
 if jm_aval_namec="Proportion of Very Much Improved and Much Improved" then jm_aval_namec=strip(jm_aval_namec)||"^n";
 

 if jm_aval_namec="CGI-C at End of Week 4^nNumber of Participants with at^n^{nbspace 4}Least One Survey^n"  then jm_aval_namec="^{nbspace 2}Number of Participants with at Least One Survey^n";
 if jm_aval_namec="CGI-C at End of Week 12^nNumber of Participants with at^n^{nbspace 4}Least One Survey^n" then jm_aval_namec="^{nbspace 2}Number of Participants with at Least One Survey^n";
GROUPVARN=0.5;

     if avisitn=4 then pageno=1;
else if avisitn=12 then pageno=2;
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1); 

%LET _default_box=%str(Variable^n     ^{nbspace 5}Category);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, 
	jm_breakopt=N, jm_breakvar=);

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
