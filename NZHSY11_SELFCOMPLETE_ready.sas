
*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 SELF_COMPLETE                                                                                              **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE ADULT SELF-COMPLETE DATASET MACRO
      %Make_AdultSC
      uses FINAL_YA
         -> ADULT_SELF
         -> by_Gender_adult_42
         -> by_Gender_adult_43
         -> by_Gender_adult_43
         -> by_AGE_GROUP_adult_42
         -> by_AGE_GROUP_adult_43
         -> by_ETHNIC_GROUP_adult_42
         -> by_ETHNIC_GROUP_adult_43
         -> by_ALL_adult_42
         -> by_ALL_adult_43
         -> SELFCOMPLETE_ADULT

   3. MAKE ADULT SELF-COMPLETE DATASET MACRO
      %Make_ChildSC
         -> CHILD_SELF
         -> by_Gender_child_42
         -> by_Gender_child_43
         -> by_AGE_GROUP_child_42
         -> by_AGE_GROUP_child_43
         -> by_ETHNIC_GROUP_child_42
         -> by_ETHNIC_GROUP_child_43
         -> by_ALL_child_42
         -> by_ALL_child_43
         -> SELFCOMPLETE_CHILD
         -> 

   4. REPORT SELF-COMPLETE MACRO
      %Rpt_SelfComplete
      proc print

   5. RUN MACROS AND SET UP ODS
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
%let ods_file=NZHS_Y11_SelfComplete.xlsx;



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




********** MAKE ADULT SELF-COMPLETE DATASETS MACRO **********;


%macro Make_AdultSC;

/* Create Gender and Age Group variables */
data ADULT_SELF(keep=&key_NZHS AD_01 A6_12 A6_13 A5_30bIntro Gender Age_Group);
   set FINAL_YA;

   attrib
      Gender      length=$12     label='Gender'
      Age_Group   length=$12     label='Age Group'
   ;

   select (AD_01);
      when ('1')     Gender='Male';
      otherwise      Gender='Female';
   end;

   select;
      when (age in (15:19)) Age_Group='15-19 years';
      when (age in (15:19)) Age_Group='20-24 years';
      when (age in (15:19)) Age_Group='25-34 years';
      when (age in (15:19)) Age_Group='35-44 years';
      when (age in (15:19)) Age_Group='45-54 years';
      when (age in (15:19)) Age_Group='55-64 years';
      otherwise Age_Group='65+ years';
   end;

run;


/* Create Ethnic Group variables from merge with COMBO */
data ADULT_SELF(drop=AdultEthnicityMPAO);
   merge
      ADULT_SELF(in=a)
      COMBO_YA(in=b keep=&key_NZHS AdultEthnicityMPAO);
   by &key_NZHS;
   if a;

   attrib
      Eligible                         label='Eligible'
      Ethnic_Group      length=$12     label='Ethnic Group'
   ;
 
   Eligible = 1;

   SELECT (AdultEthnicityMPAO);
      WHEN ('A') Ethnic_Group='Asian';
      WHEN ('M') Ethnic_Group='Maori';
      WHEN ('P') Ethnic_Group='Pacific';
      WHEN ('O') Ethnic_Group='Other';
      OTHERWISE Ethnic_Group='Other';
   END;

run;


/* create exemption binaries */
data ADULT_SELF;
   set ADULT_SELF;

   attrib
      Exempt_Cog                       label='Cognitive'
      Exempt_Lang                      label='Interpreter'
      Exempt_Priv                      label='Privacy'
      Complete                         label='Completed'
   ;
   
   Exempt_Cog=(A6_12 EQ "1");
   Exempt_Lang=(A6_13 EQ "1");
   Exempt_Priv=(A5_30bIntro eq "2");
   Complete=(A5_30bIntro NE '.');

Run;


