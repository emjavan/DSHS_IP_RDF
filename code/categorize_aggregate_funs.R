#//////////////////////////////////////////////
# Functions used for city-level data filtering
#//////////////////////////////////////////////

#////////////////////////////////////////////////////////////
#' Extract data date from file path
#'
#' This function extracts the date from file paths that match the pattern for `out.IP_*_filtered.txt` files.
#' It handles file names with both year and quarter 
#' (e.g., `out.IP_2018_Q3_4_filtered.txt`) or just year (e.g., `out.IP_2022_filtered.txt`).
#' If the file path is for a synthetic data file 
#' (`IP_RDF_synthetic_data_filtered.txt`), it assigns `NA` to `data_date`.
#' If the file path does not match either pattern, an error is thrown.
#'
#' @param file_path character: The path to the input file.
#' @return character: The extracted date or date and quarter as a string for 
#' `out.IP_*_filtered.txt` files, or `NA` for synthetic data files.
#' @examples
#' get_data_date("../../FILTERED_PAT_FILES/out.IP_2018_Q3_4_filtered.txt")
#' # Returns "2018_Q3_4"
get_data_date <- function(file_path) {
  if (grepl("out\\.IP_.*_filtered\\.txt$", file_path)) {
    # Extract the date or date+quarter from the out.IP file name
    data_date = gsub(".*out\\.IP_", "", file_path)
    data_date = gsub("_filtered\\.txt$", "", data_date)
    data_date = gsub("_", "-", data_date)
  } else if (grepl("synthetic_data/IP_RDF_synthetic_data_filtered\\.txt$", file_path)) {
    # For synthetic data files, set data_date to NA
    data_date <- ""
  } else {
    stop("Unknown file type")
  } # end if else
  
  return(data_date)
} # end get_data_date

#////////////////////////////////////////////////////////////
#' Clean a text col to get rid of unknown characters or 
#'  ones that get used selectively, e.g. St. > St > ST
clean_text_column <- function(string) {
  
  # Apply the cleaning logic
  clean_string = string %>%
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT", sub = "") %>% # Remove non-ASCII characters
    gsub(" - ", " ", .) %>% # Replace hyphen with spaces around it
    gsub("-", " ", .) %>% # Replace hyphen without spaces with a space
    gsub("[&,'\\.()]", "", .) %>% # Remove &, commas, apostrophes, periods, and parentheses
    gsub("  ", " ", .) %>% # Replace any double spaces with single
    toupper() # Convert to uppercase
  
  return(clean_string)
} # end clean_text_column

#////////////////////////////////////////////////////////////
#' Normalize street addresses
norm_name_with_dict <- function(name, dictionary) {
  
  # Convert dictionary to a named vector
  replacements <- setNames(dictionary$NEW_NAME, # replacements
                           dictionary$OG_NAME ) # patterns
  
  # Apply all replacements at once
  name <- toupper(name) # Ensure consistency
  name_new <- str_replace_all(name, replacements) # Vectorized replacements
  
  return(name_new)
} # end norm_name_with_dict

