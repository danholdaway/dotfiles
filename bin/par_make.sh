#!/bin/bash
#SBATCH --job-name=make_job
#SBATCH --nodes=1
#SBATCH --time=06:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

# Usage: sbatch submit_make_job.sh <build_dir> [num_jobs]

BUILD_DIR="$1"
NUM_JOBS="${2:-12}"

if [ -z "$BUILD_DIR" ]; then
  echo "Error: No build directory provided."
  exit 1
fi

cd "$BUILD_DIR" || { echo "Failed to cd to $BUILD_DIR"; exit 1; }

# Move SLURM log files into the build directory
mv "$SLURM_JOB_NAME-$SLURM_JOB_ID.out" "$BUILD_DIR/slurm-$SLURM_JOB_ID.out"
mv "$SLURM_JOB_NAME-$SLURM_JOB_ID.err" "$BUILD_DIR/slurm-$SLURM_JOB_ID.err"

make VERBOSE=yes 

#-j$NUM_JOBS
