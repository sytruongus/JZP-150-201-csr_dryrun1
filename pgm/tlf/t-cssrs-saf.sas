/*************************************************************************
 * STUDY DRUG:        
 * PROTOCOL NO:        
 * PROGRAMMER:        Pavani Balmuri
 * DATE CREATED:      
 * PROGRAM NAME:      t-CSSRS-SAF.SAS
 * DESCRIPTION:       C-SSRS Across All Study Periods, Excluding Placebo Data 
 * DATA SETS USED:    
 ***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer: VIjay - re-did teh whole program as original program was wrong.
			Vijay - added Any YES sections for Ideation and Behaviour
*************************************************************************/;
OPTIONS MPRINT NONUMBER;
proc datasets lib=work memtype=data kill;quit;

*-----------------------------------------------------------------;
*INCLUDE THE TLF DEFAULTS FOR THE POPULATION AND DATASETS.;
*UPDATE ANY DEFAULTS AS REQUIRED FOR THE TABLE;
*-----------------------------------------------------------------;

%include " _treatment_defaults-saffl.sas";
%include " _treatment_defaults-cssrs-saffl.sas";
%LET _BIGN_WHERE=SAFFL='Y' ;
%LET _DEFAULT_WHERE=SAFFL='Y' ;
%LET _DEFAULT_BOX= Visit | ^    Number of Subjects with ;
%LET _DEFAULT_SPAN_HEAD=Baseline Medication Group ^{nbspace 33} ^n;
*-----------------------------------------------------------------;

*TITLE AND FOOTNOTES
*-----------------------------------------------------------------;
%global mypgmname;

data _null_;
   call symputx('mypgmname',scan("%sysget(SAS_EXECFILENAME)",1,'.'));
run;
%JM_TF (jm_infile=C:\SASData\JZP-080\&study.\statdoc\TFL, JM_PROG_NAME=&mypgmname.,
   JM_PRODUCE_STATEMENTS=Y, JM_FOOT_FONT=fontsize=7pt);

*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;

*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;


 data ADSL;                             
      set adam.ADSL;                             
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
   data ADQS ;                             
      set adam.ADQS3 ;                             
      where  parcat1  in ("C-SSRS BASELINE/SCREENING VERSION","C-SSRS SINCE LAST VISIT")   and anl01fl="Y" and SAFFL="Y";
      
	  trtn=TRTAN;                             
      trt=TRTA; 
       output;                             
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="JZP150 Total";                            
      output;              
                                             
                              
   run;    

 proc freq data=ADQS noprint;
table avisitn*parcat1*parcat2*PARAMCD*PARAM/out=frq_chk;
*where parcat2="SUICIDAL BEHAVIOR";
where index(param,"Life")>0;

run;

data frq_chk1;
length newcd $200.;
set frq_chk;
newcd=put(paramn-100,z2.)||":"||strip(param);
run;
data adqscssr1;
  set ADQS;
  *where (parcat1n 1 or (parcat1n=2 and avisitn in(100,203,304))) and parcat2n ne 2;
  where parcat2 in ("SUICIDAL BEHAVIOR","SUICIDAL IDEATION") and avisitn ne . ;
  
  length type $100;
  	typen=avisitn;
	type=strip(avisit);
	if avisitn=0 then type='Baseline Visit';
  *if paramcd in("CSS0418A","CSS0418B","CSS0418C","CSS0421A","CSS0421B","CSS0221C","CSS0422A","CSS0423A") then delete;


	
if  parcat1= "C-SSRS BASELINE/SCREENING VERSION" then parcat1n=1;
else  parcat1n=2;


     if parcat2 in ("SUICIDAL BEHAVIOR") then parcat2n=2;
else if parcat2 in ("SUICIDAL IDEATION") then parcat2n=1;

run;



 proc freq data=adqscssr1 noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chk_2;
*where parcat2="SUICIDAL BEHAVIOR";
*where index(paramcd,"A")>0;

run;

data screen;
set adqscssr1;
if parcat1n=1 and index(param,"Life")>=1 ;

run;


 proc freq data=screen noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chk2;
*where parcat2="SUICIDAL BEHAVIOR";
*where index(paramcd,"A")>0;

run;
data other ;
set adqscssr1;
if parcat1n=2 ;
run;

data adqscssr1;
set screen ;

if parcat1n=1 and paramcd in ("CSS0401A","CSS0402A","CSS0403A","CSS0404A","CSS0405A",
                                    "CSS0419A","CSS0418A","CSS0415A","CSS0420A");
run;

 proc freq data=adqscssr1 noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chk_2;
*where parcat2="SUICIDAL BEHAVIOR";
*where index(paramcd,"A")>0;

run;



**derive - Any Ideation or Behaviour all other visits except past year or past months**;
proc sort data=adqscssr1 out=any1 nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 ;
  where parcat2 ne "INTENSITY OF IDEATION" and avalc ne '' ;
run;
data any1;
  set any1;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 ;
  if first.parcat1n;
run;


data any1;set any1;
 
    parcat2n=4;parcat2='Any suicidal Ideation or Behavior (1-9)';
    paramcd='CSSIDB';param='Any Ideation/Behavior(1-9)';

