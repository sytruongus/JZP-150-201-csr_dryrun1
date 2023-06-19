/*************************************************************************
* STUDY DRUG:     	JZP150-201
* PROTOCOL NO:    	JZP150-201 
* PROGRAMMER:       krishnaprasad Mummalaneni
* DATE CREATED:   	26JAN2023
* PROGRAM NAME:   	f_caps_int_plotchange
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
%let output=&valoutnm;
*-----------------------------------------------------------------;
*DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
*-----------------------------------------------------------------;
%JM_DATAPREP;

*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;


/*macro for data*/

%include "C:\SASData\JZP-150\150-201\stat\csr_dryrun1\pgm\tlf\f_macro_wk1_wk12.sas";

%fig(dset=adqs,paramcd=%str("CA5BTOSV"));


proc sort data=all;
by trtan ;
run;

proc template;
define statgraph linegraph;
begingraph / designwidth=1019 designheight=450 border=false;

layout lattice / rowdatarange=data columndatarange=data rowgutter=0 columngutter=10 
    rows=1 columns=1 rowgutter=10 columngutter=10 rowweights=(1.0 preferred) columnweights=(1.0);

layout overlay / xaxisopts=( LABEL= ('Visit') labelattrs=(family='Courier New' size=7pt )
	 linearopts=(tickvaluelist=(1 2 3 4)))  
	yaxisopts=(  LABEL= ('Change from Baseline Intrusive Symptoms') labelattrs=(family='Courier New' size=7pt ));

	scatterplot x=avisitn y=lsmndiff /group=trtan discreteoffset= -0.05 yerrorupper=ucl yerrorlower=lcl name='scatter1'
		markerattrs=( symbol= circlefilled weight=normal) datalabel=LABEL legendlabel='Treatment';

	seriesplot x=avisitn y= lsmndiff / group=trtan name='series1' discreteoffset= -0.05 clusterwidth=0.85 connectorder=xaxis 
		grouporder=data lineattrs=( pattern=solid thickness=1) DATALABEL=lsmndiff name='series1';

	discretelegend 'scatter1' 'series1' / opaque=true border=yes halign=center valign=bottom  location=outside
		displayclipped=true order=rowmajor across=2 down=1 title=" " titleattrs=(family='Courier New' size=8pt )
		valueattrs=(family='Courier New' size=8pt );	
endlayout;

endlayout;
endgraph;
end;
run;

*-----------------------------------------------------------------------------------------------------------------------;
*ODS OPEN- OPENS RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

options nonumber nobyline ;
OPTIONS FORMCHAR='|_---|+|---+=|-/\<>*'; 
ods escapechar "^" noproctitle;
ods rtf nogtitle nogfootnote ; 
goptions  reset=symbol ftext="Courier New" gsfmode=replace 
	noborder hsize=6.75in vsize=3.95in ;
	ods output  SGRender=stat;
proc sgrender data=all template=linegraph ;
format avisitn visit. trtan trt.;
run;
quit;

*----------------------------------------------------------------------------------------------------------------------------------;
*ODS CLOSE- CLOSES RTF DESTINATION;
*----------------------------------------------------------------------------------------------------------------------------------;
%JM_ODSCLOSE;
ods listing;

proc sort data=stat;
by trtan avisitn;
run;

data tlfdata.&output.;
set stat;
run;
