/*************************************************************************
 * STUDY DRUG:        JZP-110 
 * PROTOCOL NO:       JZP-080/301
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      30Mar2020
 * PROGRAM NAME:      t_Lab_shift_Che_SAF.sas
 * DESCRIPTION:       Table 14.3.4.2.2: Chemistry Shift Table
 * DATA SETS USED:    ADLB and ADSL

 ** MACRO VARIABLE USAGE NOTES:
 * TRTVAR= BLMEDGR, --> Characer Treatment Variable (without n) from ADSL/ADLB to be used for Summary. 
 * eg: if you have TRT01A, TRT01AN then use TRTVAR=TRT01A. 
 * Program will automatically pick both character and numeric treatment variables **;
 * postbase_avisitn=%str(203,407),  --> List of Post Baseline AVISITN values to be summarized separated by comma.
 * base_avisitn=99,  --> Baseline AVISITN value.
 * ADLB_SUBSET=%STR(parcat1n=3 and ANL01FL='Y' AND PARAMN LE 302),  --> Subset condition to select records from data.
 * BASECATVAR=BNRIND --> This is Baseline Cateogry variable name ex: BNRIND, BTOXGR etc.
 * POSTCATVAR=ANRIND  --> This is Post-Baseline Cateogory variable name. ex: ANRIND, ATOXGR etc.
 * tab_page_size=16,  --> Number of records per page for proper page break. Default is 16.
 * drop_missing_row=N,  --> Y/N: if the value is Y then MISSING ROW will be deleted.Default is N.
 * drop_missing_column=N,  --> Y/N: if the value is Y then MISSING COLUMN will be deleted.Default is N.
 * drop_zero_rows=N,  --> Y/N: if the value is Y then the records with ZERO count across all treatments will be deleted.
 * Default is N.
 * BIGN_DATA=ADLB  --> ADSL or any other ADAM dataset name: 
 * --> if ADSL then the program will use BIGN from ADSL for denominator. 
 * The BIGN from ADSL will be displayed next to treatment label.
 * --> Otherwise: #of subjects with non-missing baselin and post-baseline ANRIND with in each visit will be
 * used as denominator. 
 * The N= number of subjects with both baseline and postbaseline data for the parameter/visit
 * will be displayed next to treatment label.

 * Specify _DEFAULT_WHERE global macro paramter value at the begining. This is for Population subset.
 * eg: %LET _DEFAULT_WHERE=SAFFL='Y';
 * ***************************************************************************
 * PROGRAM MODIFICATION LOG
 * ***************************************************************************
 * Programmer:    
 * Date:          
 * Description:   
 * *************************************************************************/;

proc datasets lib=work memtype=data kill nolist; quit;
options orientation=landscape missing=' ' nodate nonumber;

%macro t_lab_shift_hem_saffl( TRTVAR=, ADSL_SUBSET=%str(trt01aN in (1,2,3) and saffl='Y'), ADLB_SUBSET=%STR(trtaN in (1,2,3) and ANL01FL='Y'),
                  postbase_avisitn=, base_avisitn=,
                  BASECATVAR=,POSTCATVAR=,tab_page_size=16,
                  drop_missing_row=N,drop_missing_column=N,drop_zero_rows=N,
                  BIGN_DATA=);

   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath.,JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);

   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;
       
   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl adlb);
	
   proc format;
      invalue inlbshift
         "Panic Low" =1
         "Low"=2
         "Normal"=3
         "High"=4
         "Panic High"=5
         "Total"=6
      ;
	     value shift
      1="1: PL" 
      2="2: Low"
      3="3: Normal"
      4="4: High"
      5="5: PH"
      6="6:Total"
   ;
	  value avisit
	  	1 = "End of Week 1"
		4 = "End of Week 4"
		8 = "End of Week 8"
		12= "End of Week 12"
		92= "End of Week 92"
	;
   run;
