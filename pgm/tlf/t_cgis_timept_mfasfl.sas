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
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("CGI0201")  and avisitn in (0,1,4,8,12,92) and anl01fl="Y" and MFASFL="Y";
      
                                
                              
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

 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= MFASFL, JM_SECONDARY_WHERE= avalc ne "" , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=101, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Number of Participants with at Least One Survey) );



data Jm_aval_count101;
set Jm_aval_count101;

  Jm_aval_countc=strip(put(Jm_aval_count,best.));
run;




 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=0,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=0, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=102, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Baseline) );

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=1,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=1, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=103, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Week 1) );

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=4,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=4, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=104, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Week 4) );

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=8,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=8, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=105, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Week 8) );


 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=12,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=12, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=106, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Week 12) );


 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE= avisitn=92,JM_SUFFIX=1);                 
 %JM_AVAL_COUNT(JM_INDSN=target, jm_var= aval, JM_SECONDARY_WHERE= avalc ne "" and avisitn=92, jm_bign=jm_bign1, jm_trtvarn=trtn,JM_FMT=cgis.,
jm_block=107, jm_cntvar=usubjid, JM_BYVAR=  avisitn avisit paramcd param , JM_AVAL_LABEL=%bquote(Safety Follow-Up) );



*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;


%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="COUNT")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS2, JM_TRANS_BY=  avisitn avisit paramcd param  JM_BLOCK grpvar JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=COLVAL , JM_TRANS_ID=JM_TRTVARN);

proc sort data=JM_AVAL_TRANS2;
by avisitn avisit;
run;

 Data final ;
 length jm_aval_label _name_  $200 ;
  set JM_AVAL_TRANS2;* LSM_STAT LSMD_OUT ;

  if grpvar="Y" then grpvar="00:Number of Participants with at Least One Survey";
    jm_aval_namen=input(scan(grpvar,1,':'),best.); 
     jm_aval_namec=scan(grpvar,2,':'); 
     jm_aval_label=strip(jm_aval_namec);

 RUN ;


 proc sort data=final out= dummy ;
 by avisitn avisit;
 run;

data dummy;
set dummy;
 by avisitn avisit;

 if first.avisitn;

 jm_aval_namec=avisit;
 jm_aval_label=strip(jm_aval_namec);
 grpvar="00:"||strip(avisit);
 jm_aval_namen=-1;
 drop TRTn:;
 run;

data final;
set final dummy;


ordn=jm_aval_namen;
run;
proc sort data=final;
by avisitn avisit jm_aval_namen ;
run;


data final;
set final;
by avisitn avisit jm_aval_namen ;
retain block 0;
if first.avisitn then block=block+1;

    JM_BLOCK=strip(put(block,best.));

retain ord1 0;
if first.avisitn then ord1=1;
else ord1=ord1+1;

ordc=put(ord1,z2.);
 grpvar=ordc||":"||strip(jm_aval_label);

jm_aval_namen=ord1;

run;



*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 14, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;


     if avisit in ("Baseline","Week 1") then pageno=1;
     if avisit in ("Week 4","Week 8") then pageno=2;
     if avisit in ("Week 12","Safety Follow-Up") then pageno=3;
        
     if  jm_aval_namen not in (1) then  jm_aval_namec='   '||strip(jm_aval_namec);


     groupvarn=orig_rec_num;
     jm_aval_namen=orig_rec_num;


    /* if ordn=0 then do;
        jm_aval_label = strip(avisit)|| '^n'||strip(jm_aval_label);
    end;*/

jm_aval_namec = grpvar;
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1); 

%LET _default_box=Timepoint;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;
proc sort data=jm_Aval_Allreport1;
  by jm_block jm_aval_namen jm_aval_label;
run;
data jm_aval_Allreport1;
  set jm_aval_allreport1(drop=jm_aval_label);
  by jm_block jm_aval_namen;
  jm_aval_namec=strip(scan(jm_aval_namec,2,':'));
  if first.jm_block ne 1 then jm_Aval_namec='^{nbspace 2}'||strip(jm_Aval_namec);
  if last.jm_block then jm_aval_namec=strip(jm_aval_namec)||'^n';


  if JM_block in ("6") then do;
   if last.jm_block then jm_aval_namec=tranwrd(jm_aval_namec,"^n","");
   end;

  length  jm_aval_label $200;
  if first.jm_block then jm_aval_label=jm_aval_namec;retain jm_aval_label;
run;

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
