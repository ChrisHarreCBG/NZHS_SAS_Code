

*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 NON-RESPONSE REPORTS                                                                                       **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE NON-RESPONSE DATASET MACRO
      %Make_NonReponse(dsin)
         -> NR_02
            arguments are:
               dsin = final_qa42
                      final_qa43
                      final_qc42
                      final_qc43
            output is NR_02

   3. MAKE NON-RESPONSE REPORT MACRO
      %Rpt_NonResponse(AC_QTR);
         -> proc print Non-Response
            input argument is for title:
            Adult Qtr 42
            Child Qtr 43
            Adult Qtr 42
            Child Qtr 43
      Run %Rpt_NonResponse after each run %Make_NonReponse

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
%let ods_file=NZHS_Y11_NonResponse.xlsx;



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


********** MAKE NON-RESPONSE DATASETS MACROS **********;
/* run each adult/child qtrs separately and report each immediately after dataset before next make */

%macro Make_NonReponse(dsin);
   /* dsin - input dataset
            = final_qa42
            = final_qa43
            = final_qc42
            = final_qc43
      
      output dataset is NR_02, used as argument in Rpt macro
   */

/* get all char vars and values where not missing */
data NR_01(keep=Variable Value);
   length Value $300.;
   set &dsin;
   array aq(*) _character_;
   do i = 1 to dim(aq);
      Variable =vname(aq[i]);
      Value = aq[i];
      if Value NE . then output;
   end;
run;

/* ds NR_DKR = subset for Values = .K, .R */
data NR_DKR;
   set NR_01(where=(Value in ('.K', '.R')));
run;

/* get NR_tab_R = counts of .R in NR_DKR */
ods select none;
proc tabulate
      data=NR_DKR
      out=NR_tab_R
   ;
   where Value EQ '.R';
   class Variable;
   tables 
      Variable, 
      n
   ;
run;
ods select all;

/* get NR_tab_DK = counts of .K in NR_DKR */
ods select none;
proc tabulate
      data=NR_DKR
      out=NR_tab_DK
   ;
   where Value EQ '.K';
   class Variable;
   tables 
      Variable, 
      n
   ;
run;
ods select all;

/* get NR_tab_ALL = count all in NR_01 */
ods select none;
proc tabulate
      data=NR_01
      out=NR_tab_ALL
   ;
   class Variable;
   tables 
      Variable, 
      n
   ;
run;
ods select all;

/* rename N as R/DK/ALL + sort by Variable for merge */
proc sort data=NR_tab_R(rename=(N=R));
   by Variable;
run;
proc sort data=NR_tab_DK(rename=(N=DK));
   by Variable;
run;
proc sort data=NR_tab_ALL(rename=(N=ALL));
   by Variable;
run;

/* merge NR_Q42_tab_R NR_Q42_tab_DK NR_Q42_tab_ALL + replace missing with 0 */
data NR_02;
   merge
      NR_tab_ALL
      NR_tab_DK
      NR_tab_R
   ;
   by Variable;

   R = coalesce(R,0);
   DK = coalesce(DK,0);

run;

/* calculate stats */
data NR_02;
   retain Variable DKR pcDK pcR pcDKR ALL;
   set NR_02(drop=_TYPE_ _PAGE_ _TABLE_);

   DKR = sum(DK, R);
   pcDK = DK/ALL;
   pcR = R/ALL;
   pcDKR = DKR/ALL;
   format 
      pcDK pcR pcDKR percent8.1;
   label
      Variable = 'Question'
      DKR = 'Obs'
      pcDK = 'DK %'
      pcR = 'R %'
      pcDKR = 'Total DKR %'
      All = 'Total Obs'
      R = 'R'
      DK = 'DK'
   ;
   if DKR gt 0 and pcDKR lt 1;
run;

/* sort by descending percentate non-response (pcDKR) */
proc sort data=NR_02;
   by descending pcDKR;
run;

%mend Make_NonReponse;

********** END MAKE NON-RESPONSE DATASETS MACROS **********;

********** REPORT NON-RESPONSE MACROS **********;

%macro Rpt_NonResponse(AC_QTR);
/* uses NR_02 as input dataset
   AC_QTR is adult/child qtr title text:
   Adult Qtr 42
   Adult Qtr 43
   Child Qtr 42
   Child Qtr 43
*/

proc print data=NR_02(where=(pcDKR GE 0.05)) noobs label;
   title "&AC_QTR - Non-Response/DKR";
   var Variable DKR pcDK pcR pcDKR All;
run;
title;

%mend Rpt_NonResponse;

********** END REPORT NON-RESPONSE MACROS **********;


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
%Sheetname(Non_Reponse);

%Make_NonReponse(final_qa42);
%Rpt_NonResponse(Adult Qtr 42);

%Make_NonReponse(final_qa43);
%Rpt_NonResponse(Adult Qtr 43);

%Make_NonReponse(final_qc42);
%Rpt_NonResponse(Child Qtr 42);

%Make_NonReponse(final_qc43);
%Rpt_NonResponse(Child Qtr 43);


/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */
