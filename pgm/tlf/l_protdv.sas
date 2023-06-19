
/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Nitesh Patil
* DATE CREATED:   	18JAN2023
* PROGRAM NAME:   	l-PROTDV
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
proc sort data=adam.addv out=addv(drop=trtedt);
	by usubjid;
	where saffl ='Y' and COVFL="N";
run;

proc sort data=adam.adsl out=adsl;*(keep=usubjid trtedt EOTSTT );
    by usubjid;
	where saffl ='Y';
run;

data dv;

	merge adsl(in=a keep=usubjid SSNRIS) addv(in=b);
	by usubjid;
	if a and b;

	var1 = subjid;
		  if upcase(race) =: "WHITE" then racec = "W";
   else if upcase(race) =: "BLA" then racec = "B";
   else if upcase(race) =: "NATIVE" then racec = "N";
   else if upcase(race) = "ASIAN" then racec = "A";
   else if upcase(race) =: "AMERICAN" then racec = "I"; 
   else if upcase(race) =: "OTHER" then racec = "O";
   else if upcase(race) =: "MULTIPLE" then racec = "P";

	var2 = catx("/",age,sex,racec);
	var3 =  strip(DVSTDTC)||" ("||strip(dvstdy)||")";
	var4 = DVCAT;
	var5 = strip(DVTERM)||" "||strip(DVTERM1)||" "||strip(DVTERM2)||" "||strip(DVTERM3);

/*	var5 = catx(" ",DVTERM,DVTERM1,DVTERM2,DVTERM3);*/
	var6 = '';
	var7 = DVSCAT;

	

	label
	var1="Participant|ID"
	var2="Age/|Sex/|Race"
	var3="Date of |Deviation |(Study Day)"
	var4='Deviation |Category'
	var5= 'Description' 
	var6= 'Action'
	var7= 'Severity'
		
;
	keep usubjid var: SSNRIS trt01a;  
run;

proc sort data =  dv;
	by SSNRIS trt01a var7 var4 var1 var2 var3 var5 var6 ;
run;
data dv;
	set dv;
	by SSNRIS trt01a var7 var4 var1 var2 var3 var5 var6 ;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=dv, JM_INDSN2=, JM_BREAKCNT=4, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRIS trt01a var7 var4 var1 var2 var3 var5 var6 ;
	where usubjid^='';
run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
    by pageno SSNRIS trt01a var7 var4 var1 var2 var3 var5 var6 ;

	if not first.var1 then do;
		var1='';		
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
	title%eval(&lasttitlenum.+3) j=l "Treatment Group: #BYVAL(trt01a)";

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7
,JM_CELLWIDTH= 1.0 0.75 0.85 0.75 4.0  0.5  0.65
,JM_BYVAR= SSNRIS trt01a
,JM_BREAKVAR=
,JM_REPTYPE=Listing
);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;

data tlfdata.&output.;
	set temp_output;
	keep var: 	PAGENO	_PAGE	_BOTTOM_LINE_;
run;
