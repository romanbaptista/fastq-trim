#!/bin/bash

# check_trimmomatic
# Verifies that a valid Trimmomatic installation exists within a given directory.
#
# Arguments:
#   $1 - Pipeline root directory
#
# Operation:
#   - Validates the presence of the Trimmomatic directory.
#   - Confirms the Trimmomatic JAR file exists and contains data.
#   - Verifies that a Java runtime is available.
#
# Returns:
#   0 if Trimmomatic installation is complete and runnable
#   1 if installation is missing or incomplete
#   2 if required argument is not provided
check_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    check_directory "${dir}/trimmomatic" &&
    check_file "${dir}/trimmomatic/trimmomatic.jar" &&
    check_file_data "${dir}/trimmomatic/trimmomatic.jar" &&
    check_command java
}

# download_trimmomatic
# Downloads a pinned Trimmomatic release into the specified directory.
#
# Arguments:
#   $1 - Target directory for download
#
# Operation:
#   - Navigates to the target directory.
#   - Downloads the release archive from GitHub using wget.
#
# Returns:
#   0 on successful download
#   1 if the download fails
#   2 if required argument is not provided
download_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Downloading trimmomatic to ${dir}..."

    # Navigate to given directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Download tarball
    wget -q https://github.com/usadellab/Trimmomatic/archive/refs/tags/v0.39.tar.gz

    echo "  trimmomatic downloaded"
}

# extract_trimmomatic
# Extracts the downloaded Trimmomatic archive and normalises installation.
#
# Arguments:
#   $1 - Directory containing the downloaded archive
#
# Operation:
#   - Extracts the archive.
#   - Removes the archive after extraction.
#   - Renames the extracted directory to 'trimmomatic/'.
#
# Returns:
#   0 on successful extraction
#   1 if extraction fails
#   2 if required argument is not provided
extract_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Extracting trimmomatic in ${dir}..."

    # Navigate to directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Extract package
    tar -xzf v0.39.tar.gz
    # Remove tarball
    rm -f v0.39.tar.gz
    # Rename package folder
    mv Trimmomatic-0.39 trimmomatic

    echo "  trimmomatic extracted"
}

# install_trimmomatic
# Ensures a valid Trimmomatic installation is present.
#
# Arguments:
#   $1 - Pipeline root directory
#
# Operation:
#   - Downloads Trimmomatic if missing.
#   - Extracts and normalises installation.
#   - Verifies installation integrity using check_trimmomatic.
#
# Returns:
#   0 if installation succeeds or already exists
#   1 if installation or verification fails
#   2 if required argument is not provided
#
# Design note:
#   Intended for preflight execution only.
#   Defines tool availability required for downstream modules.
install_trimmomatic() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Installing trimmomatic to ${dir}..."
    download_trimmomatic "${dir}" || fail "  Unable to download trimmomatic using 'wget'"
    extract_trimmomatic "${dir}" || fail "  Unable to extract trimmomatic using 'tar'"
    echo "  Confirming installation..."
    check_trimmomatic "${dir}" || fail "  trimmomatic install may have failed"

    return 0
}