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
TOOLNAME="bbtools"

######################### SOURCE #########################

source "${UTILS_DIR}/utils_${TOOLNAME}.sh"
source "${FUNCTIONS_DIR}/functions_${TOOLNAME}.sh"

######################### CHECKS #########################

CHECK_ARRAY=(
    BBTOOLS_URL
    BBTOOLS_TARBALL
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
)

for var in "${CHECK_ARRAY[@]}"; do
    variable_check_nonempty "${var}" || fail_message "Variable is empty or not set: ${var}"
done

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME}..."

# Check for BBTools
if ! check_bbtools "${ROOT_DIR}"; then
    echo "  Downloading ${TOOLNAME}..."
    download_bbtools "${ROOT_DIR}" "${BBTOOLS_URL}" || fail_message "Failed to download ${TOOLNAME}"
    echo "  ${TOOLNAME} downloaded"
    echo "  Extracting ${TOOLNAME}..."
    extract_bbtools "${ROOT_DIR}" "${BBTOOLS_TARBALL}" || fail_message "Failed to extract ${TOOLNAME}"
    echo "  ${TOOLNAME} extracted"
    echo "  Validating ${TOOLNAME} installation..."
    check_bbtools "${ROOT_DIR}" || fail_message "Failed to install ${TOOLNAME}"
fi

echo "  ${TOOLNAME} validated"
echo "${SCRIPT_NAME} COMPLETE"