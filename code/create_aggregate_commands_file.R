#////////////////////////////////////////////////////
# Generate commands_run_aggregate_funs.txt based on
# desired parameter input combinations
# Emily Javan - ATX - 2024-12-08
#////////////////////////////////////////////////////

# NOTE
# Farinaz's project needs FLU admits by county
# Dongah's forecasting needs FLU census by city/county
# Jose's project will use COVID admits by ZCTA

# Generate disease combinations or specify a single disease
diseases = c("COV", "FLU", "ILI", "RSV") # IRB approved disease list
all_disease_comb <- lapply(1:length(diseases), function(k) {
  combn(diseases, k, simplify = FALSE)
  }) %>%
  unlist(recursive = FALSE) %>% # Flatten the list
  sapply(function(combo) paste(sort(combo), collapse = "-")) # Sort and join with "-"
# all_disease_comb = "FLU"

# How to count patients
# ADMITS = admissions only, so each admit event counted once & disregard time in hospital
# CENSUS = patient counted across their stay, so each day were they in hospital
count_type = c("HOSP_ADMIT", "HOSP_CENSUS")

# All the possible spatial resolutions
# The PAT_*** from census blocks are only 3 char, not 15, so those do not work yet
spatial_resolution = c(
  "THCIC_ID",               # HOSPITAL level time series
  #"PAT_CENSUS_BLOCKGROUP", # doubt we'd have the patient count needed to publish this resolution
  "HOSP_CITY",              # HOSPITALS within a CITY
  "PAT_CITY",               # PATIENTS mailing address within a CITY
  #"PAT_CENSUS_TRACT",      # PATIENTS mailing address within a CENSUS TRACT
  "HOSP_COUNTY",            # HOSPITALS within a County
  #"PAT_COUNTY",            # PATIENTS mailing address within a County, will include PAT_COUNTY_FIPS as col
  "PAT_ZCTA",               # PATIENTS mailing address within a ZCTA
  "HOSP_STATE"              # Only state we have is TEXAS => All TEXAS hospitals reporting
  #"PAT_STATE"              # PATIENTS mailing address within TEXAS
)

# Time series temporal resolution options
temporal_resolution = "WEEKLY" # "DAILY" must be created to aggregate to weekly

# Time series span, can only be years
min_year = "2018"
max_year = "2022"

# Running only FLU initially => only 36 combinations
all_unique_param_combinations = 
  expand_grid(
    all_disease_comb, 
    count_type, 
    spatial_resolution, 
    temporal_resolution,
    min_year,
    max_year
    )

# 270 combinations when doing all diseases
nrow(all_unique_param_combinations)

# Create command that computer will run
command_list = all_unique_param_combinations %>%
  rowwise() %>%
  mutate(COMMANDS = paste(
    "Rscript run_aggregate_funs.R",
    paste(across(all_disease_comb:max_year), collapse = " ") # Collapse the columns into a single string
  )) %>%
  ungroup()

# Write commands to file without quotes or headers
writeLines(
  command_list$COMMANDS,
  "commands_run_aggregate_funs.txt"
)



