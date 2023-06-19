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
      where /*TRT01AN in (1,2,3) and  MFASFL='Y' and */ paramcd in ("CGI0201") and .<=avisitn<=8  and anl01fl="Y" and MFASFL="Y"; 
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

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN=0 and ABLFL="Y", JM_AVAL_LABEL=%bquote(Baseline), JM_BYVAR= AVISITN,   JM_BLOCK=101,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 1 , JM_AVAL_LABEL=%bquote(End of Week 1), JM_BYVAR= AVISITN, JM_BLOCK=102,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 1   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 1),JM_BYVAR= AVISITN,  JM_BLOCK=103,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 4 , JM_AVAL_LABEL=%bquote(End of Week 4), JM_BYVAR= AVISITN, JM_BLOCK=104,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 4   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 4),JM_BYVAR= AVISITN,  JM_BLOCK=105,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 8 , JM_AVAL_LABEL=%bquote(End of Week 8),JM_BYVAR= AVISITN,  JM_BLOCK=106,JM_SIGD=0 );

%JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 8   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 8),JM_BYVAR= AVISITN, JM_BLOCK=107,JM_SIGD=0 );

%*JM_AVAL_SUM(JM_INDSN=target, jm_var=aval, jm_bign=, jm_trtvarn=trtn, JM_SECONDARY_WHERE= AVISITN = 12 , JM_AVAL_LABEL=%bquote(End of Week 12),JM_BYVAR= AVISITN,  JM_BLOCK=108,JM_SIGD=0 );

%*JM_AVAL_SUM(JM_INDSN=target, jm_var=chg, jm_bign=, jm_trtvarn=trtn,  JM_SECONDARY_WHERE= AVISITN = 12   , JM_AVAL_LABEL=%bquote(Change from Baseline to End of Week 12),JM_BYVAR= AVISITN, JM_BLOCK=109,JM_SIGD=0 );


*----------------------------------------------------------------------------------------------------------------------------------;

*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1(where=(JM_TYPE="SUMMARY")), 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=AVISITN JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC, 
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



************************************************************;
* LS Mean DIFF, SE, 95% CI & p-value between JZP & placebo *;
************************************************************;
** normality test: if p-value <0.05 at Shapiro-Wilk test, not normal distribution then use shift location/H-L estimate **;
** else use ranked ANCOVA **;

ods select none;

PROC MIXED DATA =target_1 METHOD =TYPE3;
CLASS SSNRISN  trtn;
MODEL CHG = base trtn  SSNRISN/ RESIDUAL OUTP=rsd_data;
LSMEANS trtn/DIFF CL;
RUN;

proc univariate data=rsd_data normal;
  var resid;
  ods output TestsForNormality=d_normtst(where=(Test="Shapiro-Wilk"));
run;
ods select all;

** setup macro to run LSMean based on p-value from normality test **;

** setup macro to run LSMean based on p-value from normality test **;
%macro LSM(whr=, ds=);
	proc sql noprint;
		select pvalue into :pval
		from d_normtst
		;
	quit;
	%put &pval.;
	
	/*%if &pval.<0.05 %then %do;*/

	** shift location, H-L Estimate **;
	
		data dbrw_data_&ds;
		set target_1 ;
			if chg ne . and trtn in (1,2,3)  and &whr;
		run;
	
		ods select none;
		proc rank data=dbrw_data_&ds out=ranked_&ds ties=mean;
  		var  base chg;
  		ranks rbase rchg;
		run;

		*p-value for estimated median;
		 proc mixed data=ranked_&ds method=reml;
		 where &whr;
            class id avisitn SSNRISN  trtn;
            model rchg=rbase trtn avisitn trtn*avisitn rbase*avisitn SSNRISN SSNRISN*avisitn;
            repeated avisitn/type=un sub=id;
            lsmeans trtn*avisitn / diff cl alpha=0.05;
            ods output LSMeans=LSM_temp_hl_&ds.  diffs=ls_diffs_hl_&ds. ;
         run;

proc sort data=ls_diffs_hl_&ds.;
by avisitn trtn;
run;

data Manova_&ds.;
set ls_diffs_hl_&ds.;
   by avisitn trtn ;
   where  trtn in (1,2) and _trtn=3;
		P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');

	      %if &ds=1 %then %do;
	        if  avisitn in (1)  and  _avisitn in (1) then output;
	      %end;
	%else %if &ds=4 %then %do;
	if  avisitn in (4)  and  _avisitn in (4) then output;
	%end;
    %else %if &ds=8 %then %do;
	if  avisitn in (8)  and  _avisitn in (8) then output;
	%end;
	%else %if &ds=12 %then %do;
	if  avisitn in (12)  and  _avisitn in (12) then output;
	%end;
run;

proc sort data=dbrw_data_&ds.;
by avisitn;
run;

