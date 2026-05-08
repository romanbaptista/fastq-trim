# `preflight`
This directory contains the preflight validation layer for the trim pipeline.

Preflight scripts are responsible for all validation and environment checks required to safely execute the pipeline under SLURM.

No pipeline modules are submitted unless all preflight checks succeed.

Preflight scripts are sourced and executed by `run_pipeline.sh` on the login node before any SLURM jobs are submitted.

# Design Contract
All preflight scripts adhere to the following principles:
- Fail‑fast validation before any computation is scheduled
- No side effects beyond controlled tool installation
- Clear and actionable error messages
- Deterministic checks with no reliance on execution order beyond orchestration
- Validation only — no pipeline execution logic
- Centralized enforcement of pipeline invariants

Once preflight validation completes successfully, downstream scripts may assume:
- All required configuration variables, tools, files, and directories are valid and usable.

# Responsibilities of Preflight
The preflight layer ensures that:
- User configuration is complete and non‑empty
- Input data are present and correctly structured
- Required scripts exist and are non‑empty
- All required external commands are available
- Tool‑specific dependencies are installed and usable
- Required adapter and executable files exist and are non‑empty

This avoids late‑stage failures inside SLURM jobs and prevents unnecessary consumption of compute resources.

# Preflight Script Overview
The following scripts are executed during preflight, in a controlled order defined by `run_pipeline.sh`:
```text
preflight_input.sh
preflight_variables.sh
preflight_scripts.sh
preflight_commands.sh
preflight_bbduk.sh                  (if PACKAGE_TO_USE=bbduk)
preflight_trimmomatic.sh            (if PACKAGE_TO_USE=trimmomatic)
```

## `preflight_input.sh`
Validates the user‑supplied input data directory.

### Responsibilities
- Confirms `INPUT_DIR` is set and non‑empty
- Verifies that `INPUT_DIR` exists
- Confirms the presence of at least one `.fastq.gz` file

This script ensures that the pipeline will have sequencing data to process before submission.

## `preflight_variables.sh`
Validates core pipeline configuration variables.

### Responsibilities
- Confirms `PACKAGE_TO_USE` is set and non‑empty

Validates that `PACKAGE_TO_USE` is one of:
- bbduk
- trimmomatic

This script determines which tool‑specific preflight and module scripts will execute downstream.

## `preflight_scripts.sh`
Validates pipeline module integrity.

### Responsibilities
- Confirms all expected module scripts exist in `modules/`
- Verifies that each module script is non‑empty
- Confirms presence and integrity of `modules/pipeline.sh`

This prevents submission of incomplete or corrupted pipeline code.

### `preflight_commands.sh`
Validates required external commands.

### Responsibilities
- Confirms availability of all commands used by the pipeline at runtime
- Uses `check_command` for strict, PATH‑based validation

Commands validated here include:
- Shell and filesystem utilities
- SLURM submission commands
- Download and archive tools needed for tool installation

This script intentionally checks only commands actually used by the pipeline, avoiding redundant or cluster‑specific assumptions.

## `preflight_bbduk.sh`
Runs only when PACKAGE_TO_USE=bbduk.

### Responsibilities
- Validates all BBDUK‑specific configuration variables
- Ensures BBTools is installed (downloads if missing)

Verifies:
- `bbtools/bbduk.sh` exists, is executable, and non‑empty
- Adapter FASTA file exists and is non‑empty

This script centralizes all BBTools‑specific invariants so that `modules/bbduk.sh` can assume correctness at runtime.

### `preflight_trimmomatic.sh`
Runs only when `PACKAGE_TO_USE`=trimmomatic.

### Responsibilities
- Validates all Trimmomatic‑specific configuration variables
- Ensures Trimmomatic is installed (downloads if missing)

Verifies:
- Trimmomatic JAR exists and is non‑empty
- Java runtime is available

This script ensures Trimmomatic execution will not fail due to missing runtime dependencies.

# Execution Model
All preflight scripts are:
- Executed on the login node
- Sourced into the same shell for shared context
- Terminated immediately on failure

No SLURM jobs are submitted unless all applicable preflight scripts complete successfully.

# Invariants Guaranteed After Preflight
After preflight completes, downstream pipeline stages may assume:
- Configuration variables are set and non‑empty
- Input directories and FASTQ files exist
- Required tools are installed and usable
- Adapter and executable files exist and contain data
- All required commands are available in PATH

This contract enables clean separation between validation and execution throughout the pipeline.

# Notes
- Preflight scripts are not intended to be run directly by end users
- Tool installation performed during preflight is deterministic and repeat‑safe
- All validation logic is centralized; modules do not repeat preflight checks
- Any modification to pipeline inputs or configuration requires rerunning preflight