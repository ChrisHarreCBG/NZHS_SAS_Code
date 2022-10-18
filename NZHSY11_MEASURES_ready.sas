




*************************************************************************************************************************
**                                                                                                                     **
**                                                                                                                     **
**  YEAR 11 MEASURES                                                                                                   **
**                                                                                                                     **
**                                                                                                                     **
*************************************************************************************************************************;

/* 

   1. Use NZHSRpt11_INITIALISE.sas to initialise source and ref datasets
      assign output filename to ods_file (as xlsx)

   2. MAKE MEASURE BP STATUS DATASET MACRO
      %Make_BPStatus
         uses MEASUREBP_YA, COMBO_YA
         -> MSR_BP2
         -> MSR_BP3
         -> MSR_BP

   3. MAKE FIRST DECIMAL DATASETS MACRO
      %Make_Decimal1
         uses FINAL_YA, FINAL_YC
         -> MSR_DIGIT1_A
         -> MSR_DIGIT1_HT_A
         -> MSR_DIGIT1_WT_A
         -> MSR_DIGIT1_WA_A
         -> MSR_DIGIT2_A
      
         -> MSR_DIGIT1_C
         -> MSR_DIGIT1_HT_C
         -> MSR_DIGIT1_WT_C
         -> MSR_DIGIT1_WA_C
         -> MSR_DIGIT2_C
         
   4. MAKE THIRD MEASURE DATASETS MACRO
      %Make_Measure3
         uses MEASURE_YA, MEASURE_YC
         -> MSR_HT3_A
         -> MSR_WT3_A
         -> MSR_WA3_A
         -> MSR_3_A
      
         -> MSR_HT3_C
         -> MSR_WT3_C
         -> MSR_WA3_C
         -> MSR_3_C

   5. MAKE MEASURE CONSENT DATASETS MACRO
      %Make_MeasureConsent
         uses COMBO_YA, COMBO_YC
         -> MSR_STATUS_A
         -> MSR_STATUS_C



   6. REPORT BP STATUS MACRO
      %Rpt_BPStatus
      proc tabulate

   7. REPORT FIRST DIGIT MACRO 
      %Rpt_Decimal1
      proc tabulate

   8. REPORT THIRD MEASURES MACRO
      %Rpt_Measure3
      proc tabulate

   9. REPORT MEASURE CONSENT MACRO
      %Rpt_MeasureConsent
      proc tabulate

   1. RUN MACROS AND SET UP ODS
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
%let ods_file=NZHS_Y11_Measurements.xlsx;



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


********** MAKE BP STATUS DATASETS MACRO **********;

%macro Make_BPStatus;

/* make measure 2 and 3 datasets */
data 
      MSR_BP2(rename=(SystolicBP=S_BP2 DiastolicBP=D_BP2) drop=MeasureNumber)
      MSR_BP3(rename=(SystolicBP=S_BP3 DiastolicBP=D_BP3) drop=MeasureNumber)
   ;

   set MEASUREBP_YA(where=(MeasureNumber in (2, 3)) keep=&key_NZHS MeasureNumber SystolicBP DiastolicBP);

   if MeasureNumber=2 then output MSR_BP2;
   if MeasureNumber=3 then output MSR_BP3; 

run;

/* sort by key_NZHS for merge */
proc sort data=MSR_BP2;
   by &key_NZHS;
run;
proc sort data=MSR_BP3;
   by &key_NZHS;
run;

/* merge with COMBO for age group and assign status */
data MSR_BP(keep=&key_NZHS AgeGroup Status);
   merge
      MSR_BP2(in=inBP2)
      MSR_BP3
      COMBO_YA(in=inCOMBO keep=&key_NZHS AdultAgeGroup Year)
   ;
   by &key_NZHS;

   if inBP2 and inCombo;

   /* create SystolicBP/DiastolicBP variables */
   SystolicBP = min(S_BP2,S_BP3);
   DiastolicBP = min(D_BP2,D_BP3);

      /* create status variable */
   	length status $15;
   	if SystolicBP < 130 and DiastolicBP < 80 then Status = "Ideal";
   	if SystolicBP >= 130 and SystolicBP <= 169 then Status = "Raised";
   	if DiastolicBP >= 80 and DiastolicBP <= 99 then Status = "Raised";
   	if SystolicBP >= 170 or DiastolicBP >= 100 then Status = "Very raised";

   /* create agegroup variable */
   length AgeGroup $5;
   select (AdultAgeGroup);
   	when (1) Agegroup = "15-19";
   	when (2) Agegroup = "20-24";
   	when (3) Agegroup = "25-34";
   	when (4) Agegroup = "35-44";
   	when (5) Agegroup = "45-54";
   	when (6) Agegroup = "55-64";
   	when (7) Agegroup = "65-74";
   	when (8) Agegroup = "75+";
   	otherwise call missing (Agegroup);
   end;

