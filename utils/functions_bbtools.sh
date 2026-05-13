#!/bin/bash


# check_bbtools
# Verifies that a valid BBTools installation exists within a given directory.
#
# Arguments:
#   $1 - Pipeline root directory
#
# Operation:
#   - Validates that the BBTools directory exists.
#   - Confirms presence and integrity of the bbduk.sh executable.
#   - Ensures the adapter FASTA file exists and contains data.
#
# Returns:
#   0 if BBTools installation is complete and usable
#   1 if installation is missing or incomplete
#   2 if required argument is not provided
#
# Design note:
#   This function is intended for use in the preflight layer only.
#   Execution modules assume this invariant has already been validated.
check_bbtools() {
    local dir="$1"
    local CHECK_DIR="${dir}/bbtools"
    local CHECK_BBDUK="${dir}/bbtools/bbduk.sh"
    local CHECK_ADAPTER="${dir}/bbtools/resources/adapters.fa"

    check_arg "${dir}" || return $?

    check_directory "${CHECK_DIR}" &&
    check_file "${CHECK_BBDUK}" &&
    check_file_data "${CHECK_BBDUK}" &&
    check_executable "${CHECK_BBDUK}" &&
    check_file "${CHECK_ADAPTER}" &&
    check_file_data "${CHECK_ADAPTER}"
}

# download_bbtools
# Downloads a pinned BBTools (BBMap) release into the specified directory.
#
# Arguments:
#   $1 - Target directory for download
#
# Operation:
#   - Navigates to the target directory.
#   - Downloads the BBTools tarball using wget.
#
# Returns:
#   0 on successful download
#   1 if the download fails
#   2 if required argument is not provided
download_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Downloading bbtools... "

    # Navigate to given directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Download tarball
    wget -q https://sourceforge.net/projects/bbmap/files/BBMap_39.01.tar.gz

    echo "  bbtools downloaded"
}

# extract_bbtools
# Extracts a previously downloaded BBTools archive.
#
# Arguments:
#   $1 - Directory containing the downloaded archive
#
# Operation:
#   - Extracts the tarball.
#   - Removes the archive after extraction.
#   - Normalises directory structure to 'bbtools/'.
#
# Returns:
#   0 on successful extraction
#   1 if extraction fails
#   2 if required argument is not provided
extract_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Extracting bbtools in ${dir}..."
    
    # Navigate to directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Extract package
    tar -xzf BBMap_39.01.tar.gz
    # Remove tarball
    rm -f BBMap_39.01.tar.gz

    # Rename directory to 'bbtools' if name contains 'BBMap_'
    for d in BBMap_*; do
        [[ -d "$d" ]] && mv "$d" bbtools && break
    done

    echo "  bbtools extracted"
}

# install_bbtools
# Ensures a valid BBTools installation is present.
#
# Arguments:
#   $1 - Pipeline root directory
#
# Operation:
#   - Downloads BBTools if missing.
#   - Extracts and normalises installation.
#   - Verifies installation integrity using check_bbtools.
#
# Returns:
#   0 if installation succeeds or already exists
#   1 if installation or verification fails
#   2 if required argument is not provided
#
# Design note:
#   Intended for preflight execution only.
#   This function defines tool availability invariants for downstream modules.
install_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?

    echo "  Installing bbtools..."
    download_bbtools "${dir}" || fail "  Unable to download bbtools using 'wget'"
    extract_bbtools "${dir}" || fail "  Unable to extract bbtools using 'tar'"
    echo "  Confirming installation..."
    check_bbtools "${dir}" || fail "  bbtools install may have failed"

    return 0
}