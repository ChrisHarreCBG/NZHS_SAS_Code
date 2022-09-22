



/* 

   HOUSEHOLD OUTCOMES YEAR 11

   Creates Household outcomes dataset for NZHS
   input datasets:
   * NZHSL2.NZHSCOMBO
   * NZHSFIN.NZHSFINALCHILDY11
   * NZHSFIN.NZHSFINALADULTY11
   * AGILEL1.CONTACTS
   output dataset:
   * WORK.YEAR11_HH_OUTCOME


   For future years, replace:
   * NZHSFINALCHILDY11 in steps 3 and 5
   * NZHSFINALADULTY11 in steps 4 and 6
   * qtr in (42, 43) in step 1
   * NZHSOUTCOME_Y11 in steps 15, 16, 17
   * YEAR11_HH_OUTCOME in step 17

*/


/* STEP 1
   NZHSComboFlag 
   make NZHSCOMBOFLAG from NZHSCOMBO with current quarters
   conditioned on Household or HouseholdNDE or DeclineAdvance
*/
data NZHSComboFlag(compress=char rename=(SamplingUnit=PSU2015));  * rename SamplingUnit as PSU2015;
	set NZHSL2.NZHSCOMBO(
      drop=PSU2015 
      where=((Household or HouseholdNDE or DeclineAdvance) and qtr in (42, 43))
      )
   ;
run;


/* STEP 2
   sort NZHSCOMBOFLAG by qtr psu2015 nzhshhid */
proc sort data=NZHSComboFlag;
   by Qtr PSU2015 NZHSHHID;
run;


/* STEP 3
   sort FINALCHILD by qtr PSU2015 nzhshhid */
proc sort 
      data=NZHSFIN.NZHSFINALCHILDY11
      out=WORK.NZHSFINALCHILDY11(rename=(PSU=PSU2015));
   by Qtr PSU NZHSHHID;
run;
data NZHSFINALCHILDY11; * match COMBO attributes for Qtr and PSU2015;
   attrib
      Qtr      length=3    format=F3.  label='NZHS Quarter'
      PSU2015  length=5    format=7.   label='SamplingUnit defined in SamplingType'
   ;
   set NZHSFINALCHILDY11(rename=(Qtr=Temp_Qtr PSU2015=Temp_PSU2015));
   Qtr=Temp_Qtr;
   PSU2015=Temp_PSU2015;

   drop Temp_:;
run;


/* STEP 4
   sort FINALADULT by qtr PSU2015 nzhshhid */
proc sort 
      data=NZHSFIN.NZHSFINALADULTY11
      out=WORK.NZHSFINALADULTY11(rename=(PSU=PSU2015));
   by Qtr PSU NZHSHHID;
run;
data NZHSFINALADULTY11; * match COMBO attributes for Qtr and PSU2015;
   attrib
      Qtr      length=3    format=F3.  label='NZHS Quarter'
      PSU2015  length=5    format=7.   label='SamplingUnit defined in SamplingType'
   ;
   set NZHSFINALADULTY11(rename=(Qtr=Temp_Qtr PSU2015=Temp_PSU2015));
   Qtr=Temp_Qtr;
   PSU2015=Temp_PSU2015;

   drop Temp_:;
run;


/* STEP 5
   merge NZHSCOMBOFLAG and FINALCHILD
   by Qtr PSU2015 NZHSHHID
   if in NZHSComboFlag
   set datchild=0 if req
*/
data NZHSComboFlag;
   merge 
      NZHSComboFlag(in=in1) 
      NZHSFINALCHILDY11(in=in2 keep=Qtr PSU2015 NZHSHHID MaoriHousehold Match_Address);
   by Qtr PSU2015 NZHSHHID;
   if in1 and not in2 then DatChild=0; 
   if in1;
run;


/* STEP 6
   merge NZHSCOMBOFLAG and FINALADULT
   by Qtr PSU2015 NZHSHHID
   if in NZHSComboFlag
   set datadult=0 if req
*/
data NZHSComboFlag;
   merge 
      NZHSComboFlag(in=in1)
      NZHSFINALADULTY11(in=in2 keep=Qtr PSU2015 NZHSHHID MaoriHousehold Match_Address);
   by Qtr PSU2015 NZHSHHID;
   if in1 and not in2 then  DatAdult=0; 
   if in1;
run;


/* STEP 7
   sort NZHSComboFlag by qtr psu2015 meshblock2006 nzhshhid */
proc sort data = NZHSComboFlag; 
   by Qtr PSU2015 meshblock2006 NZHSHHID; 
run;



/* STEP 8
   Create Outcome variable in NZHSComboFlag */
data NZHSComboFlag(compress=char);
	set NZHSComboFlag;
	keep 
      PSU2015 Meshblock2006 NZHSHHID SampleType Household HouseholdNDE 
      DatAdult DatChild NotContacted NotVisited Contacted 
      HouseholdNDE NotOccupied Decline DeclineAdult
      DeclineChild DeclineHousehold DeclineAdvance Outcome 
      RoomsEligible RoomsOccupied RoomsTotal adults children qtr year Surveyor UrbanArea2015Class
      MaoriHousehold Match_Address
   ;
   attrib
      Outcome     length=$20     format=$20.        label='Household Outcome'
   ;

   select;
      when(DatAdult or DatChild)          Outcome='Survey';
      when(NotContacted or NotVisited)    Outcome='Not Contacted';
      when(Contacted)                     Outcome='Contacted';
      when(HouseholdNDE)                  Outcome='NDE';
      when(NotOccupied)                   Outcome='Not Occupied';
      when(Decline)                       Outcome='Decline';  /* *** never set *** */
      when(DeclineAdvance)                Outcome='Advance Decline';	
   end;

	Surveyor=datsurveyoradult;
	if datsurveyoradult = '' and datsurveyorchild ne '' then Surveyor=datsurveyorchild;
	rename SampleType=SampleGroup;

