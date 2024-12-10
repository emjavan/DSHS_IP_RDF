

#//////////////////////////////////////////////
#### Load the packages and custom function ####
#//////////////////////////////////////////////
source("get_packages_used.R")
source("sum_stats_functions.R")
source("plot_sum_stats_functions.R")

# Make dir for figs if it doesn't exist
fig_dir="../figures/"
if(!dir.exists(fig_dir)){
  dir.create(fig_dir)
} # end if fig dir not made



#/////////////////////
#### SUMMARY FIGS ####
#/////////////////////
create_los_cost_plot(patient_data = patient_data_icd10_cat, 
                     y_var = "WARD_AMOUNT", 
                     file_name = "los_wardcost_regression", 
                     width = 9, 
                     height = 11, 
                     fig_dir,
                     data_date, 
                     append_data_date_string)

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