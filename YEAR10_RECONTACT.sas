


/* build YEAR10_RECONTACTINFORMATION 

   source datasets:
   * NZHSL2.NZHSCOMBO
      key = Qtr + SamplingUnit + NZHSHHID
      * Qtr - format=3.

   * NZHSFIN.NZHSFINALADULTY10 (+ child)
      key = Qtr + PSU + NZHSHHID
      * PSU - rename=SamplingUnit
      * PSU - length=5
      * PSU - format=7.

   *  NZHSL2.NZHSASKIASURVEYSADULTY10 (+ child)
      key = Qtr + SamplingUnit + NZHSHHID

   output dataset:
   * YEAR10_RECONTACTINFORMATION
   
   For future years replace:
   * macro variables YrSubset, QtrSubset in setup step 1
   * dataset NZHSL2.NZHSCOMBO in stepup step 2
   * dataset NZHSFIN.NZHSFINALADULTY10 in sepup step 3
   * dataset NZHSFIN.NZHSFINALCHILDY10 in setup step 4
   * dataset NZHSL2.NZHSASKIASURVEYSADULTY10 in setup step 5
   * dataset NZHSL2.NZHSASKIASURVEYSCHILDY10 in setup step 6

   * dataset YEAR10_RECONTACTINFORMATION as final output dataset


*/

/* SETUP STEP 1
   set up macros */

/* merge/sort key */
%let DLKey=Qtr SamplingUnit NZHSHHID;

%let DLKey2=Qtr SamplingUnit meshblock2006 NZHSHHID;


/* year/quarter partitions */
%let YrSubset=Year eq 10;
%let QtrSubset=Qtr in (38, 39, 40);

/* encrypt pw */
%getusername(CBGSAS04,NZHSDARE);



/* SETUP STEP 2
   get copy combo */
data COMBO;
   format Qtr 3.;
   set NZHSL2.NZHSCOMBO(where=(&qtrSubset));
run;

/* SETUP STEP 3 
   get copy finaladulty10 */
data FINALADULT_Y10(drop=old_PSU);
   retain Qtr SamplingUnit;
   attrib
      SamplingUnit length=5 format=7.;
   set NZHSFIN.NZHSFINALADULTY10(rename=(PSU=old_PSU));

   SamplingUnit=old_PSU;

run;

/* SETUP STEP 4
   get copy finalchildy10 */
data FINALCHILD_Y10(drop=old_PSU);
   retain Qtr SamplingUnit;
   attrib
      SamplingUnit length=5 format=7.;
   set NZHSFIN.NZHSFINALCHILDY10(rename=(PSU=old_PSU));

   SamplingUnit=old_PSU;

run;

/* SETUP STEP 5
   get copy level2.askiasurveysadult ASKIAADULT */
data ASKIAADULT;
      set NZHSL2.NZHSASKIASURVEYSADULTY10(encryptkey="&password" where=(&QtrSubset));
run;

/* SETUP STEP 6 
   get copy level2.askiasurveyschild ASKIACHILD */
data ASKIACHILD;
      set NZHSL2.NZHSASKIASURVEYSCHILDY10(encryptkey="&password" where=(&QtrSubset));
run;



****************************************;



/* STEP 01 */
/* Make RECONTACT from COMBO */
data RECONTACT_01;
   set COMBO;

   /* new variables */
   AdultStreetAddress=StreetAddress;
   AdultSuburb=Suburb;
   AdultTown=Town;
   ChildStreetAddress=StreetAddress;
   ChildSuburb=Suburb;
   ChildTown=Town;
   GuardianStreetAddress=StreetAddress;
   GuardianSuburb=Suburb;
   GuardianTown=Town;
   AdultPostcode=Postcode;
   ChildPostcode=Postcode;
   GuardianPostcode=Postcode;

   keep
      meshblock2006 
      NZHSHHID 
      AdultStreetAddress 
      AdultSuburb 
      AdultTown 
      ChildStreetAddress 
      ChildSuburb 
      ChildTown 
      AdultFirstName 
      AdultMiddleName 
      AdultSurname 
      ChildFirstName 
      ChildMiddleName 
      ChildSurname 
      AdultCellphone 
      AdultPhone 
      AdultEMail 
      GuardianCellphone 
      GuardianPhone 
      GuardianName 
      GuardianEMail 
      GuardianStreetAddress 
      GuardianSuburb 
      GuardianTown 
      datadult 
      datchild 
      qtr 
      SamplingUnit 
      GuardianPostcode 
      ChildPostcode 
      AdultPostcode 
      UrbanArea2015Class
   ;

