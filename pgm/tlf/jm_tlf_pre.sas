/*************************************************************************      
 * STUDY DRUG:        Global
 * PROTOCOL NO:       Global  
 * PROGRAMMER:        Vijay Koduru
 * DATE CREATED:      8/17/2022
 * PROGRAM NAME:      t_dispo_001.sas
 * DESCRIPTION:       Pre-processign macro to be copied to study level and update as needed
 * DATA SETS USED:    
 * Parameter: DTNAMES - List of Space seperated datasets to be copied from ADAM library to WORK.
 *								if this macro parameter is missing then all datasets from ADAM will be copied to WORK.
 ************************************************************************
PROGRAM MODIFICATION LOG
*************************************************************************
Programmer:  
Date:        
Description: 
*************************************************************************/

%macro jm_tlf_pre(dtnames=);

***USER DEFNIED FORMATS;
%jm_fmt;

***DEFAULTS FOR THE TLFS;
%GLOBAL  _default_twips default_fontsize _DEFAULT_BOX _DEFAULT_BOXX _DEFAULT_SPAN_HEAD _DEFAULT_BYVARS;

%LET _BIGN_DSN  =ADSL;
%LET _BIGN_TRTVAR=TRTN;
%LET _BIGN_TRT_FMT=TRT;
%LET _DEFAULT_BYVARS=;
%LET _COUNT_DSET=ADSL;
%LET _SUMM_DSET=ADSL;
%LET _default_twips=560;
%LET default_fontsize=9;
%LET _DEFAULT_SPAN_HEAD=;
%LET _DEFAULT_WHERE=;
%LET _BIGN_WHERE=;
%let jm_pointsize=8;

ods escapechar="^";

proc copy in=adam out=work memtype=data;
%if &dtnames. ne %str() %then %do; select &dtnames.;%end;
run;




data adae;
  set adam.adae;
  if AEOUT in ("NOT RECOVERED/NOT RESOLVED","RECOVERING/RESOLVING" ) then AE_R1="Y";
  if AEOUT in ("NOT RECOVERED/NOT RESOLVED")                         then AE_R2="Y";
  if AEOUT in ("RECOVERING/RESOLVING" )                              then AE_R3="Y";
  IF MISSING(AEBODSYS) THEN AEBODSYS="NOT CODED AEBODYSYS";
  IF MISSING(AEDECOD) THEN AEDECOD="*NOT CODED AEDECOD";
  AREL=AEREL;

run;
proc sql;
  **Get max grade with in each subject **;
  create table maxgrpt as
  select distinct usubjid,max(ASEVN) as maxgr_pt
  from adae 
  group by usubjid;

  **Get max rel ae grade with in each subject **;
  create table maxgr_rel as
  select distinct usubjid,max(ASEVN) as maxgr_rel
  from adae where upcase(AREL) ='RELATED'
  group by usubjid;

  **Get max grade with in each subject and within each period **;
  create table maxgrpt_per as
  select distinct usubjid,aperiod,max(ASEVN) as maxgrpt_per
  from adae 
  group by usubjid,aperiod;

  **Get max rel ae grade with in each subject **;
  create table maxgr_rel_per as
  select distinct usubjid,aperiod,max(ASEVN) as maxgr_rel_per
  from adae where upcase(AREL) ='RELATED'
  group by usubjid,aperiod;
quit;
data adae;
  merge adae maxgrpt maxgr_rel;
  by usubjid;
run;
proc sort data=adae;by usubjid aperiod;run;
data adae;
  merge adae maxgrpt_per maxgr_rel_per;
  by usubjid aperiod;
run;



data adcm;
  set adam.adcm;
  length cmtext $2000;
  IF MISSING(cmatc4) THEN cmatc4="NOT CODED CM";
  IF MISSING(cmdecod) THEN cmdecod="*NOT CODED drugname";
  if cmdecod ne '' then cmdecod=tranwrd(cmdecod,';','; ');
  cmtext=catx("*",cmatc4,cmdecod);
run;

%mend; 