*ci for estimated median;

		* H-L estimate and 95% CI; 

     proc npar1way data=dbrw_data_&ds. hl(refclass="Placebo");
	 where trtn in (1,3);
          class /*trtn*/ trt01p;
            var chg;
          ods output hodgeslehmann=HLdata1_&ds.;
		  by avisitn;
        run;	

proc npar1way data=dbrw_data_&ds. hl(refclass="Placebo");
	 where trtn in (2,3);
          class /*trtn*/ trt01p;
            var chg;
          ods output hodgeslehmann=HLdata2_&ds.;
		  by avisitn;
        run;	
   
		data HLestimate_&ds.;
  		set HLdata1_&ds.(in=a) HLDATA2_&ds.(in=b);
		by avisitn;

		if a then trtn=1;
		else if b then trtn=2;

  		drop variable type;
  		format shift midpoint 9.2 stderr lowerCL upperCL 9.2 ;
		run;


		data LSM_data_&ds.;
		merge HLestimate_&ds.(in=a)
		      MANOVA_&ds.(in=b keep=avisitn trtn Probt);
		by avisitn trtn;
		keep avisitn trtn shift lowerCL upperCL Probt;
		format shift 9.2;
	   run;

		ods select all;
		/*title3 "shift, 95% CI, p-value";
		proc print; run;*/

		** LSM dataset **;
		data LSM_data_&ds.;
		set LSM_data_&ds.;
			*aperiod=99;
			LSM_lbl1=compress(put(shift,9.1)); 
			CI_95p=compress('('||put(lowercl,9.1))||', '||compress(put(uppercl,9.1))||')';
			p_value=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.'); 
			lsm_lbl2=' ';  ** reserve as blank to keep dataset consistent for H-L est and ANCOVA **;
		run;


		
proc transpose data=LSM_data_&ds. out=lsmdata_stat_HL_&ds.;
id trtn;
var LSM_lbl1 CI_95p  p_value;
by avisitn ;

run;


data lsmdata_stat_HL_&ds.;
length JM_AVAL_LABEL _name_ _LABEL_ JM_AVAL_NAMEC $200. ;
 SET lsmdata_stat_HL_&ds. ;
 JM_BLOCK = '105' ; JM_AVAL_LABEL = 'Change' ; 
 if _name_ = 'LSM_lbl1' then do ;
 JM_AVAL_NAMEC = 'LS Mean Diff' ; _name_='Shift';_LABEL_ = 'LS Mean Diff' ; trtn1 = _1 ; trtn2 = _2 ;ord=14;
 end;

  if _name_ = 'CI_95p' then do ;
 JM_AVAL_NAMEC = 'LS_MEANCL' ; _name_='95% CI';_LABEL_ = '95% CI' ; trtn1 = _1 ; trtn2 = _2 ;ord=15;
 end;

  if _name_ = 'p_value' then do ;
 JM_AVAL_NAMEC = 'p-value' ; _name_ = 'P_VALUE';_LABEL_ = 'P-VALUE' ; trtn1 = _1 ; trtn2 = _2 ;ord=16;
 end;
 drop _1 _2 ;
 RUN;

		data lsmd_out_HL_&ds.;
		set lsmdata_stat_HL_&ds.;

		 %if &ds=1 %then %do;
	        if  avisitn in (1)   then output;
	      %end;
	%else %if &ds=4 %then %do;
	if  avisitn in (4)   then output;
	%end;
    %else %if &ds=8 %then %do;
	if  avisitn in (8) then output;
	%end;
	%else %if &ds=12 %then %do;
	if  avisitn in (12)   then output;
	%end;
	
	 run;

/*%end;*/

	/*%else %if &pval.>=0.05 %then %do;*/	** ANCOVA **;
		ods select none;

	** LS MEAN DIFF, SE, 95% CI, p-value between trt **;

		
 data target_1_&ds. ;
  SET target ;
  IF chg ne . and trtn in (1,2,3) and &whr;; 
id=subjid;
 RUN ;

proc mixed data=target_1_&ds. method=reml;
class id avisitn SSNRISN  trtn;
model chg=base trtn avisitn trtn*avisitn base*avisitn SSNRISN SSNRISN*avisitn/ ddfm=kr residual outp=residual;
repeated avisitn/type=un sub=id;
lsmeans trtn*avisitn / diff cl alpha=0.05;
ods output LSMeans=LSM_temp_&ds.   diffs=lsmdiffs_&ds.;

run;


ods select all;
data lsmdiffs1_&ds.;
set lsmdiffs_&ds.;
   by avisitn trtn ;
   where  trtn in (1,2) and _trtn=3;
	LS_Mean=strip(put(round(Estimate,0.1),9.1));
	SE=strip(put(round(stderr,0.01),9.2));
    LS_MEANCL= compress('('||put(Lower,9.1))||', '||compress(put(upper,9.1))||')';
	P_VALUE=tranwrd(compress(put(Probt,pvalue6.4)),'<.','<0.');

	      %if &ds=1 %then %do;
	        if  avisitn in (1)  and  _avisitn in (1) then output;
	      %end;
	%else %if &ds=4 %then %do;
	if  avisitn in (4)  and  _avisitn in (4) then output;
	%end;
    %else %if &ds=8 %then %do;
	if  avisitn in (8)  and  _avisitn in (8) then output;
	%end;
	%else %if &ds=12 %then %do;
	if  avisitn in (12)  and  _avisitn in (12) then output;
	%end;
	
