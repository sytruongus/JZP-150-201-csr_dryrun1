/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Vikram K
* DATE CREATED:   	18JAN2023
* PROGRAM NAME:   	l_ie
* DESCRIPTION:    	Creating 10.2.1.2 Inclusion Criteria Not Met and/or Exclusion Criteria Met  listing
* DATA SETS USED: 	IE 
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


proc sort data=sdtm.ie out=SDTMIE;
    by USUBJID IESEQ;
run;

data SUPPIE_1;
	set sdtm.suppie;
	length IESEQ 8;
	IESEQ=input(IDVARVAL,8.);
run;

proc sort data=SUPPIE_1 ;
    by USUBJID IESEQ;
run;

proc transpose data=SUPPIE_1 out=tr_suppie;
by usubjid IESEQ;
var qval;
id qnam;
idlabel qlabel;

run;

data ie_1;
	merge SDTMIE(in=MAIN) tr_suppie ;
	by  USUBJID IESEQ;
	if MAIN;

run;

proc sort data=ie_1 out=ie;
	by usubjid;
run;

proc sort data=adam.adsl out=adsl;
    by usubjid;
	where enrlfl ='Y';
run;

data dv1;
	merge adsl(in=a) ie(in=b);
	by usubjid;
	if a;

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
		var4 = strip(iedtc);
		if iecat='INCLUSION' then var5 = strip(ieorres);
		if iecat='EXCLUSION' then var6 = strip(ieorres);
		var7= strip(ietest);
		var3=strip(icpv2);

	label
	var1='Participant|ID'
	var2='Age/|Sex/|Race'
	var3='Protocol|Version'
	var4='Screen|Failure|Date'
	var5='Inclusion|Criteria|Not Met'
	var6='Exclusion|Criteria|Met'
	var7='Description of Criteria'
	
;
	keep usubjid  var: ;  
run;

proc sort data =  dv1;
	by  var1;
run;
data adsl;
	set dv1;
	by var1;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=adsl, JM_INDSN2=, JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

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
,JM_COL2VAR=  var1    var2   var3  var4      var5  var6   var7 
,JM_CELLWIDTH= 0.8    0.6    0.8    0.8     0.75   0.6   2.75   
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
	keep  usubjid var1-var11 PAGENO	_PAGE	_BOTTOM_LINE_;
run;

