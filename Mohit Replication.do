clear all 
set more off
cd "//Users/mohit/Downloads/Replication1"
*we first need to open all the databases
foreach database in 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 00 01 02 {
fdause//Users/mohit/Downloads/Replication1/CDBRFS`database'.XPT

capture rename income income2
capture rename orace _raceg2
gen income = 5000 if income2==1
replace income = 12500 if income2==2
replace income = 17500 if income2==3
replace income = 22500 if income2==4
replace income = 30000 if income2==5
replace income = 42500 if income2==6
replace income = 62500 if income2==7
replace income = 85000 if income2==8
replace _finalwt = round(_finalwt)	
* converting feet to inches
capture gen inches= htf*12 
*converting height in inches and then meters
capture gen height2 = inches + hti
capture gen htm = 0.0254*height2
*weight in kilograms
gen kg= 0.453592*weight
*number of cigarettes smoked 
capture gen smokenum = .
capture gen hispanic = hispanc2
keep _state idate imonth iday iyear income _raceg2 marital educa sex age kg htm _finalwt smokenum hispanic

recast str8 iyear
recast str8 idate
capture erase "//Users/mohit/Downloads/Replication1/CDBRFS`database'.dta"
save "//Users/mohit/Downloads/Replication1/CDBRFS`database'.dta"
clear all
}

*compiling all databases in one 
clear all
use "//Users/mohit/Downloads/Replication1/CDBRFS84.dta"
foreach database in 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 00 01 02 {
append using  "//Users/mohit/Downloads/Replication1/CDBRFS`database'.dta"
}


replace iyear = "02" if iyear=="2002"
replace iyear = "01" if iyear=="2001"
replace iyear = "00" if iyear=="2000"
replace iyear = "99" if iyear=="1999"

drop if iyear>="2003"
drop if iyear<="83"


ssc install estout, replace
ssc install outreg2

set more off

clear all 
global directory_in "/Users/mohit/Downloads/Replication1"
global directory_out "/Users/mohit/Downloads/Replication 4"

cd "${directory_in}"

			*here we create databases for tax, CPI, unemployment
			*taxes
			clear all
			 import excel "${directory_in}\real and nominal tax rate.xlsx", firstrow
		

			sort fips month year

			drop if month==.
			drop if year=="."
			drop if fips==.

			quietly by fips month year:  gen dup = cond(_N==1,0,_n)
			drop if dup==2
			drop if dup>=1
			drop dup

			save "${directory_in}\tax_database.dta", replace 
			
			*unemployment
			clear all 
			import excel "${directory_in}\Unemprate.xlsx", firstrow

			drop Year
			rename year2 year 
			rename *, lower
			rename rate unem_rate
			rename state fips
			sort fips month 
			 
			 save "${directory_in}\unemployment_database.dta", replace
			 
			*CPI
			clear all
			 import excel "${directory_in}\CPI.xlsx", firstrow
		
			rename year2 year
			drop if month==.
			save "${directory_in}\CPI.dta", replace 
			 
			 

	
* we import our CDBRFS and then merge all databases into one
clear all
use "${directory_in}\CDBRFS_final_database"

 
 rename _state fips
 rename iyear year
 rename imonth month

 drop if fips==72

 destring month, replace
 tostring month, g(m)
 tostring fips, g(f)
 
 
merge m:1 fips year month using "${directory_in}\unemployment_database.dta"
drop if _merge==1
drop if _merge==2
drop _merge

merge m:1 fips year month using "${directory_in}\tax_database.dta"

drop if _merge==1
drop if _merge==2
drop _merge


merge m:1 year month using "${directory_in}\CPI.dta"

drop if _merge==1
drop if _merge==2
drop _merge

 
 
 
*BMI
gen height2 = htm^2
gen bmi =  kg / height2
drop if bmi==.
*drop if bmi>=250
*drop if bmi<=5

*obese
gen obese= 0
replace obese= 1 if bmi>=30

*smoking
replace smokenum=0 if smokenum==.
gen smoke = 0
replace smoke = 1 if smokenum>=1
gen cigs = smokenum
gen cig_miss= cigs
replace cig_miss= . if cig_miss==0
replace smoke = 0 if smokenum== .

*Real tax
replace CPI2002 = CPI2002/100

gen real_tax_2002 = (State_tax)/ CPI2002

*real price
gen real_pack_price= Averagepriceperpack/(CPI2002*100)

*race 
gen white= 0
replace white= 1 if _raceg2==1

gen black= 0
replace black= 1 if _raceg2==2

gen asian= 0
replace asian= 1 if _raceg2==3

gen hispan= 0
replace hispan= 1 if hispanic==1	

*marital status
gen married= 0
replace  married=1 if marital==1

gen divorced= 0
replace  divorced=1 if marital==2

gen widowed= 0
replace  widowed=1 if marital==3

*education
gen eight= 0
replace eight= 1 if educa ==1
replace eight= 1 if educa ==2

gen nine_eleven= 0
replace nine_eleven= 1 if educa==3 

