

*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 DURATION REPORTS                                                                                           **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE DURATION DATASET MACROS
      %Make_Adult_Durations
         -> ADULT_SURVEY_DUR
      %Make_Child_Durations
         -> CHILD_SURVEY_DUR
      %Make_Long(isqtr)
         -> Adult_Long (for quarter)
         -> child_Long (for quarter)

   3. MAKE DURATION REPORT MACROS
      %Rpt_Interview_Duration
         -> proc tabulate Interview Duration Stats
      %Rpt_CoreModule_Duration
         -> proc tabulate Core/Module Durations
      %Rpt_Section_Duration
         -> proc tabulate Section Duration Stats
      %Rpt_Long_Questions(isqtr)
         -> proc print Longest Duration Questions (for quarter)

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
%let ods_file=NZHS_Y11_Durations.xlsx;



/* block out put %include macros to log */
%if 0 %then %do;

/*  check macros from NZHSRpt11_INITIALISE */
%put &=path_out;     * output path ;
%put &=qtr_in;       * current reporting quarters ;
%put &=yr_is;        * current reporting year ;
%put &=key_NZHS;     * by key ;
%put &=ods_file;     * output filename ;

%end;
/* end block out put %include macros to log */

********** MAKE DURATION DATASETS MACROS **********;

%macro Make_Adult_Durations;

   /* create adult duration dataset 1 from askia
   	excludes HHComp and Measurement */