#////////////////////////////////////////////////////////////
#' Link THCIC_IDs to city and county through time
#' Seems to be change difference in 2020 with new census, so year is a needed feature
hospital_ids_to_city_county = function(){
  output_file_path = "../input_data/thcic-ids_city_county_crosswalk.csv"
  
  if(!file.exists(output_file_path)){
    #### DICT + CROSSWALK ####
    # Hand-made dictionary of replacements
    # Ensuring any white space in CSV matches encoding in R (was having issues)
    hosp_name_dict  = read_csv("../input_data/HospitalName_Replacements.csv") %>%
      mutate(
        OG_NAME = str_trim(OG_NAME), # Remove leading/trailing spaces
        OG_NAME = str_replace_all(OG_NAME, "\\s+", " ") # Replace multiple spaces with a single space
      )
    county_name_crosswalk = read_csv("../input_data/US_ZCTA-CITY-COUNTY_pop_2018-2022_acs.csv") %>%
      dplyr::select(COUNTY, COUNTY_FIPS) %>%
      drop_na() %>%
      distinct() # 3198
    
    #### PUDF STATISTICS ####
    # Define the folder containing the Excel files
    folder_path <- "../input_data/PUDF_Discharge_Stats/"
    
    # Get a list of all .xls and .xlsx files in the folder
    pudf_stats_files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)
    
    combined_data <- pudf_stats_files %>%
      lapply(function(file) {
        # Extract the year from the file name
        year <- str_extract(basename(file), "\\d{4}") # Extract 4-digit year
        
        # Read the file and add the year column
        read_csv(file, col_types = cols(.default = "c")) %>% # Read all columns as characters
          rename_all(toupper) %>% # Ensure consistent column names
          mutate(YEAR = year) # Add year column
      }) %>%
      bind_rows() %>% # 1677 rows # Combine all into a single data frame 
      # removes 1 NA row and 4 end of file character strings => 1672 rows
      filter(str_detect(THCIC_ID, "^\\d{6}$")) # Matches exactly 6 digits
    
    total_hosp_ids = length(unique(combined_data$THCIC_ID)) # 863
    
    combined_data_clean = combined_data %>%
      dplyr::select(-starts_with("Q"), -starts_with("END")) %>%
      rename(HOSP_NAME       = HOSPITAL_NAME, HOSP_CITY = HOSPITAL_CITY) %>%
      mutate(COUNTY_FIPS     = coalesce(COUNTY, COUNTY_FIPS),
             COUNTY_FIPS     = paste0("48", COUNTY_FIPS), # add state code
             HOSP_NAME_clean = norm_name_with_dict(clean_text_column(HOSP_NAME), hosp_name_dict),
             HOSP_CITY       = clean_text_column(HOSP_CITY),
             COUNTY_NAME     = toupper(COUNTY_NAME)
      ) %>%
      dplyr::select(-COUNTY) %>% # remove redundant county fips col with unclear name
      distinct() %>%
      left_join(county_name_crosswalk, by="COUNTY_FIPS") %>%
      rename(HOSP_COUNTY_FIPS = COUNTY_FIPS) %>%
      mutate(HOSP_COUNTY = coalesce(COUNTY_NAME, COUNTY),
             HOSP_STATE = "TX") %>%
      dplyr::select(-COUNTY_NAME, -COUNTY) %>%
      drop_na() %>% 
      distinct() %>%
      dplyr::select(THCIC_ID, starts_with("HOSP_NAME"), 
                    HOSP_CITY, HOSP_COUNTY, HOSP_COUNTY_FIPS, 
                    HOSP_STATE, YEAR)
    
    total_hosp_ids_clean =length(unique(combined_data_clean$THCIC_ID)) # 863
    
    if(!(total_hosp_ids_clean == total_hosp_ids)){
      rlang::warn("THCIC_IDs missing after drop_na()")
    } # end if drop_na was heavy handed
    
    write.csv(combined_data_clean, output_file_path, row.names=F)
  } else {
    combined_data_clean = read_csv(output_file_path) %>%
      mutate(across(everything(), as.character))
  } # end if file already exists
  
  return(combined_data_clean)
} # end function hospital_ids_to_address

#////////////////////////////////////////////////////////////////////////////////////////////////////
#' Function to check ICD-10 code match based on matching the first 3 characters or the full string.
#' 
#' This function checks if the diagnosis code from patient data matches an ICD-10 code from the ICD-10 category list.
#' Depending on the value of `code_start_with`, the function will either compare the first 3 characters or the entire string.
#' 
#' @param diag_code A character string. The diagnosis code from the patient data (e.g., PRINC_DIAG_CODE).
#' @param icd10_code A character string. The ICD-10 code from the ICD-10 category list.
#' @param code_start_with A character string ("T" or "F"). Indicates whether to match by the first 3 characters ("T") or the full string ("F").
#' @return A logical value. Returns `TRUE` if the codes match according to the `code_start_with` rule, `FALSE` otherwise.
#' 
#' @examples
#' # Example where codes match the first 3 characters
#' match_icd10("J129", "J12", "T") # TRUE
#' 
#' # Example where full string match is required
#' match_icd10("J129", "J129", "F") # TRUE
#' 
#' # Example where no match occurs
#' match_icd10("J129", "J128", "F") # FALSE
match_icd10 <- function(diag_code, icd10_code, code_start_with) {
  # Check if the code should match on the first 3 characters
  if (code_start_with == "T") {
    # Return TRUE if the first 3 characters of both codes match
    return(substr(diag_code, 1, 3) == substr(icd10_code, 1, 3))
  } else {
    # Return TRUE if the full strings match
    return(diag_code == icd10_code)
  }
  # Explicitly return FALSE if neither condition is met (not really needed due to logic but makes the intent clearer)
  return(FALSE)
}