run;


/* STEP 02 */
/* sort RECONTACT, FINALADULT, FINALCHILD for merge by &DLKey */
proc sort
      data=RECONTACT_01
      out=RECONTACT_02;
   by &DLKey;
run;

proc sort
      data=FINALADULT_Y10;
   by &DLKey;
run;

proc sort
      data=FINALCHILD_Y10;
   by &DLKey;
run;


/* STEP 03 */
/* merge RECONTACT and FINALCHILD */
data RECONTACT_03;
   merge
      RECONTACT_02(in=a)
      FINALCHILD_Y10(in=b keep=&DLKey)
      ;
   by &DLKey;
   if a and not b then datchild=0;
   if a;
run;


/* STEP 04 */
/* merge RECONTACT and FINALCHILD */
data RECONTACT_04;
   merge
      RECONTACT_03(in=a)
      FINALADULT_Y10(in=b keep=&DLKey)
      ;
   by &DLKey;
   if a and not b then datadult=0;
   if a;
run;


/* STEP 05 */
/* subset RECONTACT for ad_ = 1 */
data RECONTACT_05;
   set RECONTACT_04(where=(datadult = 1 or datchild = 1));
run;


/* STEP 06 */
/* sort RECONTACT by DLKey2 */
proc sort
      data=RECONTACT_05
      out=RECONTACT_06;
   by &DLKey2;
run;


/* STEP 06.5 */
/* sort exit questions by DLKey */
proc sort 
      data=ASKIAADULT;
   by &DLKey;
run;

proc sort 
      data=ASKIACHILD;
   by &DLKey;
run;


/* STEP 07 */
/* merge RECONTACT and ASKIAADULT */
data RESEARCHADULT_01;
   merge
      RECONTACT_06(in=a)
      ASKIAADULT(in=b keep=&DLKey A6_04 A6_07);

   by &DLKey;
   if a;
   
   rename
      A6_04 = Q_6_04_Adult
      A6_07 = Q_6_07_Adult
      ; 
      
run;


/* STEP 07 */
/* merge RECONTACT and ASKIACHILD */
data RESEARCHCHILD_01;
   merge
      RECONTACT_06(in=a)
      ASKIACHILD(in=b keep=&DLKey C6_04 C6_07 C6_08 C6_08City C6_08Street C6_08Suburb);
   by &DLKey;
   if a;

   if C6_08City ne '' then do;
      ChildTown = C6_08City;
      ChildSuburb = C6_08Suburb;
      ChildStreetAddress = C6_08Street;
   end;

   rename
      C6_04 = Q_6_04_Child 
      C6_07 = Q_6_07_Guardian 
      C6_08 = Q_6_08_Child
      ;

   rename /* askia vars not renamed above */
      C6_08City   = Q_6_08_City
      C6_08Street = Q_6_08_Street
      C6_08Suburb = Q_6_08_Suburb
      ;

run;


/* STEP 08 */
/* merge RESEARCHADULT and RESEARCHCHILD */
data FOLLOWUP_RESEARCH_01;
   merge
      RESEARCHADULT_01
      RESEARCHCHILD_01
      ;
   by &DLKey;
run;


