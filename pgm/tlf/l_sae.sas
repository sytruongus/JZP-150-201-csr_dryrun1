
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
proc sort data=adam.adae out=adae(drop=trtedt);
	by usubjid;
	where saffl ='Y' and AESER ="Y";
run;

proc sort data=adam.adsl out=adsl(keep=usubjid trtedt EOTSTT );
    by usubjid;
	where saffl ='Y';
run;

data ae;
	length  var2 var3 var5 var6 var7 var8 var9 $300 var4 var10 $600  block aeout $200 ;
	merge adsl(in=a) adae(in=b);
	by usubjid;
	if a and b;

	var1=compress(trt01a,"Dummy Treatment");

    var2 = strip(RFSTDTC)||"/ ^n"||strip(RFENDTC);

	 if missing(aebodsys) then var3 = "NOT CODED AEBODSYS/ ^n"; else var3 = strip(aebodsys)||"/ ^n";
	 if missing(aedecod)  then var3 = strip(var3)|| "NOT CODED AEDECOD/ ^n"; else  var3 = strip(var3)||strip(aedecod)||"/ ^n" ;
	 if missing(aeterm)   then var3 = strip(var3)|| "/ ^n"; else  var3 = strip(var3)||strip(aeterm) ;


	** derive AE start and end days ;
	     if ^missing(aestdtc) then var4 = strip(aestdtc)|| " (" || strip(put(astdy,8.))|| ")"; 
	     if ^missing(aeendtc) then var5 = strip(var5) || substr(strip(aeendtc),1,10) || " (" || strip(put(aendy,8.)) || ")" ;
	else if missing(aendt) and 	AEENRF="ONGOING" then  var5 = strip(var5) || "ONGOING";

	if ^missing(strip(TRTEMFL)) and TRTEMFL="Y" then var6 = "Yes";
	if ^missing(strip(TRTEMFL)) and TRTEMFL="N" then var6 = "No";

	     /*if AESER = "Y" then Var6=strip(var6)||"/^n"||strip("Yes");
	else if AESER = "N" then Var6=strip(var6)||"/^n"||strip("No");*/

	Var7=compress(TRTA,"Dummy Treatment");

	if ^missing(strip(AETOXGR)) then var8 = strip(ATOXGR)||"/^n"||strip(AEREL);

		
	if length(aeout)>18 then aeout=tranwrd(aeout,"/","/^n");
	if ^missing(AEACN) or ^missing(AEACNOTH) then var9= strip(AEACN)||'/^n' || strip(AEACNOTH) ;


	var10=strip(AEOUT);
	     if AESCONG ne "" then SAECRIT="Congenital Anomaly or Birth Defect";
	else if AESDISAB ne "" then SAECRIT="Persist or Signif Disability/Incapacity";
	else if AESDTH ne "" then SAECRIT="Fatal";
	else if AESHOSP ne "" then SAECRIT="Requires or Prolongs Hospitalization";
	else if AESLIFE ne "" then SAECRIT="Life Threatening";
	else if AESMIE ne "" then SAECRIT="Other Medically Important Serious Event";

	Var11=strip(SAECRIT);

	
	block=catx("-",usubjid, aeseq);

	label
	subjidl="Patient ID/|Age/Sex/|Race"
	var1="Rand Trt. Group"
	var2='First Dose/Last|Dose of Study|Intervention'
	var3= 'System Organ Class/|Preferred Term/|Reported Term' 
	var4= 'Start Date|(Study Day)'
	var5= 'End Date|(Study Day)'
	var6='TEAE/|SAE?'
	var7='Trt. Group|at Start of AE'
	var8='Severity Grade/|Rel. with Study Intervention/|Rel. with Study Procedures'
	var9='Action Taken/|Other Action(s) Taken|(Specify)' 
	Var10='Outcome'
    Var11='Seriousness|Criteria'	
;
	keep usubjid subjidl var: block aedecod aestdtc trt01: aeseq TRTSDT TRT01A TRT01AN;  
run;

proc sort data =  AE;
	by TRT01AN var1 SUBJIDL  aeseq ;
run;
data ae;
	set ae;
	by TRT01AN var1 SUBJIDL  aeseq ;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=AE, JM_INDSN2=, JM_BREAKCNT=3, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno TRT01AN var1 SUBJIDL  aeseq ;
run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
	by pageno TRT01AN var1 subjidl aeseq;

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
,JM_COL2VAR=  var1   subjidl   var2 sp2  var3 sp3 var4   var5  sp5 var6 var7 var8 var9 var10 var11
,JM_CELLWIDTH= 0.4    0.65    0.95 .05   1.0 .05  0.75    0.75  .05 0.4  0.6  1.0 0.75 0.8    0.85 
,JM_BYVAR= 
,JM_BREAKVAR=
,JM_REPTYPE=Listing
);

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;
/*
data tlfdata.&output.;
	set temp_output;
	keep subjidl usubjid var2-var11 TRT01A TRT01AN 	PAGENO	_PAGE	_BOTTOM_LINE_;
run;
*/
