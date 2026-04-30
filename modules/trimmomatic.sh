#!/bin/bash
#SBATCH --job-name=trimmomatic
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=8G

# Exit on error
set -euo pipefail

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/trimmomatic"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### MODULES ########################

# Load java module
module load apps/java-8u151.tcl

######################### CHECKS #########################

# Check if INPUT_DIR exists
if [[ -z "${INPUT_DIR}" || ! -d "${INPUT_DIR}" ]]; then
    echo "ERROR: INPUT_DIR is not set or does not exist: ${INPUT_DIR}"
    exit 1
fi

# Source helper functions
source  "${PIPELINE_DIR}/helper_functions.sh"
ensure_trimmomatic

######################### VARIABLES ######################

# Define trimmomatic.jar path
TRIM_JAR="${PIPELINE_DIR}/trimmomatic/trimmomatic.jar"
# Define adapter path
TRIM_ADAPTER="${PIPELINE_DIR}/trimmomatic/adapters/TruSeq3-PE.fa"

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

        # Define sample output directory
        SAMPLE_OUT_DIR="${OUTPUT_DIR}/${SAMPLE_ID}"
        # Create directory
        mkdir -p "${SAMPLE_OUT_DIR}"

        # Define log file path
        LOGFILE="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_trim.log"
        # Redirect .out/.err logs to LOGFILE
        exec >"${LOGFILE}" 2>&1

        echo "RUNNING trimmomatic.sh..."
        echo
        echo "  Input directory:                        ${INPUT_DIR}"
        echo "  Output directory:                       ${OUTPUT_DIR}"
        echo "  CPUs allocated:                         ${SLURM_CPUS_PER_TASK}"
        echo "  Memory per CPU:                         ${SLURM_MEM_PER_CPU}"
        echo "  Allowed seed mismatches:                ${TRIM_MISMATCH}"
        echo "  Palindrome clip threshold:              ${TRIM_LEADING}"
        echo "  Simple clip threshold:                  ${TRIM_TRAILING}"
        echo "  Window scan size:                       ${TRIM_WINDOW}"
        echo "  Minimum adapter length for clipping:    ${TRIM_CLIP}"
        echo "  Post-clipping discard threshold:        ${TRIM_DISCARD}"
        echo

        echo "  TRIMMING ${SAMPLE_ID}"
        echo "  R1: ${R1}"
        echo "  R2: ${R2}"
        echo "  Output directory: ${SAMPLE_OUT_DIR}"

        # Run trimmomatic
        java -jar "${TRIM_JAR}" \
            PE \
                "${R1}" "${R2}" \
                -baseout "${SAMPLE_OUT_DIR}/${SAMPLE_ID}.trim.fastq.gz" \
            ILLUMINACLIP:"${TRIM_ADAPTER}":"${TRIM_MISMATCH}":"${TRIM_LEADING}":"${TRIM_TRAILING}":"${TRIM_CLIP}":True \
            LEADING:"${TRIM_LEADING}" \
            TRAILING:"${TRIM_TRAILING}" \
            SLIDINGWINDOW:"${TRIM_WINDOW}":${TRIM_CLIP} \
            MINLEN:"${TRIM_DISCARD}"

        echo "trimmomatic.sh COMPLETE"

    )

done







