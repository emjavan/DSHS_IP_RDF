#/////////////////////////////////////////////////////////////
# Run city-lvl data cleaning functions to get the count of all 
#  patient admits per ZIP code and assign ZIP to a city
#/////////////////////////////////////////////////////////////

#### Load libraries ####
library(tidyverse)

#### Load the custom function from city_lvl_functions.R ####
source("code/get_packages_used.R")
source("code/city_lvl_functions.R")

# disable verbose/debug print statements
ic_disable()

#### Read in data ####
# ICD-10 code disease categorization
icd10_df = read_csv("input_data/icd10_disease_category_list.csv") %>%
  dplyr::select(ICD10_CODE, CODE_STARTS_WITH, ICD10_3CHAR_SUBSTRING, DISEASE_CAT)
# The IP RDF patient file
patient_data = read_tsv("synthetic_data/IP_RDF_synthetic_data_filtered.txt") 
# Crosswalk for ZIPs to cities
zip_to_city = read_csv("input_data/simplemaps_uszips_basicv185.csv") %>%
  filter(state_id=="TX") %>%
  select(zip, city, state_id, county_fips, county_name) %>%
  rename(PAT_ZIP_5CHAR=zip, CITY=city, STABR=state_id, 
         COUNTY_FIPS = county_fips, COUNTY_NAME = county_name)

#### Assign Disease category ####
patient_data_icd10_cat = process_patient_data(patient_data, icd10_df)
write.csv(patient_data_icd10_cat, "synthetic_data/IP_RDF_synthetic_data_categorized.csv", row.names=F)

# Group primary data to ZIP code level
admit_per_zip =  %>%
  summarize_admissions_by_zip(patient_data_icd10_cat, zip_to_city)
write.csv(admit_per_zip, "synthetic_data/IP_RDF_synthetic_data_hosp_admit_timeseries.csv", row.names=F)


  
# Test out running on frontera
#  downloading icecream package, module load Rstats
#  get parallel script going to do each year file from command line
# write csv appropriately with year
# will need to do some error checking
# finish documentation of the columns in the files
# share path with Dongah and Jose to look at the files





