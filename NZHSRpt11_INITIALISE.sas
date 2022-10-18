

/*********************************************************
**                                                      **
** Create WORK copies of lib datasets                   **
**                                                      **
** YEAR 11 REPORT                                       **
** Year = 11                                            **
** Qtr = 42, 43                                         **
**                                                      **
**                                                      **
*********************************************************/


/* MAKE REFERENCE VARIABLE MACROS */

%let qtr_in=Qtr in (42, 43);     * current reporting quarter;
%let yr_is=(Year EQ 11);  					      * current reporting year;
%let key_NZHS=Qtr PSU NZHSHHID;	* key variables for sort and merge (FINAL variable names);

/* password for encryption */
%getusername(CBGSAS04,NZHSDARE,passwordvar=pwNZHS);

/* export and ods output file path */
%let path_out=C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY11_REPORT\Output\REPORT\;


/*
PSU - standardise for all WORK datasets
   NZHSFIN.NZHSFINAL_:
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   NZHSL2.NZHSCOMBO
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType'
      PSU2015        length=4    format=Z6.  label='Copy of Sampling Unit when SamplingType=PSU2015... etc'
   NZHSL2.ASKIASURVEYS
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType'
      PSU2015        length=4    format=Z6.  label='Copy of Sampling Unit when SamplingType=PSU2015... etc'
   NZHSL1.NZHSMEASUREMENTS
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType
   NZHSL1.NZHSMEASUREMENTSBP
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   NZHSL1.NZHSEXITQUESTIONS_
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   NZHSL1.NZHSCONSENTSDATALINKING
      SamplingUnit   length=5    format=7.   label='Sampling Unit Defined in SamplingType'
Qtr - standardise for all WORK datasets
   NZHSFIN.NZHSFINAL_:
      Qtr            length=3    format=3.   label='NZHS Quarter'
   NZHSL2.NZHSCOMBO
      Qtr            length=3    format=F3.  label='NZHS Quarter'
   NZHSL2.ASKIASURVEYS
      Qtr            length=3    format=3.   label='NZHS Quarter
   NZHSL1.NZHSMEASUREMENTS
      Qtr            length=3    format=F3.  label='NZHS Quarter'
   NZHSL1.NZHSMEASUREMENTSBP
      Qtr            length=3    format=F3.  label='NZHS Quarter'
   NZHSL1.NZHSEXITQUESTIONS_
      Qtr            length=3    format=F3.  label='NZHS Quarter'
   NZHSL1.NZHSCONSENTSDATALINKING
      Qtr            length=5    format=F3.  label='NZHS Quarter'
NZHSHHID - standardise for all WORK datasets
   NZHSFIN.NZHSFINAL_:
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL2.NZHSCOMBO
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL2.ASKIASURVEYS
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL1.NZHSMEASUREMENTS
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL1.NZHSMEASUREMENTSBP
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL1.NZHSEXITQUESTIONS_
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'
   NZHSL1.NZHSCONSENTSDATALINKING
      NZHSHHID       length=11   format=$11. label='NZHS Household ID'

do this:

EXCEPT FOR FINAL:
before set statement:
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
in set statement add option:
   rename=(SamplingUnit=old_SamplingUnit)
in data step add statements:
   SamplingUnit=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;
    
IN FINAL:
in data step add statement:
   format Qtr F3.;
   
*/

**********************************************************
**                                                      **
** MAKE REFERENCE DATASETS                              **
**                                                      **
*********************************************************;

/* 
   Use NZHSFIN.NZHSFINAL... as source datasets
   standardise PSU attributes
   keep only keylist variables
   Use to partition other source datasets by Adult/Child, Year/Quarter

   datasets:
   * REF_YA
   * REF_QA42
   * REF_QA43
   * REF_YC
   * REF_QC42
   * REF_QC43

*/

/* Adult REF datasets */
data REF_YA(label="REFERENCE Adult Year");
   set NZHSFIN.NZHSFINALADULTY11(keep=&key_NZHS);
   format Qtr F3.;
run;

data 
      REF_QA42(label="REFERENCE Adult Qtr 42")
      REF_QA43(label="REFERENCE Adult Qtr 43")
   ;
   set REF_YA;
   if Qtr = 42 then output REF_QA42;
   if Qtr = 43 then output REF_QA43;
run;