/*   data _null_;*/
/*      tab_span_header='Baseline';*/
/*      call symputx("_DEFAULT_SPAN_HEAD",strip(tab_span_header)||' ^{nbspace 33} ^n');*/
/*   run;*/
	  	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'Baseline" trtn1 trtn2 trtn3 trtn4 trtn5 trtn6));

   proc format lib=work cntlout=shift_list;
      select lbshift;
   run;

   %global shift_list miss_shift_cat tot_shift_cat;

   proc sql noprint;
      select distinct strip(start) into: shift_list separated by ',' from shift_list order by input(start,best.);
      select distinct strip(start) into: miss_shift_cat from shift_list where index(label,'Missing') gt 0;
      select count(distinct strip(start)) into: tot_shift_cat from shift_list;
   quit;

   %put &miss_shift_cat. &shift_list. &tot_shift_cat.;

   **Read ADSL dataset and subset as needed**;
   data adsl;
      set adsl;
      where &ADSL_SUBSET. and trt01an ne .;
      keep usubjid trt01a:;
   run;

   **Get Post Baseline data and subset as needed**;
   proc sort data=adam.adlb out=adlbpost(keep=usubjid &trtvar.: avisitn param: &POSTCATVAR.: &BASECATVAR.) nodupkey;
      by usubjid paramcd avisitn &POSTCATVAR.;
      where  &ADLB_SUBSET. and &trtvar.n ne . and avisitn in(&postbase_avisitn.);
   run;

   **Create a flag to identify subject/parameter/visit records that has both baseline and post-baseline info**;
   data adlbpost;
      set adlbpost;

      if &POSTCATVAR. ne '' and &BASECATVAR. ne '' then
         base_post='Y';
      drop &BASECATVAR.;
   run;

   **Create format for AVISIT **;
/*   proc sql;*/
/*      create table avisfmt as*/
/*         select distinct avisitn as start,strip(avisit) as label,'avisit' as fmtname*/
/*            from adam.adlb*/
/*               where  &ADLB_SUBSET. and &trtvar.n ne . and avisitn in(&postbase_avisitn.)*/
/*                  order by avisitn;*/
/*   quit;*/
/**/
/*   proc format cntlin=avisfmt;*/
/*   run;*/

   **Get Baseline data**;
   proc sort data=adam.adlb out=adlbbase(keep=usubjid &trtvar.: param: &POSTCATVAR. rename=(&POSTCATVAR.=&BASECATVAR.)) nodupkey;
      by usubjid paramcd avisitn &POSTCATVAR.;
      where  &ADLB_SUBSET. and ablfl='Y' and &trtvar.n ne . and avisitn in(&base_avisitn.) and &POSTCATVAR. ne '';
   run;

   **Populate &BASECATVAR. for all postbaseline visits **;
   data adlbbase;
      set adlbbase;

      do avisitn=&postbase_avisitn.;
         output;
      end;
   run;

   proc sort data=adlbbase;
      by usubjid paramcd avisitn;
   run;

   **Merge &BASECATVAR. & &POSTCATVAR. **;
   data adlb;
      merge adlbbase adlbpost;
      by usubjid &trtvar.n &trtvar. paramcd paramn param avisitn;
      length avisit $50;

      if avisitn ne . then
         avisit=strip(put(avisitn,avisit.));
   run;

   **Create Dummy - all subjects from ADSL, with all parameters and all visits in ADLB**;
   proc sql;
      create table dummyparm as 
         select a.*,b.*
            from (select distinct paramcd, param,paramn from adlb where paramcd ne '') as a, 
               (select distinct avisitn,avisit from adlb where avisit ne '') as b
                  order by a.paramn,b.avisitn;
      create table dummyadsl as
         select a.*,b.*
            from adsl as a, dummyparm as b
               order by a.usubjid,b.paramcd,b.avisitn;
   quit;

   **Populate &POSTCATVAR., &BASECATVAR. and BASE_POST flag from ADLB dataset after merging with DUMMY dataset created above**;
   proc sql;
      create table adlb_ as
         select a.*,b.&POSTCATVAR.,b.&BASECATVAR.,b.base_post
            from dummyadsl as a left join adlb as b
               on a.usubjid=b.usubjid and a.paramcd=b.paramcd and a.avisitn=b.avisitn
            order by a.usubjid,a.paramcd,a.avisitn;
   quit;

   **Get Total row and column for each &POSTCATVAR. & &BASECATVAR. **;
   **Get Total &POSTCATVAR. - Sum of Non-missing &POSTCATVAR. only**;
   data adlb1;
      set adlb_;
      output;

      if &POSTCATVAR. ne ' ' then
         do;
            &POSTCATVAR.n=6;
            &POSTCATVAR.='Total';
            output;
         end;
   run;

   **Get Total &BASECATVAR.  - Sum of Non-missing &BASECATVAR. only**;
   data adlb1_;
      set adlb1;
      output;

      if &BASECATVAR. ne ' ' then
         do;
            &BASECATVAR.n=6;
            &BASECATVAR.='Total';
            output;
         end;
   run;

   **Create numeric variables for &POSTCATVAR./&BASECATVAR.**;
   data adlb1_;
      set adlb1_;

      if &POSTCATVAR. eq '' then delete;
