/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       krishnaprasad Mummalaneni
* DATE CREATED:   	22NOV2022
* PROGRAM NAME:   	f_pgi_forest_subg
* DESCRIPTION:    	Creating Adverse Events listing
* DATA SETS USED: 	adsl adae 
***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer:    
Date:          
Description:   
*************************************************************************/

options nofmterr noxwait  missing='';
/*****/options mprint mlogic symbolgen;
options formchar="|----|+|---+=|-/\<>*";
options varlenchk=nowarn;

proc datasets lib=work memtype=data nolist kill; 
quit;

%let PROTOCOL=150-201;
ods escapechar="^";

%let default_fontsize=9;
%let RSLTPATH=C:\SASData\JZP-150\150-201\stat\csr_dryrun1\results;

data _null_;
   call symputx('mypgmname',scan("%sysget(SAS_EXECFILENAME)",1,'.'));
run;
%put &mypgmname;

*-----------------------------------------------------------------;

*TITLE AND FOOTNOTES
*-----------------------------------------------------------------;
%JM_TF (jm_infile=C:\SASData\JZP-150\150-201\stat\csr_dryrun1\statdoc\sap, JM_PROG_NAME= &mypgmname.,
	JM_PRODUCE_STATEMENTS=Y);

*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;

*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;

****************************************************;
* read in adam.adqs dataset *;
****************************************************;
ods listing close;
ods graphics off;
%macro trt(n=,grp=);
proc sql;
 create table grp&n._cnt as select &grp,&n as grp,trt01an,count(usubjid) as count from adam.adsl where mfasfl="Y" and &grp ne "" group by trt01an,&grp order by grp,&grp;
 quit;
 proc transpose data=grp&n._cnt out=grp&n._cnt_ prefix=trtn;
 by grp &grp;
 var count;
 id trt01an;
 run;
 %mend;
%trt(n=1,grp=SSNRIS);
%trt(n=2,grp=agegr1);
%trt(n=3,grp=agegr2);
%trt(n=4,grp=sex);
%trt(n=6,grp=VISITTYP);

proc sql;
   create table caps as 
       select usubjid,trta,trtan,sex,SSNRIS,SSNRISN,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.adqs where paramcd="PGI0101" and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y" 
       order by trtan,SSNRIS,paramcd;
 quit;

data caps;
set caps;
if avisitn=12 then wk12=1 ; 
else wk12=0;
  if SSNRIS="Presence" then SSNRISN1=1;
  else if SSNRIS="Absence" then SSNRISN1=0;
run;

 proc sql noprint;
   select count(distinct usubjid) into:nsub1 from caps where SSNRIS="Presence";;
   select count(distinct usubjid) into:nsub2 from caps where SSNRIS="Absence";
quit;


/* decimal places and format as per parameter*/
proc sql;
  create table pr as 
    select distinct paramcd,max(length(avalc)) as maxlen,max(ifn(index(avalc,".")=0,0,length(scan(avalc,2,".")))) as maxdec 
    from caps 
  group by paramcd;
quit;

data fmt;
set pr;
  length  mnft rngft sdft $5;
  mnft=cats(put(maxlen+4,2.),'.',put(maxdec+1,2.));
  qft=cats(put(maxlen+4,2.),'.',put(maxdec+1,2.));
  rngft=cats(put(maxlen+2,2.),'.',put(maxdec,4.));
  sdft=cats(put(maxlen+4,2.),'.',put(maxdec+2,2.));
run;

 data caps_nchg;
 set caps;
   if chg ne .;
 run;

 
data caps_nchg_1 caps_nchg_2;
set caps_nchg;
if trtan in (1,3) then output caps_nchg_1;
if trtan in (2,3) then output caps_nchg_2;
run;

data caps_nchg_1;
set caps_nchg_1;
if trtan=3 then trtan=0;
run;
data caps_nchg_2;
set caps_nchg_2;
if trtan=3 then trtan=0;
if trtan=2 then trtan=1;
run;


ods trace on;
ods output contrasts=contrst1;
ods output estimates=estimates1;
proc mixed data=caps_nchg_1;
class usubjid avisit ;
model chg=base trtan wk12  SSNRISN1 base*wk12 SSNRISN1*trtan trtan*wk12 SSNRISN1*wk12 SSNRISN1*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "Presence ACT-PBO    Week 4" trtan 1 SSNRISN1*trtan 1/cl alpha=0.05;
estimate "Absence ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "Presence ACT-PBO  Week 12" trtan 1 trtan*wk12 1 SSNRISN1*trtan 1 SSNRISN1*trtan*wk12 1/cl alpha=0.05;
estimate "Absence ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" SSNRISN1*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" SSNRISN1*trtan 1 SSNRISN1*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;

data contrst1(keep=label ProbF trtan);
set contrst1;
if label in ("Treatment*Week 12*Subgroup Interaction");
trtan=1;
run;