run;

**Any Ideation/Any Behaviour**;
proc sort data=adqscssr1 out=any3 nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2  aval ;
  where parcat2n in(1,2) and avalc ne '';
run;

proc sort data=any3;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2 descending aval ;
data any3;
  set any3;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2  descending aval ;
  if first.parcat2n;
run;

data any3;set any3;

 if parcat2n=1 then do ;
    paramcd="CSS500I";
	param='Any Suicidal Ideation (1-5)';
	paramn=500;
	parcat2n=5;

 end;

  if  parcat2n=2 then do ;
          paramcd="CSS510B";
	      param='Any Suicidal Behavior (6-9)';

		  paramn=510;
		  parcat2n=6;

end;

run;

data adqscssr2;
  set adqscssr1 
      any1 any3;* self4;
run;

proc sort data=adqscssr2;
    by studyid usubjid trtn trt; 
run;


   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target;                             
      merge ADSL(in= a) 
            adqscssr2(in= b);                             
      by studyid usubjid trtn trt;                             
      if a;  

	  
run;


 proc freq data=target noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chkt;
*where parcat2="SUICIDAL BEHAVIOR";
*where index(paramcd,"A")>0;

run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);  

*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;

*By Viist suicidal ideation*;
proc sort data=adqscssr2 out=adqs_id nodupkey;
  where parcat2n=1 and aval=1;
by usubjid trtn;
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=adqs_id,jm_intrtvar=trt);

%JM_BIGN(JM_INDSN=adqs_id,jm_suffix=2, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 5 and strip(param)='Any Suicidal Ideation (1-5)' and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=101, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Ideation (1-5)));

%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 paramn paramcd param, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 1 and aval=1), JM_FMT= , jm_bign=jm_bign2,
jm_trtvarn=trtn, jm_block=102, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Ideation - 1-5 ));

data jm_aval_count101;
length param $200.;
set jm_aval_count101;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));
parcat2n=1;
param=JM_AVAL_LABEL;



run;


data jm_aval_count1;
  set jm_aval_count101(in=a) jm_aval_count102(in=b) ;
/*  if a then do; paramcd='CSS0001';param='Suicidal Ideation 1-5';end;*/
  jm_block='1';
  JM_AVAL_LABEL='Suicidal Ideation';
  grpvar='1';

  parcat2n=1;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count101 jm_aval_count102 ;
run;quit;


**By visit Behaviour*;
proc sort data=target out=adqs_b nodupkey;
  where parcat2n=2  and aval=1;
by usubjid trtn;
run;
%jm_gen_trt_fmt(jm_indsn=adqs_b,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_b,jm_suffix=3, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6 and strip(param)='Any Suicidal Behavior (6-9)' and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=201, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior (6-9)));


%JM_BIGN(JM_INDSN=adqs_idb,jm_suffix=4, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 paramn paramcd param, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 2 and aval=1), JM_FMT= , jm_bign=jm_bign3,
jm_trtvarn=trtn, jm_block=202, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior - 6-9 ));



data jm_aval_count201;
length param $200.;
set jm_aval_count201;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));

parcat2n=2 ;
param=JM_AVAL_LABEL;



run;

data jm_aval_count2;
  set jm_aval_count201(in=a) jm_aval_count202(in=b) ;
/*  if a then do; paramcd='CSS0001';param='Suicidal Behavior 6-10';end;*/
  jm_block='2';
  JM_AVAL_LABEL='Suicidal Behavior';
    grpvar='2';
	parcat2n=2 ;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count201 jm_aval_count202 ;
run;quit;


**ideation or behaviour**;
proc sort data=target out=adqs_idb nodupkey;
  where parcat2n=4;
by usubjid trtn;
run;
%jm_gen_trt_fmt(jm_indsn=adqs_idb,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_idb,jm_suffix=4, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=adqscssr2, jm_byvar = typen type parcat1n parcat1  , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 4 ), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=3, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any suicidal Ideation or Behavior (1-9)));

**Y responses only for Ideation or Behavior**;
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1  paramn paramcd param, jm_var= parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 5  and paramcd="CSS500I" and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=4, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any Suicidal Ideation (1-5)));

%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1  paramn paramcd param, jm_var= parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6  and paramcd="CSS510B" and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=5, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any Suicidal Behavior (6-9)));



**  Self-injurious Behavior without Suicidal Intent**;

data adqscssr_self;
set screen ;

if parcat1n=1 and paramcd in ("CSS0414A");
run;

proc sort data=adqscssr_self out=self nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 paramn paramcd param;
  where parcat2 ne "INTENSITY OF IDEATION" and avalc ne '' and index(paramcd ,"CSS0414")>0 ;
run;

data self4;
  set self;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 paramn paramcd param ;
  if first.paramcd;

  parcat2n=7;
  parcat2='Self-injurious Behavior without Suicidal Intent';

  paramcd="CSS520S";
	 param='Self-injurious Behavior without Suicidal Intent';
run;


data adqscssr_self;
set adqscssr_self self4;
run;


proc sort data=adqscssr_self out=adqs_idb nodupkey;
  where parcat2n=7;
