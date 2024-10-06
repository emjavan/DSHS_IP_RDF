#//////////////////////////////////////////////
# Functions used for city-level data filtering
#//////////////////////////////////////////////

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
process_patient_data <- function(df, icd10_df) {
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
      LENGTH_OF_STAY_DAYS = time_length(STMT_PERIOD_THRU - ADMIT_START_OF_CARE, unit = "days"),
      
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
      )
    ) %>%
    dplyr::select(
      PRINC_DIAG_CODE, POA_PRINC_DIAG_CODE, PRIMARY_ADMIT_POA_Y,
      ends_with("_1"), ends_with("_2"), ends_with("_3"),
      starts_with("SECONDARY_"),
      contains("_ZIP"), contains("_AGE"),
      contains("_WARD"), contains("_ICU"),
      everything()
    )
  
  return(cleaned_pat_df)
} # end process_patient_data

#' Summarize admissions per ZIP code
#'
#' This function summarizes patient admissions data by disease category, ZIP code, age group, 
#' and admission start date. It also calculates the counts of secondary diagnoses for specific diseases.
#'
#' @param df data.frame: The input patient dataset that has already been processed with disease categories.
#' @param zip_to_city data.frame: The dataset mapping ZIP codes to city names.
#'
#' @return data.frame: A summary dataset with counts of primary and secondary diagnoses 
#' per disease category, ZIP code, age group, and admission date, joined with city information.
#' 
#' @examples
#' admit_summary <- summarize_admissions_by_zip(patient_data_icd10_cat, zip_to_city)
summarize_admissions_by_zip <- function(df, zip_to_city) {
  admit_per_zip = 
    df %>%
    rename(PRIMARY_ADMIT_POA_Y_DISEASE_CAT = PRIMARY_ADMIT_POA_Y) %>%
    drop_na(PRIMARY_ADMIT_POA_Y_DISEASE_CAT) %>%
    group_by(PRIMARY_ADMIT_POA_Y_DISEASE_CAT, PAT_ZIP_5CHAR, PAT_AGE_GRP, ADMIT_START_OF_CARE) %>%
    summarize(
      PRIMARY_ADMIT_COUNT = n(),
      SECONDARY_COV_COUNT = sum(SECONDARY_COV),
      SECONDARY_FLU_COUNT = sum(SECONDARY_FLU),
      SECONDARY_RSV_COUNT = sum(SECONDARY_RSV),
      SECONDARY_ILI_COUNT = sum(SECONDARY_ILI)
    ) %>%
    ungroup() %>%
    dplyr::select(
      PRIMARY_ADMIT_POA_Y_DISEASE_CAT, PAT_ZIP_5CHAR, 
      PAT_AGE_GRP, ADMIT_START_OF_CARE, contains("_COUNT")
    ) %>%
    arrange(
      PRIMARY_ADMIT_POA_Y_DISEASE_CAT, PAT_ZIP_5CHAR, PAT_AGE_GRP, ADMIT_START_OF_CARE
    ) %>%
    left_join(zip_to_city, by = c("PAT_ZIP_5CHAR"))
  
  return(admit_per_zip)
} # end summarize_admissions_by_zip

#' Extract data date from file path
#'
#' This function extracts the date from file paths that match the pattern for `out.IP_*_filtered.txt` files.
#' It handles file names with both year and quarter (e.g., `out.IP_2018_Q3_4_filtered.txt`) or just year (e.g., `out.IP_2022_filtered.txt`).
#' If the file path is for a synthetic data file (`IP_RDF_synthetic_data_filtered.txt`), it assigns `NA` to `data_date`.
#' If the file path does not match either pattern, an error is thrown.
#'
#' @param file_path character: The path to the input file.
#'
#' @return character: The extracted date or date and quarter as a string for `out.IP_*_filtered.txt` files, or `NA` for synthetic data files.
#'
#' @examples
#' get_data_date("../../FILTERED_PAT_FILES/out.IP_2018_Q3_4_filtered.txt")
#' # Returns "2018_Q3_4"
#' 
#' get_data_date("../../FILTERED_PAT_FILES/out.IP_2022_filtered.txt")
#' # Returns "2022"
#' 
#' get_data_date("../../synthetic_data/IP_RDF_synthetic_data_filtered.txt")
#' # Returns empty string
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