/*         &POSTCATVAR.='Missing';*/

      if &BASECATVAR. eq '' then delete;
/*         &BASECATVAR.='Missing';*/

      if &POSTCATVAR. ne '' then
         &POSTCATVAR.n=input(propcase(&POSTCATVAR.),inlbshift.);

      if &BASECATVAR. ne '' then
         &BASECATVAR.n=input(propcase(&BASECATVAR.),inlbshift.);
      length shiftcat $100;
      shiftcat=strip(&BASECATVAR.)||' to '||strip(&POSTCATVAR.);
      shiftcatn=input(strip(put(&BASECATVAR.n,best.))||'.'||strip(put(&POSTCATVAR.n,best.)),best.);
  /*    **if Denominator is subject/parameter/visits with both postbaseline and baseline then keep only those cases**;
      %if %upcase(&BIGN_DATA) ne ADSL %then
         %do;
            if base_post ne 'Y' then
               delete;
         %end;*/
   run;

   **Create Total Treatment Group**;
   data adlb2;*(rename=( &trtvar.n =trtn &trtvar.=trt));
      set adlb1_;
	trtn = trt01an;
	trt = trt01a;

      output;
	  if trt01an in (1,2 ) ;
      trtn=99;
      trt='JZP150 Total';
      output;
/*      rename &trtvar.n=trtn &trtvar.=trt;*/
   run;

   data adsl;*(rename=( trt01an=trtn trt01a=trt));
      set adsl;
	trtn = trt01an;
	trt = trt01a;

      output;
	  if trt01an in (1,2 ) ;
      trtn=99;
      trt='JZP150 Total';
      output;
/*      rename trt01an=trtn trt01a=trt;*/
   run;
   ** Create Treatment formats for reporting **;
   %jm_gen_trt_fmt(jm_indsn=adsl,jm_intrtvar=trt);

   **Run below for each PARAMCD & AVSITN **;
   **Get Unique list of PARAM & AVISITs **;
   proc sql;
      create table parmvislist as
         select distinct paramn,paramcd,param,avisitn,avisit
            from adlb2
               order by paramn,avisitn;
   quit;

   %global n_blocks;
   %let n_blocks=&sqlobs.;
   %put &n_blocks.;

   **Create BLOCK_NUM variable. This will be used extensively from now on**;
   data parmvislist;
      set parmvislist;
      block_num=_n_;
   run;

   **Merge PARMVISTLIST with ADLB2 to populate BLOCK_NUM into final ADLB that goes into n (%) calculation **;
   proc sql;
      create table target as 
         select a.*,b.block_num
            from adlb2 as a left join parmvislist as b
               on a.paramn=b.paramn and a.avisitn=b.avisitn
            order by a.usubjid,a.paramn,a.avisitn;
   quit;

   options nomprint nomlogic nosymbolgen;

   *-----------------------------------------------------------------;
   *BIGN CALCULATION.;
   *-----------------------------------------------------------------;
   *** Calculate the Big N denominator from ADSL by treatment ***;
   %JM_BIGN(JM_INDSN=adsl,jm_suffix=1, jm_trtvarn=trtn, jm_trtfmt=trt );

   data bign_adsl;
      set jm_bign1;
   run;

   *** Run JM_AVAL_COUNT once for each BLOCK_NUM **;

   **if BIGN_DATA not equal to ADSL then create separate BIGN dataset for each BLOCK_NUM. This individual BIGN dataset will be used
     to calcualte percentages in n(%)**;
