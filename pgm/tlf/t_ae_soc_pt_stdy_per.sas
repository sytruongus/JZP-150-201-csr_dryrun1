 /*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08/29/2022
 * PROGRAM NAME:      t_ae_soc_pt_sev_004.sas
 * DESCRIPTION:       Template program to create "Treatment-Emergent Adverse Events by System Organ Class, 
 *           			 Preferred Term and Maximum CTCAE v[X.X] Grade" Table
 * DATA SETS USED:    ADSL, ADAE
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
 *            TAB_EVENT_COUNT - Display AE Event Counts Y or N ex: Y - to display event counts
 *            TAB_SORT        - Sorting order. can take FREQ or missing. FREQ - Descending order of PT
 *            ANALYSIS_VAR    - Analysis variable ex: ARELN
 *            ANALYSIS_VAR_FMT- Anaysis variable format. ex: arel
 *            ADSL_SUBSET     - ADSL subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y'
 *            ADAE_SUBSET     - ADAE subset condition to be used. ex: &TRTVAR.N in (1,2,3,4) and SAFFL='Y' and 
 *                                  TRTEMFL='Y' and PLBFL ne 'Y'
 ************************************************************************
 PROGRAM MODIFICATION LOG
 *************************************************************************
 Programmer:  
 Date:        
 Description: 
*************************************************************************/

PROC DATASETS LIB=WORK MEMTYPE=DATA KILL;QUIT;

options orientation=landscape missing=' ' nodate nonumber;
 
