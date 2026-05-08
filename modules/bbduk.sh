#!/bin/bash
#SBATCH --job-name=bbduk
set -euo pipefail

######################### PATHS ###########################

# Define script output directory
TRIM_DIR="${PIPELINE_DIR}/output/trim"
# Create output directory
mkdir -p "${TRIM_DIR}"

# Define path to bbtools executable
BBDUK_PATH="${PIPELINE_DIR}/bbtools/bbduk.sh"
# Define path to bbtools adapters
BBDUK_ADAPTERS="${PIPELINE_DIR}/bbtools/resources/adapters.fa"

######################### SOURCE ##########################

# Enable module commands for batch jobs
source /etc/profile.d/modules.sh
# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source base functions
source "${UTILS_DIR}/functions_base.sh"

######################### MAIN ############################

echo "RUNNING bbduk.sh ..."
echo
echo "  Input directory:             ${INPUT_DIR}"
echo "  Output directory:            ${TRIM_DIR}"
echo "  CPUs allocated:              ${SLURM_CPUS_PER_TASK}"
echo "  Memory per CPU:              ${SLURM_MEM_PER_CPU}"


# Iterate over sample directories in INPUT_DIR
for SAMPLE_DIR in "${INPUT_DIR}"/*/; do
    
    # Skip if no directories match
    [[ -d "${SAMPLE_DIR}" ]] || continue

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
        SAMPLE_OUT_DIR="${TRIM_DIR}/${SAMPLE_ID}"
        # Create directory
        mkdir -p "${SAMPLE_OUT_DIR}"
        
        # Define log file path
        LOGFILE="${SAMPLE_OUT_DIR}/${SAMPLE_ID}_trim.log"
        # Redirect .out/.err logs to LOGFILE
        exec >"${LOGFILE}" 2>&1

        echo "  TRIMMING:                    ${SAMPLE_ID}"
        echo "  R1:                          ${R1}"
        echo "  R2:                          ${R2}"
        echo "  Sample output directory:     ${SAMPLE_OUT_DIR}"
        echo

        # Run BBDUK
        ${BBDUK_PATH} \
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
            threads="${SLURM_CPUS_PER_TASK}"

        echo "Trimming COMPLETE"

    )

done

echo
echo "bbduk.sh COMPLETE"
echo