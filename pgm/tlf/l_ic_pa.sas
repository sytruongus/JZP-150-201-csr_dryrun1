/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Vikram K
* DATE CREATED:   	18JAN2023
* PROGRAM NAME:   	l_ic_pa
* DESCRIPTION:    	10.2.1.3 Informed Consent / Protocol Amendment- Re Consent listing
* DATA SETS USED: 	 
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

data adsl;
	set adam.adsl;
		where enrlfl='Y';

	if strip(upcase(race))="AMERICAN INDIAN OR ALASKA NATIVE" then racec="N";
	else if strip(upcase(RACE))="ASIAN" then racec="A";
	else if strip(upcase(RACE))="BLACK OR AFRICAN AMERICAN" then racec="B";
	else if strip(upcase(RACE))="NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" then racec="NO";
	else if strip(upcase(RACE))="WHITE" then racec="W";
	else if strip(upcase(RACE))="NOT REPORTED" then racec="R";
	else if strip(upcase(RACE))="MULTIPLE" then racec="P";
	else if strip(upcase(RACE))="OTHER" then racec="O";
	else if strip(upcase(RACE))="DECLINED TO STATE" then racec="DS";
	
		var1 = strip(subjid);
		var2 = put(age, 2.) || "/" || sex || "/" || racec;
		var3= strip(RFICDTC);
		var4='';
		var5='';
		var6='';
		var7='';

label
	var1='Participant ID'
	var2='Age/|Sex/|Race'
	var3='Informed|Consent|Date'
	var4='Consent|Version|Signed'
	var5='Rescreened'
	var6='Informed|Consent|Date'
	var7='Consent|Version|Signed'

;
	keep usubjid  var: ;  
run;

proc sort data =  adsl;
	by var1;
run;

data adsl;
	set adsl;
	by var1;
	obs = _n_;
run;

%let _default_span_head=(var1 var2 var3 var4 var5 ("^R'\brdrb\brdrs\brdrw4 ' PK Consent/Assent" var6 var7));

%global _DEFAULT_BYVARS;

%JM_PGBRK (JM_INDSN1=adsl, JM_INDSN2=, JM_BREAKCNT=24, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
 	where usubjid ne '';
   by pageno var1 ;
run;

data temp_output;
	set JM_AVAL_ALLREPORT;
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
,JM_COL2VAR=  var1    var2   var3   var4    var5  var6   var7 
,JM_CELLWIDTH= 0.8    0.6    0.8    0.9     0.9   0.9    1   
,JM_BYVAR= 
,JM_BREAKVAR=
,JM_REPTYPE=Listing
,JM_SPANHEADOPT=Y
);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;

data tlfdata.&output.;
	set temp_output;
	keep  usubjid var1-var11 PAGENO	_PAGE	_BOTTOM_LINE_;
run;

