/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Vikram K
* DATE CREATED:   	19JAN2023
* PROGRAM NAME:   	l_demog
* DESCRIPTION:    	10.2.4.1 Demographics and Other Baseline Characteristics
* DATA SETS USED: 	ADSL 
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

data adqs10;
	set adam.adqs;
	where ablfl='Y' and paramcd='PTSDTSEV';
	var10=strip(put(aval,best.));

	keep usubjid var10 saffl;
run;
proc sort nodupkey; by usubjid; run;

data adqs21;
	set adam.adqs;
	where ablfl='Y' and paramcd='PGI0101';
	var121=strip(put(aval,best.));
	keep usubjid var121 saffl;
run;
proc sort nodupkey; by usubjid; run;

data adqs22;
	set adam.adqs;
	where ablfl='Y' and paramcd='CGI0201';
	var122=strip(put(aval,best.));

	keep usubjid var122 saffl;
run;
proc sort nodupkey; by usubjid; run;

data adqs12;
	merge adqs21(in=a) adqs22(in=b);
	by usubjid;
	if a or b;
	var12= strip(var121)||'/'||strip(var122);
run;

data adqs13;
	set adam.adqs2;
	where ablfl='Y' and paramcd='PCL0125';
	var13=strip(put(aval,best.));

	keep usubjid var13 saffl;
run;
proc sort nodupkey; by usubjid; run;


data adsl;
	merge adam.adsl(in=a) adqs10 adqs12 adqs13;
	by usubjid saffl;
	if a;
		where saffl='Y';

	if strip(upcase(race))="AMERICAN INDIAN OR ALASKA NATIVE" then racec="N";
	else if strip(upcase(RACE))="ASIAN" then racec="A";
	else if strip(upcase(RACE))="BLACK OR AFRICAN AMERICAN" then racec="B";
	else if strip(upcase(RACE))="NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" then racec="NO";
	else if strip(upcase(RACE))="WHITE" then racec="W";
	else if strip(upcase(RACE))="NOT REPORTED" then racec="R";
	else if strip(upcase(RACE))="MULTIPLE" then racec="P";
	else if strip(upcase(RACE))="OTHER" then racec="O";
	else if strip(upcase(RACE))="DECLINED TO STATE" then racec="DS";
	
		var1= strip(subjid);
		var2= strip(trt01a);
		var3 = put(age, 2.);
		var4 = strip(sex);
		var5 = strip(racec);
		var6 = strip(ethnic);
		var7 = strip(put(weightbl,best.));
		var8 = strip(put(heightbl,best.));
		var9 = strip(put(bmibl,best.));
		var11 = strip(childpot);
		var14= strip(SSNRIS);


	label
	var1='Participant|ID'
	var2='Treatment|Group'
	var3='Age|(ye|ars)'
	var4='Gend|er'
	var5='Race'
	var6='Ethni|city'
	var7='Weight|(kg) at|Screening'
	var8='Height|(cm) at|Screening'
	var9='BMI|(kg/m2)|at|Screen|ing'
	var10='Baseline|CAPS-5|Total|Score'
	var11='Childbearing|Potential'
	var12='Baseline|PGI-S|CGI-S'
	var13='Baseline|PCL-5'
	var14='Randomization|Stratum'
;
	keep usubjid  var: dcsreas  TRTSDT TRT01P TRT01PN;  
run;


proc sort data =  adsl;
	by var11 var1;
run;
data adsl;
	set adsl;
	by var11 var1;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=adsl, JM_INDSN2=, JM_BREAKCNT=8, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
	where usubjid ne '';
    by pageno var11 var1 ;
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
,JM_COL2VAR=  var1   var2   var3  var4    var5    var6 var7  var8  var9  var10  var11 var12 var13 var14
,JM_CELLWIDTH= 0.6   0.6    0.3    0.3    0.25     0.5  0.5  0.5    0.5     0.5   0.4   0.5  0.5   0.6
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
	keep  usubjid var1-var14 PAGENO	_PAGE	_BOTTOM_LINE_;
run;
