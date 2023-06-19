***************************************************************************
Protocol          : All Studies
Program Name      : 
SAS Version       : 9.4
Purpose           : 
Files Used        :
Author            : Jagan Achi
Date Created      : 19Dec2016
Modification History: 
***************************************************************************;
options mprint mlogic symbolgen;

%macro autoexec;
   libname here " ";
   %global gtoplevel;

   data _null_;
      path=pathname("here");
      pos=index(path,"\stat\")+5;
      gtoplevel=substr(path,1,pos);
      call symputx("gtoplevel",gtoplevel);
   run;

   %put &gtoplevel.;
   libname here clear;

   *** Identify the utilities folder ***;
   filename util1 "..\..\..\..\utilities";
   filename util2 "..\..\..\utilities";
   filename util3 "..\..\utilities";
   filename util4 "..\utilities";
   filename util5 ".\utilities";

   *** Identify setup.sas programs ***;
   filename setup1 "..\..\..\..\utilities\setup.sas";
   filename setup2 "..\..\..\utilities\setup.sas";
   filename setup3 "..\..\utilities\setup.sas";
   filename setup4 "..\utilities\setup.sas";
   filename setup5 ".\utilities\setup.sas";

   data _null_;
      *** Identify the closest utility path ***;
      path1 = pathname('util1');
      path2 = pathname('util2');
      path3 = pathname('util3');
      path4 = pathname('util4');
      path5 = pathname('util5');
     if fileexist(path1) then call symput('utilpath',strip(path1));
     if fileexist(path2) then call symput('utilpath',strip(path2));
     if fileexist(path3) then call symput('utilpath',strip(path3));
     if fileexist(path4) then call symput('utilpath',strip(path4));
     if fileexist(path5) then call symput('utilpath',strip(path5));

     *** Idetify the closest setup.sas program ***;
     setup1 = pathname('setup1');
     setup2 = pathname('setup2');
     setup3 = pathname('setup3');
     setup4 = pathname('setup4');
     setup5 = pathname('setup5');
      if fileexist(setup1) then call symput('setupprog',strip(setup1));
      if fileexist(setup2) then call symput('setupprog',strip(setup2));
      if fileexist(setup3) then call symput('setupprog',strip(setup3));
      if fileexist(setup4) then call symput('setupprog',strip(setup4));
      if fileexist(setup5) then call symput('setupprog',strip(setup5));
   run;
   
   *** Clear temporary filenames ***;
   filename util1;
   filename util2;
   filename util3;
   filename util4;
   filename util5;
 
   options Mautosource
   sasautos=(sasautos "&utilpath");
   %include "&setupprog";
%mend autoexec;

%autoexec;
