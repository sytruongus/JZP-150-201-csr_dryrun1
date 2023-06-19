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
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("REQL111") and .<=avisitn<=12  and anl01fl="Y" and MFASFL="Y"; 
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


%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline),   JM_BLOCK=101,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 12 , JM_AVAL_LABEL=%bquote(End of Week 12),  JM_BLOCK=102,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12), JM_BLOCK=103,JM_SIGD=0 );


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC  JM_Q1C_Q3C JM_RANGEC, 
   JM_TRANS_ID=JM_TRTVARN);


   data JM_AVAL_TRANS1;
   set JM_AVAL_TRANS1;

         if _NAME_="JM_NC"  then ord=1;
   else  if _NAME_="JM_MEANSTDC"  then ord=2;
   else  if _NAME_="JM_MEDIANC"  then ord=3;
   else  if _NAME_="JM_Q1C_Q3C"  then ord=4;
   else  if _NAME_="JM_RANGEC"  then ord=5;

 run;

*-----------------------------------------------------------------------------------------------------------------------------;
   * LS Means
*-----------------------------------------------------------------------------------------------------------------------------;

 data target_1 ;
  SET target ;
  IF chg ne . and trtn in (1,2,3); 
id=subjid;
 RUN ;

/*
ODS trace on;
 proc mixed data=target_1 method=reml;
class id avisitn SSNRISN  trtn;
model chg=base trtn avisitn trtn*avisitn base*avisitn SSNRISN SSNRISN*avisitn/ ddfm=kr residual outp=residual;
repeated avisitn/type=un sub=id;
lsmeans trtn*avisitn / diff cl alpha=0.05;
ods output LSMeans=LSM_temp   diffs=ls_diffs;

run;
ODS Trace off; 
*/

/*
 proc glm data=target_1(where=(chg ne . and trtn in (1,2,3) ));
class trtn SSNRISN;
model chg=trtn SSNRISN base / SS3;
lsmeans trtn/cl stderr diff  alpha=0.05;
ods output LSMeans=LSM_temp  LSMeanCL=LSMEANCL;
run;
quit;
*/

/*
data LSM_temp1;
set LSM_temp;
   by trtn ;

   where avisitn=12;

	LS_Mean=strip(put(round(Estimate,0.1),9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(Lower,9.1))||', '||compress(put(upper,9.1))||')';
run;

proc transpose data=lsm_temp1 out=LSM_stat;
id trtn;
var ls_mean se LS_MEANCL;
run;


data LSM_STAT ;
length JM_AVAL_LABEL _name_ _LABEL_  JM_AVAL_NAMEC $200. ;
 SET LSM_STAT ;
 JM_BLOCK = '104' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean' ; _LABEL_ = 'LS Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=7;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE_Mean' ; _name_ = 'SE_Mean';_LABEL_ = 'SE_Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=8;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;ord=9;
 end;
 drop _1 _2 _3 ;
 RUN;
*/

************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;
** normality test: if p-value <0.05 at Shapiro-Wilk test, not normal distribution then use shift location/H-L estimate **;
** else use ranked ANCOVA **;


ods select none;
proc mixed data=target_1 method=reml;
class id avisitn SSNRISN  trtn;
model chg=base trtn avisitn trtn*avisitn base*avisitn SSNRISN SSNRISN*avisitn/ ddfm=kr residual outp=rsd_data;
repeated avisitn/type=un sub=id;
lsmeans trtn*avisitn / diff cl alpha=0.05;
run;

proc univariate data=rsd_data normal;
  var resid;
  ods output TestsForNormality=d_normtst(where=(Test="Shapiro-Wilk"));
run;
ods select all;

** setup macro to run LSMean based on p-value from normality test **;
%macro LSM;
	proc sql noprint;
		select pvalue into :pval
		from d_normtst
		;
	quit;
	%put &pval.;
	
	/*%if &pval.<0.05 %then %do;*/

	** shift location, H-L Estimate **;
		data dbrw_data;
		set target_1 ;
			if chg ne . and trtn in (1,2,3) ;
		run;

		ods select none;

		proc rank data=dbrw_data out=ranked ties=mean;
  		var  base chg;
  		ranks rbase rchg;
		run;


		*p-value for estimated median;

PROC MIXED DATA=RANKED METHOD=TYPE3;
where trtn in (1,3);

     CLASS trtn SSNRISN;
     MODEL RCHG = trtn RBASE SSNRISN;
	 ods output tests3=ls_diffs_hl_1;
RUN;

PROC MIXED DATA=RANKED METHOD=TYPE3;
where trtn in (2,3);

     CLASS trtn SSNRISN;
     MODEL RCHG = trtn RBASE SSNRISN;
	 ods output tests3=ls_diffs_hl_2;
RUN;

data Manova;
set ls_diffs_hl_1(in=a where=(effect="trtn")) ls_diffs_hl_2(in=b where=(effect="trtn"));
  if a then trtn=1;
  else if b then trtn=2;

	
	P_VALUE=tranwrd(compress(put(ProbF,pvalue6.4)),'<.','<0.');
run;


