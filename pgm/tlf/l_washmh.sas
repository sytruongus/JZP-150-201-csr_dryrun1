
/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Akumar
* DATE CREATED:   	04OCT2022
* PROGRAM NAME:   	l-ae
* DESCRIPTION:    	Creating Adverse Events listing
* DATA SETS USED: 	adsl adcm 
***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer:    
Date:          
Description:   
*************************************************************************/
options missing ='' MPRINT NONUMBER validvarname = upcase fmtsearch=(work); 
%let sepvar=/^n;

*-----------------------------------------------------------------;
*TITLE AND FOOTNOTES
*-----------------------------------------------------------------;
 %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

%let output=&valoutnm;


*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;

*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%let default_fontsize = 9;
%JM_TEMPLATES;

*-----------------------------------------------------------------;
*Body of table;
*-----------------------------------------------------------------;
proc sort data=adam.adcm out=adcm(drop=trtedt);
	by usubjid;
	where saffl ='Y' and MEDWOFL="Y";
run;

proc sort data=adam.adsl out=adsl(keep=usubjid trtedt EOTSTT SSNRISN SSNRIS);
    by usubjid;
	where saffl ='Y';
run;

data cm;
	length  var1 var2 var3 var5  var7 var8 var9 $300 var4 var10 $600  block aeout $200 ;
	merge adsl(in=a) adcm(in=b);
	by usubjid;
	if a and b;

    var1=strip(SSNRIS);

	var2=compress(trt01a,"Dummy Treatment");

   
    if missing(CMATC4)  then CMATC4 = "NOT CODED ATC level 4";
    if missing( CMtrt) then CMtrt="Not Reported Drug Name";
    if missing(CMdecod)  then CMDECOD="NOT CODED CMDECOD";

	var3=strip(CMTRT)||"/ ^n"||strip(CMdecod)||"/ ^n"||strip(CMATC4);

	** derive AE start and end days ;

if ASTDT ne . then var4=strip(put(ASTDT,yymmdd10.))|| "^n(" || strip(put(astdy,8.))|| ")";

if AENDT ne . then var5=strip(put(AENDT,yymmdd10.))|| "^n(" || strip(put(aendy,8.))|| ")";
else if missing(aendt) and 	AEENRF="ONGOING" then  var5 = strip(var5) || "ONGOING";

*VAR6="";

if cmiss(cmdose,cmdosu) eq 0 then var7=strip(put(cmdose,best.))||' ('||strip(cmdosu)||')';
if cmiss(cmdosfrq,cmroute) eq 0 then var8=strip(cmdosfrq)||'/^n'||strip(cmroute);

var9=strip(cmindc);
VAR10=CATX("/", OF CMINDC2-CMINDC5);
	
	block=catx("-",usubjid, cmseq);

	label
	subjidl="Participant ID/|Age/Sex/Race"
	var1="Randomization Stratum"
	var2='Treatment Group'
	var3= 'Reported Drug Name/|Preferred Drug Term/|ATC (Level 4) Class' 
	var4= 'Start Date|(Study Day)'
	var5= 'End Date|(Study Day)'
	/*var6='Study Week|of Use|Medication'*/
	var7='Dose|(Units)'
	var8='Frequency/|Route'
	var9='Indication' 
	Var10='Specify|Term'
	
;
	keep usubjid subjidl var: block SSNRISN SSNRIS TRTA trt01: cmseq TRTSDT TRT01A TRT01AN SUBJID AGERASEX;  
run;

proc sort data =  CM;
	by SSNRISN var1 TRT01AN  SUBJIDL  CMseq ;
run;
data CM;
	set CM;
		by SSNRISN var1 TRT01AN  SUBJIDL  CMseq ;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=CM, JM_INDSN2=, JM_BREAKCNT=3, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRISN var1 TRT01AN  SUBJIDL  CMseq ;
run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
	by pageno SSNRISN var1 TRT01AN  SUBJIDL  CMseq ;

	if SUBJIDL="" then delete;

	if not first.subjidl then do;
		subjidl='';
		var1='';		
	end;
    sp0='';
	sp1='';
	sp2='';
	sp3='';sp4='';sp5='';
	label sp0='|'; label sp1='|';label sp2='|';label sp3='|';label sp4='|';label sp5='|';;
run;


proc sql;
 create table dummy as
 select * from jm_aval_allreport
 where usubjid ne '';
quit;
%let myobs=&sqlobs.;


options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

options nobyline;
	title%eval(&lasttitlenum.+2) j=l "Randomization stratum: #BYVAL(SSNRIS)";
	title%eval(&lasttitlenum.+3) j=l "Treatment Group: #BYVAL(trta)";

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;
%if &myobs. gt 0 %then %do;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR= SUBJIDL var3 var4 var5  var7 var8 var9 var10 
,JM_CELLWIDTH= 1.2   2.0  0.9  0.9    0.9  0.9  1.1   1.1
,JM_BYVAR= SSNRIS trta
,JM_BREAKVAR=
,JM_REPTYPE=Listing

);
%end;
%else %do;
%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  jm_aval_label
,JM_CELLWIDTH= 0.9
,JM_BYVAR= 
,JM_BREAKVAR=
,JM_REPTYPE=Listing
);
%end;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;

data tlfdata.&output.;
	set temp_output;
	keep var: SSNRIS trta	PAGENO	_PAGE	_BOTTOM_LINE_;
run;
