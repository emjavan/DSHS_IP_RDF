#!/bin/bash

#SBATCH -J aggregate_iprdf              # Job name
#SBATCH -o aggregate_iprdf.%j.o         # Name of stdout output file
#SBATCH -e aggregate_iprdf.%j.e         # Name of stderr error file
#SBATCH -p corralextra                  # Queue (partition) name
#SBATCH -N 2                            # Total nodes (must be 1 for serial)
#SBATCH -n 5                            # Total mpi tasks to start at once (should be 1 for serial)
#SBATCH -t 00:30:00                     # Run time (hh:mm:ss)
#SBATCH --mail-type=all                 # Send email at begin, end, fail of job
#SBATCH -A IBN24016                     # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=emjavan@utexas.edu  # Email to send to

# File run from inside DSHS_IP_RDF/code/

# Create output dirs if they don't exist
mkdir -p "../../PAT_CATEGORIZED_BY_DISEASE/"
mkdir -p ../../AGGREGATED_PAT_FILES/

# Load module to run sinularity container
#module load tacc-apptainer
module load Rstats

# Load launcher for MPI task
module load launcher

# Book keeping statements
pwd
date

# Configure launcher
EXECUTABLE=$TACC_LAUNCHER_DIR/init_launcher
PRUN=$TACC_LAUNCHER_DIR/paramrun
CONTROL_FILE=commands_run_aggregate_funs.txt
export LAUNCHER_JOB_FILE=commands_run_aggregate_funs.txt
export LAUNCHER_WORKDIR=`pwd`
export LAUNCHER_SCHED=interleaved

# Start launcher
$PRUN $EXECUTABLE $CONTROL_FILE
