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
echo "  Input directory:    ${INPUT_DIR}"
echo "  Trimming method:    ${PACKAGE_TO_USE}"
echo

case "${PACKAGE_TO_USE}" in

    bbduk)
        echo " Submitting BBDUK trimming job"

        TRIMMING_JOB_ID=$(
            sbatch \
                --parsable \
                --cpus-per-task="${BBDUK_CPUS}" \
                --mem-per-cpu="${BBDUK_MEM_PER_CPU}" \
                "${MODULES_DIR}/bbduk.sh"
        )
        ;;

    trimmomatic)
        echo "  Submitting Trimmomatic trimming job"

        TRIMMING_JOB_ID=$(
            sbatch \
                --parsable \
                --cpus-per-task="${TRIM_CPUS}" \
                --mem-per-cpu="${TRIM_MEM_PER_CPU}" \
                "${MODULES_DIR}/trimmomatic.sh"
        )
        ;;
    
    *)
        echo "  ERROR: Invalid PACKAGE_TO_USE '${PACKAGE_TO_USE}'"
        echo "  Valid options are: bbduk | trimmomatic"
        exit 1
        ;;
esac

echo
echo "Job submitted SUCCESSFULLY"
echo "SLURM job ID: ${TRIMMING_JOB_ID}"
echo "User may now disconnect from the cluster if required"
echo