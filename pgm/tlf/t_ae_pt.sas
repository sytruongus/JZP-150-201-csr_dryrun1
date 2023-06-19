 /*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08/29/2022
 * PROGRAM NAME:      t_ae_pt_001.sas
 * DESCRIPTION:       Template program to create "Treatment-Emergent Adverse Events by Preferred Term" Table
 * DATA SETS USED:    ADSL, ADAE
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
 *            TAB_EVENT_COUNT - Display AE Event Counts Y or N ex: Y - to display event counts
 *            TAB_SORT        - Sorting order. can take FREQ or missing. FREQ - Descending order of PT
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

%macro t_ae_pt(trtvar=TRT01A,tab_page_size=19,Tab_Event_Count_YN=N,tab_sort=FREQ,
                   adsl_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y'),
                   adae_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y' and TRTEMFL='Y')
                   );

   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);
    
   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;
    
   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl adae);
    
   %global _DEFAULT_BOX _DEFAULT_BOXX _DEFAULT_SPAN_HEAD _DEFAULT_BYVARS;

   data _null_;
      evntcnt="&tab_event_count_yn.";
      if upcase(evntcnt)='Y' then tab_box='Preferred Term, n (%) [E]';
      else tab_box='Preferred Term, n (%)';
      tab_span_header='Treatment Group';

	  
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_SPAN_HEAD",strip(tab_span_header)||' ^{nbspace 33} ^n');
   run;
   %let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                             
   data ADSL;                             
      set ADSL;                             
      where &adsl_subset. ;                             
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
      where &adae_subset. ; 
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
    
   *** Create TARGET dataset by combing the Working datasets ***;                             
   data target;                             
      merge ADSL(in= a) ADAE (in= b);                             
      by studyid usubjid trtn trt;                             
      if a;                             
   run;                             
    
   ** Create Treatment formats for reporting **;
   %jm_gen_trt_fmt(jm_indsn=target,jm_intrtvar=trt);

   *** Create JM_BIGN(n) by calling JM_BIGN macro. ***;                             
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(saffl='Y'),JM_SUFFIX=1);                   

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y',JM_VAR=TRTEMFL,                    
      JM_AVAL_LABEL=Number of participants with at least one TEAE,JM_BLOCK=101,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '',
      JM_VAR=aedecod,                    
      JM_AVAL_LABEL=Preferred Term,JM_BLOCK=102,JM_TRTVARN=trtn
      );

   **Get event counts **;
   %macro gen_evnt_cnt;
      %if &Tab_Event_Count_YN.=Y %then %do;
         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y',JM_VAR=TRTEMFL,                    
            JM_AVAL_LABEL=evnt_tot,JM_BLOCK=201,JM_TRTVARN=trtn
            );

         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '',
            JM_VAR=aedecod,JM_AVAL_LABEL=event_pt,JM_BLOCK=202,JM_TRTVARN=trtn
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
         quit;

         data jm_aval_count1;
           set jm_aval_count1;
           jm_aval_countc=strip(jm_Aval_countc)||' '||strip(evntcnt);
         run;

         data jm_aval_count2;
           set jm_aval_count2;
           jm_aval_countc=strip(jm_Aval_countc)||' '||strip(evntcnt);
         run;

         proc datasets lib=work memtype=data;
           delete jm_Aval_count101 jm_aval_count102 jm_Aval_count201 jm_aval_count202;
         run;
         quit;
      %end;
   %mend;
   %gen_evnt_cnt;

   * Apply PROC TEMPLATE code for setting style elements ;                             
   %JM_TEMPLATES(JM_POINTSIZE= );    

   * SET THE DATASETS ;                             
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1,JM_BIGN=,JM_GRPVAR=grpvar);                   

   * TRANSPOSE THE DATASETS ;                             
   %JM_AVAL_SUM_TRANS(
      JM_AVAL_INPUT=jm_aval_alldata1(where=(JM_TYPE='COUNT')),JM_AVAL_OUTPUT=JM_AVAL_TRANS2,                    
      JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC,JM_TRANS_VAR=COLVAL,
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
      if block_num=2 then jm_aval_label=strip(jm_aval_namec);                        
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
      if block_num=2 then jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);                        
   run;                        
    
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      if block_num=2 and trtn2 not in('','0') then aedecod_lin= input(scan(trtn2,1,'('),best.);                        
      else if block_num=2 and trtn2 in('0') then aedecod_lin=0;                        
      else aedecod_lin=999999;                        
       if block_num=1 then jm_aval_namec=strip(jm_aval_label)||'^n';                             
   run;   
 
   %macro sort; 
      proc sort data=JM_AVAL_TRANS2;                        
         by jm_block block_num %if &tab_sort. eq FREQ %then %do; descending aedecod_lin %end; jm_aval_label rec_num;                        
      run;
   %mend;
   %sort;

   * APPLY PAGEBREAK ;                             
   %JM_PGBRK(
      JM_INDSN1= ,JM_INDSN2=JM_AVAL_TRANS2,JM_BREAKCNT=&tab_page_size.,JM_CONTOPT=Y,JM_GROUPOPT=Y,
      JM_OUTDSN=JM_AVAL_ALLREPORT1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

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
      JM_INDENTOPT=N,JM_GROUPLABEL=,JM_CELLWIDTH=,JM_TRTWIDTH=,JM_SPANHEADOPT=Y,JM_BYVAR=,JM_REPTYPE=Table);                   

   *ODS CLOSE- CLOSES RTF DESTINATION ;                             
   %JM_ODSCLOSE(JM_ODSTYPE=rtf);  

%mend; 
%t_ae_pt;