run;

proc transpose data=lsmdiffs1_&ds. out=lsmdiffs_stat_&ds.;
id trtn;
var ls_mean se LS_MEANCL  p_value;
by avisitn;

run;


data lsmdiffs_stat_&ds.;
length JM_AVAL_LABEL _name_ _LABEL_ JM_AVAL_NAMEC $200. ;
 SET lsmdiffs_stat_&ds. ;
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



		data lsmdiffs_out_&ds.;
		set lsmdiffs_stat_&ds.;
	 run;

		
	/*%end;*/


%mend;
%lsm(whr=%str(avisitn <=1),ds=1);
%lsm(whr=%str(avisitn <=4),ds=4);
%lsm(whr=%str(avisitn <=8),ds=8);
%*lsm(whr=%str(avisitn <=12),ds=12);



data LSMD_OUT_HL ;
length JM_AVAL_LABEL $200. ;
 SET LSMD_OUT_HL_1 LSMD_OUT_HL_4 LSMD_OUT_HL_8;* LSMD_OUT_HL_12;
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
 

 keep avisitn jm_block JM_AVAL_LABEL JM_AVAL_NAMEC _NAME_ _LABEL_ trtn1 trtn2 ord;
 RUN;

 data lsmdiffs_out;
 set lsmdiffs_out_1 lsmdiffs_out_4 lsmdiffs_out_8;* lsmdiffs_out_12;
 run;


 data stats;
 length JM_BLOCK $10.;
 set lsmdiffs_out(in=a) LSMD_OUT_HL(in=b);



       if avisitn=1 then jm_block="103";
 else  if avisitn=4 then jm_block="105";
 else  if avisitn=8 then jm_block="107";
 else  if avisitn=12 then jm_block="109";
 
 
run;

 Data final ;
 length jm_aval_label _name_ _label_ trtn1 trtn2 trtn3 $200 ;
  set JM_AVAL_TRANS1  stats ;
  if jm_aval_label = 'Change' then do;
    jm_aval_label = "Change from Baseline to End of Week "||strip(put(avisitn,best.)) ;
   
  end;

 JM_BLOCKN=input(JM_BLOCK,best.);

 RUN ;


proc sort data=final;
by avisitn jm_blockn ord;
run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=FINAL, JM_INDSN2= , JM_BREAKCNT= 10, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

data jm_aval_allreport1;
 set jm_aval_allreport1;

   if jm_aval_namec="Q1C-Q3C" then jm_aval_namec="Q1, Q3";
  if jm_aval_namec="SE_Mean" then jm_aval_namec="SE";
  if jm_aval_namec="SE_Dif" then jm_aval_namec="SE";
  if jm_aval_namec="LS_MEANCL" then jm_aval_namec="95% CI";
  if jm_aval_namec="EMD" then jm_aval_namec="Estimated Median Difference";

   if jm_aval_namec="p-value" then jm_aval_namec="p-value^n";

    if jm_aval_namec="Min, Max" then jm_aval_namec="Min, Max";

	if jm_aval_namec="LS Mean Diff" and ord=10 then jm_aval_namec="LS Mean Diff to Placebo";

 
   if jm_block = ' ' then delete ;
      if strip(jm_Aval_namec)='EMD' then jm_aval_namec='Estimated median difference';
      if strip(grouplabel)=:'Change' and upcase(strip(_name_)) in('JM_Q1C_Q3C','LS_MEANCL') then jm_aval_namec=strip(jm_aval_namec);
      jm_aval_namec='   '||strip(jm_aval_namec);

	  groupvarn=orig_rec_num;
	  jm_aval_namen=orig_rec_num;



	   if jm_block in ("101") then pageno=1;
		 if jm_block in ("102") then pageno=2;
            if jm_block in ("103") and ord<=5 then pageno=2;
	   else if jm_block in ("103") and ord>5 then pageno=3;

	    if jm_block in ("104") then pageno=5;
            if jm_block in ("105") and ord<=5 then pageno=5;
	   else if jm_block in ("105") and ord>5  then pageno=6;
        

	    if jm_block in ("106") then pageno=8;
            if jm_block in ("107") and ord<=5 then pageno=8;
	   else if jm_block in ("107") and ord>5  then pageno=9;
        

	        if jm_block in ("108") then pageno=11;
            if jm_block in ("109") and ord<=5 then pageno=11;
	   else if jm_block in ("109") and ord>5  then pageno=12;
        
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


