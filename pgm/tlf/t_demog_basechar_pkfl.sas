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

%macro t_demog_basechar_pkfl(trtvar=TRT01A,tab_page_size=12,
                   adsl_subset=%str(&TRTVAR.N in (1,2,3) and PKFL='Y')
                 );

   

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

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Randomized Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   
   *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
   data target;                             
      set ADSL;                             
      where &adsl_subset.;


	       if upcase(RACE)="AMERICAN INDIAN OR ALASKA NATIVE" then RACEN=1	;
	  else if upcase(RACE)="ASIAN" then RACEN=2	;
	  else if upcase(RACE)="BLACK OR AFRICAN AMERICAN" then RACEN=3	;
	  else if upcase(RACE)="NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" then RACEN=4	;
	  else if upcase(RACE)="WHITE" then RACEN=5;
	  else if upcase(RACE)="DECLINED TO STATE" then RACEN=6	;
	  else if upcase(RACE)="MULTIPLE" then RACEN=7	;
	  else if upcase(RACE)="MISSING" then RACEN=8	;


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

   	  	proc sql;
	  select * from target;
	quit;

	%if &sqlobs. gt 0 %then %do;

   *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                   

   *** Call JM_AVAL_COUNT macro once for each summary variable ***;                             
   %jm_aval_sum(JM_INDSN=target, jm_var=age, jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=101,JM_SIGD=0 ,
   JM_AVAL_LABEL=%bquote(Age (years)) );

 


   %jm_aval_count(
      jm_indsn=target,jm_var=agegr1n,jm_secondary_where=, jm_fmt=agegr1n., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=102, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Age Group 1, n (%))
      );
 

   %jm_aval_count(
      jm_indsn=target,jm_var=sexn,jm_secondary_where=, jm_fmt=sexn., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=103, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Gender, n (%))
      );
                               
   %jm_aval_count(
      jm_indsn=target,jm_var=racen,jm_secondary_where=, jm_fmt=racen., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=104, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Race, n (%))
      );

   %jm_aval_count(
      jm_indsn=target,jm_var=ethnicn,jm_secondary_where=, jm_fmt=ethnicn., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=105, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Ethnicity, n (%))
      );




   %jm_aval_sum(JM_INDSN=target, jm_var=hgtsc, jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=108,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Height (cm) at baseline) );

   %jm_aval_sum(JM_INDSN=target, jm_var=wgtbl, jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=109,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Weight (kg) at baseline) );

   %jm_aval_sum(JM_INDSN=target, jm_var=bmibl, jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=110,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Body Mass Index (kg/m^{super 2}) at baseline) );

  
   %jm_aval_count(
      jm_indsn=target,jm_var=childpotn,jm_secondary_where=, jm_fmt=childpotn., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=112, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Childbearing Potential for Females)
      );

	   %jm_aval_count(
      jm_indsn=target,jm_var=SSNRISN,jm_secondary_where=, jm_fmt=SSNRISN., 
      jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=113, jm_cntvar=usubjid,
      jm_aval_label=%bquote(Concomitant use of SSRIs/SNRIs at Baseline)
      );
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

   %jm_aval_sum_trans(
      jm_aval_input=jm_aval_alldata1(where=(JM_TYPE='COUNT')),jm_aval_output=jm_aval_trans2, 
      jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, JM_TRANS_VAR=COLVAL,jm_trans_id=jm_trtvarn
      );

   %macro update_trans;
      %do i=1 %to 2;
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
      jm_indsn1=jm_aval_trans1,jm_indsn2=jm_aval_trans2, jm_breakcnt=&tab_page_size., jm_contopt=Y, jm_groupopt=N, 
      jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   data jm_aval_allreport1;
      set jm_aval_allreport1 end=eos;
      if _name_='JM_NC' and trtn1='' then jm_aval_namen=0;
      _TYPE_='';
      if eos then jm_aval_namec=strip(tranwrd(jm_aval_namec,'^n',''));
   run;
%end;
	%else %do;
	  data _null_;
	    set jm_bign1 end=eos;
		 length trttxt $100;
		 if _n_=1 then trttxt='trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 else trttxt=strip(trttxt)||'trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 retain trttxt;
		 if eos then call symputx("trtimp",strip(trttxt));
		run;

		data jm_aval_allreport1;
			_TYPE_='FREQ';
			jm_aval_namec='No data to report';
			jm_aval_label='No data to report';
			jm_block='100';
			jm_aval_countc='';
			pageno=1;
			&trtimp.;
		run;
	%end;                       
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
%t_demog_basechar_pkfl;
