


*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 DATA LINKING AND RESEARCH CONSENT                                                                          **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE CONSENT DATASET MACRO
      %Make_Consent
         -> DL

   3. MAKE CONSENT REPORT MACRO
      %Rpt_Consent
         -> proc tabulate

   4. RUN MACROS AND SET UP ODS
      %Sheetname(shtname)
         -> set sheetname per report macro
      Store output path/file name macros for output
      Open ODS sandwich
      Run %Make_Consent and %Rpt_Consent macros/write to excel
      Close ODS sandwich

*/


/* set up ref and source dataset */
%include "C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY11_REPORT\SASProgs\NZHSRpt11_INITIALISE.sas";

/* create output filename */
%let ods_file=NZHS_Y11_DLResearch_Consent.xlsx;



/* block out put %include macros to log */
%if 0 %then %do;

/*  check macros from NZHSRpt11_INITIALISE */
%put &=path_out;     * output path ;
%put &=qtr_in;       * current reporting quarters ;
%put &=yr_is;        * current reporting year ;
%put &=key_NZHS;     * by key ;
%put &=ods_file;

%end;
/* end block out put %include macros to log */


%macro Make_Consent;

/* adult consent dataset */
data DL_A(drop=A6_04 A6_08 A6_10Surname A6_10DOB);
   set surveys_ya(keep=&key_NZHS A6_04 A6_08 A6_10Surname A6_10DOB);

   is_adult=1;
   is_child=0;

   count_RS_Given = (A6_04 EQ '1');
   count_DL_Given = (A6_08 EQ '1');
   count_DL_Name=(A6_10Surname NE ' ' and length(strip(A6_10Surname)) GT 1);
   count_DL_DOB=(A6_10DOB NE ' ' and length(strip(A6_10DOB)) GT 1);

   label
      count_RS_Given='Research Consent Given'
      count_DL_Given='Data Linkage Consent Given'
      count_DL_Name='Surname Provided'
      count_DL_DOB='DOB Provided'
   ;
run;


/* child consent dataset */
data DL_C(drop=C6_04 C6_09 C6_11Surname C6_11DOB);
   set surveys_yc(keep=&key_NZHS C6_04 C6_09 C6_11Surname C6_11DOB);

   is_adult=0;
   is_child=1;

   count_RS_Given = (C6_04 EQ '1');
   count_DL_Given = (C6_09 EQ '1');
   count_DL_Name=(C6_11Surname NE ' ' and length(strip(C6_11Surname)) GT 1);
   count_DL_DOB=(C6_11DOB NE ' ' and length(strip(C6_11DOB)) GT 1);

   label
      count_RS_Given='Research Consent Given'
      count_DL_Given='Consent Given'
      count_DL_Name='Surname Provided'
      count_DL_DOB='DOB Provided'
   ;
run;

/* combined consent dataset */
data DL;
   set
      DL_A
      DL_C
   ;
run;

proc delete
      data=DL_A DL_C
   ;
run;


%mend Make_Consent;


%macro Rpt_Consent;

/* adult DL consent */
proc tabulate
      data=DL
      format=percent9.2
   ;
   where is_adult;
   title 'Adult Data Linkage Consent';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      count_DL_Given*mean=' ',
      qtr
      /
      box = 'Consent Rate'
   ;
run;
title;

/* adult DL Surname/DOB */
proc tabulate
      data=DL /*DL_A*/
      format=percent9.2
   ;
   where (count_DL_Given EQ 1) and is_adult;
   title 'Adult Data Linkage: Surname and DOB Provided';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      (count_DL_Name count_DL_DOB)*mean=' ',
      qtr
      /
      box = 'ID Provided'
   ;
run;
title;

/* child DL consent */
proc tabulate
      data=DL
      format=percent9.2
   ;
   where is_child;
   title 'Child Data Linkage Consent';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      count_DL_Given*mean=' ',
      qtr
      /
      box = 'Consent Rate'
   ;
run;
title;

/* child DL Surname/DOB */
proc tabulate
      data=DL
      format=percent9.2
   ;
   where (count_DL_Given EQ 1) and is_child;
   title 'Child Data Linkage: Surname and DOB Provided';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      (count_DL_Name count_DL_DOB)*mean=' ',
      qtr
      /
      box = 'ID Provided'
   ;
run;
title;


/* adult research consent */
proc tabulate
      data=DL
      format=percent9.2
   ;
   where is_adult;
   title 'Adult Research Consent';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      count_RS_Given*mean=' ',
      qtr
      /
      box = 'Consent Rate'
   ;
run;
title;

/* child research consent */
proc tabulate
      data=DL
      format=percent9.2
   ;
   where is_child;
   title 'Child Research Consent';
   class qtr;
   var count_RS_Given count_DL_Given count_DL_Name count_DL_DOB;
   tables
      count_RS_Given*mean=' ',
      qtr
      /
      box = 'Consent Rate'
   ;
run;
title;

%mend Rpt_Consent;





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

%Make_Consent;
%Sheetname(Consent);
%Rpt_Consent;

/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */


