


*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 OTHER/SPECIFY                                                                                              **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE ADULT OTHER/SPECIFY DATASETS MACRO
      %Make_Adult_OtherSpec
      use FINAL
          = FINAL_QAxx
         -> OTHER_SPEC
      use data step to create FINAL from FINAL_QAxx before run macro
      use data step to create OTHER_SPEC_QAxx after run macro

   3. MAKE CHILD OTHER/SPECIFY DATASETS MACRO
      %Make_Child_OtherSpec
      use FINAL
          = FINAL_QCxx
         -> OTHER_SPEC
      use data step to create FINAL from FINAL_QCxx before run macro
      use data step to create OTHER_SPEC_QCxx after run macro

   4. REPORT ADULT OTHER/SPECIFY MACROS
      %Rpt_Adult_OtherSpec
      proc print

   5. REPORT ADULT OTHER/SPECIFY MACROS
      %Rpt_Child_OtherSpec
      proc print


   6. RUN MACROS AND SET UP ODS
      %Sheetname(shtname)
         -> set sheetname per report macro
      Store output path/file name macros for output
      Open ODS sandwich
      1. Run %Sheetname
      2. Run data step to make FINAL for adult qtr
      3. Run %Make_Adult_OtherSpec for adult qtr
      4. Run %Rpt_Adult_OtherSpec for adult qtr
      5. Repeat 2-4 for next quarter
      6. Run data step to make FINAL for child qtr
      7. Run %Make_Child_OtherSpec for child qtr
      8. Run %Rpt_Child_OtherSpec for child qtr
      9. Repeat 6-8 for next quarter
      Close ODS sandwich

*/


/* set up ref and source dataset */
%include "C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY11_REPORT\SASProgs\NZHSRpt11_INITIALISE.sas";

/* create output filename */
%let ods_file=NZHS_Y11_OtherSpecify.xlsx;



/* block out put %include macros to log */
%if 0 %then %do;

/*  check macros from NZHSRpt11_INITIALISE */
%put &=path_out;     * output path ;
%put &=qtr_in;       * current reporting quarters ;
%put &=yr_is;        * current reporting year ;
%put &=key_NZHS;     * by key ;
%put &=ods_file;     * output file ;


%end;
/* end block out put %include macros to log */



********** MAKE ADULT OTHER/SPECIFY DATASETS MACROS **********;

%macro Make_Adult_OtherSpec;

/* drop derived vars from final (not other-specify questionnaire variables) */
%let drop_derived=Other_Asian Other_Pacific Euro_Other;

/* get variable names from SURVEYS */
proc contents
      data=FINAL(drop=&drop_derived)
      out=NAMES
      noprint;
run;

/* sort variable names by varnum (PDV order) */
proc sort data=NAMES(keep=name--format);
   by varnum;
run;

/* OTHER: create new names for counts */
data OTHER;
   set NAMES;

   length Name2 $32;

   if (index(upcase(Name),"OTHER") GT 0) and (index(upcase(Name),"TIME") EQ 0);
   Name2=STRIP(Name)||'_';
   if length(Name) ge 32 then do;
      Name2=strip(substr(strip(Name),1,31))||'_';
   end;

run;

/* OTHER: get variable name list as macro string variables */
proc sql noprint;

   select Name into :OTHER_S separated by ' '
   from OTHER;

   select Name2 into :OTHER_2 separated by ' '
   from OTHER;

quit;

%put &=OTHER_S;
%put &=OTHER_2;


/* OTHER: create count binaries */
data OTHER_COUNT(drop = i);
   set FINAL(keep=&OTHER_S drop=&drop_derived);

   array have[*] &OTHER_S;
   array want[*] &OTHER_2;

   do i = 1 to dim(have);
      want[i] = 1 - (missing(have[i]) or (have[i] EQ '.'));
   end;

run;

/* OTHER: get count sums/drop auto variables */
proc means data=OTHER_COUNT sum noprint;
   var &OTHER_2;
   output out=OTHER_COUNT(drop=_FREQ_ _TYPE_) sum=;
run;


/* OTHER: transpose to long */
proc transpose 
      data=OTHER_COUNT
      out=OTHER_COUNT;
run;


/* OTHER: rename tranposed variables */
data OTHER_COUNT;
   set OTHER_COUNT(rename=(_NAME_ = NewVar COL1=Obs));
   counter+1;
