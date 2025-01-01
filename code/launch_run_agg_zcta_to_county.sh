#!/bin/bash

#SBATCH -J zcta_to_county               # Job name
#SBATCH -o zcta_to_county.%j.o          # Name of stdout output file
#SBATCH -e zcta_to_county.%j.e          # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 1                            # Total nodes (must be 1 for serial)
#SBATCH -n 1                            # Total mpi tasks to start at once (should be 1 for serial)
#SBATCH -t 00:05:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email to send to

# File run from inside DSHS_IP_RDF/code/

# Load module to run sinularity container
#module load tacc-apptainer
module load Rstats

# Load launcher for MPI task
module load launcher

# Book keeping statements
pwd
date

# Convert ZCTA pat files to county and save to new folder
Rscript aggregate_zcta_to_county.R