#' Function to assign disease category based on diagnosis codes and POA status
#'
#' This function checks whether the given diagnosis code (either primary or secondary) matches an entry
#' in the ICD-10 disease category list. It then returns the corresponding disease category if the POA
#' code is "Y", indicating that the diagnosis was present on admission.
#'
#' @param diag_code A character string. The diagnosis code from the patient data (e.g., PRINC_DIAG_CODE).
#' @param poa_code A character string. The POA (Present on Admission) code, typically "Y" or "N".
#' @param icd10_df A data frame. The ICD-10 disease category list with columns ICD10_CODE, CODE_START_WITH, and DISEASE_CAT.
#'
#' @return A character string. Returns the disease category if a match is found and POA code is "Y". Otherwise, returns NA.
#' 
#' @example assign_disease_category(diag_code="J1011", poa_code="Y", icd10_df)
assign_disease_category <- function(diag_code, poa_code, icd10_df) {
  
  if (is.na(diag_code)) {
    return(NA_character_)  # Return NA for missing POA codes or when POA is not "Y"
  }
  
  if ((!is.na(poa_code)) & (poa_code == "Y")) {
    # Add columns for icd-10 substring and matching logic, then filter for only matching string
    match_row <- icd10_df %>%
      mutate(
        diag_substr = substr(diag_code,  1, 3) # Extract first 3 characters from diag_code
      ) %>%
      rowwise() %>%
      mutate(
        match_condition = ifelse(CODE_STARTS_WITH == T, 
                                 diag_substr == ICD10_3CHAR_SUBSTRING, 
                                 diag_code == ICD10_CODE)  # Match logic
      ) %>%
      ungroup() %>%
      filter(match_condition)
    
    # Return the disease category if a match is found
    if (nrow(match_row) > 0) {
      # print the matched row if debugging
      #ic(c(match_row$ICD10_CODE[1], match_row$DISEASE_CAT[1]))
      return(match_row$DISEASE_CAT[1])  # Return the first matching disease category
    } else {
      return(NA_character_)  # Return NA if no match is found
    }
  }
  return(NA_character_)  # Return NA if POA code is not "Y"
} # end assign_disease_category


