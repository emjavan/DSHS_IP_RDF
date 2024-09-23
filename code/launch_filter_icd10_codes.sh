#!/bin/bash

#SBATCH -J test_icd10_filter            # Job name
#SBATCH -o test_icd10_filter.%j.o       # Name of stdout output file
#SBATCH -e test_icd10_filter.%j.e       # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 1                            # Total nodes (must be 1 for serial)
#SBATCH -n 1                            # Total mpi tasks (should be 1 for serial)
#SBATCH -t 00:30:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email to send to

# File run from inside DSHS_IP_RDF/code/

# Book keeping statements
pwd
date

# Launch serial code
time bash filter_icd10_codes.sh \
../../data_subsets_for_testing/head50lines_out.IP_2018_Q3_4.txt \
../input_data/icd10_disease_category_list.csv