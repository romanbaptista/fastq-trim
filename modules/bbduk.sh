#!/bin/bash
#SBATCH --job-name=bbduk
set -euo pipefail

######################### GUARDS ##########################

# Required variables inherited via EXPORT_ARRAY + SLURM
GUARD_ARRAY=(
    PIPELINE_DIR
    INPUT_DIR
    OUTPUT_DIR
    SCRIPT_OUTDIR
    SLURM_CPUS_PER_TASK
    BBDUK_TRIMQ
    BBDUK_MINLEN
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check EXPORT_ARRAY in run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### PATHS ###########################

# Define tool paths (guaranteed by preflight)
BBDUK_PATH="${PIPELINE_DIR}/bbtools/bbduk.sh"
BBDUK_ADAPTERS="${PIPELINE_DIR}/bbtools/resources/adapters.fa"

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Info:"
echo "      Input directory:            ${INPUT_DIR}"
echo "      Output directory:           ${SCRIPT_OUTDIR}"
echo "      CPUs allocated per task:    ${SLURM_CPUS_PER_TASK}"

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
        
        # Enforce exactly one pair
        [[ ${#R1_FILES[@]} -eq 1 && ${#R2_FILES[@]} -eq 1 ]] || fail "  ERROR: Expected exactly one FASTQ pair for sample: ${SAMPLE_ID}"

        # Require exactly one FASTQ pair
        #if [[ ${#R1_FILES[@]} -ne 1 || ${#R2_FILES[@]} -ne 1 ]]; then
        #    fail "Expected exactly one FASTQ pair for ${SAMPLE_ID}"
        #fi

        # Define paired files
        R1="${R1_FILES[0]}"
        R2="${R2_FILES[0]}"

        # Create sample output directory
        SAMPLE_OUTDIR="${SCRIPT_DIR}/${SAMPLE_ID}"
        mkdir -p "${SAMPLE_OUTDIR}"
        
        # Create LOGFILE and redirect sample logs
        LOGFILE="${SAMPLE_OUTDIR}/${SAMPLE_ID}_trim.log"
        exec >"${LOGFILE}" 2>&1

        echo "  TRIMMING:                    ${SAMPLE_ID}"
        echo "  R1:                          ${R1}"
        echo "  R2:                          ${R2}"
        echo "  Sample output directory:     ${SAMPLE_OUTDIR}"
        echo

        # Skip existing files
        if compgen -G "${SAMPLE_OUTDIR}/*.trim.fastq.gz" > /dev/null; then
            echo "  Trimmed files already exist; skipping"
            exit 0
        fi

        # Run BBDUK
        ${BBDUK_PATH} \
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

        echo "   Trimming COMPLETE"

    )

done

echo
echo "${SCRIPT_NAME} COMPLETE"
echo