/* Child REF datasets */
data REF_YC(label="REFERENCE Child Final Year");
   set NZHSFIN.NZHSFINALCHILDY11(keep=&key_NZHS);
   format Qtr F3.;
run;

data 
      REF_QC42(label="REFERENCE Child Qtr 42")
      REF_QC43(label="REFERENCE Child Qtr 43")
   ;
   set REF_YC;
   if Qtr = 42 then output REF_QC42;
   if Qtr = 43 then output REF_QC43;
run;


**********************************************************
**                                                      **
** MAKE FINAL DATASETS                                  **
**                                                      **
*********************************************************;

/*
   Use as source NZHSFIN.NZHSFINAL...
   standardise PSU attributes
   partition with REF_...

   datasets:
   * FINAL_YA
   * FINAL_QA42
   * FINAL_QA43
   * FINAL_YC
   * FINAL_QC42
   * FINAL_QC43

*/

/* Adult FINAL datasets */
data FINAL_YA(label="FINAL Adult Year" compress=yes);
   set NZHSFIN.NZHSFINALADULTY11;
   format Qtr F3.;
run;

data
      FINAL_QA42(label="FINAL Adult Qtr 42")
      FINAL_QA43(label="FINAL Adult Qtr 43")
   ;
   set FINAL_YA;
   if Qtr = 42 then output FINAL_QA42;
   if Qtr = 43 then output FINAL_QA43;
run;


/* Child FINAL datasets */
data FINAL_YC(label="FINAL Child Year" compress=yes);
   set NZHSFIN.NZHSFINALCHILDY11;
   format Qtr F3.;
run;

data
      FINAL_QC42(label="FINAL Child Qtr 42")
      FINAL_QC43(label="FINAL Child Qtr 43")
   ;
   set FINAL_YC;
   if Qtr = 42 then output FINAL_QC42;
   if Qtr = 43 then output FINAL_QC43;
run;


**********************************************************
**                                                      **
** MAKE COMBO DATASETS                                  **
**                                                      **
*********************************************************;

/* MAKE WORK.COMBO DATASETS */
/*
   Use as source NZHSL2.NZHSCOMBO
   rename SamplingUnit to PSU/standardise attributes
   Use as source WORK.COMBO
   partition with REF_... and selectedadult/selectedchild

   datasets:
   * FINAL_YA
   * FINAL_QA42
   * FINAL_QA43
   * FINAL_YC
   * FINAL_QC42
   * FINAL_QC43
*/

data COMBO;
   retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL2.NZHSCOMBO(rename=(SamplingUnit=old_SamplingUnit) where=&yr_is);
   PSU=old_SamplingUnit;
   drop old_SamplingUnit;
run;

data COMBO_YA(label="COMBO Adult Year" compress=yes);
   merge 
      COMBO(in=base where=(selectedadult))
      REF_YA(in=ref);
   by &key_NZHS;
   if base and ref;
run;

data 
      COMBO_QA42(label="COMBO Adult Qtr 42" compress=yes)
      COMBO_QA43(label="COMBO Adult Qtr 43" compress=yes);
   set COMBO_YA;
   if Qtr = 42 then output COMBO_QA42;
   if Qtr = 43 then output COMBO_QA43;
run;

data COMBO_YC(label="COMBO Child Year" compress=yes);
   merge 
      COMBO(in=base where=(selectedchild))
      REF_YC(in=ref);
   by &key_NZHS;
   if base and ref;
run;

data 
      COMBO_QC42(label="COMBO Child Qtr 42" compress=yes)
      COMBO_QC43(label="COMBO Child Qtr 43" compress=yes);
   set COMBO_YC;
   if Qtr = 42 then output COMBO_QC42;
   if Qtr = 43 then output COMBO_QC43;
run;

data COMBO_Y(label="COMBO All" compress=yes);
   set 
      COMBO_YA
      COMBO_YC
   ;
run;

proc delete data=COMBO;
run;


**********************************************************
**                                                      **
** MAKE ASKIASURVEYS DATASETS                           **
**                                                      **
*********************************************************;


/* MAKE WORK.ASKIA DATASETS */
/*
   Use as source NZHSL2.ASKIASURVEYSADULT, NZHSL2.ASKIASURVEYSCHILD
   unencrypt source datasets
   rename SamplingUnit to PSU/standardise attributes
   Partition with REF_...  
*/