by usubjid trtn;
run;
%jm_gen_trt_fmt(jm_indsn=adqs_idb,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_idb,jm_suffix=5, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=adqscssr_self, jm_byvar = typen type parcat1n parcat1 paramn paramcd param, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 7), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=6, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Self-injurious Behavior without Suicidal Intent));

**Y responses only for non-suicidal behavior**;
%JM_AVAL_COUNT(JM_INDSN=adqscssr_self, jm_byvar = typen type parcat1n parcat1 paramn paramcd param, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(aval=1), JM_FMT= , jm_bign=jm_bign5,
jm_trtvarn=trtn, jm_block=7, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Yes));

data jm_aval_count6;
set jm_aval_count6;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));
run;


data all;
set jm_aval_count1
    jm_aval_count2
	jm_aval_count3
	jm_aval_count4
	jm_aval_count5
	jm_aval_count6
	jm_aval_count7
	;

	grpvar=strip(grpvar);

run;

proc sort data=all;
by parcat1n parcat1 parcat2n parcat2 paramn paramcd param typen ;
run;



*----------------------------------------------------------------------------------------------------------------------------------;
*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);


proc sort data=JM_AVAL_ALLDATA1;
by parcat1n parcat1 JM_BLOCK parcat2n parcat2 paramn paramcd param typen ;
run;


DATA jm_aval_alldata1;set jm_aval_alldata1;
origparm=param;
     if strip(paramcd) in("CSS0401A","CSS0401B","CSS0401C") then do; param="1.Wish to be dead"; paramn=2;end;
else if strip(paramcd) in("CSS0402C","CSS0402A","CSS0402B") then do; param="2.Non-specific active suicidal thoughts"; paramn=3;end;
else if strip(paramcd) in("CSS0403C","CSS0403A","CSS0403B") then do;  param="3.Active suicidal ideation with any methods (not plan) without intent to act"; paramn=4;end;
else if strip(paramcd) in("CSS0404C","CSS0404A","CSS0404B") then do; param="4.Active suicidal ideation with some intent to act,without specific plan"; paramn=5;end;
else if strip(paramcd) in("CSS0405C","CSS0405A","CSS0405B") then do; param="5.Active suicidal ideation with specific plan and intent"; paramn=6;end;
else if strip(paramcd) in("CSS0419C","CSS0419A","CSS0419B") then do; param="6.Preparatory acts or behavior"; paramn=8;end;
else if strip(paramcd) in("CSS0418A","CSS0418B","CSS0418C") then do; param="7.Aborted attempt"; paramn=9;end;
else if strip(paramcd) in("CSS0415A","CSS0415B","CSS0415C") then do; param="8.Interrupted attempt"; paramn=10;end;
else if strip(paramcd) in("CSS0420A","CSS0420B","CSS0420C") then do; param="9.Non-fatal suicide attempt"; paramn=11;end;
else if strip(paramcd) in("CSS0221","CSS0421A","CSS0421B")  then do;  param="10.Completed suicide"; paramn=12;end;
else if strip(JM_AVAL_LABEL)="Any suicidal Ideation or Behavior (1-9)" then do; param="Any suicidal Ideation or Behavior (1-9)"; paramn=13;end;
else if strip(param)="Any Suicidal Ideation (1-5)" then do; param="Any Suicidal Ideation (1-5)"; paramn=14;end;
else if strip(param)="Any Suicidal Behavior (6-9)" then do; param="Any Suicidal Behavior (6-9)"; paramn=15;end;

else if strip(paramcd) in("CSS520S") and JM_BLOCK="6" then do; 
	paramn=16; param="Self-injurious Behavior without Suicidal Intent";
end;

else if strip(paramcd) in("CSS520S") and JM_BLOCK="7" then do; 
	paramn=17; param="Yes";
end;
else if  strip(param)="Suicidal Ideation (1-5)" then do; param="Suicidal Ideation (1-5)"; paramn=1;end;
else if  strip(param)="Suicidal Behavior (6-9)" then do; param="Suicidal Behavior (6-9)"; paramn=7;end;

if index(JM_AVAL_LABEL,"Any")>0 then do;

   JM_block="3";
   param=JM_AVAL_LABEL;
   grpvar="3";
   end;

if index(JM_AVAL_LABEL,"Self")>0 then JM_block="7";
 


grpvar=strip(grpvar);
if index(param,"CSS0")>=1 then delete;



run;


*** Calculate the Big N denominator from adqscssr by treatment ***;
%JM_BIGN(JM_INDSN=adsl,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );
*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata1, 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=typen type JM_BLOCK JM_AVAL_LABEL parcat1n parcat1 grpvar  paramn paramcd param JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_AVAL_COUNTC , JM_TRANS_ID=JM_TRTVARN);

proc sort data=jm_aval_trans1;
by JM_BLOCK grpvar paramn ;
run;


data dummy;

do paramn=1 to 17;
 parcat1n=1;
 avisitn=-1;
 output;
 end;
run;

proc sort data=jm_aval_trans1;
by paramn;

run;

data jm_aval_trans1;
merge dummy jm_aval_trans1;
by parcat1n paramn;

