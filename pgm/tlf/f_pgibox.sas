/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       krishnaprasad Mummalaneni
* DATE CREATED:   	22NOV2022
* PROGRAM NAME:   	f-pgibox
* DESCRIPTION:    	Creating Adverse Events listing
* DATA SETS USED: 	adsl adae 
***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer:    
Date:          
Description:   
*************************************************************************/

options nofmterr noxwait  missing='';
/*****/options mprint mlogic symbolgen;
options formchar="|----|+|---+=|-/\<>*";
options varlenchk=nowarn;

proc datasets lib=work memtype=data nolist kill; 
quit;

%let PROTOCOL=150-201;
ods escapechar="^";

%let default_fontsize=9;
%let RSLTPATH=C:\SASData\JZP-150\150-201\stat\csr_dryrun1\results;

data _null_;
   call symputx('mypgmname',scan("%sysget(SAS_EXECFILENAME)",1,'.'));
run;
%put &mypgmname;

*-----------------------------------------------------------------;

*TITLE AND FOOTNOTES
*-----------------------------------------------------------------;
%JM_TF (jm_infile=C:\SASData\JZP-150\150-201\stat\csr_dryrun1\statdoc\sap, JM_PROG_NAME= &mypgmname.,
	JM_PRODUCE_STATEMENTS=Y);

*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;

*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;

proc format;
	 value trt (MULTILABEL)

1="JZP150 0.3 mg"
2="JZP150 4 mg"
3="Placebo";
   ;
run;


****************************************************;
* read in adam.adqsess dataset *;
****************************************************;
proc sql;
  create table caps as select usubjid,trta,trtan label="Treatment",avisit,avisitn,base,chg,paramcd from adam.adqs
where parcat1="PGI" and paramcd="PGI0101" and chg ne . and avisit="Week 12" and MFASFL="Y" and anl01fl="Y" order by trtan,chg;
quit;

****************************************************;
* define plot template *;
****************************************************;
proc template;
define statgraph boxplot;
begingraph / designwidth=1019 designheight=370 border=false;

/*layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;*/
	layout overlay / xaxisopts=( LABEL= ('Treatment Group') labelattrs=(family='Courier New' size=9pt ) )
	yaxisopts=( LABEL= "Change in PGI-S" labelfitpolicy=splitalways labelsplitchar='*'  offsetmin=0.05 
		labelattrs=(family='Courier New' size=9pt ) );

		boxplot x=trtan y=chg / group=trtan groupdisplay=cluster name='box' boxwidth=0.1 ;
	endlayout;
/*endlayout;*/
endgraph; 
end;
run;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
ods escapechar "^" noproctitle;
ods rtf nogtitle nogfootnote ; 
goptions  reset=symbol ftext="Courier New" gsfmode=replace 
	noborder hsize=7.75in vsize=4.95in ;
	ods output  SGRender=stat;
proc sgrender data=caps template=boxplot ;
format trtan trt. ;
run;quit;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;
ods listing;


data tlfdata.&mypgmname.(drop=CHG TRTAN BOX_CHG_X_TRTAN_GROUP_TRTAN__GP rename=(BOX_CHG_X_TRTAN_GROUP_TRTAN___Y=statval BOX_CHG_X_TRTAN_GROUP_TRTAN__ST=stat BOX_CHG_X_TRTAN_GROUP_TRTAN___X=trt ));
set stat;
run;

