*************************************************************************
* STUDY DRUG    :   JZP150 
* PROTOCOL NO   :   JZP150-201
* PROGRAMMER    :   Arun Kumar  
* DATE CREATED  :   06SEPT2022
* PROGRAM NAME  :   adae.sas
* DESCRIPTION   :   Produce ADAE ADaM dataset
* DATA SETS USED: 	sdtm.<ae,suppae>, adam.adsl
***************************************************************************
PROGRAM MODIFICATION LOG
***************************************************************************
Programmer: 		
Date:       	
Description: 
****************************************************************************;
dm "clear log"; dm "clear output";

options mprint mlogic symbolgen; 

%setup; 


proc format;
	value mdayf 
		1=31
		3=31
		4=30
		5=31
		6=30
		7=31 
		8=31
		9=30
		10=31
		11=30
		12=31;
run;


%macro parentsupp(lib=sdtm, ds=, qnams=);
	
    %if &qnams eq %then %do;
        proc sql noprint;
            select distinct(qnam) into: qnam separated by ' ' 
            from &lib..supp&ds;
		quit;
	%end;
 
	proc sort data=&lib..supp&ds.  out=_temp_supp&ds.;
	  by usubjid idvarval;
	run;

    proc sort data = &lib..&ds. out=_temp_&ds.;
	  by usubjid %if &ds ne dm %then %do; &ds.seq %end;;
	run;

	proc transpose data=_temp_supp&ds. out=_t_supp&ds.;
	  by usubjid idvarval;
	  id qnam;
      idl qlabel;
	  var qval;
	run;

	data _t_supp&ds. (drop= _: idvarval );
	  set _t_supp&ds.;
	  %if &ds ne dm %then %do; &ds.seq=input(compress(idvarval),8.); %end;
	run;

	proc sort data=_t_supp&ds.;
	  by usubjid %if &ds ne dm %then %do; &ds.seq %end;;
	run;     
	 
	data sdtm&ds.;
	  merge _temp_&ds.(in=a)
	        _t_supp&ds.;
	  by usubjid %if &ds ne dm %then %do; &ds.seq %end;;
	  if a;
	run;

   	proc datasets nolist;
   	   delete _temp_ _t:;
    run; 
	quit;

%mend parentsupp;

***sdtm.ae;
%parentsupp(lib=sdtm, ds=ae, qnams=); 


data sdtmae;
	set sdtmae;
	/***to test imputation
	if aestdtc='2019-12-10' then aestdtc='2019-12';
	if aeendtc='2020-01-27' then aeendtc='2020';remove later***/
	format _all_;
	informat _all_;
run;
proc sort data=sdtmae;
	by studyid usubjid aeseq;
run; 


***adsl;
proc sort data=adam.adsl out=adsl;
	by studyid usubjid;
run;



***to check comp disc from ds;
proc sort data=sdtm.ds out=stncompdt(keep=studyid usubjid dsdecod dsscat dsstdtc rename=(dsstdtc=compdisc));
	where upcase(dscat)='DISPOSITION EVENT'; 
	by studyid usubjid dsstdtc;
run;
data stncompdt;
	set stncompdt;
	by studyid usubjid compdisc;
	if first.usubjid;
	format _all_;
	informat _all_;
run; 



***sdtm.dm;
data sdtmdm;
	set sdtm.dm;
	format _all_;
	informat _all_;
run;
proc sort data=sdtmdm;
	by studyid usubjid;
run; 