if paramn=12 then do;

 typen=avisitn;
 JM_BLOCK="2";
 JM_AVAL_LABEL="Suicidal Behavior";
 parcat1="C-SSRS BASELINE/SCREENING VERSION";
 grpvar="2";
 PARAMCD="CSS0221";
 param="10.Completed suicide";
 JM_AVAL_NAMEC=-1;

 type=Screening;
end;
run;





   data jm_aval_trans1;
     set jm_aval_trans1;
	 by JM_BLOCK grpvar paramn ;
	 where typen ne .;
	 

	   array myarr{*} $ trtn:;
  do i=1 to dim(myarr);
    if paramn in (1,7,16) and myarr(i)='' then myarr(i)='0';
	else if paramn not  in (1,7,16) and myarr(i)='' then myarr(i)='0(0)';
  end;


	jm_aval_namec=strip(param);

	if paramcd ne  ""  and JM_Block in (1,2) then jm_aval_namec='^{nbspace 5}'||strip(jm_aval_namec);

	if paramcd ne  ""  and JM_Block in (7) and param="Yes" then jm_aval_namec='^{nbspace 5}'||strip(jm_aval_namec);

	if  paramn in (1,7,13,14,15,16) then jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);

	if last.grpvar then jm_aval_namec=strip(jm_aval_namec)||"^n";
run;





data dummy_1;
set jm_aval_trans1;
by parcat1n avisitn;
if first.avisitn;

paramn=0;

if avisitn=-1 then jm_aval_namec="Screening Visit ^nFor Lifetime";
else jm_aval_namec=strip(type);
drop trtn:;
run;


data jm_aval_trans1;
set dummy_1 jm_aval_trans1;

  

run;

run;

proc sort data=jm_aval_trans1;
by parcat1n avisitn paramn;
run;
data jm_aval_trans1;
set jm_aval_trans1;

	  orig_block=jm_block;
	  jm_block=strip(put(typen,best.));
	  jm_aval_label="Screening Visit^nFor Lifetime";

	  origparamn=paramn;
	  *paramn=_n_;

	  part=1;

run;




/*****PART 3 Since Last Visit by visit*****/
data adqscssr_1;
  set ADQS;
  *where (parcat1n 1 or (parcat1n=2 and avisitn in(100,203,304))) and parcat2n ne 2;
  where parcat2 in ("SUICIDAL BEHAVIOR","SUICIDAL IDEATION") and avisitn ne . ;
  
  length type $100;
  	typen=avisitn;
	type=strip(avisit);
	if avisitn=0 then type='Baseline Visit';
  *if paramcd in("CSS0418A","CSS0418B","CSS0418C","CSS0421A","CSS0421B","CSS0221C","CSS0422A","CSS0423A") then delete;
	
if  parcat1= "C-SSRS BASELINE/SCREENING VERSION" then parcat1n=1;
else  parcat1n=2;

     if parcat2 in ("SUICIDAL BEHAVIOR") then parcat2n=2;
else if parcat2 in ("SUICIDAL IDEATION") then parcat2n=1;

run;

proc freq data=adqscssr_1 noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chk_2;
where parcat1n=2;
run;

data screen;
set adqscssr_1;
if parcat1n=2 ;
run;

data adqscssr_1;
set screen ;
   if parcat1n=2 and paramcd in ("CSS0201","CSS0202","CSS0203","CSS0204","CSS0205",
                                 "CSS0219","CSS0218","CSS0215","CSS0220","CSS0221");
run;

 proc freq data=adqscssr_1 noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chk_2;

run;



**derive - Any Ideation or Behaviour all other visits except past year or past months**;
proc sort data=adqscssr_1 out=any_1 nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 avisitn avisit aval parcat2n parcat2 ;
  where parcat2 ne "INTENSITY OF IDEATION" and aval=1 ;
run;
data any_1;
  set any_1;
  by usubjid trtn trt typen type parcat1n parcat1 avisitn avisit aval parcat2n parcat2 ;
  if first.parcat1n;
run;


data any_1;set any_1;
 
    parcat2n=4;parcat2='Any suicidal Ideation or Behavior (1-9)';
    paramcd='CSSIDB';param='Any Ideation/Behavior(1-9)';

run;

**Any Ideation/Any Behaviour**;
proc sort data=adqscssr_1 out=any_3 nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2  aval ;
  where parcat2n in(1,2) and avalc ne ""; 
run;

proc sort data=any_3;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2 descending aval ;
data any_3;
  set any_3;
  by usubjid trtn trt typen type parcat1n parcat1 parcat2n parcat2  descending aval ;
  if first.parcat2n;
run;

data any_3;set any_3;

 if parcat2n=1 then do ;
    paramcd="CSS500I";
	param='Any Suicidal Ideation (1-5)';
	paramn=500;
	parcat2n=5;

 end;

  if  parcat2n=2 then do ;
          paramcd="CSS510B";
	      param='Any Suicidal Behavior (6-9)';
		  paramn=510;
		  parcat2n=6;

end;

run;

data adqscssr_2;
  set adqscssr_1 
      any_1 any_3;* self4;
run;

proc sort data=adqscssr_2;
    by studyid usubjid trtn trt avisitn ; 
