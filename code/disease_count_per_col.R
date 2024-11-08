#//////////////////////////////////////////////////////////////////////////////////////
# Code to count how many times a disease category occurs in Primary and Secondary cols
# IPRDF data is expensive, so attempting to see if Primary + 3 Secondary cols needed
# Emily Javan - 2024-11-07 - ATX
#//////////////////////////////////////////////////////////////////////////////////////

#### Load libraries ####
library(tidyverse)
library(icecream)

#### Data processing function ####
#' Count Diseases from Categorized Hospital Admission Files
#'
#' This function reads multiple files with the pattern "out.IP_*_categorized.csv" for each year 
#' from 2018 to 2022, or a single specified file, and counts the occurrences of each disease 
#' category in the columns PRIMARY_ADMIT_POA_Y, SECONDARY_ADMIT_POA_Y_1, SECONDARY_ADMIT_POA_Y_2, 
#' and SECONDARY_ADMIT_POA_Y_3.
#'
#' @param dir_path Character string. Path to the directory containing the CSV files. Default is NULL.
#' @param file_path Character string. Path to a specific CSV file for testing, e.g. synthetic data. Default is NULL.
#' @return A data frame with the columns: 
#'   `ADMIT_TYPE`, `DISEASE`, `ADMIT_POA_Y_COUNT`, `ICD10_COL_NUM`, and `YEAR` if it exists
#' @import tidyverse
#' @examples
#' \dontrun{
#'   # Count diseases in files located in the specified directory
#'   disease_counts <- count_diseases_in_files(dir_path = "../../FILTERED_PAT_FILES/")
#'   
#'   # Count diseases in a specific file for testing
#'   disease_counts <- 
#'     count_diseases_in_files(file_path = "../synthetic_data/IP_RDF_synthetic_data_categorized.csv")
#'   print(disease_counts)
#' }
count_diseases_in_files <- function(dir_path = NULL, file_path = NULL) {
  # Expected row output combinations
  admit_type = c("PRIMARY_ADMIT_POA_Y", "SECONDARY_ADMIT_POA_Y_1", "SECONDARY_ADMIT_POA_Y_2", "SECONDARY_ADMIT_POA_Y_3")
  disease = c("COV", "FLU", "ILI", "RSV", "NOT_RESP")
  
  # All the unique combinations of primary or secondary admits with disease categories
  expected_rows = expand_grid(admit_type, disease)
  
  # If a specific file path is provided, process that file
  # This processes the synthetic data to test code on local machine
  if (!is.null(file_path)) {
    # Load data
    data <- read_csv(file_path, show_col_types = FALSE)
    
    # Count occurrences of each disease in the specified columns
    results <- data %>%
      # Organize data into columns we can group by
      select(PRIMARY_ADMIT_POA_Y, SECONDARY_ADMIT_POA_Y_1, SECONDARY_ADMIT_POA_Y_2, SECONDARY_ADMIT_POA_Y_3) %>%
      pivot_longer(everything(), names_to = "admit_type", values_to = "disease") %>%
      mutate(disease = ifelse(is.na(disease), "NOT_RESP", disease)) %>%
      group_by(admit_type, disease) %>%
      summarize(admit_poa_y_count = n()) %>%
      ungroup() %>%
      
      # Add any missing combination and make it 0 count
      full_join(expected_rows, by=c("admit_type", "disease")) %>%
      mutate(icd10_col_num = gsub("SECONDARY_ADMIT_POA_Y_", "", admit_type),
             icd10_col_num = ifelse(admit_type=="PRIMARY_ADMIT_POA_Y", "0", icd10_col_num)) %>%
      replace_na(list(admit_poa_y_count=0)) %>%
      
      # Normalize the counts to percentages to make another plot
      group_by(disease) %>%
      mutate(total_records_per_disease = sum(admit_poa_y_count)) %>%
      ungroup() %>%
      mutate(percent_record_per_column = admit_poa_y_count/total_records_per_disease*100) %>%
      
      # Clean-up column names and organization for writing to file
      rename_with(toupper) %>% # make all the column names upper case
      dplyr::select(ICD10_COL_NUM, everything()) %>%
      arrange(ICD10_COL_NUM, DISEASE)

    # Write results to file
    write.csv(
      results, 
      paste0("../synthetic_data/IP_RDF_synth_disease_count_per_ICD10column.csv"),
      row.names = F
    ) # end write.csv
    
    # If a directory path is provided, process each year file
    # This is for the real data on cluster that is year dependent
  } else if (!is.null(dir_path)) {
    # All files in directory
    file_list_vect = list.files(dir_path, pattern="*_categorized.csv")
    
    ic(file_list_vect)

    # Initialize an empty data frame to store the results
    results <- data.frame()
    year_vect = rep(NA, length(file_list_vect))
    # Loop over files in dir
    for (year_index in 1:length(file_list_vect)) {
      # Get year of file in list vector
      single_year = gsub(pattern="out.IP_", "", file_list_vect[year_index])
      single_year = gsub(pattern="_categorized.csv", "", single_year)
      
      ic(single_year)

      # Path to file in input dir_path and open it
      file_path <- file.path(dir_path, file_list_vect[year_index])
      data <- read_csv(file_path, show_col_types = FALSE)
      
      # Count occurrences of each disease in the specified columns
      counts <- data %>%
        # Organize data into columns we can group by
        select(PRIMARY_ADMIT_POA_Y, SECONDARY_ADMIT_POA_Y_1, SECONDARY_ADMIT_POA_Y_2, SECONDARY_ADMIT_POA_Y_3) %>%
        pivot_longer(everything(), names_to = "admit_type", values_to = "disease") %>%
        mutate(disease = ifelse(is.na(disease), "NOT_RESP", disease)) %>%
        group_by(admit_type, disease) %>%
        summarize(admit_poa_y_count = n()) %>%
        ungroup() %>%
        
        # Add any missing combination and make it 0 count
        full_join(expected_rows, by=c("admit_type", "disease")) %>% # add any missing combination and make it 0 count
        mutate(icd10_col_num = gsub("SECONDARY_ADMIT_POA_Y_", "", admit_type),
               icd10_col_num = ifelse(admit_type=="PRIMARY_ADMIT_POA_Y", "0", icd10_col_num)) %>%
        replace_na(list(admit_poa_y_count=0)) %>%
        
        # Normalize the counts to percentages to make another plot
        group_by(disease) %>%
        mutate(total_records_per_disease = sum(admit_poa_y_count)) %>%
        ungroup() %>%
        mutate(percent_record_per_column = admit_poa_y_count/total_records_per_disease*100) %>%
        
        # Clean-up column names and organization for writing to file
        rename_with(toupper) %>% # make all the column names upper case
        mutate(YEAR = single_year) %>%
        dplyr::select(YEAR, ICD10_COL_NUM, everything()) %>%
        arrange(YEAR, ICD10_COL_NUM, DISEASE)
      
      results <- bind_rows(results, counts)
      year_vect[year_index] = single_year
      ic(year_vect)
    } # end loop over years
    
    # Write results to file
    first_year = gsub("_", "", year_vect[1])  # change to 2018Q34
    last_year  = year_vect[length(year_vect)]
    write.csv(
      results, 
      paste0("../produced_data/out.IP_", first_year, "-", last_year, "_disease_count_per_ICD10column.csv"),
      row.names = F
    ) # end write.csv
  } else {
    stop("Please provide either a directory path or a file path.")
  } # end if path to folder or files
  
  return(results)
} # end function count_diseases_in_files


