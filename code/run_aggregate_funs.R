#///////////////////////////////////////////////////////////////////////////
#' Aggregate patient data that has already had ICD-10-CM codes categorized
#' Patient data can spatially aggregate from Census Block Group to County 
#'  and ZCTA to City. 
#' Temporally can be aggregated from daily to weekly. Weekly depends on the
#'  daily file, so it will be created if it doesn't exist.
#' Emily Javan - ATX - 2024-12-10
#///////////////////////////////////////////////////////////////////////////

#///////////////////////////////////
#### LOAD PACKAGES & FUNCTIONS ####
#//////////////////////////////////
source("get_packages_used.R")
source("categorize_aggregate_funs.R")

# disable verbose/debug print statements
#ic_disable()

#//////////////////////////////////
#### DEFINE INPUT ARGS & PATHS ####
#//////////////////////////////////
# Allocation for parallel computing on Lonestar6 
parallel_env = TRUE
if(parallel_env){
  ##### PARALLEL ENV INPUTS #####
  input_cat_dir      = "../../CATEGORIZED_PAT_FILES/"
  output_discat_dir  = "../../PAT_CATEGORIZED_BY_DISEASE/"
  output_agg_dir     = "../../AGGREGATED_PAT_FILES/"
  args        = commandArgs(TRUE)
  DISEASE_CAT = as.character(args[1]) # Disease category, i.e. FLU-ILI-RSV, FLU, COV, etc.
  COUNT_TYPE  = as.character(args[2]) # Patient count in hospital type, only HOSP_ADMIT or HOSP_CENSUS
  GRP_VAR     = as.character(args[3]) # Spatial resolution grouping variable, PAT_CITY, HOSP_COUNTY, etc.
  TIME_RES    = as.character(args[4]) # Temporal resolution, only DAILY or WEEKLY
  MIN_YEAR    = as.character(args[5]) # 4 digit year to start the time series file
  MAX_YEAR    = as.character(args[6]) # 4 digit year to end the time series file
  
  # Aggregated data output file path
  agg_output_file_path = 
    paste0(output_agg_dir, "IPRDF-aggregated_", 
           gsub("_", "-", DISEASE_CAT), "_", # turn underscore to hyphen for file name
           gsub("_", "-", COUNT_TYPE),  "_", # underscore will be used to separate file names
           gsub("_", "-", GRP_VAR),     "_", 
           TIME_RES,    "_",
           MIN_YEAR, "-", MAX_YEAR, ".csv"
    )
  ic(agg_output_file_path)
  
  # Patient grouped data together with disease categorized
  discat_output_file_path = 
    paste0(output_agg_dir, "IPRDF-categorized_", 
           gsub("_", "-", DISEASE_CAT), "_", # turn underscore to hyphen for file name
           MIN_YEAR, "-", MAX_YEAR, ".csv"
    )
  ic(discat_output_file_path)
  
  # full.names will join path to pattern when returning, so remove duplicate / from strings
  all_pat_data_list = 
    list.files(path = input_cat_dir, pattern = "_categorized.csv$", full.names = TRUE) %>%
    (function(paths) gsub("/+", "/", paths))() %>%
    # Filter by year extracted from the file names
    (function(files) Filter(function(file) {
      year <- as.numeric(str_extract(file, "\\d{4}")) # Extract the year from the file name
      ic(year)
      MIN_YEAR = as.numeric(MIN_YEAR)
      MAX_YEAR = as.numeric(MAX_YEAR)
      ic(MIN_YEAR); ic(MAX_YEAR)
      !is.na(year) && year >= MIN_YEAR && year <= MAX_YEAR # Check if year is within range
    }, files)) # Pass the files explicitly to Filter
  ic(length(all_pat_data_list))
}else{
  ##### LOCAL ENV INPUTS #####
  input_cat_dir = output_discat_dir = output_agg_dir = "../synthetic_data/"
  DISEASE_CAT = "FLU"        # Disease category, i.e. FLU-ILI-RSV, FLU, COV, etc.
  COUNT_TYPE  = "HOSP_ADMIT" # Patient count in hospital type, only HOSP_ADMIT or HOSP_CENSUS
  GRP_VAR     = "PAT_COUNTY"  # Spatial resolution grouping variable, PAT_CITY, HOSP_COUNTY, etc.
  TIME_RES    = "WEEKLY"      # Temporal resolution, only DAILY or WEEKLY
  # no date range for synthetic data
  
  # Aggregated data output file path
  agg_output_file_path = 
    paste0(output_agg_dir, "IPRDF-aggregated_", 
           gsub("_", "-", DISEASE_CAT), "_", 
           gsub("_", "-", COUNT_TYPE),  "_",
           gsub("_", "-", GRP_VAR)   ,  "_", 
           TIME_RES, ".csv"
    )
  ic(agg_output_file_path)
  # Patient grouped data together with disease categorized
  discat_output_file_path = 
    paste0(output_agg_dir, "IPRDF-categorized_", 
           gsub("_", "-", DISEASE_CAT), ".csv" # turn underscore to hyphen for file name
    )
  ic(discat_output_file_path)
  # Only one categorized synthetic file
  all_pat_data_list = paste0(input_cat_dir, "IP_RDF_synthetic_data_categorized.csv")
  ic(all_pat_data_list)
} # end if running locally or on LS6

