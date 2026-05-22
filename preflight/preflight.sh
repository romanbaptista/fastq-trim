#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${PREFLIGHT_DIR:?PREFLIGHT_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${PREFLIGHT_ARRAY:?PREFLIGHT_ARRAY not set (check arrays.sh)}"
: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."

# Check for selected package
case "${PACKAGE_TO_USE}" in
    bbduk)
        # Define TOOL_PREFLIGHT
        TOOL_PREFLIGHT="preflight_bbduk.sh"
        ;;
    trimmomatic)
        # Define TOOL_PREFLIGHT
        TOOL_PREFLIGHT="preflight_trimmomatic.sh"
        ;;
    *)
        fail "  ERROR: Invalid PACKAGE_TO_USE: ${PACKAGE_TO_USE}; Valid options are: 'bbduk' | 'trimmomatic'"
        ;;
esac

# Iterate through preflight checks
for file in "${PREFLIGHT_ARRAY[@]}" "${TOOL_PREFLIGHT}"; do
    check_file "${PREFLIGHT_DIR}/${file}" || fail "  Please ensure that preflight script exists: ${file}"
    check_file_data "${PREFLIGHT_DIR}/${file}" || fail "  Please ensure that preflight script contains data: ${file}"
    source "${PREFLIGHT_DIR}/${file}"
done

echo
echo "  ${SCRIPT_NAME} COMPLETE"