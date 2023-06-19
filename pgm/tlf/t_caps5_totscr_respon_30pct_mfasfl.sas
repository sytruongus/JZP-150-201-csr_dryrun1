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
      where  paramcd in ("PTSDTSEV") and  anl01fl="Y" and MFASFL="Y"; 
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

%JM_AVAL_COUNT(JM_INDSN=target, jm_var= CRIT1FL, JM_SECONDARY_WHERE=%str(CRIT1FL="Y") , jm_bign=jm_bign1, jm_trtvarn=trtn, jm_block=109,
               jm_cntvar=usubjid, JM_BYVAR= , JM_AVAL_LABEL=%bquote(>=30%) );

%JM_AVAL_COUNT(JM_INDSN=target, jm_var= CRIT2FL, JM_SECONDARY_WHERE=%str(CRIT2FL="Y") , jm_bign=jm_bign1, jm_trtvarn=trtn, jm_block=110,
               jm_cntvar=usubjid, JM_BYVAR= , JM_AVAL_LABEL=%bquote(<30%) );


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;


%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="COUNT")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=    JM_BLOCK grpvar JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);

proc sort data=JM_AVAL_TRANS2;
by JM_BLOCK;
run;


data dummy;
do i=109 to 110;
output;
end;
run;

data dummy;
length JM_AVAL_LABEL $2000.;
set dummy;

jm_block=strip(put(i,best.));
     if jm_block="109" then JM_AVAL_LABEL=">=30%";
else if jm_block="110" then JM_AVAL_LABEL="<30%";
run;

data JM_AVAL_TRANS2;
length JM_AVAL_LABEL $2000.;
merge dummy(in=a) JM_AVAL_TRANS2(in=b);
by jm_block;

JM_AVAL_NAMEC=strip(JM_AVAL_LABEL);
JM_block="109";
JM_AVAL_LABEL="Percent improvement in the CAPS-5 total^nscore from Baseline to End of Week 12";

if trtn1="" then trtn1="0";
if trtn2="" then trtn2="0";
if trtn3="" then trtn3="0";
run;


data target;
set target;
/*if CRIT1FL="" then CRIT1FL="N";
if CRIT2FL="" then CRIT2FL="N";

if CRIT1FL="Y"   then CRITCFL="Y";
else CRITCFL="N";*/
run;


proc freq data=target noprint;
 table usubjid*CRIT1FL*CRIT2FL/out=chk nocol nopct;
run;


%macro cmh;

  proc sql noprint;
  create table sub as
     select  count(distinct usubjid) as count	  from target
	 where CRIT1FL="Y"    ;
  quit;

  data sub;
  set sub;

  call symput("subj",count);
  run;
  %put &subj;


  %if &subj >=1 %then %do;

  proc freq data=target noprint;
   table usubjid*SSNRISN*avisitn*trtn*trt*CRIT1FL/out=frq_(keep=usubjid SSNRISN TRT CRIT1FL trtn avisitn) nocol nopct;
   where trtn in (1,3);
   run;

   data frq_;
   set frq_;

   if CRIT1FL="" then CRIT1FL="N";
   run;


  	
ods trace on ;

ods output CMH=FRQ_cmh_1;
PROC FREQ DATA=frq_;
TABLES SSNRISN*TRT*CRIT1FL/CMH ;

*TABLES TRTN*cri4fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (1,3) and avisitn=12;
RUN;

ods trace off;

ods trace on ;
ods output PdiffCLs=frq_PdiffCLs_1;
PROC FREQ DATA=target;
TABLES TRT*CRIT1FL/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (1,3) and avisitn=12;
RUN;
ods trace off;


ods trace on ;

ods output CMH=FRQ_cmh_2;
PROC FREQ DATA=target;
TABLES SSNRISN*TRT*CRIT1FL/CMH ;
*TABLES TRTN*cri4fl/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (2,3) and avisitn=12;
RUN;
ods trace off;

ods trace on ;
ods output PdiffCLs=frq_PdiffCLs_2;
PROC FREQ DATA=target;
TABLES TRT*CRIT1FL/RISKDIFF(CL=(WILSON(CORRECT)));
where trtn in (2,3) and avisitn=12;
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


proc transpose data=FRQ_cmh out=tr_frq_cmh prefix=trtn;
var diff p_value;
id trtn;
run;

proc transpose data=frq_PdiffCLs out=tr_frq_PdiffCLs prefix=trtn;

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


data frq_all;
set frq_all(in=a) 
    frq_all(in=b where=(JM_BLOCK="110" and jm_aval_namen=1) keep= JM_BLOCK jm_aval_namen jm_aval_namec);

	if b then do ;
      jm_aval_namen=0;
	  jm_aval_namec="Difference in Proportion from Placebo";
	end;

run;
%end;

%else %do;

data frq_all;
length JM_BLOCK $12. trtn1-trtn3 $40. jm_aval_namec $2000.;
JM_BLOCK="110";
do i=0 to 3;
if i=0 then do;
jm_aval_namec="Difference in Proportion from Placebo";
jm_aval_namen=0;
end;

else if i=1 then do;
jm_aval_namec="Difference";
jm_aval_namen=1;
trtn1="na";
trtn2="na";
trtn3="na";
end;

else if i=2 then do;
jm_aval_namec="95% CI";
jm_aval_namen=2;
trtn1="(na,na)";
trtn2="(na,na)";
trtn3="(na,na)";
end;
else if i=3 then do;
jm_aval_namec="p-value";
jm_aval_namen=3;
trtn1="na";
trtn2="na";
trtn3="na";
end;
output;
end;
run;
%end;

%mend;

%cmh;


data obs;
set JM_AVAL_TRANS2;
where i=109 and jm_block="109";
jm_aval_namec="Percent improvement in the CAPS-5 total^nscore from Baseline to End of Week 12";
i=0;


keep i jm_block jm_aval_namec;
run;


Data final ;
 length jm_aval_label _name_  $200 ;
  set  JM_AVAL_TRANS2;

  if grpvar=""  then grpvar="Percent improvement in the CAPS-5 total^nscore from Baseline to End of Week 12^n";

     jm_aval_namen=_n_; 
     jm_aval_namec=strip(jm_aval_namec); 

	 if jm_aval_namec="<30%" then jm_aval_namec=strip(jm_aval_namec)||"^n"; 
     *jm_aval_label=strip(jm_aval_namec);

 RUN ;


 data final;
set obs final frq_all;
by JM_BLOCK ;

 jm_aval_namen=_n_; 
    if i ne 0 then  jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec); 
run;
data final;
set final;* dummy;
   ordn=jm_aval_namen;
run;
proc sort data=final;
by JM_BLOCK jm_aval_namen ;
run;


data final;
set final;
by JM_BLOCK jm_aval_namen ;
run;

proc sort data=frq_all;
by JM_BLOCK  jm_aval_namen ;
run;

proc sort data=final;
by JM_BLOCK  jm_aval_namen ;
run;





*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 14, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;
     groupvarn=orig_rec_num;
     jm_aval_namen=orig_rec_num;
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1); 

%LET _default_box=Timepoint;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);


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