run;

/* MANUAL INTERVENTION REQUIRED HERE */

/*

proc print data=OTHER_COUNT; run;

*/

/* PARENT VARIABLES
   identify by inspection
   
   parent questions for non-zero count OTHER variables.
   Use non-missing/'.' counts as total obs/denominators for % of Total calcs

Child             Parent         bin/excl
A1_07_OTHER       A1_07_77       bin
A1_11_OTHER       A1_11_77       bin
A1_14_OTHER       A1_14_77       bin
A1_17_OTHER       A1_17_77       bin
A1_19_OTHER       A1_19_77       bin
A1_20_OTHER       A1_20          excl
A1_21_OTHER       A1_21_77       bin
A1_24_OTHER       A1_24_77       bin
A1_26_OTHER       A1_26_77       bin
A1_28_OTHER       A1_28_77       bin
A2_040_OTHER      A2_040_77      bin
A2_360_OTHER      A2_360_77      bin
A2_720_OTHER      A2_720_77      bin
A2_830_OTHER      A2_830_77      bin
COV1_13c_OTHER    COV1_13c_77    bin
A3_37_OTHER       A3_37_77       bin
AMH1_08_OTHER     AMH1_08_08     bin
AMH1_11a_OTHER    AMH1_11a_13    bin
A5_03_OTHER1      A5_03_77       bin
A5_03_OTHER2      A5_03_77       bin
A5_03_OTHER3      A5_03_77       bin
A5_05_OTHER       A5_05          excl
A5_07_OTHER1      A5_07_77       bin
A5_07_OTHER2      A5_07_77       bin
A5_07_OTHER3      A5_07_77       bin
A5_14_OTHER       A5_14          excl
A5_15_OTHER       A5_15          excl
A5_17_OTHER       A5_17          excl
A5_21_OTHER       A5_21          excl


*/

/* use assign statements = output to create PARENT_YA
   (datalines statement doesn't work inside macro )
*/

data PARENT;
   length Parent_Name $32;

   Parent_Name='A1_07_77'; output;
   Parent_Name='A1_11_77'; output;
   Parent_Name='A1_14_77'; output;
   Parent_Name='A1_17_77'; output;
   Parent_Name='A1_19_77'; output;
   Parent_Name='A1_20'; output;
   Parent_Name='A1_21_77'; output;
   Parent_Name='A1_24_77'; output;
   Parent_Name='A1_26_77'; output;
   Parent_Name='A1_28_77'; output;
   Parent_Name='A2_040_77'; output;
   Parent_Name='A2_360_77'; output;
   Parent_Name='A2_720_77'; output;
   Parent_Name='A2_830_77'; output;
   Parent_Name='COV1_13c_77'; output;
   Parent_Name='A3_37_77'; output;
   Parent_Name='AMH1_08_08'; output;
   Parent_Name='AMH1_11a_13'; output;
   Parent_Name='A5_03_77'; output;
   Parent_Name='A5_05'; output;
   Parent_Name='A5_07_77'; output;
   Parent_Name='A5_14'; output;
   Parent_Name='A5_15'; output;
   Parent_Name='A5_17'; output;
   Parent_Name='A5_21'; output;

run;



/* PARENT: create new names for counts */
data PARENT;
   set PARENT;
   length Parent_Name2 $32;

   Parent_Name=Strip(Parent_Name);
   Parent_Name2=Strip(Parent_Name)||'_';

   if length(Parent_Name) ge 32 then do;
      Parent_Name2=STRIP(SUBSTR(STRIP(Parent_Name),1,31))||"_";
   end;

run;

/* PARENT: get variable name lists as macros */
proc sql noprint;

   select Parent_Name into :Parent_S separated by ' '
   from PARENT;

   select Parent_Name2 into :Parent_2 separated by ' '
   from PARENT;

quit;

/*
%put &=PARENT_S;
%put &=PARENT_2;
*/

/* PARENT: create count binaries */
data PARENT_COUNT(drop=i);
   set FINAL(keep=&PARENT_S drop=&drop_derived);

   array have[*] &PARENT_S;
   array want[*] &PARENT_2;

   do i = 1 to dim(have);
      want[i] = 1 - (missing(have[i]) or (have[i] EQ '.'));
   end;

run;