***to do imputation for partial dates;
data adae1; 

	merge adsl(in=b) sdtmae(in=a) stncompdt ;
    by studyid usubjid;
	if a and b;



	length trtp trta $40;
	trtp=trt01p;
	if trt01pn ne . then trtpn=trt01pn;
	trta=trt01a;
	if trt01an ne . then trtan=trt01an;

	if rficdtc ne '' then rficdt=input(substr(rficdtc,1,10),is8601da.); 

	if rfstdtc ne '' then rfstdtc_dtc=substr(rfstdtc,1,10);
	if rfxendtc ne '' then rfxendtc_dtc=substr(rfxendtc,1,10);

	if aestdtc ne '' then aestdtc_dtc=substr(aestdtc,1,10);
	if aeendtc ne '' then aeendtc_dtc=substr(aeendtc,1,10);

	if rfstdtc ne '' then do;
	    rfxstdt=input(substr(rfstdtc,1,10),is8601da.);
		dosy=input(substr(rfstdtc,1,4),best.);
		***dosm=input(substr(rfstdtc,6,2),best.);
		dosm=input(scan(rfstdtc, 2, '-'), best8.);
	end;
	if rfxendtc ne '' then do;
	    rfxendt=input(substr(rfxendtc,1,10),is8601da.); 
		rfxendt30c=put((rfxendt+30),is8601da.);
		doey=input(substr(rfxendtc,1,4),best.);
		***doem=input(substr(rfxendtc,6,2),best.);
		doem=input(scan(rfxendtc, 2, '-'), best8.);
		doey30=input(substr(rfxendt30c,1,4),best.);
		***doem30=input(substr(rfxendt30c,6,2),best.);
		doem30=input(scan(rfxendt30c, 2, '-'), best8.);
	end;
	if aestdtc ne '' then do;
		aesy=input(substr(aestdtc,1,4),best.);
		***aesm=input(substr(aestdtc,6,2),best.);
		aesm=input(scan(aestdtc, 2, '-'), best8.);
	end;
	if aeendtc ne '' then do;
		aeey=input(substr(aeendtc,1,4),best.);
		***aeem=input(substr(aeendtc,6,2),best.);
		aeem=input(scan(aeendtc, 2, '-'), best8.);
	end;
run;





***derive ASTDT and ASTDTF;
data adae2;
	length aestart1 aestart2 $20;
	set adae1;
	if length(aestdtc_dtc)=10 then astdt=input(aestdtc_dtc, ??is8601da.);
	***if length(aestdtc)>=10 then astdt=input(substr(aestdtc,1,10),??is8601da.);

	***If Month and Day are missing;
	else do;
		if length(aestdtc_dtc)=4 then do;
			aestart1=strip(aestdtc_dtc)||'-'||'01-01';
			if aesy = dosy then aestart2=rfstdtc_dtc;
			ASTDTF='M';
		end;

		***If only Day is missing;
		else if length(aestdtc_dtc)=7 then do;
			aestart1=strip(aestdtc_dtc)||'-'||'01';
			if aesy = dosy and aesm =dosm then aestart2=rfstdtc_dtc;
			ASTDTF='D';
		end;
	end;

	aestart1_ = input(aestart1, ??is8601da.);
	aestart2_ = input(aestart2, ??is8601da.);

	format aestart1_ aestart2_ e8601da10.;
	drop aestart1 aestart2 ;
run;

