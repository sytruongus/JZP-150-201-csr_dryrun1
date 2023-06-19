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
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("ISI0108") and avisitn in (0,1,4,8,12,92) and anl01fl="Y" and MFASFL="Y"; 
      
                                
                              
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

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(End of Week 1),  JM_BLOCK=102,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =1 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 1), JM_BLOCK=103,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(End of Week 4),  JM_BLOCK=104,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =4 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 4), JM_BLOCK=105,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(End of Week 8),  JM_BLOCK=106,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN =8 , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 8), JM_BLOCK=107,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN =12, JM_AVAL_LABEL=%bquote(End of Week 12),  JM_BLOCK=108,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12, JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12), JM_BLOCK=109,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Safety Follow-up),  JM_BLOCK=110,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 92, JM_AVAL_LABEL=%bquote(Change from Baseline to Safety Follow-up), JM_BLOCK=111,JM_SIGD=0 );

*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_NC JM_MEANSTDC JM_MEDIANC JM_RANGEC /*JM_Q1C_Q3C*/, 
   JM_TRANS_ID=JM_TRTVARN);

*-----------------------------------------------------------------------------------------------------------------------------;
   * LS Means
*-----------------------------------------------------------------------------------------------------------------------------;

 data target_1 ;
  SET target ;
  IF chg ne . and trtn in (1,2,3);
 RUN ;
   
ODS trace on;
 proc glm data=target_1(where=(chg ne . and trtn in (1,2,3) ));
class trtn SSNRISN;
model chg=trtn SSNRISN base / SS3;
lsmeans trtn/cl stderr diff  alpha=0.05;
ods output LSMeans=LSM_temp  LSMeanCL=LSMEANCL;
run;
quit;
ODS Trace off;


