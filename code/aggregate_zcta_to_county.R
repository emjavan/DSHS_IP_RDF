#/////////////////////////////////
# Translate PAT_ZCTA to PAT_COUNTY
# Only needed until we get the correct IPRDF column
#/////////////////////////////////

#//////////////////////
#### LOAD PACKAGES ####
#//////////////////////
source("get_packages_used.R")

# disable verbose/debug print statements
#ic_disable()

#//////////////////////////
#### LOAD NEEDED FILES ####
#//////////////////////////
# open crosswalk of ZCTA to TX COUNTY
# All ZCTA are unique => assigning all of a ZCTA to one county
# Crosswalk made in "hospital_catchment_estimation/code/create_thcic-id_to_ccn_crosswalk.R"
#  can be found at https://github.com/emjavan/hospital_catchment_estimation/tree/main/code
zcta_county_cross = read_csv("../input_data/US_ZCTA-CITY-COUNTY_pop_2018-2022_acs.csv") %>%
  mutate(ZCTA=as.character(ZCTA))

parallel=TRUE
if(parallel){
  input_dir_path  = "../../AGGREGATED_PAT_FILES"
  output_dir_path = "../../AGGREGATED_BY_CROSSWALK_PAT_FILES"
  if(!dir.exists(output_dir_path)){
    dir.create(output_dir_path)
  } # make output dir if needed
}else{
  input_dir_path  = output_dir_path = "../synthetic_data"
} # end if opening real or synthetic data

# List files matching the pattern
file_pattern = "IPRDF-aggregated_.*_.*_PAT-ZCTA_.*\\.csv"
agg_file_paths = list.files(
  path = input_dir_path, 
  pattern = file_pattern, 
  full.names = TRUE
)

#///////////////////////////////
#### CONVERT ZCTA TO COUNTY ####
#///////////////////////////////
for(i in 1:length(agg_file_paths)){
  ic(i)
  # Join ZCTA county crosswalk and aggregate to patients per county
  zcta_to_county_conv = read_csv(agg_file_paths[i]) %>%
    mutate(PAT_ZCTA=as.character(PAT_ZCTA)) %>%
    left_join(zcta_county_cross, by=c("PAT_ZCTA"="ZCTA"))
  
  # Sum appropriate columns depending on count type and daily/weekly
  count_type = unique(zcta_to_county_conv$COUNT_TYPE)
  weekly_file = str_detect(agg_file_paths[i], "WEEKLY")
  if(count_type=="HOSP_CENSUS" & weekly_file){
    # Weekly census files require more columns to aggregate 
    grpd_county_df = zcta_to_county_conv %>%
      # Daily files have DATE and weekly have WEEK column
      group_by(DISEASE_CAT, COUNT_TYPE, COUNTY, COUNTY_FIPS, STATE, WEEK) %>%
      # Sum the weekly metrics for all ZCTA in a county
      summarise(
        across(PATIENT_COUNT_MEAN:PATIENT_COUNT_MAX, sum, .names = "{.col}_SUM"),
        .groups = "drop"
      )
  }else{ # count_type=="HOSP_ADMIT
    # Admits is just the sum of new admissions
    #  and daily census only has patient count on each day
    grpd_county_df = zcta_to_county_conv %>%
      mutate(TOTAL_PATIENTS_TX = sum(PATIENT_COUNT) # keeping the sum for error checking at the end
      ) %>%
      # Daily files have DATE and weekly have WEEK column
      group_by(across(any_of(c("DISEASE_CAT", "COUNT_TYPE", "COUNTY", "COUNTY_FIPS", "STATE", "DATE", "WEEK")))) %>%
      summarise(
        PATIENT_COUNT = sum(PATIENT_COUNT),
        TOTAL_PATIENTS_TX = first(TOTAL_PATIENTS_TX),
        .groups = "drop"
      )
    
    # Error check that no difference in total patient count
    total_pat_after_agg = sum(grpd_county_df$PATIENT_COUNT)
    total_pat_before_agg = grpd_county_df$TOTAL_PATIENTS_TX[1]
    if(!(total_pat_after_agg==total_pat_before_agg)){
      warn("The number of patients before and after crosswalk differ")
    } # end if patient count differs
    
    grpd_county_df = grpd_county_df %>%
      dplyr::select(-TOTAL_PATIENTS_TX)
  } # end if hosp census or admit data
  
  # Write converted file to path
  file_name = tail(strsplit(agg_file_paths[i], "/")[[1]], 1)
  output_file_name = gsub("PAT-ZCTA", "PAT-COUNTY", file_name)
  ouput_file_path = paste0(output_dir_path, "/", output_file_name)
  write.csv(grpd_county_df, ouput_file_path, row.names = F)
} # end loop over files to convert

















