 /*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08/29/2022
 * PROGRAM NAME:      t_ae_overall_001.sas
 * DESCRIPTION:       Template program to create "Overall Summary of Treatment-Emergent Adverse Events" Table
 * DATA SETS USED:    ADSL, ADAE
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
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

data row_meta;
   INFILE DATALINES DLM=',' DSD;
   length row_text $200 row_var row_fmt $20;
   INPUT Row_Block Row_text Row_Var Row_fmt Row_label_line$ Row_Indent Row_Pageno; 
   datalines;
   1,Participants with at least one,,,Y,,1
   1,TEAE,TRTEMFL,,,2,1
   1,Serious TEAE,AESER,,,2,1
   1,Severe Life-Threatening and Fatal serious TEAE,AESER,,,2,1
   1,Treatment-related TEAE,AREL,,,2,1
   1,Serious treatment-related TEAE,AESER,,,2,1
   1,Severe Life-Threatening and Fatal Serious treatment-related TEAE,AESER,,,2,1
   2,Maximum severity of TEAE,maxgr_pt,aetoxgr,Y,,1
   2,Maximum severity of treatment-related TEAE,maxgr_rel,aetoxgr,Y,,2
   3,Participants with at least one TEAE leading to ,,,Y,,2
   3,Study treatment discontinuation,AEACN,,,2,2
   3,Study treatment interruption,AEACN,,,2,2
   3,Study treatment reduction,AEACN,,,2,2
   3,Study treatment increase,AEACN,,,2,2
   4,Participants with at least one TEAE outcome of,,,Y,,3
   4,Not recovered or recovering/resolving,AE_R1,,,2,3
   4,Not recovered,AE_R2,,,2,3
   4,Recovering/resolving,AE_R3,,,2,3
   5,Participants with a fatal TEAE,AESDTH,,,,3
   ;
run;

data row_meta;
   set row_meta;
   block_num=_n_;
run;

%macro t_ae_overall(trtvar=TRT01A,tab_page_size=12,
                           adsl_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y'),
                           adae_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y' and TRTEMFL='Y')
                           );

   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath.,JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);
    
   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;   
   %JM_DATAPREP;
    
   **Call Pre-processing Macro **;
   %jm_tlf_pre(dtnames=adsl adae);
    
   %global _DEFAULT_BOX _DEFAULT_BOXX _DEFAULT_SPAN_HEAD _DEFAULT_BYVARS;
   data _null_;
      tab_box='Total Number, n (%)';
      tab_span_header='Baseline Medication Group';
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

   *** Create JM_BIGN(n) by calling JM_BIGN macro.**;
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(saffl='Y'),JM_SUFFIX=1);                   
                             
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y',JM_VAR=TRTEMFL,                    
      JM_AVAL_LABEL=TEAE,JM_BLOCK=102,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=AESER ='Y',JM_VAR=AESER,                    
      JM_AVAL_LABEL=Serious TEAE,JM_BLOCK=103,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=AESER ='Y' and atoxgrn >=3,
      JM_VAR=AESER,JM_AVAL_LABEL=Severe Life-Threatening and Fatal serious TEAE,JM_BLOCK=104,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=upcase(AREL) ='RELATED',
      JM_VAR=AREL,JM_AVAL_LABEL=Treatment-related TEAE,JM_BLOCK=105,JM_TRTVARN=trtn
      );
                            
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AESER ='Y' and upcase(AREL) ='RELATED',
      JM_VAR=AESER,JM_AVAL_LABEL=Serious treatment-related TEAE,JM_BLOCK=106,JM_TRTVARN=trtn
      );
                             
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AESER ='Y' and upcase(AREL) ='RELATED' and atoxgrn >=3,
      JM_VAR=AESER,JM_AVAL_LABEL=Severe Life-Threatening and Fatal Serious treatment-related TEAE,JM_BLOCK=107,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=maxgr_pt ne .,
      JM_VAR=maxgr_pt,JM_FMT=aesev.,JM_AVAL_LABEL=Maximum severity of TEAE,JM_BLOCK=108,JM_TRTVARN=trtn
      );
                          
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=maxgr_rel ne . And upcase(AREL) ='RELATED',
      JM_VAR=maxgr_rel,JM_FMT=aesev.,JM_AVAL_LABEL=Maximum severity of treatment-related TEAE,
      JM_BLOCK=109,JM_TRTVARN=trtn
      );
                               
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AEACN ='DRUG WITHDRAWN',
      JM_VAR=AEACN,JM_AVAL_LABEL=Study treatment discontinuation,JM_BLOCK=111,JM_TRTVARN=trtn
      );
                              
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AEACN ='DRUG INTERRUPTED',
      JM_VAR=AEACN,JM_AVAL_LABEL=Study treatment interruption,JM_BLOCK=112,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AEACN ='DOSE REDUCED',
      JM_VAR=AEACN,JM_AVAL_LABEL=Study treatment reduction,JM_BLOCK=113,JM_TRTVARN=trtn
      );
                              
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AEACN ='DOSE INCREASED',
      JM_VAR=AEACN,JM_AVAL_LABEL=Study treatment increase,JM_BLOCK=114,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AE_R1 ='Y',
      JM_VAR=AE_R1,JM_AVAL_LABEL=Not recovered or recovering/resolving,JM_BLOCK=116,JM_TRTVARN=trtn
      );
                               
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AE_R2 ='Y',
      JM_VAR=AE_R2,JM_AVAL_LABEL=Not recovered,JM_BLOCK=117,JM_TRTVARN=trtn
      );

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=AE_R3 ='Y',
      JM_VAR=AE_R3,JM_AVAL_LABEL=Recovering/resolving,JM_BLOCK=118,JM_TRTVARN=trtn
      );
                             
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,
      JM_SECONDARY_WHERE=aesdth='Y',
      JM_VAR=AESDTH,JM_AVAL_LABEL=Participants with a fatal TEAE,JM_BLOCK=119,JM_TRTVARN=trtn
      );
   * Apply PROC TEMPLATE code for setting style elements ;                             
   %JM_TEMPLATES;

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
    
   proc sort data=row_meta;                        
      by block_num;
   run;                        

   data JM_AVAL_TRANS2;                        
      length jm_aval_namec jm_aval_label $2000;                        
      merge JM_AVAL_TRANS2 row_meta;                        
      by block_num;                        
      if lowcase(row_summary) eq 'summ' then delete;                        
      if row_label_line='Y' and row_text ne jm_aval_label then jm_aval_label=row_text;                        
      if row_var eq '' or (row_var ne '' and jm_aval_label eq '') then do;                        
         jm_block=strip(put(100+block_num,best.));                        
         jm_aval_label=strip(row_text);                        
         jm_aval_namec=jm_aval_label;                        
      end;                        
      if row_label_line ne 'Y' and row_text ne '' then jm_aval_namec=jm_aval_label;                        
      array mytrtarr{*} $ trtn:;                        
      do i=1 to dim(mytrtarr);                        
         if row_var ne '' and mytrtarr(i)='' then mytrtarr(i)='0';                        
         if row_PCT='N' then mytrtarr(i)=strip(scan(mytrtarr(i),1,'('));                        
         if Row_Total_only='Y' and lowcase(vname(mytrtarr(i))) ne 'trtn99' then do;                        
            mytrtarr(i)='';                        
            _name_=" ";                        
            _TYPE_=" ";                        
         end;                        
      end;                        
      if row_fmt ne '' then do;                        
         jm_aval_namen=input(strip(scan(compbl(jm_aval_namec),1,':')),best.);                        
         jm_aval_namec=strip(scan(compbl(jm_aval_namec),2,':'));                        
      end;                        
   run;                        
    
   proc sort data=JM_AVAL_TRANS2;                        
      by block_num rec_num;                        
   run;                        
    
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      by block_num rec_num;                        
      indent_vtype=vtype(row_indent);                        
      if row_indent not in(.,0) and row_label_line ne 'Y' then jm_aval_namec='^{nbspace '||strip(put(row_indent,best.))||'}'||strip(jm_aval_namec);                        
      else if row_indent not in(.,0) and row_label_line eq 'Y' then jm_aval_namec='^{nbspace '||strip(put(row_indent+2,best.))||'}'||strip(jm_aval_namec);                        
      else if row_indent in(.,0) and row_label_line eq 'Y' and row_var ne '' then jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);                        
      output;                        
      array mytrtarr{*} $ trtn:;                        
      if first.block_num and row_var ne '' and row_label_line='Y' then do;                        
         jm_aval_namen=0;                        
         jm_aval_namec=jm_Aval_label;                        
         if row_indent not in('','0') and row_label_line eq 'Y' then jm_aval_namec='^{nbspace '||strip(row_indent)||'}'||strip(jm_aval_namec);                        
         rec_num=0;                        
         do i=1 to dim(mytrtarr);                        
            mytrtarr(i)='';                        
            _name_=" ";                        
            _TYPE_=" ";                        
         end;                        
         output;                        
      end;                        
      drop i;                        
   run;                        
    
   proc sort data=JM_AVAL_TRANS2;                        
      by row_block block_num jm_block rec_num jm_aval_namen;                       
   run;                       
    
   * APPLY PAGEBREAK ;                             
   %JM_PGBRK(
      JM_INDSN1= ,JM_INDSN2=JM_AVAL_TRANS2,JM_BREAKCNT=&tab_page_size.,JM_CONTOPT=,JM_GROUPOPT=Y,
      JM_OUTDSN=JM_AVAL_ALLREPORT1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   proc sql noprint;                             
      select max(pageno) into: max_page_allrep1 from jm_aval_allreport1;                             
   quit;                             
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      if &max_page_allrep1. eq 1 and _n_ > &tab_page_size. then pageno=ceil(_n_/&tab_page_size.);                             
      else if &max_page_allrep1. gt 1 then pageno=pageno;                             
      else pageno=1;                             
   run;                             
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      if pageno=. then pageno=0;                             
      if row_pageno ne . then pageno=row_pageno;                             
   run;                             
    
   proc sort data=jm_aval_allreport1;                             
      by pageno row_block block_num jm_block rec_num jm_aval_namen;                            
   run;                            
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      by pageno row_block block_num jm_block rec_num jm_aval_namen;                             
      if last.row_block and last.pageno ne 1 and row_var ne '' then jm_aval_namec=strip(jm_aval_namec)||'^n';                             
   run;                             
    
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      array mytrtarr{*} $ trtn:;                             
      do i=1 to dim(mytrtarr);                             
         if mytrtarr(i)='0 (0)' then mytrtarr(i)='0';                             
         if index(mytrtarr(i),'100.0)') gt 0 then mytrtarr(i)=tranwrd(mytrtarr(i),'100.0)','100)');                             
      end;                             
      if lowcase(row_var)='cmdecod' then jm_aval_namec=tranwrd(jm_aval_namec,'; ',';');                             
   run;                             
    
   *ODS OPEN- OPENS RTF DESTINATION ;                             
   %JM_ODSOPEN(JM_OUTREPORT= ,JM_POINTSIZE=,JM_ODSTYPE=rtf,JM_STYLE=OXYSTYLE,JM_BODYTITLEOPT=0);                   

   %JM_TEMPLATES(JM_POINTSIZE=9);     

   *REPORT- PROC REPORT MODULE ;                             
   %JM_AVAL_REPORT(
      JM_INDSN=Jm_aval_allreport1,JM_BIGNDSN=Jm_bign1,JM_COL2VAR=,JM_BREAKVAR=pageno,JM_BREAKOPT=N,
      JM_INDENTOPT=N,JM_GROUPLABEL=,JM_CELLWIDTH=,JM_TRTWIDTH=,JM_SPANHEADOPT=Y,JM_BYVAR=,JM_REPTYPE=Table);                   

   *ODS CLOSE- CLOSES RTF DESTINATION ;                             
   %JM_ODSCLOSE(JM_ODSTYPE=rtf);      
 
%mend;
%t_ae_overall;