%macro run_aval_count;
   %do myblock_num=1 %to &n_blocks.;
      %if %upcase(&BIGN_DATA) ne ADSL %then
         %do;
            data targetx;
               set target;
               where index(lowcase(shiftcat),'missing') eq 0;
            run;
            *** Calculate the Big N denominator from ADLB by treatment ***;
            %JM_BIGN(JM_INDSN=targetx,jm_suffix=&myblock_num., jm_trtvarn=trtn, jm_trtfmt=trt,
                  JM_BIGN_WHERE= block_num=&myblock_num.);
         %end;

      %if %upcase(&BIGN_DATA) eq ADSL %then
         %let bign_suff=1;
      %else %let bign_suff=&myblock_num.;

      *** Calculate the counts for Any Deviations ***;
      %JM_AVAL_COUNT(JM_INDSN=target, jm_var=shiftcatn,jm_bign=jm_bign&bign_suff., jm_trtvarn=trtn, 
         JM_SECONDARY_WHERE= block_num=&myblock_num.,
         jm_block=&myblock_num., JM_CNTVAR=USUBJID,JM_AVAL_LABEL= Shift Category summary &BASECATVAR. by &POSTCATVAR. for block=&myblock_num.);

      data jm_Aval_count&myblock_num.;
         set jm_aval_count&myblock_num.;
         block_num=&myblock_num.;
         shiftcatn=input(strip(jm_Aval_namec),best.);
      run;

      **append all individual BIGN datasets into one**;
      %if %upcase(&BIGN_DATA) ne ADSL %then
         %do;

            data jm_bign&myblock_num.;
               set jm_bign&myblock_num.;
               block_num=&myblock_num.;
            run;

            %if &myblock_num =1 %then
               %do;

                  proc datasets lib=work memtype=data;
                     delete bign_all;
                  run;

                  quit;

               %end;

            proc append base=bign_all data=jm_bign&myblock_num. force;
            run;

         %end;
   %end;
%mend;

%run_aval_count;

*** Combine Summary data into one ALLDATA ***;
%JM_AVAL_ALLDATA (JM_OUTDSN=JM_AVAL_ALLDATA1);

**if BIGN_DATA not equal to ADSL then merge JM_AVAL_ALLDATA1 with combined BIGN dataset to get correct JM_AVAL_BIGN_LABEL**;
%if %upcase(&BIGN_DATA) ne ADSL %then
   %do;

      data jm_aval_alldata1;
         set jm_aval_alldata1;
         drop trtvar jm_aval_bign jm_aval_bign_label jm_aval_fmtname;
      run;

      proc sql;
         create table jm_aval_alldata1_ as
            select a.*, b.trtvar,b.jm_aval_bign,b.jm_aval_bign_label,b.jm_aval_fmtname
               from jm_aval_alldata1 as a left join bign_adsl as b
                  on a.JM_TRTVARN=b.JM_TRTVARN;
      quit;

   %end;

**Get &POSTCATVAR. &BASECATVAR. FROM SHIFTCAT (JM_AVAL_NAMEC)**;
DATA JM_AVAL_ALLDATA2;
   SET %if %upcase(&BIGN_DATA) ne ADSL %then

      %do;
         JM_AVAL_ALLDATA1_
      %end;