data adae3;
	length astdtc $10  AperiodC APERIODW $200.;
	set adae2;
	if astdtf ne '' then do;
		if aestart1_ ne . and aestart2_ ne . then astdt = max(aestart1_, aestart2_);
		else astdt =aestart1_;
	end; 
     
	if astdt eq . then ASTDTC ='';
	else ASTDTC = put(astdt,??is8601da.); 
    
	***rfxstdt=input(substr(rfstdtc,1,10),is8601da.);
	if (astdt ne . ) and (rfxstdt ne . ) then ASTDY = astdt - rfxstdt +(astdt>=rfxstdt);


	/*
The time of first onset of TEAE is calculated as follows: 
	start date of TEAE – Date of first dose of study intervention + 1 day.
  The Intervention Period is assigned if the time of first onset of TEAE is between Day 1 and 84. 
The Safety Follow-Up period is assigned if the time of first onset of TEAE is greater than Day 84.
*/


	if (astdt ne . ) and (rfxstdt ne . ) then APSTDY = astdt - rfxstdt +1;

	if 1<=APSTDY<=84  then do;
	   Aperiod=1;
	   APeriodc="Intervention Period";
	end;
	else if APSTDY>84  then do;
	    Aperiod=2;
	    APeriodc="Safety Follow-Up period";
	end;


	/*
	The time of first onset of TEAE is calculated as follows: start date of TEAE – Date of first dose of study intervention + 1 day. 
	The time of first onset categories are assigned as: 
	Week 1 (Day 1 to 7), Weeks 2 to 4 (day 8 to 28), Weeks 5 to 8 (day 29 to 56), Weeks 9 to 12 (Day 57 to 84) and After Last Dose.
	
*/

	  if 1<=APSTDY<=7  then do;
	  APERIODN=1;
	   APERIODW="Week 1";
	end;
	else if 8<=APSTDY<=28  then do;
	   APERIODN=2;
	   APeriodw="Weeks 2 to 4";
	end;
	else if 29<=APSTDY<=56  then do;
	   APERIODN=3;
	   APeriodw="Weeks 5 to 8";
	end;
	else if 57<=APSTDY<=84  then do;
	   APERIODN=4;
	   APeriodw="Weeks 9 to 12";
	end;
	else if APSTDY>84  then do;
	   APERIODN=5;
	   APeriodw="After Last Dose";
	end;
    
	format astdt e8601da10. ;
	drop aestart1_ aestart2_ ;
run;


***derive AENDT and AENDTF;
data adae4;
	set adae3;
	length  aestop1 /*aestop2*/ $20;
	if length(aeendtc_dtc)=10 then aendt=input(aeendtc_dtc, ??is8601da.);
	***if length(aeendtc)>=10 then aendt=input(substr(aeendtc,1,10),??is8601da.);

	***If Month and Day are missing;
	else do;
		if length(aeendtc_dtc)=4 then do;
			aestop1=strip(aeendtc_dtc)||'-'||'12-31';
			*if aeey = doey then aestop2=put((trtedt +30),yymmdd10.);
			AENDTF='M';
		end;

		***If only Day is missing;
		else if length(aeendtc_dtc)=7 then do;
			aestop1=strip(aeendtc_dtc)||'-'||put(aeem,mdayf.);
			if aeem=2 then do;
				if mod(aeey,4)=0 then aestop1=strip(aeendtc_dtc)||'-29';
				if mod(aeey,4) ^=0 then aestop1=strip(aeendtc_dtc)||'-28';
			end;

			/*** use trtedt +30 only when event month = rfxstdtc_dtc;??
			if aeey = doey and aeem =doem and aeem ne 2 then aestop2=put((rfxendt +30),yymmdd10.);
			or do the below condition regardless of the condition where event month = rfxstdtc_dtc month;?
			** aestop2=put((rfxendt +30),yymmdd10.);???*/
			AENDTF='D';
		end;
	end;

	aestop1_ = input(aestop1, ??is8601da.);
	/*aestop2_ = input(aestop2,yymmdd10.);*/

	format aestop1_ /*aestop2_*/ e8601da10.;
	drop aestop1 /*aestop2*/;
run;

data adae5;
	length aendtc $10;
	set adae4;
	if aendtf ne '' then do;
		/*if aestop1_ ne . and aestop2_ ne . then
		aendt = min(aestop1_, aestop2_);
		else*/ aendt =aestop1_;
	end;

	if aendt eq . then AENDTC ='';
	else AENDTC = put(aendt, ??is8601da.);
 
	***;
	if (aendt ne . ) and (rfxstdt ne . ) then AENDY = aendt - rfxstdt +(aendt>=rfxstdt);
	   
	format aendt  e8601da10. ;
	   
	drop aestop1_ /*aestop2_*/ ; 
run; 



data adae6;
	set adae5;
	***trtemfl;
********** TRTEMFL  **********;
  if . < trtsdt <= astdt <= (trtedt+14) then TRTEMFL="Y";

