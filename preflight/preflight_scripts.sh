#!/bin/bash
set -euo pipefail

# Define modules directory
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define script name
CURRENT_SCRIPT="$(basename "${BASH_SOURCE[0]}")"

# Define module script array
SCRIPT_ARRAY=(
    'bbduk.sh'
    'trimmomatic.sh'
)

echo "  RUNNING ${CURRENT_SCRIPT} ..."
echo "  Checking module scripts..."

# Iterate through scripts
for script in "${SCRIPT_ARRAY[@]}"; do
    check_file "${MODULES_DIR}/${script}" || fail "    Please ensure file exists: ${script}"
    check_file_data "${MODULES_DIR}/${script}" || fail "   Please ensure file contains data: ${script}"
done

# Check for pipeline.sh
check_file "${MODULES_DIR}/pipeline.sh" || fail "   Please ensure pipeline.sh exists"
check_file_data "${MODULES_DIR}/pipeline.sh" || fail "   Please ensure pipeline.sh contains data"

echo "  Module scripts confirmed"
echo "  ${CURRENT_SCRIPT} COMPLETE"