/* STEP 09 */
/* refine FOLLOWUP_RESEARCH on datadult/datchild + fix names */
data FOLLOWUP_RESEARCH_02;
   set FOLLOWUP_RESEARCH_01;

   if datadult and Q_6_04_adult = "" then Q_6_04_adult = "2";
   if datchild = 1 and Q_6_04_Child = "" then Q_6_04_Child = "2";
   if datadult = 0 then Q_6_04_adult="";
   if datchild = 0 then Q_6_04_Child="";

   /* FIX NAMES */
   /* AdultFirstName */
   AdultFirstName = STRIP(AdultFirstName);
   AdultFirstName = COMPRESS(AdultFirstName,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   AdultFirstName = TRANSLATE(AdultFirstName,' ','\/_,');

   /* AdultMiddleName */
   AdultMiddleName = STRIP(AdultMiddleName);
   AdultMiddleName = COMPRESS(AdultMiddleName,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   AdultMiddleName = TRANSLATE(AdultMiddleName,' ','\/_,');

   /* AdultSurname */
   AdultSurname = STRIP(AdultSurname);
   AdultSurname = COMPRESS(AdultSurname,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   AdultSurname = TRANSLATE(AdultSurname,' ','\/_,');

   /* ChildFirstName */
   ChildFirstName = STRIP(ChildFirstName);
   ChildFirstName = COMPRESS(ChildFirstName,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   ChildFirstName = TRANSLATE(ChildFirstName,' ','\/_,');

   /* ChildMiddleName */
   ChildMiddleName = STRIP(ChildMiddleName);
   ChildMiddleName = COMPRESS(ChildMiddleName,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   ChildMiddleName = TRANSLATE(ChildMiddleName,' ','\/_,');

   /* ChildSurname */
   ChildSurname = STRIP(ChildSurname);
   ChildSurname = COMPRESS(ChildSurname,'1234567890()[]=`.~!@#$%^&*+{}?<>;:');
   ChildSurname = TRANSLATE(ChildSurname,' ','\/_,');

run;


/* STEP 10 */
data FOLLOWUP_RESEARCH_03;
   set FOLLOWUP_RESEARCH_02;

   if Q_6_04_Adult ne "1" then do; /* ADULT FOLLOW UP RESEARCH NOT YES */
      AdultFirstName=''; 
      AdultSurname=''; 
      AdultCellphone=''; 
      Q_6_07_Adult=''; 
      AdultPhone=''; 
      AdultEMail='';
      AdultStreetAddress=''; 
      AdultSuburb=''; 
      AdultTown =''; 
      AdultPostcode=.;
   end;

   if Q_6_04_Child ne "1" then do; /* CHILD FOLLOW UP RESEARCH NOT YES */
      ChildFirstName=''; 
      ChildSurname=''; 
      GuardianCellphone=''; 
      Q_6_07_Guardian=''; 
      GuardianPhone=''; 
      GuardianName=''; 
      GuardianEMail=''; 
      Q_6_08_Child=''; 
      ChildStreetAddress=''; 
      ChildSuburb=''; 
      ChildTown=''; 
      ChildPostcode=.; 
      GuardianStreetAddress=''; 
      GuardianSuburb=''; 
      GuardianTown=''; 
      GuardianPostcode=.;
   end;

   if Q_6_07_adult in ('3','') then do; /* ADULT FOLLOW-UP RESEARCH NAME/ADDRESS = 3 or missing */
      AdultStreetAddress=''; 
      AdultSuburb=''; 
      AdultTown =''; 
      AdultFirstName=''; 
      AdultSurname=''; 
      AdultPostcode=.; 
   end;

   %if 0 %then %do; /* SKIP: else resets address if consent = Yes! */
   if Q_6_07_adult in ('1') then do; /* ADULT FOLLOW-UP RESEARCH RECORD NAME/ADDRESS = YES */
      AdultStreetAddress=''; 
      AdultSuburb=''; 
      AdultTown ='';
      AdultPostcode=.;
   end;
   %end;


   if Q_6_07_Guardian in ('3') then do; /* CHILD FOLLOW-UP RESEARCH RECORD PARENT NAME/ADDRESS = 3 */
      GuardianStreetAddress=''; 
      GuardianSuburb=''; 
      GuardianTown=''; 
      GuardianPostcode=.;
      GuardianName='';
   end;

   %if 0 %then %do; /* SKIP: else resets parent address if consent = Yes! */
   if Q_6_07_Guardian in ('1') then do; /* CHILD FOLLOW-UP RESEARCH RECORD PARENT NAME/ADDRESS = YES */
      GuardianStreetAddress=''; 
      GuardianSuburb=''; 
      GuardianTown=''; 
      GuardianPostcode=.;
   end;
   %end;

   %if 0 %then %do; /* SKIP: else resets child address if consent = Yes! */
   if Q_6_08_child in ('1') then do; /* CHILD FOLLOW-UP RESEARCH RECORD CHILD NAME/ADDRESS = YES */
      ChildStreetAddress=''; 
      ChildSuburb=''; 
      ChildTown=''; 
      ChildPostcode=.;
   end;
   %end;

   if Q_6_08_child in ('3','') then do; /* CHILD FOLLOW-UP RESEARCH RECORD CHILD NAME/ADDRESS = 3 or missing */
      ChildStreetAddress=''; 
      ChildSuburb=''; 
      ChildTown=''; 
      ChildFirstName=''; 
      ChildSurname=''; 
      ChildPostcode=.; 
   end;

   if datchild=0 then do;
      GuardianStreetAddress='';
      GuardianSuburb='';
      GuardianTown='';
      GuardianPostcode=.;
   end;

run;


/* STEP 11 */
/* rearrange variable order */
data FOLLOWUP_RESEARCH_04;

   retain 
      Qtr
      SamplingUnit
/*      PSU2015*/
      Meshblock2006
      NZHSHHID
      UrbanArea2015Class
      DatAdult
      Q_6_04_adult
      AdultPhone
      AdultCellphone
      AdultEMail
      Q_6_07_adult
      AdultFirstName
      AdultMiddleName
      AdultSurname
      AdultStreetAddress
      AdultSuburb
      AdultTown
      AdultPostcode

      DatChild
      Q_6_04_Child
      GuardianPhone
      GuardianCellphone
      GuardianEMail
      Q_6_07_Guardian
      GuardianName
      GuardianStreetAddress
      GuardianSuburb
      GuardianTown
      GuardianPostcode

      Q_6_08_Child
      ChildFirstName
      ChildMiddleName
      ChildSurname
      ChildStreetAddress
      ChildSuburb
      ChildTown
      ChildPostcode
      ;

   set FOLLOWUP_RESEARCH_03;

run;


/* STEP 12 */
proc sort
      data=FOLLOWUP_RESEARCH_04
      out=FOLLOWUP_RESEARCH_05
      ;
   by &DLKey;
run;


/* STEP 13 */
data FOLLOWUP_RESEARCH_06(drop=Q_6_08_City Q_6_08_Street Q_6_08_Suburb);
   set FOLLOWUP_RESEARCH_05;

   attrib key length=$25 format=$25.;

   key=CATX("_",qtr,SamplingUnit,NZHSHHID);
   
run;

%if 0 %then %do;
proc print data=FOLLOWUP_RESEARCH_06(obs=10);
   var &DLKey key;
run;
%end;


/* COPY TO LIBRARY */
%if 0 %then %do;

   libname YEAR10DL "C:\Users\cbg.chrish\OneDrive - CBG Health Research Ltd\Documents\VM150 SAS\Scripts\NZHS_MISC\NZHSY10DataLinkage\Library\YEAR10";

   data work.YEAR10_RECONTACTINFORMATION;
      set work.FOLLOWUP_RESEARCH_06(rename=(SamplingUnit=PSU2015));
   run;

   proc copy
         in=WORK
         out=YEAR10DL
         memtype=data
         ;
      select
         YEAR10_RECONTACTINFORMATION
         ;
   run;

%end;


/* CHECKS */


%if 0 %then %do;

   data test1;
      set work.FOLLOWUP_RESEARCH_06;
         where 
            (Q_6_07_adult in ('1','2') and AdultFirstName='' and AdultSurname='') 
               or 
            (Q_6_07_Guardian in ('1','2') and GuardianName='') 
               or 
            (Q_6_07_Guardian in ('2') and  GuardianSuburb='') 
               or 
            (Q_6_08_Child in ('2') and ((ChildFirstName='' and ChildSurname='') or ChildStreetAddress=''));
   run;

   proc sort
         data=COMBO
         out=test2;
      by &DLKey;
   run;

   data test3;
      merge 
         test2(in=a keep=&DLKey datsurveyoradult datsurveyorchild) 
         FOLLOWUP_RESEARCH_06(in=b keep=&DLKey Q_6_04_adult Q_6_04_child);
         by &DLKey;
      if a and b;
   run;

%end;

