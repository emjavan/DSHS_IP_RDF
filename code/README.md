# Running R on TACC LS6 Protected Data Cluster

## Download r_tidycensus_jags_geo.sif
`cd /corral-secure/utexas/IBN24016/DSHS_IP_RDF/code/`<br/>
Get `.sif` file from Emily if not there <br/>

## Add personal R lib to paths
Make an R library folder if it doesn't exist <br/>
`mkdir -p ~/R/x86_64-pc-linux-gnu-library/4.0/`<br/>
Open your R profile `vi ~/.Rprofile`<br/>
Press i to insert and paste in `.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.0/", .libPaths()))`<br/>
then hit esc, :wq to write and quit <br/>

Load apptainer module<br/>
`module load tacc-apptainer`<br/>
Get on an interactive development node<br/>
`idev -N 1 -n 1 -t 02:00:00 -p development`<br/>
Open the apptainer with the R library path as your personal one<br/>
`apptainer exec --env R_LIBS_USER=~/R/library r_tidycensus_jags_geo.sif R`<br/>

Run this from the pacman package webpage
```
library(devtools)
install_github("trinker/pacman")
quit()
```

This should now run
```
apptainer exec --env R_LIBS_USER=~/R/x86_64-pc-linux-gnu-library/4.0/ \
r_tidycensus_jags_geo.sif Rscript run_sum_stats_functions.R \
../synthetic_data/IP_RDF_synthetic_data_filtered.txt
```