run;


%mend Make_BPStatus;


********** END MAKE BP STATUS DATASETS MACRO **********;



********** MAKE FIRST DECIMAL DATASETS MACRO **********;

%macro Make_Decimal1;

/* ADULT */
data MSR_DIGIT1_A(keep=&key_NZHS HTDigit1 WTDigit1 WADigit1);
   set FINAL_YA;

   /* first decimals for height/weight/waist */
   array m_in[3] measureHT1 measureWT1 measureWA1;
   array m_out[3] $ HTDigit1 WTDigit1 WADigit1;

   
   do i = 1 to 3;
      m_out[i]=substr(reverse(put(INT(10*m_in[i]),f7.1)),3,1);
   end;

run;


/* check missing counts */
/*

   data MSR_MISS_A;
      set FINAL_YA(keep=&key_NZHS measureHT1 measureWT1 measureWA1);
      m_ht = missing(measureHT1);
      m_wt = missing(measureWT1);
      m_wa = missing(measureWA1);
   run;

   proc freq data=MSR_MISS_A;
      title 'Inspect missing measures';
      tables m_: / &fno;
   run;
   title;
*/
   /* lots missing:
      measure = not missing + missing
      HT = 494 + 3940
      WT = 486 + 3948
      WA = 491 + 3943

      check measurestatus?

   */

