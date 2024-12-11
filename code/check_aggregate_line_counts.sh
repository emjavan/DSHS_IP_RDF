#!/bin/bash

# Define input files and expected line counts
input_files=(
  "../../CATEGORIZED_PAT_FILES/out.IP_2018_Q3_4_categorized.csv"
  "../../CATEGORIZED_PAT_FILES/out.IP_2019_categorized.csv"
  "../../CATEGORIZED_PAT_FILES/out.IP_2020_categorized.csv"
  "../../CATEGORIZED_PAT_FILES/out.IP_2021_categorized.csv"
  "../../CATEGORIZED_PAT_FILES/out.IP_2022_categorized.csv"
)

# Define output files to check
output_files=(
  "../../PAT_CATEGORIZED_BY_DISEASE/IPRDF-categorized_COV_2018-2022.csv"
  "../../PAT_CATEGORIZED_BY_DISEASE/IPRDF-categorized_FLU_2018-2022.csv"
  "../../PAT_CATEGORIZED_BY_DISEASE/IPRDF-categorized_ILI_2018-2022.csv"
  "../../PAT_CATEGORIZED_BY_DISEASE/IPRDF-categorized_RSV_2018-2022.csv"
)

# Tolerance percentage (e.g., 10%)
tolerance=10

# Function to count lines in a list of files
count_lines() {
  local files=("$@")
  local total=0
  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      lines=$(wc -l < "$file")
      total=$((total + lines))
    else
      echo "Warning: File $file not found."
    fi
  done
  echo $total
}

# Get total lines in input files
input_total=$(count_lines "${input_files[@]}")

# Get total lines in output files
output_total=$(count_lines "${output_files[@]}")

# Calculate expected range with tolerance
tolerance_amount=$((input_total * tolerance / 100))
min_allowed=$((input_total))
max_allowed=$((input_total + tolerance_amount))

# Output results
echo "Input Total Lines: $input_total"
echo "Output Total Lines: $output_total"
echo "Expected Range: $min_allowed - $max_allowed"

# Check if output total is within the expected range
if (( output_total >= min_allowed && output_total <= max_allowed )); then
  echo "Line counts are within the expected range."
else
  echo "Line counts are outside the expected range!"
  exit 1
fi

