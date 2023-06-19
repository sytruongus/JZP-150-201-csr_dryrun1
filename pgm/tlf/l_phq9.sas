
/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       Nitesh Patil
* DATE CREATED:   	25JAN2023
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
proc sort data=adam.adqs2 out=adqs_01(keep= usubjid subjid avisit visit adt ady anl01fl chg paramcd avalc);
	by usubjid subjid visit avisit adt;
	where saffl ='Y' and paramcd in  ('PHQ0111');
run;
proc sort data=adam.adqs2 out=adqs_02(keep= usubjid subjid SSNRIS visit avisit adt ady parcat1 parcat2 paramcd param age sex race trta trtsdt trtedt aval avalc);
	by trta SSNRIS usubjid subjid visit avisit adt age sex race trtsdt trtedt;
	where saffl ='Y'  and  paramcd in  ( "PHQ0101" 'PHQ0102' 'PHQ0103' 'PHQ0104' 'PHQ0105' 'PHQ0106' 'PHQ0107' 'PHQ0108' 'PHQ0109' 'PHQ0110' ) ;
run;

proc freq data=adqs_02;
	tables param*paramcd / list out=param;
run;

proc sort data=adam.adsl out=adsl;*(keep=usubjid SSNRIS );
    by usubjid;
	where saffl ='Y';
run;

proc transpose data=adqs_02 out=adqs_t;
	by trta SSNRIS usubjid subjid visit avisit adt age sex race trtsdt trtedt ;
	id paramcd;
	var aval;
run;
proc sort data=adqs_t;
	by usubjid subjid visit avisit adt;
run;

data qs;
	merge 	adqs_01 adqs_t;
	by usubjid subjid visit avisit adt ;

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
	var4 = strip(put(adt,yymmdd10.));
	var5 = strip(anl01fl)||"/"||strip(avisit);
	var6 = strip(put(ady,best.));
	var7 = Strip(trta);
	var8 = strip(avalc);
	var9 = strip(put(chg,best.));
	var10 = strip(PHQ0101);
	var11 = strip(PHQ0102);
	var12 = strip(PHQ0103);
	var13 = strip(PHQ0104);
	var14 = strip(PHQ0105);
	var15 = strip(PHQ0106);
	var16 = strip(PHQ0107);
	var17 = strip(PHQ0108);
	var18 = strip(PHQ0109);
	var19 = strip(PHQ0110);
	
label
	var1="Participant|ID"
	var2="Age/|Sex/|Race"
	var3="Visit"
	var4='Assessment |Date'
	var5= 'Visit |Used for |Analysis |(Y/N)/ |Analysis |Visit' 
	var6= 'Study |Day'
	var7= 'Assigned |Dose |(mg/d)'
	var8= 'PHQ01-Total |Score'
	var9= 'Change |from |Baseline'
	var10= 'Little Interest/Pleasure in Things |Score'
	var11= 'Feeling Down Depressed or Hopeless |Score'
	var12= 'Trouble Falling or Staying Asleep |Score'
	var13= 'Feeling Tired or Little Energy |Score'
	var14= 'Poor Appetite or Overeating |Score'
	var15= 'Feeling Bad About Yourself |Score'
	var16= 'Trouble Concentrating on Things |Score'
	var17= 'Moving Slowly or Fidgety/Restless |Score'
	var18= 'Thoughts You Be Better Off Dead |Score'
	var19= 'Difficult to Work/Take Care Things';

keep usubjid var: SSNRIS trta; 
 
run;

proc sort data =  qs;
	by SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19;
run;
data qs;
	set qs;
	by SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19;
	obs = _n_;
run;

%JM_PGBRK (JM_INDSN1=qs, JM_INDSN2=, JM_BREAKCNT=4, JM_CONTOPT=N, JM_GROUPOPT=N, JM_OUTDSN=JM_AVAL_ALLREPORT, JM_REPTYPE=Listing);

proc sort data=JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19;
	where usubjid^='';
run;


data temp_output;
	set JM_AVAL_ALLREPORT;
run;

data JM_AVAL_ALLREPORT;
	set JM_AVAL_ALLREPORT;
    by pageno SSNRIS trta var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19;

	if not first.var1 then do;
		var1='';var2='';		
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
	title%eval(&lasttitlenum.+3) j=l "Treatment Group: #BYVAL(trta)";

*----------------------------------------------------------------------------------------------------------------------------------;
*REPORT- PROC REPORT MODULE;
*----------------------------------------------------------------------------------------------------------------------------------;

%JM_AVAL_REPORT(JM_INDSN=JM_AVAL_ALLREPORT
,JM_COL2VAR=  var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19
,JM_CELLWIDTH= 0.4 0.35 0.5 0.65 0.5  0.3  0.35 0.4 0.4 0.4 0.4  0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4
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
	keep var: SSNRIS trta	PAGENO	_PAGE	_BOTTOM_LINE_;
run;
