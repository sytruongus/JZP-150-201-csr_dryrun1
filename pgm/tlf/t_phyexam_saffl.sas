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
     
       tab_box='Body System|Visit, n (%)';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   
      data ADSL;                             
      set ADSL;                             
      where TRT01AN in (1,2,3) and SAFFL='Y';                             
      trtn=TRT01AN;                             
      trt=TRT01A; 

      output;                             
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="JZP150 Total";                            
      output;                
                            
   run;                             
    
   proc sort data=ADSL;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
 
   *** Create a macro variable for storing ADQS dataset name from the list of datasets ***;                             
   data ADPE ;                             
      set adam.ADPE ;                             
      where  anl01fl="Y" and SAFFL="Y";
      
	  trtn=TRTAN;                             
      trt=TRTA; 
       output;                             
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="JZP150 Total";                            
      output;                
                                  
                              
   run;                             
    
   proc sort data=ADPE ;                             
      by studyid usubjid trtn trt;                         
                            
   run;                             
 
   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target;   
      merge ADSL(in= a) 
            ADPE (in= b);                             
      by studyid usubjid trtn trt;                             
      if a;  

length REAS $200.;

	  if index(AVALC,"-")>=1 then REAS= strip(tranwrd(AVALC,"Abnormal - ",""));
	  
	  if index(AVALC,"-")>=1 then AVALC_new=scan(AVALC,1,"-");
	  else AVALC_new=strip(AVALC);



	  if AVALC_new="Normal"       then AVALN=1;
	  else if AVALC_new="Abnormal"  then AVALN=2;

	       if strip(reas)="Not Clinically Significant"  then REASN=4;
	  else if reas="Clinically Significant"  then REASN=3;

   run;                             
    
proc freq data=target noprint;
table paramn*PARAMCD*PARAM*avisitn*avisit*AVALN*AVALC*REAS*REASN/out=frq_chk;

run;





 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);                 


*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;

   %JM_AVAL_COUNT(JM_INDSN=target, jm_var=SAFFL , JM_SECONDARY_WHERE= , jm_bign=jm_bign1, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=, jm_block=100, jm_cntvar=usubjid, JM_BYVAR=avisit avisitn  paramn paramcd param    , JM_AVAL_LABEL=%bquote(Visit) );

data jm_aval_count100;
set jm_aval_count100;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));
run;

 *** Create Treatment formats for reporting ***;

   /**Screening Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=-1 and paramn=101,JM_SUFFIX=2);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=-1 and paramn=101, jm_bign=jm_bign2, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=101, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(LIVER Screening_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=-1 and paramn=101 and reas ne ""), jm_bign=jm_bign2, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=102, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(LIVER Screening_REAS) );

   
   /**baseline Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=0 and paramn=101,JM_SUFFIX=0);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=0 and paramn=101, jm_bign=jm_bign0, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=103, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(LIVER Baseline_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=0 and paramn=101 and reas ne ""), jm_bign=jm_bign0, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=104, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(LIVER Baseline_REAS) );

   /**Week 4 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=4 and paramn=101,JM_SUFFIX=4);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=4 and paramn=101, jm_bign=jm_bign2, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=105, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(LIVER Week4_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=4 and paramn=101 and reas ne ""), jm_bign=jm_bign2, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=106, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(LIVER Week4_REAS) );


   /**Week 8 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=8 and paramn=101,JM_SUFFIX=8);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=8 and paramn=101, jm_bign=jm_bign8, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=107, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(LIVER Week8_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=8 and paramn=101 and reas ne ""), jm_bign=jm_bign8, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=108, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(LIVER Week8_REAS) );

   /**Week 8 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=12 and paramn=101,JM_SUFFIX=12);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=12 and paramn=101, jm_bign=jm_bign12, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=109, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(LIVER Week12_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=12 and paramn=101 and reas ne ""), jm_bign=jm_bign12, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=110, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(LIVER Week12_REAS) );

   




   /**Screening Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=-1 and paramn=102,JM_SUFFIX=2);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=-1 and paramn=102, jm_bign=jm_bign2, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=201, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(Testes Screening_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=-1 and paramn=102 and reas ne ""), jm_bign=jm_bign2, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=202, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(Testes Screening_REAS) );

   
   /**baseline Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=0 and paramn=102,JM_SUFFIX=0);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=0 and paramn=102, jm_bign=jm_bign0, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=203, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(Testes Baseline_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=0 and paramn=102 and reas ne ""), jm_bign=jm_bign0, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=204, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(Testes Baseline_REAS) );

   /**Week 4 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=4 and paramn=102,JM_SUFFIX=4);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=4 and paramn=102, jm_bign=jm_bign2, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=205, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(Testes Week4_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=4 and paramn=102 and reas ne ""), jm_bign=jm_bign2, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=206, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(Testes Week4_REAS) );


   /**Week 8 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=8 and paramn=102,JM_SUFFIX=8);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=8 and paramn=102, jm_bign=jm_bign8, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=207, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(Testes Week8_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=8 and paramn=102 and reas ne ""), jm_bign=jm_bign8, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=208, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(Testes Week8_REAS) );

   /**Week 8 Visit***/
       %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=avisitn=12 and paramn=102,JM_SUFFIX=12);
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= avaln, JM_SECONDARY_WHERE= avisitn=12 and paramn=102, jm_bign=jm_bign12, jm_trtvarn=trtn,JM_FMT=norm.,JM_BYVARFMT=,
                 jm_block=209, jm_cntvar=usubjid, JM_BYVAR=   , JM_AVAL_LABEL=%bquote(Testes Week12_AVALC) );

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= REASN, JM_SECONDARY_WHERE=%str(avisitn=12 and paramn=102 and reas ne ""), jm_bign=jm_bign12, jm_trtvarn=trtn,JM_BYVARFMT=,
                JM_FMT=abnorm., jm_block=210, jm_cntvar=usubjid, JM_BYVAR=    , JM_AVAL_LABEL=%bquote(Testes Week12_REAS) );

   