/* replace askia_ya with surveys_ya
   cross ref surveys_ya and survey doc for core and module section variable sequences
*/

   data ADULT_SEC_DUR_1(keep=&key_NZHS Section1-Section6);
   	set surveys_ya;

      * initial demog = AD_01--AD_02 ;
      * overall sat/well-being = AMH2_01--AMH2_02 ;
      * Section 1 = A1_01--A1_31a ;
      * interviewer obs = A6_13--A6_14 ;
      * -> use AD_01--A6_14 = TimeAD_01--TimeA6_14 ;
   	Section1  = sum(0, of TimeAD_01--TimeA6_14);
   	label Section1  = 'Long-term health conditions';

      * Health service utilisation = A2_01--A2_95a ;
      * -> use A2_01--A2_95a = TimeA2_01--TimeA2_95a ;
   	Section2  = sum(0, of TimeA2_01--TimeA2_95a);
   	label Section2  = 'Health Service utilisation and patient experience';

      * Health behaviours = A3_01--A3_12c A3_13--A3_37_OTHER ;
      * -> use A3_01--A3_12c A3_13--A3_37_OTHER = TimeA3_01--TimeA3_12c TimeA3_13--TimeA3_37_OTHER ;
      Section3  = sum(0, of TimeA3_01--TimeA3_12c) + sum(0, of TimeA3_13--TimeA3_37_OTHER);
   	label Section3  = 'Health behaviours and risk factors';

      * health status = A4_01--A4_12 A4_13--A4_22 AMH1_01a ;
      * EXCLUDE FUNCTIONAL DIFFICULTIES FD1_01--FD1_06 ;
      * -> use A4_01--A4_12 A4_13--A4_22 AMH1_01a = TimeA4_01--TimeA4_12 TimeA4_13--TimeA4_22 TimeAMH1_01a ;
      Section4  = sum(0, of TimeA4_01--TimeA4_12) + sum(0, of TimeA4_13--TimeA4_22, TimeAMH1_01a);
   	label Section4  = 'Health Status';

      * socio-demog = A5_01_DKR--A5_30b ;
      * -> TimeA5_01--TimeA5_30b ;
      Section5 = sum(0, of TimeA5_01_DKR--TimeA5_30b);
   	label Section5 = 'Socio-demographics';

      * exits = A6_01--VIP1_11_Record_last_8_digits_of ;
      * -> TimeA6_01--TimeVIP1_11_Record_last_8_digits;
      Section6 = sum(0, of TimeA6_01--TimeVIP1_11_Record_last_8_digits);
   	label Section6 = 'Exit Questions';

   run;


   /* create adult duration dataset 2 from combo
   	for HHComp and Measurement */

   data ADULT_SEC_DUR_2(drop=householdcompduration measuredurationtotaladult);
   	/* from combo_ya/qtrs 38, 39, 40only */
   	set combo_ya(
   			keep=&key_NZHS householdcompduration measuredurationtotaladult);

   	HHComp = householdcompduration;
   	label HHComp = 'Household composition';

   	Measure = measuredurationtotaladult;
   	label Measure = 'Measurements';

   run;


   /* sort for merge to single dataset */

   proc sort data = ADULT_SEC_DUR_1; 
   	by &key_NZHS;
   run;
   proc sort data = ADULT_SEC_DUR_2; 
         by &key_NZHS;
   run;

   /* Merged Adult Durations + exclude any section duration = 0 */
   data ADULT_SEC_DUR(keep=&key_NZHS CoreTotal SampleMgrTotal Section1-Section6 HHComp Measure);
      merge 
         ADULT_SEC_DUR_1
         ADULT_SEC_DUR_2
      ;
      by &key_NZHS;

      CoreTotal = sum(of Section1-Section6);
      SampleMgrTotal = coalesce(HHComp,0) + coalesce(Measure,0);

      label 
         CoreTotal = "Core Total"
         SampleMgrTotal = "Sample Manager Total"
      ;

      exclude = 0;
      array IZ{*} Section1-Section6 HHComp Measure;
      do i = 1 to dim(IZ);
         exclude = exclude + (IZ{i} EQ 0);
      end;

      if exclude = 0;

      drop i exclude;

   run;

   /* delete ADULT_SEC_DUR_1 and ADULT_SEC_DUR_2 */
   proc delete 
      data=ADULT_SEC_DUR_1 ADULT_SEC_DUR_2;
   run;


   /* Module Durations */

   data ADULT_MOD_DUR(keep=&key_NZHS Module1-Module3 ModuleTotal);
      set surveys_ya;

      /* Module 1 COVID */
      Module1 = sum(0, of TimeCOV1_13--TimeCOV1_04); 
      label Module1 = 'COVID-19';
      
      /* Module 2 Functional Difficulties */
      Module2 = sum(0, of TimeFD1_01--TimeFD1_06);
      label Module2 ='Functional Difficulties';

      /* Mental Health Self-Complete - PHQ & AST */
      Module3 = sum(0, of TimeAMHIntro_1--TimeAMH_ThankyouAlert);
      label Module3 = "Mental Health";

      ModuleTotal = sum(of Module1-Module3);
   	label ModuleTotal = "Module Total";

   run;
   
   /* ADD Total and ModuleTotal somewhere */
   /* Core/Module/SM/Total Durations */
   data ADULT_SURVEY_DUR;
      retain &key_NZHS Section1-Section6 HHComp Measure Module1-Module3;
      merge
      	ADULT_SEC_DUR(in=core)
      	ADULT_MOD_DUR(in=mod)
      ;
      by &key_NZHS;

      SurveyTotal = CoreTotal + SampleMgrTotal + ModuleTotal;
      AdultChild='Adult';
      Label 
         SurveyTotal='Survey Duration Total'
         AdultChild='Adult/Child indicator'
      ;
   run;

%mend Make_Adult_Durations;