run;


   *** Create TARGET dataset by combing the Working datasets ***;                          
   data target;                             
      merge ADSL(in= a) 
            adqscssr_2(in= b);                             
      by studyid usubjid trtn trt;                             
      if a;  

	  if parcat1n=2;
run;


 proc freq data=target noprint;
table avisitn*parcat1n*parcat1*parcat2n*parcat2*PARAMCD*PARAM/out=frq_chkt;
*where parcat2="SUICIDAL BEHAVIOR";
*where index(paramcd,"A")>0;

run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=,JM_SUFFIX=1);  

*----------------------------------------------------------------------------------------------------------------------------------;
* CALL SUMMARYSTAT FOR DESCRIPTIVE AND COUNTF FOR THE CATEGORICAL IN THE ORDER OF TABLE SHELL AND INCREMENT BLOCK NUMBERS;
*----------------------------------------------------------------------------------------------------------------------------------;

*By Viist suicidal ideation*;
proc sort data=adqscssr_2 out=adqs_id nodupkey;
  where parcat2n=1 and aval=1;
by usubjid trtn ;
run;

 *** Create Treatment formats for reporting ***;
   %jm_gen_trt_fmt(jm_indsn=adqs_id,jm_intrtvar=trt);

%JM_BIGN(JM_INDSN=adqs_id,jm_suffix=2, jm_trtvarn=trtn, jm_trtfmt=trt );


%JM_AVAL_COUNT(JM_INDSN=target, jm_var=SAFFL,JM_SECONDARY_WHERE=avalc ne '' , JM_FMT= , jm_bign=jm_bign1, jm_trtvarn=trtn,
jm_block=200, jm_cntvar=usubjid,JM_BYVAR= paramn param  avisitn avisit, JM_AVAL_LABEL=%bquote(Visit) );


%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 avisitn avisit , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 5 and strip(param)='Any Suicidal Ideation (1-5)' and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=201, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Ideation (1-5)));

%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 paramn paramcd param avisitn avisit, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 1 and aval=1), JM_FMT= , jm_bign=jm_bign2,
jm_trtvarn=trtn, jm_block=202, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Ideation - 1-5 ));

data jm_aval_count201;
length param $200.;
set jm_aval_count201;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));
parcat2n=1;
param=JM_AVAL_LABEL;



run;

PROC SORT DATA=JM_AVAL_COUNT201;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

PROC SORT DATA=JM_AVAL_COUNT202;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

data JM_AVAL_COUNT202;
  merge JM_AVAL_COUNT202(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT201(in=b keep=parcat1n parcat1  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by parcat1n parcat1  avisitn avisit jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT202;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;

data jm_aval_count_1;
  set jm_aval_count201(in=a) jm_aval_count202(in=b) ;
/*  if a then do; paramcd='CSS0001';param='Suicidal Ideation 1-5';end;*/
  jm_block='11';
  JM_AVAL_LABEL='Suicidal Ideation';
  grpvar='11';

  parcat2n=1;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count201 jm_aval_count202 ;
run;quit;


**By visit Behaviour*;
proc sort data=target out=adqs_b nodupkey;
  where parcat2n=2  and aval=1;
by usubjid trtn;
run;

  proc sql noprint;
  create table sub as
     select  count(distinct usubjid) as count	  from adqs_b
	  ;
  quit;

  data sub;
  set sub;

  call symput("subj",count);
  run;
  %put &subj;

%macro subj;
%if &subj >=1 %then %do;



%jm_gen_trt_fmt(jm_indsn=adqs_b,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_b,jm_suffix=3, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 avisitn avisit , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6 and strip(param)='Any Suicidal Behavior (6-9)' and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=301, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior (6-9)));

%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 paramn paramcd param avisitn avisit, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 2 and aval=1), JM_FMT= , jm_bign=jm_bign3,
jm_trtvarn=trtn, jm_block=302, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior - 6-9 ));


data jm_aval_count301;
length param $200.;
set jm_aval_count301;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));

parcat2n=2 ;
param=JM_AVAL_LABEL;

run;

 PROC SORT DATA=JM_AVAL_COUNT301;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

PROC SORT DATA=JM_AVAL_COUNT302;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

data JM_AVAL_COUNT302;
  merge JM_AVAL_COUNT302(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT301(in=b keep=parcat1n parcat1  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by parcat1n parcat1  avisitn avisit jm_trtvarn;
  if a and b;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
run;
proc sort data = JM_AVAL_COUNT302;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


data jm_aval_count_2;
  set jm_aval_count301(in=a) jm_aval_count302(in=b) ;
/*  if a then do; paramcd='CSS0001';param='Suicidal Behavior 6-10';end;*/
  jm_block='12';
  JM_AVAL_LABEL='Suicidal Behavior';
    grpvar='2';
	parcat2n=2 ;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count201 jm_aval_count202 ;
run;quit;


%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1  paramn paramcd param avisitn avisit, jm_var= parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6  and paramcd="CSS510B" and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=15, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any Suicidal Behavior (6-9)));

%end;

%else %do;

proc sort data=target out=adqs_b nodupkey;
  where parcat2n=2 ;
