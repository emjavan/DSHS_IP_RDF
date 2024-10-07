#!/bin/bash

#SBATCH -J cza_single                   # Job name
#SBATCH -o cza_single.%j.o              # Name of stdout output file
#SBATCH -e cza_single.%j.e              # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 1                            # Total nodes (must be 1 for serial)
#SBATCH -n 1                            # Total mpi tasks (should be 1 for serial)
#SBATCH -t 08:00:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email job status to

# File run from inside DSHS_IP_RDF/code/

# Load module to run sinularity container
#module load tacc-apptainer
module load Rstats

# Book keeping statements
pwd
date

# Did not finish making categorized file in 2hrs
Rscript run_sum_stats_functions.R ../../FILTERED_PAT_FILES/out.IP_2021_filtered.txt

