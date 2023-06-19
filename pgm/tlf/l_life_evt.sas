
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
	where  upcase(PARCAT1) in  ('LEC-5 EXTENDED VERSION');
run;

proc freq data=adqs3;
	tables param*paramcd / list;
run;


proc sort data=adam.adqs3 out=adqs_01(keep= trta usubjid subjid avisit visit param TRAUMAFL adt ady anl01fl paramcd PARCAT1 rename=(param=param_trauma) );
    by trta usubjid subjid visit avisit adt;
    where saffl ='Y' and TRAUMAFL ="Y" and paramcd not in ("NTRAUMA") and upcase(PARCAT1) in  ('LEC-5 EXTENDED VERSION') ;
run;


proc sort data=adam.adqs3 out=adqs_02(keep= trta usubjid subjid avisit visit param INDEXFL adt ady anl01fl paramcd PARCAT1 rename=(param=param_index));
    by trta usubjid subjid visit avisit adt;
    where saffl ='Y' and INDEXFL ="Y" and avalc^='' 
			and paramcd in ("LEC01B01","LEC01B02","LEC01B03","LEC01B04","LEC01B05","LEC01B06","LEC01B07","LEC01B08","LEC01B09","LEC01B10","LEC01B11","LEC01B12","LEC01B13","LEC01B14","LEC01B15","LEC01B16","LEC01B17") 
			and upcase(PARCAT1) in  ('LEC-5 EXTENDED VERSION') ;
run;

proc sort data=adam.adqs3 out=adqs_03(keep= adt trta param usubjid subjid avisit PARCAT1 visit avalc rename=(avalc=INDEXYRS_avalc));
    by trta usubjid subjid visit avisit adt ;
    where saffl ='Y' and paramcd = "INDEXYRS" and upcase(PARCAT1) in  ('LEC-5 EXTENDED VERSION') ; 
run;

proc sort data=adam.adqs3 out=adqs_04(keep= trta usubjid subjid avisit visit param INDEXFL adt ady anl01fl paramcd PARCAT1 avalc rename=(param=param_que avalc=avalc_response));
    by trta usubjid subjid visit avisit adt;
    where saffl ='Y' and INDEXFL ="Y" and avalc^='' 
			and paramcd in ("LEC01B31","LEC01B32","LEC01B33","LEC01B34","LEC01B35","LEC01B6","LEC01B7","LEC01B8","LEC01B8N") and upcase(PARCAT1) in  ('LEC-5 EXTENDED VERSION') ;
run;
data qs;
    merge adqs_02 adqs_03 adqs_04;
    by trta usubjid subjid visit avisit adt;

	var1 = subjid;
          if upcase(race) =: "WHITE" then racec = "W";
   else if upcase(race) =: "BLA" then racec = "B";
   else if upcase(race) =: "NATIVE" then racec = "N";
   else if upcase(race) = "ASIAN" then racec = "A";
   else if upcase(race) =: "AMERICAN" then racec = "I";
   else if upcase(race) =: "OTHER" then racec = "O";
   else if upcase(race) =: "MULTIPLE" then racec = "P";

    var2 = Strip(trta);
    var3 = strip(put(adt,yymmdd10.))||"("||strip(put(ady,best.))||")";
    var4 = "";
    var5 = Strip(param_index);
    var6 = strip(INDEXYRS_avalc);
    var7 = strip(param_que);
    var8 = strip(avalc_response);


label
    var1="Participant|ID"
    var2="Treatment Group"
    var3="Date of Assessment (Study Day)"
    var4= 'Type of Trauma'
    var5= 'Index Event'
    var6= 'Time Since Index Event Occurred'
    var7= 'Question'
    var8= 'Response'

    keep usubjid var: SSNRIS trta;

run;

proc sort data =  qs;
    by trta var1 var2 var3 var4 var5 var6 var7 var8 ;
run;
data qs;
    set qs;
    by  trta var1 var2 var3 var4 var5 var6 var7 var8   ;
    obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=qs, JM_INDSN2=, JM_BREAKCNT=3, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno trta var1 var2 var3 var4 var5 var6 var7 var8  ;
    where usubjid^='';
run;


data temp_output;
    set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
    set JM_AVAL_ALLREPORT;
    by pageno trta var1 var2 var3 var4 var5 var6 var7 var8 ;

    if not first.var1 then do;
        var1='';var2='';
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
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7 var8 
,JM_CELLWIDTH= 0.4 0.35 0.5 0.65 0.5  0.3  0.35 0.4 0.4 0.4
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
    keep var: trta   PAGENO  _PAGE   _BOTTOM_LINE_;
run;
