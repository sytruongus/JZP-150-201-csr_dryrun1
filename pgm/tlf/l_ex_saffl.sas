
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
proc sort data=adam.adexsum out=adex(keep= usubjid subjid paramcd age sex race trta trtsdt trtedt avalc);
	by trta usubjid subjid age sex race  trtsdt trtedt;
	where saffl ='Y'and paramcd in ("EXPDAVG" "EXDUR");
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

	merge adsl(in=a) adex_t(in=b) sdtm.ex(keep=usubjid exstdy exendy exstdtc exendtc);
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
	var3 = strip(exstdtc)||" ("||strip(exstdy)||")";
	var4 = strip(exendtc)||" ("||strip(exendy)||")";
	var5 = EXPDAVG;
	var6 = EXDUR;

	

	label
	var1="Participant |ID"
	var2="Age/|Sex/|Race"
	var3="Date of First |Dose (Study Day)"
	var4="Date of Last |Dose (Study Day)"
	var5="Daily Dosage |(mg)"
	var6='Duration of |Exposure (Days)'
	
		
;
	keep usubjid SSNRIS trta var:;  
run;

proc sort data =  ex;
	by SSNRIS trta var1 var2 var3 var4 var5 var6;
run;
data ex;
	set ex;
	by SSNRIS trta var1 var2 var3 var4 var5 var6;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=ex, JM_INDSN2=, JM_BREAKCNT=10, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6;
		where usubjid^='';

run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6;

/*	if not first.var1 then do;*/
/*		var1='';		*/
/*	end;*/
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
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6
,JM_CELLWIDTH= 1 1 1 1 1 1
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
