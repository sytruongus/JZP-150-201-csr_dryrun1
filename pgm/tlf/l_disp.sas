/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Vikram K
* DATE CREATED:   	17JAN2023
* PROGRAM NAME:   	l_disp
* DESCRIPTION:    	Creating 10.2.1.1 Participant Disposition listing
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

data ds;
	set sdtm.ds;
	where dsdecod='RANDOMIZED';
			var6= strip(dsstdtc);
			keep usubjid var6;
run;

proc sort nodupkey; by usubjid; run;

data adsl_;
	merge ds(in=a) adam.adsl(in=b);
	by usubjid;
	if a;
run;

data adsl;
	length var11 $200.;
	set adsl_;
		where fasfl='Y';

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
		var2 = put(age, 2.) || "/^n" || sex || "/^n" || racec;
		var3 = strip(enrlfl) || "/" ||strip(saffl)|| "/" ||strip(pkfl)|| "/^n" || strip(fasfl) || "/" ||  strip(mfasfl) ;
		var4= strip(RFICDTC);
/*		var5= compress(trt01p,"Dummy Treatment");*/
		var5= strip(trt01p);
/*		var6= strip(RFXSTDTC);*/
		var7= "   "||strip(compsfl);

		var8=put(trtsdt,yymmdd10.);
		var9=put(trtedt,yymmdd10.);

		if nmiss(eosdt,trtsdt)=0 then stydy=eosdt-trtsdt+(eosdt>=trtsdt);
		if eosdt ne . and stydy ne . then var10= strip(put(eosdt,yymmdd10.))||' ('|| strip(put(stydy,8.))||')';
		else if eosdt ne . and stydy eq . then var10= strip(put(eosdt,yymmdd10.));

		if eosstt='COMPLETED' then var11='COMPLETED';
		if eosstt='DISCONTINUED' and dcsreas ne '' then var11='DISCONTINUED'||': '||strip(dcsreas);	
		if eosstt='DISCONTINUED' and dcsreas eq '' then var11='DISCONTINUED';	

	label
	var1='Participant ID'
	var2='Age/|Sex/|Race'
	var3='ENR/SAF/|PK/|FAS/mFAS'
	var4='Date of|Informed Consent'
	var5='Randomized|Treatment|Group'
	var6='Date of|Randomization'
	var7='Completed|(Y/N)'
	var8='First|Dose|Date'
	var9='Last|Dose|Date'
	var10='Completion or|Discontinuation|Date (Study|Day)'
	var11='Primary Reason|for|Discontinuation'
	
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

%JM_PGBRK (JM_INDSN1=adsl, JM_INDSN2=, JM_BREAKCNT=5, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

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
,JM_COL2VAR=  var1    var2   var3  var4    var5  var6 var7 var8 var9 var10 var11
,JM_CELLWIDTH= 0.8    0.3   0.6   0.75    0.75   0.5  0.75  0.75  0.7   0.8    1.3 
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

