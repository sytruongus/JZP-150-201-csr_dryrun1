/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      24Sep2022
 * PROGRAM NAME:      t_dispo_003.sas
 * DESCRIPTION:       Template program to create "Study Disposition" Table
 * DATA SETS USED:    ADSL
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            ADSL_SUBSET     - ADSL subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y'
************************************************************************
PROGRAM MODIFICATION LOG
*************************************************************************
Programmer:  
Date:        
Description: 
*************************************************************************/
proc datasets lib=work memtype=data kill nolist;
quit;



*TITLE AND FOOTNOTES;
%JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
%JM_DATAPREP;

**Call Pre-processing Macro **;
%jm_tlf_pre(dtnames=adsl);

%let trtvar=TRT01A;
%let adsl_subset=%str(&trtvar.n in(1,2,3));
%let _default_box=Number of Participants, n (%);
%let _default_boxx=&_default_box.;
%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Full Analysis Set" trtn1 trtn2 trtn3 trtn99)  trtn999);

*** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
data target;                             
   set adsl;                             
  * where &adsl_subset. ;                             

   length trt_reas $2000 trt_complete $200;
   /*if dct01rs="" and dct02rs="" and dct03rs="" and dct04rs="" then trt_complete="Completed";
   else trt_complete="Discontinued";
   trt_reas=catx(",",dct01rs,dct02rs,dct03rs,dct04rs);
*/
   trtn=&TRTVAR.N;                             
   trt=&TRTVAR.;                             
   output;                             
if trtn  in (1,2,3) and FASFL="Y"  then do;
   trtn=99;                             
   trt="Total";                            
   output;  
   end;

run;


data enrl_tot;
set target;

if ENRLFL="Y" ;
   trtn=999;                             
   trt="Enrolled Analysis Set";                            
   output;
run;

data target;
set target enrl_tot;

     if SCRFL="Y" then SCRNFL=1;
else if SCRFL="N" then SCRNFL=2; 


if RFSTDTC ne "" then one_D="Y";
if EOTSTT="COMPLETED" then comp_SI="Y";
if EOTSTT="DISCONTINUED" then DISC_TRT="Y";

if EOSSTT="COMPLETED" then comp_S="Y";
if EOSSTT="DISCONTINUED" then DISC_STY="Y";

if COMPSFL="Y"  then SAF_comp="Y";
     if COMP04FL="Y"  then COMP04=1;
else if COMP04FL="N"  then COMP04=2;
     if COMP12FL="Y"  then COMP12=1;
else if COMP12FL="N"  then COMP12=2;


run;
 


%jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

%jm_bign (jm_indsn=target,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt,JM_BIGN_WHERE=);

* Participant Treatment Status *;
%jm_aval_count(
   jm_indsn=target,jm_var=SCRNFL,jm_fmt=SCR., jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=100, jm_cntvar=usubjid, jm_aval_label=%bquote(Number of Participants)
   );

   data jm_aval_count100;
   set jm_aval_count100;

     if JM_TRTVARN=999;
   run;

%jm_bign (jm_indsn=target,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt,JM_BIGN_WHERE=);



%jm_aval_count(
   jm_indsn=target,jm_var=RANDFL,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE=RANDFL='Y', 
   jm_block=101, jm_cntvar=usubjid, jm_aval_label=%bquote(Randomized)
   );
%jm_aval_count(
   jm_indsn=target,jm_var=one_D,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=102, jm_cntvar=usubjid, jm_aval_label=%bquote(Received at Least One Dose of Study intervention)
   );
%jm_aval_count(
   jm_indsn=target,jm_var=comp_SI,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=103, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed study intervention)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DISC_TRT,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=104, jm_cntvar=usubjid, jm_aval_label=%bquote(Discontinued Early from study intervention)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DCTREAS,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=105, jm_cntvar=usubjid, jm_aval_label=%bquote(Primary Reason for Early Discontinuation from study intervention)
   );

%jm_aval_count(
   jm_indsn=target,jm_var=comp_S,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=106, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed the study)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DISC_STY,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=107, jm_cntvar=usubjid, jm_aval_label=%bquote(Discontinued Early from Study)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DCSREAS,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=108, jm_cntvar=usubjid, jm_aval_label=%bquote(Primary Reason for Early Discontinuation from study)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=SAF_comp,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=109, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Safety Follow-up)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=SAF_comp,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=110, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Safety Follow-up)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=COMP04,jm_fmt=YN., jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=111, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Efficacy Follow-up at Week 4)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=COMP12,jm_fmt=YN., jm_bign=jm_bign1, jm_trtvarn=trtn,
   jm_block=112, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Efficacy Follow-up at Week 12)
   );

 

*  SET THE DATASETS;
%jm_aval_alldata(jm_outdsn=jm_aval_alldata1);

   data jm_bign_e;
   set jm_bign1;
   where JM_TRTVARN=999;

   run;


%jm_bign (jm_indsn=target,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt,JM_BIGN_WHERE=FASFL="Y");


%jm_aval_count(
   jm_indsn=target,jm_var=RANDFL,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE=RANDFL='Y' and FASFL="Y", 
   jm_block=101, jm_cntvar=usubjid, jm_aval_label=%bquote(Randomized)
   );
