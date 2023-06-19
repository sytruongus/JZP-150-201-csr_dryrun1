
/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Akumar
* DATE CREATED:   	04OCT2022
* PROGRAM NAME:   	l-ae
* DESCRIPTION:    	Creating Adverse Events listing
* DATA SETS USED: 	adsl adae 
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

data da(keep=usubjid visit dadtc datestcd DAORRES darefid dady);
	set sdtm.da;
run;

proc sort data=da out=da_disp;
	by usubjid darefid visit dadtc;
	where datestcd = "DISPAMT";
run;
proc sort data=da out=da_return;
	by usubjid darefid visit dadtc;
	where datestcd = "RETAMT";
run;

data da_list;
	merge da_disp(rename=(dadtc=disp_dadtc DAORRES=disp_DAORRES dady=disp_dady))
			da_return(rename=(dadtc=ret_dadtc DAORRES=ret_DAORRES dady=ret_dady));
	by usubjid darefid visit ;


run;

proc sort data=adam.adexsum out=adex(keep= usubjid subjid paramcd age sex race trta trtsdt trtedt avalc);
	by trta usubjid subjid age sex race  trtsdt trtedt;
	where saffl ='Y' and paramcd in ("HAVTAKEN" "COMPL");
run;

proc sort data=adam.adsl out=adsl(keep=usubjid SSNRIS );
    by usubjid;
	where saffl ='Y';
run;

proc transpose data=adex out=adex_t;
	by trta usubjid subjid age sex race  trtsdt trtedt;
	id paramcd;
	var avalc;
run;

proc sort data=adex_t;
	by usubjid;
run;

data ex;

	merge adsl(in=a) da_list(in=b) sdtm.ex(keep=usubjid exstdy exendy exstdtc exendtc) adex_t;
	by usubjid;
	if a and b;

		  if upcase(race) =: "WHITE" then racec = "W";
   else if upcase(race) =: "BLA" then racec = "B";
   else if upcase(race) =: "NATIVE" then racec = "N";
   else if upcase(race) = "ASIAN" then racec = "A";
   else if upcase(race) =: "AMERICAN" then racec = "I"; 
   else if upcase(race) =: "OTHER" then racec = "O";
   else if upcase(race) =: "MULTIPLE" then racec = "P";

	var1 = subjid;
	var2 = catx("/",age,sex,racec);

	IF disp_dadtc^='' THEN var3 = strip(disp_dadtc)||" ("||strip(put(disp_dady,best.))||")";
	IF ret_dadtc^='' THEN var4 = strip(ret_dadtc)||" ("||strip(put(ret_dady,best.))||")";
	IF exendtc^='' THEN var5 = strip(exendtc)||" ("||strip(put(exendy,best.))||")";
	var6 = '';
	var7 = strip(ret_DAORRES);
	var8 = strip(put((input(disp_DAORRES,best.) - input(ret_DAORRES,best.)),best.));
	if HAVTAKEN^=. then var9 = strip(put(HAVTAKEN,best.));
	if COMPL^=. then var10 = strip(put(COMPL,best.));

	

	label
	var1="Participant |ID"
	var2="Age/|Sex/|Race"
	var3="Date Bottle |Dispensed |(Study Day)"
	var4="Date Bottle |Returned |(Study Day)"
	var5="Date of |Last Dose |(Study Day)"
	var6='Bottle |ID'
	var7='Number |of |Capsules |Returned'
	var8='N of |Capsules |Taken'
	var9='N of Capsules |That Should |Have Been Taken'
	var10='Compliance |(%)'
		
;
	keep usubjid SSNRIS trta  var:;  
run;

proc sort data =  ex;
	by SSNRIS trta var1 var2 var3 var4 ;
run;
data ex;
	set ex;
	by SSNRIS trta var1 var2 var3 var4 ;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=ex, JM_INDSN2=, JM_BREAKCNT=10, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 ;
		where usubjid^='';

run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 ;

	if not first.var1 then do;
		var1='';	
		VAR2='';
var9='';
var10='';	
	end;
/*    sp0='';*/
/*	sp1='';*/
/*	sp2='';*/
/*	sp3='';sp4='';sp5='';*/
/*	label sp0='|'; label sp1='|';label sp2='|';label sp3='|';label sp4='|';label sp5='|';;*/
run;

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

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7 var8 var9 var10
,JM_CELLWIDTH= 0.75 0.75 0.75 0.75 0.75 0.75 0.75 0.75 0.75 0.75
,JM_BYVAR= SSNRIS trta
,JM_BREAKVAR= 
,JM_REPTYPE=Listing
);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;

data tlfdata.&output.;
	set temp_output;
	keep var: SSNRIS trta	PAGENO	_PAGE	_BOTTOM_LINE_;
run;