%macro Make_Child_Durations;


   /* create child duration dataset 1 from askia
   	excludes HHComp and Measurement 
   */

   data CHILD_SEC_DUR_1(keep=&key_NZHS Section1-Section4 Section6);
      set surveys_yc;

      Section1  = sum(0, of TimeCD_01--TimeC1_19);
      label Section1  = 'Long-term health conditions';

      Section2  = sum(0, of TimeC2_01a--TimeC2_83a);
      label Section2  = 'Health Service utilisation';

      Section3  = sum(0, of TimeC3_01--TimeC3_16a);
      label Section3  = 'Health behaviours and risk factors';

      Section4  = sum(0, of TimeC4_01_DKR--TimeC4_23);
      label Section4  = 'Socio-demographics';

      Section6 = sum(0, of TimeC6_01--TimeRBEnd) + sum(0, of TimeCR1_05--TimeRBEnd2);
      label Section6 = 'Exit Questions';

   run;

   /* create child duration dataset 2 from combo
   	for HHComp and Measurement */
   data CHILD_SEC_DUR_2(drop=householdcompduration measuredurationchild);
      set combo_yc(keep=&key_NZHS householdcompduration measuredurationchild);

      HHComp  = householdcompduration;
      label HHComp  = 'Household composition';

      Measure = measuredurationchild;
      label Measure = 'Measurements';

   run;

   /* sort for merge to single dataset */

   proc sort data=CHILD_SEC_DUR_1; 
      by &key_NZHS;
   run;
   proc sort data=CHILD_SEC_DUR_2; 
      by &key_NZHS;
   run;

   /* Merged Child Durations + exclude any section duration = 0 */
   data CHILD_SEC_DUR(keep=&key_NZHS CoreTotal SampleMgrTotal Section1-Section4 Section6 HHComp Measure);
      merge 
      	CHILD_SEC_DUR_1
      	CHILD_SEC_DUR_2
      ;
      by &key_NZHS;

      CoreTotal=sum(of Section1-Section4, Section6);
      SampleMgrTotal = coalesce(HHComp,0) + coalesce(Measure, 0);

      label 
         CoreTotal="Core Total"
         SampleMgrTotal="Sample Manager Total"
      ;

      exclude = 0;
      array IZ{*} Section1-Section4 Section6 HHComp Measure;
      do i = 1 to dim(IZ);
         exclude = exclude + (IZ{i} EQ 0);
      end;

      if exclude = 0;

      drop exclude i;

   run;

   /* delete CHILD_SEC_DUR_1 and CHILD_SEC_DUR_2 */
   proc delete 
      data=CHILD_SEC_DUR_1 CHILD_SEC_DUR_2;
   run;


   /* Module Durations */
   data CHILD_MOD_DUR(keep=&key_NZHS Module1-Module3 ModuleTotal);
      set surveys_yc;

      Module1 = sum(0, of TimeCDWIntro--TimeCMH1_12a_Another_reason_Spec);
      label Module1 = "Mental Health/Strengths and Difficulties";

      Module2 = sum(0, of TimeCPS1_01--TimeCPS1_05);
      label Module2 = "Parental Stress";

      Module3 = sum(0, of TimeCFS_Intro--TimeCFS1_08);
      label Module3 = "Household Food Security";

      ModuleTotal = sum(of Module1-Module3);
      label ModuleTotal = "Module Total";

   run;


   /* Core/Module/SM/Total Durations */
   data CHILD_SURVEY_DUR;
      retain &key_NZHS Section1-Section4 Section6 HHComp Measure Module1-Module3;
      merge
         CHILD_SEC_DUR(in=core)
         CHILD_MOD_DUR(in=mod)
      ;
      by &key_NZHS;

      SurveyTotal = CoreTotal + SampleMgrTotal + ModuleTotal;
      AdultChild='Child';
      Label 
         SurveyTotal='Survey Duration Total'
         AdultChild='Adult/Child indicator'
      ;
   run;


%mend Make_Child_Durations;



%macro Make_Long(isqtr);
/* NEED TO ADD QUARTERS */


***** ADULT make longest questions datasets *****;

/* duration variable list */
%let adult_TimeVars=TimeAD_01--TimeVIP1_11_Record_last_8_digits TimeAMH_Thankyou--TimeRBend2;
%let adult_noQuestions=30;
%let adultds=surveys_qa&isqtr;


/* get Time variables */
data Adult_Long01;
   set &adultds(keep=&adult_TimeVars);
run;

/* tabulate mean durations / output to dataseet Adult_Long_Means */
ods select none;
proc tabulate
      data=Adult_Long01
      out=Adult_Long02
   ;
   var &adult_TimeVars;
   table (&adult_TimeVars)*mean;
run;
ods select all;

/* transpose Adult_Long_Means */
proc transpose 
      data=Adult_Long02
      out=Adult_Long03
   ;
run;


/* clean variable names 
   condition on _NAME_ starts with TIME
   remove '_MEAN' from value in _NAME_
   rename _NAME_ as Question
   drop _LABEL_
   rename _NAME_ as Question
*/
data Adult_Long04;*(drop=_LABEL_ rename=(_NAME_=Question COL1=Mean));
   set Adult_Long03(where=(index(upcase(_NAME_),'TIME') EQ 1));
   _NAME_ = TRANWRD(_NAME_,'_Mean','');
   drop _LABEL_;
   rename
      _NAME_=Question 
      COL1=Mean
   ;