/* ASKIASURVEYS ADULT */
data SURVEYS_ADULT;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL2.NZHSASKIASURVEYSADULTY11(
         encryptkey="&pwNZHS" 
         rename=(SamplingUnit=old_SamplingUnit)
         where=(&qtr_in)
         );
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;
run;

data SURVEYS_YA(label="ASKIASURVEYS Adult Year");
   merge
      SURVEYS_ADULT(in=askia)
      REF_YA(in=ref);
   by &key_NZHS;
   if askia and ref;
run;

data 
      SURVEYS_QA42(label="ASKIASURVEYS Adult Qtr 42")
      SURVEYS_QA43(label="ASKIASURVEYS Adult Qtr 43");
   ;
   set SURVEYS_YA;
   if Qtr = 42 then output SURVEYS_QA42;
   if Qtr = 43 then output SURVEYS_QA43;
run;


/* ASKIASURVEYS CHILD */
data SURVEYS_CHILD;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL2.NZHSASKIASURVEYSCHILDY11(
         encryptkey="&pwNZHS" 
         rename=(SamplingUnit=old_SamplingUnit)
         where=(&qtr_in)
         );
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;
run;

data SURVEYS_YC(label="ASKIASURVEYS Child Year");
   merge
      SURVEYS_CHILD(in=askia)
      REF_YC(in=ref);
   by &key_NZHS;
   if askia and ref;
run;

data 
      SURVEYS_QC42(label="ASKIASURVEYS Child Qtr 42")
      SURVEYS_QC43(label="ASKIASURVEYS Child Qtr 43");
   ;
   set SURVEYS_YC;
   if Qtr = 42 then output SURVEYS_QC42;
   if Qtr = 43 then output SURVEYS_QC43;
run;




**********************************************************
**                                                      **
** MAKE MEASUREMENT DATASETS                            **
**                                                      **
*********************************************************;

/*
   Use as source NZHSL1.NZHSMEASUREMENTS/NZHSMEASUREMENTSBP
   Use as source NZHSL1.NZHSCONSENTSDATALINKING
   rename PSU2015 to PSU/standardise attributes
*/

/* make Adult and Child MEASURE_... 
   - for height/weight/waist 
   - rename PSU2015 to PSU/standardise attributes
*/

/* all in qtr 42/43 */
data 
      MEASURE_YA
      MEASURE_YC
   ;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL1.NZHSMEASUREMENTS(rename=(SamplingUnit=old_SamplingUnit) where=(&qtr_in));
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;

   if adultchild="A" then output MEASURE_YA;
   if adultchild="C" then output MEASURE_YC;

run;

proc sort data=MEASURE_YA;
   by &key_NZHS;
run;

/* Adult Year by REF */
data MEASURE_YA(label="Adult Measurements Year" compress=yes);
   merge
      MEASURE_YA(in=base)
      REF_YA(in=ref);
   by &key_NZHS;
   if base and ref;
run;

/* Adult Quarter by REF */
data 
      MEASURE_QA42(label="Adult Measurements Qtr 42" compress=yes)
      MEASURE_QA43(label="Adult Measurements Qtr 43" compress=yes)
   ;
   set MEASURE_YA;
   if Qtr = 42 then output MEASURE_QA42;
   if Qtr = 43 then output MEASURE_QA43;

run;


/* Child by REF_YC */
proc sort data=MEASURE_YC;
   by &key_NZHS;
run;

/* Child Year by REF */
data MEASURE_YC(label="Child Measurements Year" compress=yes);
   merge
      MEASURE_YC(in=base)
      REF_YC(in=ref);
   by &key_NZHS;
   if base and ref;
run;

/* Child Quarter by REF */
data 
      MEASURE_QC42(label="Child Measurements Qtr 42" compress=yes)
      MEASURE_QC43(label="Child Measurements Qtr 43" compress=yes)
   ;
   set MEASURE_YC;
   if Qtr = 42 then output MEASURE_QC42;
   if Qtr = 43 then output MEASURE_QC43;

run;


data MEASUREBP_YA;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL1.NZHSMEASUREMENTSBP(rename=(SamplingUnit=old_SamplingUnit) where=(&qtr_in));
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;

run;

proc sort data=MEASUREBP_YA;
   by &key_NZHS;
run;

/* Adult BP Year by REF */
data MEASUREBP_YA(label="Adult BP measurements Year" compress=yes);
   merge
      MEASUREBP_YA(in=base)
      REF_YC(in=ref);
   by &key_NZHS;
   if base and ref;
