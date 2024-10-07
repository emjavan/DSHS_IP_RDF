#/////////////////////////////////////////////////////////////
# Run city-lvl data cleaning functions to get the count of all 
#  patient admits per ZIP code and assign ZIP to a city
#/////////////////////////////////////////////////////////////

# Working directory is DSHS_IP_RDF/code/

# To Do
# Add testthat error checking
# finish documentation of the columns in the files
# update readme in parent dir and code
# share path with Dongah and Jose to look at the files

#//////////////////////////////////////////////
#### Load the packages and custom function ####
#//////////////////////////////////////////////
source("get_packages_used.R")
source("sum_stats_functions.R")
source("plot_sum_stats_functions.R")

# disable verbose/debug print statements
#ic_disable()

#////////////////////////////////
#### The IP RDF patient file ####
#////////////////////////////////
# Local machine parameter example to test: pat_data_path="../synthetic_data/IP_RDF_synthetic_data_filtered.txt"
# On LS6 take in file path from command line: ../FILTERED_PAT_FILES/out.IP_*_filtered.txt
# *_filtered.txt files created with filter_icd10_codes.sh
args                = commandArgs(TRUE)
pat_data_path       = as.character(args[1])
re_make_cat_files   = as.logical(args[2])
re_make_admit_files = as.logical(args[3])
if(re_make_cat_files == T){
  re_make_admit_files = T
} # end if need to re-create all files

# Open patient data file to clean, get date, set paths
patient_data        = read_delim(pat_data_path, delim = "\t", col_types = cols(.default = "c")) %>%
  mutate(across(everything(), ~ na_if(.x, "")), # convert blanks to NAs
         across(c(PAT_AGE_DAYS, WARD_AMOUNT, ICU_AMOUNT), as.numeric)
         )
output_path_prefix = gsub("_filtered.txt", "", pat_data_path)
data_date = get_data_date(pat_data_path) # get data date and ensure sep="-"

# Make dir for figs if it doesn't exist
fig_dir="../figures/"
if(!dir.exists(fig_dir)){
  dir.create(fig_dir)
} # end if fig dir not made

# Data date doesn't exist for the synthetic data
if(!(data_date=="")){
  append_data_date_string = paste0("_", data_date) # date for figs
}else{
  append_data_date_string = ""
} # end if data_date is from real file for some local test data

#/////////////////////
#### Read in data ####
#/////////////////////
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
  write.csv(zip_to_city_tx, zip_city_path, row.names=F)
}else{
  zip_to_city_tx = read_delim(zip_city_path, delim = ",", col_types = cols(.default = "c"))
} # end if tx only ZIP to city crosswalk file was created

#////////////////////////////////
#### Assign Disease category ####
#////////////////////////////////
categorized_data_path = paste0(output_path_prefix, "_categorized.csv")
if(!file.exists(categorized_data_path) | re_make_cat_files ==T){
  patient_data_icd10_cat = process_patient_data(patient_data, icd10_df)
  write.csv(patient_data_icd10_cat, categorized_data_path, row.names=F)
}else{
  patient_data_icd10_cat = read_csv(categorized_data_path)
} # end if diseases have been categorized

#/////////////////////////////////////////////
#### Group primary data to ZIP code level ####
#/////////////////////////////////////////////
admit_zip_path = paste0(output_path_prefix, "_hosp_admit_timeseries.csv")
if(!file.exists(admit_zip_path) | re_make_admit_files==T ){
  admit_per_zip = summarize_admissions_by_zip(patient_data_icd10_cat, zip_to_city_tx)
  write.csv(admit_per_zip, admit_zip_path, row.names=F)
}else{
  admit_per_zip = read_csv(admit_zip_path)
} # end if admits grouped to disease/ZIP/age grp/day

#/////////////////////
#### SUMMARY FIGS ####
#/////////////////////
create_los_cost_plot(patient_data_icd10_cat, 
                     y_var = "WARD_AMOUNT", 
                     file_name = "los_wardcost_regression", 
                     width = 6, 
                     height = 5, 
                     fig_dir = fig_dir, 
                     data_date = data_date, 
                     append_data_date_string = append_data_date_string)

# Example usage for ICU cost plot
create_los_cost_plot(patient_data_icd10_cat, 
                     y_var = "ICU_AMOUNT", 
                     file_name = "los_icucost_regression", 
                     width = 6, 
                     height = 5, 
                     fig_dir, 
                     data_date, 
                     append_data_date_string)

# do ggpairs of numeric columns
# do cost analysis of stay by hospital and co-morbs?
#  goal of this would be to estimate days in ICU based on cost 
# Maybe cluster Ward and ICU amount with co-morbs and label by hospital
#  would be best to pull out cov/flu/ili relevant co-morbidities
# Use SPEC_UNIT_1 to confirm patients