%else
   %do;
      JM_AVAL_ALLDATA1
   %end;;

   &POSTCATVAR.N=INPUT(SCAN(strip(JM_AVAL_NAMEC),2,'.'),best.);
   &BASECATVAR.N=INPUT(SCAN(strip(JM_AVAL_NAMEC),1,'.'),best.);
   JM_AVAL_NAMEC=STRIP(PUT(&POSTCATVAR.N,SHIFT.));
run;

*** Transpose the data in preprations for reporting ***;;
%JM_AVAL_SUM_TRANS(JM_AVAL_INPUT=Jm_aval_alldata2, 
   JM_AVAL_OUTPUT=JM_AVAL_TRANS1, JM_TRANS_BY=TRTN JM_AVAL_BIGN_LABEL BLOCK_NUM JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC &POSTCATVAR.N, 
   JM_TRANS_VAR=JM_AVAL_COUNTC , JM_TRANS_ID=&BASECATVAR.N);

**Wehn PARAM/AVISIT is missing then populate missing PARAM & AVISIT info into TRANSDATASET**;
proc sql;
   create table JM_AVAL_TRANS2 as
      select a.*,b.paramcd,b.paramn,b.avisitn,b.avisit,b.param
         from JM_AVAL_TRANS1 as a left join parmvislist as b
            on a.block_num=b.block_num
         order by b.paramn,b.avisitn,a.trtn,a.&POSTCATVAR.n;
quit;

**replace missing values with 0 **;
DATA JM_AVAL_TRANS3;
   SET JM_AVAL_TRANS2(rename=(trtn=JM_TRTVARN));
   JM_BLOCK=STRIP(PUT(PARAMN,BEST.))||'.'||STRIP(PUT(AVISITN,BEST.));
   JM_AVAL_LABEL=STRIP(AVISIT);
   array myarr{*} trt:;
   do i=1 to dim(myarr);
      if myarr(i)='' then
         myarr(i)='0';
   end;

   drop i;
run;

PROC SORT DATA=JM_AVAL_TRANS3;
   BY PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N;
RUN;

**Dummy all &POSTCATVAR. categories **;
data alldummycat;
   length jm_aval_namec $200;

   do i=&shift_list.;
      &POSTCATVAR.n=i;
      jm_aval_namec=strip(put(&POSTCATVAR.n,lbshift.));
      output;
   end;

   drop i;
run;

data dummyparm;
   set dummyparm;
   JM_BLOCK=STRIP(PUT(PARAMN,BEST.))||'.'||STRIP(PUT(AVISITN,BEST.));
   JM_AVAL_LABEL=STRIP(AVISIT);
   block_num=_n_;
run;

proc sql;
   create table dummycat as 
      select a.*,b.*,c.*
         from (select distinct jm_trtvarn,jm_Aval_bign_label from jm_aval_trans3) as a,
            (select distinct block_num,jm_block,jm_aval_label,paramcd,paramn,param,avisitn,
               avisit from dummyparm) as b,
            (select * from alldummycat) as c
               order by b.paramn,b.avisitn,a.jm_trtvarn,c.&POSTCATVAR.n;
quit;

**get a dataset wiht all &POSTCATVAR. cats**;
data JM_AVAL_TRANS4;
   length %do i= 1 %to &tot_shift_cat.;
   trtn%sysfunc(scan("&shift_list.",&i.,","))
   %end;
   $200;
   MERGE DUMMYCAT (IN=A) JM_AVAL_TRANS3(IN=B keep=PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N TRT:);
   by PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N;

   if a  %if %upcase(&drop_zero_rows)=Y %then
      %do;
         and b
      %end;
   ;
   array myarr{*} trt:;
   do i=1 to dim(myarr);
      if myarr(i)='' then
         myarr(i)='0';
   end;

   drop i;
run;

**Indent the JM_AVAL_NAMEC correctly for reporting**;
DATA JM_AVAL_TRANS4;
   SET JM_AVAL_TRANS4;
   by PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N;

   *JM_AVAL_NAMEC='      '||STRIP(SCAN(JM_AVAL_NAMEC,2,':'));
   JM_AVAL_NAMEC='   '||STRIP(SCAN(JM_AVAL_NAMEC,2,':'));
   output;

   if first.JM_TRTVARN then
      do;
         JM_AVAL_NAMEC=compbl(strip(tranwrd(JM_AVAL_BIGN_LABEL,'|','')));
         &POSTCATVAR.N=0;
         OUTPUT;
      END;
