#!/bin/bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define modules directory
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"
# Define preflight directory
PREFLIGHT_DIR="${PIPELINE_DIR}/preflight"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source base functions
source "${UTILS_DIR}/functions_base.sh"

######################### LOGS ############################

# Define log directory
LOG_DIR="${PIPELINE_DIR}/logs"
# Create log directory
mkdir -p "${LOG_DIR}"

# Define log file for run_pipeline.sh
LOG_FILE="${LOG_DIR}/run_pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT for run_pipeline.sh ..."

# Define preflight array
PREFLIGHT_ARRAY=(
    "preflight_input.sh"
    "preflight_variables.sh"
    "preflight_scripts.sh"
    "preflight_commands.sh"
)

# Check for selected package
case "${PACKAGE_TO_USE}" in
    bbduk)
        # Add preflight to PREFLIGHT_ARRAY
        PREFLIGHT_ARRAY+=("preflight_bbduk.sh")
        # Source bbduk functions
        source "${UTILS_DIR}/functions_bbduk.sh"
        ;;
    trimmomatic)
        # Add preflight to PREFLIGHT_ARRAY
        PREFLIGHT_ARRAY+=("preflight_trimmomatic.sh")
        # Source trimmomatic functions
        source "${UTILS_DIR}/functions_trimmomatic.sh"
        ;;
    *)
        fail "  ERROR: Invalid PACKAGE_TO_USE: ${PACKAGE_TO_USE}; Valid options are: 'bbduk' | 'trimmomatic'"
        ;;
esac

# Iterate through preflight checks
for file in "${PREFLIGHT_ARRAY[@]}"; do
    check_file "${PREFLIGHT_DIR}/${file}" || fail "  Please ensure that preflight script exists: ${file}"
    check_file_data "${PREFLIGHT_DIR}/${file}" || fail "  Please ensure that preflight script contains data: ${file}"
    source "${PREFLIGHT_DIR}/${file}"
done

echo
echo "  Selected trimming method: '${PACKAGE_TO_USE}'"
echo "Preflight checks COMPLETE"
echo "Moving to main execution"

######################### EXPORTS #########################

# Define export array
EXPORT_ARRAY=(
    PIPELINE_DIR
    MODULES_DIR
    UTILS_DIR
    LOG_DIR
    INPUT_DIR
    PACKAGE_TO_USE
)

# Iterate over directories to export
for var in "${EXPORT_ARRAY[@]}";do
    export "${var}"
done

# Snapshot EXPORT_ARRAY
SBATCH_EXPORTS="$(IFS=,; echo "${EXPORT_ARRAY[*]}")"

######################### MAIN ############################

echo
echo "RUNNING run_pipeline.sh ..."

echo
echo "  User configuration:"
echo "    Input directory:            ${INPUT_DIR}"
echo "    Trimming method:            ${PACKAGE_TO_USE}"

echo
echo "  Submitting pipeline to SLURM..."

PIPELINE_JOB_ID=$(
    sbatch \
        --parsable \
        --export="$(SBATCH_EXPORTS)" \
        --output="${LOG_DIR}/pipeline.%j.log" \
        "${MODULES_DIR}/pipeline.sh"
) || fail "  ERROR: Failed to submit pipeline.sh"

echo
echo "Pipeline Job ID: ${PIPELINE_JOB_ID}"
echo "run_pipeline.sh COMPLETE"
echo 