gen hs_grad= 0
replace hs_grad= 1 if educa == 4

gen some_coll= 0
replace some_coll= 1 if educa ==5

gen coll= 0
replace coll= 1 if educa ==6
replace coll= 1 if educa ==7
replace coll= 1 if educa ==8


*Real income
gen r_income= income/CPI2002

*sex
gen male = 0
replace male = 1 if sex==1

*age groups
gen age_g= 1 if age<25
replace age_g= 2 if age>=25 & age<30
replace age_g= 3 if age>=30 & age<35
replace age_g= 4 if age>=35 & age<40
replace age_g= 5 if age>=40 & age<45
replace age_g= 6 if age>=45 & age<50
replace age_g= 7 if age>=50 & age<55
replace age_g= 8 if age>=55 & age<60
replace age_g= 9 if age>=60 & age<65

*group and sex
forvalues i=1/9 {
gen male_g`i'= 0
replace male_g`i'= 1 if age_g==`i' & male==1

gen female_g`i'= 0
replace female_g`i'= 1 if age_g==`i' & male==0
}


*table 1
preserve 
collapse (mean) bmi obese smoke cigs cig_miss real_tax_2002 real_pack_price r_income unem_rate white black hispan married divorced widowed eight nine_eleven hs_grad some_coll coll age male [aw=_finalwt]
export excel using "${directory_out}/table1.xls", sheet(row_table1_mean) firstrow(varlabels) sheetmodify	
restore

preserve 
collapse (sd) bmi obese smoke cigs cig_miss real_tax_2002 real_pack_price r_income unem_rate white black hispan married divorced widowed eight nine_eleven hs_grad some_coll coll age male [aw=_finalwt]
export excel using "${directory_out}/table1.xls", sheet(row_table1_sd) firstrow(varlabels) sheetmodify	
restore

gen fips_string= f
gen month_string= m
gen year_string= year

drop f m 

egen month_year= concat(month_string-year_string)
destring month_year, replace
 
*table 2
set more off
reg bmi real_tax_2002 r_income black white hispan married divorced widowed unem_rate nine_eleven hs_grad some_coll coll male_g1 female_g1 male_g2 female_g2 male_g3 female_g3 male_g4 female_g4 male_g5 female_g5 male_g6 female_g6 male_g7 female_g7 male_g8 female_g8 male_g9 i.fips i.month_year [aw=_finalwt] if age<=65, nocons
outreg2 using "${directory_out}/table2.xls", replace ctitle(BMI)
*help outreg2
reg obese real_tax_2002 r_income black white hispan married divorced widowed unem_rate nine_eleven hs_grad some_coll coll male_g1 female_g1 male_g2 female_g2 male_g3 female_g3 male_g4 female_g4 male_g5 female_g5 male_g6 female_g6 male_g7 female_g7 male_g8 female_g8 male_g9 i.fips i.month_year [aw=_finalwt] if age<=65, nocons
outreg2 using "${directory_out}/table2.xls", append ctitle(Obese)

*table 4
set more off
*first stage: smoking on excise tax 
reg smoke real_tax_2002 i.fips i.month_year [aw=_finalwt] if age<=65,cluster(fips)
outreg2 using "${directory_out}/table4.xls", keep(real_tax_2002) replace ctitle(1st Stage: regression of odds of smoking on excise tax) tstat 

*second stage bmi
ivregress 2sls bmi i.fips i.month_year (smoke = real_tax_2002)[aw=_finalwt] if age<=65,cluster(fips) 
outreg2 using "${directory_out}/table4.xls", keep(smoke) append ctitle(IV Results: coefficient of smoke dummy) tstat


*first stage: smokenum excise tax 
reg smokenum real_tax_2002 i.fips i.month_year [aw=_finalwt] if age<=65,cluster(fips)
outreg2 using "${directory_out}/table4.xls", keep(real_tax_2002) append ctitle(1st Stage: regression of daily cigarettes smoked (0’s for non-smokers) on excise tax) tstat

*second stage bmi
ivregress 2sls bmi i.fips i.month_year (smokenum = real_tax_2002)[aw=_finalwt] if age<=65,cluster(fips) 
outreg2 using "${directory_out}/table4.xls", keep(smokenum) append ctitle(IV Results: coefficient of daily cigarettes smoked (0’s for non-smokers)) tstat




*second stage obese
ivregress 2sls obese i.fips i.month_year (smoke = real_tax_2002)[aw=_finalwt] if age<=65,cluster(fips) 
outreg2 using "${directory_out}/table4.xls", keep(smoke) append ctitle(IV Results: coefficient of daily cigarettes smoked(0’s for non-smokers)) tstat

*second stage obese smokenum
ivregress 2sls obese i.fips i.month_year (smokenum = real_tax_2002)[aw=_finalwt] if age<=65,cluster(fips) 
outreg2 using "${directory_out}/table4.xls", keep(smokenum) append ctitle(IV Results: coefficient of daily cigarettes smoked (0’s for non-smokers)) tstat





