
#!/bin/bash
set -euo pipefail

# Define script name
CURRENT_SCRIPT="$(basename "${BASH_SOURCE[0]}")"

# Define required commands
COMMAND_ARRAY=(
    bash
    sbatch
    find
    basename
    mkdir
    gzip
    tar
    wget
)

echo "  RUNNING ${CURRENT_SCRIPT} ..."
echo "  Checking required external commands..."

# Iterate over required commands
for cmd in "${COMMAND_ARRAY[@]}"; do
    check_command "${cmd}" || fail "  Please ensure command is available in PATH: ${cmd}"
done

echo "  All required commands confirmed"
echo "  ${CURRENT_SCRIPT} COMPLETE"