%jm_aval_count(
   jm_indsn=target,jm_var=one_D,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=102, jm_cntvar=usubjid, jm_aval_label=%bquote(Received at Least One Dose of Study intervention)
   );
%jm_aval_count(
   jm_indsn=target,jm_var=comp_SI,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=103, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed study intervention)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DISC_TRT,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=104, jm_cntvar=usubjid, jm_aval_label=%bquote(Discontinued Early from study intervention)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DCTREAS,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=105, jm_cntvar=usubjid, jm_aval_label=%bquote(Primary Reason for Early Discontinuation from study intervention)
   );

%jm_aval_count(
   jm_indsn=target,jm_var=comp_S,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=106, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed the study)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DISC_STY,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=107, jm_cntvar=usubjid, jm_aval_label=%bquote(Discontinued Early from Study)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=DCSREAS,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=108, jm_cntvar=usubjid, jm_aval_label=%bquote(Primary Reason for Early Discontinuation from study)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=SAF_comp,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=109, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Safety Follow-up)
   );

 %jm_aval_count(
   jm_indsn=target,jm_var=SAF_comp,jm_fmt=, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=110, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Safety Follow-up)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=COMP04,jm_fmt=YN., jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=111, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Efficacy Follow-up at Week 4)
   );
 %jm_aval_count(
   jm_indsn=target,jm_var=COMP12,jm_fmt=YN., jm_bign=jm_bign1, jm_trtvarn=trtn,JM_SECONDARY_WHERE= FASFL="Y", 
   jm_block=112, jm_cntvar=usubjid, jm_aval_label=%bquote(Completed Efficacy Follow-up at Week 12)
   );

 

*  SET THE DATASETS;
%jm_aval_alldata(jm_outdsn=jm_aval_alldata2);


 data jm_bign_f;
   set jm_bign1;
   where JM_TRTVARN^=999;
run;

 data jm_bign1;
   set jm_bign_e jm_bign_f;
 run;


data jm_aval_alldata1;
set jm_aval_alldata1;

if JM_TRTVARN=999;
run;

data jm_aval_alldata2;
set jm_aval_alldata2;

if JM_TRTVARN^=999;
run;


data jm_aval_alldata3;
set jm_aval_alldata1
    jm_aval_alldata2;

run;


*  TRANSPOSE THE DATASETS;
%jm_aval_sum_trans(jm_aval_input=jm_aval_alldata3,jm_aval_output=jm_aval_trans1, 
   jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, jm_trans_var=jm_aval_countc, jm_trans_id=jm_trtvarn
   );


   data jm_aval_trans1;
   set jm_aval_trans1;
   if JM_AVAL_NAMEC in ("   2: No","   3:Not Applicable") then delete;

   if JM_AVAL_NAMEC in ("   Y","   1: Yes") then JM_AVAL_NAMEC=strip(JM_AVAL_LABEL);

   if JM_BLOCK="100" then JM_AVAL_NAMEC=strip(scan(JM_AVAL_NAMEC,2,":"));
   run;


*  APPLY PAGEBREAK;
%jm_pgbrk(jm_indsn1=,jm_indsn2=jm_aval_trans1, jm_breakcnt=8, jm_contopt=N, jm_groupopt=N, jm_outdsn=jm_aval_allreport1);

data jm_aval_allreport1;
   set jm_Aval_allreport1;
   /*if strip(jm_aval_namec)=:'Complete' then jm_Aval_namen=1;
   else if strip(jm_aval_namec)=:'Ongoing' then jm_Aval_namen=2;
   else if strip(jm_aval_namec)=:'Discontin' then jm_Aval_namen=3;
   else jm_Aval_namen=_n_;

   if jm_block in('100','102') then jm_aval_namec="^{nbspace 2}"||strip(jm_aval_namec);
   else if jm_block in('101','103') then jm_aval_namec="^{nbspace 4}"||strip(jm_aval_namec);
*/
if JM_block in ("100","101","102","103","104","105") then pageno=1;
else pageno=2;

   jm_Aval_namen=_n_;
run;

proc sort data=jm_Aval_allreport1;
   by jm_block jm_aval_namen;
run;

data jm_aval_allreport1;
   set jm_aval_allreport1;
   by jm_block jm_aval_namen;
   if jm_block='100' and last.jm_block then jm_Aval_namec=strip(jm_Aval_namec)||'^n';
   output;
   if first.jm_block and input(jm_block,best.) in(105,108) then do;
      jm_aval_namec=strip(jm_Aval_label);
      jm_aval_namen=0;
      array myarr{*}$ trtn:;
      do i=1 to dim(myarr);
         myarr(i)='';
      end;
      output;
   end;
   drop i;
run;

proc sort data=jm_aval_allreport1;
   by jm_block jm_aval_namen;
run;

*ODS OPEN- OPENS RTF DESTINATION;
%jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

*REPORT- PROC REPORT MODULE;
options formchar='|_---|+|---+=|-/\<>*';

%jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y , jm_indentopt=N, 
   jm_breakopt=, jm_breakvar=,jm_byvar=);

*ODS CLOSE- CLOSES RTF DESTINATION;
%jm_odsclose;