run;



/* STEP 9
   get surveyor ID from AGILEL1.CONTACTS
   NEED LIBREF FOR AgileL1 + get encryption password */
%libname(AGILEL1);
%getusername(CBGSAS04,AgileCRMDARE,passwordvar=AgileCRMDARE);
%put &=AgileCRMDARE;

data ID;
   set AgileL1.Contacts(encryptkey="&AgileCRMDARE" keep=SurveyorNumber Username);
   rename SurveyorNumber=SurveyorID Username=Surveyor;
run;

libname AGILEL1 clear;

/* STEP 10
   sort ID by Surveyor for merge with NZHSComboFlag */
proc sort data=ID;
   by Surveyor;
run;

/* STEP 11
   sort NZHSComboFlag by Surveyor for merge with ID */
proc sort data=NZHSComboFlag;
   by Surveyor;
run;

/* STEP 12
   add SurveyorID to NZHSComboFlag - merge ID and NZHSComboFlag by Surveyor */
data NZHSComboFlag;
   merge 
      NZHSComboFlag(in=in1) 
      ID;
   by Surveyor;
   if in1;
run; 

/* STEP 13
   re-sort NZHSComboFlag by qtr psu2015 nzhshhid*/
proc sort data = NZHSComboFlag; 
   by Qtr PSU2015 NZHSHHID; 
run;


/* STEP 14
   sort NZHSL1.NZHSHOUSEHOLDS into WORK.NZHSHOUSEHOLDS by Qtr PSU2015 NZHSHHID for merge with NZHSCOMBOFLAG */

%getusername(CBGSAS04,NZHSDARE,passwordvar=pwNZHS);

proc sort 
      data=NZHSL1.Nzhshouseholds(encryptkey="&pwNZHS")
      out=WORK.NZHSHOUSEHOLDS(rename=(SamplingUnit=PSU2015)); 
   by  Qtr SamplingUnit NZHSHHID;
run;


/* STEP 15
   merge NZHSCOMBOFLAG MAORI WORK.NZHSHOUSEHOLDS into NZHSOutcomeYear9 */
data NZHSOUTCOME_Y11;
   merge 
      NZHSComboFlag(in=in1) 
      Nzhshouseholds(keep=Qtr PSU2015 NZHSHHID DwellingStatus);
   by Qtr PSU2015  NZHSHHID;
   if in1;
run;



/* STEP 16
   reorder variables in NZHSOutcomeYear9/drop surveyor */
data NZHSOUTCOME_Y11;
   retain
      Qtr
      PSU2015
      NZHSHHID
      UrbanArea2015Class
      SampleGroup
      Year
      DwellingStatus
      MaoriHousehold
      Match_address
      DatAdult
      DatChild
      SurveyorID
      Adults
      Children
      HouseholdNDE
      NotOccupied
      NotVisited
      Contacted
      NotContacted
      Decline
      DeclineAdvance
      DeclineHousehold
      DeclineAdult
      DeclineChild
      Household
      Match_Address
      MaoriHousehold
      Outcome
   ;

   set NZHSOUTCOME_Y11;
   drop Surveyor;

run;


/* STEP 17
   make YEARxx_HH_OUTCOME dataset/add new outcome DVs */
data YEAR11_HH_OUTCOME;
   set NZHSOUTCOME_Y11;

   attrib 
      Key      length=$22     format = $2.      label='Qtr_PSU2015_NZHSHHID'
   ;

   Key=compress(qtr||'_'||PSU2015||'_'||NZHSHHID);

   if RoomsEligible = .  then DwellingStatus='Private';
   if RoomsEligible ne . then DwellingStatus='Non-Private';
   if datadult in (0,.) and datchild   in (0,.) then  SurveyorID = '' ;
   if Outcome='Not Contacted' then do adults=.; Children=.;end;
   if SampleGroup='E' then SampleGroup='A';
   drop RoomsEligible RoomsOccupied RoomsTotal meshblock2006;

run;


/* EXTRA STEPS CAN ADAPTED TO SAVE COPY OF OUTCOME DATASET AND COPY TO MOH FTP
   SET LIBREF FILE PATHS AND DATASET NAMES AND LABELS AS REQUIRED
   THIS SECTION IS BLOCKED USING %IF 0 %THEN &DO /%END MACRO STATEMENTS */

/* COPY TO LIBRARY YEAR10DL */
%if 0 %then %do;

   /* libref copy destination */
   libname YEAR10DL "C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY10DataLinkage\Library\YEAR10";

   /* copy to destination */
   proc copy
         in=work
         out=YEAR10DL 
         memtype=data
      ;
      select
         YEAR11_HH_OUTCOME
      ;
   run;

   /* rename and label in destination */
   proc datasets lib=YEAR10DL;
      change
         YEAR11_HH_OUTCOME=YEAR11_HH_OUTCOME_20220922
      ;
      modify 
         YEAR11_HH_OUTCOME_20220922(label='NZHS Year 11 Household Outcomes 22/9/2022')
      ;
   quit;

%end;

/* COPY TO MOH FTP */
%if 0 %then %do;

  libname MOHFTP '\\CBGWEB04\ftproot\ftp.healthstat.co.nz\ad\ftp.moh\Year+11\Full Datasets\Y11';

   proc copy
         in=YEAR10DL
         out=MOHFTP
         memtype=data
      ;
      select
         YEAR11_HH_OUTCOME_20220922
      ;
   run;

   libname MOHFTP clear;

   libname YEAR10DL clear;

%end;


