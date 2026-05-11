#!/bin/bash
set -euo pipefail

# Define script name
CURRENT_SCRIPT="$(basename "${BASH_SOURCE[0]}")"

# Source trimmomatic functions
source "${UTILS_DIR}/functions_trimmomatic.sh"

# Define config variables
VARIABLE_ARRAY=(
    TRIM_CPUS
    TRIM_MEM_PER_CPU
    TRIM_MISMATCH
    TRIM_LEADING
    TRIM_TRAILING
    TRIM_WINDOW
    TRIM_CLIP
    TRIM_DISCARD
)

echo "  RUNNING ${CURRENT_SCRIPT} ..."
echo "  Checking for trimmomatic-specific user-defined variables..."

# Iterate over variables
for variable in "${VARIABLE_ARRAY[@]}"; do
    check_variable "${variable}" || fail "  Set variable in config.sh: ${variable}"
done

echo "  All trimmomatic variables confirmed"
echo "  Checking for trimmomatic install..."

ensure_trimmomatic "${PIPELINE_DIR}"

echo "  ${CURRENT_SCRIPT} COMPLETE"