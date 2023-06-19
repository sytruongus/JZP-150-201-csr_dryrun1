/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08SEP2022
 * PROGRAM NAME:      t_pop_001.sas
 * DESCRIPTION:       Template program to create "Summary of Analysis Sets" Table
 * DATA SETS USED:    ADSL
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
 *            ADSL_SUBSET     - ADSL subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y'
************************************************************************
 PROGRAM MODIFICATION LOG
 *************************************************************************
 Programmer:  
 Date:        
 Description: 
 ************************************************************************/

PROC DATASETS LIB=WORK MEMTYPE=DATA KILL;QUIT;
options orientation=landscape missing=' ' nodate nonumber;

%macro t_con_strata(trtvar=SERONOE,tab_page_size=16,
                   adsl_subset=%str(&TRTVAR.N in (1,2) and FASFL='Y')
                 );

 

   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;

   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl);

	%let _default_box=Total Number, n (%);
	%let _default_boxx=&_default_box.;


	  data _null_;
     
       tab_box='Concomitant Use of SSRI/SNRI Recorded in IRT';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'Concomitant Use of SSRI/SNRI Recorded in EDC" trtn1 trtn2 trtn99)  trtn990 trtn999);

   *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
   data target;                             
      set ADSL;                             
      where &adsl_subset.;
      /*if saffl ne 'Y' then saffl='N';
	  if saffl ne 'Y' then saffl='N';
      if mittfl ne 'Y' then mittfl='N';*/
       
	  if modfl ne 'Y' then modfl='';
      *ittfl=mittfl;
      trtn=&trtvar.n;
      trt=SERONORE;                             
      output;                             
      trtn=99;                             
      trt="Total";                            
      output;                             
   run;  

  data target;
   set target;
     output;

   if SERONOIN in (1,2) then SERONOIN=3 ;
  output;

  run;
 


 
   proc sort data=target;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
    
   *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(FASFL='Y'),JM_SUFFIX=1);                   

   *** Call JM_AVAL_COUNT macro once for each summary variable ***;                             
   %jm_aval_count(
      jm_indsn=target,jm_var=SERONOIN,jm_secondary_where= %str(SERONOIN in (1,2,3)), jm_fmt=$ynt., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=101, jm_cntvar=usubjid, jm_aval_label=%bquote(SERONOIN)
      );
     

   *PROC TEMPLATE CODE FOR STYLE ELEMENT ;                             
   %JM_TEMPLATES(JM_POINTSIZE= );    
                               
   * SET THE DATASETS ;                             
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1);


   data JM_AVAL_ALLDATA1;
   set JM_AVAL_ALLDATA1 ;
    colval=strip(put(JM_AVAL_COUNT,best.));
   run;

  data jm_bign1;
  length TRTVAR $200.;
  set  jm_bign1;

  JM_AVAL_BIGN_LABEL=strip(scan(JM_AVAL_BIGN_LABEL,1,"|"));
output;
 
  do JM_TRTVARN=990, 999;
if JM_TRTVARN=990 then   do;
   JM_AVAL_BIGN_LABEL="Cohen’s Kappa";
   TRTVAR="Cohen’s Kappa";
   JM_AVAL_START=990;
   trtn=990;
   JM_AVAL_BIGN=0;

end;

if JM_TRTVARN=999 then  do;
   JM_AVAL_BIGN_LABEL="Quality of Agreement";
   TRTVAR="Quality of Agreement";
   JM_AVAL_START=999;
   trtn=999;
   JM_AVAL_BIGN=0;
end;
output;
end;
run;

proc sort data =jm_bign1 noduprecs;
by trtn;
run;

                               
   *  TRANSPOSE THE DATASETS;
   %jm_aval_sum_trans(
      jm_aval_input=jm_aval_alldata1(where=(JM_TYPE='COUNT')),jm_aval_output=jm_aval_trans2, 
      jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, JM_TRANS_VAR=COLVAL,jm_trans_id=jm_trtvarn
      );


  /** Cappa's Value*/
	  data chk;
	  set target;
	  if trtn=99 and SERONOIN=3;
	  run;
ods trace on;
ods output  Kappa=kappa;

 PROC FREQ data=chk;
TABLE SERONORI*SERONORE / AGREE;
   
 RUN;
ods trace off;

 data kappa;
 length trtn990 trtn999 $200.;
 set kappa;
 if Name1="_KAPPA_";
 trtn990=strip(put(nValue1,5.2));

      if nValue1<=0.20 then trtn999="Poor";
 else if 0.21<=nValue1<=0.40 then trtn999="Fair";
 else if 0.41<=nValue1<=0.60 then trtn999="Moderate";
 else if 0.61<=nValue1<=0.80 then trtn999="Good";
 else if 0.81<=nValue1<=1.00 then trtn999="Very good";

JM_AVAL_NAMEC="   3:Total";
JM_AVAL_LABEL="SERONOIN";
JM_BLOCK="101";
keep JM_AVAL_NAMEC JM_AVAL_LABEL JM_BLOCK trtn990 trtn999;

run;



   data jm_aval_trans2;
      merge  jm_Aval_trans2 kappa;
	  by JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC;

jm_aval_namen=input(strip(scan(JM_AVAL_NAMEC,1,":")),best.);
      
   run;





   proc sort data=jm_aval_trans2;
      by jm_block jm_aval_namen;
   run;

   *  APPLY PAGEBREAK;
   %jm_pgbrk(
      jm_indsn1=,jm_indsn2=jm_aval_trans2, jm_breakcnt=&tab_page_size., jm_contopt=Y, jm_groupopt=N, 
      jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   *ODS OPEN- OPENS RTF DESTINATION;
   %jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

   *REPORT- PROC REPORT MODULE;
   options formchar='|_---|+|---+=|-/\<>*';

   %jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y , jm_indentopt=N, 
      jm_breakopt=, jm_breakvar=,jm_byvar=);

   *ODS CLOSE- CLOSES RTF DESTINATION;
   %jm_odsclose;

%mend;
%t_con_strata;