length ASEV $20.;
if aetoxgr ne "" then do;
atoxgrn=input(aetoxgr,best.);
 atoxgr='GRADE '||strip(AETOXGR);

      if atoxgrn=1 then ASEV="Mild";
 else if atoxgrn=2 then ASEV="Moderate";
 else if atoxgrn=3 then ASEV="Severe";
 else if atoxgrn=4 then ASEV="Life-Threatening";
 else if atoxgrn=4 then ASEV="Fatal";
 ASEVN=atoxgrn;
 end;



	length arel $16;
	arel=upcase(aerel);

	if n(astdt, aendt)=2 then do; 
		adurn=aendt-astdt;  
  		if adurn >=0 then adurn=adurn+1; 
		aduru='Days';
  	end; 

	if atoxgrn in (3 4) then teg34fl='Y';  

	length aesityp $200;
	if upcase(AEDECOD) in ("SOMNOLENCE","COMA","LIMB ATAXIA", "GAIT ATAXIA","POSTURAL ATAXIA",
                           "DYSARTHRIA","NYSTAGMUS","HEADACHE","DIZZINESS","GAIT DISTURBANCE",
                           "SLURRED SPEECH","BLURRED VISION","AMNESIA") then AESI='Y';
	AESITYP='';
	
    if AESI='Y' then AESITYP=strip(AEDECOD);

	if upcase(aeacn)='DRUG WITHDRAWN'   then aediscon='Y'; 
	if upcase(aeacn)='DRUG INTERRUPTED' then aedosint='Y'; 


	label 
	   aediscon="Discontinued from Treatment"
       aedosint="Drug interrupted from Treatment"
	   AENDY="Analysis End Relative Day"
	   /*AEACNOSP="Action Other Specify"*/
       ACTARM="Description of Actual Arm"
	   ACTARMCD="Description of Actual Arm Code"
	   AESI="Adverse Event of Special Intrest"
	   AESITYP="Adverse Event of Special Intrest Type"
	   AESER ="Serious Event"
	   ;
run; 


%*let corevars=STUDYID USUBJID SUBJID SITEID COUNTRY BRTHDTC AGE AGEU AGEGR1 AGEGR1N AGEGR2 AGEGR2N SEX SEXN RACE SUBJIDL AGESEX AGERASEX  ETHNIC ETHNICN WEIGHTBL
              HEIGHTBL BMIBL RFICDTC RFICDT RFXSTDTC RFXENDTC RFSTDTC RFENDTC ACTARM ACTARMCD ARM ARMCD TRT01P TRT01PN TRT01A TRT01AN TRTSDT 
              TRTEDT SAFFL ENRLFL PKFL PDFL RANDFL SCRFL FASFL COMPSFL MFASL PTSDHFL ;



%*let adaevars=AESEQ TRTP TRTPN TRTA TRTAN AETERM AEDECOD AEBODSYS AEBDSYCD AELLTCD AELLT AEPTCD
			AEHLT AEHLTCD AEHLGT AEHLGTCD AESOC AESOCCD AESTDTC ASTDT ASTDTF AEENDTC AENDT ASTDY AENDY 
			AEENRF AESER AESCONG AESDISAB AESDTH AESHOSP AESLIFE AESMIE AEREL VMEDDRA AEDISCON AEDOSINT
			AEACN  AEACNOTH  AEOUT AETOXGR ATOXGR ATOXGRN ASEVN ASEV TRTEMFL AESI AESITYP TEG34FL APSTDY APERIOD APERIODC APERIODN APERIODW; 


data adae7(label="Adverse Events Analysis Dataset"); 
	*retain &corevars &adaevars;
	set adae6;
	*keep &corevars &adaevars;
 	if asev='' then do; asev='Severe'; ASEVN=3; end;

run;


%global ADAM_SPEC_FILE;
%let ADAM_SPEC_FILE=%str(ADaM_DEV_SPECS_JZP_150_201.xlsx);
%jm_read_devspec(jm_domain=ADAE,jm_indsn=adae7,jm_inlib=work, jm_outlib=ADAM );