run;

/* sort desc to get longest question durations */
proc sort
      data=Adult_Long04
      out=Adult_Long05;
   by descending mean;
run;


/* reduce to top 20 */
data Adult_Long06;
   set Adult_Long05(obs=&adult_noQuestions);
run;


/* get list (top 20) */
proc sql noprint;

   /* question variables macro */   
   select distinct Question into :ALIST separated by ' '
   from Adult_Long06;

   /* count obs in source dataset */
   select count(*) into :ACOUNT 
   from Adult_Long01;

quit;

%put &=ALIST;
%put &=ACOUNT;


/* reduce source to top 20 */
data Adult_Long07;
   set Adult_Long01(keep=&ALIST);
run;


/* remove labels */
proc datasets lib=work nolist;
   modify Adult_Long07;
      attrib _all_ label='';
quit;


/* get means (again) from reduced source */
ods select none;
proc tabulate
      data=Adult_Long07
      out=Adult_Long08_mean
   ;
   var &ALIST;
   table 
      (&ALIST)*mean
   ;
run;
ods select all;

/* get counts from reduced source */
ods select none;
proc tabulate
      data=Adult_Long07
      out=Adult_Long08_n
   ;
   var &ALIST;
   table 
      (&ALIST)*n
   ;
run;
ods select all;

/* transpose reduced means and counts */
proc transpose
      data=Adult_Long08_mean
      out=Adult_Long09_mean
   ;
run;

proc transpose
      data=Adult_Long08_n
      out=Adult_Long09_n
   ;
run;


/* tidy means for merge 
   remove '_MEAN' from value in _NAME_
   rename _NAME_ as Question
   rename COL1 as Mean
   condition on _NAME_ starts with  TIME
*/
data Adult_Long10_mean;
   set Adult_Long09_mean;
   
   _NAME_ = TRANWRD(_NAME_,'_Mean','');
   rename 
      _NAME_ = Question
      COL1 = Mean
   ;
   if index(upcase(_NAME_),'TIME') eq 1;
   drop _LABEL_;

run;


/* tidy counts for merge */
data Adult_Long10_n;
   set Adult_Long09_n;

   _NAME_=substr(_NAME_,1,length(_NAME_)-2); * use substr -2 instead of tranwrd;
   All_Obs=&ACOUNT;
   PctObs=COL1/&ACOUNT;
   format PctObs PERCENT8.1;

   rename 
      _NAME_ = Question
      COL1 = Obs
   ;
   if index(upcase(_NAME_),'TIME') eq 1;
   drop _LABEL_;

run;

/* merge means and counts */
data Adult_Long;
   merge
      Adult_Long10_mean
      Adult_Long10_n
   ;
   by Question;
   Question = tranwrd(Question,'Time','');
run;

proc sort data=Adult_Long;
   by descending mean;
run;

proc delete
      data=
         adult_long01
         adult_long02
         adult_long03
         adult_long04
         adult_long05
         adult_long06
         adult_long07
         adult_long08_mean
         adult_long08_n
         adult_long09_mean
         adult_long09_n
         adult_long10_mean
         adult_long10_n
   ;
run;


***** CHILD make longest questions datasets *****;


/* duration variable list */
%let child_TimeVars=TimeCD_01--TimeRBEnd TimeCR1_05--TimeRBEnd2;
%let child_noQuestions=30;
%let childds=surveys_qc&isqtr;

/* get Time variables */
data child_Long01;
   set &childds(keep=&child_TimeVars);
run;

/* tabulate mean durations / output to dataseet child_Long_Means */
ods select none;
proc tabulate
      data=child_Long01
      out=child_Long02
   ;
   var &child_TimeVars;
   table (&child_TimeVars)*mean;
run;
ods select all;

/* transpose child_Long_Means */
proc transpose 
      data=child_Long02
      out=child_Long03
   ;
run;