RUN;

PROC SORT DATA=JM_AVAL_TRANS4;
   BY PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N;
RUN;

**Set TRT n% info missing for the header rows of each treatment**;
data jm_aval_trans4;
   set jm_aval_trans4;
   BY PARAMN AVISITN JM_TRTVARN &POSTCATVAR.N;

   if first.avisitn then
      jm_ord=0;
   jm_ord+1;
   retain jm_ord;
   array myarr{*} trt:;
   do i=1 to dim(myarr);
      if &POSTCATVAR.n le 0 then
         myarr(i)='';
   end;

   drop i;
run;

**Delete missing row/missing column/or both**;
data jm_aval_trans4;
   set jm_aval_trans4;

   %if %upcase(&drop_missing_row)=Y %then
      %do;
         if &POSTCATVAR.n=&miss_shift_cat. then
            delete;
      %end;

   %if %upcase(&drop_missing_column)=Y %then
      %do;
         drop trtn&miss_shift_cat.;
      %end;
	  if ANRINDn =99 then delete;
run;

*** Count the page breaks for the report ***;
%JM_PGBRK (JM_INDSN1=JM_AVAL_TRANS4, JM_BREAKCNT=12, JM_CONTOPT=N, JM_GROUPOPT=Y, JM_OUTDSN=JM_AVAL_ALLREPORT1);

**Creat PAGENO & also PARAMN, AVISITN from JM_BLOCK**;
data jm_aval_allreport1;
   set jm_aval_allreport1;
   jm_aval_namen=jm_ord;

   if paramn eq . then
      paramn=input(scan(strip(jm_block),1,'.'),best.);

   if avisitn eq . then
      avisitn=input(scan(strip(jm_block),2,'.'),best.);
   newpage=ceil(_n_/&tab_page_size);
   drop pageno;
   rename newpage=pageno;
run;

**Reset JM_BIGN1 and reset macro variables for treatment labels - These will be based on &BASECATVAR.**;
data jm_bign1;
   set jm_bign1(obs=1);

   do i=&shift_list.;
      JM_TRTVARN=I;
      JM_AVAL_START=I;
      TRTN=I;
      JM_AVAL_BIGN=0;
      JM_AVAL_BIGN_LABEL=strip(scan(PUT(i,lbshift.),2,':'));
      TRTVAR=JM_AVAL_BIGN_LABEL;
      JM_AVAL_FMTNAME='BIGNTRTF';
      OUTPUT;
   end;

   DROP I;
run;

**RE-Create macro variables for treatment labels**;
%do i=1 %to &tot_shift_cat.;
   %global trtlab&i.;
   %let trtlab&i.=;
%end;

DATA _NULL_;
   SET JM_BIGN1;
   call symput("TRTLAB"||strip(put(_n_,best.)),strip(jm_aval_bign_label));
run;

** COunt number of parameters to loop through**;
proc sql;
   create table parmlist as
      select distinct paramn,param,paramcd
         from JM_AVAL_ALLREPORT1
            where paramn ne . and param ne ''
               order by paramn;
quit;

%global n_lab_param;
%let n_lab_param=&sqlobs.;
%put &n_lab_param.;

proc sql noprint;
   create table jm_aval_allreport2 as
      select a.*,b.paramcd,b.param
         from jm_aval_allreport1(drop=paramcd param) as a left join parmlist as b
            on a.paramn=b.paramn
         order by a.PARAMN,a.AVISITN,a.JM_TRTVARN,a.&POSTCATVAR.N;
   select count(distinct jm_block) into :n_all_blocks
      from jm_aval_allreport2;
quit;