#//////////////////////////////////
#### GROUPED DISEASE CAT FILES ####
#//////////////////////////////////
# Turn disease category string into vector
disease_vect = str_split(DISEASE_CAT, pattern = "-", simplify = FALSE)[[1]]

# If categorized disease file doesn't exist create it and filter as needed
if(!file.exists(discat_output_file_path)){
  # Row bind all the categorized files 
  # This will be very large file, but appropriate for LS6
  patient_data_icd10_cat = all_pat_data_list %>%
    # YEAR=NA for synthetic data
    lapply(function(file) {
      # Extract the year from the file name
      year <- str_extract(basename(file), "\\d{4}") # Extract 4-digit year
      
      # Read the file and add the year column
      read_csv(file, col_types = cols(.default = "c")) %>% # Read all columns as characters
        rename_all(toupper) %>% # Ensure consistent column names
        mutate(FILE_YEAR = year) # Add year column
    }) %>%
    bind_rows() %>%
    filter(if_any(
      c(PRIMARY_ADMIT_POA_Y, SECONDARY_ADMIT_POA_Y_1, SECONDARY_ADMIT_POA_Y_2, SECONDARY_ADMIT_POA_Y_3),
      ~ . %in% disease_vect
    ))
  # Save dataframe to csv
  write.csv(patient_data_icd10_cat, 
            discat_output_file_path,
            row.names=F)
  message("New file written:", discat_output_file_path)
}else{
  patient_data_icd10_cat = read_csv(discat_output_file_path)
  message("Existing file opened:", discat_output_file_path)
} # end if disease categorized file needs to be created

#////////////////////////////////
#### AGGREGATE DAILY SPATIAL ####
#////////////////////////////////
# What's going to happen...
# 1. pass patient_data_icd10_cat to
#    daily census function or admit function
# 2. save all daily to files in the aggregation folder
# 3. if weekly then aggregate to weekly and save to folder
#    will be hard coding start of week instead of passing
#    Sunday is week start Farinaz wanted

# Output path for the daily file created, daily needed to aggregate to weekly
agg_output_file_path_daily = gsub("WEEKLY", "DAILY", agg_output_file_path)
if(!file.exists(agg_output_file_path_daily)){
  if(COUNT_TYPE=="HOSP_ADMIT"){
    hosp_daily_timeseries = 
      count_hospital_admits_daily(
        patient_data_icd10_cat, 
        grouping_var = GRP_VAR # how to group for spatial resolution
    ) # end daily admit function call
  }else{ # COUNT_TYPE=="HOSP_CENSUS"
    hosp_daily_timeseries = 
      count_hospital_census_daily(
        patient_data_icd10_cat, 
        grouping_var = GRP_VAR # how to group for spatial resolution
    ) # end daily census function call
  } # end if creating daily admit or census file needed
  
  # Add book keeping columns
  hosp_daily_timeseries = hosp_daily_timeseries %>%
    mutate(
      DISEASE_CAT = DISEASE_CAT, # Disease category, i.e. FLU-ILI-RSV, FLU, COV, etc.
      COUNT_TYPE  = COUNT_TYPE,  # Patient count in hospital type, only HOSP_ADMIT or HOSP_CENSUS
    ) 
  
  # Write dataframe to csv
  write.csv(hosp_daily_timeseries,
            agg_output_file_path_daily, 
            row.names = F)
  message("New file written:", agg_output_file_path_daily)
}else{
  # If daily file exists open it 
  hosp_daily_timeseries = read_csv(agg_output_file_path_daily)
  message("Existing file opened:", agg_output_file_path_daily)
} # end if daily census file needs to be created


#///////////////////////////
#### WEEKLY AGGREGATION ####
#///////////////////////////
# Define start of week
# This is written in case you want to add as commandline parameter
day_of_week_start = toupper("sunday")
ic(day_of_week_start)
#day_of_week_start = "2020-04-05"

# Change date to day of week if that's what was passed
if(grepl("^\\d{4}-\\d{2}-\\d{2}$", day_of_week_start)){
  day_of_week_start = toupper(weekdays(as.Date(day_of_week_start)))
}

# Output path for the daily file created, daily needed to aggregate to weekly
# append start day of week, e.g. WEEKLY-SUNDAY
agg_output_file_path_weekly = 
  gsub("WEEKLY",
       paste0("WEEKLY-", day_of_week_start), 
       agg_output_file_path)

# If input it weekly and file not yet made
if(TIME_RES == "WEEKLY" & !file.exists(agg_output_file_path_weekly)){  
  # aggregate hosp_daily_timeseries to weekly
  hosp_weekly_timeseries = 
    group_daily_to_weekly(
      hosp_daily_timeseries, # data frame of patient data
      date_col     = "DATE", 
      grouping_var = GRP_VAR, # spatial geo to group by, could be HOSP_COUNTY, PAT_CITY etc.
      week_start   = day_of_week_start, # can be day or YEAR-MM-DD format
      count_type   = COUNT_TYPE
    )
  # Save weekly to file
  write.csv(
    hosp_weekly_timeseries,
    agg_output_file_path_weekly,
    row.names=F
  )
  message("New file written:", agg_output_file_path_weekly)
}else{
  message("File already exists:", agg_output_file_path_weekly)
} # end if time series aggregated to weekly from daily