#' Assign disease categories and create summary variables
#'
#' This function processes a dataset by assigning disease categories based on ICD-10 codes
#' and creating binary variables indicating the presence of specific diseases (COV, FLU, RSV, ILI) in secondary diagnoses.
#' It also processes length of stay, ZIP codes, ward/ICU status, and age groups.
#'
#' @param df data.frame: The input patient dataset.
#' @param icd10_df data.frame: The ICD-10 code reference dataset.
#'
#' @return data.frame: A modified patient dataset with assigned disease categories, binary flags for specific diseases,
#' processed length of stay, ZIP code, and age group.
#' 
#' @examples
#' processed_data <- process_patient_data(patient_data, icd10_df)
process_patient_data <- function(
    df, 
    icd10_df
    ) {
  
  # Crosswalk only county name to county fips
  county_name_crosswalk = read_csv("../input_data/US_ZCTA-CITY-COUNTY_pop_2018-2022_acs.csv") %>%
    dplyr::select(COUNTY, COUNTY_FIPS) %>%
    drop_na() %>%
    distinct() %>% # 3198
    rename_with(~ paste0("PAT_", .x)) # Add "PAT_" prefix to all column names
  
  # Open crosswalk from ZIPs to ZCTAs and join ZCTA to City crosswalk
  zip_zcta_city_crosswalk = readxl::read_xlsx("../input_data/ZIPCode-to-ZCTA-Crosswalk.xlsx") %>%
    rename(PAT_ZCTA=zcta, PAT_ZIP_5CHAR = ZIP_CODE) %>%
    mutate(PAT_ZCTA = ifelse(PAT_ZIP_5CHAR=="75390", "75235", PAT_ZCTA), # Dallas ZIP w/o population, really tiny
           PAT_ZCTA = ifelse(PAT_ZIP_5CHAR=="78802", "78801", PAT_ZCTA)  # Uvalde PO box not in crosswalk
    ) %>%
    left_join(read_csv("../input_data/US_ZCTA-CITY-COUNTY_pop_2018-2022_acs.csv"), 
              by=c("PAT_ZCTA"="ZCTA")) %>%
    separate(CITY_NAME, into=c("PAT_CITY", NA), sep=", ", extra="merge") %>%
    dplyr::select(PAT_ZIP_5CHAR, PAT_ZCTA, PAT_CITY)
  
  # Categorize ICD-10s of patients and get all their features
  cleaned_pat_df =
    df %>%
    rowwise() %>%
    # Assign disease categories based on ICD-10 codes for primary and secondary diagnoses
    mutate(
      PRIMARY_ADMIT_POA_Y     = assign_disease_category(PRINC_DIAG_CODE, POA_PRINC_DIAG_CODE, icd10_df),
      SECONDARY_ADMIT_POA_Y_1 = assign_disease_category(OTH_DIAG_CODE_1, POA_OTH_DIAG_CODE_1, icd10_df),
      SECONDARY_ADMIT_POA_Y_2 = assign_disease_category(OTH_DIAG_CODE_2, POA_OTH_DIAG_CODE_2, icd10_df),
      SECONDARY_ADMIT_POA_Y_3 = assign_disease_category(OTH_DIAG_CODE_3, POA_OTH_DIAG_CODE_3, icd10_df),
      
      # Binary flags if any of the disease categories (COV, FLU, RSV, ILI) appear in secondary diagnoses
      # Convert NA values to FALSE before summing
      SECONDARY_COV = as.integer(sum(across(starts_with("SECONDARY_ADMIT_POA_Y"), 
                                            ~ replace_na(. == "COV", FALSE)) > 0)),
      SECONDARY_FLU = as.integer(sum(across(starts_with("SECONDARY_ADMIT_POA_Y"), 
                                            ~ replace_na(. == "FLU", FALSE)) > 0)),
      SECONDARY_RSV = as.integer(sum(across(starts_with("SECONDARY_ADMIT_POA_Y"), 
                                            ~ replace_na(. == "RSV", FALSE)) > 0)),
      SECONDARY_ILI = as.integer(sum(across(starts_with("SECONDARY_ADMIT_POA_Y"), 
                                            ~ replace_na(. == "ILI", FALSE)) > 0))
    ) %>%
    ungroup() %>%
    mutate(
      # Calculate length of stay
      ADMIT_START_OF_CARE = lubridate::ymd(ADMIT_START_OF_CARE),
      STMT_PERIOD_THRU    = lubridate::ymd(STMT_PERIOD_THRU),
      LENGTH_OF_STAY_DAYS = lubridate::time_length(STMT_PERIOD_THRU - ADMIT_START_OF_CARE, unit = "days"),
      ADMIT_YEAR          = as.character(lubridate::year(ADMIT_START_OF_CARE)), # Extract year
      
      # Binary flags for ward and ICU amounts being 0
      WARD_AMOUNT_0USD = ifelse(WARD_AMOUNT == 0, 1, 0),
      ICU_AMOUNT_0USD  = ifelse(ICU_AMOUNT  == 0, 1, 0),
      
      # Minimize ZIP codes to 5 characters
      PAT_ZIP_5CHAR = substr(PAT_ZIP, 1, 5),
      
      # Convert patient age in days to years and assign to an age group
      PAT_AGE_YRS_FLOOR = floor(PAT_AGE_DAYS / 365),
      PAT_AGE_GRP = case_when(
        PAT_AGE_YRS_FLOOR >= 0  & PAT_AGE_YRS_FLOOR <= 4  ~ "0-4",
        PAT_AGE_YRS_FLOOR >= 5  & PAT_AGE_YRS_FLOOR <= 9  ~ "5-9",
        PAT_AGE_YRS_FLOOR >= 10 & PAT_AGE_YRS_FLOOR <= 17 ~ "10-17",
        PAT_AGE_YRS_FLOOR >= 18 & PAT_AGE_YRS_FLOOR <= 49 ~ "18-49",
        PAT_AGE_YRS_FLOOR >= 50 & PAT_AGE_YRS_FLOOR <= 64 ~ "50-64",
        PAT_AGE_YRS_FLOOR >= 65                           ~ "65+",
        TRUE ~ NA_character_ # Catch any unmatched cases
      ),
      PAT_STATE_FIPS             = str_sub(PAT_ADDR_CENSUS_BLOCK, 1, 2),
      PAT_COUNTY_FIPS            = str_sub(PAT_ADDR_CENSUS_BLOCK, 1, 5),
      PAT_CENSUS_TRACT_FIPS      = str_sub(PAT_ADDR_CENSUS_BLOCK, 1, 11),
      PAT_CENSUS_BLOCKGROUP_FIPS = str_sub(PAT_ADDR_CENSUS_BLOCK, 1, 12)
    ) %>%
    # Add county names, since people like to search those
    left_join(county_name_crosswalk, by="PAT_COUNTY_FIPS") %>%
    dplyr::select(
      PRINC_DIAG_CODE, POA_PRINC_DIAG_CODE, PRIMARY_ADMIT_POA_Y,
      ends_with("_1"), ends_with("_2"), ends_with("_3"),
      starts_with("SECONDARY_"),
      contains("_ZIP"), contains("_AGE"),
      contains("_WARD"), contains("_ICU"),
      everything()
    ) %>%
    left_join(zip_zcta_city_crosswalk, by="PAT_ZIP_5CHAR") %>%
    # Open all info about the hospital THCIC_ID
    left_join(hospital_ids_to_city_county(), by=c("THCIC_ID", "ADMIT_YEAR"="YEAR")) %>%
    mutate(PAT_CITY = toupper(PAT_CITY))
  
  return(cleaned_pat_df)
} # end process_patient_data

