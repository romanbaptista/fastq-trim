#!/bin/bash
set -euo pipefail

# Define script name
CURRENT_SCRIPT="$(basename "${BASH_SOURCE[0]}")"

# Define config variables
VARIABLE_ARRAY=(
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
)

echo "  RUNNING ${CURRENT_SCRIPT} ..."
echo "  Checking for bbduk-specific user-defined variables..."

# Iterate over variables
for variable in "${VARIABLE_ARRAY[@]}"; do
    check_variable "${variable}" || fail "  Set variable in config.sh: ${variable}"
done

echo "  All bbduk variables confirmed"
echo "  Checking for bbtools install..."

ensure_bbtools "${PIPELINE_DIR}"

echo "  Checking for bbtools executable..."
check_file "${PIPELINE_DIR}/bbtools/bbduk.sh"
check_file_data "${PIPELINE_DIR}/bbtools/resources/adapters.fa"
check_executable "${PIPELINE_DIR}/bbtools/bbduk.sh"

echo "  Checking for bbtools adapter file..."
check_file "${PIPELINE_DIR}/bbtools/resources/adapters.fa"
check_file_data "${PIPELINE_DIR}/bbtools/resources/adapters.fa"

echo "  ${CURRENT_SCRIPT} COMPLETE"