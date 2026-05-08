#!/bin/bash
set -euo pipefail

# Define script name
CURRENT_SCRIPT="$(basename "${BASH_SOURCE[0]}")"

# Define config variables
VARIABLE_ARRAY=(
    PACKAGE_TO_USE
)

echo "  RUNNING ${CURRENT_SCRIPT} ..."
echo "  Checking for core user-defined variables..."

# Iterate over variables
for variable in "${VARIABLE_ARRAY[@]}"; do
    check_variable "${variable}" || fail "  Set variable in config.sh: ${variable}"
done

# Check PACKAGE_TO_USE value
if [[ "${PACKAGE_TO_USE}" != "bbduk" && "${PACKAGE_TO_USE}" != "trimmomatic" ]]; then
    fail "  ERROR: Invalid PACKAGE_TO_USE: ${PACKAGE_TO_USE}; Valid options are: 'bbduk' | 'trimmomatic'"
fi

echo "  All core user-defined variables confirmed"
echo "  ${CURRENT_SCRIPT} COMPLETE"