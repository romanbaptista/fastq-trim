#!/bin/bash

# check_trimmomatic
check_trimmomatic() {
    local dir="${1-}"

    # VALIDATION
    arg_check_nonempty "${dir}" || return $?

    # FUNCTION
    # Define variables
    local trimmomatic_exists=true
    local CHECK_DIR="${dir}/trimmomatic"
    local CHECK_JAR="${dir}/trimmomatic/trimmomatic.jar"

    # Run checks
    directory_check_exists "${CHECK_DIR}" || {
        echo "  WARNING: Missing directory: ${CHECK_DIR}"
        trimmomatic_exists=false
    }

    file_check_exists "${CHECK_JAR}" || {
        echo "  WARNING: trimmomatic script not found: ${CHECK_JAR}"
        trimmomatic_exists=false
    }

    file_check_nonempty "${CHECK_JAR}" || {
        echo "  WARNING: trimmomatic script is empty: ${CHECK_JAR}"
        trimmomatic_exists=false
    }

    # Check trimmomatic_exists
    if [[ "${trimmomatic_exists}" == true ]]; then
        return 0
    else
        return 1
    fi
}

# download_trimmomatic
download_trimmomatic() {
    local dir="${1-}"
    local url="${2-}"
    
    # VALIDATION
    local arg_array=(
        "${dir}"
        "${url}"
    )

    for arg in "${arg_array[@]}"; do
        arg_check_nonempty "${arg}" || return $?
    done

    # FUNCTION
    # Navigate to directory
    cd "${dir}" || fail_message "Failed to navigate to specified directory: ${dir}"
    # Download tarball
    wget -q "${url}" || return 1
}

# extract_trimmomatic
extract_trimmomatic() {
    local dir="${1-}"
    local tarball="${2-}"

    # VALIDATION
    local arg_array=(
        "${dir}"
        "${tarball}"
    )

    for arg in "${arg_array[@]}"; do
        arg_check_nonempty "${arg}" || return $?
    done

    # FUNCTION
    # Navigate to directory
    cd "${dir}" || fail_message "Failed to navigate to specified directory: ${dir}"
    # Extract tarball
    tar -xzf "${tarball}"
    # Remove tarball
    rm -f "${tarball}"
    
    # Remove existing 'trimmomatic' directory if it exists
    rm -rf "trimmomatic"

    # Rename package folder
    for d in Trimmomatic-*; do
        [[ -d "$d" ]] && {
            mv "$d" "trimmomatic"
            break
        }
    done
}