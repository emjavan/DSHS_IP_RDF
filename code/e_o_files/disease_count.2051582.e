── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──
✔ ggplot2 3.4.3     ✔ purrr   1.0.2
✔ tibble  3.2.1     ✔ dplyr   1.1.3
✔ tidyr   1.3.0     ✔ stringr 1.5.0
✔ readr   2.1.4     ✔ forcats 0.5.1
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
Rows: 100 Columns: 7
── Column specification ────────────────────────────────────────────────────────
Delimiter: ","
chr (3): YEAR, ADMIT_TYPE, DISEASE
dbl (4): ICD10_COL_NUM, ADMIT_POA_Y_COUNT, TOTAL_RECORDS_PER_DISEASE, PERCEN...

ℹ Use `spec()` to retrieve the full column specification for this data.
ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
ℹ ic| `first_year`: chr "2018_Q3_4"
ℹ ic| `last_year`: chr "2022"
Warning messages:
1: Removed 8 rows containing missing values (`geom_line()`). 
2: Removed 8 rows containing missing values (`geom_point()`). 