*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;


%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="COUNT")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=  avisit avisitn  paramn paramcd param JM_BLOCK grpvar JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);




   data dummy1;
   set JM_AVAL_TRANS2;
   where  JM_BLOCK="102" and JM_AVAL_NAMEC in ("   03:Clinically Significant","   04:Not Clinically Significant");

   do i=1 to 10;
   output;
   end;

   keep JM_BLOCK JM_AVAL_NAMEC i;

   run;

   data dummy1;
   set dummy1;


        if i=1 then JM_BLOCK="102";
   else if i=2 then JM_BLOCK="104";
   else if i=3 then JM_BLOCK="106";
   else if i=4 then JM_BLOCK="108";
   else if i=5 then JM_BLOCK="110";
   else if i=6 then JM_BLOCK="202";
   else if i=7 then JM_BLOCK="204";
   else if i=8 then JM_BLOCK="206";
   else if i=9 then JM_BLOCK="208";
   else if i=10 then JM_BLOCK="210";

run;

proc sort data=JM_AVAL_TRANS2;
by JM_BLOCK JM_AVAL_NAMEC;
run;
 
proc sort data=dummy1;
   by jm_block jm_aval_namec;
run;

data JM_AVAL_TRANS2;
   merge  JM_AVAL_TRANS2 dummy1;
   by JM_BLOCK JM_AVAL_NAMEC;



   if  jm_block="100" then do;
        if paramn=101 and avisitn=-1  then JM_BLOCK="101";
		if paramn=101 and avisitn=0   then JM_BLOCK="103";
		if paramn=101 and avisitn=4   then JM_BLOCK="105";
		if paramn=101 and avisitn=8   then JM_BLOCK="107";
        if paramn=101 and avisitn=12  then JM_BLOCK="109";

		if paramn=102 and avisitn=-1  then JM_BLOCK="201";
		if paramn=102 and avisitn=0   then JM_BLOCK="203";
		if paramn=102 and avisitn=4   then JM_BLOCK="205";
		if paramn=102 and avisitn=8   then JM_BLOCK="207";
        if paramn=102 and avisitn=12  then JM_BLOCK="209";

		JM_AVAL_NAMEC=" 0.5:"||strip(JM_AVAL_NAMEC);
   end;

        if JM_BLOCK="102"  then JM_BLOCK="101";
		if JM_BLOCK="104"  then JM_BLOCK="103";
		if JM_BLOCK="106"  then JM_BLOCK="105";
		if JM_BLOCK="108"  then JM_BLOCK="107";
		if JM_BLOCK="110"  then JM_BLOCK="109";
		if JM_BLOCK="202"  then JM_BLOCK="201";
		if JM_BLOCK="204"  then JM_BLOCK="203";
		if JM_BLOCK="206"  then JM_BLOCK="205";
		if JM_BLOCK="208"  then JM_BLOCK="207";
		if JM_BLOCK="210"  then JM_BLOCK="209";
	

		if paramn=102 and avisitn=-1  then JM_BLOCK="201";
		if paramn=102 and avisitn=0   then JM_BLOCK="203";
		if paramn=102 and avisitn=4   then JM_BLOCK="205";
		if paramn=102 and avisitn=8   then JM_BLOCK="207";
        if paramn=102 and avisitn=12  then JM_BLOCK="209";

		if JM_BLOCK in ("101","102","103","105","107","109") then JM_AVAL_LABEL="Liver";
		if JM_BLOCK in ("201","202","203","205","207","209") then JM_AVAL_LABEL="Testes";

		grpvar="Y";

	       if index(jm_aval_namec,':') gt 0 then do;
                  jm_aval_namen=input(scan(trim(left(jm_aval_namec)),1,':'),best.);
				 
                  if jm_aval_namen   in (0.5)   then jm_aval_namec='^{nbspace 2}'||strip(scan(strip(jm_aval_namec),2,':'));
				  if jm_aval_namen   in (1,2)   then jm_aval_namec='^{nbspace 4}'||strip(scan(strip(jm_aval_namec),2,':'));
				  if jm_aval_namen   in (3,4)   then jm_aval_namec='^{nbspace 6}'||strip(scan(strip(jm_aval_namec),2,':'));
               end; 


