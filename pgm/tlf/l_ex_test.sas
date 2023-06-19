
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

data suppda(keep= usubjid qval daseq);
	set sdtm.suppda;
	where qnam="EXPDATE";

	DASEQ = input(idvarval,best.);
run;
data da(keep= usubjid darefid daseq) ;
	set sdtm.da;
run;

data da_list;
	merge suppda(in=a) da;
	by usubjid daseq;
	if a;
run;


proc sort data=adam.adsl out=adsl(keep=usubjid trt01a SSNRIS age sex race subjid );
    by usubjid;
	where saffl ='Y';
run;


data ex;

	merge adsl(in=a) da_list(in=b);
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
	var2 = trt01a;
	var3 = strip(darefid);
	var4 = strip(qval);

	

	label
	var1="Participant |ID"
	var2="Study Intervention"
	var3="Lot Number"
	var4="Expiration Date"
	
		
;
	keep usubjid SSNRIS trta var:;  
run;

proc sort data =  ex;
	by   var1 var2 var3 var4 ;
run;
data ex;
	set ex;
	by   var1 var2 var3 var4 ;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=ex, JM_INDSN2=, JM_BREAKCNT=22, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno var1 var2 var3 var4 ;
		where usubjid^='';

run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
    by pageno var1 var2 var3 var4 ;

	if not first.var1 then do;
		var1='';	
		var2='';	
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

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 
,JM_CELLWIDTH= 1 1 1 1 
,JM_BYVAR= 
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