/* PARENT: get count sums */
proc means data=PARENT_COUNT sum noprint;
   var &PARENT_2;
   output out=PARENT_COUNT(drop=_FREQ_ _TYPE_)  sum=;
run;

/* PARENT: transpose to long */
proc transpose 
      data=PARENT_COUNT
      out=PARENT_COUNT;
run;

/* OTHER: rename tranposed variables */
data PARENT_COUNT;
   set PARENT_COUNT(rename=(_NAME_ = NewVar COL1=TotalObs));
   counter+1;
run;


/* MANUAL INTERVENTION REQUIRED HERE */


/* print PARENT and OTHER for inspection, ID observations to be removed by counter ID 

proc print data=PARENT_COUNT; title PARENT_COUNT; run;
proc print data=OTHER_COUNT; title OTHER_COUNT; run;

ie 
A5_03 - ethnicity
A5_05 - country of birth
A5_07 - languages
*/

/* by inspection, delete these observations:

from OTHER:
19-21 A5_03_OTHER1_ 2_ 3_
22    A5_05_OTHER
23-25 A5_07_OTHER1_ 2_ 3_
ie 19-25

from PARENT:
19    A5_03_77_
20    A5_05_
21    A5_07_77_
ie 19-21

*/

/* set deleteme flag by manual inclusion by counter ID */
data OTHER_COUNT(drop=counter deleteme);
   set OTHER_COUNT(rename=(NewVar=OtherQuestion));
   deleteme = (Counter in (19:25));
   if deleteme = 0;
   NewCounter+1;
run;

data PARENT_COUNT(drop=counter deleteme);
   set PARENT_COUNT(rename=(NewVar=ParentQuestion));
   deleteme = (Counter in (19:21));
   if deleteme = 0;
   NewCounter+1;
run;

/*
proc print data=OTHER_COUNT; title OTHER_COUNT; run;
proc print data=PARENT_COUNT; title PARENT_COUNT; run;
*/


/* merge OTHER and COUNT into OTHER_SPEC by NewCounter ID
   calculate proportion observations */
data OTHER_SPEC(drop=NewCounter OtherQuestion end rename=(ParentQuestion=Question));
   label ParentQuestion="Question";
   merge 
      PARENT_COUNT
      OTHER_COUNT
      ;
   by NewCounter;
   
   label 
      TotalObs = "Total Obs"
      Obs = "Obs"
      PctObs = "% of Total"
      ;

   if TotalObs = 0 then PctObs=0;
   else PctObs = Obs/TotalObs*100;

   end = find(ParentQuestion,'_','i',find(ParentQuestion,'_')+1)-1;
   ParentQuestion = substr(ParentQuestion,1,end);

run;

/* sort descending order */
proc sort data=OTHER_SPEC;
   by descending PctObs ;
run;


%mend Make_Adult_OtherSpec;

********** END MAKE ADULT OTHER/SPECIFY DATASETS MACROS **********;

********** MAKE CHILD OTHER/SPECIFY DATASETS MACROS **********;


%macro Make_Child_OtherSpec;

/* drop derived vars from final (not other-specify questionnaire variables) */
%let drop_derived=Other_Asian Other_Pacific Euro_Other;


/* get variable names from SURVEYS */
proc contents
      data=FINAL(drop=&drop_derived)
      out=NAMES
      noprint;
run;

/* sort variable names by varnum (PDV order) */
proc sort data=NAMES(keep=name--format);
   by varnum;
run;

/* OTHER: create new names for counts */
data OTHER;
   set NAMES;

   length Name2 $32;

   if (index(upcase(Name),"OTHER") GT 0) and (index(upcase(Name),"TIME") EQ 0);
   Name2=STRIP(Name)||'_';
   if length(Name) ge 32 then do;
      Name2=strip(substr(strip(Name),1,31))||'_';
   end;

run;

/* OTHER: get variable name list as macro string variables */
proc sql noprint;

   select Name into :OTHER_S separated by ' '
   from OTHER;

   select Name2 into :OTHER_2 separated by ' '
   from OTHER;

quit;

%put &=OTHER_S;
%put &=OTHER_2;

/* OTHER: create count binaries */
data OTHER_COUNT(drop = i);
   set FINAL(keep=&OTHER_S drop=&drop_derived);

   array have[*] &OTHER_S;
   array want[*] &OTHER_2;

   do i = 1 to dim(have);
      want[i] = 1 - (missing(have[i]) or (have[i] EQ '.'));
   end;