#////////////////////////////////////////////////////////////
#' Count patients admitted to hospital for each date someone 
#'  admitted, i.e. only non-zero days in file
#' User will have to expand to 0 count days if needed for use
count_hospital_admits_daily = function(
  patient_data, # data frame of patient data
  grouping_var = "PAT_COUNTY", # spatial geo to group by, could be HOSP_COUNTY, PAT_CITY etc.
  optional_grp_var = NULL # pass if age needed, but should come from command line "PAT_AGE_GRP"
  ){
  # Check grouping variable in df
  if (!grouping_var %in% names(patient_data) || 
      (!is.null(optional_grp_var) && !optional_grp_var %in% names(patient_data))) {
    stop(paste(
      "Grouping variable", grouping_var, 
      if (!is.null(optional_grp_var)) paste("or optional variable", optional_grp_var) else "",
      "not found in the data."
    ))
  } # end if grouping_var and optional_grp_var not in passed data frame
  
  # Dynamically find columns that start with grouping_var
  # e.g. group_by both PAT_COUNTY and PAT_COUNTY_FIPS
  group_vars <- names(patient_data)[startsWith(names(patient_data), grouping_var)]
    
  # Add optional_grp_var if not NULL
  if (!is.null(optional_grp_var)) {
    group_vars <- c(group_vars, optional_grp_var)
  } # end if using optional grouping var
  
  # Convert time series to count of patients in hospital on day by spatial resolution
  hospital_admit_count <- patient_data %>%
    mutate(
      ADMIT_START_OF_CARE = lubridate::ymd(ADMIT_START_OF_CARE)
    ) %>%
    # Group by each date and count the number of patients
    group_by(across(all_of(group_vars)), ADMIT_START_OF_CARE) %>%
    summarise(PATIENT_COUNT = n(), .groups = "drop") %>%
    # Give consistent naming scheme to match hosp census data
    rename(DATE = ADMIT_START_OF_CARE)
  
  return(hospital_admit_count)
  } # end count_hospital_admits_daily

#////////////////////////////////////////////////////////////////////////////////////////////////
#' Count patients currently at hospital, e.g. hospital census
#' Will make very large files depending on the grouping variable
#'   but won't have any 0s for dates and spatial geometries
#' Dependent on the pre-filtered patient_data passed, i.e. only has
#'   FLU primary/secondary patients if that's what's desired
count_hospital_census_daily = function(
    patient_data, # data frame of patient data
    grouping_var = "PAT_COUNTY", # spatial geo to group by, could be HOSP_COUNTY, PAT_CITY etc.
    optional_grp_var = NULL # pass if age needed, but should come from command line "PAT_AGE_GRP"
    ){
  # Check grouping variable in df
  if (!grouping_var %in% names(patient_data) || 
      (!is.null(optional_grp_var) && !optional_grp_var %in% names(patient_data))) {
    stop(paste(
      "Grouping variable", grouping_var, 
      if (!is.null(optional_grp_var)) paste("or optional variable", optional_grp_var) else "",
      "not found in the data."
    ))
  } # end if grouping_var and optional_grp_var not in passed data frame
  
  # Dynamically find columns that start with grouping_var
  # e.g. group_by both PAT_COUNTY and PAT_COUNTY_FIPS
  group_vars <- names(patient_data)[startsWith(names(patient_data), grouping_var)]
  
  # Add optional_grp_var if not NULL
  if (!is.null(optional_grp_var)) {
    group_vars <- c(group_vars, optional_grp_var)
  } # end if using optional grouping var
  
  # Convert time series to count of patients in hospital on day by spatial resolution
  hospital_census_count <- patient_data %>%
    mutate(
      ADMIT_START_OF_CARE = lubridate::ymd(ADMIT_START_OF_CARE),
      STMT_PERIOD_THRU = lubridate::ymd(STMT_PERIOD_THRU)
    ) %>%
    # Create a sequence of dates for each patient
    rowwise() %>%
    mutate(DATE = list(seq.Date(ADMIT_START_OF_CARE, STMT_PERIOD_THRU, by = "day"))) %>%
    ungroup() %>%
    # Expand and unnest the date range
    unnest(DATE) %>%
    # Group by each date and count the number of patients
    group_by(across(all_of(c(group_vars) )), DATE) %>%
    summarise(PATIENT_COUNT = n(), .groups = "drop")
  
  return(hospital_census_count)
} # end count_hospital_census

