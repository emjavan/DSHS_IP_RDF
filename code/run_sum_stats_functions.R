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


#### Load the custom function from city_lvl_functions.R ####
source("get_packages_used.R")
source("sum_stats_functions.R")

# disable verbose/debug print statements
#ic_disable()

#### The IP RDF patient file ####
# Local machine parameter example to test: pat_data_path="../synthetic_data/IP_RDF_synthetic_data_filtered.txt"
# On LS6 take in file path from command line: ../FILTERED_PAT_FILES/out.IP_*_filtered.txt
# *_filtered.txt files created with filter_icd10_codes.sh
args               = commandArgs(TRUE)
pat_data_path      = as.character(args[1])
patient_data       = read_delim(pat_data_path, delim = "\t", col_types = cols(.default = "c")) %>%
  mutate(across(everything(), ~ na_if(.x, "")), # convert blanks to NAs
         across(c(PAT_AGE_DAYS, WARD_AMOUNT, ICU_AMOUNT), as.numeric)
         )
output_path_prefix = gsub("_filtered.txt", "", pat_data_path)
data_date = get_data_date(pat_data_path) # get data date and ensure sep="-"
fig_dir="../figures/"
if(!dir.exists(fig_dir)){
  dir.create(fig_dir)
} # end if fig dir not made
if(!(data_date=="")){
  append_data_date_string = paste0("_", data_date) # date for figs
}else{
  append_data_date_string = ""
} # end if data_date is from real file for some local test data


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
  write.csv(zip_to_city_tx, zip_city_path, row.names=F)
}else{
  zip_to_city_tx = read_delim(zip_city_path, delim = ",", col_types = cols(.default = "c"))
} # end if tx only ZIP to city crosswalk file was created

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

#/////////////////////
#### SUMMARY FIGS ####
#/////////////////////
los_wardcost_plt = 
  ggplot(patient_data_icd10_cat %>%
           drop_na(PRIMARY_ADMIT_POA_Y),
         aes(x=LENGTH_OF_STAY_DAYS, y=WARD_AMOUNT, group=PRIMARY_ADMIT_POA_Y, color=PRIMARY_ADMIT_POA_Y))+
  geom_smooth(method = "lm", formula = "y~x")+
  geom_point()+
  labs(x="Patient Length of Stay", y="Ward Amount",
       color=paste0("Disease\n", data_date) )+
  theme_bw()
ggsave(paste0(fig_dir, "los_wardcost_regression", append_data_date_string, ".png"), 
       los_wardcost_plt, width = 5, height = 6, dpi=1200)

los_icucost_plt = 
  ggplot(patient_data_icd10_cat %>%
           drop_na(PRIMARY_ADMIT_POA_Y),
         aes(x=LENGTH_OF_STAY_DAYS, y=ICU_AMOUNT, group=PRIMARY_ADMIT_POA_Y, color=PRIMARY_ADMIT_POA_Y))+
  geom_smooth(method = "lm", formula = "y~x")+
  geom_point()+
  labs(x="Patient Length of Stay", y="ICU Amount",
       color=paste0("Disease\n", data_date) )+
  theme_bw()
ggsave(paste0(fig_dir, "los_icucost_regression", append_data_date_string, ".png"), 
       los_icucost_plt, width = 5, height = 6, dpi=1200)