data LSM_temp1;
merge  LSM_temp
   LSMEANCL(keep=trtn lowercl uppercl);
   by trtn ;
	LS_Mean=strip(put(round(lsmean,0.1),9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(lowercl,9.2))||', '||compress(put(uppercl,9.2))||')';
run;

proc transpose data=lsm_temp1 out=LSM_stat;
id trtn;
var ls_mean se LS_MEANCL;
run;


data LSM_STAT ;
length JM_AVAL_LABEL _name_ _LABEL_ $200. ;
 SET LSM_STAT ;
 JM_BLOCK = '104' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LS_Mean' then do ;
 JM_AVAL_NAMEC = 'LS Mean' ; _LABEL_ = 'LS Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;
 end;
 if _name_ = 'SE' then do ;
 JM_AVAL_NAMEC = 'SE_Mean' ; _name_ = 'SE_Mean';_LABEL_ = 'SE_Mean' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;
 end;

  if _name_ = 'LS_MEANCL' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_ = 'LS_MEANCL';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;trtn3 = _3 ;
 end;
 drop _1 _2 _3 ;
 RUN;


************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;
** normality test: if p-value <0.05 at Shapiro-Wilk test, not normal distribution then use shift location/H-L estimate **;
** else use ranked ANCOVA **;

ods select none;

PROC glm DATA=target(where=(chg ne . and trtn in (1,2,3) ));
  CLASS trtn  SSNRISN;
  MODEL chg = trtn SSNRISN base;
  output out=rsd_data p=p r=resid ;  
RUN;

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
	
	%if &pval.<0.05 %then %do;

	** shift location, H-L Estimate **;
		data dbrw_data;
		set target ;
			if chg ne . and trtn in (1,2,3) ;
		run;
	
		ods select none;
		proc rank data=dbrw_data out=ranked ties=mean;
  		var  base chg;
  		ranks rbase rchg;
		run;

		PROC GLM DATA=RANKED ;
  		CLASS trtn SSNRISN;
  		MODEL rchg = trtn  rbase / SS3 ;
  			lsmeans trtn/cl diff;
  		ods output ModelANOVA=MANOVA (where=(source="trtn")) ;
		RUN;
		quit;

		* H-L estimate and 95% CI;

        proc npar1way data=dbrw_data hl(refclass="Dummy Treatment C");
          class /*trtn*/ trt01p;
            var chg;
          ods output hodgeslehmann=HLdata;
        run;	


		data HLestimate;
  		set HLdata;
  		drop variable type;
  		format shift midpoint 9.2 stderr lowerCL upperCL 9.2 ;
		run;

		proc sql;
		create table LSM_data as
		select a.shift format 9.2, a.lowerCL, a.upperCL, b.probf
		from HLdata as a, Manova as b;
		quit;

		ods select all;
		/*title3 "shift, 95% CI, p-value";
		proc print; run;*/

		** LSM dataset **;
		data lsmd1(keep=LSM_lbl1) lsmd2(keep=ci_95p) lsmd3(keep=p_value) lsmd4(keep=lsm_lbl2);
		set LSM_data;
			*aperiod=99;
			LSM_lbl1=compress(put(shift,9.2)); output lsmd1;
			CI_95p=compress('('||put(lowercl,9.2))||', '||compress(put(uppercl,9.2))||')'; output lsmd2;
			p_value=tranwrd(compress(put(probf,pvalue6.4)),'<.','<0.'); output lsmd3;
			lsm_lbl2=' '; output lsmd4;  ** reserve as blank to keep dataset consistent for H-L est and ANCOVA **;
		run;

		data lsmd_out;
		set lsmd1 lsmd4 lsmd2 lsmd3;
			length JZP150 $20. _name_ $20 ;
			*aperiod=99;
			if lsm_lbl1 ne ' ' then do; _name_='Shift'; ord=1; JZP150=lsm_lbl1; end;
			if lsm_lbl2 ne ' ' then do; _name_='SE_Dif'; ord=2; JZP150=lsm_lbl2; end;
			if CI_95p ne ' ' then do; _name_='95% CI'; ord=3; JZP150=CI_95p; end;
			if p_value ne ' ' then do; _name_='p-value'; ord=4; JZP150=p_value; end;
			*keep /*aperiod*/ _name_ JZP150 ord;
		run;

	%end;

	%else %if &pval.>=0.05 %then %do;	** ANCOVA **;
		ods select none;

	** LS MEAN DIFF, SE, 95% CI, p-value between trt **;


		PROC GLM DATA = target(where=(chg ne . and trtn in (1,2,3) ));
  		CLASS trtn SSNRISN ;
  		MODEL chg = trtn SSNRISN base / SS3 ;
  		lsmeans trtn/diff stderr cl ;
  		estimate 'JZP 150 A vs Placebo' trtn 1 0 -1;
		estimate 'JZP 150 B vs Placebo' trtn 0 1 -1;
  		ods output ModelANOVA=Model_ANOVA LSMeans=LSMdiff/*(keep=probtdiff)*/ LSMeanDiffCL=LSMdiff_CL/*(keep=difference lowercl uppercl)*/ 
			estimates=LSMse;
		RUN;
		quit;

		data LSMse;
		set LSMse;
		if parameter="JZP 150 A vs Placebo" then trtn=1;
		else trtn=2;
		run;


		data LSMdiff;
		set LSMdiff(rename=(trtn=trtc));

		trtn=input(trtc,best.);
		run;


		data LSMDIFF_CL;
		set LSMDIFF_CL;
		if (trtn=1 and _trtn=3) or (trtn=2 and _trtn=3);
		run;
		 
		data LSMdiff_stat;
		merge LSMdiff(in=a keep= trtn  probt)
		      LSMDIFF_CL(in=b keep=trtn difference lowercl uppercl)
              LSMse(in=c keep=trtn StdErr);
		by trtn;

       LS_Mean_Diff=difference;
	   SE=StdErr;
       LCL=lowercl;
	   UCL=uppercl;
	   p_value=probt;


	   if trtn in (1,2);

	   format LS_Mean_Diff  9.2  SE 9.3 LCL 9.2 UCL 9.2 p_value  7.4;
	   keep trtn LS_Mean_Diff SE LCL UCL p_value;
  run;

		
		ods select all;
		/*title3 "LS MEAN DIFF, SE, 95% CI, P-value";
		proc print data=lsmdiff_stat; run;*/

		data lsmd1(keep= trtn lsm_lbl1) lsmd2(keep= trtn ci_95p) lsmd3(keep= trtn p_value) lsmd4(keep= trtn lsm_lbl2);
		set lsmdiff_stat(rename=(ls_mean_diff=lsmdiff_o p_value=pval se=o_se));
			*aperiod=99;
			lsm_lbl1=compress(put(lsmdiff_o,9.2)); output lsmd1;
			CI_95p=compress('('||put(lcl,9.2))||', '||compress(put(ucl,9.2))||')'; output lsmd2;
			p_value=tranwrd(compress(put(pval,pvalue6.4)),'<.','<0.'); output lsmd3;
			lsm_lbl2=compress(put(o_se,9.3)); output lsmd4;
		run;

		data lsmd_out;
		set lsmd1 lsmd4 lsmd2 lsmd3;
			length JZP150 $20.  _name_ $20 ;
			*aperiod=99;
			if lsm_lbl1 ne ' ' then do; _name_='LS Mean Diff'; ord=1; JZP150=lsm_lbl1; end;
			if lsm_lbl2 ne ' ' then do; _name_='SE_Dif'; ord=2; JZP150=lsm_lbl2; end;
			if CI_95p ne ' ' then do; _name_='95% CI'; ord=3; JZP150=CI_95p; end;
			if p_value ne ' ' then do; _name_='p-value'; ord=4; JZP150=p_value; end;

			rename _name_=name;
			*keep avisit _name_ JZP150 ord;
		run;

		proc transpose data=lsmd_out out=tr_lsmd_out prefix=trtn;
		by ord name;
		var JZP150;
		id trtn;
		run;

data LSMD_OUT ;
 set tr_lsmd_out(keep=ord name trtn1 trtn2);
 _name_=name;
 run;

		
	%end;
%mend;
%lsm;


data LSMD_OUT ;
length JM_AVAL_LABEL $200. ;
 SET LSMD_OUT ;
 if _name_ ^= ' ' then do ; 
  JM_BLOCK = '105' ;
  JM_AVAL_LABEL = 'Change' ;
  JM_AVAL_NAMEC = _name_ ;
  _LABEL_ = _name_ ;
 end;

 if _name_ = 'Shift' then do ;
  JM_AVAL_NAMEC = 'EMD' ; 
 _LABEL_ = 'Estimated Median difference' ;
 _NAME_ = 'EMD' ;
 end;
 

 keep jm_block JM_AVAL_LABEL JM_AVAL_NAMEC _NAME_ _LABEL_ trtn1 trtn2 ;
 RUN;

 Data final ;
 length jm_aval_label _name_ _label_ $200 ;
  set JM_AVAL_TRANS1;* LSM_STAT LSMD_OUT ;
  if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week 12" ;
    jm_block="103";
  end;
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
  if jm_aval_namec="LS_MEAN" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_block in ("101","102","103") then pageno=1;
   if jm_block in ("104","105") then pageno=2;
   if jm_block in ("106","107") then pageno=3;
   if jm_block in ("108","109") then pageno=4;
   if jm_block in ("110","111") then pageno=5;


   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;

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