#////////////////////////////////////////////////////////////////////////////////////////////////
#' Group daily data into weekly by specifying the start of the week
#' Start can be day, "MONDAY", or a date and it will determine day of week
#' A date input does not filter data to starting with that date, only day of week
group_daily_to_weekly <- function(
    patient_data, # data frame of patient data
    date_col         = "DATE", 
    grouping_var     = "PAT_COUNTY", # spatial geo to group by, could be HOSP_COUNTY, PAT_CITY etc.
    optional_grp_var = NULL, # pass if age needed, but should come from command line "PAT_AGE_GRP"
    week_start       = "SUNDAY", # can be day or YEAR-MM-DD format
    count_type       = "HOSP_ADMIT" # Or HOSP_CENSUS
    ) {
  # Convert date column to Date if not already
  patient_data <- patient_data %>%
    mutate(across(all_of(date_col), as.Date))
  
  # ensure day inputs match
  week_start   = toupper(week_start)
  start_date   = as.Date("2020-04-05") # Start with a known Sunday
  # "MONDAY"    "TUESDAY"   "WEDNESDAY" "THURSDAY"  "FRIDAY"    "SATURDAY"  "SUNDAY"
  days_of_week = toupper(weekdays(seq.Date(start_date, start_date + 6, by = "day")))
  
  # Define the start of the week
  # YEAR-MM-DD format expected
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", week_start)) {
    # Specific date provided, use it as the start of the week
    start_date   = lubridate::ymd(week_start)
  } else if (week_start %in% days_of_week) {
    # Sunday = 1, ... Saturday = 7
    week_start_num <- match(week_start, days_of_week)
    start_date <- start_date + week_start_num - 1
  } else {
    stop("Invalid week_start format. Use a specific date ('YYYY-MM-DD') or a day of the week.")
  } # end if taking in a specific date or a string
  
  # Add WEEK column to data frame for grouping
  patient_data <- patient_data %>%
    mutate(
      WEEK = start_date + 7 * floor(as.numeric(difftime(.data[[date_col]], start_date, units = "days")) / 7)
    )
  
  # Dynamically find columns that start with grouping_var
  # e.g. group_by both PAT_COUNTY and PAT_COUNTY_FIPS
  group_vars <- names(patient_data)[startsWith(names(patient_data), grouping_var)]
  
  # Add optional_grp_var if not NULL
  if (!is.null(optional_grp_var)) {
    group_vars <- c(group_vars, optional_grp_var)
  } # end if using optional grouping var
  
  # Controls how to aggregate from daily to weekly
  if(count_type == "HOSP_ADMIT"){
    weekly_data <- patient_data %>%
      group_by(across(all_of(group_vars)), WEEK) %>%
      summarise(PATIENT_COUNT = sum(PATIENT_COUNT), .groups = "drop")
  }else{
    weekly_data <- patient_data %>%
      group_by(across(all_of(group_vars)), WEEK) %>%
      summarise(
        PATIENT_COUNT_SUM    = sum(PATIENT_COUNT),
        COVERAGE_DAYS        = n(),
        PATIENT_COUNT_MEAN   = PATIENT_COUNT_SUM/COVERAGE_DAYS,
        PATIENT_COUNT_MEDIAN = median(PATIENT_COUNT),
        PATIENT_COUNT_MIN    = min(PATIENT_COUNT),
        PATIENT_COUNT_MAX    = max(PATIENT_COUNT),
        .groups = "drop")
  } # end if doing admits or census
 
  return(weekly_data)
} # end group_daily_to_weekly















