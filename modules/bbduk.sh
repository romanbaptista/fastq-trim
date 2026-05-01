#!/bin/bash
#SBATCH --job-name=bbduk
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null


# Exit on error
set -euo pipefail

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### DIRECTORIES ####################

# Navigate to pipeline root path
cd "${PIPELINE_DIR}"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/trimmed"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS #########################

# Check if INPUT_DIR exists
if [[ -z "${INPUT_DIR}" || ! -d "${INPUT_DIR}" ]]; then
    echo "ERROR: INPUT_DIR is not set or does not exist: ${INPUT_DIR}"
    exit 1
fi

# Source helper functions
source  "${PIPELINE_DIR}/helper_functions.sh"
ensure_bbtools

######################### VARIABLES ######################

BBDUK_PATH="${PIPELINE_DIR}/bbtools/bbduk.sh"
BBDUK_ADAPTERS="${PIPELINE_DIR}/bbtools/resources/adapters.fa"

NUM_THREADS="${SLURM_CPUS_PER_TASK}"

######################### SCRIPT #########################

# Iterate over folders in INPUT_DIR
find "${INPUT_DIR}" -mindepth 1 -maxdepth 1 -type d | while read -r SAMPLE_DIR; do
    
    (
    
        # Get sample ID
        SAMPLE_ID="$(basename "${SAMPLE_DIR}")"

        # Get paired files
        R1="$(ls "${SAMPLE_DIR}"/*_1.fastq.gz)"
        R2="$(ls "${SAMPLE_DIR}"/*_2.fastq.gz)"

        # Check both files exist
        if [[ ! -f "${R1}" || ! -f "${R2}" ]]; then
            echo "  ERROR: Missing FASTQ pair for ${SAMPLE_ID}"
            exit 1
        fi

        # Check for single pair of files
        [[ ${#R1[@]} -ne 1 || ${#R2[@]} -ne 1 ]] && {
        echo "ERROR: Expected exactly one FASTQ pair for ${SAMPLE_ID}"
        exit 1
        }

        # Define sample output directory
        SAMPLE_OUT_DIR="${OUTPUT_DIR}/${SAMPLE_ID}"
        # Create directory
        mkdir -p "${SAMPLE_OUT_DIR}"
        
        # Define log file path
        LOGFILE="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_trim.log"
        # Redirect .out/.err logs to LOGFILE
        exec >"${LOGFILE}" 2>&1

        echo "RUNNING bbduk.sh..."
        echo
        echo "  Input directory:      ${INPUT_DIR}"
        echo "  Output directory:     ${OUTPUT_DIR}"
        echo "  CPUs allocated:       ${SLURM_CPUS_PER_TASK}"
        echo "  Memory per CPU:       ${SLURM_MEM_PER_CPU}"
        echo

        echo "  TRIMMING ${SAMPLE_ID}"
        echo "  R1: ${R1}"
        echo "  R2: ${R2}"
        echo "  Output directory: ${SAMPLE_OUT_DIR}"
        echo

        # Run BBDUK
        $BBDUK_PATH \
            in1="${R1}" \
            in2="${R2}" \
            out1="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_1.trim.fastq.gz" \
            out2="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_2.trim.fastq.gz" \
            ref="${BBDUK_ADAPTERS}" \
            k=23 \
            hdist=1 \
            qtrim=rl \
            trimq="${BBDUK_TRIMQ}" \
            minlen="${BBDUK_MINLEN}" \
            threads="${NUM_THREADS}"

        echo "bbduk.sh COMPLETE"

    )

done