/* clean variable names 
   condition on _NAME_ starts with TIME
   remove '_MEAN' from value in _NAME_
   rename _NAME_ as Question
   drop _LABEL_
   rename _NAME_ as Question
*/
data child_Long04;*(drop=_LABEL_ rename=(_NAME_=Question COL1=Mean));
   set child_Long03(where=(index(upcase(_NAME_),'TIME') EQ 1));
   _NAME_ = TRANWRD(_NAME_,'_Mean','');
   drop _LABEL_;
   rename
      _NAME_=Question 
      COL1=Mean
   ;
run;

/* sort desc to get longest question durations */
proc sort
      data=child_Long04
      out=child_Long05;
   by descending mean;
run;


/* reduce to top 20 */
data child_Long06;
   set child_Long05(obs=&child_noQuestions);
run;


/* get list (top 20) */
proc sql noprint;

   /* question variables macro */   
   select distinct Question into :CLIST separated by ' '
   from child_Long06;

   /* count obs in source dataset */
   select count(*) into :CCOUNT 
   from child_Long01;

quit;

%put &=CLIST;
%put &=CCOUNT;


/* reduce source to top 20 */
data child_Long07;
   set child_Long01(keep=&CLIST);
run;


/* remove labels */
proc datasets lib=work nolist;
   modify child_Long07;
      attrib _all_ label='';
quit;


/* get means (again) from reduced source */
ods select none;
proc tabulate
      data=child_Long07
      out=child_Long08_mean
   ;
   var &CLIST;
   table 
      (&CLIST)*mean
   ;
run;
ods select all;

/* get counts from reduced source */
ods select none;
proc tabulate
      data=child_Long07
      out=child_Long08_n
   ;
   var &CLIST;
   table 
      (&CLIST)*n
   ;
run;
ods select all;

/* transpose reduced means and counts */
proc transpose
      data=child_Long08_mean
      out=child_Long09_mean
   ;
run;

proc transpose
      data=child_Long08_n
      out=child_Long09_n
   ;
run;


/* tidy means for merge 
   remove '_MEAN' from value in _NAME_
   rename _NAME_ as Question
   rename COL1 as Mean
   condition on _NAME_ starts with  TIME
*/
data child_Long10_mean;
   set child_Long09_mean;
   
   _NAME_ = TRANWRD(_NAME_,'_Mean','');
   rename 
      _NAME_ = Question
      COL1 = Mean
   ;
   if index(upcase(_NAME_),'TIME') eq 1;
   drop _LABEL_;

run;


/* tidy counts for merge */
data child_Long10_n;
   set child_Long09_n;

   _NAME_=substr(_NAME_,1,length(_NAME_)-2); * use substr -2 instead of tranwrd;
   All_Obs=&CCOUNT;
   PctObs=COL1/&CCOUNT;
   format PctObs PERCENT8.1;

   rename 
      _NAME_ = Question
      COL1 = Obs
   ;
   if index(upcase(_NAME_),'TIME') eq 1;
   drop _LABEL_;

run;

/* merge means and counts */
data child_Long;
   merge
      child_Long10_mean
      child_Long10_n
   ;
   by Question;
   Question = tranwrd(Question,'Time','');
run;

proc sort data=child_Long;
   by descending mean;
run;

proc delete
      data=
         child_long01
         child_long02
         child_long03
         child_long04
         child_long05
         child_long06
         child_long07
         child_long08_mean
         child_long08_n
         child_long09_mean
         child_long09_n
         child_long10_mean
         child_long10_n
   ;
run;


%mend Make_Long;



********** DURATION REPORT MACROS **********;

%macro Rpt_Interview_Duration;
/* TOTAL SURVEY DURATIONS, including Sample Manager Activities (Measure, HHComp) */

/* Adult */
proc tabulate
      data=adult_survey_dur
      format=mmss.
   ;
   title 'Adult Interview Duration Stats';
   var SurveyTotal;
   class qtr;
   table
      (SurveyTotal=' ')*(mean median std max min p25 p75),
      qtr='Quarter'
      /
      box = 'Adult Interview Duration'
   ;
   keylabel std='Std Deviation' p25='Lower Quartile' p75='Upper Quartile';
run;
title;

