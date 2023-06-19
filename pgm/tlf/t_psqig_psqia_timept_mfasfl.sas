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
      set adam.ADQS2 ;                             
      where paramcd in ("PSQPWSCR","PSQIASUM","PSQDBSCR","PSQDRSCR","PSQDYSCR","PSQLTSCR","PSQMDSCR","PSQOVSCR","PSQSESCR") 
            and avisitn in (0,1,4,8,12,92) and anl01fl="Y" and MFASFL="Y"; 

if paramcd="PSQPWSCR" then  PARAMN=1;
if paramcd="PSQDRSCR" then  PARAMN=2;
if paramcd="PSQDBSCR" then  PARAMN=3;
if paramcd="PSQLTSCR" then  PARAMN=4;
if paramcd="PSQDYSCR" then  PARAMN=5;
if paramcd="PSQSESCR" then  PARAMN=6;
if paramcd="PSQOVSCR" then  PARAMN=7;
if paramcd="PSQMDSCR" then  PARAMN=8;
if paramcd="PSQIASUM" then  PARAMN=9;
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


%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline),
 JM_BYVAR=  avisitn avisit PARAMN paramcd param , JM_BLOCK=101,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(End of Week 1),
 JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=102,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 1),
 JM_BYVAR=  avisitn avisit PARAMN paramcd param , JM_BLOCK=103,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(End of Week 4),
JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=104,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 4),
JM_BYVAR=  PARAMN paramcd param avisitn avisit, JM_BLOCK=105,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(End of Week 8),
JM_BYVAR=   PARAMN paramcd param avisitn avisit,  JM_BLOCK=106,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 8),
JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=107,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =12, JM_AVAL_LABEL=%bquote(End of Week 12),
JM_BYVAR=   PARAMN paramcd param avisitn avisit,  JM_BLOCK=108,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12, JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12),
JM_BYVAR=   PARAMN paramcd param avisitn avisit, JM_BLOCK=109,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Safety Follow-up),
JM_BYVAR=  PARAMN paramcd param avisitn avisit,  JM_BLOCK=110,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Change from Baseline to Safety Follow-up),
JM_BYVAR=  PARAMN paramcd param avisitn avisit, JM_BLOCK=111,JM_SIGD=0 );

*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=PARAMN paramcd param avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC JM_RANGEC /*JM_Q1C_Q3C*/, 
   JM_TRANS_ID=JM_TRTVARN);


   proc freq data=JM_AVAL_TRANS1 noprint;
    table PARAMN*param*paramcd/out=freq nocol nopct;
   run;


 Data final ;
 length jm_aval_label _name_ _label_ $200 ;
  set JM_AVAL_TRANS1;* LSM_STAT LSMD_OUT ;

  if paramcd in ("PSQPWSCR") then do;
     paramn=1;
	 PARAM="PSQI Global Score";
 end;
/*  "PSQDBSCR","PSQDRSCR","PSQDYSCR","PSQLTSCR","PSQMDSCR","PSQOVSCR","PSQSESCR"*/
 else if paramcd in ("PSQDRSCR") then do;
           paramn=2;
		   PARAM="Duration of sleep";
 end;
 else if paramcd in ("PSQDBSCR") then do;
           paramn=3;
		   PARAM="Sleep disturbance";
 end;
 else if paramcd in ("PSQLTSCR") then do;
           paramn=4;
  	       PARAM="Sleep latency";
 end;
 else if paramcd in ("PSQDYSCR") then do;
           paramn=5;
  	       PARAM="Day dysfunction due to sleepiness";
 end; 
 else if paramcd in ("PSQSESCR") then do;
           paramn=6;
  	       PARAM="Sleep efficiency";
 end; 
 else if paramcd in ("PSQOVSCR") then do;
           paramn=7;
  	       PARAM="Overall sleep quality";
 end;
  else if paramcd in ("PSQMDSCR") then do;
           paramn=8;
  	       PARAM="Need meds to sleep";
 end;

 else if paramcd in ("PSQIASUM") then do;
         paramn=9;
	     PARAM="PSQI-A Total Score ";
 end;

 RUN ;
proc sort data=final;
by paramn avisitn avisit JM_BLOCK ;
run;



*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 8, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);


proc sort data=jm_aval_allreport1;
by paramn avisitn avisit JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEN JM_AVAL_NAMEC;
run;

data jm_aval_allreport1;
 set jm_aval_allreport1;

 orig_rec_num=_n_;


   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEAN" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_block in ("101","102","103") then pageno=1;
   if jm_block in ("104","105") then pageno=2;
   if jm_block in ("106","107") then pageno=3;
   if jm_block in ("108","109") then pageno=4;
   if jm_block in ("110","111") then pageno=5;

   if paramn=1 then pageno=100+pageno;
   if paramn=2 then pageno=200+pageno;
   if paramn=3 then pageno=300+pageno;
   if paramn=4 then pageno=400+pageno;
   if paramn=5 then pageno=500+pageno;
   if paramn=6 then pageno=600+pageno;
   if paramn=7 then pageno=700+pageno;
   if paramn=8 then pageno=800+pageno;
   if paramn=9 then pageno=900+pageno;
   
   
   if jm_aval_label="Baseline" then jm_aval_label=strip(PARAM)||"^n"||strip(jm_aval_label);

  if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);
run;
proc sort data=jm_aval_allreport1;
by pageno paramn avisitn JM_BLOCK jm_aval_namen;
run;

data jm_aval_allreport1;
set jm_aval_allreport1;
by pageno paramn avisitn JM_BLOCK jm_aval_namen;

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;

	  
	  array myarr{*} $ trtn:;
           do i=1 to dim(myarr);
          if paramn  in (106,201) and  myarr(i)=''  then myarr(i)='0' ;
           end;


run;


 proc freq data=jm_aval_allreport1 noprint;
    table PARAMN*param*paramcd/out=freq nocol nopct;
   run;


%LET _default_box=Timepoint;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport1, JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=jm_aval_label);

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




%let dsname=T_9_02_09_02_03;
data tlfdata.&dsname;
set jm_aval_allreport1;

keep JM_: TRTN: PARAM:;
run;
