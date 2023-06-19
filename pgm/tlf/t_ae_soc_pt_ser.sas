/*************************************************************************      
 * STUDY DRUG:        Global Template Programs/Macros
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      08/29/2022
 * PROGRAM NAME:      t_ae_soc_pt_001.sas
 * DESCRIPTION:       Template program to create "Treatment-Emergent Adverse Events by System Organ Class and Preferred Term" Table
 * DATA SETS USED:    
 * Parameter: TRTVAR          - Treatment Varibale Name (char). EX: if dataset has TRTAN, TRTA, pls specify TRTA
 *            TAB_PAGE_SIZE   - PAGESIZE to be plugged into JM_PBGRK. ex: 12
 *            TAB_EVENT_COUNT - Display AE Event Counts Y or N ex: Y - to display event counts
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
%include "&macpath.\call_sandbox_macs.sas";
options orientation=landscape missing=' ' nodate nonumber;

%macro t_ae_soc_pt_ser(trtvar=TRT01A,tab_page_size=16,Tab_Event_Count_YN=N,tab_sort=FREQ,
                       adsl_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y'),
                       adae_subset=%str(&TRTVAR.N in (1,2,3) and SAFFL='Y' and TRTEMFL='Y' and AESER="Y")
                       );
 
   *TITLE AND FOOTNOTES;
   %JM_TF (jm_infile=&tocpath., JM_PROG_NAME= %jm_get_pgmname,JM_PRODUCE_STATEMENTS=Y);
 
   *DELETE TABLE FROM TLFDATA OF PREVIOUS ITERATION;
   %JM_DATAPREP;

   **Call Pre-processing Macro **;   
   %jm_tlf_pre(dtnames=adsl adae);

   data _null_;
      evntcnt="&tab_event_count_yn.";
      if upcase(evntcnt)='Y' then tab_box='System Organ Class, n (%) [E]|Preferred Term, n (%) [E]';
      else tab_box='System Organ Class, n (%)|Preferred Term, n (%)';
      *** Create Global macro parameters for _DEFAULT_BOX & _DEFAULT_SPAN_HEAD ***;
      call symputx("_DEFAULT_BOX",strip(tranwrd(tab_box,'|','|  ')),'g');
      call symputx("_DEFAULT_BOXX",strip(tranwrd(tab_box,'|','|  ')),'g');
   run; 

	%let _default_span_head=(("^R'\brdrb\brdrs\brdrw4 ' Treatment Group" trtn1 trtn2 trtn3)  trtn99);
   *** Create TOTAL Treatment column as well. Total Treatment number is set to 99 ***;                              
   data ADSL;                             
      set ADSL;                             
      where &adsl_subset.;                             
      trtn=&trtvar.N;                             
      trt=&trtvar.;                             
      output; 
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="Total";                            
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
      trtn=&trtvar.N;                             
      trt=&trtvar.;                             
      output;    
      if trtn in (1,2 ) ; 
      trtn=99;                             
      trt="Total";                            
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
   %jm_gen_trt_fmt;
 
   *** Create JM_BIGN(n) by calling JM_BIGN macro. The number of JM_BIGN datasets ***;                               
   %JM_BIGN(JM_INDSN=target,JM_CNTVAR=usubjid,JM_TRTVARN=trtn,JM_TRTFMT=trt,JM_BIGN_WHERE=%bquote(saffl='Y'),JM_SUFFIX=1);                   

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y',JM_VAR=TRTEMFL,                    
      JM_AVAL_LABEL=Number of participants with at least one TEAE,JM_BLOCK=101,JM_TRTVARN=trtn
      );

	  	proc sql;
	  select * from jm_aval_count101;
	quit;

	%if &sqlobs. gt 0 %then %do;

   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aebodsys ne '',
      JM_VAR=aebodsys,                    
      JM_AVAL_LABEL=System organ Class,JM_BLOCK=102,JM_TRTVARN=trtn
      );
 
   %JM_AVAL_COUNT(
      JM_INDSN=target,JM_CNTVAR=usubjid,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '',
      JM_VAR=aedecod, JM_BYVAR=aebodsys,                   
      JM_AVAL_LABEL=Preferred Term,JM_BLOCK=103,JM_TRTVARN=trtn
      );

   **Get event counts **;
   %macro gen_evnt_cnt;
      %if &Tab_Event_Count_YN.=Y %then %do;
         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y',JM_VAR=TRTEMFL,                    
            JM_AVAL_LABEL=Number of participants cnt,JM_BLOCK=201,JM_TRTVARN=trtn
            );

         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aebodsys ne '',
            JM_VAR=aebodsys,                    
            JM_AVAL_LABEL=System organ Class cnt,JM_BLOCK=202,JM_TRTVARN=trtn
            );
 
         %JM_AVAL_COUNT(
            JM_INDSN=target,JM_CNTVAR=evnt,JM_BIGN=jm_bign1,JM_SECONDARY_WHERE=trtemfl='Y' and aedecod ne '',
            JM_VAR=aedecod, JM_BYVAR=aebodsys,                   
            JM_AVAL_LABEL=Preferred Term cnt,JM_BLOCK=203,JM_TRTVARN=trtn
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
           delete jm_Aval_count101 jm_aval_count102 jm_aval_count103 jm_Aval_count201 jm_aval_count202 jm_aval_count203;
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

   data jm_aval_count2;                             
      set jm_aval_count2(in=a) jm_aval_count3(in=b);                             
      grp_ord=jm_block;                             
      jm_aval_label=strip(jm_aval_namec);                             
      if b then jm_aval_namec=strip(grpvar);                             
      jm_Aval_namec=strip(jm_Aval_namec);                             
      jm_block=strip(put(103,best.));                             
   run;                             
    
   proc datasets lib=work memtype=data noprint;                             
      delete jm_aval_count3;                             
   run;                             
   quit;   
 
   * SET THE DATASETS ;                                                         
   %JM_AVAL_ALLDATA(JM_OUTDSN=JM_AVAL_ALLDATA1,JM_BIGN=,JM_GRPVAR=grpvar);                   
                               
   * TRANSPOSE THE DATASETS ;                                                        
   %JM_AVAL_SUM_TRANS(
      JM_AVAL_INPUT=jm_aval_alldata1(where=(JM_TYPE='COUNT')),JM_AVAL_OUTPUT=JM_AVAL_TRANS2,                    
      JM_TRANS_BY=JM_BLOCK JM_AVAL_LABEL JM_AVAL_NAMEC grpvar grp_ord,JM_TRANS_VAR=COLVAL,
      JM_TRANS_ID=JM_TRTVARN
      );                   
                          
   * Format the dataset for Indentation and sorting ;                                                       
   data JM_AVAL_TRANS2;                        
      set JM_AVAL_TRANS2;                        
      rec_num=_n_;                        
      block_num=input(jm_block,best.)-100;                        
      if jm_block=strip(put(103,best.)) and strip(jm_aval_namec)=strip(jm_Aval_label) and jm_block ne grp_ord then 
      block_num=input(jm_block,best.)-100-1;                        
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
      if jm_block='101' then grp_ord=jm_block;
      if grp_ord='101' then jm_aval_namec=strip(jm_aval_label); 
      if grp_ord='103' then jm_aval_namec='^{nbspace 2}'||strip(jm_aval_namec);                        
      if grp_ord='103' and trtn2 not in('','0') then aedecod_lin= input(scan(trtn2,1,'('),best.);                        
      else if grp_ord='103' and trtn2 in('0') then aedecod_lin=0;                        
      else aedecod_lin=999999;                        
   run;                        

   proc sort data=JM_AVAL_TRANS2;                        
      by jm_block jm_aval_label block_num grpvar descending aedecod_lin rec_num;                        
   run; 

   *** Get Total subjects per AEDECOD to be used for sorting if needed ***;  
   %macro sort;                           
      proc sql;                             
         create table socptmax_pt_ord as select distinct jm_block,block_num,jm_aval_label,jm_aval_namec,sum(aedecod_lin) as sum_lin from jm_aval_trans2 
         where block_num=3 group by jm_block,jm_aval_label,jm_aval_namec order by                              
         jm_block,jm_aval_label, %if &tab_sort. eq FREQ %then %do; calculated sum_lin desc, %end; jm_aval_namec;
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
      socptmax_pt_ord as b on a.jm_block=b.jm_block and a.block_num=b.block_num and a.jm_Aval_label=b.jm_aval_label and                              
      a.jm_Aval_namec=b.jm_aval_namec;
   quit;                             
    
   data jm_aval_trans2x;                             
      set jm_aval_trans2x;                             
      if _name_='' then delete;                             
      if aedecod_lin ne 999999 and sum_lin ne . and block_num=3 then aedecod_lin=sum_lin;
   run;                             
    
   proc sort data=jm_aval_trans2x;                             
      by jm_block jm_aval_label block_num socptmax_pt_ord jm_aval_namec grpvar;                             
   run; 
                           
   * APPLY PAGEBREAK ;                                                         
   %JM_PGBRK(
      JM_INDSN1= ,JM_INDSN2=JM_AVAL_TRANS2x,JM_BREAKCNT=&tab_page_size.,JM_CONTOPT=Y,JM_GROUPOPT=Y,
      JM_OUTDSN=JM_AVAL_ALLREPORT1,JM_REPTYPE=Table,JM_FCOL_WIDTH=55
      );

   proc sql noprint;                             
      select max(pageno) into: max_page_allrep1 from jm_aval_allreport1;                             
   quit;                             
 
   proc sort data=jm_aval_allreport1;                             
      by pageno jm_block jm_aval_label block_num descending aedecod_lin rec_num jm_aval_namen;                             
   run;                             
 
   data jm_aval_allreport1;                             
      set jm_aval_allreport1;                             
      by pageno jm_block jm_aval_label block_num descending aedecod_lin rec_num jm_aval_namen;                             
      if last.jm_aval_label and last.pageno ne 1 then jm_aval_namec=strip(jm_aval_namec)||'^n';                             
      if first.jm_aval_label then new_rec_cnt=0;                             
      else new_rec_cnt+1;                             
      retain new_rec_cnt;                            
      jm_aval_namen=new_rec_cnt;                             
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
    %end;
	%else %do;
	  data _null_;
	    set jm_bign1 end=eos;
		 length trttxt $100;
		 if _n_=1 then trttxt='trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 else trttxt=strip(trttxt)||'trtn'||strip(put(jm_trtvarn,best.))||"='';";
		 retain trttxt;
		 if eos then call symputx("trtimp",strip(trttxt));
		run;

		data jm_aval_allreport1;
			_TYPE_='FREQ';
			jm_aval_namec='No data to report';
			jm_aval_label='No data to report';
			jm_block='100';
			jm_aval_countc='';
			pageno=1;
			&trtimp.;
		run;
	%end;                        
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
%t_ae_soc_pt_ser; 
