#!/bin/bash
set -euo pipefail

######################### GUARDS #########################

GUARD_ARRAY=(
    FUNCTIONS_DIR
    INPUT_DIR
    ROOT_DIR
    PACKAGE_OUTDIR
    TRIMMOMATIC_CPUS
    TRIMMOMATIC_MEM_PER_CPU
    TRIMMOMATIC_MISMATCH
    TRIMMOMATIC_LEADING
    TRIMMOMATIC_TRAILING
    TRIMMOMATIC_WINDOW
    TRIMMOMATIC_CLIP
    TRIMMOMATIC_DISCARD
    SLURM_CPUS_PER_TASK
    SLURM_MEM_PER_CPU
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or empty}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE #########################

# Allow module loading in SLURM job
source /etc/profile.d/modules.sh
source "${FUNCTIONS_DIR}/functions_base.sh"

######################### MODULES ########################

# Load java
module load apps/java-8u151.tcl || fail_message "Failed to load java module"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo
echo "  Info:"
echo "    Input directory:                        ${INPUT_DIR}"
echo "    Output directory:                       ${PACKAGE_OUTDIR}"
echo "    CPUs allocated:                         ${SLURM_CPUS_PER_TASK}"
echo "    Memory per CPU:                         ${SLURM_MEM_PER_CPU}"
echo "    Allowed seed mismatches:                ${TRIMMOMATIC_MISMATCH}"
echo "    Palindrome clip threshold:              ${TRIMMOMATIC_LEADING}"
echo "    Simple clip threshold:                  ${TRIMMOMATIC_TRAILING}"
echo "    Window scan size:                       ${TRIMMOMATIC_WINDOW}"
echo "    Minimum adapter length for clipping:    ${TRIMMOMATIC_CLIP}"
echo "    Post-clipping discard threshold:        ${TRIMMOMATIC_DISCARD}"

# Define tool paths (guaranteed by preflight)
TRIMMOMATIC_JAR="${ROOT_DIR}/trimmomatic/trimmomatic.jar"
TRIMMOMATIC_ADAPTER="${ROOT_DIR}/trimmomatic/adapters/TruSeq3-PE.fa"

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
        echo "  Method:                      trimmomatic"                    
        echo "  R1:                          ${R1}"
        echo "  R2:                          ${R2}"
        echo "  Sample output directory:     ${SAMPLE_OUTDIR}"

        # Skip existing files
        if compgen -G "${SAMPLE_OUTDIR}/*.trim.fastq.gz" > /dev/null; then
            echo "  Trimmed files already exist; skipping"
            exit 0
        fi

        echo "  Trimming paired FASTQ files..."

        # Run trimmomatic
        java -jar "${TRIMMOMATIC_JAR}" \
            PE \
                "${R1}" "${R2}" \
                -baseout "${SAMPLE_OUTDIR}/${SAMPLE_ID}.trim.fastq.gz" \
            ILLUMINACLIP:"${TRIMMOMATIC_ADAPTER}":"${TRIMMOMATIC_MISMATCH}":"${TRIMMOMATIC_LEADING}":"${TRIMMOMATIC_TRAILING}":"${TRIMMOMATIC_CLIP}":True \
            LEADING:"${TRIMMOMATIC_LEADING}" \
            TRAILING:"${TRIMMOMATIC_TRAILING}" \
            SLIDINGWINDOW:"${TRIMMOMATIC_WINDOW}":${TRIMMOMATIC_CLIP} \
            MINLEN:"${TRIMMOMATIC_DISCARD}"

        echo "  Trimming complete"
        
    )

done

echo "${SCRIPT_NAME} COMPLETE"