data jm_aval_allreport2;
   set jm_aval_allreport2;
   array myarr{*} $ trt:;
   do i=1 to dim(myarr);
      if lowcase(strip(jm_aval_namec))='missing' then myarr(i)=strip(scan(myarr(i),1,'('));
   end;
   drop i;
   if index(trtn99,'(') gt 0 then trtn99=strip(scan(trtn99,1,'('));

   drop trtn99;
run;

ods escapechar="^";
options nonumber;
*-----------------------------------------------------------------;
*PROC TEMPLATE CODE FOR STYLE ELEMENT;
*-----------------------------------------------------------------;
%JM_TEMPLATES;


%macro pageby_rep;
   *----------------------------------------------------------------------------------------------------------------------------------;
   *ODS OPEN- OPENS RTF DESTINATION;
   *----------------------------------------------------------------------------------------------------------------------------------;
   %JM_ODSOPEN (JM_OUTREPORT=, JM_BODYTITLEOPT=0, JM_STYLE=OXYSTYLE);

   *-----------------------------------------------------------------;
   *PROC TEMPLATE CODE FOR STYLE ELEMENT;
   *-----------------------------------------------------------------;
   *select one paramter one visit at a time**;
   %do myrep =1 %to &n_all_blocks.;

      *&n_lab_param.;
      data _null_;
         set dummyparm(firstobs=&myrep. obs=&myrep.);
         call symput("sel_paramn",strip(put(paramn,best.)));
         call symput("sel_param",strip(param));
         call symput("sel_avisitn",strip(put(avisitn,best.)));
         call symput("sel_avisit",strip(avisit));
      run;

      *-----------------------------------------------------------------;
      *TITLES AND FOOTNOTES ARE READ FROM EXCEL SPREADSHEET.;
      *-----------------------------------------------------------------;
      %LET _DEFAULT_BOX=Parameter: &sel_param.|Post Baseline Visit: &sel_avisit.|Treatment|  Category, n (%);

      data jm_aval_allreport;
         set jm_aval_allreport2;
         where block_num=&myrep.;
         if index(jm_aval_namec,'N=') eq 0 then jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);
      run;

      %JM_AVAL_REPORT (JM_INDSN=Jm_aval_allreport,JM_BYVAR= , JM_BIGNDSN=Jm_bign1, jm_spanheadopt=Y , 
         JM_INDENTOPT=N, jm_breakopt=N, jm_breakvar=JM_AVAL_LABEL,JM_TRTWIDTH=0.6in);
   %end;

   %JM_ODSCLOSE;
%mend;

%pageby_rep;

proc sql;
   create table paramfmt as 
      select distinct paramn as start,param as label, 'paramfmt' as fmtname
         from dummyparm
            order by paramn;
   create table paramcdfmt as
      select distinct paramn as start,paramcd as label, 'paramcdfmt' as fmtname
         from dummyparm
            order by paramn;
quit;

proc format cntlin=paramfmt;
run;

proc format cntlin=paramcdfmt;
run;

**Update Output reporting dataset**;
data _null_;
   output=tranwrd("&outputnm.",'-','_');
   call symput("outputdt",strip(output));
run;

%put &outputdt.;
data tlfdata.&OUTPUTdt.;
   set jm_aval_allreport2;
   keep paramcd param paramn trt: jm_trtvarn avisit: jm_block jm_aval_label jm_aval_namec &POSTCATVAR.n;
run;

%mend t_lab_shift_hem_saffl;

%t_lab_shift_hem_saffl(TRTVAR=TRTA, postbase_avisitn=%str(1,4,8,12,92), base_avisitn=%str(0,-1),
   ADLB_SUBSET=%STR(&TRTVAR.N in (1,2,3) and saffl='Y' and parcat1="Hematology" and ANL01FL='Y' and anl05fl='Y'),
   BASECATVAR=BNRIND,POSTCATVAR=ANRIND,
   tab_page_size=14,drop_missing_row=N,drop_missing_column=N,drop_zero_rows=N,BIGN_DATA=ADLB);

ODS LISTING;
title;
footnote;