if jm_aval_namen   in (3,4) then do;

       array myarr{*} $ trtn:;
           do i=1 to dim(myarr);
                 if  myarr(i)='' then myarr(i)='0';
               end;
            
      end;
	  drop i;



run;


  data dummy;
   set JM_AVAL_TRANS2;
   where  avisitn=-1;
jm_aval_namen=0;
GROUPVARN=0;
jm_aval_namec=strip(param); 
array myarr{*} $ trtn:;
           do i=1 to dim(myarr);
                  myarr(i)='';
           end;
    output;
      
	  drop i;

   run;



   data jm_aval_trans2;
   set jm_aval_trans2 dummy;
   run;

proc sort data=JM_AVAL_TRANS2;
by JM_BLOCK JM_AVAL_NAMEN;
run;

data jm_aval_trans2;
set jm_aval_trans2;
by   jm_block jm_aval_namen;

if last.jm_block then jm_aval_namec=strip(jm_aval_namec)||"^n";
run;


  %jm_pgbrk(
      jm_indsn1=jm_aval_trans2,jm_indsn2=, jm_breakcnt=20, jm_contopt=N, jm_groupopt=N, 
      jm_outdsn=jm_aval_allreport1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   data jm_aval_allreport1;
      set jm_aval_allreport1 ;

	  jm_aval_namen=_n_;


	  if JM_BLOCK in ("101","103","105") then pageno=1;
      if JM_BLOCK in ("107","109") then pageno=2;
      	  if JM_BLOCK in ("201","203","205") then pageno=3;
      if JM_BLOCK in ("207","209") then pageno=4;

	  array myarr{*} $ trtn:;
           do i=1 to dim(myarr);
          if GROUPVAR not in ("Liver","Testes") and  myarr(i)=''  then myarr(i)='0' ;
           end;
    output;
      
	  drop i;

     
      
   run;



   *ODS OPEN- OPENS RTF DESTINATION;
   %jm_odsopen (jm_outreport=,jm_bodytitleopt=0, jm_style=oxystyle);

   *REPORT- PROC REPORT MODULE;
   %jm_aval_report (jm_indsn=jm_aval_allreport1, jm_bigndsn=jm_bign1, jm_spanheadopt=Y, jm_indentopt=N, 
      jm_breakopt=, jm_breakvar=,jm_byvar=);

   *ODS CLOSE- CLOSES RTF DESTINATION;
   %jm_odsclose;




%let dsname=T_9_03_05_01_01;
data tlfdata.&dsname;

set jm_aval_allreport1;

jm_aval_namec=tranwrd(jm_aval_namec,"^{nbspace 2}","");
jm_aval_namec=tranwrd(jm_aval_namec,"^{nbspace 4}","");
jm_aval_namec=tranwrd(jm_aval_namec,"^{nbspace 6}","");
jm_aval_namec=tranwrd(jm_aval_namec,"^n","");

jm_aval_namec=strip(jm_aval_namec);

run;
