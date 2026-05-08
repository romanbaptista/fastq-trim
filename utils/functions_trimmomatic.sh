#!/bin/bash

# check_trimmomatic
# Verifies that Trimmomatic is installed and runnable.
# Arguments:
#   $1 - Directory to check
# Operation:
#   Checks for trimmomatic directory, trimmomatic.jar, and java command.
# Returns:
#   0 if Trimmomatic installation is valid
#   1 if missing or incomplete
#   2 if function called without required argument
# Example:
# check_trimmomatic "$PIPELINE_DIR"
check_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    check_directory "${dir}/trimmomatic" &&
    check_file "${dir}/trimmomatic/trimmomatic.jar" &&
    check_command java
}

# download_trimmomatic
# Downloads and installs Trimmomatic into a given directory.
# Arguments:
#   $1 - Directory in which to install
# Operation:
#   Downloads v0.39 tarball from GitHub, extracts it, renames folder to 'trimmomatic'.
# Returns:
#   0 on successful installation
#   1 on download or extraction failure
#   2 if function called without required argument
# Example:
# download_trimmomatic "$PIPELINE_DIR"
download_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    # Navigate to given directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Download tarball
    wget -q https://github.com/usadellab/Trimmomatic/archive/refs/tags/v0.39.tar.gz
    # Extract package
    tar -xzf v0.39.tar.gz
    # Remove tarball
    rm -f v0.39.tar.gz
    # Rename package folder
    mv Trimmomatic-0.39 trimmomatic
}

# ensure_trimmomatic
# Ensures Trimmomatic is installed, downloading it if necessary.
# Arguments:
#   $1 - Directory to check
# Operation:
#   Calls check_trimmomatic; if missing, installs it.
# Returns:
#   0 if present or successfully installed
#   1 if installation fails
#   2 if function called without required argument
# Example:
# ensure_trimmomatic "$PIPELINE_DIR"
ensure_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    if check_trimmomatic "${dir}"; then
        echo "  Trimmomatic found"
    else
        echo "  Trimmomatic not found or incomplete; downloading and extracting..."
        download_trimmomatic "${dir}"
        echo "  Download and extraction complete"
    fi
}