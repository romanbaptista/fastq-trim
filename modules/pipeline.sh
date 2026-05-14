#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

GUARD_ARRAY=(
    INPUT_DIR
    PIPELINE_DIR
    MODULES_DIR
    LOG_DIR
    PACKAGE_TO_USE
    EXPORT_ARRAY
    SBATCH_EXPORTS
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    TRIM_CPUS
    TRIM_MEM_PER_CPU
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### LOGS ############################

LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  User configuration:"
echo "    Input directory:      ${INPUT_DIR}"
echo "    Trimming method:      ${PACKAGE_TO_USE}"

echo
echo "  Dispatching module..."

case "${PACKAGE_TO_USE}" in

    bbduk)
        echo "  Submitting BBDUK job..."

        JOB_ID=$(
            sbatch \
                --parsable \
                --export="${SBATCH_EXPORTS}" \
                --cpus-per-task="${BBDUK_CPUS}" \
                --mem-per-cpu="${BBDUK_MEM_PER_CPU}" \
                "${MODULES_DIR}/bbduk.sh"
        )
        ;;

    trimmomatic)
        echo "  Submitting Trimmomatic job..."
        
        JOB_ID=$(
            sbatch \
                --parsable \
                --export="${SBATCH_EXPORTS}" \
                --cpus-per-task="${TRIM_CPUS}" \
                --mem-per-cpu="${TRIM_MEM_PER_CPU}" \
                "${MODULES_DIR}/trimmomatic.sh"
        )
        ;;
    
    *)
        fail "  ERROR: Invalid PACKAGE_TO_USE: '${PACKAGE_TO_USE}'"
esac

echo
echo "Pipeline SUBMITTED"
echo "SLURM job ID: ${JOB_ID}"
echo "You may now disconnect from the cluster if required"
echo