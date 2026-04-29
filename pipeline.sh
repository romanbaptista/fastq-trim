#!/bin/bash

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Export pipeline root path
export PIPELINE_DIR
# Define MODULES directory path
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output"
# Create OUTPUT directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### PIPELINE #######################
echo
echo "RUNNING trim pipeline..."
echo "User configuration from config.sh:"
echo "  Parameter 1:            $PARAMETER1"
echo "  Parameter 2:            $PARAMETER2"
echo

# Submit first job
FIRST_JOB=$(
    sbatch \
    --parsable \
    "${MODULES_DIR}/scriptname1.sh"
)

# Submit second job
SECOND_JOB=$(
    sbatch \
    --parsable \
    --dependency=afterok:"${FIRST_JOB}" \
    "${MODULES_DIR}/scriptname2.sh"
) || {
    echo "  Failed to submit scriptname2.sh. Exiting..."
    exit 1
}

echo
echo "  Pipeline submitted successfully"
echo