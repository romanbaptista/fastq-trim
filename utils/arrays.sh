#!/bin/bash

# PREFLIGHT_ARRAY:
# Ordered list of preflight scripts executed during pipeline validation.
# This array defines all preflight checks required to safely run the pipeline.
# Each script is sourced sequentially by preflight.sh before any pipeline
# modules are executed.
#
# Define preflight array (all preflight scripts, order is significant)
PREFLIGHT_ARRAY=(
    "preflight_variables.sh"
    "preflight_input.sh"
    "preflight_commands.sh"
    "preflight_scripts.sh"
)

# SCRIPT_ARRAY:
# Ordered list of module scripts that comprise the pipeline execution layer.
#
# Scope:
#   - Used by preflight_scripts.sh to validate script existence and integrity.
#   - Defines the set of valid execution modules that may be dispatched by pipeline.sh.
#
# Design note:
#   This array describes pipeline structure, not execution order.
SCRIPT_ARRAY=(
    "bbduk.sh"
    "trimmomatic.sh"
)

# EXPORT_ARRAY:
# Canonical list of pipeline-owned variables that define the execution ABI.
#
# Scope:
#   - Acts as the single source of truth for environment variables that must be
#     inherited across process boundaries (e.g. into SLURM jobs).
#   - Consumed by run_pipeline.sh to:
#       1. export variables into the shell environment
#       2. construct SBATCH_EXPORTS for controlled propagation
#   - Consumed by downstream scripts to validate required execution context.
#
# Guarantees:
#   - All variables listed here are defined exactly once in run_pipeline.sh.
#   - Only pipeline-owned variables appear here (never SLURM-injected variables).
#   - Every non-SLURM variable used in downstream scripts must appear here.
#
# Design principles:
#   - Defines the execution ABI (application binary interface), not logical dependencies.
#   - Immutable after initialization — must never be modified in downstream scripts.
#   - Structured (array) representation is canonical; SBATCH_EXPORTS is a derived snapshot.
EXPORT_ARRAY=(
    PIPELINE_DIR
    MODULES_DIR
    UTILS_DIR
    PREFLIGHT_DIR
    LOG_DIR
    OUTPUT_DIR
    SCRIPT_OUTDIR
    INPUT_DIR
    PACKAGE_TO_USE
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
    TRIM_CPUS
    TRIM_MEM_PER_CPU
    TRIM_MISMATCH
    TRIM_LEADING
    TRIM_TRAILING
    TRIM_WINDOW
    TRIM_CLIP
    TRIM_DISCARD
)

# COMMAND_ARRAY:
# Canonical list of generic external commands required by the pipeline framework.
#
# Scope:
#   - Validated by preflight_commands.sh.
#   - Includes only framework-level commands used by:
#       - run_pipeline.sh
#       - preflight scripts
#       - pipeline.sh
#       - execution modules
#
# Notes:
#   - Tool-specific binaries (e.g. bbduk, java, trimmomatic) are intentionally excluded
#     and validated by dedicated tool preflight scripts.
COMMAND_ARRAY=(
    sbatch
    grep
    sed
    tr
    xargs
    tee
    mkdir
    gzip
    find
    basename
)

# VARIABLE_ARRAY:
# List of required user-defined configuration variables.
#
# Scope:
#   - Validated by preflight_variables.sh.
#   - Variables must be defined and non-empty in config.sh.
#
# Design note:
#   These represent user inputs, not runtime ABI — but are included in EXPORT_ARRAY
#   so they are available in downstream execution contexts.
VARIABLE_ARRAY=(
    INPUT_DIR
    PACKAGE_TO_USE
    BBDUK_CPUS
    BBDUK_MEM_PER_CPU
    BBDUK_TRIMQ
    BBDUK_MINLEN
    TRIM_CPUS
    TRIM_MEM_PER_CPU
    TRIM_MISMATCH
    TRIM_LEADING
    TRIM_TRAILING
    TRIM_WINDOW
    TRIM_CLIP
    TRIM_DISCARD
)