/* adult single measures */
/* HEIGHT */
data MSR_DIGIT1_HT_A(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_A;
   
   MeasureType=1;
   MeasureVal = HTDIGIT1;

run;

/* WEIGHT */
data MSR_DIGIT1_WT_A(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_A;
   
   MeasureType=2;
   MeasureVal = WTDIGIT1;

run;

/* WAIST */
data MSR_DIGIT1_WA_A(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_A;
   
   MeasureType=3;
   MeasureVal = WADIGIT1;

run;

/* adult all single measures */
data MSR_DIGIT2_A;
   set 
      MSR_DIGIT1_HT_A
      MSR_DIGIT1_WT_A
      MSR_DIGIT1_WA_A
   ;
   by &key_NZHS;
run;


/* CHILD */
data MSR_DIGIT1_C(keep=&key_NZHS HTDigit1 WTDigit1 WADigit1);
   set FINAL_YC;

   /* first decimals for height/weight/waist */
   array m_in[3] measureHT1 measureWT1 measureWA1;
   array m_out[3] $ HTDigit1 WTDigit1 WADigit1;

   
   do i = 1 to 3;
      m_out[i]=substr(reverse(put(INT(10*m_in[i]),f7.1)),3,1);
   end;

run;


/* check missing counts */
/*

   data MSR_MISS_C;
      set FINAL_YC(keep=&key_NZHS measureHT1 measureWT1 measureWA1);
      m_ht = missing(measureHT1);
      m_wt = missing(measureWT1);
      m_wa = missing(measureWA1);
   run;

   proc freq data=MSR_MISS_C;
      title 'Inspect missing measures';
      tables m_: / &fno;
   run;
   title;

*/
   /* lots missing:
      measure = not missing + missing
      HT = 99 + 1224
      WT = 98 + 1225
      WA = 82 + 1241

      check measurestatus?

   */


/* child single measures */
/* HEIGHT */
data MSR_DIGIT1_HT_C(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_C;
   
   MeasureType=1;
   MeasureVal = HTDIGIT1;

run;

/* WEIGHT */
data MSR_DIGIT1_WT_C(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_C;
   
   MeasureType=2;
   MeasureVal = WTDIGIT1;

run;

/* WAIST */
data MSR_DIGIT1_WA_C(drop=HTDigit1 WTDigit1 WADigit1);
   set MSR_DIGIT1_C;
   
   MeasureType=3;
   MeasureVal = WADIGIT1;

run;

/* child all single measures */
data MSR_DIGIT2_C;
   set 
      MSR_DIGIT1_HT_C
      MSR_DIGIT1_WT_C
      MSR_DIGIT1_WA_C
   ;
   by &key_NZHS;
run;

%mend Make_Decimal1;


********** END MAKE FIRST DECIMAL DATASETS MACRO **********;



********** MAKE THIRD MEASURE DATASETS MACRO **********;

%macro Make_Measure3;

/* adult */
data
	MSR_HT3_A(keep=HT3 &key_NZHS)
	MSR_WT3_A(keep=WT3 &key_NZHS)
	MSR_WA3_A(keep=WA3 &key_NZHS)
   ;
   
   set MEASURE_YA(where=(Measure in ('HT', 'WT', 'WA')));

   select (Measure);
      when ("HT") 
			do;
				HT3=(not missing(measure3));
				output MSR_HT3_A;
			end;
		when ("WT") 
			do;
				WT3=(not missing(measure3));
				output MSR_WT3_A;
			end;
		when ("WA") 
			do;
				WA3=(not missing(measure3));
				output MSR_WA3_A;
			end;
		otherwise;
	end;

run;

   
/* Adult appended measures for tabulation */
data MSR_3_A;
	set MSR_HT3_A MSR_WT3_A MSR_WA3_A;
 	Year=11;
run;


/* child */
data
	MSR_HT3_C(keep=HT3 &key_NZHS)
	MSR_WT3_C(keep=WT3 &key_NZHS)
	MSR_WA3_C(keep=WA3 &key_NZHS)
   ;
   
   set MEASURE_YC(where=(Measure in ('HT', 'WT', 'WA')));

   select (Measure);
      when ("HT") 
			do;
				HT3=(not missing(measure3));
				output MSR_HT3_C;
			end;
		when ("WT") 
			do;
				WT3=(not missing(measure3));
				output MSR_WT3_C;
			end;
		when ("WA") 
			do;
				WA3=(not missing(measure3));
				output MSR_WA3_C;
			end;
		otherwise;
	end;

run;

   
/* Child appended measures for tabulation */
data MSR_3_C;
	set MSR_HT3_C MSR_WT3_C MSR_WA3_C;
 	Year=11;
run;


%mend Make_Measure3;

********** END MAKE THIRD MEASURE DATASETS MACRO **********;


********** MAKE MEASURE CONSENT DATASETS MACRO **********;

%macro Make_MeasureConsent;

/* create reporting datasets with rate-able status values */
data MSR_STATUS_A(drop=i);
	/* Adult */
	set COMBO_YA(keep=Qtr HeightStatusAdult WeightStatusAdult WaistStatusAdult BPDoneAdult);

	label HTconsent='Height';
	label WTconsent='Weight';
	label WAconsent='Waist';
	label BPconsent='BP';
   
   /* exclude pregnant and alert level 2 observations */
   if HeightStatusAdult not in ('7', 'P') and not missing(HeightStatusAdult);
   if WeightStatusAdult not in ('4', 'P') and not missing(WeightStatusAdult);
   if WaistStatusAdult not in ('4', 'P') and not missing(WaistStatusAdult);
   /* exclude BP results in 0, 1 */
   if BPDoneAdult in (0, 1);

	/* Create numeric binaries from characters - excludes BP */
	array have[*] $ HeightStatusAdult WeightStatusAdult WaistStatusAdult;
	array want[*] HTConsent WTConsent WAConsent;
	do i = 1 to dim(have);
      want[i] = (have[i] EQ '1');
	end;
	/* Create numeric binary for BP */
	BPconsent=BPDoneAdult;

run;


data MSR_STATUS_C(drop=i);
	/* Child */
	set COMBO_YC(keep=Qtr HeightStatusChild WeightStatusChild WaistStatusChild);

   label HTconsent='Height';
	label WTconsent='Weight';
	label WAconsent='Waist';

   /* exclude alert level 2 observations */
   if HeightStatusChild not in ('7', 'A') and not missing(HeightStatusChild);
   if WeightStatusChild not in ('4', 'A') and not missing(WeightStatusChild);
   if WaistStatusChild not in ('4', 'A') and not missing(WaistStatusChild);

   /* Create numeric binaries from characters */
   array have[*] $ HeightStatusChild WeightStatusChild WaistStatusChild;
	array want[*] HTconsent WTconsent WAconsent;
   do i = 1 to dim(have);
      want[i] = (have[i] EQ '1');
   end;
run;

%mend Make_MeasureConsent;


********** END MAKE MEASURE CONSENT DATASETS MACRO **********;


********** REPORT BP STATUS MACRO **********;

%macro Rpt_BPStatus;
/* get count BP measurements taken */
proc sql noprint;
   select count(*) into :n_bp
   from msr_bp;

quit;

 /* report BP status */
proc tabulate data=msr_bp;
   title 'Adult BP Status';
   footnote "BP measurements taken = &n_bp";
   class Qtr AgeGroup Status;
   table
      AgeGroup all,
      Qtr*(status*rowpctn='%'*f=7.1)
      /
      box='Age Group' misstext='0.0';
run;
title;
footnote;

%mend Rpt_BPStatus;


********** END REPORT BP STATUS MACRO **********;


********** REPORT FIRST DIGIT MACRO **********;
 
%macro Rpt_Decimal1;

/* format for measuretype */
proc format;
   value MeaureTypeFmt
      1 = 'Height %'
      2 = 'Weight %'
      3 = 'Waist %'
   ;
run;

/* adult */
/* count mising/not missing/all */
proc sql noprint;

   select count(*) into :miss_digit1_a42
   from MSR_DIGIT2_A
   where MeasureVal is missing and Qtr eq 42;

   select count(*) into :all_digit1_a42
   from MSR_DIGIT2_A
   where Qtr eq 42;

   select count(*) into :miss_digit1_a43
   from MSR_DIGIT2_A
   where MeasureVal is missing and Qtr eq 43;

   select count(*) into :all_digit1_a43
   from MSR_DIGIT2_A
   where Qtr eq 43;

quit;

proc tabulate data=MSR_DIGIT2_A;
   title "Adult Measurements First Decimal";
   footnote1 "Quarter 42: &miss_digit1_a42 /&all_digit1_a42 not measured";
   footnote2 "Quarter 43: &miss_digit1_a43 /&all_digit1_a43 not measured";
   class Qtr MeasureType MeasureVal;
   format MeasureType MeaureTypeFmt.;
   table
      MeasureVal=' '
      ,
      Qtr*(MeasureType='Adult Records'*f=4.1*colpctn=' ')
      /
      box='Decimal'
      misstext='0.0'
   ;
run;
title;
footnote;

/* Child */
/* count mising/not missing/all */
proc sql noprint;

   select count(*) into :miss_digit1_c42
   from MSR_DIGIT2_C
   where MeasureVal is missing and Qtr eq 42;

   select count(*) into :all_digit1_c42
   from MSR_DIGIT2_C
   where Qtr eq 42;

   select count(*) into :miss_digit1_c43
   from MSR_DIGIT2_C
   where MeasureVal is missing and Qtr eq 43;

   select count(*) into :all_digit1_c43
   from MSR_DIGIT2_C
   where Qtr eq 43;

quit;

proc tabulate data=MSR_DIGIT2_C;
   title "Child Measurements First Decimal";
   footnote1 "Quarter 42: &miss_digit1_c42 /&all_digit1_c42 not measured";
   footnote2 "Quarter 43: &miss_digit1_c43 /&all_digit1_c43 not measured";
   class Qtr MeasureType MeasureVal;
   format MeasureType MeaureTypeFmt.;
   table
      MeasureVal=' '
      ,
      Qtr*(MeasureType='Child Records'*f=4.1*colpctn=' ')
      /
      box='Decimal'
      misstext='0.0'
   ;
run;
footnote;

%mend Rpt_Decimal1;

********** END REPORT FIRST DIGIT MACRO **********;
 

********** REPORT THIRD MEASURES MACRO **********;
 
%macro Rpt_Measure3;

/* REPORT ADULT */
proc tabulate
      data=MSR_3_A
      format=percent10.;
   title 'Adult - 3rd measure required';
   var HT3 WT3 WA3;
   class qtr;
   table
      mean='Mean'*(HT3 WT3 WA3)
      ,
      qtr='Quarter'
   	;
	run;
title;

/* REPORT CHILD */
proc tabulate
      data=MSR_3_C
      format=percent10.;
   title 'Child - 3rd measure required';
   var HT3 WT3 WA3;
   class qtr;
   table
      mean='Mean'*(HT3 WT3 WA3)
   	,
      qtr='Quarter';
	run;
title;


%mend Rpt_Measure3;

********** END REPORT THIRD MEASURES MACRO **********;


********** REPORT MEASURE CONSENT MACRO **********;

%macro Rpt_MeasureConsent;

/* Adult */
proc tabulate
      data=MSR_STATUS_A
      format=percent10.;
   title 'Adult Measure Consent';
	var HTconsent WTconsent WAconsent BPconsent;
   class Qtr;
	table 
      HTconsent WTconsent WAconsent BPconsent
      , 
      qtr* mean='Consent Rate';
run;
title;


/* Child */
proc tabulate
      data=MSR_STATUS_C
      format=percent10.;
   title 'Child Measure Consent';
	var HTconsent WTconsent WAconsent;
   class Qtr;
	table 
      HTconsent WTconsent WAconsent
      , 
      qtr* mean='Consent Rate';
run;
title;

%mend Rpt_MeasureConsent;


********** END MEASURE CONSENT MACRO **********;







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

%Make_BPStatus;
%Sheetname(BPStatus);
%Rpt_BPStatus;

%Make_Decimal1;
%Sheetname(FirstDecimal);
%Rpt_Decimal1;

%Make_Measure3;
%Sheetname(ThirdMeasure);
%Rpt_Measure3;

%Make_MeasureConsent;
%Sheetname(MeasureConsent);
%Rpt_MeasureConsent;


/* close ODS sandwich */
ods excel close;



%end
/* END block out ods output */