*ci for estimated median;

		* H-L estimate and 95% CI; 

     proc npar1way data=dbrw_data hl(refclass="Placebo");
	 where trtn in (1,3);
          class /*trtn*/ trt01p;
            var chg;
          ods output hodgeslehmann=HLdata1;
        run;	


		proc npar1way data=dbrw_data hl(refclass="Placebo");
	 where trtn in (2,3);
          class /*trtn*/ trt01p;
            var chg;
          ods output hodgeslehmann=HLdata2;
        run;	
   


		data HLestimate;
  		set HLdata1(in=a) HLDATA2(in=b);

		if a then trtn=1;
		else if b then trtn=2;

  		drop variable type;
  		format shift midpoint 9.2 stderr lowerCL upperCL 9.2 ;
		run;


		data LSM_data;
		merge HLestimate(in=a)
		      MANOVA(in=b keep=trtn Probf);
		by trtn;
		keep trtn shift lowerCL upperCL Probf;
		format shift 9.2;

	   run;

	   		** LSM dataset **;
		data LSM_data;
		set LSM_data;
			*aperiod=99;
			LSM_lbl1=compress(put(shift,9.1)); 
			CI_95p=compress('('||put(lowercl,9.1))||', '||compress(put(uppercl,9.1))||')';
			p_value=tranwrd(compress(put(Probf,pvalue6.4)),'<.','<0.'); 
			lsm_lbl2=' ';  ** reserve as blank to keep dataset consistent for H-L est and ANCOVA **;
		run;


		ods select all;
		
proc transpose data=LSM_data out=lsmdata_stat_HL;
id trtn;
var LSM_lbl1 CI_95p  p_value;
run;


data lsmdata_stat_HL;
length JM_AVAL_LABEL _name_ _LABEL_ JM_AVAL_NAMEC $200. ;
 SET lsmdata_stat_HL ;
 JM_BLOCK = '105' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LSM_lbl1' then do ;
 JM_AVAL_NAMEC = 'LS Mean Diff' ; _name_='Shift';_LABEL_ = 'LS Mean Diff' ; trtn1 = _1 ; trtn2 = _2 ;ord=10;
 end;

  if _name_ = 'CI_95p' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_='95% CI';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;ord=12;
 end;

  if _name_ = 'p_value' then do ;
 JM_AVAL_NAMEC = 'p-value' ; _name_ = 'P_VALUE';_LABEL_ = 'P-VALUE' ; trtn1 = _1 ; trtn2 = _2 ;ord=13;
 end;
 drop _1 _2 ;
 RUN;

		data lsmd_out_HL;
		set lsmdata_stat_HL;
	 run;

/*%end;*/

	/*%else %if &pval.>=0.05 %then %do;*/	** ANCOVA **;
		ods select none;

	** LS MEAN DIFF, SE, 95% CI, p-value between trt **;



PROC MIXED DATA =target_1 METHOD =TYPE3;
  CLASS SSNRISN  trtn;
MODEL CHG = base trtn SSNRISN/ RESIDUAL OUTP=rsd_data;
LSMEANS trtn/DIFF CL;
ods output LSMeans=LSM_temp   diffs=lsmdiffs;
RUN;

ods select all;

data lsmdiffs1;
set lsmdiffs;
   by trtn ;
   where trtn in (1,2) and _trtn=3;
	LS_Mean=strip(put(round(Estimate,0.1),9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(Lower,9.1))||', '||compress(put(upper,9.1))||')';
	P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');
run;

proc transpose data=lsmdiffs1 out=lsmdiffs_stat;
id trtn;
var ls_mean se LS_MEANCL  p_value;
run;


data lsmdiffs_stat;
length JM_AVAL_LABEL _name_ _LABEL_ JM_AVAL_NAMEC $200. ;
 SET lsmdiffs_stat ;
 JM_BLOCK = '105' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean Diff' ; _LABEL_ = 'LS Mean Diff' ; trtn1 = _1 ; trtn2 = _2 ;ord=10;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE' ; _name_ = 'SE_Mean_diff';_LABEL_ = 'SE' ; trtn1 = _1 ; trtn2 = _2 ;ord=11;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;ord=12;
 end;

  if _name_ = 'P_VALUE' then do ;
 JM_AVAL_NAMEC = 'p-value' ; _name_ = 'P_VALUE';_LABEL_ = 'P-VALUE' ; trtn1 = _1 ; trtn2 = _2 ;ord=13;
 end;
 drop _1 _2 ;
 RUN;



		data lsmdiffs_out;
		set lsmdiffs_stat;
	 run;

		
	/*%end;*/
%mend;
%lsm;


data LSMD_OUT_HL ;
length JM_AVAL_LABEL $200. ;
 SET LSMD_OUT_HL ;
 if _name_ ^= ' ' then do ; 
  JM_BLOCK = '106' ;
  JM_AVAL_LABEL = 'Change' ;
  *JM_AVAL_NAMEC = _name_ ;
  *_LABEL_ = _name_ ;
 end;

 if _name_ = 'Shift' then do ;
  JM_AVAL_NAMEC = 'EMD' ; 
 _LABEL_ = 'Estimated Median difference' ;
 _NAME_ = 'EMD' ;
 end;
 

 keep jm_block JM_AVAL_LABEL JM_AVAL_NAMEC _NAME_ _LABEL_ trtn1 trtn2 ord;
 RUN;

 Data final ;
 length jm_aval_label _name_ _label_ $200 ;
  set JM_AVAL_TRANS1  lsmdiffs_out LSMD_OUT_HL ;
  if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    jm_block="103";
  end;

  if JM_block in ("105","106") then JM_BLOCK="103";
 RUN ;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 8, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEANCL" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_aval_namec="p-value" then jm_aval_namec="p-value^n";

    if jm_aval_namec="Min, Max" then jm_aval_namec="Min, Max^n";

	if jm_aval_namec="LS Mean Diff" and ord=10 then jm_aval_namec="LS Mean Diff to Placebo";

 
   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;


	   if jm_block in ("101") then pageno=1;
		 if jm_block in ("102") then pageno=2;
       if jm_block in ("103") and groupvarn<=19 then pageno=3;
	   else if jm_block in ("103") and groupvarn>19 then pageno=4;
        

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


