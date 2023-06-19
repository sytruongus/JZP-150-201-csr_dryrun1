
/*************************************************************************
* STUDY DRUG:       JZP150-201
* PROTOCOL NO:      JZP150-201
* PROGRAMMER:       Nitesh Patil
* DATE CREATED:     25JAN2023
* PROGRAM NAME:     l-PROTDV
* DESCRIPTION:      Creating Adverse Events listing
* DATA SETS USED:   adsl adae
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
data adqs3;
	set adam.adqs3;
	where  upcase(PARCAT1) in  ('MINI 7.0.2');
run;

proc freq data=adqs3;
	tables parcat1*param*paramcd / list;
run;

proc sort data=adam.adqs3 out=adqs_01(keep= age sex race  trta usubjid subjid avisit visit adt ady anl01fl param paramcd PARCAT1 parcat2 aval avalc QSEVLINT QSEVINTX);
    by trta  usubjid subjid visit avisit adt;
    where saffl ='Y' and PARCAT1 in  ('MINI 7.0.2') ;
run;


data qs;
    set adqs_01;

    var1 = subjid;
          if upcase(race) =: "WHITE" then racec = "W";
   else if upcase(race) =: "BLA" then racec = "B";
   else if upcase(race) =: "NATIVE" then racec = "N";
   else if upcase(race) = "ASIAN" then racec = "A";
   else if upcase(race) =: "AMERICAN" then racec = "I";
   else if upcase(race) =: "OTHER" then racec = "O";
   else if upcase(race) =: "MULTIPLE" then racec = "P";

    var2 =  strip(trtan);
    var3 = strip(put(adt,yymmdd10.))||"("||strip(put(ady,best.))||")";
    var4 = strip(parcat2);
    if QSEVLINT^='' then var5 = QSEVLINT;
	else if QSEVINTX^='' then var5 = QSEVINTX;

	var6 = Strip(param);
    var7 = strip(avalc);


label
    var1="Participant|ID"
    var2="Treatment Group"
    var3= 'Date of Assessment (Study Day)'
    var4= 'Module'
    var5= 'Time Frame'
    var6= 'Question'
    var7= 'Response'

/*    keep usubjid var: SSNRIS trta;*/

run;

proc sort data =  qs;
    by  trta var1 var2 var3 var4 var5 var6 var7  ;
run;
data qs;
    set qs;
    by  trta var1 var2 var3 var4 var5 var6 var7  ;
    obs = _n_;
	    keep usubjid var:  trta;

run;

%JM_PGBRK (JM_INDSN1=qs, JM_INDSN2=, JM_BREAKCNT=5, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno  trta var1 var2 var3 var4 var5 var6 var7 ;
    where usubjid^='';
run;


data temp_output;
    set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
    set JM_AVAL_ALLREPORT;
    by pageno  trta var1 var2 var3 var4 var5 var6 var7  ;

    if not first.var1 then do;
        var1='';
    end;
/*    sp0='';*/
/*  sp1='';*/
/*  sp2='';*/
/*  sp3='';sp4='';sp5='';*/
/*  label sp0='|'; label sp1='|';label sp2='|';label sp3='|';label sp4='|';label sp5='|';;*/
run;

options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*';
*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

/*options nobyline;*/
/*    title%eval(&lasttitlenum.+2) j=l "Randomization stratum: #BYVAL(SSNRIS)";*/
/*    title%eval(&lasttitlenum.+3) j=l "Treatment Group: #BYVAL(trta)";*/

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7 
,JM_CELLWIDTH= 0.4 0.35 0.35 0.45 0.45  1.0  1.0 
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
    keep var: SSNRIS trta   PAGENO  _PAGE   _BOTTOM_LINE_;
run;