run;

/* OTHER: get count sums/drop auto variables */
proc means data=OTHER_COUNT sum noprint;
   var &OTHER_2;
   output out=OTHER_COUNT(drop=_FREQ_ _TYPE_) sum=;
run;


/* OTHER: transpose to long */
proc transpose 
      data=OTHER_COUNT
      out=OTHER_COUNT;
run;


/* OTHER: rename tranposed variables */
data OTHER_COUNT;
   set OTHER_COUNT(rename=(_NAME_ = NewVar COL1=Obs));
   counter+1;
run;



/* MANUAL INTERVENTION REQUIRED HERE */

/*

proc print data=OTHER_COUNT; run;

*/

/* PARENT VARIABLES
   identify by inspection
   
   parent questions for non-zero count OTHER variables.
   Use non-missing/'.' counts as total obs/denominators for % of Total calcs

Child             Parent         bin/excl      
C2_011_OTHER      C2_011_77      bin
C2_270_OTHER      C2_270_77      bin
C2_620_OTHER      C2_620_77      bin
C2_730_OTHER      C2_730_77      bin
C3_11_OTHER       C3_11_77       bin
CMH1_08_OTHER     CMH1_08_06     bin
CMH1_12a_OTHER    CMH1_12a_13    bin
C4_03_OTHER1      C4_03_77       bin
C4_03_OTHER2      C4_03_77       bin
C4_03_OTHER3      C4_03_77       bin
C4_05_OTHER       C4_05          excl
C4_20_OTHER       C4_20          excl
C4_21_OTHER       C4_21          excl
C4_22_OTHER       C4_22          excl

*/

/* use assign statements = output to create PARENT_YA
   (datalines statement doesn't work inside macro )
*/


data PARENT;
   length Parent_Name $32;

   Parent_Name='C2_011_77'; output;
   Parent_Name='C2_270_77'; output;
   Parent_Name='C2_620_77'; output;
   Parent_Name='C2_730_77'; output;
   Parent_Name='C3_11_77'; output;
   Parent_Name='CMH1_08_06'; output;
   Parent_Name='CMH1_12a_13'; output;
   Parent_Name='C4_03_77'; output;
   Parent_Name='C4_05'; output;
   Parent_Name='C4_20'; output;
   Parent_Name='C4_21'; output;
   Parent_Name='C4_22'; output;

run;

/* PARENT: create new names for counts */
data PARENT;
   set PARENT;
   length Parent_Name2 $32;

   Parent_Name=Strip(Parent_Name);
   Parent_Name2=Strip(Parent_Name)||'_';

   if length(Parent_Name) ge 32 then do;
      Parent_Name2=STRIP(SUBSTR(STRIP(Parent_Name),1,31))||"_";
   end;

run;

/* PARENT: get variable name lists as macros */
proc sql noprint;

   select Parent_Name into :Parent_S separated by ' '
   from PARENT;

   select Parent_Name2 into :Parent_2 separated by ' '
   from PARENT;

quit;

/*
%put &=PARENT_S;
%put &=PARENT_2;
*/

/* PARENT: create count binaries */
data PARENT_COUNT(drop=i);
   set FINAL(keep=&PARENT_S drop=&drop_derived);

   array have[*] &PARENT_S;
   array want[*] &PARENT_2;

   do i = 1 to dim(have);
      want[i] = 1 - (missing(have[i]) or (have[i] EQ '.'));
   end;

run;

/* PARENT: get count sums */
proc means data=PARENT_COUNT sum noprint;
   var &PARENT_2;
   output out=PARENT_COUNT(drop=_FREQ_ _TYPE_)  sum=;
run;

/* PARENT: transpose to long */
proc transpose 
      data=PARENT_COUNT
      out=PARENT_COUNT;
run;

/* OTHER: rename tranposed variables */
data PARENT_COUNT;
   set PARENT_COUNT(rename=(_NAME_ = NewVar COL1=TotalObs));
   counter+1;
run;



/* MANUAL INTERVENTION REQUIRED HERE */


/* print PARENT and OTHER for inspection, ID observations to be removed by counter ID 

proc print data=PARENT_COUNT; title PARENT_COUNT; run;
proc print data=OTHER_COUNT; title OTHER_COUNT; run;

ie 
A4_03 - ethnicity
A4_05 - country of birth
*/

