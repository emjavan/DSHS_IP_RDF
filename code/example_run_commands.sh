# Example run commmands

# local machine testing with synthetic data
time bash filter_icd10_codes.sh \
../synthetic_data/IP_RDF_synthetic_data.txt \
../input_data/icd10_disease_category_list.csv

# Lonestar6 testing with a real subset of the patient data
# This line is copied into the launch_filter_icd10_codes.sh 
#  NOT run on the login node!!!
time bash filter_icd10_codes.sh \
../../data_subsets_for_testing/head50lines_out.IP_2018_Q3_4.txt \
../input_data/icd10_disease_category_list.csv