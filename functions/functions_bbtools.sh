#!/bin/bash

# check_bbtools
check_bbtools() {
    local dir="${1-}"

    # VALIDATION
    arg_check_nonempty "${dir}" || return $?

    # FUNCTION
    # Define variables
    local bbtools_exists=true
    local CHECK_DIR="${dir}/bbtools"
    local CHECK_SCRIPT="${dir}/bbtools/bbduk.sh"
    local CHECK_ADAPTERS="${dir}/bbtools/resources/adapters.fa"

    # Run checks
    directory_check_exists "${CHECK_DIR}" || {
        echo "  WARNING: Missing directory: ${CHECK_DIR}"
        bbtools_exists=false
    }

    file_check_exists "${CHECK_SCRIPT}" || {
        echo "  WARNING: bbduk script not found: ${CHECK_SCRIPT}"
        bbtools_exists=false
    }

    file_check_nonempty "${CHECK_SCRIPT}" || {
        echo "  WARNING: bbduk script is empty: ${CHECK_SCRIPT}"
        bbtools_exists=false
    }

    file_check_executable "${CHECK_SCRIPT}" || {
        echo "  WARNING: bbduk script is not executable: ${CHECK_SCRIPT}"
        bbtools_exists=false
    }

    file_check_exists "${CHECK_ADAPTERS}" || {
        echo "  WARNING: Adapter file not found: ${CHECK_ADAPTERS}"
        bbtools_exists=false
    }
    
    file_check_nonempty "${CHECK_ADAPTERS}" || {
        echo "  WARNING: Adapter file is empty: ${CHECK_ADAPTERS}"
        bbtools_exists=false
    }

    # Check bbtools_exists
    if [[ "${bbtools_exists}" == true ]]; then
        return 0
    else
        return 1
    fi
}

# download_bbtools
download_bbtools() {
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


# extract_bbtools
extract_bbtools() {
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

    # Remove existing 'bbtools' directory if present
    rm -rf "bbtools"

    # Rename new directory to 'bbtools' if name contains 'BBMap_'
    for d in BBMap_*; do
        [[ -d "$d" ]] && {
            mv "$d" "bbtools"
            break
        }
    done
}