/* Child */
proc tabulate
      data=child_survey_dur
      format=mmss.
   ;
   title 'Child Interview Duration Stats';
   var SurveyTotal;
   class qtr;
   table
      (SurveyTotal=' ')*(mean median std max min p25 p75),
      qtr='Quarter'
      /
      box = 'Child Interview Duration'
   ;
   keylabel std='Std Deviation' p25='Lower Quartile' p75='Upper Quartile';
run;
title;

%mend Rpt_Interview_Duration;

%macro Rpt_CoreModule_Duration;
/* CORE MODULE DURATIONS, excluding Sample Manager Activities (Measure, HHComp) */

/* Adult */
proc tabulate
      data=adult_survey_dur
      format=mmss.
   ;
   title 'Adult Survey Core/Module Durations';
   var CoreTotal ModuleTotal;
   class qtr;
   table
      (CoreTotal='Core' ModuleTotal='Module')*mean=' ',
      qtr
      /
      box = 'Adult Mean Durations'
   ;
run;
title;

/* Child */
proc tabulate
      data=child_survey_dur
      format=mmss.
   ;
   title 'Child Survey Core/Module Durations';
   var CoreTotal ModuleTotal;
   class qtr;
   table
      (CoreTotal='Core' ModuleTotal='Module')*mean=' ',
      qtr
      /
      box = 'Child Mean Durations'
   ;
run;
title;

%mend Rpt_CoreModule_Duration;


%macro Rpt_Section_Duration;
/* SECTION DURATIONS, Core and Module, including Sample Manager Activities (Measure, HHComp) */

/* Adult */
proc tabulate
      data=adult_survey_dur /*(where=(Module3 gt 0))*/
      format=mmss.
   ;
   title 'Adult Section Duration Stats';
   var Section1-Section6 HHComp Measure Module1-Module3 SurveyTotal;
   class qtr;
   table
      (Section1-Section6 HHComp Measure Module1-Module3 SurveyTotal),
      qtr*(mean median std max min)
      /
      box = 'Adult Section Durations'
   ;
run;
title;


/* Child */
proc tabulate
      data=child_survey_dur /*(where=(Module3 gt 0))*/
      format=mmss.
   ;
   title 'Child Section Duration Stats';
   var Section1-Section4 Section6 HHComp Measure Module1-Module3 SurveyTotal;
   class qtr;
   table
      (Section1-Section4 Section6 HHComp Measure Module1-Module3 SurveyTotal),
      qtr*(mean median std max min)
      /
      box = 'Child Section Durations'
   ;
run;
title;

%mend Rpt_Section_Duration;


%macro Rpt_Long_Questions(isqtr);
/* LONGEST DURATION QUESTIONS Adult & Child */

proc print data=Adult_Long noobs; 
   title "Adult Longest Duration Questions Quarter &isqtr";
   format Mean mmss.;
run;
title;


proc print data=child_Long noobs; 
   title "Child Longest Duration Questions Quarter &isqtr";
   format Mean mmss.;
run;
title;

%mend Rpt_Long_Questions;



***********************************;


/* OUTPUT REPORTS */


/* RUN MAKE DURATION DATASETS MACROS  - moved to ODS sandwich */
/*
%Make_Adult_Durations;
%Make_Child_Durations;
*/
/*
%Make_Long(42);
%Make_Long(43);
*/

/* run reports */
/*
%Rpt_Interview_Duration;
%Rpt_CoreModule_Duration;
%Rpt_Section_Duration;
%Rpt_Long_Questions(42);
%Rpt_Long_Questions(43);
*/

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

/* run adult and child duration macros */
%Make_Adult_Durations;
%Make_Child_Durations;

/* write interview duration tables */
%Sheetname(Interview);
%Rpt_Interview_Duration;

/* write core/module split tables */
%Sheetname(CoreModule);
%Rpt_CoreModule_Duration;

/* write section duration tables */
%Sheetname(Section);
%Rpt_Section_Duration;

/* make longest question duration tables for quarter 42 */
%Make_Long(42);
/* write longest question duration tables for quarter 42 */
%Sheetname(LongestQuestions42);
%Rpt_Long_Questions(42);

/* make longest question duration tables for quarter 43 */
%Make_Long(43);
/* write longest question duration tables for quarter 43 */
%Sheetname(LongestQuestions43);
%Rpt_Long_Questions(43);


/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */
