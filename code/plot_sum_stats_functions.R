#//////////////////////////////////////////////
# Functions used to generate figures
#//////////////////////////////////////////////


#' Create and save length of stay vs cost plots
#'
#' This function generates and saves a plot for either ward or ICU costs against the length of stay
#' for patients grouped by the primary admit disease category. You can specify the width and height of the saved plot.
#'
#' @param patient_data data.frame: The dataset containing patient information.
#' @param y_var character: The column name for the cost variable to be plotted on the y-axis (e.g., "WARD_AMOUNT" or "ICU_AMOUNT").
#' @param file_name character: The full path where the plot will be saved, including the filename.
#' @param width numeric: The width of the saved plot (default is 6).
#' @param height numeric: The height of the saved plot (default is 5).
#' @param fig_dir character: Directory where the figure will be saved.
#' @param data_date character: Date or string for plot labels.
#' @param append_data_date_string character: String to append to filename for identification.
#' @param dpi numeric: Dots per inch for saving the plot (default is 1200).
#'
#' @return NULL
#' @examples
#' create_los_cost_plot(patient_data_icd10_cat, "WARD_AMOUNT", "ward_cost_plot.png", 6, 5)
create_los_cost_plot <- function(patient_data, 
                                 y_var, 
                                 file_name, 
                                 width = 6, 
                                 height = 5, 
                                 fig_dir, 
                                 data_date, 
                                 append_data_date_string, 
                                 dpi = 1200) {
  
  # Create the ggplot
  los_cost_plt <- ggplot(patient_data %>%
                           drop_na(PRIMARY_ADMIT_POA_Y),
                         aes(x = LENGTH_OF_STAY_DAYS, y = !!sym(y_var)/100, 
                             group = PRIMARY_ADMIT_POA_Y, color = PRIMARY_ADMIT_POA_Y)) +
    geom_smooth(method = "lm", formula = "y~x") +
    geom_point(alpha = 0.3) +
    labs(x = "Patient Length of Stay", 
         y = ifelse(y_var == "WARD_AMOUNT", "Ward Amount ($)", "ICU Amount ($)"),
         color = paste0("Disease\n", data_date)) +
    theme_bw()
  
  # Save the plot
  ggsave(paste0(fig_dir, file_name, append_data_date_string, ".png"), 
         los_cost_plt, width = width, height = height, dpi = dpi)
}