#!/bin/bash

#SBATCH -J disease_count                # Job name
#SBATCH -o disease_count.%j.o           # Name of stdout output file
#SBATCH -e disease_count.%j.e           # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 1                            # Total nodes (must be 1 for serial)
#SBATCH -n 1                            # Total mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email to send to

# Make output folder if it doesn't exist
mkdir -p "../produced_data/"

# Load R module to run script
module load Rstats

# Run code to make files and plots
Rscript disease_count_per_col.R cluster 2018Q34 2022