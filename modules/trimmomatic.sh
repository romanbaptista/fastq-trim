#!/bin/bash
#SBATCH --job-name=trimmomatic
#SBATCH --ntasks=1
set -euo pipefail

######################### PATHS ###########################

# Define script output directory
SCRIPT_DIR="${PIPELINE_DIR}/output/trim"
# Create output directory
mkdir -p "${SCRIPT_DIR}"

# Define trimmomatic.jar path
TRIM_JAR="${PIPELINE_DIR}/trimmomatic/trimmomatic.jar"
# Define adapter path
TRIM_ADAPTER="${PIPELINE_DIR}/trimmomatic/adapters/TruSeq3-PE.fa"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh
# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source base functions
source "${UTILS_DIR}/functions_base.sh"

######################### MODULES ########################

# Load java module
module load apps/java-8u151.tcl

######################### MAIN ############################

echo "RUNNING trimmomatic.sh ..."
echo
echo "  Input directory:                        ${INPUT_DIR}"
echo "  Output directory:                       ${SCRIPT_DIR}"
echo "  CPUs allocated:                         ${SLURM_CPUS_PER_TASK}"
echo "  Memory per CPU:                         ${SLURM_MEM_PER_CPU}"
echo "  Allowed seed mismatches:                ${TRIM_MISMATCH}"
echo "  Palindrome clip threshold:              ${TRIM_LEADING}"
echo "  Simple clip threshold:                  ${TRIM_TRAILING}"
echo "  Window scan size:                       ${TRIM_WINDOW}"
echo "  Minimum adapter length for clipping:    ${TRIM_CLIP}"
echo "  Post-clipping discard threshold:        ${TRIM_DISCARD}"

# Iterate over folders in INPUT_DIR
find "${INPUT_DIR}" -mindepth 1 -maxdepth 1 -type d | while read -r SAMPLE_DIR; do
    
    (

        # Get sample ID
        SAMPLE_ID="$(basename "${SAMPLE_DIR}")"
        
        # Get FASTQ pairs
        shopt -s nullglob
        R1_FILES=("${SAMPLE_DIR}"/*_1.fastq.gz)
        R2_FILES=("${SAMPLE_DIR}"/*_2.fastq.gz)
        shopt -u nullglob

        # Require exactly one FASTQ pair
        if [[ ${#R1_FILES[@]} -ne 1 || ${#R2_FILES[@]} -ne 1 ]]; then
            fail "Expected exactly one FASTQ pair for ${SAMPLE_ID}"
        fi

        # Define paired files
        R1="${R1_FILES[0]}"
        R2="${R2_FILES[0]}"

        # Define sample output directory
        SAMPLE_OUT_DIR="${SCRIPT_DIR}/${SAMPLE_ID}"
        # Create directory
        mkdir -p "${SAMPLE_OUT_DIR}"

        # Define log file path
        LOGFILE="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_trim.log"
        # Redirect .out/.err logs to LOGFILE
        exec >"${LOGFILE}" 2>&1

        echo "TRIMMING                                ${SAMPLE_ID}"
        echo "R1:                                     ${R1}"
        echo "R2:                                     ${R2}"
        echo "Sample output directory:                ${SAMPLE_OUT_DIR}"

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

        echo "Trimming COMPLETE"

    )

done

echo
echo "trimmomatic.sh COMPLETE"
echo