by usubjid trtn;
run;


%jm_gen_trt_fmt(jm_indsn=adqs_b,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_b,jm_suffix=3, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 avisitn avisit , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6 and strip(param)='Any Suicidal Behavior (6-9)' ), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=301, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior (6-9)));

%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1 paramn paramcd param avisitn avisit, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 2 ), JM_FMT= , jm_bign=jm_bign3,
jm_trtvarn=trtn, jm_block=302, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Suicidal Behavior - 6-9 ));


data jm_aval_count301;
length param $200.;
set jm_aval_count301;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));

JM_AVAL_COUNTC="0";
JM_AVAL_COUNT=0;

parcat2n=2 ;
param=JM_AVAL_LABEL;

run;

 PROC SORT DATA=JM_AVAL_COUNT301;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

PROC SORT DATA=JM_AVAL_COUNT302;
  BY parcat1n parcat1  avisitn jm_trtvarn;
run;

data JM_AVAL_COUNT302;
  merge JM_AVAL_COUNT302(drop=JM_AVAL_BIGN in=a) JM_AVAL_COUNT301(in=b keep=parcat1n parcat1  avisitn avisit  JM_TRTVARN JM_AVAL_COUNT RENAME=(JM_AVAL_COUNT=JM_AVAL_BIGN));
  by parcat1n parcat1  avisitn avisit jm_trtvarn;
  if a and b;
  JM_AVAL_COUNT=0;

  if JM_AVAL_COUNT GT 0 then do;
  	JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,BEST.))|| ' ('||STRIP(PUT(JM_AVAL_COUNT/JM_AVAL_BIGN*100,4.1))||')';
  END;
else   JM_AVAL_COUNTC="0(0)";
run;
proc sort data = JM_AVAL_COUNT302;
by JM_AVAL_NAMEN JM_AVAL_NAMEC JM_TRTVARN ;
run;


data jm_aval_count_2;
  set jm_aval_count301(in=a) jm_aval_count302(in=b) ;
/*  if a then do; paramcd='CSS0001';param='Suicidal Behavior 6-10';end;*/
  jm_block='12';
  JM_AVAL_LABEL='Suicidal Behavior';
    grpvar='2';
	parcat2n=2 ;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count301 jm_aval_count302 ;
run;quit;


%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1  paramn paramcd param avisitn avisit, jm_var= parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 6  and paramcd="CSS510B" ), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=15, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any Suicidal Behavior (6-9)));


data JM_AVAL_COUNT15;
set  JM_AVAL_COUNT15;
     JM_AVAL_COUNTC="0(0)";
	 JM_AVAL_COUNTC=0;

run;

%end;



%mend;
%subj;



**ideation or behaviour**;
proc sort data=target out=adqs_idb nodupkey;
  where parcat2n=4 and aval=1;
by usubjid trtn;
run;

%jm_gen_trt_fmt(jm_indsn=adqs_idb,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_idb,jm_suffix=4, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=adqscssr_2, jm_byvar = typen type parcat1n parcat1 avisitn avisit , jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 4 and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=13, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any suicidal Ideation or Behavior (1-9)));

**Y responses only for Ideation or Behavior**;
%JM_AVAL_COUNT(JM_INDSN=target, jm_byvar = typen type parcat1n parcat1  paramn paramcd param avisitn avisit, jm_var= parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 5  and paramcd="CSS500I" and aval=1), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=14, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Any Suicidal Ideation (1-5)));








**  Self-injurious Behavior without Suicidal Intent**;

data adqscssr_self;
set screen ;

if parcat1n=2 and paramcd in ("CSS0214");
run;

proc sort data=adqscssr_self out=self nodupkey;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 paramn paramcd param avisitn avisit;
  where parcat2 ne "INTENSITY OF IDEATION" and avalc ne '' and index(paramcd ,"CSS0214")>0 ;
run;

data self4;
  set self;
  by usubjid trtn trt typen type parcat1n parcat1 aval parcat2n parcat2 paramn paramcd param ;
  if first.paramcd;

  parcat2n=7;
  parcat2='Self-injurious Behavior without Suicidal Intent';

  paramcd="CSS520S";
	 param='Self-injurious Behavior without Suicidal Intent';
run;


data adqscssr_self;
set adqscssr_self self4;
run;


proc sort data=adqscssr_self out=adqs_idb nodupkey;
  where parcat2n=7;
by usubjid trtn;
run;
%jm_gen_trt_fmt(jm_indsn=adqs_idb,jm_intrtvar=trt);
%JM_BIGN(JM_INDSN=adqs_idb,jm_suffix=5, jm_trtvarn=trtn, jm_trtfmt=trt );
%JM_AVAL_COUNT(JM_INDSN=adqscssr_self, jm_byvar = typen type parcat1n parcat1 paramn paramcd param avisitn avisit, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(parcat2n eq 7), JM_FMT= , jm_bign=jm_bign1,
jm_trtvarn=trtn, jm_block=16, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Self-injurious Behavior without Suicidal Intent));

