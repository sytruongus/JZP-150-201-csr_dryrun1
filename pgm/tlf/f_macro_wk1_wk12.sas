DM "log;clear;lst;clear;";
*************************************************************************
* STUDY DRUG    :     	JZP150
* PROTOCOL NO   :       JZP150-201
* PROGRAMMER    :     	kmummalaneni
* DATE CREATED  :   	30JAN2023
* PROGRAM NAME  :       f_macro_wk1_wk12
* DESCRIPTION   :    	 
* DATA SETS USED: 		adam.adsl,adam.adqs2,adqs
***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer:  	
Date:        	
Description: 	
***************************************************************************;

%macro fig(dset=,paramcd=);
ods listing close;
proc sql;
   create table caps as 
       select usubjid,trta,trtan,SSNRISN,paramcd,ablfl,adt format=date9.,trtsdt format=date9.,aval,avalc,base,chg,avisit,avisitn,anl01fl,anl02fl,anl03fl 
       from adam.&dset where paramcd=&paramcd and .<avisitn<=12 and mfasfl="Y" and anl01fl="Y" 
       order by trtan,paramcd,avisitn;
 quit;

 data caps;
 set caps;
 if paramcd="PHQ0111" and ablfl="Y" and avisit="Screening" and avisitn=-1 then do;
 avisit="Baseline";avisitn=0;end;
 if paramcd="PHQ0111" and avisit="Week 8" then delete;
 run;


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



proc format;
 
    value visit
  1="Week 1"
  2="Week 4"
  3="Week 8"
  4="Week 12";
  	 value trt (MULTILABEL)

1="JZP150 0.3 mg"
2="JZP150 4 mg"
3="Placebo";
   ;
run;


 proc sql;
   create table vis as select distinct avisit,avisitn from caps order by avisitn;
 quit;
 data vis;
 set vis;
 ord=_n_;
 avisitn_=strip(put(avisitn,best.));
 run;

proc transpose data=vis out=avisitn prefix=vis;
var avisitn_;
id ord;
run;

data avisitn;
set avisitn;
if vis1="" then vis1="";
if vis2="" then vis2="";
if vis3="" then vis3="";
if vis4="" then vis4="";
if vis5="" then vis5="";
vis=compress("v"||strip(catx(" ",of vis1-vis5)));
run;

proc sql noprint;
   select vis into:vis from avisitn;
quit;
%put &vis.;


/*LS means*/

%macro lsin;
%if &vis=v014812 %then %do;
 data caps_w1 caps_w4 caps_w8 caps_w12;
 set caps;
   if chg ne . and avisitn=1 then output caps_w1;
   if chg ne . and avisitn<=4 then output caps_w4;
   if chg ne . and avisitn<=8 then output caps_w8;
   if chg ne . and avisitn<=12 then output caps_w12;
 run;
 %end;
%else %if &vis=v01412 %then %do;
 data caps_w1 caps_w4  caps_w12;
 set caps;
   if chg ne . and avisitn=1 then output caps_w1;
   if chg ne . and avisitn<=4 then output caps_w4;
   if chg ne . and avisitn<=12 then output caps_w12;
 run;
 %end;
%else %if &vis=v04812 %then %do;
 data  caps_w4 caps_w8 caps_w12;
 set caps;
   if chg ne . and avisitn<=4 then output caps_w4;
   if chg ne . and avisitn<=8 then output caps_w8;
   if chg ne . and avisitn<=12 then output caps_w12;
 run;
 %end;
 %if &vis=v0412 %then %do;
 data  caps_w4  caps_w12;
 set caps;
   if chg ne . and avisitn<=4 then output caps_w4;
   if chg ne . and avisitn<=12 then output caps_w12;
 run;
 %end;
%mend lsin;
%lsin;

%macro lsmean(in=,diff=,visit=,visitn=,final=);
ods trace on;
/*ods output  ClassLevels=x;*/
ods output diffs=&diff(keep=trtan _trtan avisit _avisit Estimate StdErr Probt Lower Upper);***ls means diff;
proc mixed data =&in ;
 class usubjid trtan avisit ssnrisn ;
 model chg = base trtan avisit trtan*avisit base*avisit ssnrisn ssnrisn*avisit / ddfm=kr residual outp=residual; 
 repeated avisit/type=un sub=usubjid;
 lsmeans trtan*avisit / cl diff alpha=0.05;
run;
ods trace off;

