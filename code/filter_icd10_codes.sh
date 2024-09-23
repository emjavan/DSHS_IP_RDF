#!/bin/bash

# Check if an argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Extract directory and filename
input_dir=$(dirname "$input_file")           # Get the directory of the input file
input_base=$(basename "$input_file")         # Get the filename (without the path)
output_file="${input_dir}/filtered_${input_base}"  # Define the output file in the same directory

echo "Processing file: $input_file"
echo "Filtered output will be written to: $output_file"

# Parse the header to find the column numbers for the desired columns
columns=$(head -n 1 "$input_file" | awk -F'\t' '
{
    for (i = 1; i <= NF; i++) {
        if ($i == "PRINC_DIAG_CODE") diag1 = i;
        if ($i == "OTH_DIAG_CODE_1") diag2 = i;
        if ($i == "OTH_DIAG_CODE_2") diag3 = i;
        if ($i == "OTH_DIAG_CODE_3") diag4 = i;
    }
    print diag1, diag2, diag3, diag4;
}')

# Split the column numbers into separate variables
read col1 col2 col3 col4 <<< "$columns"

# Check if columns were found
if [[ -z "$col1" || -z "$col2" || -z "$col3" || -z "$col4" ]]; then
    echo "Error: One or more of the required columns (PRINC_DIAG_CODE, OTH_DIAG_CODE_1, OTH_DIAG_CODE_2, OTH_DIAG_CODE_3) not found in the input file."
    exit 1
fi

echo "Columns selected for filtering:"
echo "  PRINC_DIAG_CODE (column $col1)"
echo "  OTH_DIAG_CODE_1 (column $col2)"
echo "  OTH_DIAG_CODE_2 (column $col3)"
echo "  OTH_DIAG_CODE_3 (column $col4)"

# Extract disease categories and codes from the input CSV file
declare -A disease_cats
while IFS=',' read -r code description category; do
    disease_cats[$code]=$category
done < ../input_data/icd10_disease_category_list.csv  # This file contains the codes and categories

# Get unique disease categories for header
categories=$(awk -F',' 'NR > 1 {print $3}'../input_data/icd10_disease_category_list.csv | sort -u)

# Count total rows before filtering
total_rows=$(wc -l < "$input_file")
echo "Total rows before filtering: $total_rows"

# Create header for output file
header=$(head -n 1 "$input_file")
for category in $categories; do
    header+=$'\t'"${category}_MATCH"
done
echo -e "$header" > "$output_file"

# Use awk to filter and add new columns based on disease category matches (handling 3, 4, and 5 char codes)
awk -v col1="$col1" -v col2="$col2" -v col3="$col3" -v col4="$col4" '
BEGIN {
    FS = "\t"; OFS = "\t";                            # Set field separator to tab
    while (getline line < "../input_data/icd10_disease_category_list.csv") {  # Read the ICD-10 list from CSV file
        split(line, fields, ",");
        code = fields[1]; category = fields[3];
        if (length(code) == 3) match_list_3[code] = category;
        else if (length(code) == 4) match_list_4[code] = category;
        else if (length(code) == 5) match_list_5[code] = category;
    }
}
NR > 1 {                                  # Skip the header row
    # Extract the first 3, 4, and 5 characters of the relevant columns
    diag1_3 = substr($col1, 1, 3);         # First 3 chars of PRINC_DIAG_CODE
    diag1_4 = substr($col1, 1, 4);         # First 4 chars of PRINC_DIAG_CODE
    diag1_5 = substr($col1, 1, 5);         # First 5 chars of PRINC_DIAG_CODE

    diag2_3 = substr($col2, 1, 3);         # First 3 chars of OTH_DIAG_CODE_1
    diag2_4 = substr($col2, 1, 4);         # First 4 chars of OTH_DIAG_CODE_1
    diag2_5 = substr($col2, 1, 5);         # First 5 chars of OTH_DIAG_CODE_1

    diag3_3 = substr($col3, 1, 3);         # First 3 chars of OTH_DIAG_CODE_2
    diag3_4 = substr($col3, 1, 4);         # First 4 chars of OTH_DIAG_CODE_2
    diag3_5 = substr($col3, 1, 5);         # First 5 chars of OTH_DIAG_CODE_2

    diag4_3 = substr($col4, 1, 3);         # First 3 chars of OTH_DIAG_CODE_3
    diag4_4 = substr($col4, 1, 4);         # First 4 chars of OTH_DIAG_CODE_3
    diag4_5 = substr($col4, 1, 5);         # First 5 chars of OTH_DIAG_CODE_3

    # Create an associative array to track category matches
    delete matched_categories;

    # Check for matches in each column
    if (match_list_3[diag1_3]) matched_categories[match_list_3[diag1_3]] = 1;
    if (match_list_4[diag1_4]) matched_categories[match_list_4[diag1_4]] = 1;
    if (match_list_5[diag1_5]) matched_categories[match_list_5[diag1_5]] = 1;

    if (match_list_3[diag2_3]) matched_categories[match_list_3[diag2_3]] = 1;
    if (match_list_4[diag2_4]) matched_categories[match_list_4[diag2_4]] = 1;
    if (match_list_5[diag2_5]) matched_categories[match_list_5[diag2_5]] = 1;

    if (match_list_3[diag3_3]) matched_categories[match_list_3[diag3_3]] = 1;
    if (match_list_4[diag3_4]) matched_categories[match_list_4[diag3_4]] = 1;
    if (match_list_5[diag3_5]) matched_categories[match_list_5[diag3_5]] = 1;

    if (match_list_3[diag4_3]) matched_categories[match_list_3[diag4_3]] = 1;
    if (match_list_4[diag4_4]) matched_categories[match_list_4[diag4_4]] = 1;
    if (match_list_5[diag4_5]) matched_categories[match_list_5[diag4_5]] = 1;

    # Output the row and append the binary columns for each category
    printf "%s", $0
    for (category in match_list_3) {
        printf "\t%d", matched_categories[category] ? 1 : 0
    }
    printf "\n"
}' "$input_file" >> "$output_file"

# Count total rows after filtering
filtered_rows=$(wc -l < "$output_file")
echo "Total rows after filtering: $filtered_rows"

echo "Filtered data written to $output_file"