run;

/* Adult BP Quarter by REF */
data 
      MEASUREBP_QA42(label="Adult BP Measurements Qtr 42" compress=yes)
      MEASUREBP_QA43(label="Adult BP Measurements Qtr 43" compress=yes)
   ;
   set MEASUREBP_YA;   
   if Qtr = 42 then output MEASUREBP_QA42;
   if Qtr = 43 then output MEASUREBP_QA43;

run;



   
/* Q40 didn't use NZHSL1.NZHSCONSENTSDATALINKING.
   * ASKIA_YA:
      data DL_GIVEN_A(drop=A6_08 A6_10Surname A6_10DOB);
         set ASKIA_YA(where=(A6_08="1") keep=&keylist A6_08 A6_10Surname A6_10DOB);

         is_adult=1;
         is_child=0;
         count_DL_name = (A6_10Surname NE '' and length(strip(A6_10Surname)) GT 1);
         count_DL_DOB = (A6_10DOB NE '' and length(strip(A6_10DOB)) GT 1);

      run;

   * ASKIA_YC:
      data DL_GIVEN_C(drop=C6_09 C6_11Surname C6_11DOB);
         set ASKIA_YC(where=(C6_09="1") keep=&keylist C6_09 C6_11Surname C6_11DOB);

         is_adult=0;
         is_child=1;
         count_DL_name = (C6_11Surname NE '' and length(strip(C6_11Surname)) GT 1);
         count_DL_DOB = (C6_11DOB NE '' and length(strip(C6_11DOB)) GT 1);

      run;
/*



/********************************************************/

**********************************************************
**                                                      **
** MAKE EXIT DATASETS                                   **
**                                                      **
*********************************************************;


/*
   Use as source NZHSL1.NZHSEXITQUESTIONS...
   rename PSU2015 to PSU/standardise attributes
   unencrypt source datasets
*/

/* Adult Exit */
data EXIT_YA;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL1.nzhsexitquestionsadult(encryptkey="&pwNZHS" rename=(SamplingUnit=old_SamplingUnit) where=(&qtr_in));
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;
run;

proc sort data=EXIT_YA;
   by &key_NZHS;
run;

/* adult exit by REF */
data Exit_YA(label="Adult Exit Year" compress=yes);
   merge
      Exit_YA(in=base)
      REF_YA(in=ref)
   ;
   by &key_NZHS;
   if base and ref;
run;

/* Adult exit quarter by REF */
data 
      EXIT_QA42(label="Adult Exit Qtr 42" compress=yes)
      EXIT_QA43(label="Adult Exit Qtr 43" compress=yes)
   ;
   set Exit_YA;
   if Qtr = 42 then output EXIT_QA42;
   if Qtr = 43 then output EXIT_QA43;

run;


/* Child Exit */
data EXIT_YC;
   Retain Qtr PSU NZHSHHID;
   attrib
      PSU            length=5    format=7.   label='Sampling Unit Defined in SamplingType'
   ;
   set NZHSL1.nzhsexitquestionschild(encryptkey="&pwNZHS" rename=(SamplingUnit=old_SamplingUnit) where=(&qtr_in));
   PSU=old_SamplingUnit;
   drop old_SamplingUnit SamplingType;
run;

proc sort data=EXIT_YC;
   by &key_NZHS;
run;

/* child exit by REF */
data EXIT_YC(label="Child Exit Year" compress=yes);
   merge
      EXIT_YC(in=base)
      REF_YA(in=ref)
   ;
   by &key_NZHS;
   if base and ref;
run;

/* Child exit quarter by REF */
data 
      EXIT_QC42(label="Child Exit Qtr 42" compress=yes)
      EXIT_QC43(label="Child Exit Qtr 43" compress=yes)
   ;
   set EXIT_YC;
   if Qtr = 42 then output EXIT_QC42;
   if Qtr = 43 then output EXIT_QC43;

run;

/********************************************************/


/* MAKE WORK.YEAR_QTR REFERENCE TABLE */
/* to Match Year and Quarter */

DATA  Year_Qtr (label="Year/Quarter Reference Table");
   input year qtr;
   attrib 
      year  length=3       format=3.      label='NZHS Year'
      qtr   length=3       format=F3.     label='NZHS Quarter';
   datalines;
11 42
11 43
;

/********************************************************/