%macro t_ae_soc_pt_stdy_per(trtvar=TRT01A,tab_page_size=12,Tab_Event_Count_YN=N,tab_sort=FREQ,
                           analysis_var=aperiod,analysis_var_fmt=aperiod,
                           adsl_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y'),
                           adae_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y' and TRTEMFL='Y')
                           );
 
   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);
 
   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;

   **Call Pre-processing Macro **; 
   %jm_tlf_pre(dtnames=adsl adae);

   data _null_;
      evntcnt="&tab_event_count_yn.";
      if upcase(evntcnt)='Y' then tab_box='System Organ Class|Study Period, n (%) [E]|  Preferred Term|    CTCAE Grade, n (%) [E]';
      else tab_box='System Organ Class|Study Period, n (%)|  Preferred Term|    Study Period, n (%)';
      tab_span_header='Baseline Medication Group';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_SPAN_HEAD",strip(tab_span_header)||' ^{nbspace 33} ^n');
   run;

   %let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 'Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
   data ADSL;                             
      set ADSL;                             
      where &adsl_subset.;
      trtn=&TRTVAR.N;                             
      trt=&TRTVAR.;                             
      output;  
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="JZP150 Total";                            
      output;                             
   run;                             
    
   proc sort data=ADSL;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
    
   *** Create a macro variable for storing ADAE dataset name from the list of datasets ***;                             
   data ADAE ;                             
      set ADAE ;                             
      where &adae_subset.;
      evnt=_n_; 
      trtn=&TRTVAR.N;                             
      trt=&TRTVAR.;                             
      output;  
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="JZP150 Total";                            
      output;                             
   run;                             
    
   proc sort data=ADAE ;                             
      by studyid usubjid trtn trt;                             
      where trtn ne .;                             
   run;                             
    
   *** For ADAE reports by worst/max sevrity/toxicity/relationship/outcome create flag variables for 
      maximum with in subject, maximum within USUBJID/AEBODSYS, maximuym within USUBJHID/AEBODSYS/AEDECOD
      1) Flag variable for max wiht in Subject ends with _SUBJ 
      2) Flag variable for max wiht in Subject/AEBODSYS ends with _SOC 
      3) Flag variable for max wiht in Subject/AEBODSYS/AEDECOD ends with _PT ***;                            
   proc sql;                             
      create table ADAE__1 as select a.*,case when a.&analysis_var. = b.&analysis_var._subj then 'Y' else ' ' end as
      &analysis_var._subj 
      from adae as a left join (select distinct usubjid,trtn, min(&analysis_var.) as &analysis_var._subj from ADAE 
      where &analysis_var. ne . group by usubjid,trtn) as b on a.usubjid=b.usubjid and a.trtn=b.trtn;

      create table ADAE__2 as select a.*,case when a.&analysis_var. = b.&analysis_var._soc then 'Y' else ' ' end as 
      &analysis_var._soc 
      from ADAE__1 as a left join (select distinct usubjid,trtn,aebodsys, min(&analysis_var.) as &analysis_var._soc 
      from ADAE__1 
      where &analysis_var. ne . group by usubjid,trtn,aebodsys) as b on a.usubjid=b.usubjid and a.trtn=b.trtn and 
      a.aebodsys=b.aebodsys;

      create table ADAE__3 as select a.*,case when a.&analysis_var. = b.&analysis_var._pt then 'Y' else ' ' end as 
      &analysis_var._pt 
      from ADAE__2 as a left join (select distinct usubjid,trtn, aebodsys,aedecod, max(&analysis_var.) as 
      &analysis_var._pt from ADAE__2 
      where &analysis_var. ne . group by usubjid,trtn,aebodsys,aedecod) as b on a.usubjid=b.usubjid and a.trtn=b.trtn 
      and a.aebodsys=b.aebodsys and a.aedecod=b.aedecod;
   quit;                             
    
   data ADAE;                             
      set ADAE__3;                             
   run;                             
    
   *** Create TARGET dataset by combing the Working datasets ***;                             
   data target;                             
      merge ADSL(in= a) ADAE (in= b);                             
      by studyid usubjid trtn trt;                             
      if a;                             
   run;        
 
   proc sql noprint;
     select max(start) into : maxfmtval
     from formats
     where upcase(fmtname)=%upcase("&analysis_var_fmt.");
   quit;
   %put &maxfmtval.; 

   *** Create formats for Treatment variables ***;                             
   %jm_gen_trt_fmt;

   *** Create JM_BIGN(n) by calling JM_BIGN macro.;                      
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(saffl='Y'),JM_SUFFIX=1);                   

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=trtemfl='Y' and &analysis_var. ne . and &analysis_var._subj eq 'Y',JM_VAR=&analysis_var.,JM_FMT=&analysis_var_fmt..,                    
      JM_AVAL_LABEL=Number of Subjects with at Least One TEAE,JM_BLOCK=101,JM_BYVAR=trtemfl,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=trtemfl='Y' and aebodsys ne '' and &analysis_var. ne . and &analysis_var._soc eq 'Y',
      JM_VAR=&analysis_var.,JM_FMT=&analysis_var_fmt..,                    
      JM_AVAL_LABEL=System organ Class,JM_BLOCK=102,JM_BYVAR=aebodsys,JM_TRTVARN=trtn
      );
                            
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '' and &analysis_var. ne . and &analysis_var._pt eq 'Y',
      JM_VAR=&analysis_var.,JM_FMT=&analysis_var_fmt..,                    
      JM_AVAL_LABEL=Preferred Term,JM_BLOCK=103,JM_BYVAR=aebodsys aedecod,JM_TRTVARN=trtn
      );

   **Get event counts **;
   %macro gen_evnt_cnt;
      %if &Tab_Event_Count_YN.=Y %then %do;
         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,
            JM_SECONDARY_WHERE=trtemfl='Y' and &analysis_var. ne . and &analysis_var._subj eq 'Y',JM_VAR=&analysis_var.,
            JM_FMT=&analysis_var_fmt..,                    
            JM_AVAL_LABEL=Number of Subjects with at Least One TEAE cnt,JM_BLOCK=201,JM_BYVAR=trtemfl,JM_TRTVARN=trtn
            );

         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,
            JM_SECONDARY_WHERE=trtemfl='Y' and aebodsys ne '' and &analysis_var. ne . and &analysis_var._soc eq 'Y',
            JM_VAR=&analysis_var.,JM_FMT=&analysis_var_fmt..,                    
            JM_AVAL_LABEL=System organ Class cnt,JM_BLOCK=202,JM_BYVAR=aebodsys,JM_TRTVARN=trtn
            );
                                  
         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,
            JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '' and &analysis_var. ne . and &analysis_var._pt eq 'Y',
            JM_VAR=&analysis_var.,JM_FMT=&analysis_var_fmt..,                    
            JM_AVAL_LABEL=Preferred Term cnt,JM_BLOCK=203,JM_BYVAR=aebodsys aedecod,JM_TRTVARN=trtn
            );
          
         proc sql;
            create table jm_aval_count1 as
            select a.*,'['||strip(put(b.jm_aval_count,best.))||']' as evntcnt
            from jm_aval_count101 as a left join jm_Aval_count201 as b
            on a.jm_aval_namen=b.jm_aval_namen;

            create table jm_aval_count2 as
            select a.*,'['||strip(put(b.jm_aval_count,best.))||']' as evntcnt
            from jm_aval_count102 as a left join jm_Aval_count202 as b
            on a.jm_aval_namen=b.jm_aval_namen;

            create table jm_aval_count3 as
            select a.*,'['||strip(put(b.jm_aval_count,best.))||']' as evntcnt
            from jm_aval_count103 as a left join jm_Aval_count203 as b
            on a.jm_aval_namen=b.jm_aval_namen;
         quit;

         data jm_aval_count1;
            set jm_aval_count1;
            jm_aval_countc=strip(jm_Aval_countc)||' '||strip(evntcnt);
         run;

         data jm_aval_count2;
            set jm_aval_count2;
            jm_aval_countc=strip(jm_Aval_countc)||' '||strip(evntcnt);
         run;

         data jm_aval_count3;
            set jm_aval_count3;
            jm_aval_countc=strip(jm_Aval_countc)||' '||strip(evntcnt);
         run;

         proc datasets lib=work memtype=data;
            delete jm_Aval_count101 jm_aval_count102 jm_Aval_count201 jm_aval_count202  jm_Aval_count103 jm_aval_count203;
         run;
         quit;
      %end;
		%else %do;
			proc datasets lib=work;
				change jm_aval_count101=jm_aval_count1 jm_aval_count102=jm_aval_count2 jm_aval_count103=jm_aval_count3;
			run;quit;
		%end;
   %mend;
   %gen_evnt_cnt;                              
                              
   * SET THE DATASETS ;                             
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1,JM_BIGN=,JM_GRPVAR=grpvar);   

   data jm_aval_alldata1;
      set jm_aval_alldata1;
      grp_ord=jm_block;
      jm_Aval_namec=strip(jm_aval_namec);
      if jm_aval_label=:'Number of' and strip(jm_Aval_namec) ne strip(jm_aval_label) then jm_aval_namec=jm_Aval_label;
      if aedecod ne '' and strip(jm_Aval_namec) ne strip(aedecod) then jm_Aval_namec=aedecod;
      if aebodsys ne '' then jm_aval_label=strip(aebodsys);
   run;

   data jm_aval_alldata1;
      set jm_aval_alldata1;
      grp_ord=jm_block;
   run; 

   * TRANSPOSE THE DATASETS ;                             
   %JM_AVAL_SUM_TRANS(
      JM_AVAL_INPUT=jm_aval_alldata1(where=(JM_TYPE='COUNT')),JM_AVAL_OUTPUT=JM_AVAL_TRANS2,                    
      JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC grpvar ,JM_TRANS_VAR=COLVAL,
      JM_TRANS_ID=JM_TRTVARN
      ); 

   * Format the dataset for Indentation and sorting ;                             
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      rec_num=_n_;                        
      block_num=input(jm_block,best.)-100;                        
   run;                        
    
   proc sort data=JM_AVAL_TRANS2;                        
      by block_num jm_block rec_num;                        
   run;                        
    
   data JM_AVAL_TRANS2;                        
      length jm_aval_namec jm_aval_label $2000;                        
      set JM_AVAL_TRANS2;                        
      by block_num;                        
      array mytrtarr{*} $ trtn:;                        
      do i=1 to dim(mytrtarr);                        
         if mytrtarr(i)='' then mytrtarr(i)='0';                        
      end;                        
   run;                        
    
   proc sort data=JM_AVAL_TRANS2;                        
      by block_num rec_num;                        
   run;                        
    
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      by block_num rec_num;                        
      if jm_block='103' then jm_aval_namec='^{nbspace 4}'||strip(jm_aval_namec);                        
   run;                        
    
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      if jm_block='103' and trtn2 not in('','0') then aedecod_lin= input(scan(trtn2,1,'('),best.);                        
      else if jm_block='103' and trtn2 in('0') then aedecod_lin=0;                        
      else aedecod_lin=999999;                        
   run;                        
    
   proc sort data=JM_AVAL_TRANS2;                        
      by jm_block jm_aval_label block_num grpvar descending aedecod_lin rec_num;                        
   run;                        
    
   %macro sort;                            
      *** Get Total subjects per AEDECOD to be used for sorting if needed ***;                             
      proc sql;                             
         create table socptmax_pt_ord as select distinct jm_block,block_num,jm_aval_label,jm_aval_namec,sum(aedecod_lin) 
         as sum_lin from jm_aval_trans2 
         where block_num=3 
         group by jm_block,jm_aval_label,jm_aval_namec 
         order by jm_block,jm_aval_label,%if &tab_sort. eq FREQ %then %do; calculated sum_lin desc, %end; jm_aval_namec;
      quit;                             
       
      data socptmax_pt_ord;                             
         set socptmax_pt_ord;                             
         by jm_block jm_aval_label %if &tab_sort. eq FREQ %then %do; descending sum_lin %end; jm_aval_namec;                             
         if first.jm_aval_label then socptmax_pt_ord=0;                             
         socptmax_pt_ord+1;                             
         retain socptmax_pt_ord;                             
      run;                             
   %mend;
   %sort; 

   proc sql;                             
      create table jm_aval_trans2x as select a.*,b.socptmax_pt_ord,b.sum_lin from jm_aval_trans2 as a left join 
      socptmax_pt_ord as b on a.jm_block=b.jm_block and a.block_num=b.block_num and a.jm_Aval_label=b.jm_aval_label 
      and a.jm_Aval_namec=b.jm_aval_namec;
   quit;                             
    
   data jm_aval_trans2x;                             
      set jm_aval_trans2x;                             
      if jm_block='103' then jm_block='102';                             
      if _name_='' then delete;                             
      jm_aval_namen=input(scan(grpvar,1,':'),best.);                             
      if aedecod_lin ne 999999 and sum_lin ne . and block_num=3 then aedecod_lin=sum_lin;
   run;                             
    
   proc sort data=jm_aval_trans2x;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namec grpvar;                             
   run;                             
    
   data jm_aval_trans2y;                             
      set jm_aval_trans2x(in=a where=(jm_aval_namen=1)) jm_aval_trans2x(in=b) ;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namec grpvar;                             
      if a then do;                             
         jm_aval_namen=0;                             
         rec_num=0;                            
         if block_num eq 3 then jm_aval_namec=tranwrd(jm_aval_namec,'nbspace 2','nbspace 4');
         array mytrtarr{*} $ trtn:;                             
         do i=1 to dim(mytrtarr);                             
            mytrtarr(i)='';                             
            _name_=" ";                             
            _TYPE_=" ";                             
         end;                             
         output;                             
      end;                             
      if b then do;                             
            if block_num ne 3 then jm_aval_namec='^{nbspace 2}'||strip(scan(grpvar,2,':'));                             
            else if block_num eq 3 then jm_aval_namec='^{nbspace 6}'||strip(scan(grpvar,2,':'));                             
         output;                             
      end;                             
   run;  

   proc sort data=jm_aval_trans2y;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namen jm_aval_namec grpvar;                             
   run;                             
    
   data jm_aval_trans2z;                             
      set jm_aval_trans2y;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namen jm_aval_namec grpvar;                             
      retain x 0;                             
      if jm_aval_label ne lag(jm_aval_label) then x+1;                             
      retain x;                             
   run;                             
    
   data jm_aval_trans2zz;                             
      set jm_aval_trans2z;                             
      jm_block=strip(put(100+x,best.));                             
   run;                             
    
   proc sort data=jm_aval_trans2zz;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namen jm_aval_namec grpvar;                             
   run;                             
    
   data jm_aval_trans2zz;                             
      set jm_aval_trans2zz;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namen jm_aval_namec grpvar;                             
      if first.jm_block then xx=0;                             
      xx+1;                            
      retain xx;                             
      jm_aval_namen=xx;                             
      drop xx;                            
   run;                             
    
   data jm_aval_trans2;                             
      set jm_aval_trans2zz;                             
   run;                             
    
   * APPLY PAGEBREAK ;                             
   %JM_PGBRK(
      JM_INDSN1= ,JM_INDSN2=JM_AVAL_TRANS2,JM_BREAKCNT=&tab_page_size.,JM_CONTOPT=Y,JM_GROUPOPT=Y,
      JM_OUTDSN=JM_AVAL_ALLREPORT1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   proc sort data=jm_aval_allreport1;                             
      by pageno jm_block jm_aval_namen;                             
   run;                             
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      by pageno jm_block jm_aval_namen;
      lagpg=lag(pageno); 
      if input(scan(grpvar,1,':'),best.)= &maxfmtval. then do;
         if last.pageno ne 1 then jm_aval_namec=strip(jm_aval_namec)||'^n';
         if pageno ne lagpg then pageno=lagpg; 
      end;
   run;                             
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      array mytrtarr{*} $ trtn:;                             
      do i=1 to dim(mytrtarr);                             
         if input(compress(mytrtarr(i),' ()[]'),best.) eq 0 then mytrtarr(i)='0';                             
         if index(mytrtarr(i),'100.0)') gt 0 then mytrtarr(i)=tranwrd(mytrtarr(i),'100.0)','100)');                             
         if length(strip(scan(mytrtarr(i),2,'(.'))) eq 2 then mytrtarr(i)=tranwrd(mytrtarr(i),'(','( ');
         else if length(strip(scan(mytrtarr(i),2,'(.'))) eq 1 then mytrtarr(i)=tranwrd(mytrtarr(i),'(','(  ');
      end;                             
   run;                             
    
   *ODS OPEN- OPENS RTF DESTINATION ;                             
   %JM_ODSOPEN(JM_OUTREPORT= ,JM_POINTSIZE=,JM_ODSTYPE=rtf,JM_STYLE=OXYSTYLE,JM_BODYTITLEOPT=0);                   

   %JM_TEMPLATES(JM_POINTSIZE=9);     

   *REPORT- PROC REPORT MODULE ;                             
   %JM_AVAL_REPORT(
      JM_INDSN=Jm_aval_allreport1,JM_BIGNDSN=Jm_bign1,JM_COL2VAR=,JM_BREAKVAR=jm_aval_label,JM_BREAKOPT=N,
      JM_INDENTOPT=N,JM_GROUPLABEL=,JM_CELLWIDTH=4.0in,JM_TRTWIDTH=,JM_SPANHEADOPT=Y,JM_BYVAR=,JM_REPTYPE=Table
		);                   

   *ODS CLOSE- CLOSES RTF DESTINATION ;                             
   %JM_ODSCLOSE(JM_ODSTYPE=rtf);      
 
%mend;
%t_ae_soc_pt_stdy_per;
