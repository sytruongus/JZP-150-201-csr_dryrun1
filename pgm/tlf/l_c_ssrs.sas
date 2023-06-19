
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
proc sort data=adam.adqs3 out=adqs_01(keep= age sex race SSNRIS trta usubjid subjid avisit visit adt ady anl01fl param paramcd PARCAT1 parcat2 aval avalc QSEVLINT QSEVINTX);
    by trta SSNRIS usubjid subjid visit avisit adt;
    where saffl ='Y' and PARCAT1 in  ('C-SSRS SINCE LAST VISIT','C-SSRS BASELINE/SCREENING VERSION') ;
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

    var2 = catx("/",age,sex,racec);
    var3 =  strip(visit);
    var4 = strip(anl01fl)||"/"||strip(avisit);
    var5 = strip(put(adt,yymmdd10.))||"^n("||strip(put(ady,best.))||")";
    var6 = strip(parcat2);
    var7 = Strip(param);
    if QSEVLINT^='' then var8 = QSEVLINT;
	else if QSEVINTX^='' then var8 = QSEVINTX;
    var9 = strip(put(aval,best.));
    var10 = strip(avalc);


label
    var1="Participant|ID"
    var2="Age/|Sex/|Race"
    var3="Visit"
    var4= 'Visit |Used for |Analysis |(Y/N)/ |Analysis |Visit'
    var5= 'Assessment |Date (Study Day)'
    var6= 'Category'
    var7= 'Question'
    var8= 'Assessment |Period'
    var9= 'Response'
    var10= 'Description';

/*    keep usubjid var: SSNRIS trta;*/

run;

proc sort data =  qs;
    by SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 ;
run;
data qs;
    set qs;
    by SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10  ;
    obs = _n_;
	    keep usubjid var: SSNRIS trta;

run;

%JM_PGBRK (JM_INDSN1=qs, JM_INDSN2=, JM_BREAKCNT=5, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 ;
    where usubjid^='';
run;


data temp_output;
    set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
    set JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 ;

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

options nobyline;
    title%eval(&lasttitlenum.+2) j=l "Randomization stratum: #BYVAL(SSNRIS)";
    title%eval(&lasttitlenum.+3) j=l "Treatment Group: #BYVAL(trta)";

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7 var8 var9 var10
,JM_CELLWIDTH= 0.4 0.35 0.35 0.45 0.45  0.45  0.85 0.4 0.4 0.4
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
    keep var: SSNRIS trta   PAGENO  _PAGE   _BOTTOM_LINE_;
run;