data estimates1(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates1;
if label in ("Presence ACT-PBO  Week 12","Absence ACT-PBO Week 12");
trtan=1;
run;
ods trace on;
ods output contrasts=contrst2;
ods output estimates=estimates2;
proc mixed data=caps_nchg_2;
class usubjid avisit ;
model chg=base trtan wk12  SSNRISN1 base*wk12 SSNRISN1*trtan trtan*wk12 SSNRISN1*wk12 SSNRISN1*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "Presence ACT-PBO    Week 4" trtan 1 SSNRISN1*trtan 1/cl alpha=0.05;
estimate "Absence ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "Presence ACT-PBO  Week 12" trtan 1 trtan*wk12 1 SSNRISN1*trtan 1 SSNRISN1*trtan*wk12 1/cl alpha=0.05;
estimate "Absence ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" SSNRISN1*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" SSNRISN1*trtan 1 SSNRISN1*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;
data contrst2(keep=label ProbF trtan);
set contrst2;
if label="Treatment*Week 12*Subgroup Interaction";
trtan=2;
run;
data estimates2(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates2;
if label in ("Presence ACT-PBO  Week 12","Absence ACT-PBO Week 12");
trtan=2;
run;


data contrasts;
set contrst2 contrst1;
 paramcd="PGI0101";
run;

data contrasts_1;
set contrasts;
SSNRIS="Presence";
run;
data contrasts_2;
set contrasts;
SSNRIS="Absence" ;
run;

data contrasts_f;
set contrasts_1 contrasts_2;
run;

 proc sort data=contrasts_f;
 by SSNRIS paramcd ;
 run;

proc transpose data=contrasts_f out=contrasts_f_ prefix=trtn;
 by SSNRIS paramcd ;
 var probf;
 id trtan;
run;  
data estimates(keep=SSNRIS paramcd trtan Estimate Lower Upper);
set estimates2 estimates1;
 paramcd="PGI0101";
 SSNRIS=strip(scan(label,1,""));
run;
proc sort data=estimates;
by SSNRIS paramcd  ;
run;

proc transpose data=estimates out=estimates_1 prefix=trtn;
 by SSNRIS paramcd  ;
 var  Estimate Lower Upper ;
 id trtan;
run;

data estimates_1_a estimates_1_b estimates_1_c;
set estimates_1;
if _name_="Estimate" then output estimates_1_a;
if _name_="Lower" then output estimates_1_b;
if _name_="Upper" then output estimates_1_c;
run;



proc sql;
  create table final_ssnris_grp1 as select a.SSNRIS,a.paramcd,a.trtn1 as interact_trtn1,a.trtn2 as interact_trtn2,
    b.trtn1 as est_trtn1,b.trtn2 as est_trtn2,
    c.trtn1 as lo_trtn1,c.trtn2 as lo_trtn2,
    d.trtn1 as up_trtn1,d.trtn2 as up_trtn2, 1 as grp 
    from contrasts_f_ as a left join estimates_1_a as b on a.SSNRIS=b.SSNRIS
	left join estimates_1_b as c on a.SSNRIS=c.SSNRIS
	left join estimates_1_c as d on a.SSNRIS=d.SSNRIS;
quit;


/*agegr1*/


proc sql;
   create table caps_agegr1 as 
       select usubjid,trta,trtan,AGEGR1,SSNRIS,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.adqs where paramcd="PGI0101" and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y" 
       order by trtan,AGEGR1,paramcd;
 quit;

data caps_agegr1;
set caps_agegr1;
if avisitn=12 then wk12=1 ; 
else wk12=0;
  if AGEGR1="<=65 years" then AGEGR1n=1;
  else if AGEGR1=">65 years" then AGEGR1n=0;
    if SSNRIS="Presence" then SSNRISN=1;
  else if SSNRIS="Absence" then SSNRISN=0;
run;

 proc sql noprint;
   select count(distinct usubjid) into:nsub1 from caps_agegr1 where AGEGR1="<=65 years";
   select count(distinct usubjid) into:nsub2 from caps_agegr1 where AGEGR1=">65 years";
quit;

 data caps_nchg;
 set caps_agegr1;
   if chg ne .;
 run;

 
data caps_nchg_1 caps_nchg_2;
set caps_nchg;
if trtan in (1,3) then output caps_nchg_1;
if trtan in (2,3) then output caps_nchg_2;
run;

data caps_nchg_1;
set caps_nchg_1;
if trtan=3 then trtan=0;
run;
data caps_nchg_2;
set caps_nchg_2;
if trtan=3 then trtan=0;
if trtan=2 then trtan=1;
run;


ods trace on;
ods output contrasts=contrst1;
ods output estimates=estimates1;
proc mixed data=caps_nchg_1;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn AGEGR1n base*wk12 AGEGR1n*trtan trtan*wk12 AGEGR1n*wk12 AGEGR1n*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "<=65 years ACT-PBO    Week 4" trtan 1 AGEGR1n*trtan 1/cl alpha=0.05;
estimate ">65 years ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "<=65 years ACT-PBO  Week 12" trtan 1 trtan*wk12 1 AGEGR1n*trtan 1 AGEGR1n*trtan*wk12 1/cl alpha=0.05;
estimate ">65 years ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" AGEGR1n*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" AGEGR1n*trtan 1 AGEGR1n*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;

data contrst1(keep=label ProbF trtan);
set contrst1;
if label in ("Treatment*Week 12*Subgroup Interaction");
trtan=1;
run;




data estimates1(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates1;
if label in ("<=65 years ACT-PBO  Week 12",">65 years ACT-PBO Week 12");
trtan=1;
run;
ods trace on;
ods output contrasts=contrst2;
ods output estimates=estimates2;
proc mixed data=caps_nchg_2;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn AGEGR1n base*wk12 AGEGR1n*trtan trtan*wk12 AGEGR1n*wk12 AGEGR1n*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "<=65 years ACT-PBO    Week 4" trtan 1 AGEGR1n*trtan 1/cl alpha=0.05;
estimate ">65 years ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "<=65 years ACT-PBO  Week 12" trtan 1 trtan*wk12 1 AGEGR1n*trtan 1 AGEGR1n*trtan*wk12 1/cl alpha=0.05;
estimate ">65 years ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" AGEGR1n*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" AGEGR1n*trtan 1 AGEGR1n*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;
data contrst2(keep=label ProbF trtan);
set contrst2;
if label="Treatment*Week 12*Subgroup Interaction";
trtan=2;
run;
data estimates2(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates2;
if label in ("<=65 years ACT-PBO  Week 12",">65 years ACT-PBO Week 12");
trtan=2;
run;


data contrasts;
set contrst2 contrst1;
 paramcd="PGI0101";
run;
data contrasts_1;
set contrasts;
agegr1="<=65 years";
run;
data contrasts_2;
set contrasts;
agegr1=">65 years" ;
run;

data contrasts_f;
set contrasts_1 contrasts_2;
run;

proc sort data=contrasts_f;
 by agegr1 paramcd ;
 run;

proc transpose data=contrasts_f out=contrasts_f_ prefix=trtn;
 by agegr1 paramcd ;
 var probf;
 id trtan;
run;  
data estimates(keep=agegr1 paramcd trtan Estimate Lower Upper);;
set estimates2 estimates1;
 paramcd="PGI0101";
 agegr1=strip(scan(label,1,""))||" "||strip(scan(label,2,""));
run;


proc sort data=estimates;
by agegr1 paramcd  ;
run;

proc transpose data=estimates out=estimates_1 prefix=trtn;
 by agegr1 paramcd  ;
 var  Estimate Lower Upper ;
 id trtan;
run;

data estimates_1_a estimates_1_b estimates_1_c;
set estimates_1;
if _name_="Estimate" then output estimates_1_a;
if _name_="Lower" then output estimates_1_b;
if _name_="Upper" then output estimates_1_c;
run;


proc sql;
  create table final_agegr1_grp2 as select a.agegr1,a.paramcd,a.trtn1 as interact_trtn1,a.trtn2 as interact_trtn2,
    b.trtn1 as est_trtn1,b.trtn2 as est_trtn2,
    c.trtn1 as lo_trtn1,c.trtn2 as lo_trtn2,
    d.trtn1 as up_trtn1,d.trtn2 as up_trtn2, 2 as grp 
    from contrasts_f_ as a left join estimates_1_a as b on a.agegr1=b.agegr1
	left join estimates_1_b as c on a.agegr1=c.agegr1
	left join estimates_1_c as d on a.agegr1=d.agegr1;
quit;

/*agegr2*/



proc sql;
   create table caps_agegr2 as 
       select usubjid,trta,trtan,agegr2,SSNRIS,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.adqs where paramcd="PGI0101" and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y" 
       order by trtan,agegr2,paramcd;
 quit;

data caps_agegr2;
set caps_agegr2;
if avisitn=12 then wk12=1 ; 
else wk12=0;
  if agegr2="<=45 years" then agegr2n=1;
  else if agegr2=">45 years" then agegr2n=0;
    if SSNRIS="Presence" then SSNRISN=1;
  else if SSNRIS="Absence" then SSNRISN=0;
run;

 proc sql noprint;
   select count(distinct usubjid) into:nsub1 from caps_agegr2 where agegr2="<=45 years";
   select count(distinct usubjid) into:nsub2 from caps_agegr2 where agegr2=">45 years";
quit;

 data caps_nchg;
 set caps_agegr2;
   if chg ne .;
 run;

 
data caps_nchg_1 caps_nchg_2;
set caps_nchg;
if trtan in (1,3) then output caps_nchg_1;
if trtan in (2,3) then output caps_nchg_2;
run;

data caps_nchg_1;
set caps_nchg_1;
if trtan=3 then trtan=0;
run;
data caps_nchg_2;
set caps_nchg_2;
if trtan=3 then trtan=0;
if trtan=2 then trtan=1;
run;


ods trace on;
ods output contrasts=contrst1;
ods output estimates=estimates1;
proc mixed data=caps_nchg_1;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn agegr2n base*wk12 agegr2n*trtan trtan*wk12 agegr2n*wk12 agegr2n*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "<=45 years ACT-PBO    Week 4" trtan 1 agegr2n*trtan 1/cl alpha=0.05;
estimate ">45 years ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "<=45 years ACT-PBO  Week 12" trtan 1 trtan*wk12 1 agegr2n*trtan 1 agegr2n*trtan*wk12 1/cl alpha=0.05;
estimate ">45 years ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" agegr2n*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" agegr2n*trtan 1 agegr2n*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;

data contrst1(keep=label ProbF trtan);
set contrst1;
if label in ("Treatment*Week 12*Subgroup Interaction");
trtan=1;
run;




data estimates1(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates1;
if label in ("<=45 years ACT-PBO  Week 12",">45 years ACT-PBO Week 12");
trtan=1;
run;
ods trace on;
ods output contrasts=contrst2;
ods output estimates=estimates2;
proc mixed data=caps_nchg_2;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn agegr2n base*wk12 agegr2n*trtan trtan*wk12 agegr2n*wk12 agegr2n*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "<=45 years ACT-PBO    Week 4" trtan 1 agegr2n*trtan 1/cl alpha=0.05;
estimate ">45 years ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "<=45 years ACT-PBO  Week 12" trtan 1 trtan*wk12 1 agegr2n*trtan 1 agegr2n*trtan*wk12 1/cl alpha=0.05;
estimate ">45 years ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" agegr2n*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" agegr2n*trtan 1 agegr2n*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;
data contrst2(keep=label ProbF trtan);
set contrst2;
if label="Treatment*Week 12*Subgroup Interaction";
trtan=2;
run;
data estimates2(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates2;
if label in ("<=45 years ACT-PBO  Week 12",">45 years ACT-PBO Week 12");
trtan=2;
run;

data contrasts;
set contrst2 contrst1;
 paramcd="PGI0101";
run;
data contrasts_1;
set contrasts;
agegr2="<=45 years";
run;
data contrasts_2;
set contrasts;
agegr2=">45 years" ;
run;

data contrasts_f;
set contrasts_1 contrasts_2;
run;

proc sort data=contrasts_f;
 by agegr2 paramcd ;
 run;

proc transpose data=contrasts_f out=contrasts_f_ prefix=trtn;
 by agegr2 paramcd ;
 var probf;
 id trtan;
run;  
data estimates(keep=agegr2 paramcd trtan Estimate Lower Upper);;
set estimates2 estimates1;
 paramcd="PGI0101";
 agegr2=strip(scan(label,1,""))||" "||strip(scan(label,2,""));
run;


proc sort data=estimates;
by agegr2 paramcd  ;
run;

proc transpose data=estimates out=estimates_1 prefix=trtn;
 by agegr2 paramcd  ;
 var  Estimate Lower Upper ;
 id trtan;
run;

data estimates_1_a estimates_1_b estimates_1_c;
set estimates_1;
if _name_="Estimate" then output estimates_1_a;
if _name_="Lower" then output estimates_1_b;
if _name_="Upper" then output estimates_1_c;
run;


proc sql;
  create table final_agegr2_grp3 as select a.agegr2,a.paramcd,a.trtn1 as interact_trtn1,a.trtn2 as interact_trtn2,
    b.trtn1 as est_trtn1,b.trtn2 as est_trtn2,
    c.trtn1 as lo_trtn1,c.trtn2 as lo_trtn2,
    d.trtn1 as up_trtn1,d.trtn2 as up_trtn2, 3 as grp 
    from contrasts_f_ as a left join estimates_1_a as b on a.agegr2=b.agegr2
	left join estimates_1_b as c on a.agegr2=c.agegr2
	left join estimates_1_c as d on a.agegr2=d.agegr2;
quit;

/*sex*/

proc sql;
   create table caps_sex as 
       select usubjid,trta,trtan,sex,SSNRIS,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.adqs where paramcd="PGI0101" and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y" 
       order by trtan,sex,paramcd;
 quit;

data caps_sex;
set caps_sex;
if avisitn=12 then wk12=1 ; 
else wk12=0;
  if sex="M" then sexn=1;
  else if sex="F" then sexn=0;
    if SSNRIS="Presence" then SSNRISN=1;
  else if SSNRIS="Absence" then SSNRISN=0;
run;

 proc sql noprint;
   select count(distinct usubjid) into:nsub1 from caps_sex where sex="M";;
   select count(distinct usubjid) into:nsub2 from caps_sex where sex="F";
quit;

 data caps_nchg;
 set caps_sex;
   if chg ne .;
 run;


 
data caps_nchg_1 caps_nchg_2;
set caps_nchg;
if trtan in (1,3) then output caps_nchg_1;
if trtan in (2,3) then output caps_nchg_2;
run;

data caps_nchg_1;
set caps_nchg_1;
if trtan=3 then trtan=0;
run;
data caps_nchg_2;
set caps_nchg_2;
if trtan=3 then trtan=0;
if trtan=2 then trtan=1;
run;


ods trace on;
ods output contrasts=contrst1;
ods output estimates=estimates1;
proc mixed data=caps_nchg_1;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn sexn base*wk12 sexn*trtan trtan*wk12 sexn*wk12 sexn*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "Male ACT-PBO    Week 4" trtan 1 sexn*trtan 1/cl alpha=0.05;
estimate "Female ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "Male ACT-PBO  Week 12" trtan 1 trtan*wk12 1 sexn*trtan 1 sexn*trtan*wk12 1/cl alpha=0.05;
estimate "Female ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" sexn*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" sexn*trtan 1 sexn*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;

data contrst1(keep=label ProbF trtan);
set contrst1;
if label in ("Treatment*Week 12*Subgroup Interaction");
trtan=1;
run;




data estimates1(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates1;
if label in ("Male ACT-PBO  Week 12","Female ACT-PBO Week 12");
trtan=1;
run;
ods trace on;
ods output contrasts=contrst2;
ods output estimates=estimates2;
proc mixed data=caps_nchg_2;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn sexn base*wk12 sexn*trtan trtan*wk12 sexn*wk12 sexn*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "Male ACT-PBO    Week 4" trtan 1 sexn*trtan 1/cl alpha=0.05;
estimate "Female ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "Male ACT-PBO  Week 12" trtan 1 trtan*wk12 1 sexn*trtan 1 sexn*trtan*wk12 1/cl alpha=0.05;
estimate "Female ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" sexn*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" sexn*trtan 1 sexn*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;
data contrst2(keep=label ProbF trtan);
set contrst2;
if label="Treatment*Week 12*Subgroup Interaction";
trtan=2;
run;
data estimates2(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates2;
if label in ("Male ACT-PBO  Week 12","Female ACT-PBO Week 12");
trtan=2;
run;


data contrasts;
set contrst2 contrst1;
 paramcd="PGI0101";
run;
data contrasts_1;
set contrasts;
sex="M";
run;
data contrasts_2;
set contrasts;
sex="F" ;
run;

data contrasts_f;
set contrasts_1 contrasts_2;
run;

proc sort data=contrasts_f;
 by sex paramcd ;
 run;

proc transpose data=contrasts_f out=contrasts_f_ prefix=trtn;
 by sex paramcd ;
 var ProbF;
 id trtan;
run;  
data estimates(keep=sex paramcd trtan Estimate Lower Upper);;
set estimates2 estimates1;
 paramcd="PGI0101";
 sex=strip(substr(label,1,1));
run;


proc sort data=estimates;
by sex paramcd  ;
run;

proc transpose data=estimates out=estimates_1 prefix=trtn;
 by sex paramcd  ;
 var  Estimate Lower Upper ;
 id trtan;
run;
data estimates_1_a estimates_1_b estimates_1_c;
set estimates_1;
if _name_="Estimate" then output estimates_1_a;
if _name_="Lower" then output estimates_1_b;
if _name_="Upper" then output estimates_1_c;
run;




proc sql;
  create table final_sex_grp4 as select a.sex,a.paramcd,a.trtn1 as interact_trtn1,a.trtn2 as interact_trtn2,
    b.trtn1 as est_trtn1,b.trtn2 as est_trtn2,
    c.trtn1 as lo_trtn1,c.trtn2 as lo_trtn2,
    d.trtn1 as up_trtn1,d.trtn2 as up_trtn2, 4 as grp 
    from contrasts_f_ as a left join estimates_1_a as b on a.sex=b.sex
	left join estimates_1_b as c on a.sex=c.sex
	left join estimates_1_c as d on a.sex=d.sex;
quit;


/*visit type*/


proc sql;
   create table caps_visittyp as 
       select usubjid,trta,trtan,VISITTYP,SSNRIS,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.adqs where paramcd="PGI0101" and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y"  and VISITTYP ne ""
       order by trtan,VISITTYP,paramcd;
 quit;

data caps_visittyp;
set caps_visittyp;
if avisitn=12 then wk12=1 ; 
else wk12=0;
  if VISITTYP="On-site" then VISITTYPn=1;
  else if VISITTYP="Remote" then VISITTYPn=0;
    if SSNRIS="Presence" then SSNRISN=1;
  else if SSNRIS="Absence" then SSNRISN=0;
run;

 proc sql noprint;
   select count(distinct usubjid) into:nsub1 from caps_visittyp where VISITTYP="On-site";
   select count(distinct usubjid) into:nsub2 from caps_visittyp where VISITTYP="Remote";
quit;

 data caps_nchg;
 set caps_visittyp;
   if chg ne .;
 run;

data caps_nchg_1 caps_nchg_2;
set caps_nchg;
if trtan in (1,3) then output caps_nchg_1;
if trtan in (2,3) then output caps_nchg_2;
run;

data caps_nchg_1;
set caps_nchg_1;
if trtan=3 then trtan=0;
run;
data caps_nchg_2;
set caps_nchg_2;
if trtan=3 then trtan=0;
if trtan=2 then trtan=1;
run;


ods trace on;
ods output contrasts=contrst1;
ods output estimates=estimates1;
proc mixed data=caps_nchg_1;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn VISITTYPn base*wk12 VISITTYPn*trtan trtan*wk12 VISITTYPn*wk12 VISITTYPn*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "On-site ACT-PBO    Week 4" trtan 1 VISITTYPn*trtan 1/cl alpha=0.05;
estimate "Remote ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "On-site ACT-PBO  Week 12" trtan 1 trtan*wk12 1 VISITTYPn*trtan 1 VISITTYPn*trtan*wk12 1/cl alpha=0.05;
estimate "Remote ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" VISITTYPn*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" VISITTYPn*trtan 1 VISITTYPn*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;

data contrst1(keep=label ProbF trtan);
set contrst1;
if label in ("Treatment*Week 12*Subgroup Interaction");
trtan=1;
run;




data estimates1(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates1;
if label in ("On-site ACT-PBO  Week 12","Remote ACT-PBO Week 12");
trtan=1;
run;
ods trace on;
ods output contrasts=contrst2;
ods output estimates=estimates2;
proc mixed data=caps_nchg_2;
class usubjid avisit SSNRISn;
model chg=base trtan wk12  SSNRISn VISITTYPn base*wk12 VISITTYPn*trtan trtan*wk12 VISITTYPn*wk12 VISITTYPn*trtan*wk12/ddfm=kr residual outp=residual;
repeated avisit/type=un sub=usubjid;/*unstructured covariance*/
estimate "On-site ACT-PBO    Week 4" trtan 1 VISITTYPn*trtan 1/cl alpha=0.05;
estimate "Remote ACT-PBO  Week 4" trtan 1/cl alpha=0.05;
estimate "On-site ACT-PBO  Week 12" trtan 1 trtan*wk12 1 VISITTYPn*trtan 1 VISITTYPn*trtan*wk12 1/cl alpha=0.05;
estimate "Remote ACT-PBO Week 12" trtan 1 trtan*wk12 1/cl alpha=0.05;
contrast "Treatment*Week 4*Subgroup Interaction" VISITTYPn*trtan 1;
contrast "Treatment*Week 12*Subgroup Interaction" VISITTYPn*trtan 1 VISITTYPn*trtan*wk12 1;
run; *this part will generate lsmeans differences;
ods trace off;
data contrst2(keep=label ProbF trtan);
set contrst2;
if label="Treatment*Week 12*Subgroup Interaction";
trtan=2;
run;
data estimates2(keep=label TRTAN Estimate StdErr Probt Lower upper);
set estimates2;
if label in ("On-site ACT-PBO  Week 12","Remote ACT-PBO Week 12");
trtan=2;
run;


data contrasts;
set contrst2 contrst1;
 paramcd="PGI0101";
run;
data contrasts_1;
set contrasts;
VISITTYP="On-site";
run;
data contrasts_2;
set contrasts;
VISITTYP="Remote" ;
run;

data contrasts_f;
set contrasts_1 contrasts_2;
run;

proc sort data=contrasts_f;
 by VISITTYP paramcd ;
 run;

proc transpose data=contrasts_f out=contrasts_f_ prefix=trtn;
 by VISITTYP paramcd ;
 var ProbF;
 id trtan;
run;  
data estimates(keep=VISITTYP paramcd trtan Estimate Lower Upper);;
set estimates2 estimates1;
 paramcd="PGI0101";
 VISITTYP=strip(scan(label,1,""));

run;

proc sort data=estimates;
by VISITTYP paramcd  ;
run;

proc transpose data=estimates out=estimates_1 prefix=trtn;
 by VISITTYP paramcd  ;
 var  Estimate Lower Upper ;
 id trtan;
run;
data estimates_1_a estimates_1_b estimates_1_c;
set estimates_1;
if _name_="Estimate" then output estimates_1_a;
if _name_="Lower" then output estimates_1_b;
if _name_="Upper" then output estimates_1_c;
run;




proc sql;
  create table final_VISITTYP_grp6 as select a.VISITTYP,a.paramcd,a.trtn1 as interact_trtn1,a.trtn2 as interact_trtn2,
    b.trtn1 as est_trtn1,b.trtn2 as est_trtn2,
    c.trtn1 as lo_trtn1,c.trtn2 as lo_trtn2,
    d.trtn1 as up_trtn1,d.trtn2 as up_trtn2, 6 as grp 
    from contrasts_f_ as a left join estimates_1_a as b on a.VISITTYP=b.VISITTYP
	left join estimates_1_b as c on a.VISITTYP=c.VISITTYP
	left join estimates_1_c as d on a.VISITTYP=d.VISITTYP;
quit;



data all(drop=SSNRIS VISITTYP sex agegr1 agegr2  );
set final_SSNRIS_grp1 final_VISITTYP_grp6 final_sex_grp4 final_agegr1_grp2 final_agegr2_grp3 ;
sp="";
grp_=catx(sp, of SSNRIS VISITTYP sex agegr1 agegr2);
run;


data allcnt(drop=SSNRIS VISITTYP sex agegr1 agegr2  );
set grp1_cnt_ grp2_cnt_ grp3_cnt_ grp4_cnt_ grp6_cnt_;
sp="";
grp_=catx(sp, of SSNRIS VISITTYP sex agegr1 agegr2);
run;

proc sql;
   create table final as select a.*,b.trtn1 as n_trtn1,b.trtn2 as n_trtn2,b.trtn3 as n_trtn3 from all as a left join allcnt as b on a.grp=b.grp and a.grp_=b.grp_;
quit;
* Create Headers;
proc sql noprint;
    create table headers (cat_label char(200), grp num);
    insert into headers
        values("Randomization strata", 1)
        values("Age Group 1", 2)
        values("Age Group 2", 3)
        values("Gender", 4)
		values("Visit during COVID-19", 6)
    ;
quit;

proc sql;
  create table final_ as select a.*,b.cat_label from final as a left join headers as b on a.grp=b.grp;
  quit;

proc format;

	invalue ord
        "Presence" = 1
        "Absence" = 2
		"<=65 years" = 3 
		">65 years" = 4
		"<=45 years" = 5 
		">45 years" = 6
        "M" = 7
        "F" = 8
		"On-site" = 9 
		"Remote" = 10
	;
run;
data frrpt;
    set headers (in=inhead) final_(in=instack);
	subgrpn=input(grp_,ord.);
	run;


	proc sort data=frrpt;
	by grp subgrpn;
	run;



data frrpt_;
set frrpt;
length lsdiff_trtn1 lsdiff_trtn2 $20 parameter $50;
if n_trtn1 ne . then n_trtn1_=put(n_trtn1,4.);
if n_trtn2 ne . then n_trtn2_=put(n_trtn2,4.);
if n_trtn3 ne . then n_trtn3_=put(n_trtn3,4.);
if nmiss(est_trtn1,lo_trtn1,up_trtn1)=0 then lsdiff_trtn1=strip(put(est_trtn1,6.1))||" ("||strip(put(lo_trtn1,6.1))||","||strip(put(up_trtn1,6.1))||")";
if nmiss(est_trtn2,lo_trtn2,up_trtn2)=0 then lsdiff_trtn2=strip(put(est_trtn2,6.1))||" ("||strip(put(lo_trtn2,6.1))||","||strip(put(up_trtn2,6.1))||")";
if interact_trtn1 ne .   then interact_trtn1_=strip(put(interact_trtn1,PVALUE6.4));
if interact_trtn2 ne .   then interact_trtn2_=strip(put(interact_trtn2,PVALUE6.4));

est_trtn1n=input(put(est_trtn1,6.1),6.1);
est_trtn2n=input(put(est_trtn2,6.1),6.1);

lo_trtn1n=input(put(lo_trtn1,6.1),6.1);
lo_trtn2n=input(put(lo_trtn2,6.1),6.1);

up_trtn1n=input(put(up_trtn1,6.1),6.1);
up_trtn2n=input(put(up_trtn2,6.1),6.1);

if grp_="M" then grp_="Male";
if grp_="F" then grp_="Female";
parameter=cat_label;
if grp_ ne "" then parameter='a0'x||'a0'x||'a0'x||'a0'x||strip(grp_);
run;


proc sort data=frrpt_;
by grp subgrpn;
run;
data frrpt_a(keep=interact_trtn1_ lsdiff_trtn1 grp grp_ n_trtn1_ n_trtn3_ cat_label subgrpn parameter est_trtn1n lo_trtn1n up_trtn1n interact_trtn1) 
frrpt_b(keep=interact_trtn2_ lsdiff_trtn2 grp grp_ n_trtn2_ n_trtn3_ cat_label subgrpn parameter est_trtn2n lo_trtn2n up_trtn2n interact_trtn2) ;
set frrpt_;
run;

****************************************************;
* define plot template *;
****************************************************;
proc template;
define statgraph forest1;
    begingraph / designwidth=1100 designheight=500 border=false;

	layout lattice / columns=6   rowdatarange=union;

		 /* column headers */ 
		sidebar / align=top; 
		layout lattice / rows=1 columns=6 ;
			entry " ";
			entry " ";
			entry textattrs=(family='Courier New' size=8) halign=left "Placebo";
			entry textattrs=(family='Courier New' size=8) halign=left "0.3 mg";
            entry textattrs=(family='Courier New' size=8) halign=left "LS Mean Difference";
            entry textattrs=(family='Courier New' size=8) halign=left "Interaction";
			endlayout;
		endsidebar;

		/* first column (subgroups) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=parameter / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ';
		endlayout;

		/*second column (high/low plot) */



		layout overlay / walldisplay=none  
			xaxisopts=(type=linear labelattrs=(family='Courier New' size=8) 
			label=" " linearopts=(thresholdmin=1 thresholdmax=1) )

			yaxisopts=(reverse=true display=none);
				     ;


			referenceline x=0 / lineattrs=(pattern=solid);

			highlowplot low=lo_trtn1n high=up_trtn1n y=parameter / group=parameter lineattrs=(pattern=solid color=black);
        	scatterplot x=est_trtn1n y=parameter / group=parameter markerattrs=(symbol=circlefilled color=black);
		endlayout;

		/* third column (placebo counts) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=n_trtn3_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='n' titleattrs=(family='Courier New' size=8);
		endlayout;

		/* fourth column (JZP-150-0.3mg counts) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=n_trtn1_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='n' titleattrs=(family='Courier New' size=8);
		endlayout;

		/* fifth column (95% CI) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=lsdiff_trtn1 / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='(95% CI)' titleattrs=(family='Courier New' size=8)
				titlejustify=center;
		endlayout;

			/* Interaction p-term value */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=interact_trtn1_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='term p-value at Week 12' titleattrs=(family='Courier New' size=8)
				titlejustify=left;
		endlayout;
	
		 entryfootnote halign=left textattrs=(family='Courier New' size=8)
			"                                ";
	endlayout;
    endgraph;
    end;
run;

proc template;
define statgraph forest2;
    begingraph / designwidth=1100 designheight=500 border=false;

	layout lattice / columns=6   rowdatarange=union;

		 /* column headers */ 
		sidebar / align=top; 
		layout lattice / rows=1 columns=6 ;
			entry " ";
			entry " ";
			entry textattrs=(family='Courier New' size=8) halign=left "Placebo";
			entry textattrs=(family='Courier New' size=8) halign=left "4 mg";
            entry textattrs=(family='Courier New' size=8) halign=left "LS Mean Difference";
            entry textattrs=(family='Courier New' size=8) halign=left "Interaction";
			endlayout;
		endsidebar;

		/* first column (subgroups) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=parameter / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ';
		endlayout;

		/*second column (high/low plot) */


		layout overlay / walldisplay=none  
			xaxisopts=(type=linear labelattrs=(family='Courier New' size=8) 
			label=" " linearopts=(thresholdmin=1 thresholdmax=1) )

			yaxisopts=(reverse=true display=none);
				     ;


			referenceline x=0 / lineattrs=(pattern=solid);

			highlowplot low=lo_trtn2n high=up_trtn2n y=parameter / group=parameter lineattrs=(pattern=solid color=black);
        	scatterplot x=est_trtn2n y=parameter / group=parameter markerattrs=(symbol=circlefilled color=black);
		endlayout;

		/* third column (placebo counts) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=n_trtn3_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='n' titleattrs=(family='Courier New' size=8);
		endlayout;

		/* fourth column (JZP-150-0.3mg counts) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=n_trtn2_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='n' titleattrs=(family='Courier New' size=8);
		endlayout;

		/* fifth column (95% CI) */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=lsdiff_trtn2 / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='(95% CI)' titleattrs=(family='Courier New' size=8)
				titlejustify=center;
		endlayout;

			/* Interaction p-term value */
		layout overlay / walldisplay=none xaxisopts=(display=none)
			yaxisopts=(reverse=true display=none tickvalueattrs=(weight=bold));
			axistable y=parameter value=interact_trtn2_ / display=(values) labelattrs=(family='Courier New' size=8) 
				indentweight=indent textgroup=textid label=' ' title='term p-value at Week 12' titleattrs=(family='Courier New' size=8)
				titlejustify=left;
		endlayout;
	
		 entryfootnote halign=left textattrs=(family='Courier New' size=8)
			"                                ";
	endlayout;
    endgraph;
    end;
run;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
ods escapechar "^" noproctitle;
ods rtf nogtitle nogfootnote ; 
goptions reset=symbol ftext="Courier New" gsfmode=replace 
	noborder hsize=10in vsize=4.95in ;
ods output sgrender=stat1;
proc sgrender data=frrpt_a template=forest1 ;
run;quit;
ods output sgrender=stat2;
proc sgrender data=frrpt_b template=forest2 ;
run;quit;
*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;
ods listing; 


data data tlfdata.&mypgmname.(keep=parameter lsdiff_trtn1 lsdiff_trtn2 interact_trtn1 interact_trtn2 n_trtn1_ n_trtn2_ n_trtn3_);
set frrpt_;
run;