/* create count by group datasets */
proc sql;

   /* SUMMARY BY Gender */
   /* Qtr 42 */
   create table temp as select
     Gender label="Gender"
   , count(Gender) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where Qtr EQ 42
   group by Gender
   ORDER Gender DESC;

   create table by_Gender_adult_42 as select
     Gender
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY BY Gender */
   /* Qtr 43 */
   create table temp as select
     Gender label="Gender"
   , count(Gender) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where Qtr EQ 43
   group by Gender
   ORDER Gender DESC;

   create table by_Gender_adult_43 as select
     Gender
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY BY AGE GROUP */
   /* Qtr 42 */
   create table temp as select
     Age_Group label="Age Group"
   , count(Age_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where Qtr EQ 42
   group by Age_Group
   ORDER Age_Group;

   create table by_AGE_GROUP_adult_42 as select
     Age_Group
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* Qtr 43 */
   create table temp as select
     Age_Group label="Age Group"
   , count(Age_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where Qtr EQ 43
   group by Age_Group
   ORDER Age_Group;

   create table by_AGE_GROUP_adult_43 as select
     Age_Group
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;


   /* SUMMARY BY ETHNIC GROUP */
   /* Qtr 42 */
   create table temp as select
     Ethnic_Group label="Ethnic Group"
   , count(Ethnic_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where qtr EQ 42
   group by Ethnic_Group
   ORDER Ethnic_Group;

   create table by_ETHNIC_GROUP_adult_42 as select
     Ethnic_Group
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

      /* Qtr 43 */
   create table temp as select
     Ethnic_Group label="Ethnic Group"
   , count(Ethnic_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where qtr EQ 43
   group by Ethnic_Group
   ORDER Ethnic_Group;

   create table by_ETHNIC_GROUP_adult_43 as select
     Ethnic_Group
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY TOTAL */
   /* Qtr 42 */
   create table temp as select
     count(*) as n_Eligible label = "Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where qtr EQ 42;

   create table by_ALL_adult_42 as select
     "All" as ALL label="All"
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* Qtr 43 */
   create table temp as select
     count(*) as n_Eligible label = "Eligible (N)"
   , sum(Exempt_Cog) as n_Cog label="Cognitive Exempt (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from ADULT_SELF
   where qtr EQ 43;

   create table by_ALL_adult_43 as select
     "All" as ALL label="All"
   , n_Eligible
   , n_Cog
   , n_Cog/n_Eligible*100 as pc_COG label="Cognitive Exempt (%)" format=5.1
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

quit;


/* create generalised Class variables */
data by_GENDER_adult_42(drop=Gender);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_GENDER_adult_42;
   LENGTH Class $12.;
   Class = Gender;
   Qtr=42;
run;
data by_GENDER_adult_43(drop=Gender);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_GENDER_adult_43;
   LENGTH Class $12.;
   Class = Gender;
   Qtr=43;
run;

data by_AGE_GROUP_adult_42(drop=Age_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_AGE_GROUP_adult_42;
   LENGTH Class $12.;
   Class = Age_Group;
   Qtr=42;
run;
data by_AGE_GROUP_adult_43(drop=Age_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_AGE_GROUP_adult_43;
   LENGTH Class $12.;
   Class = Age_Group;
   Qtr=43;
run;

data by_ETHNIC_GROUP_adult_42(drop=Ethnic_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ETHNIC_GROUP_adult_42;
   LENGTH Class $12.;
   Class = Ethnic_Group;
   Qtr=42;
run;
data by_ETHNIC_GROUP_adult_43(drop=Ethnic_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ETHNIC_GROUP_adult_43;
   LENGTH Class $12.;
   Class = Ethnic_Group;
   Qtr=43;
run;

data by_ALL_adult_42(drop=ALL);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ALL_adult_42;
   LENGTH Class $12.;
   Class = ALL;
   Qtr=42;
run;
data by_ALL_adult_43(drop=ALL);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ALL_adult_43;
   LENGTH Class $12.;
   Class = ALL;
   Qtr=43;
run;


/* Append class datasets into single summary */
data SELFCOMPLETE_ADULT;
   retain Qtr Class;
   set 
      by_GENDER_adult_42
      by_GENDER_adult_43
      by_AGE_GROUP_adult_42
      by_AGE_GROUP_adult_43
      by_ETHNIC_GROUP_adult_42
      by_ETHNIC_GROUP_adult_43
      by_ALL_adult_42
      by_ALL_adult_43
      ;

   SELECT(Class);
      WHEN ("Male") ORDER_OUT=1;
      WHEN ("Female") ORDER_OUT=2;
      WHEN ("15-19 years") ORDER_OUT=3;
      WHEN ("20-24 years") ORDER_OUT=4;
      WHEN ("25-34 years") ORDER_OUT=5;
      WHEN ("35-44 years") ORDER_OUT=6;
      WHEN ("45-54 years") ORDER_OUT=7;
      WHEN ("55-64 years") ORDER_OUT=8;
      WHEN ("65+ years") ORDER_OUT=9;
      WHEN ("Asian") ORDER_OUT=12;
      WHEN ("Maori") ORDER_OUT=10;
      WHEN ("Pacific") ORDER_OUT=11;
      WHEN ("Other") ORDER_OUT=13;
      WHEN ("All") ORDER_OUT=14;
   END;

run;


proc sort 
      data=SELFCOMPLETE_ADULT 
      out=SELFCOMPLETE_ADULT(drop=ORDER_OUT);
   by qtr ORDER_OUT;
run;

%mend Make_AdultSC;

********** END MAKE ADULT SELF-COMPLETE DATASETS MACRO **********;

********** MAKE CHILD SELF-COMPLETE DATASETS MACRO **********;

%macro Make_ChildSC;

/* Create Gender and Age Group variables */
data CHILD_SELF(keep=&key_NZHS CD_02 CD_03c C6_13 CDWIntro CPS1_05 Gender Age_Group);
   set FINAL_YC;

   attrib
      Gender      length=$12     label='Gender'
      Age_Group   length=$12     label='Age Group'
   ;

   select (CD_02);
      when ('1')     Gender='Male';
      otherwise      Gender='Female';
   end;

   select (CD_03c);
      when ('1') Age_Group='0-11 months';
      when ('2') Age_Group='12-23 months';
      when ('3') Age_Group='2-4 years';
      when ('4') Age_Group='5-9 years';
      when ('5') Age_Group='10-14 years';
   end;

run;


/* Create Ethnic Group variables from merge with COMBO */
data CHILD_SELF(drop=ChildEthnicityMPAO);
   merge
      CHILD_SELF(in=a)
      COMBO_YC(in=b keep=&key_NZHS ChildEthnicityMPAO);
   by &key_NZHS;
   if a;

   attrib
      Eligible                         label='Eligible'
      Ethnic_Group      length=$12     label='Ethnic Group'
   ;
 
   Eligible = 1;

   SELECT (ChildEthnicityMPAO);
      WHEN ('A') Ethnic_Group='Asian';
      WHEN ('M') Ethnic_Group='Maori';
      WHEN ('P') Ethnic_Group='Pacific';
      WHEN ('O') Ethnic_Group='Other';
      OTHERWISE Ethnic_Group='Other';
   END;

run;


/* create exemption binaries */
data CHILD_SELF;
   set CHILD_SELF;

   attrib
      Exempt_Lang                      label='Interpreter'
      Exempt_Priv                      label='Privacy'
      Complete                         label='Completed'
   ;
   
   Exempt_Lang=(C6_13 EQ "1");
   Exempt_Priv=(CDWIntro eq "2");
   Complete=(CPS1_05 NE '.');

Run;



/* create count by group datasets */
proc sql;

   /* SUMMARY BY Gender */
   /* Qtr 42 */
   create table temp as select
     Gender label="Gender"
   , count(Gender) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where Qtr EQ 42
   group by Gender
   ORDER Gender DESC;

   create table by_Gender_child_42 as select
     Gender
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY BY Gender */
   /* Qtr 43 */
   create table temp as select
     Gender label="Gender"
   , count(Gender) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where Qtr EQ 43
   group by Gender
   ORDER Gender DESC;

   create table by_Gender_child_43 as select
     Gender
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY BY AGE GROUP */
   /* Qtr 42 */
   create table temp as select
     Age_Group label="Age Group"
   , count(Age_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where Qtr EQ 42
   group by Age_Group
   ORDER Age_Group;

   create table by_AGE_GROUP_child_42 as select
     Age_Group
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* Qtr 43 */
   create table temp as select
     Age_Group label="Age Group"
   , count(Age_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where Qtr EQ 43
   group by Age_Group
   ORDER Age_Group;

   create table by_AGE_GROUP_child_43 as select
     Age_Group
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;


   /* SUMMARY BY ETHNIC GROUP */
   /* Qtr 42 */
   create table temp as select
     Ethnic_Group label="Ethnic Group"
   , count(Ethnic_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where qtr EQ 42
   group by Ethnic_Group
   ORDER Ethnic_Group;

   create table by_ETHNIC_GROUP_child_42 as select
     Ethnic_Group
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

      /* Qtr 43 */
   create table temp as select
     Ethnic_Group label="Ethnic Group"
   , count(Ethnic_Group) as n_Eligible label="Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where qtr EQ 43
   group by Ethnic_Group
   ORDER Ethnic_Group;

   create table by_ETHNIC_GROUP_child_43 as select
     Ethnic_Group
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* SUMMARY TOTAL */
   /* Qtr 42 */
   create table temp as select
     count(*) as n_Eligible label = "Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where qtr EQ 42;

   create table by_ALL_child_42 as select
     "All" as ALL label="All"
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

   /* Qtr 43 */
   create table temp as select
     count(*) as n_Eligible label = "Eligible (N)"
   , sum(Exempt_Lang) as n_Lang label="Interpreter Exempt (N)"
   , sum(Exempt_Priv) as n_Priv label="Privacy Exempt (N)"
   , sum(Complete) as n_Complete label="Completed (N)"
   from CHILD_SELF
   where qtr EQ 43;

   create table by_ALL_child_43 as select
     "All" as ALL label="All"
   , n_Eligible
   , n_Lang
   , n_Lang/n_Eligible*100 as pc_LANG label="Interpreter Exempt (%)" format=5.1
   , n_Priv
   , n_Priv/n_Eligible*100 as pc_PRIV label="Privacy Exempt (%)" format=5.1
   , n_Complete
   , n_Complete/n_Eligible*100 as pc_Complete label="Completed (%)" format=5.1
   from temp;

quit;



/* create generalised Class variables */
data by_GENDER_child_42(drop=Gender);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_GENDER_child_42;
   LENGTH Class $12.;
   Class = Gender;
   Qtr=42;
run;
data by_GENDER_child_43(drop=Gender);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_GENDER_child_43;
   LENGTH Class $12.;
   Class = Gender;
   Qtr=43;
run;

data by_AGE_GROUP_child_42(drop=Age_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_AGE_GROUP_child_42;
   LENGTH Class $12.;
   Class = Age_Group;
   Qtr=42;
run;
data by_AGE_GROUP_child_43(drop=Age_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_AGE_GROUP_child_43;
   LENGTH Class $12.;
   Class = Age_Group;
   Qtr=43;
run;

data by_ETHNIC_GROUP_child_42(drop=Ethnic_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ETHNIC_GROUP_child_42;
   LENGTH Class $12.;
   Class = Ethnic_Group;
   Qtr=42;
run;
data by_ETHNIC_GROUP_child_43(drop=Ethnic_Group);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ETHNIC_GROUP_child_43;
   LENGTH Class $12.;
   Class = Ethnic_Group;
   Qtr=43;
run;

data by_ALL_child_42(drop=ALL);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ALL_child_42;
   LENGTH Class $12.;
   Class = ALL;
   Qtr=42;
run;
data by_ALL_child_43(drop=ALL);
   attrib
      Qtr      length=3    Format=F3.     Label='NZHS Quarter'
   ;
   set by_ALL_child_43;
   LENGTH Class $12.;
   Class = ALL;
   Qtr=43;
run;



/* Append class datasets into single summary */
data SELFCOMPLETE_CHILD;
   retain Qtr Class;
   set 
      by_GENDER_child_42
      by_GENDER_child_43
      by_AGE_GROUP_child_42
      by_AGE_GROUP_child_43
      by_ETHNIC_GROUP_child_42
      by_ETHNIC_GROUP_child_43
      by_ALL_child_42
      by_ALL_child_43
      ;

   SELECT(Class);
   WHEN ("Male") ORDER_OUT=1;
         WHEN ("Female") ORDER_OUT=2;
         WHEN ("0-11 months") ORDER_OUT=3;
         WHEN ("12-23 months") ORDER_OUT=4;
         WHEN ("2-4 years") ORDER_OUT=5;
         WHEN ("5-9 years") ORDER_OUT=6;
         WHEN ("10-14 years") ORDER_OUT=7;
         WHEN ("Asian") ORDER_OUT=10;
         WHEN ("Maori") ORDER_OUT=8;
         WHEN ("Pacific") ORDER_OUT=9;
         WHEN ("Other") ORDER_OUT=11;
         WHEN ("All") ORDER_OUT=12;
   END;

run;



proc sort 
      data=SELFCOMPLETE_CHILD 
      out=SELFCOMPLETE_CHILD(drop=ORDER_OUT);
   by qtr ORDER_OUT;
run;


%mend Make_ChildSC;

********** END MAKE CHILD SELF-COMPLETE DATASETS MACRO **********;


********** REPORT SELF-COMPLETE MACRO **********;

 %macro Rpt_SelfComplete;

/* Output ADULT Results */
title "Adult Self-Complete Section";
proc print data=SELFCOMPLETE_ADULT noobs label;
   by Qtr;
run;
title;

/* Output CHILD Results */
title "Child Self-Complete Section";
proc print data=SELFCOMPLETE_CHILD noobs label;
   by Qtr;
run;
title;


%mend Rpt_SelfComplete;


********** END REPORT SELF-COMPLETE MACRO **********;

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

%Make_AdultSC;
%Make_ChildSC;

%Sheetname(SelfComplete);
%Rpt_SelfComplete;

/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */

