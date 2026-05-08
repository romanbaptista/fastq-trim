#!/bin/bash
set -euo pipefail

: "${PIPELINE_DIR:?PIPELINE_DIR not set}"
: "${INPUT_DIR:?INPUT_DIR not set}"
: "${PACKAGE_TO_USE:?PACKAGE_TO_USE not set}"
: "${EXPORT_ARRAY:?EXPORT_ARRAY not inherited}"

######################### PATHS ###########################

# Define output directory
OUTPUT_DIR="${PIPELINE_DIR}/output"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### EXPORTS #########################

# Export OUTPUT_DIR
export OUTPUT_DIR
# Add to EXPORT ARRAY
EXPORT_ARRAY+=(OUTPUT_DIR)

# Snapshot EXPORT_ARRAY
SBATCH_EXPORTS="$(IFS=,; echo "${EXPORT_ARRAY[*]}")"

######################### MAIN ############################

echo
echo "RUNNING pipeline.sh ..."

echo
echo "  User configuration:"
echo "    Input directory:    ${INPUT_DIR}"
echo "    Trimming method:    ${PACKAGE_TO_USE}"

echo
echo "  Pipeline starting..."

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
        echo "  ERROR: Invalid PACKAGE_TO_USE: '${PACKAGE_TO_USE}'"
        echo "  Valid options are: bbduk | trimmomatic"
        echo "  Exiting..."
        exit 1
esac

echo
echo "Pipeline SUBMITTED"
echo "SLURM job ID: ${JOB_ID}"
echo "You may now disconnect from the cluster if required"
echo