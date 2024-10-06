#/////////////////////////////////////////////////////////////
# Run city-lvl data cleaning functions to get the count of all 
#  patient admits per ZIP code and assign ZIP to a city
#/////////////////////////////////////////////////////////////

# Working directory is DSHS_IP_RDF/code/

#### Load the custom function from city_lvl_functions.R ####
source("get_packages_used.R")
source("sum_stats_functions.R")

# disable verbose/debug print statements
ic_disable()

#### Read in data ####
# ICD-10 code disease categorization
icd10_df = read_csv("../input_data/icd10_disease_category_list.csv") %>%
  dplyr::select(ICD10_CODE, CODE_STARTS_WITH, ICD10_3CHAR_SUBSTRING, DISEASE_CAT)
# Crosswalk for ZIPs to cities
zip_city_path = "../input_data/simplemaps_zip_to_city_tx.csv"
if(!file.exists(zip_city_path)){
  zip_to_city_tx = read_csv("../input_data/simplemaps_uszips_basicv185.csv") %>%
    filter(state_id=="TX") %>%
    select(zip, city, state_id, county_fips, county_name) %>%
    rename(PAT_ZIP_5CHAR=zip, CITY=city, STABR=state_id, 
           COUNTY_FIPS = county_fips, COUNTY_NAME = county_name)
  write.csv(zip_to_city_tx, zip_city_path)
}else{
  zip_to_city_tx = read_csv(zip_city_path)
} # end if tx only ZIP to city crosswalk file was created

#### The IP RDF patient file ####
# Local machine parameter example to test: pat_data_path="../synthetic_data/IP_RDF_synthetic_data_filtered.txt"
# On LS6 take in file path from command line: ../FILTERED_PAT_FILES/out.IP_*_filtered.txt
# *_filtered.txt files created with filter_icd10_codes.sh
args               = commandArgs(TRUE)
pat_data_path      = as.character(args[1])
patient_data       = read_tsv(pat_data_path)
output_path_prefix = gsub("_filtered.txt", "", pat_data_path)

#### Assign Disease category ####
categorized_data_path = paste0(output_path_prefix, "_categorized.csv")
if(!file.exists(categorized_data_path)){
  patient_data_icd10_cat = process_patient_data(patient_data, icd10_df)
  write.csv(patient_data_icd10_cat, categorized_data_path, row.names=F)
}else{
  patient_data_icd10_cat = read_csv(categorized_data_path)
} # end if diseases have been categorized

#### Group primary data to ZIP code level ####
admit_zip_path = paste0(output_path_prefix, "_hosp_admit_timeseries.csv")
if(!file.exists(admit_zip_path)){
  admit_per_zip = summarize_admissions_by_zip(patient_data_icd10_cat, zip_to_city_tx)
  write.csv(admit_per_zip, admit_zip_path, row.names=F)
}else{
  admit_per_zip = read_csv(admit_zip_path)
} # end if admits grouped to disease/ZIP/age grp/day



  
# Test out running on frontera
#  downloading icecream package, module load Rstats
#  get parallel script going to do each year file from command line
# write csv appropriately with year
# will need to do some error checking
# finish documentation of the columns in the files
# share path with Dongah and Jose to look at the files



