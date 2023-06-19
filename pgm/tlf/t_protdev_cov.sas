/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      24Sep2022
 * PROGRAM NAME:      t_protdev_001.sas
 * DESCRIPTION:       Template program to create "Counts of protocol deviations " Table
 * DATA SETS USED:    ADSL, ADDV
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
 *            ADSL_SUBSET     - ADSL subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y'
 *            ADDV_SUBSET     - ADDV subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y' and 
************************************************************************
 PROGRAM MODIFICATION LOG
 *************************************************************************
 Programmer:  
 Date:        
 Description: 
 ************************************************************************/

PROC DATASETS LIB=WORK MEMTYPE=DATA KILL;QUIT;
options orientation=landscape missing=' ' nodate nonumber;
%macro t_protdev(trtvar=TRT01A,tab_page_size=16,
                   adsl_subset=%str(&TRTVAR.N in (1,2,3) and FASFL='Y'),
                   addv_subset=%str(&TRTVAR.N in (1,2,3) and FASFL='Y' and COVFL='Y')
                   );

	

	*TITLE AND FOOTNOTES;
	%JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

	*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
	%JM_DATAPREP;

	**Call Pre-processing Macro **;
	%jm_tlf_pre(dtnames=adsl addv);

	   data _null_;      
       tab_box='Protocol Deviation Category per CTMS';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'Randomized Treatment Group" trtn1 trtn2 trtn3)  trtn99);

	*** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
	data ADSL;                             
	   set ADSL;                             
	   where &adsl_subset.;
	   trtn=&trtvar.n;
	   trt=&trtvar.;                             
	   output;                             
	   trtn=99;                             
	   trt="Total";                            
	   output;                             
	run;                             
	 
	proc sort data=ADSL;                             
	   by studyid usubjid trtn trt;                             
	   where trtn ne .;                             
	run;                             
	 
	*** Create a macro variable for storing ADAE dataset name from the list of datasets ***;                             
	data ADDV ;                             
	   set ADDV ;                             
	   where &addv_subset.;
	   trtn=&trtvar.n;
	   trt=&trtvar.;                             
	   output;                             
	   trtn=99;                             
	   trt="Total";                            
	   output;                             
	run;                             
	 
	proc sort data=ADDV ;                             
	   by studyid usubjid trtn trt;                             
	   where trtn ne .;                             
	run;                             
	 
	*** Create TARGET dataset by combing the Working datasets ***;                             
	data target;                             
	   merge ADSL(in= a) ADDV (in= b);                             
	   by studyid usubjid trtn trt;                             
	   if a;                             
	run;                             
	 
	*** Create Treatment formats for reporting ***;
	%jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

	%JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(fasfl='Y'),JM_SUFFIX=1);                   

	*** Call JM_AVAL_COUNT macro once for each summary variable ***;                             
	%jm_aval_count(
	   jm_indsn=target,jm_var=DVCAT,jm_secondary_where=%str(upcase(dvscat)='ALL' and dvcat ne ''), jm_fmt=, 
	   jm_bign=jm_bign1, jm_trtvarn=trtn,jm_block=101, jm_cntvar=usubjid,
	   jm_aval_label=%bquote(Number of participants with any protocol deviations)
	   );
	   
  	proc sql;
	  select * from jm_aval_count101;
	quit;

	%if &sqlobs. gt 0 %then %do; 
	%jm_aval_count(
	   jm_indsn=target,jm_var=DVCAT,jm_secondary_where=%str(upcase(dvscat)='MAJOR' and dvcat ne ''), jm_fmt=, 
	   jm_bign=jm_bign1,jm_trtvarn=trtn,jm_block=102, jm_cntvar=usubjid,
	   jm_aval_label=%bquote(Number of participants with major protocol deviations)
	   );

	%jm_aval_count(
	   jm_indsn=target,jm_var=DVCAT,jm_secondary_where=%str(upcase(dvscat)='MINOR' and dvcat ne ''), jm_fmt=, 
	   jm_bign=jm_bign1,jm_trtvarn=trtn,jm_block=103, jm_cntvar=usubjid,
	   jm_aval_label=%bquote(Number of participants with minor protocol deviations)
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
	   jm_Aval_namen=_n_;
	run;
	proc sort data=jm_aval_trans2;
	   by jm_block jm_aval_namen;
	run;

	data jm_aval_trans2;
	   set jm_aval_trans2;
	   by jm_block jm_aval_namen;
	   jm_aval_namec="^{nbspace 2}"||strip(jm_aval_namec);
	   output;
	   if first.jm_block then do;
	      jm_aval_namec='^n'||strip(jm_Aval_label);
	      jm_aval_namen=0;
	      array myarr{*}$ trtn:;
	      do i=1 to dim(myarr);
	         myarr(i)='';
	      end;
	      output;
	   end;
	   drop i;
	run;

	proc sort data=jm_aval_trans2;
	   by jm_block jm_aval_namen;
	run;

	*  APPLY PAGEBREAK;
	%jm_pgbrk(
	   jm_indsn1=,jm_indsn2=jm_aval_trans2, jm_breakcnt=&tab_page_size., jm_contopt=Y, jm_groupopt=N, 
	   jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
	   );
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
	*ODS OPEN- OPENS RTF DESTINATION;
	%jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

	*REPORT- PROC REPORT MODULE;
	options nonumber nobyline;
	options formchar='|_---|+|---+=|-/\<>*';
	/*%let _default_box=Total Number, n (%);
	%let _default_boxx=Total Number, n (%);
	%let _default_span_head=;*/

	%jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y , jm_indentopt=N, 
	   jm_breakopt=, jm_breakvar=,jm_byvar=);

	*ODS CLOSE- CLOSES RTF DESTINATION;
	%jm_odsclose;

%mend;
%t_protdev;
