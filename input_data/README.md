# input_data Files

`ZIPCode-to-ZCTA-Crosswalk.xlsx` is from [HRSA.gov](https://data.hrsa.gov/DataDownload/GeoCareNavigator/ZIP%20Code%20to%20ZCTA%20Crosswalk.xlsx)

Another place to get ZIP code names is from the [US postal sevice](https://www.unitedstateszipcodes.org/tx/), 
but this isn't a unique mapping of ZIP code to a city and provides no ZCTA mapping. However, when I need to look-up 
a missing ZIP code this is a good reference to confirm. For example,

```
mutate(PAT_ZCTA = ifelse(PAT_ZCTA=="75390", "75235", PAT_ZCTA), # Dallas ZIP w/o population, really tiny
       PAT_ZCTA = ifelse(PAT_ZCTA=="78802", "78801", PAT_ZCTA) # Uvalde PO box not in crosswalk
      )
```
is hard coded into `count_patients_zcta_hosp_pairs` function because when I checked the output of `HOSP-CATCH-CALC_*`
the number of patients leaving this ZIP code for flu/ILI treatment was larger than the population estimate or wasn't 
in the ACS ZCTA download at all. 


`PUDF_Discharge_Stats/IPStat20XX.csv` files were downladed from 
[here](https://www.dshs.texas.gov/center-health-statistics/texas-health-care-information-collection/health-data-researcher-information/texas-hospital-emergency-department-research-data-file-ed-rdf/texas-inpatient-public-use-data-file-pudf).
Each file was converted to a csv and their names standarized to match. Hospitals do change locations, so there is a year dependency and possibly some county boundary re-assignment? A few hospitals seem to change county after the 2020 census.