/* by inspection, delete these observations:

from OTHER:
8-10  C4_03_OTHER1_ 2_ 3_
11    C4_05_OTHER
ie 8-11

from PARENT:
8     C4_03_77_
9     C4_05_
ie 8-9

*/

/* set deleteme flag by manual inclusion by counter ID */
data OTHER_COUNT(drop=counter deleteme);
   set OTHER_COUNT(rename=(NewVar=OtherQuestion));
   deleteme = (Counter in (8:11));
   if deleteme = 0;
   NewCounter+1;
run;

data PARENT_COUNT(drop=counter deleteme);
   set PARENT_COUNT(rename=(NewVar=ParentQuestion));
   deleteme = (Counter in (8:9));
   if deleteme = 0;
   NewCounter+1;
run;

/*
proc print data=PARENT_COUNT; title PARENT_COUNT; run;
proc print data=OTHER_COUNT; title OTHER_COUNT; run;
*/


/* merge OTHER and COUNT into OTHER_SPEC by NewCounter ID
   calculate proportion observations */
data OTHER_SPEC(drop=NewCounter OtherQuestion end rename=(ParentQuestion=Question));
   label ParentQuestion="Question";
   merge 
      PARENT_COUNT
      OTHER_COUNT
      ;
   by NewCounter;
   
   label 
      TotalObs = "Total Obs"
      Obs = "Obs"
      PctObs = "% of Total"
      ;

   if TotalObs = 0 then PctObs=0;
   else PctObs = Obs/TotalObs*100;

   end = find(ParentQuestion,'_','i',find(ParentQuestion,'_')+1)-1;
   ParentQuestion = substr(ParentQuestion,1,end);

run;

/* sort descending order */
proc sort data=OTHER_SPEC;
   by descending PctObs ;
run;

%mend Make_Child_OtherSpec;


********** END MAKE CHILD OTHER/SPECIFY DATASETS MACROS **********;



********** REPORT ADULT OTHER/SPECIFY DATASETS MACROS **********;


%macro Rpt_Adult_OtherSpec(qtr_in);

proc print data=OTHER_SPEC label noobs;
   title "Adult - Other/Specify (Quarter &qtr_in)";
   var Question Obs PctObs TotalObs;
   format PctObs 7.1;
run;
title;

%mend Rpt_Adult_OtherSpec;

********** END REPORT ADULT OTHER/SPECIFY DATASETS MACROS **********;


********** REPORT CHILD OTHER/SPECIFY DATASETS MACROS **********;

%macro Rpt_Child_OtherSpec(qtr_in);

proc print data=OTHER_SPEC label noobs;
   title "Child - Other/Specify (Quarter &qtr_in)";
   var Question Obs PctObs TotalObs;
   format PctObs 7.1;
run;
title;

%mend Rpt_Child_OtherSpec;


********** EMD REPORT CHILD OTHER/SPECIFY DATASETS MACROS **********;





/* RUN OUTPUT */

/* create sheetname macro  for ODS */
%macro Sheetname(shtname);
   ods excel options(sheet_name="&shtname");
%mend sheetname;



/* create ods filepath/file name */
%let ods_pathfile="&path_out.&ods_file";

%put &=ods_pathfile;


/* START block out ods output */
%if 0 %then %do;

/* run ODS process - initialise and run through each report with new sheetname */

/* open ODS sandwich */
ods excel close;
ods excel file = &ods_pathfile
options(
   sheet_interval='page'
   embedded_titles='on'
);

/* run make macros and write to excel */



%Sheetname(Other_Specify);

/* Adult Qtr 42 */
data FINAL;
   set FINAL_QA42;
run;
%Make_Adult_OtherSpec;
%Rpt_Adult_OtherSpec(42);

/* Adult Qtr 43 */
data FINAL;
   set FINAL_QA43;
run;
%Make_Adult_OtherSpec;
%Rpt_Adult_OtherSpec(43);

/* Child Qtr 42 */
data FINAL;
   set FINAL_QC42;
run;
%Make_Child_OtherSpec;
%Rpt_Child_OtherSpec(42);

/* Child Qtr 43 */
data FINAL;
   set FINAL_QC43;
run;
%Make_Child_OtherSpec;
%Rpt_Child_OtherSpec(43);


/* close ODS sandwich */
ods excel close;


%end
/* END block out ods output */