#### Command line args ####
args           = commandArgs(TRUE)
data_to_run    = as.character(args[1]) # synthetic or cluster
first_year_arg = as.character(args[2]) # 2018
last_year_arg  = as.character(args[3]) # 2022

#### Synthetic data on local machine ####
if(data_to_run=="synthetic"){
  output_file_path = "IP_RDF_synth_disease_count_per_ICD10column.csv"
  if(!file.exists(output_file_path)){
    disease_counts = count_diseases_in_files(file_path = "../synthetic_data/IP_RDF_synthetic_data_categorized.csv")
  }else{
    disease_counts = read_csv(file_path)
  } # end if need to clean data again
  
  # Plot the count data by disease and year
  count_per_col_plot = 
    ggplot(disease_counts %>%
             filter(!(DISEASE=="NOT_RESP")), 
           aes(x=ICD10_COL_NUM, y=ADMIT_POA_Y_COUNT, group=DISEASE, color=DISEASE))+
    geom_line(alpha=0.5)+
    geom_point()+
    labs(x="ICD10 Column, 0=Primary, 1-3=Secondary",
         y="Count Records (Disease Present on Admit)")+
    theme_bw()
  ggsave(
    "../figures/IP_RDF_synthetic_disease_count_per_ICD10column.png",
    count_per_col_plot, 
    width=6, height=5, units="in", dpi=1200 , bg="white"
  )
  
  # Plot the percent per column by disease and year
  percent_per_col_plot = 
    ggplot(disease_counts %>%
             filter(!(DISEASE=="NOT_RESP")), 
           aes(x=ICD10_COL_NUM, y=PERCENT_RECORD_PER_COLUMN, group=DISEASE, color=DISEASE))+
    geom_line(alpha=0.5)+
    geom_point()+
    labs(x="ICD10 Column, 0=Primary, 1-3=Secondary",
         y="Percent Records (Disease Present on Admit)")+
    theme_bw()
  ggsave(
    "../figures/IP_RDF_synthetic_disease_percent_per_ICD10column.png",
    percent_per_col_plot, 
    width=6, height=5, units="in", dpi=1200 , bg="white"
  )
  
#### IP RDF data on cluster ####
}else if(data_to_run=="cluster"){
  
  output_file_path = paste0("../produced_data/out.IP_", first_year_arg, "-", last_year_arg, "_disease_count_per_ICD10column.csv")
  if(!file.exists(output_file_path)){
    disease_counts = count_diseases_in_files(dir_path = "../../FILTERED_PAT_FILES/")
  }else{
    disease_counts = read_csv(output_file_path)
  } # end if need to clean data again
  
  # Years in final file
  first_year = min(disease_counts$YEAR)
  last_year  = max(disease_counts$YEAR)
  
  ic(first_year)
  ic(last_year)

  # Plot the count data by disease and year
  count_per_col_plot = 
    ggplot(disease_counts %>%
             filter(!(DISEASE=="NOT_RESP")), 
           aes(x=ICD10_COL_NUM, y=ADMIT_POA_Y_COUNT, group=DISEASE, color=DISEASE))+
    geom_line(alpha=0.5)+
    geom_point()+
    facet_wrap(~YEAR, ncol = 2)+
    labs(x="ICD10 Column, 0=Primary, 1-3=Secondary",
         y="Count Records (Disease Present on Admit)")+
    theme_bw()
  ggsave(
    paste0("../figures/out.IP_", first_year, "-", last_year, "_disease_count_per_ICD10column.png"),
    count_per_col_plot, 
    width=9, height=11, units="in", dpi=1200 , bg="white"
  )
  
  # Plot the percent per column by disease and year
  percent_per_col_plot = 
    ggplot(disease_counts %>%
             filter(!(DISEASE=="NOT_RESP")), 
           aes(x=ICD10_COL_NUM, y=PERCENT_RECORD_PER_COLUMN, group=DISEASE, color=DISEASE))+
    geom_line(alpha=0.5)+
    geom_point()+
    facet_wrap(~YEAR, ncol = 2)+
    labs(x="ICD10 Column, 0=Primary, 1-3=Secondary",
         y="Percent Records (Disease Present on Admit)")+
    theme_bw()
  ggsave(
    paste0("../figures/out.IP_", first_year, "-", last_year, "_disease_percent_per_ICD10column.png"),
    percent_per_col_plot, 
    width=9, height=11, units="in", dpi=1200 , bg="white"
  )
  
#### Not an option ####
}else{
  print("Only options are `synthetic` or `cluster`")
}























