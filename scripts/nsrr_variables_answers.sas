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

data answers;
    set ansnsrr.answers;
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
	else nsrr_race = "?";

*ethnicity;
	format nsrr_ethnicity $100.;
	if ethnicity = "Hispanic" then nsrr_ethnicity = 'hispanic or latino';
	else if ethnicity = "Non-Hispanic" then nsrr_ethnicity = 'not hispanic or latino';
	else nsrr_ethnicity = 'not reported';


*current_smoke;
format nsrr_current_smoker $100.;
 if subs_tob_1 = "Daily Smoker" then nsrr_current_smoker = "yes";
 else if subs_tob_1 = "Occasianal Smoker" then nsrr_current_smoker = "yes";
 else if subs_tob_1 = "Former Smoker" then nsrr_current_smoker = "no";
 else if subs_tob_1 = "Never Smoker" then nsrr_current_smoker = "no";
 else nsrr_current_smoker = "not reported";

*ever_smoke;
format nsrr_ever_smoker $100.;
 if subs_tob_1 = "Daily Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Occasianal Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Former Smoker" then nsrr_ever_smoker = "yes";
 else if subs_tob_1 = "Never Smoker" then nsrr_ever_smoker = "no";
 else nsrr_ever_smoker = "not reported";

**add in ID so can merge;
  format id 8.2;

  keep 
    id
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
  * merge the datasets ;
    data answers_combo_dataset;
    merge
      ansnsrr.answers
      ansnsrr.answers_nsrr
      ;
    by id;

	*attrib visit format=8.2$.;
	visit = "1";

  run;

/* Checking categorical variables */
proc freq data=answers_combo_dataset;
table   visit;
run;



  *******************************************************************************;
* create permanent sas datasets ;
*******************************************************************************;

*******************************************************************************;
* export nsrr csv datasets ;
*******************************************************************************;
  %let version = 0.1.0;

  data _null_;
    call symput("sasfiledate",put(year("&sysdate"d),4.)||put(month("&sysdate"d),z2.)||put(day("&sysdate"d),z2.));
  run;


  proc export
    data=answers_combo_dataset
    outfile="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20221001-answers\nsrr-prep\_releases\&version.\answers_data_&version..csv"
    dbms=csv
    replace;
  run;
