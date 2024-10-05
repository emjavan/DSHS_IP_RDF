#!/bin/bash

#SBATCH -J icd10_filter                 # Job name
#SBATCH -o icd10_filter.%j.o            # Name of stdout output file
#SBATCH -e icd10_filter.%j.e            # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 1                            # Total nodes (must be 1 for serial)
#SBATCH -n 1                            # Total mpi tasks (should be 1 for serial)
#SBATCH -t 01:00:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email to send to

# File run from inside DSHS_IP_RDF/code/

# Book keeping statements
pwd
date

# Leaving as serial task because take 11sec each
# Launch serial code

# Total rows before filtering: 1555126
# Total rows after filtering: 8991
# Took 5.835s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2018_Q3_4.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2018_Q3_4_filtered.txt

# Total rows before filtering: 3141275
# Total rows after filtering: 33368
# Took 11.629s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2019.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2019_filtered.txt

# Total rows before filtering: 2945904
# Total rows after filtering: 196218
# Took 11.446s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2020.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2020_filtered.txt

# Total rows before filtering: 3051719
# Total rows after filtering: 268126
# Took 11.899s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2021.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2021_filtered.txt

# Total rows before filtering: 3090509
# Total rows after filtering: 185730
# Took 11.521s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2022.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2022_filtered.txt
