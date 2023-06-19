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
%macro t_pop(trtvar=TRT01A,tab_page_size=16,
                   adsl_subset=%str(&TRTVAR.N in (1,2,3) and FASFL='Y')
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
     
       tab_box='Analysis Set, n (%)';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Randomized Treatment Group" trtn1 trtn2 trtn3)  trtn99);

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
      trt=&trtvar.;                             
      output;                             
      trtn=99;                             
      trt="Total";                            
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
      jm_indsn=target,jm_var=FASFL,jm_secondary_where=, jm_fmt=$ync., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=101, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Full Analysis Set)
      );
                               
   %jm_aval_count(
      jm_indsn=target,jm_var=SAFFL,jm_secondary_where=, jm_fmt=$ync., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=102, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Safety Analysis Set)
      );

   %jm_aval_count(
      jm_indsn=target,jm_var=MFASFL,jm_secondary_where=, jm_fmt=$ync., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=103, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Modified Full Analysis Set)
      );

   %jm_aval_count(
      jm_indsn=target,jm_var=PKFL,jm_secondary_where=, jm_fmt=$ync., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=104, jm_cntvar=usubjid,
      jm_aval_label=%bquote(PK Analysis Set)
      );


   %jm_aval_count(
      jm_indsn=target,jm_var=PDFL,jm_secondary_where=, jm_fmt=$ync., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=103, jm_cntvar=usubjid,
      jm_aval_label=%bquote(PD Analysis Set)
      );

   *PROC TEMPLATE CODE FOR STYLE ELEMENT ;                             
   %JM_TEMPLATES(JM_POINTSIZE= );    
                               
   * SET THE DATASETS ;                             
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1);
                               
   *  TRANSPOSE THE DATASETS;
   %jm_aval_sum_trans(
      jm_aval_input=jm_aval_alldata1(where=(JM_TYPE='COUNT')),jm_aval_output=jm_aval_trans2, 
      jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, JM_TRANS_VAR=COLVAL,jm_trans_id=jm_trtvarn
      );

   data jm_aval_trans2;
      set jm_Aval_trans2;
      if strip(jm_aval_namec)='Y' then do;
         jm_Aval_namen=1;
         jm_aval_namec=strip(jm_aval_label);
      end;
      else do;
         jm_Aval_namen=2;
         jm_aval_namec='^{nbspace 2}Total participants excluded^n';
      end;

	  if jm_Aval_namen=1;
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
%t_pop;