**Y responses only for non-suicidal behavior**;
%JM_AVAL_COUNT(JM_INDSN=adqscssr_self, jm_byvar = typen type parcat1n parcat1 paramn paramcd param avisitn avisit, jm_var=parcat2n,
	JM_SECONDARY_WHERE= %str(aval=1), JM_FMT= , jm_bign=jm_bign5,
jm_trtvarn=trtn, jm_block=17, jm_cntvar=usubjid,   JM_AVAL_LABEL=%bquote(Yes));

data jm_aval_count16;
set jm_aval_count16;

JM_AVAL_COUNTC=strip(put(JM_AVAL_COUNT,best.));

param=strip(JM_AVAL_LABEL);

run;


data jm_aval_count17;
set jm_aval_count17;


param=strip(JM_AVAL_LABEL);

run;

data all2;
set jm_aval_count_1
    jm_aval_count_2
	jm_aval_count13
	jm_aval_count14
	jm_aval_count15
	jm_aval_count16
	jm_aval_count17
	;

	grpvar=strip(compress(grpvar));

run;

proc sort data=all2;
by parcat1n parcat1 parcat2n  paramn paramcd param typen avisitn ;
run;


proc datasets lib=work memtype=data;
delete jm_aval_count200  ;
run;quit;
*----------------------------------------------------------------------------------------------------------------------------------;
*  SET THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA2);


proc sort data=JM_AVAL_ALLDATA2;
by parcat1n parcat1 JM_BLOCK parcat2n  paramn paramcd param typen ;
run;


DATA jm_aval_alldata2;
length param $200.;
set jm_aval_alldata2;
origparm=param;

grpvar=strip(compress(grpvar));


     if strip(paramcd) in("CSS0201") then do; param="1.Wish to be dead"; paramn=2;end;
else if strip(paramcd) in("CSS0202") then do; param="2.Non-specific active suicidal thoughts"; paramn=3;end;
else if strip(paramcd) in("CSS0203") then do;  param="3.Active suicidal ideation with any methods (not plan) without intent to act"; paramn=4;end;
else if strip(paramcd) in("CSS0204") then do; param="4.Active suicidal ideation with some intent to act,without specific plan"; paramn=5;end;
else if strip(paramcd) in("CSS0205") then do; param="5.Active suicidal ideation with specific plan and intent"; paramn=6;end;
else if strip(paramcd) in("CSS0219") then do; param="6.Preparatory acts or behavior"; paramn=8;end;
else if strip(paramcd) in("CSS0218") then do; param="7.Aborted attempt"; paramn=9;end;
else if strip(paramcd) in("CSS0215") then do; param="8.Interrupted attempt"; paramn=10;end;
else if strip(paramcd) in("CSS0220") then do; param="9.Non-fatal suicide attempt"; paramn=11;end;
else if strip(paramcd) in("CSS0221")  then do;  param="10.Completed suicide"; paramn=12;end;
else if strip(JM_AVAL_LABEL)="Any suicidal Ideation or Behavior (1-9)" then do; param="Any suicidal Ideation or Behavior (1-9)"; paramn=13;end;
else if strip(param)="Any Suicidal Ideation (1-5)" then do; param="Any Suicidal Ideation (1-5)"; paramn=14;end;
else if strip(param)="Any Suicidal Behavior (6-9)" then do; param="Any Suicidal Behavior (6-9)"; paramn=15;end;

else if strip(paramcd) in ("CSS520S")  then do; 
	paramn=16; param="Self-injurious Behavior without Suicidal Intent";
end;

else if strip(paramcd) in("CSS0214") and JM_BLOCK="17" then do; 
	paramn=17; param="Yes";
end;
else if  strip(param)="Suicidal Ideation (1-5)" then do; param="Suicidal Ideation (1-5)"; paramn=1;end;
else if  strip(param)="Suicidal Behavior (6-9)" then do; param="Suicidal Behavior (6-9)"; paramn=7;end;

if index(JM_AVAL_LABEL,"Any")>0 then do;

   JM_block="13";
   param=JM_AVAL_LABEL;
   grpvar="13";
   end;

if index(JM_AVAL_LABEL,"Self")>0 then JM_block="17";


if paramn=16 then param="Self-injurious Behavior without Suicidal Intent";
if paramn=17 then param="Yes";


grpvar=compress(grpvar);
if index(param,"CSS0")>=1 then delete;
grpvarn=input(grpvar,best.);

run;


data Jm_aval_alldata3;
set Jm_aval_alldata2;
if paramn=16 then param="Self-injurious Behavior without Suicidal Intent";
if paramn=17 then param="Yes";
run;


*** Calculate the Big N denominator from adqscssr by treatment ***;
%JM_BIGN(JM_INDSN=adsl,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );
*----------------------------------------------------------------------------------------------------------------------------------;

*  TRANSPOSE THE DATASETS 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata2, 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS3, JM_TRANS_BY=avisitn typen type JM_BLOCK JM_AVAL_LABEL parcat1n parcat1 parcat2n grpvarn  paramn paramcd param JM_AVAL_NAMEC, 
   JM_TRANS_VAR=JM_AVAL_COUNTC , JM_TRANS_ID=JM_TRTVARN);

