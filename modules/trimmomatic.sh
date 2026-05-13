#!/bin/bash
#SBATCH --job-name=trimmomatic
#SBATCH --ntasks=1
set -euo pipefail


######################### GUARDS ##########################

# Required variables inherited via EXPORT_ARRAY + SLURM
GUARD_ARRAY=(
    PIPELINE_DIR
    INPUT_DIR
    OUTPUT_DIR
    SCRIPT_OUTDIR
    SLURM_CPUS_PER_TASK
    TRIM_MISMATCH
    TRIM_LEADING
    TRIM_TRAILING
    TRIM_WINDOW
    TRIM_CLIP
    TRIM_DISCARD
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check EXPORT_ARRAY in run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### PATHS ###########################

# Tool paths (guaranteed by preflight)
TRIM_JAR="${PIPELINE_DIR}/trimmomatic/trimmomatic.jar"
TRIM_ADAPTER="${PIPELINE_DIR}/trimmomatic/adapters/TruSeq3-PE.fa"

######################### MODULES #########################

# Load Java (cluster-specific)
source /etc/profile.d/modules.sh
module load apps/java-8u151.tcl

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Input directory:                        ${INPUT_DIR}"
echo "  Output directory:                       ${SCRIPT_OUTDIR}"
echo "  CPUs allocated:                         ${SLURM_CPUS_PER_TASK}"
echo "  Memory per CPU:                         ${SLURM_MEM_PER_CPU}"
echo "  Allowed seed mismatches:                ${TRIM_MISMATCH}"
echo "  Palindrome clip threshold:              ${TRIM_LEADING}"
echo "  Simple clip threshold:                  ${TRIM_TRAILING}"
echo "  Window scan size:                       ${TRIM_WINDOW}"
echo "  Minimum adapter length for clipping:    ${TRIM_CLIP}"
echo "  Post-clipping discard threshold:        ${TRIM_DISCARD}"

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
        # if [[ ${#R1_FILES[@]} -ne 1 || ${#R2_FILES[@]} -ne 1 ]]; then
        #    fail "Expected exactly one FASTQ pair for ${SAMPLE_ID}"
        # fi

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

        # Restart-safe skip (Trimmomatic outputs multiple files)
        if compgen -G "${SAMPLE_OUTDIR}/*.fastq.gz" > /dev/null; then
            echo "  Trimmed FASTQ files already exist; skipping"
            exit 0
        fi

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
echo "${SCRIPT_NAME} COMPLETE"
echo