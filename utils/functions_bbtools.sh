#!/bin/bash

# check_bbtools
# Verifies that BBTools is installed and usable in a given directory.
# Arguments:
#   $1 - Directory to check
# Operation:
#   Checks for bbtools directory and bbduk.sh executable.
# Returns:
#   0 if BBTools installation is valid
#   1 if BBTools is missing or incomplete
#   2 if function called without required argument
# Example:
# check_bbtools "$PIPELINE_DIR"
check_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?
    
    check_directory "${dir}/bbtools" &&
    check_executable "${dir}/bbtools/bbduk.sh"
}

# download_bbtools
# Downloads and installs BBTools into a given directory.
# Arguments:
#   $1 - Directory in which to install
# Operation:
#   Downloads BBMap tarball, extracts it, renames folder to 'bbtools'.
# Returns:
#   0 on successful download and extraction
#   1 on download/extraction failure
#   2 if function called without required argument
# Example:
# download_bbtools "$PIPELINE_DIR"
download_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?

    # Navigate to given directory
    cd "${dir}" || fail "  Unable to navigate to directory: ${dir}"
    # Download tarball
    wget -q https://sourceforge.net/projects/bbmap/files/BBMap_39.01.tar.gz
    # Extract package
    tar -xzf BBMap_39.01.tar.gz
    # Remove tarball
    rm -f BBMap_39.01.tar.gz

    # Rename directory to 'bbtools' if name contains 'BBMap_'
    for d in BBMap_*; do
        [[ -d "$d" ]] && mv "$d" bbtools && break
    done
}

# ensure_bbtools
# Ensures BBTools is installed, downloading it if necessary.
# Arguments:
#   $1 - Directory to check
# Operation:
#   Calls check_bbtools; if missing, runs download_bbtools.
# Returns:
#   0 if BBTools is present or successfully installed
#   1 if installation fails
#   2 if function called without required argument
# Example:
# ensure_bbtools "$PIPELINE_DIR"
ensure_bbtools() {
    local dir="$1"

    check_arg "${dir}" || return $?

    if check_bbtools "${dir}"; then
        echo "  BBTools found"
    else
        echo "  BBTools not found or incomplete; downloading and extracting..."
        download_bbtools "${dir}"
        echo "  Download and extraction complete"
    fi    
}