proc sort data=jm_aval_trans3;
by avisitn JM_BLOCK parcat2n paramn ;
run;



data dummy1;
set jm_aval_trans1(keep=paramn JM_AVAL_NAMEC param where=(paramn ne 0));

do parcat1n=2 to 2;
  do avisitn=-1,0,1,2,4,8,10,12,92;
      

            output;
       
  end;
end;


run;




proc sort data=jm_aval_trans3 ;
by parcat1n avisitn  paramn ;
run;

proc sort data=dummy1;
by parcat1n avisitn  paramn ;
run;


data jm_aval_trans4;
merge dummy1 jm_aval_trans3(drop=JM_AVAL_NAMEC );
by parcat1n avisitn  paramn param;
 if 1<=paramn<=6 then do;
  JM_BLOCK="11";
  JM_AVAL_LABEL="Suicidal Ideation";
  parcat2n=1;
  grpvarn=11;
  grpvar="11";
  end;

else if 7<=paramn<=12 then do;
  JM_BLOCK="12";
  JM_AVAL_LABEL="Suicidal Behavior";
  parcat2n=2;
  grpvarn=12;
  grpvar="12";
  end;  
  else if 13<=paramn<=15 then do;
  JM_BLOCK="13";
  JM_AVAL_LABEL="Any suicidal Ideation or Behavior (1-9)";
  parcat2n=3;
  grpvarn=13;
  grpvar="13";
  end;  
   

    else if 16<=paramn<=17 then do;
  JM_BLOCK="14";
  JM_AVAL_LABEL="Self-injurious Behavior without Suicidal Intent";
  parcat2n=4;
  grpvarn=14;
  grpvar="14";
  end; 
run;


proc  sort data=jm_aval_trans4 out=jm_aval_trans4;
      by  parcat1n avisitn grpvar paramn ;;
run;

data jm_aval_trans5;
set jm_aval_trans4;
 by  parcat1n avisitn grpvar paramn ;

  PARCAT1="C-SSRS SINCE LAST VISIT";


  array myarr{*} $ trtn:;
  do i=1 to dim(myarr);
    if paramn in (1,7,16) and myarr(i)='' then myarr(i)='0';
	else if paramn not  in (1,7,16) and myarr(i)='' then myarr(i)='0(0)';
  end;

  if jm_aval_namec eq  ""  and JM_Block in ("11","12") then do;
  if paramn ne 7 then jm_aval_namec='^{nbspace 2}'||strip(param);
  else if paramn in ( 7)  then jm_aval_namec=strip(param);
  if last.grpvar then jm_aval_namec=strip(jm_aval_namec)||"^n";
  end;


run;


proc freq data=jm_aval_trans5 noprint;

table parcat1n*avisitn*type/out=vis;
where type ne "";
run;

data jm_aval_trans6;
merge jm_aval_trans5(drop=type) vis(keep=parcat1n type avisitn);
by parcat1n avisitn;

typen=avisitn;

run;

data dummy2;
set jm_aval_trans6;
by parcat1n avisitn;
if first.avisitn;

paramn=0;

if avisitn=-1 then jm_aval_namec="Screening Visit 2^nSince Last Visit";
else jm_aval_namec=strip(type);

  drop trtn:;

run;

data jm_aval_trans7;
set dummy2 jm_aval_trans6;

run;

proc sort data=jm_aval_trans7;
by parcat1n avisitn paramn;
run;


data final;
set jm_aval_trans1(in=a) jm_aval_trans7(in=b);

if paramn=10  and parcat1n=1 then delete;


run;

*----------------------------------------------------------------------------------------------------------------------------------;

*  APPLY PAGEBREAK 
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_PGBRK (JM_INDSN1=, JM_INDSN2=final, JM_BREAKCNT=15, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT1);

DATA jm_aval_allreport1;
 set jm_aval_allreport1;


  pageno=typen;
run ;


PROC SORT DATA=JM_AVAL_ALLREPORT1;
  BY TYPEN orig_block paramn jm_aval_namec;
run;
data jm_aval_allreport2;
  set jm_aval_allreport1;
  by typen orig_block paramn jm_Aval_namec;
  if first.typen then cnt=0;cnt+1;
  retain cnt;
  jm_aval_namec=strip(put(cnt,best.))||': ^{nbspace 1}'||jm_aval_namec;
  jm_aval_namec=tranwrd(jm_aval_namec,'any methods (not','any methods ^n ^{nbspace 7} (not');
  jm_aval_namec=tranwrd(jm_aval_namec,'some intent to act','some intent to ^n ^{nbspace 7} act');
  	
run;
ods escapechar="^";

*-----------------------------------------------------------------;
*TITLES AND FOOTNOTES ARE READ FROM EXCEL SPREADSHEET. ;
*-----------------------------------------------------------------;
options nonumber;
*----------------------------------------------------------------------------------------------------------------------------------;

*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport2, JM_BIGNDSN=Jm_bign1,JM_CELLWIDTH=1.60in,JM_TRTWIDTH=0.50in, 
	jm_spanheadopt=Y , JM_INDENTOPT=N, jm_breakopt=Y, jm_breakvar=JM_AVAL_LABEL);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;

%symdel outputdt;
