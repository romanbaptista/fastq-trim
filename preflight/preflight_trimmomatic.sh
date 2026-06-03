#!/bin/bash

######################### GUARDS #########################

GUARD_ARRAY=(
    UTILS_DIR
    FUNCTIONS_DIR
    ROOT_DIR
)

for var in "${GUARD_ARRAY[@]}"; do
    variable_check_nonempty "${var}" || fail_message "Variable is empty or not defined: ${var}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
# Define toolname
TOOLNAME="trimmomatic"

######################### SOURCE #########################

source "${UTILS_DIR}/utils_${TOOLNAME}.sh"
source "${FUNCTIONS_DIR}/functions_${TOOLNAME}.sh"

######################### CHECKS #########################

CHECK_ARRAY=(
    TRIMMOMATIC_URL
    TRIMMOMATIC_TARBALL
    TRIMMOMATIC_CPUS
    TRIMMOMATIC_MEM_PER_CPU
    TRIMMOMATIC_MISMATCH
    TRIMMOMATIC_LEADING
    TRIMMOMATIC_TRAILING
    TRIMMOMATIC_WINDOW
    TRIMMOMATIC_CLIP
    TRIMMOMATIC_DISCARD
)

for var in "${CHECK_ARRAY[@]}"; do
    variable_check_nonempty "${var}" || fail_message "Variable is empty or not set: ${var}"
done

# Check java
tool_check_binary "java" || fail_message "Java not found"
tool_check_runtime "java" || fail_message "Java runtime not functional"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME}..."

# Check for trimmomatic
if ! check_trimmomatic "${ROOT_DIR}"; then
    echo "  Downloading ${TOOLNAME}..."
    download_trimmomatic "${ROOT_DIR}" "${TRIMMOMATIC_URL}" || fail_message "Failed to download ${TOOLNAME}"
    echo "  ${TOOLNAME} downloaded"
    echo "  Extracting ${TOOLNAME}..."
    extract_trimmomatic "${ROOT_DIR}" "${TRIMMOMATIC_TARBALL}" || fail_message "Failed to extract ${TOOLNAME}"
    echo "  ${TOOLNAME} extracted"
    echo "  Validating ${TOOLNAME} installation..."
    check_trimmomatic "${ROOT_DIR}" || fail_message "Failed to install ${TOOLNAME}"
fi

echo "  ${TOOLNAME} validated"
echo "${SCRIPT_NAME} COMPLETE"