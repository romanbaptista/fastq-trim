#!/bin/bash
set -euo pipefail

######################### GUARDS #########################

GUARD_ARRAY=(
    ARRAY_DIR
    LOG_DIR
    PIPELINE_DIR
    PACKAGE_TO_USE
    SBATCH_EXPORTS
    FUNCTIONS_DIR
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or empty}"
done

######################### SETUP ##########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE #########################

source "${FUNCTIONS_DIR}/functions_base.sh"

######################### LOGS ###########################

LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."


echo "  Dispatching module..."

case "${PACKAGE_TO_USE}" in

    bbduk)
        echo "  Submitting bbduk..."

        JOB_ID=$(
            sbatch \
                --parsable \
                --job-name=fastq-trim-bbduk \
                --export="${SBATCH_EXPORTS}" \
                --cpus-per-task="${BBDUK_CPUS}" \
                --mem-per-cpu="${BBDUK_MEM_PER_CPU}" \
                "${PIPELINE_DIR}/bbduk.sh"
        )
        ;;

    trimmomatic)
        echo "  Submitting trimmomatic..."

        JOB_ID=$(
            sbatch \
                --parsable \
                --job-name=fastq-trim-trimmomatic \
                --export="${SBATCH_EXPORTS}" \
                --cpus-per-task="${TRIMMOMATIC_CPUS}" \
                --mem-per-cpu="${TRIMMOMATIC_MEM_PER_CPU}" \
                "${PIPELINE_DIR}/trimmomatic.sh"
        )
        ;;

    *)
        fail_message "No trimming package provided, please edit PACKAGE_TO_USE in config.sh with 'bbduk' or 'trimmomatic'"
esac

echo "${SCRIPT_NAME} COMPLETE"
echo "SLURM job ID: ${JOB_ID}"