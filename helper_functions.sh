#!/bin/bash

# Exit on error
set -euo pipefail

######################### CHECKS #########################

if [[ -z "${PIPELINE_DIR:-}" ]]; then
    echo "ERROR: PIPELINE_DIR is not set. This script must be sourced from a pipeline context."
    exit 1
fi

######################### FUNCTIONS ######################

# Define bbtools download function
ensure_bbtools() {
    if [[ ! -d "${PIPELINE_DIR}/bbtools" ]] || \
       [[ ! -x "${PIPELINE_DIR}/bbtools/bbduk.sh"  ]]; then
        
        echo "BBTools not found or incomplete. Downloading now..."
        cd "${PIPELINE_DIR}"

        # Download tarball
        wget -q https://sourceforge.net/projects/bbmap/files/BBMap_39.01.tar.gz
        # Extract package
        tar -xzf BBMap_39.01.tar.gz
        # Remove tarball
        rm -f BBMap_39.01.tar.gz

        # Rename directory if name contains 'BBMap_'
        if [[ -d BBMap_* ]]; then
            mv BBMap_* bbtools
        fi

        # Check whether executable is present
        if [[ ! -x "${PIPELINE_DIR}/bbtools/bbduk.sh" ]]; then
            echo "ERROR: bbduk executable not found after BBTools installation"
            exit 1
        fi

    fi
}

# Define trimmomatic download function
ensure_trimmomatic() {
    if [[ ! -d "${PIPELINE_DIR}/trimmomatic" ]] || \
       [[ ! -x "${PIPELINE_DIR}/trimmomatic/trimmomatic.jar"  ]]; then

        echo "Trimmomatic not found or incomplete. Downloading now..."
        cd "${PIPELINE_DIR}"

        # Download tarball
        wget -q https://github.com/usadellab/Trimmomatic/archive/refs/tags/v0.39.tar.gz
        # Extract package
        tar -xzf v0.39.tar.gz
        # Remove tarball
        rm -f v0.39.tar.gz
        # Rename package folder
        mv Trimmomatic-0.39 trimmomatic

        # Check whether executable is present
        if [[ ! -x "${PIPELINE_DIR}/trimmomatic/trimmomatic.jar" ]]; then
            echo "ERROR: Trimmomatic executable not found after installation"
            exit 1
        fi

    fi
}