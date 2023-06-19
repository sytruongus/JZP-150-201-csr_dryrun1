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

%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Randomized Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   
      data ADSL;                             
      set ADSL;                             
      where TRT01AN in (1,2,3) and MFASFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A; 

      output;                             
      trtn=99;                             
      trt="Total";                            
      output;  
                            
   run;                             
    
   proc sort data=ADSL;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
 
   *** Create a macro variable for storing ADQS dataset name from the list of datasets ***;                             
   data ADQS ;                             
      set adam.ADQS3 ;                             
      where parcat1  in ("LEC-5 EXTENDED VERSION")   and anl01fl="Y" and MFASFL="Y";
      
	  trtn=TRTAN;                             
      trt=TRTA; 
       output;                             
      trtn=99;                             
      trt="Total";                            
      output;  
                                             
                              
   run;                             
    
   proc sort data=ADQS ;                             
      by studyid usubjid trtn trt;                         
                            
   run;                             
 
   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target;                             
      merge ADSL(in= a) 
            ADQS (in= b);                             
      by studyid usubjid trtn trt;                             
      if a;  


	  if INDEXFL eq "Y" then INDEXTFL = "Y" ;
	  if paramcd in ("LEC01B21","LEC01B22","LEC01B31" ,"LEC01B32","LEC01B33","LEC01B6","LEC01B7","LEC01B8","LEC01B8N") then INDEXTFL="";

if TRAUMAFL eq "Y" and index(PARAMCD,"LEC")>=1  then paramn=input(compress(paramcd,"LEC"),best.);

paramn=paramn-100;


if INDEXTFL eq "Y" and index(PARAMCD,"LEC01B")>=1  then paramn=input(tranwrd(paramcd,"LEC01B",""),best.);


if paramcd in ("NTRAUMA") and aval>3 the avalc=">3";
   run;                             
    
proc freq data=target noprint;
table paramn*PARAMCD*PARAM/out=frq_chk;
*where paramn ne .;
where INDEXTFL eq "Y" ;
run;

data frq_chk1;
length newcd $200.;
set frq_chk;
newcd=put(paramn-100,z2.)||":"||strip(param);
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                 


*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;


 *** Create Treatment formats for reporting ***;
                  
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avalc, JM_SECONDARY_WHERE= TRAUMAFL eq "Y" and index(PARAMCD,"LEC")>=1 , jm_bign=jm_bign1, jm_trtvarn=trtn,JM_BYVARFMT=LECT.,
                JM_FMT=, jm_block=102, jm_cntvar=usubjid, JM_BYVAR=paramn   , JM_AVAL_LABEL=%bquote(Type of Trauma) );

              
%JM_AVAL_COUNT(JM_INDSN=target, jm_var= avalc, JM_SECONDARY_WHERE= avalc ne "" and paramcd in ("NTRAUMA"), jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=,
jm_block=103, jm_cntvar=usubjid, JM_BYVAR= , JM_AVAL_LABEL=%bquote(Number of Trauma) );
                  

%JM_AVAL_COUNT(JM_INDSN=target, jm_var= INDEXFL, JM_SECONDARY_WHERE= INDEXTFL eq "Y" and index(PARAMCD,"LEC")>=1 , jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=,JM_BYVARFMT=LECT.,
jm_block=104, jm_cntvar=usubjid, JM_BYVAR=   paramn  , JM_AVAL_LABEL=%bquote(Index Event) );

%jm_aval_sum(JM_INDSN=target, jm_var=aval, JM_SECONDARY_WHERE= paramcd in ("INDEXYRS")  , jm_bign=, jm_trtvarn=trtn,    JM_BLOCK=105,JM_SIGD=1 ,
   JM_AVAL_LABEL=%bquote(Time since Index Event Occurred (Continuous)) );


                
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= AVALCA1N, JM_SECONDARY_WHERE= avalc ne "" and paramcd in ("INDEXYRS"), jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=indxn.,
jm_block=106, jm_cntvar=usubjid, JM_BYVAR= , JM_AVAL_LABEL=%bquote(Time since Index Event Occurred (Categorical)) );


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
  %jm_aval_sum_trans(
      jm_aval_input=jm_aval_alldata1(where=(JM_TYPE='SUMMARY')),jm_aval_output=jm_aval_trans1, 
      jm_trans_by=jm_block grpvar jm_aval_label jm_aval_namec, 
      JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC /*JM_Q1C_Q3C*/ JM_RANGEC,jm_trans_id=jm_trtvarn
      );


%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="COUNT")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=  paramn  JM_BLOCK grpvar JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);




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

  %jm_pgbrk(
      jm_indsn1=jm_aval_trans1,jm_indsn2=jm_aval_trans2, jm_breakcnt=20, jm_contopt=Y, jm_groupopt=N, 
      jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   data jm_aval_allreport1;
      set jm_aval_allreport1 end=eos;
      if _name_='JM_NC' and trtn1='' then jm_aval_namen=0;
      _TYPE_='';
      if eos then jm_aval_namec=strip(tranwrd(jm_aval_namec,'^n',''));

	   array myarr{*} $ trtn:;
           do i=1 to dim(myarr);
          if jm_aval_namen  not in (0) and  myarr(i)='' and JM_BLOCK not in (105) then myarr(i)='0' ;
           end;

      /*
	       if JM_BLOCK in ("101","102","103","104") then pageno=1;
	  else if JM_BLOCK in ("105","106") then pageno=2;
	  else if JM_BLOCK in ("107","108","109","110") then pageno=3;
	    else if JM_BLOCK in ("111","112") then pageno=4;*/
   run;



   *ODS OPEN- OPENS RTF DESTINATION;
   %jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

   *REPORT- PROC REPORT MODULE;
   %jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y, jm_indentopt=N, 
      jm_breakopt=, jm_breakvar=,jm_byvar=);

   *ODS CLOSE- CLOSES RTF DESTINATION;
   %jm_odsclose;