/*lsmeans */
/**/
/*data &lsmean;*/
/*set &lsmean;*/
/*length paramcd $10;*/
/* paramcd=&paramcd;*/
/* if avisit=&visit;*/
/*run;*/
/**/
/**/
/*data &lsmean._1(keep=ord paramcd trtan aest bStdErr cup ) ;*/
/* merge &lsmean(in=a) fmt(in=b);*/
/* by  paramcd;*/
/* if a and b;*/
/**/
/*   array stats(*) Estimate StdErr  Lower Upper;*/
/*   array fmts(*)  qft sdft qft qft ;*/
/*   array statsd(*) $10 aest bStdErr  cLower cUpper;*/
/**/
/* do i=1 to dim(statsd);*/
/*  statsd(i)=putn(stats(i),fmts(i));*/
/*  if statsd(i)="" then statsd(i)="NA";*/
/* end;*/
/**/
/* cup="("||strip(cLower)||","||strip(cUpper)||")";*/
/* ord=3.1;*/
/*run;*/
/**/
/**/
/*proc transpose data=&lsmean._1 out=&lsmean._2 prefix=trtn;*/
/* by paramcd ord;*/
/* var  aest bStdErr cup  ;*/
/* id trtan;*/
/*run;*/


/*ls meand diff*/

data &diff;
 set &diff;
 length paramcd $10;
 paramcd=&paramcd;
 if _trtan=3;***ls means with respect to placebo vs trt groups;
 if avisit=&visit and _avisit=&visit;
run;



data &final._diff;
set &diff;
lsmndiff=estimate;
lcl=Lower;
ucl=upper;
format lsmndiff lcl ucl  6.1 ;
avisitn=&visitn;
if avisit="Week 1" then avisitn=1;
if avisit="Week 4" then avisitn=2;
if avisit="Week 8" then avisitn=3;
if avisit="Week 12" then avisitn=4;
format avisitn visit. trtan trt.;
run;

%mend;

%macro lsmeanf;
%if &vis=v014812 %then %do;
%lsmean(in=caps_w1,diff=diffw1,visit=%str("Week 1"),visitn=1,final=fw1);
%lsmean(in=caps_w4,diff=diffw4,visit=%str("Week 4"),visitn=4,final=fw4);
%lsmean(in=caps_w8,diff=diffw8,visit=%str("Week 8"),visitn=8,final=fw8);
%lsmean(in=caps_w12,diff=diffw12,visit=%str("Week 12"),visitn=12,final=fw12);
%end;
%else %if &vis=v01412 %then %do;
%lsmean(in=caps_w1,diff=diffw1,visit=%str("Week 1"),visitn=1,final=fw1);
%lsmean(in=caps_w4,diff=diffw4,visit=%str("Week 4"),visitn=4,final=fw4);
%lsmean(in=caps_w12,diff=diffw12,visit=%str("Week 12"),visitn=12,final=fw12);
%end;
%else %if &vis=v04812 %then %do;
%lsmean(in=caps_w4,diff=diffw4,visit=%str("Week 4"),visitn=4,final=fw4);
%lsmean(in=caps_w8,diff=diffw8,visit=%str("Week 8"),visitn=8,final=fw8);
%lsmean(in=caps_w12,diff=diffw12,visit=%str("Week 12"),visitn=12,final=fw12);
%end;
%else %if &vis=v0412 %then %do;
%lsmean(in=caps_w4,diff=diffw4,visit=%str("Week 4"),visitn=4,final=fw4);
%lsmean(in=caps_w12,diff=diffw12,visit=%str("Week 12"),visitn=12,final=fw12);
%end;
%mend;
%lsmeanf;

%macro qc;
%if &vis=v014812 %then %do;
 data all;
  set fw12_diff fw1_diff fw4_diff  fw8_diff     ;***descriptive stats and lsmeans estimated mean diff;
  run;
%end;
%if &vis=v01412 %then %do;
   data all;
 set fw12_diff fw1_diff fw4_diff      ;***descriptive stats and lsmeans estimated mean diff;
  run;
  %end;
%if &vis=v04812 %then %do;
   data all;
  set   fw12_diff fw4_diff  fw8_diff     ;***descriptive stats and lsmeans estimated mean diff;
  run;
%end;
%if &vis=v0412 %then %do;
   data all;
  set   fw12_diff fw4_diff       ;***descriptive stats and lsmeans estimated mean diff;
  run;
%end;
%mend;
%qc;
%mend;

