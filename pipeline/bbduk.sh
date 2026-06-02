#!/bin/bash
set -euo pipefail

######################### GUARDS #########################

GUARD_ARRAY=(
    FUNCTIONS_DIR
    INPUT_DIR
    ROOT_DIR
    PACKAGE_OUTDIR
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
    SLURM_CPUS_PER_TASK
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or empty}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE #########################

source "${FUNCTIONS_DIR}/functions_base.sh"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo
echo "  Info:"
echo "    CPUs allocated:                   ${BBDUK_CPUS}"
echo "    Memory per CPU:                   ${BBDUK_MEM_PER_CPU}"
echo "    Quality trimming threshold:       ${BBDUK_TRIMQ}"
echo "    Minimum read length:              ${BBDUK_MINLEN}"

# Define tool paths (guaranteed by preflight)
BBDUK_SCRIPT="${ROOT_DIR}/bbtools/bbduk.sh"
BBDUK_ADAPTERS="${ROOT_DIR}/bbtools/resources/adapters.fa"

# Iterate over sample directories in INPUT_DIR
for SAMPLE_DIR in "${INPUT_DIR}"/*/; do

    # Skip if no directories match
    directory_check_exists "${SAMPLE_DIR}" || continue

    (

        # Get sample ID
        SAMPLE_ID="$(basename "${SAMPLE_DIR}")"

        # Get FASTQ pair
        shopt -s nullglob
        R1_FILES=("${SAMPLE_DIR}"/*_1.fastq.gz)
        R2_FILES=("${SAMPLE_DIR}"/*_2.fastq.gz)
        shopt -u nullglob

        # Enforce one pair
        [[ ${#R1_FILES[@]} -eq 1 && ${#R2_FILES[@]} -eq 1 ]] || fail_message "Expected exactly one FASTQ pair for sample: ${SAMPLE_ID}"

        # Define paired files
        R1="${R1_FILES[0]}"
        R2="${R2_FILES[0]}"  

        # Create sample output directory
        SAMPLE_OUTDIR="${PACKAGE_OUTDIR}/${SAMPLE_ID}"
        directory_create "${SAMPLE_OUTDIR}" || fail_message "Failed to create directory: ${SAMPLE_OUTDIR}"

        # Create LOGFILE and redirect sample logs
        LOGFILE="${SAMPLE_OUTDIR}/${SAMPLE_ID}.log"
        exec >"${LOGFILE}" 2>&1
        
        echo "  Sample:                      ${SAMPLE_ID}"
        echo "  Method:                      bbduk"                    
        echo "  R1:                          ${R1}"
        echo "  R2:                          ${R2}"
        echo "  Sample output directory:     ${SAMPLE_OUTDIR}"

        # Skip existing files
        if compgen -G "${SAMPLE_OUTDIR}/*.trim.fastq.gz" > /dev/null; then
            echo "  Trimmed files already exist; skipping"
            exit 0
        fi

        echo "  Trimming paired FASTQ files..."
        
        # Run BBDUK
        ${BBDUK_SCRIPT} \
            in1="${R1}" \
            in2="${R2}" \
            out1="${SAMPLE_OUTDIR}/${SAMPLE_ID}_1.trim.fastq.gz" \
            out2="${SAMPLE_OUTDIR}/${SAMPLE_ID}_2.trim.fastq.gz" \
            ref="${BBDUK_ADAPTERS}" \
            k=23 \
            hdist=1 \
            qtrim=rl \
            trimq="${BBDUK_TRIMQ}" \
            minlen="${BBDUK_MINLEN}" \
            threads="${SLURM_CPUS_PER_TASK}"

        echo "  Trimming complete"

    )

done

echo "${SCRIPT_NAME} COMPLETE"