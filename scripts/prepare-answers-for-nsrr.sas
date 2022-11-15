*******************************************************************************;
/* prepare-answers-for-nsrr.sas */
*******************************************************************************;

*******************************************************************************;
* establish options and libnames ;
*******************************************************************************;
  libname ansnsrr "\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20221001-answers\nsrr-prep";

*******************************************************************************;
* import and process master datasets from source ;
*******************************************************************************;
proc import file ="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20221001-answers\nsrr-prep\_source\answers_data_041022.csv"
out = ansnsrr.answers
dbms=csv
replace;
guessingrows=1000;
run;

  %let version = 0.2.0;

data answers;
    set ansnsrr.answers;

	format visit 1.;
	visit = 1;

  array Nums[*] _numeric_;
   array Chars[*] _character_;
   do i = 1 to dim(Nums);
      if Nums[i] = 'NA' then Nums[i] = .;
   end;
 
   do i = 1 to dim(Chars);
      if Chars[i] = 'NA' then Chars[i] = '';
   end;
   drop i;

 run;

  proc print data=answers (obs= 10);
  run;
*******************************************************************************;
* create harmonized datasets ;
*******************************************************************************;
data answers_nsrr;
set ansnsrr.answers;

*demographics
*age;
*use sleepage5c;
  format nsrr_age 8.2;
  if age gt 89 then nsrr_age=90;
  else if age le 89 then nsrr_age = age;

*age_gt89;
*use sleepage5c;
  format nsrr_age_gt89 $10.; 
  if age gt 89 then nsrr_age_gt89='yes';
  else if age le 89 then nsrr_age_gt89='no';

*sex;
*use gender1;
  format nsrr_sex $10.;
  if sex = "Male" then nsrr_sex = 'male';
  else if sex = "Female" then nsrr_sex = 'female';
  else if sex = . then nsrr_sex = 'not reported';

*race;
*use race1c;
    format nsrr_race $100.;
	if race = 'White' then nsrr_race = 'white';
    else if race = 'Asian' then nsrr_race = 'asian';
	else if race = 'Black' then nsrr_race = 'black or african american';
    else if race = 'Multiracial' then nsrr_race = 'multiple';
	else if race = 'Native' then nsrr_race = 'american indian or alaska native';
	else if race = 'Islander' then nsrr_race = 'native hawaiian or other pacific islander';

*ethnicity;
	format nsrr_ethnicity $100.;
	if ethnicity = "Hispanic" then nsrr_ethnicity = 'hispanic or latino';
	else if ethnicity = "Non-Hispanic" then nsrr_ethnicity = 'not hispanic or latino';
	else nsrr_ethnicity = 'not reported';


*current_smoke;
format nsrr_current_smoker $100.;
 if subs_tob_1 = "Daily Smoker" then nsrr_current_smoker = "yes";
 else if subs_tob_1 = "Occasional Smoker" then nsrr_current_smoker = "yes";
 else if subs_tob_1 = "Former Smoker" then nsrr_current_smoker = "no";
 else if subs_tob_1 = "Never Smoker" then nsrr_current_smoker = "no";
 else nsrr_current_smoker = "not reported";

*ever_smoke;
format nsrr_ever_smoker $100.;
 if subs_tob_1 = "Daily Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Occasional Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Former Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Never Smoker" then nsrr_ever_smoker = "no";
 else nsrr_ever_smoker = "not reported";

**add in ID so can merge;
  format id 8.2;

    format visit 1.;
	visit = 1;

  keep 
    id
	visit
    nsrr_age
    nsrr_age_gt89
    nsrr_sex
    nsrr_race
	nsrr_ethnicity
	nsrr_current_smoker
	nsrr_ever_smoker
	;
run;

*******************************************************************************;
* checking harmonized datasets ;
*******************************************************************************;
/* Checking for extreme values for continuous variables */
proc means data=answers_nsrr;
VAR   nsrr_age
      ;
run;

/* Checking categorical variables */
proc freq data=answers_nsrr;
table   nsrr_age_gt89
    	nsrr_sex
    	nsrr_race
		nsrr_ever_smoker
		nsrr_current_smoker
		nsrr_ethnicity;
run;


 data ansnsrr.answers_nsrr;
    set answers_nsrr;
  run;
*****;
/*  * merge the datasets ;
    data answers_combo_dataset;
    merge
      ansnsrr.answers
      ansnsrr.answers_nsrr
      ;
    by id;

	*attrib visit format=8.2$.;
	visit = "1";

  run; /*

/* Checking categorical variables */
proc freq data=answers_nsrr;
table   visit;
run;



  *******************************************************************************;
* make variables lowercase ;
*******************************************************************************;

 options mprint;
  %macro lowcase(dsn);
       %let dsid=%sysfunc(open(&dsn));
       %let num=%sysfunc(attrn(&dsid,nvars));
       %put &num;
       data &dsn;
             set &dsn(rename=(
          %do i = 1 %to &num;
          %let var&i=%sysfunc(varname(&dsid,&i));    /*function of varname returns the name of a SAS data set variable*/
          &&var&i=%sysfunc(lowcase(&&var&i))         /*rename all variables*/
          %end;));
          %let close=%sysfunc(close(&dsid));
    run;
  %mend lowcase;

  %lowcase(answers);
  %lowcase(answers_nsrr);





*******************************************************************************;
* export nsrr csv datasets ;
*******************************************************************************;


  data _null_;
    call symput("sasfiledate",put(year("&sysdate"d),4.)||put(month("&sysdate"d),z2.)||put(day("&sysdate"d),z2.));
  run;


  proc export
    data=answers_nsrr
    outfile="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20221001-answers\nsrr-prep\_releases\&version.\answers-harmonized-dataset-&version..csv"
    dbms=csv
    replace;
  run;
   proc export
    data=answers
    outfile="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20221001-answers\nsrr-prep\_releases\&version.\answers-dataset-&version..csv"
    dbms=csv
    replace;
  run;
