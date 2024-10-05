# Example run commmands

# local machine testing with synthetic data
# 10 rows and filters to 8 matches
# Took 0.1 sec
time bash filter_icd10_codes.sh \
../synthetic_data/IP_RDF_synthetic_data.txt \
../input_data/icd10_disease_category_list.csv \
../synthetic_data/IP_RDF_synthetic_data_filtered.txt

# Lonestar6 testing with a real subset of the patient data
# This line is copied into the launch_filter_icd10_codes.sh 
#  NOT run on the login node!!!

# Took 0.77 sec and found no matches
time bash filter_icd10_codes.sh \
../../data_subsets_for_testing/head50lines_out.IP_2018_Q3_4.txt \
../input_data/icd10_disease_category_list.csv \
../../data_subsets_for_testing/head50lines_out.IP_2018_Q3_4_filtered.txt

# Total rows before filtering: 1555126
# Total rows after filtering: 8991
# Took 5.835s
time bash filter_icd10_codes.sh \
../../ALL_OG_FILES/OG_PATIENT_FILES/out.IP_2018_Q3_4.txt \
../input_data/icd10_disease_category_list.csv \
../../FILTERED_PAT_FILES/out.IP_2018_Q3_4_filtered.txt