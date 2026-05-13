#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${PIPELINE_DIR:?PIPELINE_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
# Define toolname
TOOLNAME="bbtools"

######################## SOURCE ##########################

# Source tool-specific functions
source "${UTILS_DIR}/functions_${TOOLNAME}.sh"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME} install..."

# Ensure bbtools is installed in pipeline root (install if missing)
if ! check_bbtools "${PIPELINE_DIR}"; then
    install_bbtools "${PIPELINE_DIR}"
fi

echo "  Install confirmed: ${TOOLNAME}"
echo "  ${SCRIPT_NAME} COMPLETE"