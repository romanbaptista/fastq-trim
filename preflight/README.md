# `preflight`

This directory contains the preflight validation layer for the `fastq-trim` pipeline.

Preflight scripts are responsible for all validation and environment checks required to safely execute the pipeline on an HPC system before any SLURM jobs are submitted.

No pipeline modules are executed unless all preflight checks succeed.

All preflight scripts are sourced and executed by run_pipeline.sh on the login node, ensuring that pipeline execution begins only after the environment, configuration, and inputs are fully validated.

# Design Contract
All preflight scripts adhere to the following principles:
- Fail‑fast validation before any pipeline execution
- No side effects beyond controlled, deterministic tool installation
- Clear, actionable error messages on failure
- Deterministic behavior with explicit ordering
- Validation only — no execution or data processing logic
- Centralized enforcement of pipeline invariants
- Strict use of canonical arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`)

Once preflight validation completes successfully, downstream scripts may assume:
- All required configuration variables are valid and non‑empty
- All required commands and tools are available and usable
- Input data is present and correctly structured
- Required directories exist and are writable
- Tool installations are complete and reproducible
- Execution modules can safely run without any further validation

# Responsibilities of Preflight
The preflight layer ensures that:
- User configuration is complete and non‑empty
- Input directory structure is valid and contains FASTQ data
- Pipeline module scripts exist and are non‑empty
- Required external commands are available
- Toolchains (bbtools or trimmomatic) are installed and usable
- Tool installations are reproducible and deterministic

This prevents late‑stage failures, wasted cluster resources, and partially executed pipelines caused by missing dependencies or invalid inputs.

# Preflight Script Overview
The set and execution order of all preflight scripts is centrally defined in:

```text
utils/arrays.sh  → PREFLIGHT_ARRAY
```

`preflight/preflight.sh` sources and executes each script listed in `PREFLIGHT_ARRAY`, followed by a tool‑specific preflight script based on `PACKAGE_TO_USE`.

### Current preflight order
```text
preflight_input.sh
preflight_variables.sh
preflight_scripts.sh
preflight_commands.sh
preflight_<tool>.sh
```

The final script is determined dynamically:
- `preflight_bbduk.sh` if `PACKAGE_TO_USE="bbduk"`
- `preflight_trimmomatic.sh` if `PACKAGE_TO_USE="trimmomatic"`

## `preflight_input.sh`
Validates pipeline input data.

### Responsibilities
- Confirms `INPUT_DIR` is defined and non‑empty
- Verifies that `INPUT_DIR` exists
- Confirms presence of `.fastq.gz` files within subdirectories

This script enforces the pipeline’s input data contract, ensuring that valid sequencing data is available before execution begins.

## `preflight_variables.sh`
Validates required user‑defined configuration variables.

### Responsibilities
Confirms all variables listed in `VARIABLE_ARRAY` are defined and non-empty

These variables originate from `config.sh` and are later exported as part of the execution ABI.

## `preflight_scripts.sh`
Validates pipeline module integrity.

### Responsibilities
- Confirms all scripts listed in `SCRIPT_ARRAY` exist under `modules/`
- Verifies that each script is non‑empty
- Confirms presence and integrity of `modules/pipeline.sh`

This prevents execution of incomplete or corrupted module code.

## `preflight_commands.sh`
Validates required framework‑level external commands.

### Responsibilities
- Confirms availability of all commands listed in `COMMAND_ARRAY`
- Uses strict `PATH`‑based validation

Commands validated include:
- Shell and filesystem utilities
- Core text-processing tools
- SLURM submission commands

Tool‑specific binaries (e.g. BBDUK, trimmomatic, Java) are intentionally excluded and handled by tool‑specific preflight scripts.

## `preflight_bbduk.sh`
Validates and installs bbtools.

### Responsibilities
- Confirms a valid bbtools installation exists

- Verifies `bbduk.sh` exists, is executable, and contains data:
- Verifies adapter FASTA file exists and is non‑empty
- Installs bbtools if missing
- Confirms installation integrity after installation

This script defines all bbtools‑specific invariants required for downstream execution.

## `preflight_trimmomatic.sh`
Validates and installs trimmomatic.

### Responsibilities
- Confirms a valid trimmomatic installation exists
- Verifies trimmomatic JAR is present and non‑empty
- Verifies java runtime is available
- Installs trimmomatic if missing
- Confirms installation integrity after installation

This script defines all trimmomatic‑specific execution invariants.

# Execution Model
All preflight scripts are:
- Executed on the login node
- Sourced into a single shell for shared context
- Run in a strictly defined order
- Terminated immediately on failure

The pipeline does not proceed unless all preflight scripts complete successfully.

# Invariants Guaranteed After Preflight
After successful preflight validation, downstream pipeline stages may assume:
- All configuration variables are defined and valid
- Input directory structure is correct and contains FASTQ data
- Required framework‑level commands are available
- Selected trimming tool is installed and usable
- Adapter files and executables are present and valid
- Module scripts exist and contain executable code
- Execution ABI (`EXPORT_ARRAY`) is complete and correct

This contract ensures a clean separation between validation and execution throughout the `fastq-trim` pipeline.

# Notes
- Preflight scripts are not intended to be run directly by end users
- Tool installation is deterministic and restart‑safe
- All validation logic is centralized in this directory
- Module scripts do not repeat validation checks
- Arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`) define the canonical validation surface
- Any modification to configuration, inputs, or pipeline structure requires rerunning preflight
