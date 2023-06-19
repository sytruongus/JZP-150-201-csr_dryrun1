/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08SEP2022
 * PROGRAM NAME:      t_demog_basechar_001.sas
 * DESCRIPTION:       Template program to create "Summary of Demographic Data and Baseline Characteristics" Table
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

%macro t_ex_saffl(trtvar=TRT01A,tab_page_size=12,
                   adsl_subset=%str(&TRTVAR.N in (1,2,3) and saffl='Y'),
				   adexsum_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y' )
                 );

   

   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;

   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl);

      data _null_;
     
       tab_box='Parameter|Statistic';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Treatment Group" trtn1 trtn2 trtn3) );
   
    *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
   data ADSL;                             
      set ADSL;                             
      where &adsl_subset. ;                             
      trtn=&TRTVAR.N;                             
      trt=&TRTVAR.;                             
                          
                           
   run;                             
    
   proc sort data=ADSL;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
    
   *** Create a macro variable for storing ADAE dataset name from the list of datasets ***;                             
   data ADEXSUM ;                             
      set adam.ADEXSUM ;                             
      where &adexsum_subset. ; 
      evnt=_n_; 
      trtn=&TRTVAR.N;                             
      trt=&TRTVAR.;                             
                            
   run;                             
    
   proc sort data=ADEXSUM ;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
    
   *** Create TARGET dataset by combing the Working datasets ***;                             
   data target;                             
      merge ADSL(in= a) ADEXSUM (in= b);                             
      by studyid usubjid trtn trt;                             
      if a;                             
   run;                             
   *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                   

   *** Call JM_AVAL_COUNT macro once for each summary variable ***;                             
   %jm_aval_sum(JM_INDSN=target, jm_var=aval,jm_secondary_where=%str(paramcd="EXPDAVG"), jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=101,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Average Total Daily Dose (mg/day)) );



  *** Call JM_AVAL_COUNT macro once for each summary variable ***;                             
   %jm_aval_sum(JM_INDSN=target, jm_var=aval,jm_secondary_where=%str(paramcd="EXDUR"), jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=102,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Duration of Exposure (days)) );

 
 
   *PROC TEMPLATE CODE FOR STYLE ELEMENT ;                             
   %JM_TEMPLATES(JM_POINTSIZE= );    
                               
   * SET THE DATASETS ;                             
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1);
                               
   *  TRANSPOSE THE DATASETS;
   %jm_aval_sum_trans(
      jm_aval_input=jm_aval_alldata1(where=(JM_TYPE='SUMMARY')),jm_aval_output=jm_aval_trans1, 
      jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, 
      JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC /*JM_Q1C_Q3C*/ JM_RANGEC,jm_trans_id=jm_trtvarn
      );


	  
   %macro update_trans;
      %do i=1 %to 1;
         data jm_aval_trans&i.;
            set jm_aval_trans&i.;
            %if &i.=1 %then %do;
               jm_aval_namen=_n_;
               jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);
            %end;
            %else %do;
               if index(jm_aval_namec,':') gt 0 then do;
                  jm_aval_namen=input(scan(trim(left(jm_aval_namec)),1,':'),best.);
                  jm_aval_namec='^{nbspace 2}'||strip(scan(strip(jm_aval_namec),2,':'));
               end;
               else do;
                  jm_aval_namen=_n_;
                  jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);
               end;
            %end;
         run;

         proc sort data=jm_aval_trans&i.;
            by jm_block jm_aval_namen;
         run;

         data jm_aval_Trans&i.;
            set jm_aval_trans&i. end=eos;
            by jm_block jm_aval_namen;
            if last.jm_block then jm_aval_namec=strip(jm_aval_namec)||'^n';
            output;
            if first.jm_block then do;
               jm_aval_namec=strip(jm_aval_label);
               jm_aval_namen=0;
               array myarr{*} $ trtn:;
               do i=1 to dim(myarr);
                  myarr(i)='';
               end;
               output;
            end;
            drop i;
         run;

         proc sort data=jm_aval_trans&i.;
            by jm_block jm_aval_namen;
         run;
      %end;
   %mend;
   %update_trans;

   *  APPLY PAGEBREAK;
   %jm_pgbrk(
      jm_indsn1=jm_aval_trans1,jm_indsn2=, jm_breakcnt=&tab_page_size., jm_contopt=Y, jm_groupopt=N, 
      jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   data jm_aval_allreport1;
      set jm_aval_allreport1 end=eos;
      if _name_='JM_NC' and trtn1='' then jm_aval_namen=0;
      _TYPE_='';
      if eos then jm_aval_namec=strip(tranwrd(jm_aval_namec,'^n',''));
   run;
    
   *** Clear the header on the left column ***;
   %*let _default_box=;

   *ODS OPEN- OPENS RTF DESTINATION;
   %jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

   *REPORT- PROC REPORT MODULE;
   %jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y, jm_indentopt=N, 
      jm_breakopt=, jm_breakvar=,jm_byvar=);

   *ODS CLOSE- CLOSES RTF DESTINATION;
   %jm_odsclose;

%mend;
%t_ex_saffl;
