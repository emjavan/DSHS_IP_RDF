#/////////////////////////////////////////////////////////////
# Run IP RDF cleaning and categorizing funcitons only
# These take different command line inputs, so split from 
#  the aggregation function calls
# This only needs to be run for new years of data or if there
#  is a change to cleaning => 
#  Currently have 2018Q3-2022Q4
# Emily Javan - ATX - 2024-12-08
#/////////////////////////////////////////////////////////////

# TO DO
# Add testthat error checking for all functions
# Finish documentation of the columns in produced files
# update readme in parent dir and code

# NOTES
# 1. Working directory is DSHS_IP_RDF/code/
# 2. Anticipated Change: Link hospital exact address to get 
#    patient Census Block drive times to each hospital
#    Will be a lat/long calculation Patient->Hosp

#///////////////////////////
#### FILTER IP RDF DATA ####
#///////////////////////////
parallel_env = FALSE # set to true if running on LS6
filter_data = TRUE # set to true if using original PUDF files from DSHS
icd10_csv_file = "../input_data/icd10_disease_category_list.csv"
if(filter_data==TRUE & parallel_env == FALSE){
  bash_script <- c(
    "filter_icd10_codes.sh",
    "../synthetic_data/IP_RDF_synthetic_data.txt",
    "../input_data/icd10_disease_category_list.csv",
    "../synthetic_data/IP_RDF_synthetic_data_filtered.txt"
  )
  # Run the command with system2
  result <- system2("bash", args = bash_script, stdout = TRUE, stderr = TRUE)
  
  # Print the output
  cat(result, sep = "\n")
}else{
  print("Run `sbatch launch_filter_icd10_codes.sh` on LS6 command line to re-filter IP RDF files")
} # end if filtering ICD10 codes or not needed

#///////////////////////////////////
#### LOAD PACKAGES & FUNCTIONS ####
#//////////////////////////////////
source("get_packages_used.R")
source("categorize_aggregate_funs.R")

# disable verbose/debug print statements
#ic_disable()

#////////////////////////////////////////
#### OPEN IP RDF & SET-UP FILE PATHS ####
#////////////////////////////////////////
# On LS6 take in file path from command line: ../../FILTERED_PAT_FILES/out.IP_*_filtered.txt
# *_filtered.txt files created with filter_icd10_codes.sh
if(parallel_env){
  args                = commandArgs(TRUE)
  pat_data_path       = as.character(args[1]) 
  re_make_cat_files   = as.logical(args[2])
  
  # Put categorized files in the categorized folder
  # Folder created in bash script to launch job
  output_path_prefix = gsub("_filtered.txt", "", pat_data_path)
  output_path_prefix = gsub("FILTERED", "CATEGORIZED", output_path_prefix)

}else{
  pat_data_path       = "../synthetic_data/IP_RDF_synthetic_data_filtered.txt"
  re_make_cat_files   = TRUE # synthetic files get re-categorized to ensure it's working
  
  # output folder doesn't change for synthetic data
  output_path_prefix = gsub("_filtered.txt", "", pat_data_path)
} # end if running on LS6 or locally
ic(pat_data_path) # print path for user to ensure it's valid
data_date = get_data_date(pat_data_path) # get data date and ensure sep="-"
ic(data_date) # will be empty when data is synthetic

# Open patient data file to clean, get date, set paths
patient_data = read_delim(pat_data_path, delim = "\t", col_types = cols(.default = "c")) %>%
  mutate(across(everything(), ~ na_if(.x, "")), # convert blanks to NAs
         across(c(PAT_AGE_DAYS, WARD_AMOUNT, ICU_AMOUNT), as.numeric)
         )


# Data date doesn't exist for the synthetic data
if(!(data_date=="")){
  append_data_date_string = paste0("_", data_date) # date for figs
}else{
  append_data_date_string = ""
} # end if data_date is from real file for some local test data

#////////////////////////////////
#### CATEGORIZE ICD-10 CODES ####
#////////////////////////////////
# Only categorizes COVID, Flu, ILI, and RSV approved by IRB
# i.e. not generic disease cat file like is written for PUDF data
categorized_data_path = paste0(output_path_prefix, "_categorized.csv")
if(!file.exists(categorized_data_path) | re_make_cat_files ==T){
  
  # ICD-10 code disease categorization
  icd10_df = read_csv(icd10_csv_file) %>%
    dplyr::select(ICD10_CODE, CODE_STARTS_WITH, ICD10_3CHAR_SUBSTRING, DISEASE_CAT)
  
  patient_data_icd10_cat = process_patient_data(patient_data, icd10_df)
  write.csv(patient_data_icd10_cat, categorized_data_path, row.names=F)
}else{
  patient_data_icd10_cat = read_csv(categorized_data_path) %>%
    mutate(PAT_ZIP_5CHAR = as.character(PAT_ZIP_5CHAR))
} # end if diseases have been categorized






