#/////////////////////////////////
# Load all the required R packages
#/////////////////////////////////

# On Lonestar6 corral-protected using the container r_tidycensus_jags_geo.sif
# These packages were downloaded into container on Frontera
#  then copied over. Cannot access protected data on dev node

# Packages here confirmed in container 2024-10-5 by Emily Javan

# Download the preliminary library
if (!require("pacman")) 
  install.packages("pacman")

# Load libraries
pacman::p_load(tidyverse,
               icecream,
               testthat,
               readxl
               )

