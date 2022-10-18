




*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 RESPONDENT BURDEN REPORTS                                                                                  **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE RESPONDENT BURDEN DATASET MACRO
      %Make_RB
         -> ADULT_RB
         -> CHILD_RB
         -> RB

   3. MAKE RESPONDENT BURDEN REPORT MACRO
      %Rpt_RB
         -> proc tabulate RB means scores

   4. RUN MACROS AND SET UP ODS
      %Sheetname(shtname)
         -> set sheetname per report macro
      Store output path/file name macros for output
      Open ODS sandwich
      Run %Sheetname %Make and %Rpt macros/write to excel
      Close ODS sandwich

*/


/* set up ref and source dataset */
%include "C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY11_REPORT\SASProgs\NZHSRpt11_INITIALISE.sas";

/* create output filename */
%let ods_file=NZHS_Y11_RespondentBurden.xlsx;



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

********** MAKE RESPONDENT BURDEN DATASETS MACROS **********;

%macro Make_RB;


data adult_rb;
   set surveys_ya(keep=&key_NZHS AR1Optionsselfcom_1-AR1Optionsselfcom_4);
   label
      RB1='Survey Length'
      RB2='Number of Questions'
      RB3='Question Complexity'
      RB4='Intrusiveness'
   ;

   array have[4] AR1Optionsselfcom_1-AR1Optionsselfcom_4;
   array want[4] RB1-RB4;

   do i = 1 to 4;
      want[i] = input(have[i],F1.);
   end;

   AdultChild='Adult';

   drop i AR1Optionsselfcom_1-AR1Optionsselfcom_4;
run;

data child_rb;
   set surveys_yc(keep=&key_NZHS RB1Optionsselfcom_1-RB1Optionsselfcom_4);
   label
      RB1='Survey Length'
      RB2='Number of Questions'
      RB3='Question Complexity'
      RB4='Intrusiveness'
   ;

   array have[4] RB1Optionsselfcom_1-RB1Optionsselfcom_4;
   array want[4] RB1-RB4;

   do i = 1 to 4;
      want[i] = input(have[i],F1.);
   end;

   AdultChild='Child';

   drop i RB1Optionsselfcom_1-RB1Optionsselfcom_4;
run;

data RB;
   set 
      adult_RB 
      child_RB
   ;
run;

proc sort data=RB;
   by &key_NZHS AdultChild;
run;

%mend Make_RB;


********** END MAKE RESPONDENT BURDEN DATASETS MACROS **********;

********** REPORT RESPONDENT BURDEN  MACROS **********;

%macro Rpt_RB;

proc tabulate
      data=RB(where=(AdultChild='Adult'))
      format=4.2
   ;
   title 'Adult Respondent Burden';
   class qtr;
   var RB1-RB4;
   table
      (RB1-RB4)*mean=' ',
      qtr='Qtr'
      /
      box='Adult Respondent Burden';
   ;
run;
title;

proc tabulate
      data=RB(where=(AdultChild='Child'))
      format=4.2
   ;
   title 'Child Respondent Burden';
   class qtr;
   var RB1-RB4;
   table
      (RB1-RB4)*mean=' ',
      qtr='Qtr'
      /
      box='Child Respondent Burden';
   ;
run;
title;

%mend Rpt_RB;


********** END REPORT RESPONDENT BURDEN  MACROS **********;


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

%Make_RB;
%Sheetname(RespondentBurden);
%Rpt_RB;

/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */

